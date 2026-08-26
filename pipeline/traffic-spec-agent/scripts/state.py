"""Loop state: PROGRESS.md, iteration directories, and the shared context.

Deliberately small. `PROGRESS.md` carries one machine-read field — the stage —
and is otherwise a human-readable log the plan agent appends to.
"""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

STAGES = ("formalize", "COMPLETE")
STAGE_RE = re.compile(r"^\s*-?\s*\*?\*?stage\*?\*?\s*:\s*([A-Za-z_]+)", re.M | re.I)

PROGRESS_TEMPLATE = """# PROGRESS

- stage: formalize

## Coverage

<!-- The plan agent maintains this table: one row per law id in the corpus,
     with status `pending`, `formalized`, `partial`, or `unsupported`.
     `unsupported` MUST name the scene-graph field the law needs and CARLA
     does not provide. -->

| law id | status | node(s) | note |
|--------|--------|---------|------|

## Log

<!-- One short entry per iteration. Newest last. -->
"""

USER_HINTS_TEMPLATE = """# USER HINTS

<!-- Anything you write under "Temporary hints" is injected into the next plan
     agent session and then cleared. Anything under "Persistent hints" is
     injected every iteration and never cleared. -->

## Temporary hints

## Persistent hints
"""


def init_state_dir(state_dir: Path) -> None:
    state_dir.mkdir(parents=True, exist_ok=True)
    progress = state_dir / "PROGRESS.md"
    if not progress.exists():
        progress.write_text(PROGRESS_TEMPLATE, encoding="utf-8")
    hints = state_dir / "USER_HINTS.md"
    if not hints.exists():
        hints.write_text(USER_HINTS_TEMPLATE, encoding="utf-8")
    auto = state_dir / "AUTO_NOTES.md"
    if not auto.exists():
        auto.write_text("", encoding="utf-8")


def read_stage(progress_file: Path, override: Optional[str] = None) -> str:
    if override:
        return override
    if not progress_file.exists():
        return "formalize"
    m = STAGE_RE.search(progress_file.read_text(encoding="utf-8"))
    if not m:
        return "formalize"
    stage = m.group(1)
    return stage if stage in STAGES else "formalize"


def write_stage(progress_file: Path, stage: str) -> None:
    text = progress_file.read_text(encoding="utf-8") if progress_file.exists() else PROGRESS_TEMPLATE
    if STAGE_RE.search(text):
        text = STAGE_RE.sub(f"- stage: {stage}", text, count=1)
    else:
        text = f"# PROGRESS\n\n- stage: {stage}\n\n" + text
    progress_file.write_text(text, encoding="utf-8")


def append_log(progress_file: Path, line: str) -> None:
    """Append an iteration entry under `## Log`."""
    text = progress_file.read_text(encoding="utf-8") if progress_file.exists() else PROGRESS_TEMPLATE
    if "## Log" not in text:
        text += "\n## Log\n"
    text = text.rstrip() + f"\n- {line}\n"
    progress_file.write_text(text, encoding="utf-8")


def next_iter_num(state_dir: Path) -> int:
    existing = [
        int(p.name.split("_")[1])
        for p in state_dir.glob("iter_*")
        if p.is_dir() and p.name.split("_")[-1].isdigit()
    ]
    return (max(existing) + 1) if existing else 1


def capture_and_clear(path: Path, preserve_marker: Optional[str] = None) -> Optional[str]:
    """Read a feedback file, then clear it.

    The read and the clear are separate calls in the phase code so a crashed
    phase leaves the file intact for the retry; this helper only performs the
    read. Use :func:`clear_feedback` after the phase succeeds.
    """
    if not path.is_file():
        return None
    try:
        return path.read_text(encoding="utf-8")
    except OSError:
        return None


def clear_auto_notes(path: Path) -> None:
    try:
        path.write_text("", encoding="utf-8")
    except OSError:
        pass


def clear_temporary_hints(path: Path) -> None:
    """Reset `## Temporary hints`, preserving `## Persistent hints` verbatim."""
    if not path.is_file():
        return
    text = path.read_text(encoding="utf-8")
    marker = "## Persistent hints"
    idx = text.find(marker)
    if idx == -1:
        path.write_text(USER_HINTS_TEMPLATE, encoding="utf-8")
        return
    persistent = text[idx:]
    template_idx = USER_HINTS_TEMPLATE.find(marker)
    path.write_text(USER_HINTS_TEMPLATE[:template_idx] + persistent, encoding="utf-8")


@dataclass
class LoopOptions:
    max_iterations: int = 3
    max_nodes_per_iter: int = 8
    max_turns: int = 60
    timeout_minutes: Optional[float] = 45
    model: Optional[str] = None
    effort: Optional[str] = None
    max_budget_usd: Optional[float] = None
    from_phase: Optional[str] = None     # "plan" | "code" | "integrate"
    force_stage: Optional[str] = None
    dry_run: bool = False


@dataclass
class LoopContext:
    repo_root: Path
    library_root: Path
    laws_file: Path
    state_dir: Path
    results_dir: Path
    prompts_dir: Path
    options: LoopOptions
    iter_num: int = 0
    stage: str = "formalize"
    skip_now: set[str] = field(default_factory=set)

    @property
    def progress_file(self) -> Path:
        return self.state_dir / "PROGRESS.md"

    @property
    def hints_file(self) -> Path:
        return self.state_dir / "USER_HINTS.md"

    @property
    def auto_notes_file(self) -> Path:
        return self.state_dir / "AUTO_NOTES.md"

    @property
    def iter_dir(self) -> Path:
        return self.state_dir / f"iter_{self.iter_num:03d}"

    @property
    def objectives_file(self) -> Path:
        return self.iter_dir / "objectives.jsonl"

    @property
    def plan_file(self) -> Path:
        return self.iter_dir / "PLAN.md"

    @property
    def nodes_dir(self) -> Path:
        return self.results_dir / f"iter_{self.iter_num:03d}" / "nodes"

    @property
    def meta_file(self) -> Path:
        return self.iter_dir / "meta.json"

    def write_meta(self, **kv) -> None:
        self.iter_dir.mkdir(parents=True, exist_ok=True)
        data = {}
        if self.meta_file.exists():
            try:
                data = json.loads(self.meta_file.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                data = {}
        data.update(kv)
        self.meta_file.write_text(
            json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8"
        )
