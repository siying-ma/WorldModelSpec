"""Phase base class.

A phase reads and writes the shared `LoopContext` and reports back whether it
ran, and whether the loop should stop. Modelled on Archon's
`archon.commands.loop.phases.base`, minus the parts that only matter at
repository scale.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import ClassVar

from ..state import LoopContext


@dataclass
class PhaseResult:
    skipped: bool = False
    completed: bool = False          # nothing left to do — break the outer loop
    blocked: bool = False            # this iteration cannot continue past this phase
    notes: list[str] = field(default_factory=list)   # feedback for the planner


class Phase(ABC):
    name: ClassVar[str] = ""
    number: ClassVar[int] = 0
    token: ClassVar[str] = ""

    def __init__(self, ctx: LoopContext) -> None:
        self.ctx = ctx

    def header(self) -> None:
        print(f"\n{'=' * 72}")
        print(f"[phase {self.number}] {self.name}  (iter {self.ctx.iter_num:03d})")
        print(f"{'=' * 72}")

    def should_skip(self) -> bool:
        return self.token in self.ctx.skip_now

    @abstractmethod
    def run(self) -> PhaseResult:
        ...
