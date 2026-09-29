"""The result record and the vacuity guard every doctor check shares."""
from __future__ import annotations

from dataclasses import dataclass

OK, FAIL, SKIP = "ok", "FAIL", "skip"
#: A finding for the operator to decide: printed with its sources, never a failure of the doctor.
REVIEW = "review"


@dataclass
class Result:
    name: str
    status: str
    detail: str
    #: Where the two sides of the comparison live, so a failure is actionable
    #: without re-deriving what was compared.
    sources: tuple[str, ...] = ()


class VacuousCheck(RuntimeError):
    """A check extracted nothing, so it would have passed by finding nothing.

    This is the failure mode a comparison-based checker is most exposed to: a
    regex that stops matching because the file it reads was reformatted returns
    an empty set, an empty set is a subset of everything, and the check reports
    `ok`. Every extraction is therefore asserted non-empty first, so a broken
    extractor fails loudly instead of certifying silence.
    """


def _nonempty(value, what: str):
    """Return `value`, or raise if it is empty — see `VacuousCheck`."""
    if not value:
        raise VacuousCheck(f"extracted nothing for {what}; the extractor is "
                           f"broken or the file it reads has moved")
    return value
