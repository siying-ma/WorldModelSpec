"""One agent session with the run's options: effort, budget, and a relaunch when the session never ran.

A session that the account or the API refused (a usage limit, an API error, a crash before the
first turn) is not the agent's failure and is never counted as an attempt against a law: it is
relaunched after `retry_wait` seconds, `session_retries` times, and if it still does not run the
phase reports `SessionUnavailable` so the loop can stop cleanly instead of burning the ledger.
"""
from __future__ import annotations
import json
import time
from pathlib import Path
from typing import Optional
from . import runner
from ..store.state import Options


class SessionUnavailable(RuntimeError):
    pass


def run(prompt: str, cwd: Path, out_dir: Path, opts: Options, *, max_turns: int, effort: Optional[str],
        label: str = "session", timeout: Optional[float] = None) -> dict:
    """Launch, record `<label>.jsonl` and `<label>_result.json`, relaunch on a refusal. Returns the result record."""
    attempts = 0
    while True:
        attempts += 1
        suffix = "" if attempts == 1 else f".retry{attempts - 1}"
        code, result, timed_out = runner.run_claude(
            prompt, cwd=cwd, stream_path=out_dir / f"{label}{suffix}.jsonl", max_turns=max_turns,
            model=opts.model, effort=effort, max_budget_usd=opts.session_budget_usd,
            timeout_seconds=timeout if timeout is not None else opts.session_timeout)
        record = {"code": code, "timed_out": timed_out, "attempt": attempts, "result": result}
        (out_dir / f"{label}_result{suffix}.json").write_text(json.dumps(record, ensure_ascii=False, indent=1), encoding="utf-8")
        why = runner.session_failure(code, result, timed_out)
        if why is None:
            return record
        hint = runner.reset_hint(why)
        print(f"[session] {label} did not run: {why}" + (f" (resets {hint})" if hint else ""))
        if attempts > opts.session_retries:
            raise SessionUnavailable(why)
        print(f"[session] relaunching in {opts.retry_wait:.0f}s ({attempts}/{opts.session_retries})")
        time.sleep(opts.retry_wait)
