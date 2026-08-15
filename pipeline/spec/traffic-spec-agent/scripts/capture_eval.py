"""Compare the library's verdicts on a captured trace against human labels.

This is the only check in the pipeline that does not depend on the agent that
wrote the specification. A rule's declared `scenarios` are authored by the same
plan agent that chose the formalization, so a misread clause yields scenarios
that agree with the misreading and the gate still prints `OK`. A capture labelled
by a person breaks that loop: the trace comes from CARLA, the verdict comes from
the spec, and the expectation comes from someone who watched the footage.

Label file (one per capture), granularity: one verdict per law per capture.

    {
      "capture": "sceneflow_sample",
      "annotator": "who labelled it, and from what evidence",
      "labels": [
        {"law": "EX-LANE-001", "verdict": "compliant", "note": "rightmost lane"},
        {"law": "EX-JUNCTION-001", "verdict": "not_applicable",
         "note": "no junction in this capture"}
      ]
    }

`not_applicable` is not a formality. A law whose situation never arises in a
capture is untested by it, and recording that as agreement would let a benchmark
of vacuous rules report a perfect score.
"""

from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

# Label vocabulary. `not_applicable` means the law's antecedent never arises in
# this capture, which is a claim about the footage, not about the spec.
VERDICTS = ("compliant", "violated", "not_applicable")

# Outcomes of comparing one law's spec verdict with its label.
AGREE = "ok"
FALSE_POSITIVE = "FALSE POSITIVE"      # lawful footage reported as a violation
MISSED = "MISSED VIOLATION"            # unlawful footage reported as compliant
UNTESTED = "UNTESTED"                  # spec grounds 0 times, label says engaged
SPURIOUS = "SPURIOUS GROUNDING"        # label says not engaged, spec grounded
NOT_FORMALIZED = "NO RULE"             # no rule in the library covers this law


@dataclass
class LawOutcome:
    law: str
    label: str
    spec: str
    groundings: int
    status: str
    nodes: list[str]
    note: str

    @property
    def is_disagreement(self) -> bool:
        return self.status not in (AGREE, NOT_FORMALIZED)


def load_labels(path: Path) -> tuple[str, str, dict[str, dict]]:
    """Read a label file, returning (capture name, annotator, law -> label)."""
    data = json.loads(path.read_text(encoding="utf-8"))
    labels: dict[str, dict] = {}
    for entry in data.get("labels", []):
        law = entry.get("law")
        verdict = entry.get("verdict")
        if not law:
            raise ValueError(f"{path}: a label entry has no `law` field")
        if verdict not in VERDICTS:
            raise ValueError(
                f"{path}: law {law} has verdict {verdict!r}; expected one of "
                f"{', '.join(VERDICTS)}"
            )
        if law in labels:
            raise ValueError(f"{path}: law {law} is labelled twice")
        labels[law] = entry
    if not labels:
        raise ValueError(f"{path}: no labels found")
    return data.get("capture", path.stem), data.get("annotator", "unknown"), labels


def parse_capture_report(output: str) -> tuple[int, list[dict]]:
    """Parse the `FRAMES` / `CAP` lines emitted by the capture harness."""
    frames = 0
    rows: list[dict] = []
    for line in output.splitlines():
        parts = line.rstrip("\n").split("\t")
        if parts[0] == "FRAMES" and len(parts) >= 2:
            frames = int(parts[1])
        elif parts[0] == "CAP" and len(parts) >= 5:
            rows.append({
                "node_id": parts[1],
                "law_refs": [r for r in parts[2].split(",") if r],
                "groundings": int(parts[3]),
                "holds": parts[4].strip() == "true",
            })
    return frames, rows


def spec_verdict(rows: list[dict]) -> tuple[str, int, list[str]]:
    """Aggregate the rules covering one law into a single verdict.

    A law may be carried by several rules (a decomposed clause), and it counts as
    violated if *any* of them is violated. Groundings are summed: the law is
    `not_applicable` from the spec's point of view only when no rule grounded at
    all, because a rule that grounds zero times has said nothing.
    """
    if not rows:
        return "no_rule", 0, []
    total = sum(r["groundings"] for r in rows)
    nodes = [r["node_id"] for r in rows]
    if total == 0:
        return "not_applicable", 0, nodes
    engaged = [r for r in rows if r["groundings"] > 0]
    if any(not r["holds"] for r in engaged):
        return "violated", total, nodes
    return "compliant", total, nodes


def classify(label: str, spec: str) -> str:
    if spec == "no_rule":
        return NOT_FORMALIZED
    if label == spec:
        return AGREE
    if label == "compliant" and spec == "violated":
        return FALSE_POSITIVE
    if label == "violated" and spec == "compliant":
        return MISSED
    if label in ("compliant", "violated") and spec == "not_applicable":
        return UNTESTED
    if label == "not_applicable":
        return SPURIOUS
    return "MISMATCH"


def evaluate(labels: dict[str, dict], rows: list[dict]) -> list[LawOutcome]:
    """One outcome per labelled law, in label-file order."""
    outcomes: list[LawOutcome] = []
    for law, entry in labels.items():
        covering = [r for r in rows if law in r["law_refs"]]
        spec, groundings, nodes = spec_verdict(covering)
        outcomes.append(LawOutcome(
            law=law,
            label=entry["verdict"],
            spec=spec,
            groundings=groundings,
            status=classify(entry["verdict"], spec),
            nodes=nodes,
            note=entry.get("note", ""),
        ))
    return outcomes


def unlabelled_rules(labels: dict[str, dict], rows: list[dict]) -> list[str]:
    """Law ids the library has rules for but the label file does not mention.

    Reported rather than ignored: an unlabelled law is a hole in the ground
    truth, and silently dropping it makes the agreement score look better than
    the annotation actually supports.
    """
    covered = {ref for r in rows for ref in r["law_refs"]}
    return sorted(covered - set(labels))


def format_report(capture: str, annotator: str, frames: int,
                  outcomes: list[LawOutcome], missing: list[str]) -> str:
    lines = [
        f"capture   : {capture}  ({frames} frames)",
        f"annotator : {annotator}",
        "",
        f"{'law':<20} {'human':<16} {'spec':<16} {'grnd':>5}  status",
        f"{'-' * 20} {'-' * 16} {'-' * 16} {'-' * 5}  {'-' * 20}",
    ]
    for o in outcomes:
        lines.append(f"{o.law:<20} {o.label:<16} {o.spec:<16} {o.groundings:>5}  "
                     f"{o.status}")
    agreed = [o for o in outcomes if o.status == AGREE]
    disagreed = [o for o in outcomes if o.is_disagreement]
    norule = [o for o in outcomes if o.status == NOT_FORMALIZED]
    tested = [o for o in outcomes
              if o.label in ("compliant", "violated") and o.groundings > 0]

    comparable = len(outcomes) - len(norule)
    lines += [
        "",
        f"{len(agreed)}/{comparable} comparable laws agree with the human labels "
        f"({len(disagreed)} disagree, {len(norule)} have no rule yet and are "
        f"neither).",
        f"{len(tested)}/{len(outcomes)} laws are actually exercised by this "
        f"capture (labelled engaged AND grounded); the rest are untested by it, "
        f"so the agreement figure above is weaker than it looks.",
    ]
    if norule:
        lines.append(f"no rule yet for: {', '.join(o.law for o in norule)} "
                     f"— run the loop to formalize these, then re-run monitor.")
    if missing:
        lines.append(f"rules exist but no human label: {', '.join(missing)} "
                     f"— annotate these or the score is incomplete.")
    if disagreed:
        lines += ["", "Disagreements — each is a finding, not a nuisance:"]
        for o in disagreed:
            detail = {
                FALSE_POSITIVE: "the footage is lawful but the spec reports a "
                                "violation; the formalization is too strict or "
                                "reads the wrong field",
                MISSED: "the footage breaks the law but the spec is satisfied; "
                        "the formalization is too weak",
                UNTESTED: "the label says this law is engaged in the footage, but "
                          "the rule grounds zero times — its binders or antecedent "
                          "do not match the capture",
                SPURIOUS: "the label says this law is not engaged, but the rule "
                          "grounded; check whether the label or the binders are wrong",
            }.get(o.status, "verdicts differ")
            lines.append(f"  - {o.law} [{', '.join(o.nodes) or 'no rule'}]: {detail}")
            if o.note:
                lines.append(f"      human note: {o.note}")
    return "\n".join(lines)
