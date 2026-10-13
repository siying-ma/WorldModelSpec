"""Running Lean: `lake build`, standalone harness files, diagnostics."""
from __future__ import annotations
import re
import subprocess
from pathlib import Path
from typing import Optional


class LeanUnavailable(RuntimeError):
    pass


class library_lock:
    """One process at a time regenerates the registries, builds or runs Lean over the library:
    gates launched by parallel coding sessions serialize on this lock (a file lock, so it holds
    across processes), and the registries a gate writes are the ones its build sees."""
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


def run(cmd: list[str], cwd: Path, timeout: float) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError as exc:
        raise LeanUnavailable(f"could not run {cmd[0]!r}: {exc}; install the toolchain (bash setup.sh)") from exc
    except subprocess.TimeoutExpired as exc:              # what the process printed before it was stopped follows the first line
        partial = exc.stdout.decode("utf-8", "replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        return 124, f"TIMEOUT: {' '.join(cmd)} exceeded {timeout:.0f}s" + (f"\n{partial}" if partial else "")
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def lake_build(library: Path, targets: Optional[list[str]] = None, timeout: float = 1800.0) -> tuple[bool, str]:
    code, out = run(["lake", "build"] + (targets or []), library, timeout)
    return code == 0, out


def lean_run(library: Path, file: Path, timeout: float = 900.0) -> tuple[bool, str]:
    """Elaborate a standalone file and run its `main` (`lake env lean --run`)."""
    code, out = run(["lake", "env", "lean", "--run", str(file.resolve())], library, timeout)
    return code == 0, out


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
