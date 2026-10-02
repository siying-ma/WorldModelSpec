"""Claude Code invocation.

Adapted from cc-refactor-agent's `scripts/runner.py`: one `claude -p` session
per unit of work, NDJSON stream saved verbatim, usage parsed from the final
`type: "result"` line, and every live subprocess killed on SIGINT/SIGTERM so an
interrupted run does not leave orphans behind.
"""

from __future__ import annotations

import json
import os
import re
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


#: Every pipeline session runs with exactly the context its prompt gives it. Without these flags
#: a session inherits the developer's environment: the repository's CLAUDE.md (a working
#: agreement written for a human-driven session), the user's plugins and their MCP servers, and
#: every installed skill. `--setting-sources ""` loads no settings file and no CLAUDE.md,
#: `--strict-mcp-config` loads no MCP server, `--disable-slash-commands` loads no skill. The
#: account login is unaffected.
ISOLATION_FLAGS = ["--setting-sources", "", "--strict-mcp-config", "--disable-slash-commands"]
#: Every session acts under an allow-list and nothing else: the default permission mode with
#: nobody to answer a prompt, so any tool use the allow rules do not name is denied. A rule names
#: a tool and, for a file tool, an absolute path (`Read(//abs/dir/**)`) or, for the shell, one
#: exact command with no wildcard (a wildcard would also admit `command && anything`). Reading is
#: allowed anywhere inside the working directory whatever the rules say, so a session's working
#: directory holds only what it may read.
PERMISSION_FLAGS = ["--permission-mode", "default", "--permission-prompts", "none"]


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
    allow: Optional[list[str]] = None,
    deny: Optional[list[str]] = None,
    disallowed_tools: Optional[list[str]] = None,
) -> tuple[int, Optional[dict], bool]:
    """Run one headless Claude session.

    `allow` is the complete list of what the session may do (`Read(//abs/dir/**)`,
    `Write(//abs/file)`, `Bash(<one exact command>)`); every other tool use is denied. `deny`
    adds rules that hold even where a rule would allow; `disallowed_tools` removes tools outright.
    Returns ``(returncode, result_line, timed_out)`` where ``result_line`` is the parsed final
    ``type: "result"`` object, or ``None`` if the session produced none (crash, hard kill).
    """
    cmd = [
        "claude",
        "-p",
        "--verbose",
        "--output-format", "stream-json",
        *PERMISSION_FLAGS,
        "--max-turns", str(max_turns),
        *ISOLATION_FLAGS,
    ]
    if allow:
        cmd += ["--allowedTools", *allow]
    resolved = resolve_model(model)
    if resolved:
        cmd += ["--model", resolved]
    if effort:
        cmd += ["--effort", effort]
    if max_budget_usd is not None:
        cmd += ["--max-budget-usd", f"{max_budget_usd:.2f}"]
    if deny:
        cmd += ["--settings", json.dumps({"permissions": {"deny": list(deny)}})]
    if disallowed_tools:
        cmd += ["--disallowedTools", *disallowed_tools]

    # The prompt goes on STDIN, never in argv.
    #
    # `execve` caps a single argument at MAX_ARG_STRLEN (32 * PAGE_SIZE, 128 KiB
    # on Linux) and caps argv+envp together as well, so a prompt passed as the
    # last argument has a hard ceiling that nothing in this repo controls: the
    # rendered plan prompt grows with the corpus, the vocabulary, the schema and
    # the gap ledger. It crossed the line at 128,388 bytes and the run died with
    # `OSError: [Errno 7] Argument list too long` before its first session
    # started — no partial output, no retry, and nothing in the loop that could
    # have anticipated it. Stdin has no such limit.

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
            cmd, stdin=subprocess.PIPE, stdout=out, stderr=subprocess.STDOUT,
            text=True, env=env, cwd=str(cwd),
        )
        _register(proc)

        # Written from a thread: a pipe holds 64 KiB, and a prompt larger than
        # that blocks the writer until the child drains it. Writing inline would
        # deadlock any child that does something else first, and this one is not
        # ours to make assumptions about.
        def _feed() -> None:
            try:
                proc.stdin.write(prompt)
            except (BrokenPipeError, OSError):
                pass
            finally:
                try:
                    proc.stdin.close()
                except (BrokenPipeError, OSError):
                    pass

        feeder = threading.Thread(target=_feed, daemon=True)
        feeder.start()
        try:
            proc.wait(timeout=timeout_seconds)
        except subprocess.TimeoutExpired:
            timed_out = True
            print(f"[warn] Claude pid={proc.pid} exceeded timeout, killing...", file=sys.stderr)
            proc.kill()
            proc.wait()
        finally:
            feeder.join(timeout=5)
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


LIMIT_PATTERNS = (r"hit your (session|usage|weekly|daily) limit", r"rate limit", r"overloaded", r"usage limit",
                  r"credit balance", r"api error", r"invalid api key", r"authentication")


def session_failure(code: int, result: Optional[dict], timed_out: bool) -> Optional[str]:
    """Why the session did not run at all — an account limit, an API error, a crash — or None when
    it ran (however it went). A session that did not run must not count as an attempt."""
    if timed_out:
        return None                      # it ran and was cut off; its files are on disk
    if result is None:
        return f"no result line (exit code {code})"
    text = str(result.get("result", "") or "")
    turns = int(result.get("num_turns", 0) or 0)
    usage = result.get("usage") or {}
    if result.get("is_error") and any(re.search(p, text, re.I) for p in LIMIT_PATTERNS):
        return f"session refused: {text[:200]}"
    if result.get("is_error") and turns <= 1:
        return f"session errored before working: {text[:200]}"
    if turns <= 1 and not int(usage.get("output_tokens", 0) or 0):
        return f"session produced nothing: {text[:200] or result.get('subtype')}"
    return None


def reset_hint(reason: str) -> str:
    m = re.search(r"resets? ([^\n]+)", reason)
    return m.group(1).strip() if m else ""


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
