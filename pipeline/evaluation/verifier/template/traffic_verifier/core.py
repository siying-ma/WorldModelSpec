"""Run the packaged monitor on one trace and join its rule verdicts into law verdicts.

A trace is a scenes-only JSON document (`{"scenes": [...]}`) in the Core trace format; a manifest
says, per atom id, whether the source observes it (`exact`, `estimate:<class>`, `subject`) or not
(`absent`). Each registered rule is monitored in its own process, under a deadline. A rule's verdict
joins its groundings' episode verdicts; a law's verdict joins its rules' verdicts. In both joins the
order is: violated, undecided (the deadline passed or the monitor failed), unknown, compliant,
not applicable — the first present wins. A rule the manifest leaves unsupported is unknown.
"""
from __future__ import annotations

import json
import os
import shutil
import subprocess
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from . import normalize

PKG = Path(__file__).resolve().parents[1]
DATA = PKG / "data"
MONITOR = PKG / "lean" / ".lake" / "build" / "bin" / "monitor"
ORDER = ("violated", "undecided", "unknown", "compliant", "not_applicable")


class VerifierError(Exception):
    pass


def _join(verdicts) -> str:
    vs = set(verdicts)
    return next((v for v in ORDER if v in vs), "not_applicable")


def laws() -> dict:
    """The packaged rules: rule id -> {law, title, text}."""
    return json.loads((DATA / "rules.json").read_text(encoding="utf-8"))["rules"]


def _rule_report(rule: str, lines: list[dict]) -> dict:
    head = next((d for d in lines if d.get("kind") == "rule" and d.get("rule") == rule), None)
    rows = [d for d in lines if d.get("kind") == "grounding" and d.get("rule") == rule]
    if head is None:
        return {"rule": rule, "verdict": "undecided", "error": "the monitor reported nothing for this rule"}
    groundings = []
    for d in rows:
        groundings.append({
            "binding": d["grounding"],
            "verdict": d["episode"]["verdict"],
            "violated_ms": [[t["from"], t["to"]] for t in d["timeline"] if t["verdict"] == "violated"],
            "unknown_reasons": sorted(d.get("unknowns") or {}),
        })
    if head["support"] == "unsupported":
        verdict = "unknown"
    elif not groundings:
        verdict = "not_applicable"
    else:
        verdict = _join(g["verdict"] for g in groundings)
    return {"rule": rule, "verdict": verdict, "support": head["support"], "absent_atoms": head["absent"],
            "groundings": groundings}


def _run_rule(rule: str, trace: Path, manifest: Path, timeout: float) -> tuple[dict, dict | None]:
    cmd = [str(MONITOR), "--rules", rule, "--json", "--manifest", str(manifest),
           "--reading", str(DATA / "reading.json"), str(trace)]
    t0 = time.monotonic()
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except subprocess.TimeoutExpired:
        return {"rule": rule, "verdict": "undecided", "error": f"deadline of {timeout:g} s passed",
                "seconds": round(time.monotonic() - t0, 1)}, None
    secs = round(time.monotonic() - t0, 1)
    if p.returncode != 0:
        return {"rule": rule, "verdict": "undecided", "error": (p.stderr.strip() or f"exit {p.returncode}")[-800:],
                "seconds": secs}, None
    lines = [json.loads(x) for x in p.stdout.splitlines() if x.strip()]
    rep = _rule_report(rule, lines)
    rep["seconds"] = secs
    return rep, next((d for d in lines if d.get("kind") == "source"), None)


def verify(trace, manifest=None, *, rules=None, law_ids=None, timeout: float = 600, jobs: int = 2,
           normalize_input: bool = True, workdir=None) -> dict:
    """Verify one trace. Returns {"violated_laws": [...], "laws": {law: {...}}, "source": ..., "notes": [...]}.

    trace, manifest   paths; without a manifest every atom is taken as observed (`exact`)
    rules, law_ids    restrict to these rule ids or law ids (default: every packaged rule)
    timeout           seconds per rule; a rule past it is `undecided`
    jobs              rules monitored at once (each process holds the decoded trace in memory)
    normalize_input   align the manifest and trace with the packaged ontology first (default on)
    """
    if not MONITOR.exists():
        raise VerifierError(f"the monitor is not built: run {PKG / 'install.sh'}")
    table = laws()
    chosen = [r for r in table if (rules is None or r in rules) and (law_ids is None or table[r]["law"] in law_ids)]
    if not chosen:
        raise VerifierError("no packaged rule matches the selection")
    tmp = Path(workdir) if workdir else Path(tempfile.mkdtemp(prefix="traffic_verifier_"))
    tmp.mkdir(parents=True, exist_ok=True)
    try:
        notes: list[str] = []
        trace, manifest = Path(trace), (Path(manifest) if manifest else None)
        if manifest is None:
            manifest = tmp / "default_manifest.json"
            shutil.copy(DATA / "default_manifest.json", manifest)
            notes.append("no manifest given: every atom is taken as observed (exact)")
        if normalize_input:
            trace, manifest, more = normalize.prepare(trace, manifest, tmp, DATA / "atom_ids.json")
            notes += more
        with ThreadPoolExecutor(max_workers=max(1, jobs)) as pool:
            done = list(pool.map(lambda r: _run_rule(r, trace, manifest, timeout), chosen))
        source = next((s for _, s in done if s), None)
        by_law: dict[str, dict] = {}
        for rep, _ in done:
            meta = table[rep["rule"]]
            law = by_law.setdefault(meta["law"], {"law": meta["law"], "title": meta.get("title", ""), "rules": []})
            law["rules"].append(rep)
        for law in by_law.values():
            law["verdict"] = _join(r["verdict"] for r in law["rules"])
        return {"trace": str(trace), "source": source, "notes": notes,
                "violated_laws": sorted(l for l, v in by_law.items() if v["verdict"] == "violated"),
                "undecided_laws": sorted(l for l, v in by_law.items() if v["verdict"] == "undecided"),
                "laws": dict(sorted(by_law.items()))}
    finally:
        if not workdir:
            shutil.rmtree(tmp, ignore_errors=True)
