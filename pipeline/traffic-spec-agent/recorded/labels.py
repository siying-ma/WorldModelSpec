"""A recording's label, read under the label contract.

Reason: training compares a law's verdict with a label, so what a label means (its verdict, the
road user it is about and the stretch of the recording it covers) must be stated once and carried
with every comparison.

The contract (v1, the only one): a label judges the subject's conduct (the trace's `subject`, one
track for the whole recording) over the whole recording; a violated label means the law's situation
was violated at least once, compliant that every occurrence complied, not applicable that it never
arose for the subject. A dataset (`DATASET.json`) or a recording's delivery metadata may state its
`label_contract`; anything stated other than v1 is refused, never read as v1.

A recorded label is read by `verdict_of`: `violation`, `violated` and `non_compliant` mean violated,
`compliant` compliant, `not applicable` and `not_applicable` not applicable; an empty or null label,
`unknown`, `inconclusive` and any label beginning with `unresolved` name no verdict (the recording is
unlabelled). Any other label is an error, never dropped silently.

A judgment call is a label whose verdict turns on a parameter value the pipeline chooses: it is
kept and reported with its verdict, but scored apart from the other labels.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass

VERDICTS = {"violation": "violated", "violated": "violated", "non_compliant": "violated",
            "compliant": "compliant",
            "not applicable": "not_applicable", "not_applicable": "not_applicable"}
#: Recorded labels that name no verdict (besides the empty label and any label beginning with `unresolved`).
NO_VERDICT = {"unknown", "inconclusive"}

#: The label contract, confirmed by the operator.
CONTRACT = {"subject": "ego", "scope": "whole recording", "provisional": False}


class LabelError(ValueError):
    pass


@dataclass(frozen=True)
class Label:
    law_id: str
    verdict: str | None          # violated, compliant, not_applicable; None: no explicit label
    recorded_label: str
    judgment_call: bool
    subject: str = CONTRACT["subject"]
    scope: str = CONTRACT["scope"]
    provisional: bool = CONTRACT["provisional"]

    def to_dict(self) -> dict:
        return asdict(self)


def require_v1(doc: dict, where: str) -> None:
    """Refuse (`ValueError`) a document whose `label_contract` is stated and is not v1 (the name
    `v1` or the contract itself); a document that states none follows v1."""
    if "label_contract" in doc and doc["label_contract"] not in ("v1", CONTRACT):
        raise LabelError(f"{where}: label contract {doc['label_contract']!r} is refused: only v1 (a label judges the "
                         "whole recording) is read")


def verdict_of(recorded_label: str | None) -> str | None:
    """The expected verdict of a recorded label; None for a label that names no verdict; `LabelError`
    for a label that is neither."""
    key = str(recorded_label or "").strip().lower()
    if key in VERDICTS:
        return VERDICTS[key]
    if not key or key in NO_VERDICT or key.startswith("unresolved"):
        return None
    raise LabelError(f"unrecognized label {recorded_label!r}: it is neither a verdict nor a label naming none")


def from_metadata(meta: dict, where: str = "metadata") -> Label:
    """A recording's label from its delivery metadata: `expected_label` (a string or null) and
    `judgment_sweep` (a boolean, the judgment-call flag). A contract other than v1, a missing or
    non-boolean flag, or an unrecognized label is refused (`LabelError`)."""
    require_v1(meta, where)
    raw = meta.get("expected_label")
    if raw is not None and not isinstance(raw, str):
        raise LabelError(f"{where}: expected_label {raw!r} is not a string or null")
    jc = meta.get("judgment_sweep")
    if not isinstance(jc, bool):
        raise LabelError(f"{where}: judgment_sweep {jc!r} is not a boolean")
    try:
        verdict = verdict_of(raw)
    except LabelError as e:
        raise LabelError(f"{where}: {e}") from None
    return Label(law_id=str(meta.get("law_id", "")), verdict=verdict, recorded_label=raw or "", judgment_call=jc)
