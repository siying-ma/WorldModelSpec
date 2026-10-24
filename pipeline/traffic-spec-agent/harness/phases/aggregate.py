"""Legal aggregates of a run: the planner's representation selection and class mappings, and their
admission by one independent semantic gate, before any node may claim one.

1. Select and derive (one planner session, `prompts/plan_aggregates.md`): for every (posted
   definition, term) the resolution table resolves, a representation — `aggregate` (the definition
   denotes an extensional set of tracked road-user classes), `not_aggregate`, or `gap` — and, for each aggregate,
   a mapping that classifies every road-user class of the ontology with quotes. The answer is
   checked structurally (`checks/aggregates.py`) and asked for once more with its defects. A pair
   still defective holds the laws that use it for the iteration, uncharged, and is asked again in
   the next; a second such failure of the same pair stops the run (`protocol_failure`). The counts
   are the run's state (`Run.aggregate_failures`), so they survive a resume.
2. Verify (one second-vendor session per aggregate, `prompts/verify_aggregate.md`, the reviewer's
   model and effort): `supported`, `contradicted` or `underdetermined` per class, never a
   replacement. Supported classes are admitted as proposed; underdetermined ones become
   `unresolved`. A contradiction returns the whole mapping once to the planner with the gate's
   feedback; the new mapping is checked and verified again, and a class still contradicted becomes
   `unresolved` (`gate_contradiction`). A verifier answer malformed after its re-ask, like a verifier
   session that cannot be launched, raises `SessionUnavailable`: nothing is admitted, and the
   resume verifies again under the session's retry budget. No admission is ever made from a
   transport or protocol failure.
3. Persist: `aggregate_certificates.jsonl` keeps the proposal, any retry, the admitted record, the
   exact verifier requests and responses, the model and effort and every input digest; only the
   admitted record enters the run's reading, and `aggregate_input_manifest.json` records, per
   admitted id, the digests of its inputs: the posted definitions its resolution reaches, its
   explicit and nested-definition resolution graph, the precedence configuration, the road-user
   classes and their contracts, its
   selection row, the two prompts, and the planner's and verifier's models and efforts. All three are
   written crash-safe, the certificate first.

Admissions are run artifacts, never library code. A new run derives and gates every aggregate. Before
downstream work in every iteration, every admission is checked (`check_admissions`): one whose inputs are unchanged is reused,
so a resumed run repeats no call; a certificate whose reading entry an interruption lost is restored
from it; one whose inputs changed is stale — an invalidation row is appended (the certificate stays),
the entry leaves the reading, the manifest and the selection, and it is derived again, unless a node
of the run already claims it, and then the run stops (`stale_aggregate`): a changed aggregate under
existing nodes requires a new run. A run on a base run takes the base's admissions whose inputs
are unchanged.

A law-local aggregate (`<law id>:<span>::<term>`) comes from a law's own plan and is admitted the
same way, its quotes verbatim in the law; its admission is bound to the record's content, so a
re-plan that writes the same id with another mapping is gated again and replaces it. A plan that claims a definition-scoped id the selection
did not make an aggregate goes back to the selection role once (`correct_claims`); a second such
claim closes the law.
"""
from __future__ import annotations

import json
from pathlib import Path

from ..agents import render
from ..agents.session import SessionUnavailable
from ..checks import aggregates as checks
from ..model import corpus, definitions as definitions_mod
from ..model.ontology import Ontology
from ..model.reading import Reading
from ..store import jsonl, paths
from ..store.state import Run
from . import validate as validate_phase

PLACEHOLDERS_PLAN_AGGREGATES = ("definitions", "uses", "classes", "selection", "aggregate_gate_feedback")
PLACEHOLDERS_VERIFY_AGGREGATE = ("definition", "classes", "record")
GATE_VERDICTS = ("supported", "contradicted", "underdetermined")


def _ws(s) -> str:
    return " ".join(str(s or "").split())


def selection_file(run: Run) -> Path:
    return run.dir / "aggregate_selection.jsonl"


def certificates_file(run: Run) -> Path:
    return run.dir / "aggregate_certificates.jsonl"


def manifest_file(run: Run) -> Path:
    return run.dir / "aggregate_input_manifest.json"


def load_selection(run: Run) -> dict[tuple[str, str], dict]:
    return {(r["definition"], r["term"]): r for r in jsonl.read_strict(selection_file(run))}


def save_selection(run: Run, rows: dict[tuple[str, str], dict]) -> None:
    jsonl.write_rows(selection_file(run), list(rows.values()))


def _prompt_digest(name: str) -> str:
    return checks.digest((paths.PROMPTS / name).read_text(encoding="utf-8"))


def inputs_of(run: Run, rec_or_entry: dict, table: dict, defs_by_id: dict, onto: Ontology, laws: dict | None,
              selection: dict[tuple[str, str], dict] | None = None) -> dict:
    """The digests of everything an admission depends on; `selection` is the run's selection unless
    another is given (a base run's, for an admission taken from it)."""
    aid = rec_or_entry.get("aggregate_id") or rec_or_entry.get("id")
    definition = rec_or_entry.get("definition") or ""
    if checks.law_local(aid):
        law_id = aid.split(":", 1)[0]
        sources = {law_id: _ws(laws[law_id].text)} if laws and law_id in laws else {}
        row = None
    else:
        sources = _sources(table, defs_by_id, definition)
        row = next((r for r in (load_selection(run) if selection is None else selection).values() if r.get("target") == aid), None)
    return {"definitions": checks.digest(sources), "resolution": checks.digest(checks.resolution_of(table, definition)),
            "precedence": definitions_mod.precedence_hash(run), "ontology": checks.ontology_digest(onto), "selection": checks.digest(row),
            "prompts": checks.digest({"plan_aggregates": _prompt_digest("plan_aggregates.md"), "verify_aggregate": _prompt_digest("verify_aggregate.md")}),
            "models": checks.digest({"planner": run.opts.model, "plan_effort": run.opts.plan_effort,
                                     "verifier": run.opts.reviewer_model, "review_effort": run.opts.review_effort})}


def _load_manifest(run: Run) -> dict:
    m = jsonl.read_json(manifest_file(run), {})
    m.setdefault("aggregates", {})
    return m


def _save_manifest(run: Run, m: dict) -> None:
    files = {}
    for name, f in (("laws", Path(run.opts.laws)), ("definitions", Path(run.opts.laws).with_name("definitions.jsonl"))):
        if f.exists():
            files[name] = checks.digest(f.read_text(encoding="utf-8"))
    m["files"] = files
    jsonl.write_atomic(manifest_file(run), json.dumps(m, ensure_ascii=False, indent=1) + "\n")


def _set_reading(run: Run, entry: dict | None, remove: str | None = None) -> None:
    data = jsonl.read_json(run.reading_file, {"params": [], "aggregates": []})
    aggs = [a for a in data.get("aggregates", []) if a.get("id") and a.get("id") != remove and (entry is None or a.get("id") != entry["id"])]
    if entry is not None:
        aggs.append(entry)
    data["aggregates"] = aggs
    jsonl.write_atomic(run.reading_file, json.dumps(data, ensure_ascii=False, indent=1) + "\n")


def _record_admission(run: Run, cert: dict, inputs: dict) -> None:
    """The certificate, then the reading entry, then the manifest entry, each written crash-safe."""
    cert = {**cert, "inputs": inputs, "input_digest": checks.digest(inputs), "iteration": run.iteration}
    jsonl.append_atomic(certificates_file(run), cert)
    _set_reading(run, {**cert["admitted"], "admitted": f"{run.opts.run_id}/iter-{run.iteration:03d}"})
    m = _load_manifest(run)
    m["aggregates"][cert["aggregate_id"]] = {"inputs": inputs, "input_digest": cert["input_digest"], "certificate": cert["admitted"]["certificate"]}
    _save_manifest(run, m)


def _effective_certificates(rows: list[dict]) -> dict[str, dict]:
    """Per aggregate id, its latest certificate that no later row invalidated."""
    out: dict[str, dict] = {}
    for r in rows:
        aid = r.get("aggregate_id")
        if r.get("invalidates"):
            if aid in out and out[aid].get("admitted", {}).get("certificate") == r["invalidates"]:
                del out[aid]
        elif r.get("admitted"):
            out[aid] = r
    return out


def certificate_digests(run: Run) -> dict[str, str]:
    """Each effective admitted aggregate's gate digest. The audit file is strict: a damaged
    certificate log is a run-level data-integrity failure, never missing evidence."""
    return {aid: str(rec.get("gate_input_digest", ""))
            for aid, rec in _effective_certificates(jsonl.read_strict(certificates_file(run))).items()}


def _drop_orphan_selections(run: Run, selected: dict[tuple[str, str], dict]) -> set[tuple[str, str]]:
    """Remove aggregate selections whose gate never produced a certificate. This is the crash
    boundary between selection and admission: on resume those pairs are selected and derived
    again instead of being mistaken for completed work."""
    admitted = Reading(run.reading_file).aggregate_ids()
    certified = set(_effective_certificates(jsonl.read_strict(certificates_file(run))))
    orphaned = {key for key, row in selected.items()
                if row.get("representation") == "aggregate"
                and row.get("target") not in admitted
                and row.get("target") not in certified}
    if orphaned:
        for key in orphaned:
            del selected[key]
        save_selection(run, selected)
    return orphaned


def check_admissions(run: Run, laws: dict, defs: list[dict], onto: Ontology, claimants: dict[str, list[str]]) -> tuple[list[str], list[str]]:
    """Before downstream work: reuse the admissions whose inputs are unchanged, restore one whose
    reading entry an interruption lost, take a base run's unchanged admissions, and retire the stale
    ones. Returns (notes, why the run must stop): a stale admission a node already claims stops it."""
    table = definitions_mod.load_table(run)
    defs_by_id = {str(d.get("id")): d for d in defs}
    notes, stop = [], []
    certs = _effective_certificates(jsonl.read_strict(certificates_file(run)))
    reading = Reading(run.reading_file)
    m = _load_manifest(run)
    for aid, cert in certs.items():                              # restore companions an interrupted admission lost
        if cert.get("input_digest") != checks.digest(inputs_of(run, cert["admitted"], table, defs_by_id, onto, laws)):
            continue
        restored = []
        if reading.aggregate(aid) is None:
            _set_reading(run, {**cert["admitted"], "admitted": f"{run.opts.run_id}/iter-{cert.get('iteration', 0):03d}"})
            restored.append("reading")
        have = m["aggregates"].get(aid)
        if not have or have.get("input_digest") != cert["input_digest"] or have.get("certificate") != cert["admitted"]["certificate"]:
            m["aggregates"][aid] = {"inputs": cert["inputs"], "input_digest": cert["input_digest"], "certificate": cert["admitted"]["certificate"]}
            _save_manifest(run, m)
            restored.append("manifest")
        if restored:
            notes.append(f"aggregate `{aid}`: restored its {' and '.join(restored)} from the certificate")
    if run.opts.base_run:
        base = paths.run_dir(run.opts.base_run)
        base_certs = _effective_certificates(jsonl.read_strict(base / "aggregate_certificates.jsonl"))
        base_selection = {(r["definition"], r["term"]): r for r in jsonl.read_strict(base / "aggregate_selection.jsonl")}
        for aid, cert in base_certs.items():
            if Reading(run.reading_file).aggregate(aid) is not None:
                continue
            # the base's admission rests on the base's selection row: it is compared with that row, and taken with it
            cur = inputs_of(run, cert["admitted"], table, defs_by_id, onto, laws, selection=base_selection)
            if cert.get("input_digest") == checks.digest(cur):
                selected = load_selection(run)
                selected.update({k: r for k, r in base_selection.items() if r.get("target") == aid and k not in selected})
                save_selection(run, selected)
                _record_admission(run, {**cert, "imported_from": run.opts.base_run}, cur)
                notes.append(f"aggregate `{aid}`: taken from base run `{run.opts.base_run}`'s admission, its inputs unchanged")
            elif claimants.get(aid):
                stop.append(f"aggregate `{aid}` of base run `{run.opts.base_run}` has changed inputs and is claimed by {claimants[aid]}")
    m = _load_manifest(run)
    selection = load_selection(run)
    for entry in list(Reading(run.reading_file).data.get("aggregates", [])):
        aid = entry.get("id")
        cur = inputs_of(run, entry, table, defs_by_id, onto, laws)
        have = m["aggregates"].get(aid)
        if have and have.get("input_digest") == checks.digest(cur):
            continue
        changed = sorted(k for k in cur if not have or have.get("inputs", {}).get(k) != cur[k])
        jsonl.append_atomic(certificates_file(run), {"aggregate_id": aid, "invalidates": entry.get("certificate"), "changed": changed,
                                                     "iteration": run.iteration})
        _set_reading(run, None, remove=aid)
        m["aggregates"].pop(aid, None)
        _save_manifest(run, m)
        for key, row in list(selection.items()):
            if row.get("target") == aid:
                del selection[key]
        save_selection(run, selection)
        if claimants.get(aid):
            stop.append(f"aggregate `{aid}` is stale ({', '.join(changed)} changed) and nodes {sorted(claimants[aid])} claim it")
        else:
            notes.append(f"aggregate `{aid}`: stale ({', '.join(changed)} changed); invalidated, derived again")
    return notes, stop


def _classes_block(onto: Ontology) -> str:
    return "### The classes of road users of the ontology\n\n" + "\n".join(f"- `{c}`: {onto.contract(c)}" for c in checks.road_user_classes(onto)) + "\n"


def _sources(table: dict, defs_by_id: dict[str, dict], definition: str) -> dict[str, str]:
    return {d: _ws(defs_by_id[d].get("text")) for d in definitions_mod.source_ids(table, definition)
            if d in defs_by_id}


def _uses_block(pairs: dict[tuple[str, str], list[str]]) -> str:
    out = []
    for (d, t), ls in sorted(pairs.items()):
        out.append(f"- `{d}` / \"{t}\": used by {', '.join(sorted(set(ls)))}")
    return "### The defined terms the laws use\n\n" + ("\n".join(out) or "(none)") + "\n"


def _defs_block(pairs, table, defs_by_id) -> str:
    ids = []
    for (d, _t) in pairs:
        for x in definitions_mod.source_ids(table, d):
            if x not in ids:
                ids.append(x)
    return "### The posted definitions\n\n" + "\n".join(f"- `{i}`: {_ws(defs_by_id[i].get('text'))}" for i in ids if i in defs_by_id) + "\n"


def _answer_defects(a: dict, pairs, table, defs_by_id, onto, want_pairs: set) -> list[str]:
    errs = []
    if set(a) - {"selection", "aggregates"}:
        errs.append("the answer has exactly the keys `selection` and `aggregates`")
    rows = a.get("selection") if isinstance(a.get("selection"), list) else None
    recs = a.get("aggregates") if isinstance(a.get("aggregates"), list) else None
    if rows is None or recs is None:
        return errs + ["`selection` and `aggregates` are lists"]
    sub = {"laws": {law: [r for r in rs if (r.get("definition"), r.get("term")) in want_pairs] for law, rs in table.get("laws", {}).items()}}
    sel, e = checks.validate_selection(rows, sub, defs_by_id)
    errs += e
    errs += [f"selection {d} / {t!r}: missing" for (d, t) in sorted(want_pairs - set(sel))]
    targets = {r["target"] for r in sel.values() if r["representation"] == "aggregate"}
    by_id = {}
    for rec in recs:
        aid = rec.get("aggregate_id") if isinstance(rec, dict) else None
        if aid not in targets:
            errs.append(f"aggregate `{aid}`: no selection row makes it an aggregate"); continue
        if aid in by_id:
            errs.append(f"aggregate `{aid}`: derived twice"); continue
        by_id[aid] = rec
        row = next(r for r in sel.values() if r["target"] == aid)
        errs += checks.record_defects(rec, onto, _sources(table, defs_by_id, row["definition"]))
    errs += [f"aggregate `{t}`: selected but not derived" for t in sorted(targets - set(by_id))]
    return errs


def select_and_derive(run: Run, table: dict, defs: list[dict], onto: Ontology, want: set[tuple[str, str]], out_dir: Path,
                      feedback: str = "", label: str = "plan_aggregates") -> tuple[dict, list[dict], list[str]]:
    """One planner session over the (definition, term) pairs `want`: (valid selection rows, valid
    mapping records, the defects that remained after the one re-ask)."""
    defs_by_id = {str(d.get("id")): d for d in defs}
    pairs = {p: ls for p, ls in checks.pairs_of(table).items() if p in want}
    if not pairs:
        return {}, [], []
    existing = load_selection(run)
    prompt = render.render("plan_aggregates.md", {
        "definitions": _defs_block(pairs, table, defs_by_id),
        "uses": _uses_block(pairs),
        "classes": _classes_block(onto),
        "selection": "### Rows already selected (read-only)\n\n" + ("\n".join(f"- `{r['definition']}` / \"{r['term']}\": {r['representation']}"
                                                                        for r in existing.values()) or "(none)") + "\n",
        "aggregate_gate_feedback": feedback or "(none)"})
    check = lambda a: _answer_defects(a, pairs, table, defs_by_id, onto, set(pairs))
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=check, model=run.opts.model, effort=run.opts.plan_effort)
    if answer is None:
        return {}, [], errs or ["dry run: no selection"]
    sub = {"laws": {law: [r for r in rs if (r.get("definition"), r.get("term")) in set(pairs)] for law, rs in table.get("laws", {}).items()}}
    sel, _e = checks.validate_selection(answer.get("selection") or [], sub, defs_by_id)
    recs = []
    for rec in answer.get("aggregates") or []:
        row = next((r for r in sel.values() if r.get("representation") == "aggregate" and r.get("target") == rec.get("aggregate_id")), None)
        if row and not checks.record_defects(rec, onto, _sources(table, defs_by_id, row["definition"])):
            recs.append(rec)
    return sel, recs, errs


def _verify_defects(a: dict, aid: str, classes: list[str]) -> list[str]:
    errs = []
    if set(a) != {"aggregate_id", "classifications"}:
        errs.append("the answer has exactly the keys `aggregate_id` and `classifications`")
    if a.get("aggregate_id") != aid:
        errs.append(f"`aggregate_id` is `{aid}`")
    cls = a.get("classifications")
    if not isinstance(cls, list):
        return errs + ["`classifications` is a list"]
    got = [c.get("class") for c in cls if isinstance(c, dict)]
    if sorted(got) != sorted(classes) or len(got) != len(set(got)):
        errs.append(f"every class appears exactly once: {classes}")
    for c in cls:
        if not isinstance(c, dict) or set(c) != {"class", "verdict", "reason"}:
            errs.append("each classification has exactly `class`, `verdict` and `reason`"); continue
        if c.get("verdict") not in GATE_VERDICTS:
            errs.append(f"{c.get('class')}: verdict is one of {list(GATE_VERDICTS)}")
        if not _ws(c.get("reason")):
            errs.append(f"{c.get('class')}: a reason")
    return errs


def verify(run: Run, rec: dict, sources: dict[str, str], onto: Ontology, out_dir: Path, label: str) -> tuple[dict | None, dict]:
    """The second-vendor verdicts on a mapping, by class, or None when the answer stayed malformed;
    with the exact request and response for the certificate. `SessionUnavailable` propagates."""
    classes = checks.road_user_classes(onto)
    prompt = render.render("verify_aggregate.md", {
        "definition": "### The posted definition(s)\n\n" + "\n".join(f"- `{k}`: {v}" for k, v in sources.items()) + "\n",
        "classes": _classes_block(onto),
        "record": "### The proposed classification\n\n```json\n" + json.dumps(rec, ensure_ascii=False, indent=1) + "\n```\n"})
    answer, errs = validate_phase._session(run, out_dir, label, prompt, check=lambda a: _verify_defects(a, rec["aggregate_id"], classes),
                                           model=run.opts.reviewer_model, effort=run.opts.review_effort)
    exchange = {"request_digest": checks.digest({"prompt": prompt, "model": run.opts.reviewer_model, "effort": run.opts.review_effort}),
                "prompt_hash": checks.digest(prompt), "response": answer, "defects": errs}
    if answer is None or errs:
        return None, exchange
    return {c["class"]: c for c in answer["classifications"]}, exchange


def _statuses(rec: dict) -> dict[str, str]:
    return {c["class"]: c["status"] for c in rec["classifications"]}


def gate(run: Run, rec: dict, sources: dict[str, str], onto: Ontology, out_dir: Path, retry,
         digests: dict[str, str]) -> tuple[dict, dict]:
    """Admit one mapping: (the reading entry, the certificate row). `retry(rec, feedback)` is the
    planner's one re-proposal after a contradiction (None when it wrote no valid mapping)."""
    aid = rec["aggregate_id"]
    cert = {"aggregate_id": aid, "proposal": rec, "retry": None, "exchanges": [], "downgrades": [],
            "model": run.opts.reviewer_model, "effort": run.opts.review_effort, **digests}
    verdicts, ex = verify(run, rec, sources, onto, out_dir, f"verify_{checks.slug(aid)}")
    cert["exchanges"].append(ex)
    current = rec
    if verdicts is None:
        raise SessionUnavailable(f"the aggregate gate's answer for `{aid}` stayed malformed; nothing is admitted")
    contradicted = [c for c, v in verdicts.items() if v["verdict"] == "contradicted"]
    if contradicted:
        feedback = "\n".join(f"- `{aid}` class `{c}`: proposed {_statuses(rec)[c]}; the gate found the posted words support the "
                             f"opposite: {_ws(verdicts[c]['reason'])}" for c in contradicted)
        new = retry(rec, feedback)
        cert["retry"] = {"feedback": feedback, "record": new, "model": run.opts.model, "effort": run.opts.plan_effort}
        if new is not None:
            current = new
            verdicts, ex = verify(run, new, sources, onto, out_dir, f"verify_{checks.slug(aid)}_retry")
            cert["exchanges"].append(ex)
            if verdicts is None:
                raise SessionUnavailable(f"the aggregate gate's answer for `{aid}` stayed malformed; nothing is admitted")
    statuses = {}
    for c, s in _statuses(current).items():
        v = verdicts.get(c, {}).get("verdict")
        if v == "supported":
            statuses[c] = s
        else:
            statuses[c] = "unresolved"
            if s != "unresolved":
                cert["downgrades"].append({"class": c, "why": "gate_contradiction" if v == "contradicted" else "underdetermined",
                                           "reason": _ws(verdicts.get(c, {}).get("reason"))})
    return _finish(cert, current, statuses, digests)


def _finish(cert: dict, rec: dict, statuses: dict[str, str], digests: dict[str, str]) -> tuple[dict, dict]:
    entry = checks.admitted(rec, statuses)
    entry["certificate"] = checks.digest({**digests, "record": rec, "exchanges": cert["exchanges"]})
    cert["admitted"] = entry
    cert["gate_input_digest"] = entry["certificate"]
    return entry, cert


def admit(run: Run, recs: list[dict], table: dict, defs: list[dict], onto: Ontology, out_dir: Path,
          laws: dict[str, corpus.Law] | None = None) -> tuple[list[dict], list[str], list[str]]:
    """Gate every mapping and merge the admitted ones into the run's reading: (entries, notes,
    lines for the operator). A law-local mapping quotes its law (`laws`)."""
    defs_by_id = {str(d.get("id")): d for d in defs}
    selection = load_selection(run)
    precedence_digest = definitions_mod.precedence_hash(run)
    entries, notes, to_user = [], [], []
    certs = _effective_certificates(jsonl.read_strict(certificates_file(run)))
    for rec in recs:
        aid = rec["aggregate_id"]
        if Reading(run.reading_file).aggregate(aid) is not None:
            if not checks.law_local(aid) or checks.digest((certs.get(aid) or {}).get("proposal")) == checks.digest(rec):
                continue                                  # admitted from this very record
            notes.append(f"law-local aggregate `{aid}`: the plan wrote another mapping under its id; gated again")
        if checks.law_local(aid):
            law_id = aid.split(":", 1)[0]
            sources = {law_id: _ws(laws[law_id].text)} if laws and law_id in laws else {}
            row = None
        else:
            sources = _sources(table, defs_by_id, rec.get("definition") or "")
            row = next((r for r in selection.values() if r.get("target") == aid), None)
        digests = {"definition_digest": checks.digest(sources), "ontology_digest": checks.ontology_digest(onto),
                   "selection_digest": checks.digest(row), "resolution_digest": checks.digest(checks.resolution_of(table, rec.get("definition") or "")),
                   "precedence_digest": precedence_digest}

        def retry(old: dict, feedback: str, aid=aid, row=row) -> dict | None:
            if row is None:
                return None                                   # a law-local mapping is re-planned with its law
            _sel, new_recs, _errs = select_and_derive(run, table, defs, onto, {(row["definition"], row["term"])}, out_dir,
                                                      feedback=feedback, label=f"plan_aggregates_retry_{checks.slug(aid)}")
            return next((r for r in new_recs if r.get("aggregate_id") == aid), None)
        entry, cert = gate(run, rec, sources, onto, out_dir, retry, digests)
        _record_admission(run, cert, inputs_of(run, rec, table, defs_by_id, onto, laws))
        entries.append(entry)
        down = cert["downgrades"]
        notes.append(f"aggregate `{aid}` admitted: included {len(entry['included'])}, unresolved {len(entry['unresolved'])}"
                     + (f"; downgraded to unresolved: {', '.join(d['class'] + ' (' + d['why'] + ')' for d in down)}" if down else ""))
    return entries, notes, to_user


def prepare(run: Run, laws: list[corpus.Law], defs: list[dict], onto: Ontology, out_dir: Path) -> tuple[list[str], list[str], dict[str, str], str]:
    """Before any plan batch: select and derive for every resolved pair not yet selected, gate the
    aggregates, merge the admitted ones. A selected aggregate with no effective certificate is an
    interrupted admission and is selected and derived again. Returns (notes, lines for the operator,
    laws held this iteration with why: a pair whose selection stayed defective, the reason the run
    stops, or ""): a pair that stays defective a second time stops the run."""
    table = definitions_mod.load_table(run)
    selected = load_selection(run)
    _drop_orphan_selections(run, selected)
    want = set(checks.missing_pairs(selected, table))
    if not want:
        return [], [], {}, ""
    out_dir.mkdir(parents=True, exist_ok=True)
    sel, recs, errs = select_and_derive(run, table, defs, onto, want, out_dir)
    if run.opts.dry_run:
        return [f"dry run: the selection prompt for {len(want)} defined term(s) is in {out_dir}"], [], {}, ""
    selected.update(sel)
    save_selection(run, selected)
    hold, stop = {}, []
    pairs = checks.pairs_of(table)
    derived = {r.get("aggregate_id") for r in recs}
    underived = {key for key, row in sel.items() if row.get("representation") == "aggregate" and row.get("target") not in derived}
    for p in sorted((want - set(sel)) | underived):
        what = "the mapping of" if p in underived else "the representation of"
        key = f"select:{p[0]}::{p[1]}"
        run.aggregate_failures[key] = run.aggregate_failures.get(key, 0) + 1
        why = f"{what} `{p[0]}` / \"{p[1]}\" stayed defective: " + "; ".join(errs)[:300]
        if run.aggregate_failures[key] >= 2:
            stop.append(why + f" (iteration after iteration, {run.aggregate_failures[key]} times)")
        for law in pairs.get(p, []):
            hold[law] = why + "; held, uncharged, and asked again next iteration"
    for p in set(sel) - underived:
        run.aggregate_failures.pop(f"select:{p[0]}::{p[1]}", None)
    notes = [f"selection: {sum(1 for r in sel.values() if r['representation'] == 'aggregate')} aggregate, "
             f"{sum(1 for r in sel.values() if r['representation'] == 'not_aggregate')} not an aggregate, "
             f"{sum(1 for r in sel.values() if r['representation'] == 'gap')} gap, of {len(want)} defined term(s)"]
    entries, n2, to_user = admit(run, recs, table, defs, onto, out_dir)
    return notes + n2, to_user, hold, "; ".join(stop)


def claimed_ids(nodes) -> dict[str, set[str]]:
    """law → the aggregate ids its nodes claim (`ru.aggregate=<id>`)."""
    out: dict[str, set[str]] = {}
    for n in nodes:
        for c in n.claimed_atoms():
            if c.startswith("ru.aggregate="):
                out.setdefault(n.law, set()).add(c.split("=", 1)[1])
    return out


def correct_claims(run: Run, claims: dict[str, set[str]], defs: list[dict], onto: Ontology, ledger, out_dir: Path) -> tuple[list[str], dict[str, str]]:
    """A plan that claims a definition-scoped id the selection did not make an aggregate: the
    selection role is asked once, per law, to keep its representation or to make it an aggregate
    with quoted support (then derived and gated). Returns (notes, laws to close with why: a second
    such claim)."""
    reading = Reading(run.reading_file)
    table = definitions_mod.load_table(run)
    selection = load_selection(run)
    want, notes, close, first_claims = set(), [], {}, set()
    for law, ids in claims.items():
        bad = [i for i in ids if not checks.law_local(i) and reading.aggregate(i) is None]
        if not bad:
            continue
        if ledger.entries[law].selection_corrections:
            close[law] = f"planning_protocol_failure: the plan again claims aggregate id(s) {bad} that the selection does not admit"
            continue
        first_claims.add(law)
        for i in bad:
            d, _, t = i.partition("::")
            pair = next((p for p in checks.pairs_of(table) if p[0] == d and checks.slug(p[1]) == t), None)
            if pair:
                want.add(pair)
            else:
                notes.append(f"`{law}` claims `{i}`, which names no resolved definition and term of this law")
    if not want:
        for law in first_claims:
            ledger.selection_correction(law)
        return notes, close
    feedback = ("Plans claim these aggregate ids, which the selection did not make aggregates. For each, either keep the row as it "
                "is (the plan then maps the words without the aggregate) or make it `aggregate` with quoted support and derive its "
                "mapping:\n" + "\n".join(f"- `{d}` / \"{t}\" (now: {selection.get((d, t), {}).get('representation', 'not selected')})" for d, t in sorted(want)))
    for p in want:
        selection.pop(p, None)
    sel, recs, _errs = select_and_derive(run, table, defs, onto, want, out_dir, feedback=feedback, label="plan_aggregates_correction")
    selection.update(sel)
    save_selection(run, selection)
    _entries, n2, _to_user = admit(run, recs, table, defs, onto, out_dir)
    for law in first_claims:
        ledger.selection_correction(law)
    return notes + n2, close
