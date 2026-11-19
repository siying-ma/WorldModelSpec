"""Run a verifier package on every recorded case of a dataset and compare each law verdict with the
case's label.

    python3 evaluate_cases.py PACKAGE CASES [--case GLOB] [--law ID ...] [--rule ID ...]
                              [--explain none|violations|all] [--timeout S] [--jobs N] [--out FILE.jsonl]

PACKAGE is a built verifier package (e.g. `smoke25`, after its `./install.sh`). CASES is a directory
with one sub-directory per recording, holding `trace.json`, `manifest.json` (optional: without it
every atom is taken as observed) and `label.json` (optional). A label names the law it is about
(`law_id`) and the expected verdict (`recorded_label`: `compliant`, `violation` or `not applicable`;
anything else is no label).

Every case selected gets one status, so the denominator is fixed:

| status | meaning |
|---|---|
| `match` | the law's verdict equals the label |
| `mismatch` | the law's verdict is decided and differs from the label |
| `unknown` | the law's verdict is unknown (the trace does not supply what it turns on) |
| `undecided` | a rule of the law passed the deadline or the monitor failed |
| `no_rule` | the package holds no rule of the labelled law |
| `unlabelled` | the case has no label (its verdict is still reported) |

A case whose law the package verifies only under an approved abstraction (the law's
`partial_coverage`) keeps its status, and is marked `partial` in the table and its JSON line; its
agreement is reported apart, never as full statutory compliance. A case marked `full` is complete
within the approved task scope (scope readings are disclosed in the rule's reading); not a
word-by-word verification of every qualifier of the statute.

Each case's full report (verdicts, violated intervals, explanations) is written as one JSON line to
`--out` (default `evaluation_<package>.jsonl` in the current directory), keyed by the case directory
name, which is unique. The case directories are only read.
"""
from __future__ import annotations

import argparse
import fnmatch
import json
import sys
from collections import Counter
from pathlib import Path

LABELS = {"compliant": "compliant", "violation": "violated", "not applicable": "not_applicable"}


def label_of(case: Path) -> tuple[str | None, str | None]:
    """(law id, expected verdict) from `label.json`; (law id or None, None) when there is no label."""
    f = case / "label.json"
    if not f.exists():
        return None, None
    d = json.loads(f.read_text(encoding="utf-8"))
    return d.get("law_id"), LABELS.get(str(d.get("recorded_label", "")).strip().lower())


def status(law: str | None, expected: str | None, laws: dict) -> tuple[str, str | None]:
    """The case's status and the law's verdict."""
    verdict = laws.get(law, {}).get("verdict") if law else None
    if expected is None:
        return "unlabelled", verdict
    if law not in laws:
        return "no_rule", None
    if verdict in ("unknown", "undecided"):
        return verdict, verdict
    return ("match" if verdict == expected else "mismatch"), verdict


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="Evaluate a verifier package on a directory of recorded cases.")
    ap.add_argument("package", type=Path, help="a built verifier package directory")
    ap.add_argument("cases", type=Path, help="a directory of case directories (trace.json, manifest.json, label.json)")
    ap.add_argument("--case", default="*", help="only case directories whose name matches this glob")
    ap.add_argument("--law", action="append", dest="law_ids", help="check only this law id (repeatable)")
    ap.add_argument("--rule", action="append", dest="rules", help="check only this rule id (repeatable)")
    ap.add_argument("--explain", choices=("none", "violations", "all"), default="violations",
                    help="none; violations (default): why each violated grounding fails; all: every grounding")
    ap.add_argument("--timeout", type=float, default=600, help="seconds per rule (default 600)")
    ap.add_argument("--jobs", type=int, default=2, help="rules monitored at once per case (default 2)")
    ap.add_argument("--out", type=Path, help="JSON lines of the full reports")
    a = ap.parse_args(argv)

    pkg = a.package.resolve()
    sys.path.insert(0, str(pkg))
    from traffic_verifier import VerifierError, verify   # the package's own API

    cases = sorted(d for d in a.cases.iterdir() if d.is_dir() and (d / "trace.json").exists() and fnmatch.fnmatch(d.name, a.case))
    if not cases:
        print(f"no case directory with a trace.json matches {a.case!r} under {a.cases}", file=sys.stderr)
        return 2
    out = a.out or Path(f"evaluation_{pkg.name}.jsonl")
    explain = {"none": False, "violations": True, "all": "all"}[a.explain]
    tally: Counter = Counter()
    partial: Counter = Counter()
    print(f"{'case':<48} {'law':<18} {'label':<15} {'verdict':<15} {'status':<10} coverage")
    with out.open("w", encoding="utf-8") as f:
        for case in cases:
            law, expected = label_of(case)
            manifest = case / "manifest.json"
            try:
                rep = verify(case / "trace.json", manifest if manifest.exists() else None, rules=a.rules,
                             law_ids=a.law_ids, timeout=a.timeout, jobs=a.jobs, explain=explain)
                st, verdict = status(law, expected, rep["laws"])
            except (VerifierError, ValueError, OSError) as e:
                rep, st, verdict = {"error": str(e)}, "undecided", None
            part = bool(law and (rep.get("laws", {}).get(law) or {}).get("partial_coverage"))
            (partial if part else tally)[st] += 1
            print(f"{case.name[:48]:<48} {str(law):<18} {str(expected):<15} {str(verdict):<15} {st:<10} {'partial' if part else 'full'}")
            f.write(json.dumps({"case": case.name, "law": law, "label": expected, "verdict": verdict,
                                "status": st, "partial_coverage": part, "report": rep}) + "\n")
    labelled = sum(v for k, v in tally.items() if k != "unlabelled")
    print()
    print(f"{len(cases)} case(s): " + ", ".join(f"{k} {v}" for k, v in sorted((tally + partial).items())))
    if labelled:
        print(f"labelled agreement: {tally['match']}/{labelled} (every labelled case counts: unknown, undecided and no_rule are not matches)")
    plabelled = sum(v for k, v in partial.items() if k != "unlabelled")
    if plabelled:
        print(f"partial coverage, apart (an approved abstraction, not full statutory compliance): {partial['match']}/{plabelled}")
    print(f"full reports: {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
