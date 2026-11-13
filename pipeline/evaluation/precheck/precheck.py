"""The label-stage precheck: before a run's label stage, per law, how many of its plain-labelled
training recordings the current data can decide, and which laws should enter the label stage.
Static and read-only: no rule is run over a recording, and no run, library, dataset or label changes.

Reason: a law none of whose plain labels the data can decide should be known as such before its
label stage is paid for, with the reasons, so that it is reported not aligned for the data and no
repair is spent on it.

Inputs: a dataset folder built from one delivery (`recorded.dataset`), the run's directory
(`results/<run>`: its ledger and its node records), the run's library (its ontology, read by the
source report) and the monitor built in that library (it must register the run's rules).

What is compared, as the label stage fixes it:
- a law's rules are the nodes of its final plan in the run's ledger (`state.json`, `ledger[].nodes`),
  accepted or not; a node the monitor does not register cannot be run, and its law is `no rule`;
- a law's recordings, plain labels (an explicit verdict that is no judgment call) and judgment calls
  are those `harness.phases.label_check.comparison_set` fixes, which also refuses a dataset whose
  traces or manifests differ from its index.

What can block a plain label, each a blocker with the rule it concerns, a class and a handling (who
the evidence points at, as `recorded.scoring` names them):
- `unsupported`: under the recording's source manifest Core gives the rule no support
  (`recorded.decidability`, Core's `Manifest.support` on a probe trace), so its verdict is unknown;
- `absent_atom:<atom>`: the rule's support is partial: it reads an atom the manifest declares absent
  (classified by `recorded.scoring`);
- `source_check:<finding>`: a case `iii` finding of the source report (`recorded.source_check`: the
  manifest declares an atom observed and the trace omits or contradicts it, such as an
  `occupancy_observed` that names no road user) on an atom the rule reads; a kind labelled on an entity
  while declared absent is left out, since the support above already counts the absent atom;
- `assumption_missing:<asm>`: an assumption the rule's record (or a rule it composes) declares, that
  some scene of the trace does not supply;
- `intention_missing:<int>`: an intention the rule's record declares, that no scene declares for the
  subject;
- `classes_missing:<who>`: road users with no `classes` in some scene: the subject (every rule binds
  its subject by class), or another road user (rules that read a road-user atom).
The atoms a rule reads are Core's (`Rule.atomIds` over the rules it composes), read through the same
probe under the source manifest with every atom declared absent. The assumption, intention and class
facts are read in the one pass over the trace that feeds the source report.

A blocker is certain when Core cannot decide the label whatever the trace holds: an unsupported rule,
when the label is not `violated` or every rule of the law is unsupported (a law's verdict joins its
rules': violated, then unknown, then compliant, then not applicable). Every other blocker says the
verdict may be unknown. A plain label is `blocked` with a certain blocker, `at_risk` with only others,
`decidable` with none.

Verdict per law: `no rule` when its final plan names no node or a node the monitor does not register;
`not aligned (data)` when none of its plain labels is decidable or at risk, which includes a law with
no plain label; `enter label stage` otherwise. An at-risk label sends its law to the label stage,
since whether a possible blocker leaves it unknown depends on how the rule reads what is missing.

Not predicted, since only an evaluation shows them: a window reaching past the recording, geometry Core
cannot use (a boundary it rejects as a polygon, a degenerate region), identity and sampling gaps, a
deadline, a crash, and any mismatch. The label stage remains the authority on every label.
"""
from __future__ import annotations

import sys

sys.dont_write_bytecode = True

import argparse
import hashlib
import json
import tempfile
from collections import Counter
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

AGENT = Path(__file__).resolve().parents[2] / "traffic-spec-agent"
sys.path.insert(0, str(AGENT))

from recorded import dataset as dataset_mod  # noqa: E402
from recorded import decidability, projection, scoring, source_check  # noqa: E402
from harness.phases import label_check  # noqa: E402

VERDICTS = ("enter label stage", "not aligned (data)", "no rule")
STATUSES = ("decidable", "at_risk", "blocked")
LABELS = ("violated", "compliant", "not_applicable")
#: A source report finding the support already counts (a kind labelled on an entity, declared absent).
COUNTED_BY_SUPPORT = "labelled_but_declared_absent"
SCAN_JOBS = 8


# ---------------------------------------------------------------------------------------------
# The run: its final plans and its node records
# ---------------------------------------------------------------------------------------------
def _json(p: Path, default=None):
    return json.loads(p.read_text(encoding="utf-8")) if p.is_file() else default


def final_plans(run_dir: Path) -> dict[str, dict]:
    """Law → {state, nodes}: the run's ledger, as the label stage reads a law's final plan."""
    state = _json(run_dir / "state.json")
    if state is None:
        raise SystemExit(f"{run_dir}: no state.json, not a run directory")
    return {e["law"]: {"state": e.get("state"), "nodes": list(e.get("nodes") or [])} for e in state.get("ledger") or []}


def node_records(run_dir: Path) -> dict[str, dict]:
    """Node id → record, the base chain's first and then the run's own (`options.json` `base_run`,
    a sibling run directory)."""
    chain, d, seen = [], run_dir, set()
    while d is not None and d.name not in seen:
        seen.add(d.name)
        chain.append(d)
        base = (_json(d / "options.json", {}) or {}).get("base_run")
        d = d.parent / base if base and (d.parent / base).is_dir() else None
    out: dict[str, dict] = {}
    for d in reversed(chain):
        out.update((_json(d / "state.json", {}) or {}).get("accepted_nodes") or {})
    return out


def composed(rule: str, records: dict[str, dict]) -> list[str]:
    """The rule and every rule it composes, transitively, by the record's `compositions`."""
    out, stack = [], [rule]
    while stack:
        r = stack.pop()
        if r in out:
            continue
        out.append(r)
        stack += [c["rule"] for c in (records.get(r) or {}).get("compositions") or [] if isinstance(c.get("rule"), str)]
    return out


def declared_facts(rule: str, records: dict[str, dict]) -> dict[str, set]:
    """The assumption and intention ids the rule's record, and those of the rules it composes, declare."""
    facts = {"asm": set(), "int": set()}
    for r in composed(rule, records):
        rec = records.get(r) or {}
        facts["asm"] |= {a["id"] for a in rec.get("assumptions") or [] if a.get("id")}
        facts["int"] |= {a["id"] for a in rec.get("intentions") or [] if a.get("id")}
    return facts


# ---------------------------------------------------------------------------------------------
# Support: the monitor on the probe trace
# ---------------------------------------------------------------------------------------------
def registered(monitor: Path, manifest: Path) -> set[str]:
    """Every rule the monitor registers."""
    return set(decidability.rule_support(monitor, manifest))


def atoms_read(monitor: Path, manifest: Path, rules: list[str]) -> dict[str, set]:
    """Rule → every atom it reads, closed over the rules it composes: its absent atoms under the
    manifest with every atom declared absent."""
    doc = json.loads(manifest.read_text(encoding="utf-8"))
    doc["atoms"] = {a: "absent" for a in doc.get("atoms") or {}}
    with tempfile.TemporaryDirectory() as t:
        none = Path(t) / "manifest.json"
        none.write_text(json.dumps(doc), encoding="utf-8")
        sup = decidability.rule_support(monitor, none, rules)
    return {r: set(s.absent) for r, s in sup.items()}


# ---------------------------------------------------------------------------------------------
# The trace: the source report and the declared facts, in one pass
# ---------------------------------------------------------------------------------------------
def _noting(scenes, facts: dict):
    """The scenes unchanged; on the way, per scene, the assumptions supplied, the intentions declared
    for the subject and the road users with no `classes`."""
    for s in scenes:
        subj = s.get("subject")
        facts["scenes"] += 1
        facts["asm"].update({a[0] for a in s.get("assumptions") or [] if a})
        facts["int"].update({v[0] for d in s.get("intents") or [] if d.get("vehicle") == subj for v in d.get("values") or [] if v})
        for u in s.get("users") or []:
            if u.get("classes") is None:
                facts["no_classes"]["subject" if u.get("track") == subj else "other road user"] += 1
        yield s


def scan(args: tuple) -> tuple[str, dict]:
    """One recording: its source report (`source_check.check`) and its declared facts."""
    rid, trace, manifest, kinds = args
    facts = {"scenes": 0, "asm": Counter(), "int": Counter(), "no_classes": Counter()}
    try:
        with Path(trace).open("rb") as f:
            rep = source_check.check(_noting(projection.iter_scenes(f, chunk_size=1 << 22), facts),
                                     json.loads(Path(manifest).read_text(encoding="utf-8")), kinds)
    except Exception as e:                       # a report: an unreadable recording is said so, never raised
        return rid, {"error": f"{type(e).__name__}: {str(e)[:300]}", "findings": [], "facts": facts}
    return rid, {"findings": rep["findings"], "facts": facts}


def scan_all(items: list[tuple], jobs: int) -> dict[str, dict]:
    if jobs <= 1 or len(items) <= 1:
        return dict(scan(a) for a in items)
    with ProcessPoolExecutor(min(jobs, len(items))) as pool:
        return dict(pool.map(scan, items))


# ---------------------------------------------------------------------------------------------
# Blockers of one plain label
# ---------------------------------------------------------------------------------------------
def _b(rule, reason, cls, handling, evidence, certain=False) -> dict:
    return {"rule": rule, "reason": reason, "class": cls, "handling": handling, "evidence": evidence, "certain": certain}


def support_blockers(rule: str, sup, declared: dict, certain: bool) -> list[dict]:
    if sup.support == "unsupported":
        return [_b(rule, "unsupported", "unsupported", "data", "the rule is unsupported: absent " + ", ".join(sup.absent), certain)]
    out = []
    for a in sup.absent:
        cls, handling, ev = scoring._blocker("absent_atom:" + a.replace(".", "_"), declared)
        out.append(_b(rule, f"absent_atom:{a}", cls, handling, ev))
    return out


def trace_blockers(rule: str, reads: set, facts: dict, rep: dict) -> list[dict]:
    out = []
    if rep.get("error"):
        return [_b(rule, "unreadable", "unreadable", "investigate", rep["error"], True)]
    for f in rep["findings"]:
        if f["case"] == "iii" and f["atom"] in reads and f["check"] != COUNTED_BY_SUPPORT:
            ev = (f"{f['entities']} of {f['checked_entities']} entities, {f['observations']} of {f['checked']} observations"
                  if "checked" in f else f"{f.get('entities', 0)} entities")
            out.append(_b(rule, "source_check:" + source_check.key(f), "trace_vs_manifest", "data", ev))
    n = facts["scenes"]
    for a in sorted(facts["need"]["asm"]):
        if facts["asm"][a] < n:
            out.append(_b(rule, f"assumption_missing:{a}", *scoring.REASONS["assumption_missing"],
                          f"supplied in {facts['asm'][a]} of {n} scenes"))
    for i in sorted(facts["need"]["int"]):
        if not facts["int"][i]:
            out.append(_b(rule, f"intention_missing:{i}", *scoring.REASONS["intention_missing"],
                          f"declared for the subject in none of {n} scenes"))
    nc = facts["no_classes"]
    if nc["subject"]:
        out.append(_b(rule, "classes_missing:subject", "classes_missing", "data", f"the subject has no classes in {nc['subject']} scene(s)"))
    if nc["other road user"] and any(a.startswith("ru.") and a != "ru.subject" for a in reads):
        out.append(_b(rule, "classes_missing:other road user", "classes_missing", "data",
                      f"{nc['other road user']} road-user scene(s) without classes"))
    return out


def label_blockers(rules: list[str], label: str, sups: dict, declared: dict, reads: dict, needs: dict,
                   rep: dict | None) -> list[dict]:
    """Every blocker of one plain label: each rule's support under the recording's source, and what
    its trace omits of what the rule reads or declares."""
    all_unsupported = all(sups[r].support == "unsupported" for r in rules)
    out = []
    for r in rules:
        out += support_blockers(r, sups[r], declared, label != "violated" or all_unsupported)
        if rep is not None:
            out += trace_blockers(r, reads[r], {**rep["facts"], "need": needs[r]}, rep)
    return out


def status_of(blockers: list[dict]) -> str:
    return "blocked" if any(b["certain"] for b in blockers) else "at_risk" if blockers else "decidable"


# ---------------------------------------------------------------------------------------------
# Per law
# ---------------------------------------------------------------------------------------------
def reasons(per_recording: dict[str, dict]) -> list[dict]:
    """The blockers of a law's plain labels grouped by reason: how many labels each reaches, on how
    many it is certain, the rules it concerns, one evidence."""
    acc: dict[str, dict] = {}
    for rid, x in sorted(per_recording.items()):
        seen = {}
        for b in x["blockers"]:
            e = seen.setdefault(b["reason"], {"certain": False, "rules": set(), "b": b})
            e["certain"] |= b["certain"]
            e["rules"].add(b["rule"])
        for reason, e in seen.items():
            g = acc.setdefault(reason, {"reason": reason, "class": e["b"]["class"], "handling": e["b"]["handling"],
                                        "labels": 0, "certain": 0, "rules": set(), "example": {"recording": rid, "evidence": e["b"]["evidence"]}})
            g["labels"] += 1
            g["certain"] += e["certain"]
            g["rules"] |= e["rules"]
    out = [{**g, "rules": sorted(g["rules"])} for g in acc.values()]
    return sorted(out, key=lambda g: (-g["labels"], g["reason"]))


def verdict_of(rules: list[str], missing: list[str], counts: Counter) -> str:
    if not rules or missing:
        return "no rule"
    return "enter label stage" if counts["decidable"] + counts["at_risk"] else "not aligned (data)"


def law_report(law: str, plan: dict, fixed: dict, cases: dict, have: set, sups: dict, declared: dict,
               reads: dict, needs: dict, reps: dict, sources: dict) -> dict:
    rules = sorted(plan["nodes"]) if plan else []
    missing = [r for r in rules if r not in have]
    plain = Counter(cases[r]["verdict"] for r in fixed.get("eligible", []))
    per = {}
    if rules and not missing:
        for rid in fixed.get("eligible", []):
            label = cases[rid]["verdict"]
            bs = label_blockers(rules, label, sups[sources[rid]], declared[sources[rid]], reads, needs, reps.get(rid))
            per[rid] = {"label": label, "status": status_of(bs), "blockers": bs}
    counts = Counter(x["status"] for x in per.values())
    return {"ledger_state": plan.get("state") if plan else None, "rules": rules, "not_registered": missing,
            "recordings": len(fixed.get("recordings", [])),
            "plain": {**{k: plain.get(k, 0) for k in LABELS}, "total": len(fixed.get("eligible", []))},
            "judgment_call": len(fixed.get("judgment_calls", [])),
            "unlabelled": len(fixed.get("recordings", [])) - len(fixed.get("eligible", [])) - len(fixed.get("judgment_calls", [])),
            **{k: counts.get(k, 0) for k in STATUSES}, "verdict": verdict_of(rules, missing, counts),
            "reasons": reasons(per), "per_recording": per}


# ---------------------------------------------------------------------------------------------
# The whole precheck
# ---------------------------------------------------------------------------------------------
def precheck(dataset: Path, run_dir: Path, library: Path, monitor: Path, laws: list[str] | None = None,
             jobs: int = SCAN_JOBS) -> dict:
    ds = dataset_mod.Dataset(dataset)
    plans = final_plans(run_dir)
    records = node_records(run_dir)
    data_laws = sorted({r["law_id"] for r in ds.rows})
    wanted = sorted(laws) if laws else sorted(plans)
    fixed = label_check.comparison_set(ds, set(wanted))
    srcs = sorted(ds.sources)
    man = {s: ds.path / "sources" / s / "manifest.json" for s in srcs}
    have = registered(monitor, man[srcs[0]]) if srcs else set()
    runnable = sorted({r for l in wanted for r in (plans.get(l) or {}).get("nodes", []) if r in have})
    sups = {s: decidability.rule_support(monitor, man[s], runnable) if runnable else {} for s in srcs}
    declared = {s: _json(man[s], {}).get("atoms", {}) for s in srcs}
    reads = {r: set() for r in runnable}
    for s in srcs:
        for r, a in (atoms_read(monitor, man[s], runnable) if runnable else {}).items():
            reads[r] |= a
    needs = {r: declared_facts(r, records) for r in runnable}
    sources = {r["recording_id"]: r["source"] for r in ds.rows}
    to_scan = sorted({rid for l in wanted if (plans.get(l) or {}).get("nodes")
                      and all(n in have for n in plans[l]["nodes"]) for rid in fixed["laws"].get(l, {}).get("eligible", [])})
    kinds = source_check.Kinds.from_library(library)
    reps = scan_all([(rid, str(ds.files(rid)["trace"]), str(ds.files(rid)["manifest"]), kinds) for rid in to_scan], jobs)
    out_laws = {l: law_report(l, plans.get(l), fixed["laws"].get(l, {}), fixed["cases"], have, sups, declared, reads, needs,
                              reps, sources) for l in wanted}
    return {"precheck": "static: blockers predicted from the source manifest, the rules' support and the trace's contents; "
                        "no rule was run over a recording, and the label stage remains the authority",
            "dataset": str(ds.path), "data_version": ds.data_version, "run": str(run_dir), "library": str(library),
            "monitor": str(monitor), "monitor_sha256": hashlib.sha256(monitor.read_bytes()).hexdigest(),
            "registered_rules": len(have),
            "overlap": {"run_laws": len(plans), "dataset_laws": len(data_laws),
                        "both": sorted(set(plans) & set(data_laws)),
                        "run_only": sorted(set(plans) - set(data_laws)), "dataset_only": sorted(set(data_laws) - set(plans))},
            "support": {s: {r: {"support": x.support, "absent": x.absent} for r, x in sorted(v.items())} for s, v in sups.items()},
            "atoms_read": {r: sorted(a) for r, a in sorted(reads.items())},
            "declared_facts": {r: {k: sorted(v) for k, v in f.items()} for r, f in sorted(needs.items())},
            "totals": totals(out_laws), "laws": out_laws}


def totals(out_laws: dict) -> dict:
    t = Counter()
    for x in out_laws.values():
        t.update({k: x[k] for k in ("recordings", "judgment_call", "unlabelled", *STATUSES)})
        t["plain"] += x["plain"]["total"]
    return {**dict(t), "verdicts": {v: sum(x["verdict"] == v for x in out_laws.values()) for v in VERDICTS}}


# ---------------------------------------------------------------------------------------------
# The table
# ---------------------------------------------------------------------------------------------
def render(doc: dict) -> str:
    head = f"{'law':20s} {'ledger':9s} {'rules':>5s} {'rec':>4s} {'plain v/c/na':>14s} {'jc':>3s} {'unl':>4s} " \
           f"{'dec':>4s} {'risk':>4s} {'blk':>4s}  verdict"
    out = [f"precheck (static; the label stage remains the authority) of {doc['run']}",
           f"dataset {doc['dataset']} (data version {doc['data_version'][:12]}); monitor registers {doc['registered_rules']} rule(s)",
           f"laws: run {doc['overlap']['run_laws']}, dataset {doc['overlap']['dataset_laws']}, both {len(doc['overlap']['both'])}; "
           f"dataset laws the run does not plan: {', '.join(doc['overlap']['dataset_only']) or 'none'}", "", head, "-" * len(head)]
    for law, x in doc["laws"].items():
        p = x["plain"]
        plain = f"{p['total']} ({p['violated']}/{p['compliant']}/{p['not_applicable']})"
        out.append(f"{law:20s} {str(x['ledger_state']):9s} {len(x['rules']):5d} {x['recordings']:4d} {plain:>14s} "
                   f"{x['judgment_call']:3d} {x['unlabelled']:4d} {x['decidable']:4d} {x['at_risk']:4d} {x['blocked']:4d}  {x['verdict']}")
        if x["not_registered"]:
            out.append(f"    not registered in the monitor: {', '.join(x['not_registered'])}")
        for g in x["reasons"]:
            sure = f", certain on {g['certain']}" if g["certain"] else ""
            out.append(f"    - {g['reason']} [{g['class']}, {g['handling']}]: {g['labels']} plain label(s){sure}; "
                       f"rules {', '.join(g['rules'])}; e.g. {g['example']['recording'][:12]}: {g['example']['evidence']}")
    t = doc["totals"]
    out += ["", f"plain labels {t.get('plain', 0)}: decidable {t.get('decidable', 0)}, at risk {t.get('at_risk', 0)}, "
                f"blocked {t.get('blocked', 0)}; verdicts " + ", ".join(f"{k} {v}" for k, v in t["verdicts"].items())]
    return "\n".join(out) + "\n"


def main(argv: list[str]) -> int:
    """python3 precheck.py --dataset DIR --run DIR [--library DIR] [--monitor PATH] [--laws A,B] [--out FILE] [--jobs N]"""
    p = argparse.ArgumentParser(prog="precheck.py", description=main.__doc__)
    p.add_argument("--dataset", required=True, help="a dataset folder built by `python -m recorded.dataset build`")
    p.add_argument("--run", required=True, help="the run's directory, results/<run> (its ledger and node records)")
    p.add_argument("--library", default="", help="the run's library (default: <run>/../../library)")
    p.add_argument("--monitor", default="", help="the monitor built in it (default: <library>/.lake/build/bin/monitor)")
    p.add_argument("--laws", default="", help="a comma-separated subset of the run's laws")
    p.add_argument("--out", default="", help="the JSON report")
    p.add_argument("--jobs", type=int, default=SCAN_JOBS)
    a = p.parse_args(argv)
    run_dir = Path(a.run).resolve()
    library = Path(a.library).resolve() if a.library else run_dir.parents[1] / "library"
    monitor = Path(a.monitor).resolve() if a.monitor else library / ".lake" / "build" / "bin" / "monitor"
    if not monitor.is_file():
        print(f"refused: no monitor at {monitor}: build it in the run's library (lake build monitor)", file=sys.stderr)
        return 2
    try:
        doc = precheck(Path(a.dataset), run_dir, library, monitor, [x for x in a.laws.split(",") if x] or None, a.jobs)
    except (dataset_mod.DatasetError, ValueError) as e:
        print(f"refused: {e}", file=sys.stderr)
        return 2
    print(render(doc), end="")
    if a.out:
        Path(a.out).parent.mkdir(parents=True, exist_ok=True)
        Path(a.out).write_text(json.dumps(doc, indent=1, sort_keys=False) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
