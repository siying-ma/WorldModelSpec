"""Run the packaged monitor on one trace and join its rule verdicts into law verdicts.

A trace is a scenes-only JSON document (`{"scenes": [...]}`) in the Core trace format; a manifest
says, per atom id, whether the source observes it (`exact`, `estimate:<class>`, `subject`) or not
(`absent`). Each registered rule is monitored in its own process, under a deadline. A rule's verdict
joins its groundings' episode verdicts; a law's verdict joins its rules' verdicts. In both joins the
order is: violated, undecided (the deadline passed or the monitor failed), unknown, compliant,
not applicable — the first present wins. A rule the manifest leaves unsupported is unknown.

A rule whose verdicts rest on an approved abstraction (the monitor names it on the rule's line) is
partial coverage: its verdict checks the conduct the rule states, not full compliance with the law.
Each rule and each law carries `abstractions` and `partial_coverage`; a law is partial coverage when
any of its rules is, and its verdict is never full statutory compliance.
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
EXPLAIN = PKG / "lean" / ".lake" / "build" / "bin" / "explain"
MAX_EXPLAINED = 2          # violated groundings explained per rule
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
    abstractions = list(head.get("abstractions", []))
    return {"rule": rule, "verdict": verdict, "support": head["support"], "absent_atoms": head["absent"],
            "abstractions": abstractions, "partial_coverage": bool(abstractions), "groundings": groundings}


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


def _explain(rep: dict, trace: Path, manifest: Path, timeout: float) -> None:
    """Attach to each violated grounding (at most MAX_EXPLAINED) why the rule is violated at the
    first observation of its first violated interval, as the explain program reports it."""
    for g in [g for g in rep.get("groundings", []) if g["violated_ms"]][:MAX_EXPLAINED]:
        at = g["violated_ms"][0][0]
        cmd = [str(EXPLAIN), "--manifest", str(manifest), "--reading", str(DATA / "reading.json"),
               "--rule", rep["rule"], "--at", str(at)]
        for name, track in g["binding"].items():
            cmd += ["--bind", f"{name}={track}"]
        try:
            p = subprocess.run(cmd + [str(trace)], capture_output=True, text=True, timeout=timeout)
            g["explanation"] = p.stdout.splitlines() if p.returncode == 0 else [f"(explain failed: {p.stderr.strip()[-300:]})"]
        except subprocess.TimeoutExpired:
            g["explanation"] = [f"(explain did not finish within {timeout:g} s)"]
        g["explained_at_ms"] = at


def _scan(rep: dict, trace: Path, manifest: Path, timeout: float) -> None:
    """Attach to every grounding of the rule (`scan`) the observations the explain program chooses
    itself, each with why it was chosen, the verdict there, the walked binder classes,
    applicability and obligation as trees, and their text: the first observation of each violated
    interval; else the first unknown and the engaged observation closest to a comparison's
    boundary; else, never engaged, the observation closest to applying."""
    for g in rep.get("groundings", []):
        cmd = [str(EXPLAIN), "--manifest", str(manifest), "--reading", str(DATA / "reading.json"),
               "--rule", rep["rule"], "--scan", "--json"]
        for name, track in g["binding"].items():
            cmd += ["--bind", f"{name}={track}"]
        try:
            p = subprocess.run(cmd + [str(trace)], capture_output=True, text=True, timeout=timeout)
            if p.returncode == 0:
                out = json.loads(p.stdout)
                g["scan"] = out["groundings"][0]["explanations"] if out["groundings"] else []
                g["scan_notes"] = out["groundings"][0]["choice_notes"] if out["groundings"] else [f"support {out['support']}"]
            else:
                g["scan_error"] = p.stderr.strip()[-300:]
        except subprocess.TimeoutExpired:
            g["scan_error"] = f"explain did not finish within {timeout:g} s"
        except (ValueError, IndexError, KeyError) as e:
            g["scan_error"] = f"explain printed no readable JSON: {e}"


def verify(trace, manifest=None, *, rules=None, law_ids=None, timeout: float = 600, jobs: int = 2,
           normalize_input: bool = True, explain=True, workdir=None) -> dict:
    """Verify one trace. Returns {"violated_laws": [...], "laws": {law: {...}}, "source": ..., "notes": [...]}.

    trace, manifest   paths; without a manifest every atom is taken as observed (`exact`)
    rules, law_ids    restrict to these rule ids or law ids (default: every packaged rule)
    timeout           seconds per rule; a rule past it is `undecided`
    jobs              rules monitored at once (each process holds the decoded trace in memory)
    normalize_input   align the manifest and trace with the packaged ontology first (default on)
    explain           True: for each violated grounding, say why the rule fails at its first violated
                      observation; "all": also, for every grounding whatever its verdict, explain the
                      observations the explain program chooses (`scan`); False: explain nothing
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
            if explain and EXPLAIN.exists():
                list(pool.map(lambda d: _explain(d[0], trace, manifest, timeout), [d for d in done if d[0]["verdict"] == "violated"]))
            if explain == "all" and EXPLAIN.exists():
                list(pool.map(lambda d: _scan(d[0], trace, manifest, timeout), done))
        source = next((s for _, s in done if s), None)
        by_law: dict[str, dict] = {}
        for rep, _ in done:
            meta = table[rep["rule"]]
            law = by_law.setdefault(meta["law"], {"law": meta["law"], "title": meta.get("title", ""), "rules": []})
            law["rules"].append(rep)
        for law in by_law.values():
            law["verdict"] = _join(r["verdict"] for r in law["rules"])
            law["abstractions"] = sorted({a for r in law["rules"] for a in r.get("abstractions", [])})
            law["partial_coverage"] = bool(law["abstractions"])
        return {"trace": str(trace), "source": source, "notes": notes,
                "violated_laws": sorted(l for l, v in by_law.items() if v["verdict"] == "violated"),
                "undecided_laws": sorted(l for l, v in by_law.items() if v["verdict"] == "undecided"),
                "partial_coverage_laws": sorted(l for l, v in by_law.items() if v["partial_coverage"]),
                "laws": dict(sorted(by_law.items()))}
    finally:
        if not workdir:
            shutil.rmtree(tmp, ignore_errors=True)
