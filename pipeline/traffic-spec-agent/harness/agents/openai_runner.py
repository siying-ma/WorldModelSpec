"""The OpenAI Responses API, for the second vendor's sessions. `run_openai` is one call for a
session that uses no tool (a reader or a judge); `request` is one call of a reviewer's tool
session, which `session.run_tools` drives request by request.

`run_openai`: one call per session, for the sessions that use no tool: the readers and the
judges. The prompt goes in as the input, the answer comes back as text, and the
record written beside the Claude session records has the same shape (`type: "result"`, `result`,
`num_turns`, `duration_ms`, `usage`) so the phases read both alike. The key is `OPENAI_API_KEY`
in the harness's own environment; every Claude session is launched without it.

Every call carries an output-token limit (reasoning tokens count against it); an answer cut off by
it comes back as it is, and the caller reads it as a malformed answer. An answer of exhausted quota
raises `BudgetPaused`: the run pauses rather than retrying. The return code says what is known of the
request:
- `BAD_REQUEST`: the API rejected the request itself (400, 404, 422); the caller never sends the same
  request again;
- 1: refused before it was executed (401, 403, 429, a refused connection, an unresolvable host, no
  key): it cost nothing;
- `LOST`: it may have been executed and its answer was lost (a timeout after sending, a dropped
  connection, 408, a 5xx, an unreadable response): the caller keeps its reservation as spent.
The client never retries: the session's relaunch is the one retry. The cost is computed by the
caller from the operator's price table. `call_digest` and `request_digest` identify the effective
request sent, so a rejected one is recognized if it is about to be sent again.
"""
from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Optional

#: The return code of a request the API rejected as such: the input is wrong, a retry would fail alike.
BAD_REQUEST = 2
#: The return code of a request that may have been executed and whose answer was lost.
LOST = 3
DETERMINISTIC = (400, 404, 422)

#: Our effort words (`claude --effort`) to the Responses API's reasoning effort.
EFFORT = {"low": "low", "medium": "medium", "high": "high", "xhigh": "high", "max": "high"}


def available() -> bool:
    return bool(os.environ.get("OPENAI_API_KEY"))


def _refused(e: BaseException) -> bool:
    """Whether a connection error happened before anything was sent: the connection was refused or
    the host did not resolve."""
    seen = set()
    while e is not None and id(e) not in seen:
        seen.add(id(e))
        if isinstance(e, ConnectionRefusedError) or type(e).__name__ == "gaierror":
            return True
        text = str(e)
        if "Connection refused" in text or "Name or service not known" in text or "nodename nor servname" in text:
            return True
        e = e.__cause__ or e.__context__
    return False


def _code(e: BaseException) -> int:
    """What an API exception says of the request: `BAD_REQUEST`, 1 (not executed) or `LOST`."""
    kinds = {c.__name__ for c in type(e).__mro__}
    status = getattr(e, "status_code", None)
    if status in DETERMINISTIC:
        return BAD_REQUEST
    if "APITimeoutError" in kinds:
        return LOST
    if "APIConnectionError" in kinds:
        return 1 if _refused(e) else LOST
    if status is None or status == 408 or status >= 500:
        return LOST
    return 1


def _digest(payload: dict) -> str:
    import hashlib
    return hashlib.sha256(json.dumps(payload, sort_keys=True, ensure_ascii=False, default=str).encode()).hexdigest()


def call_digest(prompt: str, *, model: str, effort: Optional[str], max_output_tokens: Optional[int]) -> str:
    """The identity of a tool-less call as `run_openai` sends it (no secret enters it)."""
    name = model.split(":", 1)[1] if model.startswith("openai:") else model
    return _digest({"kind": "call", "model": name, "input": prompt, "format": "json_object",
                    "effort": EFFORT.get(effort, "high") if effort else None, "max_output_tokens": max_output_tokens})


def request_digest(items: list, *, model: str, tools: list[dict], tool_choice, effort: Optional[str],
                   max_output_tokens: Optional[int]) -> str:
    """The identity of one tool-session request as `request` sends it: the conversation, the model,
    the tools and their schema, the tool choice, the effort and the output cap."""
    name = model.split(":", 1)[1] if model.startswith("openai:") else model
    return _digest({"kind": "request", "model": name, "input": items, "tools": tools, "tool_choice": tool_choice,
                    "effort": EFFORT.get(effort, "high") if effort else None, "max_output_tokens": max_output_tokens})


def last_error(stream_path: Path) -> Optional[str]:
    """The error a tool-less call recorded in its stream, if any."""
    try:
        for line in reversed(stream_path.read_text(encoding="utf-8").splitlines()):
            d = json.loads(line)
            if d.get("type") == "error":
                return str(d.get("error"))[:300]
    except (OSError, json.JSONDecodeError):
        pass
    return None


def run_openai(prompt: str, *, model: str, stream_path: Path, effort: Optional[str],
               timeout_seconds: Optional[float], max_output_tokens: Optional[int] = None) -> tuple[int, Optional[dict], bool]:
    """Run one tool-less session. Returns `(returncode, result_line, timed_out)` as `run_claude`
    does: code 0 with a result on an answer; no result when the API refused or failed, or the call
    timed out (a session that never ran), with the code saying what is known of the request
    (`BAD_REQUEST`, 1 or `LOST`)."""
    stream_path.parent.mkdir(parents=True, exist_ok=True)
    if not available():
        stream_path.write_text(json.dumps({"type": "error", "error": "OPENAI_API_KEY is not set"}) + "\n", encoding="utf-8")
        print("[info] OpenAI session not launched: OPENAI_API_KEY is not set")
        return 1, None, False
    from openai import OpenAI, APIError, APITimeoutError, RateLimitError
    name = model.split(":", 1)[1] if model.startswith("openai:") else model
    print(f"[info] Launching OpenAI {name}: out={stream_path.parent}")
    t0 = time.time()
    try:
        client = OpenAI(timeout=timeout_seconds or 900.0, max_retries=0)
        # every tool-less session answers one JSON object: JSON mode makes the answer parse
        kwargs = {"model": name, "input": prompt, "store": False, "text": {"format": {"type": "json_object"}}}
        if effort:
            kwargs["reasoning"] = {"effort": EFFORT.get(effort, "high")}
        if max_output_tokens:
            kwargs["max_output_tokens"] = int(max_output_tokens)
        resp = client.responses.create(**kwargs)
    except APITimeoutError as e:
        stream_path.write_text(json.dumps({"type": "error", "error": f"timeout: {sanitized(e)}"}) + "\n", encoding="utf-8")
        print(f"[warn] OpenAI {name} timed out")
        return LOST, None, True
    except (RateLimitError, APIError) as e:
        if "insufficient_quota" in str(e):
            from ..store.budget import BudgetPaused
            stream_path.write_text(json.dumps({"type": "error", "error": sanitized(e)}) + "\n", encoding="utf-8")
            raise BudgetPaused(f"the OpenAI account's quota is exhausted: {str(e)[:200]}")
        stream_path.write_text(json.dumps({"type": "error", "error": sanitized(e)}) + "\n", encoding="utf-8")
        print(f"[info] OpenAI {name} refused: {sanitized(e)}")
        return _code(e), None, False
    text = getattr(resp, "output_text", "") or ""
    usage = resp.usage.model_dump() if getattr(resp, "usage", None) is not None else {}
    result = {"type": "result", "subtype": "success", "is_error": False, "result": text, "num_turns": 1,
              "duration_ms": int((time.time() - t0) * 1000), "total_cost_usd": None, "usage": usage,
              "vendor": "openai", "model": getattr(resp, "model", name), "response_id": getattr(resp, "id", None),
              "status": getattr(resp, "status", None)}
    with open(stream_path, "w", encoding="utf-8") as out:
        out.write(json.dumps({"type": "request", "model": name, "effort": effort, "prompt_chars": len(prompt)}) + "\n")
        try:
            out.write(json.dumps({"type": "response", "response": resp.model_dump()}, default=str) + "\n")
        except Exception:                        # the record is informational; the result line below is what the harness reads
            pass
        out.write(json.dumps(result) + "\n")
    print(f"[info] OpenAI {name} answered in {result['duration_ms'] / 1000:.0f}s, {usage.get('total_tokens', '?')} tokens")
    return 0, result, False


def sanitized(e: BaseException) -> str:
    """An API error as it may be recorded: its type and the first 300 characters of its message,
    with anything shaped like a key masked."""
    import re
    return re.sub(r"(sk-|key-|Bearer\s+)[A-Za-z0-9_\-]{6,}", r"\1…", f"{type(e).__name__}: {str(e)}")[:300]


def request(items: list, *, model: str, tools: list[dict], tool_choice, effort: Optional[str],
            timeout_seconds: float, max_output_tokens: Optional[int] = None) -> tuple[int, Optional[dict], bool]:
    """One request of a tool session: the conversation so far (`items`), the harness's function
    tools, one call at a time. Returns `(code, response, timed_out)`: code 0 with the response as
    a plain dict (`output`, `usage`, `status`, `id`) on an answer; code `BAD_REQUEST`, 1 or `LOST`
    with `{"error": reason}` (sanitized) when the API rejected, refused or failed the request or it
    timed out. With `store: False` the reasoning items come back encrypted, to be sent
    back with the next request. Only function tools are admitted: a reviewer reaches nothing but
    the harness's checks."""
    if any(t.get("type") != "function" for t in tools):
        raise ValueError("a tool session admits only the harness's function tools")
    if not available():
        return 1, None, False
    from openai import OpenAI, APIError, APITimeoutError, RateLimitError
    name = model.split(":", 1)[1] if model.startswith("openai:") else model
    kwargs = {"model": name, "input": items, "store": False, "tools": tools, "tool_choice": tool_choice,
              "parallel_tool_calls": False, "include": ["reasoning.encrypted_content"]}
    if effort:
        kwargs["reasoning"] = {"effort": EFFORT.get(effort, "high")}
    if max_output_tokens:
        kwargs["max_output_tokens"] = int(max_output_tokens)
    try:
        resp = OpenAI(timeout=max(1.0, timeout_seconds), max_retries=0).responses.create(**kwargs)
    except APITimeoutError as e:
        return LOST, {"error": sanitized(e)}, True
    except (RateLimitError, APIError) as e:
        if "insufficient_quota" in str(e):
            from ..store.budget import BudgetPaused
            raise BudgetPaused(f"the OpenAI account's quota is exhausted: {str(e)[:200]}")
        print(f"[info] OpenAI {name} refused: {sanitized(e)}")
        return _code(e), {"error": sanitized(e)}, False
    output = [o.model_dump(exclude_none=True) for o in (resp.output or [])]     # sent back as they came, no null fields
    usage = resp.usage.model_dump() if getattr(resp, "usage", None) is not None else {}
    return 0, {"id": getattr(resp, "id", None), "status": getattr(resp, "status", None), "output": output, "usage": usage,
               "model": getattr(resp, "model", name)}, False
