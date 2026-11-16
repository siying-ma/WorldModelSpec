"""Write the operator's declarations of pending gaps carried over from an earlier run
(`config/deferred_gaps.jsonl`) from that run's gap ledger as it stood at a fixed commit.

    python -m scripts.export_deferred_gaps --commit <commit> --run <source run> --ids G17,G18 [--out <file>]

The ledger is read with `git show <commit>:<path>` (its proposals and decisions, the latest decision
of a gap standing), never from a checkout. Each id given must name a gap that run proposed, that no
decision there rejected or retired, on one law of the current training corpus whose text still has
the gap's digest and, at its occurrence, its words. Any id that fails any of these writes nothing;
otherwise the file is replaced by the selected rows, in the order given."""
from __future__ import annotations
import argparse
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from harness.__main__ import DEFAULT_LAWS
from harness.model import corpus
from harness.store import deferred_gaps, jsonl, paths

LEDGER = "pipeline/traffic-spec-agent/library/TrafficSpec/Gaps"
TRAIN_LAWS = paths.REPO / DEFAULT_LAWS                   # the harness's default corpus: the training split


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=paths.REPO, check=True, capture_output=True, text=True).stdout


def ledger_at(commit: str, ledger: str = LEDGER) -> dict[str, dict]:
    """The gaps of the ledger at `commit`, each with its latest decision applied (`state`)."""
    rows = lambda name: [json.loads(x) for x in git("show", f"{commit}:{ledger}/{name}").splitlines() if x.strip()]
    latest = {d["id"]: d for d in rows("decisions.jsonl")}
    return {p["id"]: {**p, "state": latest.get(p["id"], {}).get("state", "proposed")} for p in rows("proposals.jsonl")}


def export(commit: str, run: str, ids: list[str], texts: dict[str, str], ledger: str = LEDGER) -> tuple[list[dict], list[str]]:
    """The declaration rows of `ids`, and every reason one cannot be declared."""
    sha = git("rev-parse", "--verify", f"{commit}^{{commit}}").strip()
    gaps = ledger_at(sha, ledger)
    out, bad = [], []
    for gid in ids:
        g = gaps.get(gid)
        if g is None:
            bad.append(f"{gid}: no gap of the ledger at {sha[:12]} has this id"); continue
        why = []
        if str(g.get("proposed_in", "")).split("/")[0] != run:
            why.append(f"it was proposed in {g.get('proposed_in')!r}, not by run {run}")
        if g["state"] in ("rejected", "retired"):
            why.append(f"it is already decided ({g['state']})")
        laws = list(g.get("law_refs") or [])
        if len(laws) != 1 or not g.get("occurrence"):
            why.append("it names no single law and occurrence")
        if why:
            bad.append(f"{gid}: " + "; ".join(why)); continue
        row = {"source_commit": sha, "source_run": run, "source_id": gid, "law": laws[0],
               "law_digest": str(g["occurrence"]).rsplit("@", 1)[-1].split(":")[0], "occurrence": g["occurrence"], "span": g.get("span", ""),
               "kind": g.get("kind", ""), "proposal": g.get("proposal", ""), "source_state": g["state"]}
        why = deferred_gaps.row_defects(row) or deferred_gaps.binding_defects(row, texts.get(laws[0]))
        if why:
            bad.append(f"{gid}: " + "; ".join(why)); continue
        out.append(row)
    return out, bad


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--commit", required=True)
    ap.add_argument("--run", required=True)
    ap.add_argument("--ids", required=True, help="comma-separated gap ids of that run")
    ap.add_argument("--out", default=str(deferred_gaps.DECLARATIONS))
    a = ap.parse_args(argv)
    texts = {l.id: l.text for l in corpus.load_laws(TRAIN_LAWS)}
    rows, bad = export(a.commit, a.run, [i.strip() for i in a.ids.split(",") if i.strip()], texts)
    if bad:
        print("refused, nothing written:\n" + "\n".join(f"  {b}" for b in bad), file=sys.stderr)
        return 1
    text = "".join(json.dumps(r, ensure_ascii=False) + "\n" for r in rows)
    with tempfile.TemporaryDirectory() as t:              # the list is read back whole before it replaces the file
        probe = Path(t) / "deferred_gaps.jsonl"
        probe.write_text(text, encoding="utf-8")
        deferred_gaps.load(probe)
    jsonl.write_atomic(Path(a.out), text)
    for r in rows:
        print(f"{deferred_gaps.identity(r)} at {r['source_commit'][:12]}: {r['law']} {r['occurrence']} “{r['span']}” "
              f"({r['kind']}, {r['source_state']}): law in the training corpus, digest and words match")
    return 0


if __name__ == "__main__":
    sys.exit(main())
