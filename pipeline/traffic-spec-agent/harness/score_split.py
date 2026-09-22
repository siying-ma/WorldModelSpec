"""Score a test run against the split's test-only atoms (design §9). The run never sees this file."""
from __future__ import annotations
import json
import sys
from pathlib import Path
from . import paths
from .gaps import GapLedger
from .ledger import Ledger


def score(run_id: str, split_atoms: Path) -> dict:
    split = json.loads(split_atoms.read_text(encoding="utf-8"))
    test_only = set(split["test_only_atoms"]) | set(split["test_only_values"]) | set(split["test_only_derived"])
    run_dir = paths.run_dir(run_id)
    ledger = Ledger(run_dir / "ledger.jsonl", [], 1)
    gaps = GapLedger(paths.GAP_LEDGER)
    proposed = [g for g in gaps.rows if g.get("proposed_in", "").startswith(run_id + "/")]
    sys.path.insert(0, str(paths.REPO.parents[0] / "ontology_provenance" / "nrs_tools"))
    try:
        from atom_lexicon import scan   # type: ignore
    except Exception:
        scan = None
    hits = set()
    for g in proposed:
        if scan:
            a, v = scan(g.get("span", "") + " " + str(g.get("proposal", "")))
            hits |= (a | v) & test_only
    recall = len(hits) / len(test_only) if test_only else 1.0
    precision = (sum(1 for g in proposed if scan and ((lambda r: (r[0] | r[1]) & test_only)(scan(g.get("span", "") + " " + str(g.get("proposal", ""))))) ) / len(proposed)) if proposed else 1.0
    approximations = []
    acc = run_dir / "accepted_nodes.jsonl"
    if acc.exists() and scan:
        for l in acc.read_text(encoding="utf-8").splitlines():
            if not l.strip():
                continue
            n = json.loads(l)
            for e in n.get("elements", []):
                text = next((s["text"] for s in n.get("segmentation", []) if s["id"] == e.get("span")), "")
                a, v = scan(text)
                if (a | v) & test_only:
                    approximations.append((n["node_id"], e.get("span"), sorted((a | v) & test_only)))
    return {"laws": ledger.counts(), "gaps_proposed": len(proposed), "test_only": len(test_only),
            "gap_recall": round(recall, 3), "gap_precision": round(precision, 3),
            "approximations": approximations}
