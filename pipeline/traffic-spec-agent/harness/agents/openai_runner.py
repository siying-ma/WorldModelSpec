"""One OpenAI Responses API call per session, for the sessions that use no tool: the readers, the
judges and the reviewers. The prompt goes in as the input, the answer comes back as text, and the
record written beside the Claude session records has the same shape (`type: "result"`, `result`,
`num_turns`, `duration_ms`, `usage`) so the phases read both alike. The key is `OPENAI_API_KEY`
in the harness's own environment; every Claude session is launched without it.

Tokens are recorded; a cost in USD is not, since no price table lives here.
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
               timeout_seconds: Optional[float]) -> tuple[int, Optional[dict], bool]:
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
        resp = client.responses.create(**kwargs)
    except APITimeoutError as e:
        stream_path.write_text(json.dumps({"type": "error", "error": f"timeout: {e}"}) + "\n", encoding="utf-8")
        print(f"[warn] OpenAI {name} timed out")
        return 1, None, True
    except (RateLimitError, APIError) as e:
        stream_path.write_text(json.dumps({"type": "error", "error": str(e)[:2000]}) + "\n", encoding="utf-8")
        print(f"[info] OpenAI {name} refused: {str(e)[:200]}")
        return 1, None, False
    text = getattr(resp, "output_text", "") or ""
    usage = resp.usage.model_dump() if getattr(resp, "usage", None) is not None else {}
    result = {"type": "result", "subtype": "success", "is_error": False, "result": text, "num_turns": 1,
              "duration_ms": int((time.time() - t0) * 1000), "total_cost_usd": None, "usage": usage,
              "vendor": "openai", "model": getattr(resp, "model", name), "response_id": getattr(resp, "id", None)}
    with open(stream_path, "w", encoding="utf-8") as out:
        out.write(json.dumps({"type": "request", "model": name, "effort": effort, "prompt_chars": len(prompt)}) + "\n")
        try:
            out.write(json.dumps({"type": "response", "response": resp.model_dump()}, default=str) + "\n")
        except Exception:                        # the record is informational; the result line below is what the harness reads
            pass
        out.write(json.dumps(result) + "\n")
    print(f"[info] OpenAI {name} answered in {result['duration_ms'] / 1000:.0f}s, {usage.get('total_tokens', '?')} tokens")
    return 0, result, False
