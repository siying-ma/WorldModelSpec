"""Running Lean: `lake build`, standalone harness files, diagnostics."""
from __future__ import annotations
import re
import subprocess
from pathlib import Path
from typing import Optional


class LeanUnavailable(RuntimeError):
    pass


class library_lock:
    """One process at a time regenerates the registries and builds the library: gates launched by
    parallel coding sessions serialize on this lock (a file lock, so it holds across processes), and
    the registries a gate writes are the ones its build sees. Integration, which runs while no
    session codes, also runs its witnesses under it. No holder waits for the evaluation lock while
    it holds this one."""
    def __init__(self, library: Path):
        self.path = library / ".harness.lock"
        self.fh = None

    def __enter__(self):
        import fcntl
        self.fh = open(self.path, "w")
        fcntl.flock(self.fh, fcntl.LOCK_EX)
        return self

    def __exit__(self, *exc):
        import fcntl
        fcntl.flock(self.fh, fcntl.LOCK_UN)
        self.fh.close()
        return False


class evaluation_lock:
    """Every Lean evaluation run outside the library lock holds this lock shared, so evaluations run
    side by side; the isolated rerun of a gate's resource failure holds it exclusive, so it runs
    alone: it waits for the running evaluations to end and lets no new one start. Every holder
    passes a turnstile first, which an exclusive request keeps while it waits, since `flock` would
    otherwise let new shared holders in ahead of it."""
    def __init__(self, library: Path, exclusive: bool = False):
        self.turnstile = library / ".harness.turnstile.lock"
        self.path = library / ".harness.evaluation.lock"
        self.exclusive = exclusive
        self.fh = None

    def __enter__(self):
        import fcntl
        with open(self.turnstile, "w") as turn:
            fcntl.flock(turn, fcntl.LOCK_EX)
            self.fh = open(self.path, "w")
            fcntl.flock(self.fh, fcntl.LOCK_EX if self.exclusive else fcntl.LOCK_SH)
        return self

    def __exit__(self, *exc):
        import fcntl
        fcntl.flock(self.fh, fcntl.LOCK_UN)
        self.fh.close()
        return False


def run(cmd: list[str], cwd: Path, timeout: float) -> tuple[int, str]:
    """Run a toolchain command in its own process group, registered with the library's owner.
    Returns the exit code (negative: the signal that ended it; 124: the deadline, after which the
    whole group is ended) and what it printed."""
    import os
    import signal
    from ..store import owner
    try:
        p = subprocess.Popen(cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, start_new_session=True)
    except FileNotFoundError as exc:
        raise LeanUnavailable(f"could not run {cmd[0]!r}: {exc}; install the toolchain (bash setup.sh)") from exc
    owner.register(p.pid)
    try:
        out, _ = p.communicate(timeout=timeout)
    except subprocess.TimeoutExpired:                     # what the process printed before it was stopped follows the first line
        try:
            os.killpg(p.pid, signal.SIGKILL)
        except OSError:
            pass
        partial, _ = p.communicate()
        return 124, f"TIMEOUT: {' '.join(cmd)} exceeded {timeout:.0f}s" + (f"\n{partial}" if partial else "")
    finally:
        owner.unregister(p.pid)
    return p.returncode, out or ""


def lake_build(library: Path, targets: Optional[list[str]] = None, timeout: float = 1800.0) -> tuple[int, str]:
    """`lake build`: (exit code as `run` gives it, output)."""
    return run(["lake", "build"] + (targets or []), library, timeout)


def lean_run(library: Path, file: Path, timeout: float = 900.0) -> tuple[int, str]:
    """Elaborate a standalone file and run its `main` (`lake env lean --run`): (exit code as `run` gives it, output)."""
    return run(["lake", "env", "lean", "--run", str(file.resolve())], library, timeout)


#: What a Lean program prints when it panicked and went on with a default value.
PANIC = re.compile(r"^(PANIC at |INTERNAL PANIC|Error: index out of bounds|backtrace:$)", re.M)
STACK_OVERFLOW = re.compile(r"Stack overflow detected", re.I)


def panicked(output: str) -> list[str]:
    return [l for l in output.splitlines() if PANIC.match(l)][:3]


def error_sites(output: str) -> list[tuple[str, int, str]]:
    """Every located error: (the file as printed, its line, the message), from `lake build`
    (`error: <file>:<line>:<col>: …`) and from `lean` (`<file>:<line>:<col>: error: …`)."""
    out = []
    for l in output.splitlines():
        m = re.match(r"^error: (\S+\.lean):(\d+):\d+: (.*)", l) or re.match(r"^(\S+\.lean):(\d+):\d+: error: (.*)", l)
        if m:
            out.append((m.group(1), int(m.group(2)), m.group(3)))
    return out


def code_only(text: str) -> str:
    """The Lean source with every comment and string literal blanked to spaces: what a scan for a
    keyword or an attribute must look at. Line comments run from `--` to the end of the line,
    block comments `/- … -/` nest, and a string literal may contain escaped quotes."""
    out, i, n = [], 0, len(text)
    depth = 0
    while i < n:
        c = text[i]
        if depth:
            if text.startswith("/-", i):
                depth += 1; out.append("  "); i += 2
            elif text.startswith("-/", i):
                depth -= 1; out.append("  "); i += 2
            else:
                out.append("\n" if c == "\n" else " "); i += 1
            continue
        if text.startswith("/-", i):
            depth = 1; out.append("  "); i += 2
        elif text.startswith("--", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            out.append(" " * (j - i)); i = j
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            j = min(j + 1, n)
            out.append(" " * (j - i)); i = j
        else:
            out.append(c); i += 1
    return "".join(out)


def timed_out(output: str) -> bool:
    return output.startswith("TIMEOUT:")


def errors(output: str) -> list[str]:
    return [l for l in output.splitlines() if re.search(r"\berror\b", l)]


def sorry_warnings(output: str) -> list[str]:
    return [l for l in output.splitlines() if "declaration uses 'sorry'" in l or "declaration uses `sorry`" in l]
