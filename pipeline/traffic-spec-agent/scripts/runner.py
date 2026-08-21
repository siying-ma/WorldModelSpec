"""Claude Code invocation.

Adapted from cc-refactor-agent's `scripts/runner.py`: one `claude -p` session
per unit of work, NDJSON stream saved verbatim, usage parsed from the final
`type: "result"` line, and every live subprocess killed on SIGINT/SIGTERM so an
interrupted run does not leave orphans behind.
"""

from __future__ import annotations

import json
import os
import signal
import subprocess
import sys
import threading
import uuid
from pathlib import Path
from typing import Optional

sys.stdout.reconfigure(line_buffering=True)
sys.stderr.reconfigure(line_buffering=True)

MODEL_ALIASES = {
    "opus": "claude-opus-5",
    "sonnet": "claude-sonnet-5",
    "haiku": "claude-haiku-4-5-20251001",
    "fable": "claude-fable-5",
}

_active_procs: set[subprocess.Popen] = set()
_active_procs_lock = threading.Lock()


def _register(proc: subprocess.Popen) -> None:
    with _active_procs_lock:
        _active_procs.add(proc)


def _unregister(proc: subprocess.Popen) -> None:
    with _active_procs_lock:
        _active_procs.discard(proc)


def _kill_all(signum, frame) -> None:
    with _active_procs_lock:
        procs = list(_active_procs)
    if procs:
        print(f"\n[info] Killing {len(procs)} active Claude process(es)...", file=sys.stderr)
        for proc in procs:
            try:
                proc.kill()
            except OSError:
                pass
    sys.exit(1)


signal.signal(signal.SIGINT, _kill_all)
signal.signal(signal.SIGTERM, _kill_all)


def resolve_model(model: Optional[str]) -> Optional[str]:
    if not model:
        return None
    return MODEL_ALIASES.get(model, model)


def run_claude(
    prompt: str,
    cwd: Path,
    stream_path: Path,
    max_turns: int = 60,
    model: Optional[str] = None,
    effort: Optional[str] = None,
    max_budget_usd: Optional[float] = None,
    timeout_seconds: Optional[float] = None,
    env_overrides: Optional[dict[str, str]] = None,
) -> tuple[int, Optional[dict], bool]:
    """Run one headless Claude session.

    Returns ``(returncode, result_line, timed_out)`` where ``result_line`` is the
    parsed final ``type: "result"`` object, or ``None`` if the session produced
    none (crash, hard kill).
    """
    cmd = [
        "claude",
        "-p",
        "--verbose",
        "--output-format", "stream-json",
        "--permission-mode", "bypassPermissions",
        "--max-turns", str(max_turns),
    ]
    resolved = resolve_model(model)
    if resolved:
        cmd += ["--model", resolved]
    if effort:
        cmd += ["--effort", effort]
    if max_budget_usd is not None:
        cmd += ["--max-budget-usd", f"{max_budget_usd:.2f}"]
    cmd.append(prompt)

    env = os.environ.copy()
    if env_overrides:
        env.update(env_overrides)

    stream_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"[info] Launching Claude: cwd={cwd}")
    if timeout_seconds is not None:
        print(f"[info] Timeout: {timeout_seconds:.0f}s ({timeout_seconds / 60:.1f}m)")

    timed_out = False
    with open(stream_path, "w", encoding="utf-8") as out:
        proc = subprocess.Popen(
            cmd, stdout=out, stderr=subprocess.STDOUT, text=True,
            env=env, cwd=str(cwd),
        )
        _register(proc)
        try:
            proc.wait(timeout=timeout_seconds)
        except subprocess.TimeoutExpired:
            timed_out = True
            print(f"[warn] Claude pid={proc.pid} exceeded timeout, killing...", file=sys.stderr)
            proc.kill()
            proc.wait()
        finally:
            _unregister(proc)

    print(f"[info] Claude pid={proc.pid} exited with code {proc.returncode}"
          f"{' (timed out)' if timed_out else ''}")

    return proc.returncode, parse_result_line(stream_path), timed_out


def parse_result_line(stream_path: Path) -> Optional[dict]:
    """Find the final ``type: "result"`` object in an NDJSON stream."""
    try:
        with open(stream_path, "r", encoding="utf-8", errors="replace") as f:
            lines = [ln.strip() for ln in f if ln.strip()]
    except OSError:
        return None

    for line in reversed(lines):
        try:
            parsed = json.loads(line)
        except json.JSONDecodeError:
            continue
        if parsed.get("type") == "result":
            text = parsed.get("result", "") or ""
            shown = text if len(text) <= 500 else text[:500] + "..."
            print(f"[info] Claude result: {shown}")
            return parsed

    print(f"[warn] No type='result' line found in {stream_path}", file=sys.stderr)
    return None


def extract_cost(result: Optional[dict]) -> float:
    if not result:
        return 0.0
    try:
        return float(result.get("total_cost_usd", 0.0) or 0.0)
    except (TypeError, ValueError):
        return 0.0


def extract_tokens(result: Optional[dict]) -> tuple[int, int, int, int]:
    """``(input, output, cache_read, cache_creation)``; output includes thinking."""
    if not result:
        return 0, 0, 0, 0
    usage = result.get("usage") or {}
    try:
        return (
            int(usage.get("input_tokens", 0) or 0),
            int(usage.get("output_tokens", 0) or 0),
            int(usage.get("cache_read_input_tokens", 0) or 0),
            int(usage.get("cache_creation_input_tokens", 0) or 0),
        )
    except (TypeError, ValueError):
        return 0, 0, 0, 0


def new_stream_path(base: Path, label: str) -> Path:
    return base / f"{label}_{uuid.uuid4().hex[:8]}.jsonl"
