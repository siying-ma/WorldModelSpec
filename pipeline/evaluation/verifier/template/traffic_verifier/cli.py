"""verify TRACE [--manifest M] [--law ID ...] [--rule ID ...] [--timeout S] [--jobs N] [--json]

Exit status: 0 when no law is violated, 1 when at least one is, 2 on an error."""
from __future__ import annotations

import argparse
import json
import sys

from .core import VerifierError, laws, verify


def _secs(ms) -> str:
    return f"{ms / 1000:.2f}"


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(prog="verify", description="Report which formalized traffic laws a trace violates.")
    ap.add_argument("trace", nargs="?", help="trace JSON in the Core format ({\"scenes\": [...]})")
    ap.add_argument("--manifest", help="the source's capability manifest (default: every atom observed)")
    ap.add_argument("--law", action="append", dest="law_ids", help="check only this law id (repeatable)")
    ap.add_argument("--rule", action="append", dest="rules", help="check only this rule id (repeatable)")
    ap.add_argument("--timeout", type=float, default=600, help="seconds per rule (default 600)")
    ap.add_argument("--jobs", type=int, default=2, help="rules monitored at once (default 2)")
    ap.add_argument("--no-normalize", action="store_true", help="pass trace and manifest to the monitor as given")
    ap.add_argument("--json", action="store_true", help="print the full report as JSON")
    ap.add_argument("--list", action="store_true", help="list the packaged laws and rules, then exit")
    a = ap.parse_args(argv)
    if a.list:
        for rule, meta in laws().items():
            print(f"{meta['law']:<20} {rule:<22} {meta.get('title', '')}")
        return 0
    if not a.trace:
        ap.error("a trace is required")
    try:
        rep = verify(a.trace, a.manifest, rules=a.rules, law_ids=a.law_ids, timeout=a.timeout, jobs=a.jobs,
                     normalize_input=not a.no_normalize)
    except (VerifierError, ValueError, OSError) as e:
        print(f"verify: {e}", file=sys.stderr)
        return 2
    if a.json:
        print(json.dumps(rep, indent=1))
    else:
        src = rep["source"] or {}
        print(f"trace: {a.trace}  ({src.get('instants', '?')} scenes, source {src.get('source', '?')})")
        for n in rep["notes"]:
            print(f"note: {n}")
        print()
        for law, v in rep["laws"].items():
            print(f"{law:<20} {v['verdict'].upper() if v['verdict'] == 'violated' else v['verdict']:<15} {v['title']}")
            for r in v["rules"]:
                line = f"    {r['rule']:<22} {r['verdict']:<15} {r.get('seconds', '?')} s"
                if r.get("error"):
                    line += f"  ({r['error'].splitlines()[-1][:160]})"
                print(line)
                for g in r.get("groundings", []):
                    who = ", ".join(f"{k}=track {t}" for k, t in g["binding"].items())
                    if g["violated_ms"]:
                        spans = "; ".join(f"t={_secs(a_)}–{_secs(b)} s" for a_, b in g["violated_ms"])
                        print(f"        {who}: violated at {spans}")
                    elif g["verdict"] == "unknown" and g["unknown_reasons"]:
                        print(f"        {who}: unknown ({', '.join(g['unknown_reasons'])})")
                if r.get("absent_atoms"):
                    kind = "unsupported" if r.get("support") == "unsupported" else "partially supported"
                    print(f"        {kind}: the manifest declares absent {', '.join(r['absent_atoms'])}")
        print()
        print("violated laws: " + (", ".join(rep["violated_laws"]) or "none"))
        if rep["undecided_laws"]:
            print("undecided laws (deadline passed or monitor failed): " + ", ".join(rep["undecided_laws"]))
    return 1 if rep["violated_laws"] else 0
