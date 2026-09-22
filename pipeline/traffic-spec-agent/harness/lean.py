"""Running Lean: `lake build`, standalone harness files, diagnostics."""
from __future__ import annotations
import re
import subprocess
from pathlib import Path
from typing import Optional


class LeanUnavailable(RuntimeError):
    pass


def run(cmd: list[str], cwd: Path, timeout: float) -> tuple[int, str]:
    try:
        p = subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError as exc:
        raise LeanUnavailable(f"could not run {cmd[0]!r}: {exc}; install the toolchain (bash setup.sh)") from exc
    except subprocess.TimeoutExpired:
        return 124, f"TIMEOUT: {' '.join(cmd)} exceeded {timeout:.0f}s"
    return p.returncode, (p.stdout or "") + (p.stderr or "")


def lake_build(library: Path, targets: Optional[list[str]] = None, timeout: float = 1800.0) -> tuple[bool, str]:
    code, out = run(["lake", "build"] + (targets or []), library, timeout)
    return code == 0, out


def lean_run(library: Path, file: Path, timeout: float = 900.0) -> tuple[bool, str]:
    """Elaborate a standalone file and run its `main` (`lake env lean --run`)."""
    code, out = run(["lake", "env", "lean", "--run", str(file.resolve())], library, timeout)
    return code == 0, out


def errors(output: str) -> list[str]:
    return [l for l in output.splitlines() if re.search(r"\berror\b", l)]


def sorry_warnings(output: str) -> list[str]:
    return [l for l in output.splitlines() if "declaration uses 'sorry'" in l or "declaration uses `sorry`" in l]
