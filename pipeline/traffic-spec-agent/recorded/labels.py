"""A recording's label, read under the label contract.

Reason: training compares a law's verdict with a label, so what a label means (its verdict, the
road user it is about and the stretch of the recording it covers) must be stated once and carried
with every comparison.

Two contracts exist; a dataset states which one its labels follow (`DATASET.json`,
`label_contract`), and a dataset that states none follows v1.

- v1 (`CONTRACT`): a label judges the subject's conduct (the trace's `subject`, one track for the
  whole recording) over the whole recording; `violation` means the law's situation was violated
  at least once, `compliant` that every occurrence complied, `not applicable` that it never arose
  for the subject.
- v2 (`CONTRACT_V2`): the same verdicts and the same subject, judged over the label's scoring
  interval only. The interval is chosen by the scenario design, never by a rule, a reading or a
  repair, and never guessed: a closed interval `[start_ms, end_ms]` of integer milliseconds on the
  trace's clock (its scenes' `t`), both ends the times of observations of the trace, at least one
  observation inside. The whole trace is still evaluated (what lies before the interval is
  history, what lies after is context); only the verdicts at observations inside it are joined. A
  v2 `label.json` states, beside `law_id`, `recorded_label` and `judgment_call`:
  `label_contract: "v2"`, `subject: "ego"`, and `scoring_interval: {start_ms, end_ms, source,
  confirmed}`, where `source` names the scenario design the interval comes from and `confirmed`
  is `true` when the data producer confirms that the label's verdict holds for exactly that
  interval. A label whose interval is missing, malformed, outside the trace, not on observations
  or unconfirmed has a defect (`interval_defect`): it keeps its place among the labels, unverified,
  and is never compared.

A judgment call is a label whose verdict turns on a parameter value the pipeline chooses: it is
kept and reported with its verdict, but scored apart from the other labels.
"""
from __future__ import annotations

import json
from bisect import bisect_left
from dataclasses import asdict, dataclass
from pathlib import Path

VERDICTS = {"violation": "violated", "violated": "violated", "compliant": "compliant",
            "not applicable": "not_applicable", "not_applicable": "not_applicable"}

#: The label contract v1 (whole recording), confirmed by the operator.
CONTRACT = {"subject": "ego", "scope": "whole recording", "provisional": False}
#: The label contract v2 (a scoring interval per label, chosen by the scenario design).
CONTRACT_V2 = {"version": "v2", "subject": "ego", "scope": "scoring interval",
               "interval": "closed [start_ms, end_ms], integer ms on the trace clock, both ends observations",
               "provisional": False}
CONTRACTS = {"v1": CONTRACT, "v2": CONTRACT_V2}


def contract_of(stated) -> str:
    """The contract a dataset's `label_contract` names: v1 when it states none; an unknown contract
    is refused, never read as either."""
    if stated is None or stated == CONTRACT:
        return "v1"
    if stated == CONTRACT_V2:
        return "v2"
    raise ValueError(f"unknown label contract {stated!r}")


@dataclass(frozen=True)
class Interval:
    start_ms: int
    end_ms: int
    source: str
    confirmed: bool


@dataclass(frozen=True)
class Label:
    law_id: str
    verdict: str | None          # violated, compliant, not_applicable; None: no explicit label
    recorded_label: str
    judgment_call: bool
    subject: str = CONTRACT["subject"]
    scope: str = CONTRACT["scope"]
    provisional: bool = CONTRACT["provisional"]
    contract: str = "v1"
    interval: Interval | None = None     # v2 only, when the label states a well-formed one
    defect: str | None = None            # v2 only: why the label's interval cannot be used, before the trace is read

    def to_dict(self) -> dict:
        return asdict(self)


def verdict_of(recorded_label: str) -> str | None:
    """The expected verdict of a recorded label; None for anything that names no verdict."""
    return VERDICTS.get(str(recorded_label or "").strip().lower())


def _int(x) -> bool:
    return isinstance(x, int) and not isinstance(x, bool)


def _interval(d: dict) -> tuple[Interval | None, str | None]:
    """The scoring interval a v2 label states, or the defect that makes it unusable."""
    if d.get("label_contract") != "v2":
        return None, "the label does not state label contract v2"
    if d.get("subject") != CONTRACT_V2["subject"]:
        return None, f"the label's subject is {d.get('subject')!r}, not {CONTRACT_V2['subject']!r} (the trace's subject)"
    si = d.get("scoring_interval")
    if si is None:
        return None, "the label has no scoring interval"
    if not isinstance(si, dict):
        return None, "the scoring interval is not an object"
    s, e = si.get("start_ms"), si.get("end_ms")
    if not (_int(s) and _int(e)):
        return None, "start_ms and end_ms must be integer milliseconds"
    if s > e:
        return None, f"the scoring interval is empty: start_ms {s} > end_ms {e}"
    src = si.get("source")
    if not isinstance(src, str) or not src.strip():
        return None, "the scoring interval names no scenario-design source"
    iv = Interval(s, e, src, si.get("confirmed") is True)
    if not iv.confirmed:
        return iv, "the data producer has not confirmed the label's verdict for exactly this interval"
    return iv, None


def parse(label_json: bytes | str | dict, contract: str = "v1") -> Label:
    """A `label.json` document as a Label under `contract` (v1 or v2)."""
    if contract not in CONTRACTS:
        raise ValueError(f"unknown label contract {contract!r}")
    d = label_json if isinstance(label_json, dict) else json.loads(label_json)
    jc = d.get("judgment_call")
    base = dict(law_id=d.get("law_id", ""), verdict=verdict_of(d.get("recorded_label", "")),
                recorded_label=str(d.get("recorded_label", "")),
                judgment_call=jc if isinstance(jc, bool) else str(jc).strip().lower() == "true")
    if contract == "v1":
        return Label(**base)
    iv, defect = _interval(d)
    return Label(**base, scope=CONTRACT_V2["scope"], contract="v2", interval=iv, defect=defect)


def observation_times(trace: str | Path) -> list[int]:
    """The times (ms) of a trace's observations, in trace order."""
    return [s["t"] for s in json.loads(Path(trace).read_text(encoding="utf-8"))["scenes"]]


def interval_defect(lab: Label, times: list[int], law_id: str | None = None) -> str | None:
    """Why a v2 label cannot be scored on a trace whose observation times are `times` (sorted), or
    None: the label's own defect (an empty interval among them), a law other than `law_id`, an end
    outside the trace, or an end at no observation."""
    if lab.contract != "v2":
        return None
    if lab.defect:
        return lab.defect
    if law_id is not None and lab.law_id != law_id:
        return f"the label names law {lab.law_id!r}, the recording is filed under {law_id!r}"
    iv = lab.interval
    if not times:
        return "the trace has no observation"
    if iv.start_ms < times[0] or iv.end_ms > times[-1]:
        return f"the scoring interval [{iv.start_ms}, {iv.end_ms}] ms leaves the trace [{times[0]}, {times[-1]}] ms"
    off = [x for x in (iv.start_ms, iv.end_ms) if times[min(bisect_left(times, x), len(times) - 1)] != x]
    if off:
        return f"the scoring interval's end(s) {off} ms fall on no observation"
    return None                       # both ends are observations and start <= end: one at least is inside
