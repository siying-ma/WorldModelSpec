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
raises `BudgetPaused`: the run pauses rather than retrying. The cost is computed by the caller from
the operator's price table.
"""
from __future__ import annotations

import json
import os
import time
from pathlib import Path
from typing import Optional

#: Our effort words (`claude --effort`) to the Responses API's reasoning effort.
EFFORT = {"low": "low", "medium": "medium", "high": "high", "xhigh": "high", "max": "high"}


def available() -> bool:
    return bool(os.environ.get("OPENAI_API_KEY"))


def run_openai(prompt: str, *, model: str, stream_path: Path, effort: Optional[str],
               timeout_seconds: Optional[float], max_output_tokens: Optional[int] = None) -> tuple[int, Optional[dict], bool]:
    """Run one tool-less session. Returns `(returncode, result_line, timed_out)` as `run_claude`
    does: code 0 with a result on an answer; code 1 and no result when the API refused or failed
    (the caller treats that as a session that never ran and relaunches after its wait)."""
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
        client = OpenAI(timeout=timeout_seconds or 900.0, max_retries=2)
        # every tool-less session answers one JSON object: JSON mode makes the answer parse
        kwargs = {"model": name, "input": prompt, "store": False, "text": {"format": {"type": "json_object"}}}
        if effort:
            kwargs["reasoning"] = {"effort": EFFORT.get(effort, "high")}
        if max_output_tokens:
            kwargs["max_output_tokens"] = int(max_output_tokens)
        resp = client.responses.create(**kwargs)
    except APITimeoutError as e:
        stream_path.write_text(json.dumps({"type": "error", "error": f"timeout: {e}"}) + "\n", encoding="utf-8")
        print(f"[warn] OpenAI {name} timed out")
        return 1, None, True
    except (RateLimitError, APIError) as e:
        if "insufficient_quota" in str(e):
            from ..store.budget import BudgetPaused
            stream_path.write_text(json.dumps({"type": "error", "error": str(e)[:2000]}) + "\n", encoding="utf-8")
            raise BudgetPaused(f"the OpenAI account's quota is exhausted: {str(e)[:200]}")
        stream_path.write_text(json.dumps({"type": "error", "error": str(e)[:2000]}) + "\n", encoding="utf-8")
        print(f"[info] OpenAI {name} refused: {str(e)[:200]}")
        return 1, None, False
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
    a plain dict (`output`, `usage`, `status`, `id`) on an answer; code 1 with `{"error": reason}`
    (sanitized) when the API refused, failed or timed out. With `store: False` the reasoning items come back encrypted, to be sent
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
    try:                                     # no retry inside a request: the session's relaunch is the one retry, within its deadline
        resp = OpenAI(timeout=max(1.0, timeout_seconds), max_retries=0).responses.create(**kwargs)
    except APITimeoutError as e:
        return 1, {"error": sanitized(e)}, True
    except (RateLimitError, APIError) as e:
        if "insufficient_quota" in str(e):
            from ..store.budget import BudgetPaused
            raise BudgetPaused(f"the OpenAI account's quota is exhausted: {str(e)[:200]}")
        print(f"[info] OpenAI {name} refused: {sanitized(e)}")
        return 1, {"error": sanitized(e)}, False
    output = [o.model_dump(exclude_none=True) for o in (resp.output or [])]     # sent back as they came, no null fields
    usage = resp.usage.model_dump() if getattr(resp, "usage", None) is not None else {}
    return 0, {"id": getattr(resp, "id", None), "status": getattr(resp, "status", None), "output": output, "usage": usage,
               "model": getattr(resp, "model", name)}, False
