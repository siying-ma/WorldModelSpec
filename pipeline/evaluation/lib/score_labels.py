"""Compare the monitor's verdicts with a dataset's labels.

    python3 score_labels.py <cases.csv> <reports dir> <registered.json>

`cases.csv` gives each case its target law and expected label (`compliant`, `non_compliant`,
`not_applicable`, or `unlabeled_judgment`, which is reported and not scored). A report is the
monitor's JSON lines for one case (`<reports dir>/<case_id>.jsonl`); `registered.json` maps every
registered rule to the law it formalizes. A rule's verdict on a case joins its groundings' episode
verdicts, and a law's verdict joins its rules': violated if any is violated, else unknown if any is
unknown, else compliant if any is compliant, else not applicable. A rule with no grounding on the
case is not applicable to it; an unsupported rule is unknown. A law is marked surrogate when one of
its rules is (the monitor keeps such rules out of its concrete tallies). A case whose target law has
no registered rule, or whose report is missing, is listed and not scored.
"""
from __future__ import annotations

import csv
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

ORDER = ("violated", "unknown", "compliant", "not_applicable")
EXPECTED = {"compliant": "compliant", "non_compliant": "violated", "not_applicable": "not_applicable"}


def join(verdicts) -> str:
    vs = set(verdicts)
    return next((v for v in ORDER if v in vs), "not_applicable")


def rule_verdicts(report: Path) -> dict[str, tuple[str, bool]]:
    """Each rule of a report: its joined episode verdict ("unknown" when unsupported) and whether
    it is a surrogate."""
    rows, support, surrogate = defaultdict(list), {}, {}
    for line in report.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        d = json.loads(line)
        if d["kind"] == "rule":
            support[d["rule"]] = d["support"]
            surrogate[d["rule"]] = d["surrogate"]
        elif d["kind"] == "grounding":
            rows[d["rule"]].append(d["episode"]["verdict"])
    return {r: ("unknown" if s == "unsupported" else join(rows[r]), surrogate[r]) for r, s in support.items()}


def main(cases_csv: Path, reports: Path, registered: Path) -> None:
    law_of = {r: v["law"] for r, v in json.loads(registered.read_text(encoding="utf-8"))["rules"].items()}
    scored, confusion, unscored = Counter(), Counter(), []
    print("case\ttarget law\texpected\tgot\tmatch\tsurrogate\tother laws")
    for row in csv.DictReader(cases_csv.open(encoding="utf-8")):
        case, law, label = row["case_id"], row["law_id"], row["expected_label"]
        report = reports / f"{case}.jsonl"
        if not report.exists() or not report.stat().st_size:
            unscored.append(f"{case}: no report"); continue
        by_law, surrogate = defaultdict(list), set()
        for rule, (v, sur) in rule_verdicts(report).items():
            by_law[law_of.get(rule, rule)].append(v)
            if sur:
                surrogate.add(law_of.get(rule, rule))
        laws = {l: join(vs) for l, vs in by_law.items()}
        others = ", ".join(f"{l}={v}" for l, v in sorted(laws.items()) if l != law)
        if law not in laws:
            unscored.append(f"{case}: no rule for {law}")
            print(f"{case}\t{law}\t{label}\t-\t-\t-\t{others}"); continue
        got, sur = laws[law], "yes" if law in surrogate else "no"
        if label in EXPECTED:
            ok = got == EXPECTED[label]
            scored[law, ok] += 1; confusion[label, got] += 1
            print(f"{case}\t{law}\t{label}\t{got}\t{'yes' if ok else 'NO'}\t{sur}\t{others}")
        else:
            print(f"{case}\t{law}\t{label}\t{got}\t-\t{sur}\t{others}")
    print("\n== per law: matched / scored")
    for law in sorted({l for l, _ in scored}):
        print(f"{law}\t{scored[law, True]} / {scored[law, True] + scored[law, False]}")
    total = sum(scored.values())
    print(f"all\t{sum(n for (_, ok), n in scored.items() if ok)} / {total}")
    print("\n== expected -> got")
    for (label, got), n in sorted(confusion.items()):
        print(f"{label}\t{got}\t{n}")
    if unscored:
        print(f"\n== not scored ({len(unscored)})")
        print("\n".join(unscored))


if __name__ == "__main__":
    main(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
