"""Plan: one session writes blueprint.jsonl and PLAN.md for the plannable laws; the gaps its records propose are filed by the harness in the gap ledger."""
from __future__ import annotations
from dataclasses import dataclass, field
import json
from pathlib import Path
from ..checks import aggregates
from ..model import acquisition, corpus, definitions as definitions_mod, nodeid, ontology
from ..agents import render, session
from ..store import jsonl, paths
from ..store.gaps import GapLedger
from ..model.mapping import MappingIndex
from ..model.reading import Reading
from ..lean import surface
from . import review as review_phase
from ..model import blueprint
from ..model.blueprint import ConceptRecord, Node
from ..store.state import Run



#: The evidence of a planning or node repair session that is no law-level label repair. A run's
#: `label_repair` option gives such a session no label scope.
NO_LABEL_EVIDENCE = "## Repair evidence\n\nNo law-level label-repair evidence is supplied for this session.\n"


def evidence_block(run: Run, laws: list[corpus.Law], label_repair: bool = False) -> str:
    """The evidence a planning session is shown. A law-level label repair's re-plan (`label_repair`,
    set by that entry point only) is shown the label evidence of each of these laws that awaits its
    label repair, the `## Label mismatches` block its last committed label check rendered with the
    label contract and the repair goal; every other planning session `NO_LABEL_EVIDENCE`."""
    if not label_repair:
        return NO_LABEL_EVIDENCE
    states = getattr(run, "label_states", {}) or {}
    blocks = [(run.dir / states[l.id]["evidence"]).read_text(encoding="utf-8") for l in laws
              if states.get(l.id, {}).get("state") == "awaiting_label_repair" and (run.dir / states[l.id].get("evidence", "")).is_file()]
    return "\n".join(blocks) or NO_LABEL_EVIDENCE


def parameter_catalogue(reading: Reading) -> str:
    if not reading.params:
        return "(the catalogue is empty: every parameter a node needs is proposed in its `param_proposals` with unit, provisional value, convention and source)\n"
    out = ["| parameter | unit | convention |", "|---|---|---|"]
    for name, p in sorted(reading.params.items()):
        out.append(f"| `{name}` | {p.get('unit', '')} | {p.get('convention', '')} |")
    return "\n".join(out) + "\n"

def declaration_catalogue(reading: Reading, pending: list[dict] | None = None) -> str:
    """The one catalogue of declared-fact ids, assumptions (`asm.*`) and declared intentions
    (`int.*`), with their meanings: the reading's, then those the nodes of earlier batches of this
    iteration declared. A node reuses an id whose meaning is its words' meaning, and proposes a new
    id with its meaning only where none is."""
    rows = {i: (" ".join(str(d.get("meaning", "")).split()), "reviewed" if not d.get("proposed") else "proposed")
            for i, d in (reading.declarations() if hasattr(reading, "declarations") else {}).items()}
    for n in pending or []:
        for d in n.get("assumptions", []) + n.get("intentions", []):
            if isinstance(d, dict) and d.get("id") and str(d.get("meaning") or "").strip():
                rows.setdefault(d["id"], (" ".join(str(d["meaning"]).split()), f"declared this iteration by {n.get('node_id')}"))
    if not rows:
        return ("\n### Declared-fact ids (assumptions `asm.*`, declared intentions `int.*`)\n(the catalogue is empty: an id a node "
                "needs is declared on its span with its `meaning`)\n")
    out = ["", "### Declared-fact ids (assumptions `asm.*`, declared intentions `int.*`): reuse an id whose meaning is the words' meaning",
           "| id | meaning | status |", "|---|---|---|"]
    out += [f"| `{i}` | {m} | {st} |" for i, (m, st) in sorted(rows.items())]
    return "\n".join(out) + "\n"


PLACEHOLDERS = ("laws", "definitions", "ontology", "formula_language", "concept_language", "library_summary", "concepts", "mapping_index",
                "parameters", "gaps", "feedback", "evidence", "previous_records", "user_hints", "anchors", "aggregate_atom")
PLACEHOLDERS_REPAIR = ("concept", "verdict", "task_result", "final_files", "ontology", "formula_language", "concept_language", "concepts",
                       "definition", "users")
PLACEHOLDERS_NODE_REPAIR = ("law", "definitions", "node", "verdict", "evidence", "coder_narrowings", "task_result", "final_files", "ontology", "formula_language",
                            "concept_language", "concepts", "parameters", "anchors", "aggregate_atom")


def definitions_for(run: Run, laws: list[corpus.Law]) -> list[dict]:
    """The posted definitions that apply to a batch's laws, by the run's resolution table: every
    record a resolved term reaches through its cross-references, and every candidate of an
    ambiguous term."""
    out, seen = [], set()
    for law in laws:
        for d in definitions_mod.applicable(run, law.id):
            if d.get("id") not in seen:
                seen.add(d.get("id")); out.append(d)
    return out


def definitions_block(run: Run, laws: list[corpus.Law]) -> str:
    """The definitions table (term → applicable definition → representation → admitted aggregate),
    read-only, then the texts of the definitions that apply."""
    from . import aggregate as aggregate_phase
    rows = {law.id: definitions_mod.rows_for(run, law.id) for law in laws}
    return ("### The defined terms of these laws (read-only: resolved by the operator's declared precedence; aggregates "
            "selected and admitted by the run)\n\n" + aggregates.render(Reading(run.reading_file), rows, aggregate_phase.load_selection(run))
            + "\n### The definitions that apply\n\n" + corpus.render_definitions(definitions_for(run, laws)))


def concept_catalogue(run: Run) -> str:
    from ..model import nodeid
    concepts = run.all_concepts()
    text = surface.concepts_table({k: v for k, v in concepts.items() if not v.get("fenced")}, surface.current_callers(run))
    bad = {k: v for k, v in concepts.items() if v.get("fenced")}
    if bad:
        from ..checks.validate_a import fence_words
        text += ("\nFenced concept versions — never claim them. A successor `<id>_v<n+1>` with the same contract supersedes one "
                 "(`supersedes` naming it) without a counterexample: its fence stands for it. Or map the words around it:\n" + "".join(
                     f"- `{k}` — {fence_words(v['fenced'])}; its contract: {' '.join(str(v.get('contract', '')).split())[:400]}; "
                     f"the evidence: {str(v['fenced'].get('evidence', ''))[:300]}\n" for k, v in bad.items()))
    if run.opts.mode == "test":
        text += "\nThis run adds concepts and supersedes none: a catalogued concept whose body contradicts its contract is reported under `## Concept defects` in `PLAN.md`, not replaced.\n"
    return text + f"\nConcept families (the fixed grammar `drv.<family>.<name>`): {', '.join(nodeid.CONCEPT_FAMILIES)}.\n"


def library_summary(run: Run, pending: list[dict] | None = None) -> str:
    """The published nodes with two states apart: whether a node may be composed now (`build`, the
    run's availability rule `Run.provider_code`, never its law's formal acceptance) and its law's
    ledger state (`law`)."""
    from ..store.state import Availability, USABLE
    from ..store.ledger import Entry, _load
    entries = run.law_entries if run.law_entries is not None else _load(run.ledger_file, Entry, "law")
    av = Availability(run, entries=entries)
    rows = []
    for n in run.all_nodes().values():
        atoms = sorted(Node(n).claimed_atoms())
        code = av.code(n["node_id"], None)
        build = "composable (build)" if code == USABLE else f"not composable: {code}"
        law = (entries.get(Node(n).law).state if entries.get(Node(n).law) else "inherited")
        rows.append(f"| `{n['node_id']}` | {', '.join(n['law_refs'])} | {', '.join(b['name'] for b in n['binders'])} | {', '.join(atoms)} | {build} | {law} |")
    for n in pending or []:
        atoms = sorted(Node(n).claimed_atoms())
        rows.append(f"| `{n['node_id']}` | {', '.join(n['law_refs'])} | {', '.join(b['name'] for b in n.get('binders', []))} | {', '.join(atoms)} | "
                    "not composable: planned this iteration, not yet published | planned |")
    if not rows:
        return "(the library carries no accepted node yet)\n"
    return "\n".join(["| node | law | binders | atoms claimed | build | law state |", "|---|---|---|---|---|---|"] + rows) + "\n"


def pending_concepts_table(pending: list[dict] | None) -> str:
    """The concept records a concept repair or an earlier batch of this iteration proposed: the
    planner reuses them by id and proposes none of them again."""
    recs = [r for r in pending or [] if "concept_id" in r and "node_id" not in r]
    if not recs:
        return ""
    out = ["", "### Concepts proposed this iteration by a concept repair or an earlier batch (not yet accepted; reuse by id, never re-propose; a differing record under the same id is dropped)",
           "| id | kind | contract | definition | args | params | atoms | used by |", "|---|---|---|---|---|---|---|---|"]
    for rec in recs:
        args = ", ".join(f"{a.get('name')}:{a.get('sort')}" + (f"{a.get('values')}" if a.get("sort") == "literal" else "") for a in rec.get("args", []))
        params = ", ".join(f"{p.get('name')} ({p.get('unit')})" for p in rec.get("params", []))
        atoms = sorted({a for e in rec.get("elements", []) for a in e.get("atoms", []) + e.get("concepts", [])})
        out.append(f"| `{rec.get('concept_id')}` | {rec.get('kind')} | {' '.join(str(rec.get('contract', '')).split())} | {rec.get('definition') or ''} | {args} | {params} | "
                   f"{', '.join(atoms)} | {', '.join(rec.get('used_by', []))} |")
    return "\n".join(out) + "\n"


def pending_mappings_table(pending: list[dict] | None) -> str:
    """Span text → atoms of the nodes earlier batches of this iteration planned: the validator holds
    a later batch to the same mapping of the same words unless `PLAN.md` records a dispute."""
    rows = {}
    for n in pending or []:
        if "node_id" not in n:
            continue
        spans = {s.get("id"): s.get("text", "") for s in n.get("segmentation", [])}
        for e in n.get("elements", []):
            text = " ".join(spans.get(e.get("span"), "").split())
            if text:
                rows.setdefault(text, (sorted(set(e.get("atoms", [])) | set(e.get("derived", []))), n["node_id"]))
    if not rows:
        return ""
    out = ["", "### Spans mapped this iteration by an earlier batch (not yet accepted; the same words map to the same atoms, or `PLAN.md` records a dispute)",
           "| words | atoms | node |", "|---|---|---|"]
    for text, (atoms, nid) in sorted(rows.items()):
        out.append(f"| {text[:100]} | {', '.join(atoms)} | {nid} |")
    return "\n".join(out) + "\n"


def pending_proposals_table(pending: list[dict] | None) -> str:
    """The parameters the nodes of earlier batches of this iteration proposed, each with its full
    convention (escaped for its table cell). A proposal enters the reading only when its node is
    coded, so every node that uses a parameter of this table the reading's catalogue lacks proposes
    it again in its own `param_proposals`, under the same name with the same value, unit and
    convention; a node that names it without proposing it, or proposes it otherwise, is returned."""
    rows: dict[str, tuple] = {}
    for n in pending or []:
        if "node_id" not in n:
            continue
        for pr in n.get("param_proposals", []):
            if isinstance(pr, dict) and pr.get("name"):
                rows.setdefault(pr["name"], (pr.get("value"), pr.get("unit"), " ".join(str(pr.get("convention", "")).split()), n["node_id"]))
    if not rows:
        return ""
    out = ["", "### Parameters proposed this iteration by an earlier batch (not entered in the reading until their nodes are coded: every "
               "node that uses one the catalogue above lacks proposes it again in its own `param_proposals`, with the same name, value, "
               "unit and convention)",
           "| parameter | value | unit | convention | node |", "|---|---|---|---|---|"]
    for name, (v, u, c, nid) in sorted(rows.items()):
        cell = c.replace("\\", "\\\\").replace("|", "\\|")      # for display only; whitespace is already one space
        out.append(f"| `{name}` | {v} | {u} | {cell} | {nid} |")
    return "\n".join(out) + "\n"


def _read_json(f: Path):
    """A run's JSON file: None when absent, `_UNREAD` when it cannot be read."""
    if not f.exists():
        return None
    try:
        return json.loads(f.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return _UNREAD


_UNREAD = object()
_ws = review_phase._ws


def _law_id(raw: dict) -> str:
    refs = raw.get("law_refs")
    return str(refs[0]) if isinstance(refs, list) and refs else ""


def _task_state(task: Path) -> str:
    """What the gate decided on one coding task, as it recorded it."""
    v = _read_json(task / "verdict.json")
    if not isinstance(v, dict):
        return "coded: " + ("the gate verdict could not be read" if v is _UNREAD else "no gate verdict recorded")
    return f"coded: gate {v.get('verdict', 'not run')}" + (f" ({_ws('; '.join(str(x) for x in (v.get('details') or [])[:2]))[:240]})" if v.get("details") else "")


def _duty(raw: dict, law: corpus.Law) -> dict:
    return review_phase.duty_of(Node(raw), law)


class _Entry:
    """One node of a law's history: its duty's occurrence in the law, the record as planned, each
    later version with where it comes from, what each iteration decided, and the accepted record."""
    def __init__(self, nid: str, duty: dict):
        self.id, self.duty = nid, duty
        self.planned: dict | None = None
        self.versions: list[tuple[str, dict]] = []
        self.lines: dict[int, list[str]] = {}
        self.accepted: dict | None = None

    def matches(self, raw: dict, law: corpus.Law) -> bool:
        """The same node: the same id and the same occurrence of the law's words as its duty (by
        the id alone only where either duty is not located in the text)."""
        if self.id != raw.get("node_id"):
            return False
        duty = _duty(raw, law)
        return self.duty["id"] == duty["id"] if self.duty["ranges"] and duty["ranges"] else True

    def note(self, it: int, text: str) -> None:
        self.lines.setdefault(it, []).append(text)

    def state(self) -> str:
        if self.accepted is not None:
            return "accepted" + (", then fenced" if self.accepted.get("fenced") else "")
        return "not accepted" + ("" if any(src.startswith("as coded") for src, _r in self.versions) else ", never coded")


def _entry(entries: list[_Entry], raw: dict, law: corpus.Law) -> _Entry:
    for e in entries:
        if e.matches(raw, law):
            return e
    e = _Entry(str(raw.get("node_id")), _duty(raw, law))
    entries.append(e)
    return e


def law_history(run: Run, law: corpus.Law) -> tuple[int | None, list[_Entry], list[str]]:
    """A law's nodes in this run: every node of the latest plan before this iteration that holds a
    node of the law, coded or not; then, iteration by iteration up to this one, each repair, the
    validator's verdict, each coding task with the gate's and the review's outcome; and the accepted
    record. Versions are kept in the order they were made, so a later repair or coding is never
    hidden behind the plan. Returns the plan's iteration (None when none is recorded), the entries,
    and what could not be read."""
    unread: list[str] = []
    entries: list[_Entry] = []
    k = None
    for it in range(run.iteration - 1, 0, -1):
        try:
            planned = [n.raw for n in blueprint.load(paths.iter_dir(run.opts.run_id, it) / "plan" / "blueprint.jsonl") if _law_id(n.raw) == law.id]
        except ValueError as ex:
            unread.append(f"the plan of iteration {it} could not be read: {ex}")
            continue
        if planned:
            k = it
            for raw in planned:
                e = _entry(entries, raw, law)
                e.planned = raw
                e.versions.append((f"as planned in iteration {it}", raw))
                e.note(it, "planned")
            break
    first = k if k is not None else 1
    for it in range(first, run.iteration + 1):
        d = paths.iter_dir(run.opts.run_id, it)
        if it > first:                       # an iteration's repairs run before its plan: those of the plan's iteration are older
            for rdir in sorted(p for p in (d / "repair").glob("*") if (p / "planned.json").exists()) if (d / "repair").exists() else []:
                was = _read_json(rdir / "planned.json")
                if not isinstance(was, dict) or _law_id(was) != law.id:
                    if was is _UNREAD and nodeid.law_of(rdir.name)[0] == law.id:
                        unread.append(f"the repair of `{rdir.name}` in iteration {it} could not be read")
                    continue
                e = _entry(entries, was, law)
                rep = read_repair(rdir, concept=False)
                if rep.kind == "revised" and rep.validation == []:
                    e.versions.append((f"as repaired in iteration {it}", rep.records[0].raw))
                    e.note(it, "repaired; the validator accepted the revision")
                elif rep.kind == "revised":
                    e.note(it, "repaired; " + ("the revision was not validated" if rep.validation is None else
                                               "the validator returned the revision: " + _ws("; ".join(rep.validation[:2]))[:240]))
                elif rep.kind == "withdrawn":
                    w = rep.withdrawal or {}
                    e.note(it, f"the repair withdrew it ({w.get('kind', '?')}, span {w.get('span', '?')}: {_ws(w.get('missing'))[:160]})")
                else:
                    e.note(it, "the repair wrote no usable record" + (f" ({rep.message})" if rep.message else ""))
        verdicts: dict = {}
        vf = d / "validate" / "verdicts.jsonl"
        for line in vf.read_text(encoding="utf-8").splitlines() if vf.exists() else []:
            try:
                row = json.loads(line)
            except ValueError:
                unread.append(f"a validator verdict of iteration {it} could not be read")
                continue
            if isinstance(row, dict):
                verdicts[row.get("node_id")] = row
        coded = {}
        for f in sorted((d / "code").glob("*/node.json")) if (d / "code").exists() else []:
            raw = _read_json(f)
            if isinstance(raw, dict) and _law_id(raw) == law.id:
                coded[raw.get("node_id")] = (raw, f.parent)
            elif raw is _UNREAD and nodeid.law_of(f.parent.name)[0] == law.id:
                unread.append(f"the coded record of `{f.parent.name}` in iteration {it} could not be read")
        for nid, row in verdicts.items():
            same = [e for e in entries if e.id == nid]
            if len(same) == 1 and nid not in coded:
                same[0].note(it, f"validator {row.get('kind')}" + ("" if row.get("kind") == "accept" else
                                 ": " + _ws("; ".join(str(r) for r in (row.get("reasons") or [])[:2]))[:240]) + "; not coded")
        for nid, (raw, task) in coded.items():
            e = _entry(entries, raw, law)
            e.versions.append((f"as coded in iteration {it}", raw))
            e.note(it, (f"validator {verdicts[nid].get('kind')}; " if nid in verdicts else "") + _task_state(task))
    accepted = run.all_nodes()
    for e in entries:
        if e.id in accepted and e.matches(accepted[e.id], law):
            e.accepted = accepted[e.id]
            e.versions.append(("as accepted", e.accepted))
    return k, entries, unread


def _chars(duty: dict) -> str:
    return ", ".join(f"{a}–{z}" for a, z in duty["ranges"])


def _words(duty: dict) -> str:
    if not duty["ranges"]:
        return "its duty is not located in the law's text"
    return "its duty: " + "; ".join(f"“{_ws(w)}” (characters {a}–{z})" for w, (a, z) in zip(duty["words"], duty["ranges"]))


def _latest_elsewhere(run: Run, rid: str) -> tuple[str, dict, str] | None:
    """A node of another law: its accepted record, else its latest coded or planned record in this
    run, with its source and state."""
    acc = run.all_nodes().get(rid)
    if acc is not None:
        return "as accepted", acc, "accepted" + (", then fenced" if acc.get("fenced") else "")
    for it in range(run.iteration, 0, -1):
        d = paths.iter_dir(run.opts.run_id, it)
        raw = _read_json(d / "code" / rid / "node.json")
        if isinstance(raw, dict):
            return f"as coded in iteration {it}", raw, f"not accepted; {_task_state(d / 'code' / rid)}"
        try:
            hit = [n.raw for n in blueprint.load(d / "plan" / "blueprint.jsonl") if n.id == rid]
        except ValueError:
            hit = []
        if hit:
            return f"as planned in iteration {it}", hit[0], "not accepted, not coded since"
    return None


def _composes(run: Run, raw: dict, entries: list[_Entry], laws: dict[str, corpus.Law], elsewhere: list[str]) -> list[str]:
    """One line per composition of a record: the referring span's words and what the named node is
    (its duty and state), or `missing`; a node of another law is added to `elsewhere`."""
    spans = {s.get("id"): s.get("text", "") for s in raw.get("segmentation") or [] if isinstance(s, dict)}
    out = []
    for c in raw.get("compositions") or []:
        if not isinstance(c, dict):
            continue
        if c.get("as") == blueprint.DEFINITION:
            out.append(f"- span `{c.get('span')}` “{_ws(spans.get(c.get('span'), ''))}” borrows from `{c.get('source')}` the words "
                       f"“{_ws(c.get('quote'))}” (as definition: no rule is composed)")
            continue
        rid = str(c.get("rule"))
        same = [e for e in entries if e.id == rid]
        hit = None if same else _latest_elsewhere(run, rid)
        if len(same) == 1:
            what = (f"its duty at characters {_chars(same[0].duty)}; " if same[0].duty["ranges"]
                    else "its duty is not located in the law's text; ") + same[0].state()
        elif same:
            what = "ambiguous: records of different duties carry this id — " + " | ".join(_words(e.duty) for e in same)
        elif hit is None:
            what = "missing: no record of this id in this run or among the accepted nodes"
        elif _law_id(hit[1]) == _law_id(raw):
            law = laws.get(_law_id(raw))
            what = (f"{_words(_duty(hit[1], law))}; " if law else "") + f"{hit[2]}; a record {hit[0]}, not a node of the plan above"
        else:
            what = "a node of another law, below"
            if rid not in elsewhere:
                elsewhere.append(rid)
        out.append(f"- span `{c.get('span')}` “{_ws(spans.get(c.get('span'), ''))}” composes `{rid}` as {c.get('as')}: {what}")
    return out or ["- composes no rule"]


def _elsewhere_block(run: Run, elsewhere: list[str], laws: dict[str, corpus.Law]) -> list[str]:
    """The nodes of other laws the records compose, followed along their own compositions, each once."""
    out: list[str] = []
    done: set[str] = set()
    while elsewhere:
        rid = elsewhere.pop(0)
        if rid in done:
            continue
        done.add(rid)
        hit = _latest_elsewhere(run, rid)
        if hit is None:
            out += [f"`{rid}`: missing: no record of this id in this run or among the accepted nodes", ""]
            continue
        src, raw, state = hit
        law = laws.get(_law_id(raw))
        out += [f"`{rid}` ({_law_id(raw)}) — " + (_words(_duty(raw, law)) if law else "its law is not in this corpus"), "",
                f"- state: {state}; the record {src}", f"- applicability: {_ws(raw.get('applicability'))}",
                f"- obligation: {_ws(raw.get('obligation'))}"]
        out += _composes(run, raw, [], laws, elsewhere) + [""]
    return (["### Nodes of other laws these records compose", ""] + out) if out else []


def _known_laws(run: Run, laws: list[corpus.Law]) -> dict[str, corpus.Law]:
    out = {l.id: l for l in laws}
    try:
        return {**{l.id: l for l in corpus.load_laws(run.opts.laws)}, **out}
    except (OSError, ValueError, AttributeError):
        return out


def _differs(old: dict, new: dict) -> list[str]:
    """The fields in which two versions of a record differ; for a list of items named by a span or a
    name, the items that differ."""
    def key(x):
        return (x.get("span") or x.get("name")) if isinstance(x, dict) else None
    out = []
    for k in sorted(set(old) | set(new)):
        a, b = old.get(k), new.get(k)
        if a == b:
            continue
        if isinstance(a, list) and isinstance(b, list) and all(key(x) for x in a + b):
            names = sorted({str(key(x)) for x in a + b if [y for y in a if key(y) == key(x)] != [y for y in b if key(y) == key(x)]})
            out.append(f"`{k}` ({', '.join(names)})")
        else:
            out.append(f"`{k}`")
    return out


def previous_records(run: Run, laws: list[corpus.Law]) -> str:
    """For each law planned again: every node of its latest plan, those never coded included, each
    with what every later iteration decided (repair, validator, gate, review, acceptance), its latest
    version in full and, where it differs, the fields the plan had otherwise; what each record composes, with the
    composed node's duty and state or `missing`; and the nodes of other laws they compose, followed
    along their own compositions. Empty for a law no earlier iteration planned or coded."""
    known = _known_laws(run, laws)
    out: list[str] = []
    elsewhere: list[str] = []
    for law in laws:
        k, entries, unread = law_history(run, law)
        if not entries and not unread:
            continue
        out += [f"### `{law.id}`: " + (f"the plan of iteration {k} and what followed" if k is not None else
                                        "no plan of this law is recorded in this run; its later records"), ""]
        out += [f"- {u}" for u in unread] + ([""] if unread else [])
        for e in entries:
            src, raw = e.versions[-1]
            out += [f"`{e.id}` — {_words(e.duty)}", ""]
            out += [f"- iteration {it}: {'; '.join(ls)}" for it, ls in sorted(e.lines.items())]
            out += [f"- state: {e.state()}"] + _composes(run, raw, entries, known, elsewhere)
            out += ["", f"The record, {src}:", "", "```json", json.dumps(raw, ensure_ascii=False, indent=1), "```", ""]
            if e.planned is not None and _differs(e.planned, raw):
                out += [f"It differs from the record planned in iteration {k} in: {', '.join(_differs(e.planned, raw))}.", ""]
    out += _elsewhere_block(run, elsewhere, known)
    if not out:
        return ""
    return "## Your previous record of these laws\n\n" + "\n".join(out) + "\n"


def repair_context(run: Run, node, law: corpus.Law, siblings: list) -> str:
    """For a node repair, read-only: the law's other nodes, each in the record the repair is
    validated with, with its duty, its state and what it composes; what this node composes; and the
    nodes of other laws they compose, followed along their own compositions."""
    known = _known_laws(run, [law])
    _k, entries, _unread = law_history(run, law)
    elsewhere: list[str] = []
    out = ["## The law's other nodes and what the records compose (read-only)", "",
           "Each other node of the law in the record your revision is validated with, with its state.", ""]
    for s in [s for s in siblings if s.id != node.id]:
        e = next((x for x in entries if x.matches(s.raw, law)), None)
        src = next((label for label, raw in reversed(e.versions) if raw == s.raw), "") if e else ""
        state = e.state() if e else ("accepted" if s.id in run.all_nodes() else "not accepted")
        out += [f"`{s.id}` — {_words(_duty(s.raw, law))}", "", f"- state: {state}" + (f"; the record {src}" if src else ""),
                f"- applicability: {_ws(s.raw.get('applicability'))}", f"- obligation: {_ws(s.raw.get('obligation'))}"]
        out += [f"- span `{el.get('span')}`: {', '.join(list(el.get('atoms') or []) + list(el.get('derived') or []))}"
                for el in s.raw.get("elements") or [] if isinstance(el, dict)]
        out += _composes(run, s.raw, entries, known, elsewhere) + [""]
    out += [f"This node, `{node.id}`:"] + _composes(run, node.raw, entries, known, elsewhere) + [""]
    out += _elsewhere_block(run, elsewhere, known)
    return "\n".join(out) + "\n"


def run_plan(run: Run, laws: list[corpus.Law], defs: list[dict], tag: str = "", pending: list[dict] | None = None,
             label_repair: bool = False) -> Path:
    """One plan session over `laws`. With a `tag` the session writes under `iter/plan/<tag>/` (one
    batch of several); `pending` lists the nodes and concept records earlier batches of this
    iteration planned, so a law that names one of their laws can compose the node by its id and
    reuse the concept by its id. `label_repair` marks the re-plan of a law-level label repair, the
    one planning session shown label evidence (`evidence_block`). A batch directory that already holds a session result and a
    blueprint is a finished batch: it is returned as it is, without a session."""
    plan_dir = run.iter / "plan" / tag if tag else run.iter / "plan"
    plan_dir.mkdir(parents=True, exist_ok=True)
    if session.finished(plan_dir) and (plan_dir / "blueprint.jsonl").exists():
        return plan_dir
    onto = ontology.load(run.opts.ontology)
    values = {
        "laws": corpus.render_laws(laws),
        "definitions": definitions_block(run, laws) + definitions_mod.render_sources(definitions_mod.cited_sources(run, laws), definitions_mod.CITED_HEADING),
        "ontology": onto.text,
        "formula_language": surface.formula_language(),
        "concept_language": surface.concept_language(),
        "library_summary": library_summary(run, [n for n in pending or [] if "node_id" in n]),
        "concepts": concept_catalogue(run) + pending_concepts_table(pending),
        "mapping_index": MappingIndex(run.mapping_file).render() + pending_mappings_table(pending),
        "parameters": parameter_catalogue(Reading(run.reading_file)) + acquisition.standard_note(getattr(run.opts, "acquisition_profile", None))
                      + pending_proposals_table(pending)
                      + declaration_catalogue(Reading(run.reading_file), pending),
        "gaps": GapLedger(paths.GAPS_DIR).render({l.id for l in corpus.load_laws(run.opts.laws)}, run.opts.base_run),
        "feedback": run.read_notes(),
        "evidence": evidence_block(run, laws, label_repair),
        "previous_records": previous_records(run, laws),
        "user_hints": run.read_hints(),
        "anchors": ontology.anchors_text(onto),
        "aggregate_atom": ontology.AGGREGATE,
    }
    prompt = render.render("plan.md", values)
    validate_cmd = f"python -m harness validate --run_id {run.opts.run_id} --blueprint_file {(plan_dir / 'blueprint.jsonl').resolve()}"
    prompt += (f"\n\n## Where to write\n\nWorking directory: `{plan_dir.resolve()}`. Write `aggregates.jsonl`, `blueprint.jsonl` and "
               "`PLAN.md` there with the Write tool, as files, by hand. Everything you need is in this prompt: you read no "
               "other file, and the shell runs exactly one command, the validator below — any other command is denied.\n\n"
               "## Checking a draft\n\nThe deterministic validator the harness will run, with the run's accepted nodes, concepts, "
               "mapping index, reading and your `aggregates.jsonl`, is available to you on a draft:\n\n"
               f"```\n{validate_cmd}\n```\n\nRun it exactly as written. It prints one line per node (`accept`, `return`, `fail`) with the reasons. "
               "Run it once the file is complete, fix what it names, and stop when every node is `accept`. "
               "It is the only program you run; the self-check is yours, the schema check is its.\n")
    (plan_dir / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return plan_dir
    clear = lambda: [(plan_dir / name).unlink(missing_ok=True) for name in PLAN_OUTPUTS]
    if not session.finished(plan_dir) and session.last_launch(plan_dir) is not None:
        clear()                                  # what an unfinished launch wrote is not a plan
    session.run(prompt, cwd=plan_dir, out_dir=plan_dir, opts=run.opts, max_turns=run.opts.plan_turns,
                effort=run.opts.plan_effort, label="session", allow=session.plan_allow(plan_dir, validate_cmd),
                deny=session.deny_rules("plan", run.opts.run_id), tools=session.PLAN_TOOLS,
                env=session.harness_env(), relaunch=clear)      # raises SessionUnavailable when it never ran
    return plan_dir


PLAN_OUTPUTS = ("blueprint.jsonl", "aggregates.jsonl", "PLAN.md")


def concept_state_line(run: Run, cid: str) -> str:
    """The concept's state as its repair is shown it: what it may change under its id follows from it."""
    from .candidate import concept_state
    return f"\n\nThe concept is {concept_state(run, cid)}.\n"


def run_repair(run: Run, rec: ConceptRecord, reasons: list[str], last_task: Path, defs: list[dict],
               users: list[dict]) -> Path:
    """One repair session for a concept the gate or the review returned: it sees the record, the
    verdict, the coder's result note and the files the coder left, the ontology, the catalogue and
    the definition (if the contract is one) — no law — and writes a revised record, a split (the
    concept withdrawn and replaced by new records under new ids), or a withdrawal, to
    `record.jsonl` in its own directory. Returns that directory."""
    from ..model import nodeid
    d = run.iter / "repair" / nodeid.concept_lean_name(rec.id)
    d.mkdir(parents=True, exist_ok=True)
    onto = ontology.load(run.opts.ontology)
    note = (last_task / "task_result.md").read_text(encoding="utf-8") if (last_task / "task_result.md").exists() else "(the coding session left no result note)"
    finals = []
    for f in sorted((last_task / "final").rglob("*.lean")) if (last_task / "final").exists() else []:
        finals.append(f"```lean\n-- {f.relative_to(last_task / 'final')}\n{f.read_text(encoding='utf-8')}\n```")
    definition = "(none: the contract is the planner's)"
    if rec.get("definition"):
        dd = next((x for x in defs if x.get("id") == rec.get("definition")), None)
        definition = f"`{rec.get('definition')}`: {dd.get('text', '')}" if dd else f"`{rec.get('definition')}` (text not given)"
    prompt = render.render("concept_repair.md", {
        "concept": json.dumps(rec.raw, ensure_ascii=False, indent=1),
        "verdict": "\n".join(f"- {r}" for r in reasons) or "- (no reason recorded)",
        "task_result": note, "final_files": "\n".join(finals) or "(no file was left)",
        "ontology": onto.text, "formula_language": surface.formula_language(), "concept_language": surface.concept_language(),
        "concepts": surface.concepts_table(run.all_concepts(), surface.current_callers(run)), "definition": definition,
        "users": (", ".join(f"`{u.get('node_id')}`" for u in users) or "(none recorded)") + concept_state_line(run, rec.id)})
    prompt += (f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write `record.jsonl` there with the Write tool: one JSON "
               "object per line — the revised concept record with the same `concept_id`; or a split, `{\"concept_id\": \"<id>\", "
               "\"withdraw\": \"<why the notion is two notions>\", \"replaced_by\": [\"<new id>\", ...]}` followed by one line per "
               "new record; or a withdrawal, `{\"concept_id\": \"<id>\", \"withdraw\": \"<why the notion cannot be defined over this "
               "vocabulary>\"}`. Everything you may know is in this prompt: you read no file and the shell runs nothing.\n")
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return d
    from ..checks import validate_a
    from ..model.blueprint import Node
    ask, attempts = _repair_attempts(d, prompt)
    for attempt in attempts:
        _repair_session(run, d, ask, attempt)
        rep = read_repair(d, concept=True)
        if rep.kind == "malformed":
            errs = [f"record.jsonl could not be read: {rep.message}"]
        elif rep.records:
            outcome = validate_a.validate_concepts(rep.records, defs, onto, run.all_concepts(), [Node(u) for u in users], run.opts.mode)
            errs = [e for o in outcome for e in o.reasons]
        else:
            return d                                     # withdrawn, or nothing written: the loop records it
        (d / "validation.txt").write_text("\n".join(errs) or "accept", encoding="utf-8")
        if not errs or attempt:
            return d
        ask = _reask(d, prompt + "\n\n## Defects of your previous record\n\nThe validator returned it. Write `record.jsonl` again without these defects:\n" + "".join(f"- {e}\n" for e in errs))
    return d


def _repair_attempts(d: Path, prompt: str) -> tuple[str, tuple[str, ...]]:
    """Where a repair task starts: with its prompt and both attempts, or, when its re-ask was
    already decided (`prompt_again.md`, written before the second session), with that prompt and
    the second attempt only, so a resume never runs the first session again."""
    again = d / "prompt_again.md"
    if again.exists():
        return again.read_text(encoding="utf-8"), ("_again",)
    return prompt, ("", "_again")


def _repair_session(run: Run, d: Path, ask: str, attempt: str) -> None:
    """The repair session of one attempt (`""`, then `"_again"`), unless that attempt's session
    already ran to its end: a resume validates the record it left instead of launching it again."""
    if session.finished(d, "session" + attempt):
        return
    session.run(ask, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.plan_turns, effort=run.opts.plan_effort, role="repair",
                label="session" + attempt,
                allow=[f"{t}({session._abs(d)}/**)" for t in ("Read",) + session.WRITE_TOOLS], deny=session.deny_rules("plan", run.opts.run_id),
                tools=session.REPAIR_TOOLS, env=session.harness_env(),
                relaunch=lambda: (d / "record.jsonl").unlink(missing_ok=True))


def _reask(d: Path, ask: str) -> str:
    """The re-ask of a repair, recorded before it runs: the first attempt's record and verdict are
    kept (`record_first.jsonl`, `validation_first.txt`) and the re-ask's prompt is written
    (`prompt_again.md`), the checkpoint a resume continues from; `validation.txt` is left to the
    verdict on the second record."""
    for name, kept in (("record.jsonl", "record_first.jsonl"), ("validation.txt", "validation_first.txt")):
        if (d / name).exists():
            jsonl.write_atomic(d / kept, (d / name).read_text(encoding="utf-8"))
    (d / "validation.txt").unlink(missing_ok=True)
    jsonl.write_atomic(d / "prompt_again.md", ask)
    return ask


def run_node_repair(run: Run, node, reasons: list[str], last_task: Path, law: corpus.Law, defs: list[dict],
                    siblings: list, reading: Reading, onto) -> Path:
    """One repair session for a node the gate returned: it sees the law and its
    segmentation, the record, the law's other nodes in the records it is validated with (read-only,
    with their states and what the records compose), the verdict, the coder's result note and final
    files, the ontology, the catalogue and the reading, and writes a revised record (segmentation unchanged) or a
    withdrawal to `record.jsonl` in its own directory. The record is validated in the plan's
    context (the law's accepted and held siblings) with one re-ask; `validation.txt` records the
    outcome, and a re-ask keeps the first attempt's record, verdict and the re-ask's prompt beside
    it (`_reask`). Returns the directory."""
    from ..checks import validate_a
    from ..model.blueprint import Node
    d = run.iter / "repair" / node.id
    d.mkdir(parents=True, exist_ok=True)
    (d / "planned.json").write_text(json.dumps(node.raw, ensure_ascii=False, indent=1), encoding="utf-8")   # what the record keeps whatever the session writes
    note = (last_task / "task_result.md").read_text(encoding="utf-8") if (last_task / "task_result.md").exists() else "(the coding session left no result note)"
    narrowings: list[dict] = []
    vf = last_task / "verdict.json"
    if vf.exists():
        try:
            narrowings = [x for x in json.loads(vf.read_text(encoding="utf-8")).get("extras", {}).get("narrowings_added", []) if isinstance(x, dict)]
        except json.JSONDecodeError:
            narrowings = []
    spans = node.spans()
    if narrowings:
        rows = [f"- `{x.get('span')}` ({spans.get(x.get('span'), {}).get('role', '?')}): {x.get('why')}" for x in narrowings]
        coder_block = "## What the coder narrowed\n\nThe coding session declared these readings on spans the record carries:\n\n" + "\n".join(rows) + "\n"
    else:
        coder_block = "## What the coder narrowed\n\n(the coding session declared no narrowing)\n"
    finals = []
    for f in sorted((last_task / "final").rglob("*.lean")) if (last_task / "final").exists() else []:
        finals.append(f"```lean\n-- {f.relative_to(last_task / 'final')}\n{f.read_text(encoding='utf-8')}\n```")
    verdict = "\n".join(f"- {r}" for r in reasons) or "- (no reason recorded)"
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in node.get("segmentation", []))
    editable = {k: v for k, v in node.raw.items() if k not in FIXED_NODE_KEYS}
    prompt = render.render("node_repair.md", {
        "law": f"## The law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans (the segmentation; fixed, not part of the record you write):\n{seg}\n",
        "definitions": "## Definitions that apply\n\n" + corpus.render_definitions(definitions_for(run, [law]))
                       + definitions_mod.render_sources(definitions_mod.cited_sources(run, [law], [node]), definitions_mod.CITED_HEADING),
        "node": "## The node\n\n```json\n" + json.dumps(editable, ensure_ascii=False, indent=1) + "\n```\n"
                + GapLedger.for_run(paths.GAPS_DIR, run).cited_block(node.raw) + repair_context(run, node, law, siblings),
        "verdict": verdict, "evidence": NO_LABEL_EVIDENCE, "coder_narrowings": coder_block, "task_result": note,
        "final_files": "\n".join(finals) or "(no file was left)", "ontology": onto.text, "formula_language": surface.formula_language(),
        "concept_language": surface.concept_language(), "concepts": surface.concepts_table(run.all_concepts(), surface.current_callers(run)),
        "parameters": "## Parameters\n\n" + parameter_catalogue(reading) + acquisition.standard_note(getattr(run.opts, "acquisition_profile", None))
                      + declaration_catalogue(reading),
        "anchors": ontology.anchors_text(onto), "aggregate_atom": ontology.AGGREGATE})
    prompt += (f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write `record.jsonl` there with the Write tool: one JSON "
               "object, the revised node record (the harness attaches `node_id`, `law_refs` and `segmentation` itself), or a withdrawal "
               "`{\"withdraw\": {\"span\": \"<span id>\", \"kind\": \"atom\" | \"operator\" | \"plan\" | \"concept\", \"missing\": \"<what is lacking>\", "
               "\"nearest\": [\"<nearest id>: <the clause that excludes the span>\"]}}` (with `concept`, also `dependency_defect.json` as the "
               "Output says). Everything you may know is in this prompt: you read no "
               "file and the shell runs nothing.\n")
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return d
    laws = {law.id: law}
    index = MappingIndex(run.mapping_file)
    reading.pending_aggregates = True            # an aggregate the selection did not admit is the loop's to correct, not this session's
    accepted = {k: Node(v) for k, v in run.all_nodes().items()}
    ask, attempts = _repair_attempts(d, prompt)
    for attempt in attempts:
        _repair_session(run, d, ask, attempt)
        rep = read_repair(d, concept=False)
        if rep.kind == "withdrawn" and (rep.withdrawal or {}).get("kind") == "concept" and not attempt:
            from ..loop import concept_deps, reached_concepts
            _d, bad = review_phase.report_form(run, d, reached_concepts(run, concept_deps(node)))
            if bad:                                       # a report in the wrong form is returned once, before anything is run
                ask = _reask(d, prompt + "\n\n## Defects of your report\n\nWrite `dependency_defect.json` again without these defects:\n" + "".join(f"- {e}\n" for e in bad))
                continue
        if rep.kind in ("withdrawn", "missing"):
            return d
        if rep.kind == "malformed":
            errs = [f"record.jsonl could not be read: {rep.message}"]
            (d / "validation.txt").write_text("\n".join(errs), encoding="utf-8")
            if attempt:
                return d
            ask = _reask(d, prompt + "\n\n## Defects of your previous record\n\nWrite `record.jsonl` again as one JSON object:\n" + "".join(f"- {e}\n" for e in errs))
            continue
        rec2 = rep.records[0]
        errs = []
        others = [s for s in siblings if s.id != node.id]
        outcomes = validate_a.validate([rec2] + others, laws, onto, reading, index, accepted, run.all_concepts(), [],
                                       rejected_gaps=GapLedger.for_run(paths.GAPS_DIR, run).rejected(),
                                       sources=definitions_mod.source_texts(run))
        errs += [r for o in outcomes if o.node.id == node.id for r in o.reasons]
        # a mapping the repair changed on words a sibling also carries: the same-words rule lands on the sibling, and is the repair's to keep or dispute
        errs += [f"{node.id}: your mapping of shared words differs from the held sibling's — {r}" for o in outcomes if o.node.id != node.id
                 for r in o.reasons if f"differently from node {node.id}" in r]
        (d / "validation.txt").write_text("\n".join(errs) or "accept", encoding="utf-8")
        if not errs or attempt:
            return d
        ask = _reask(d, prompt + "\n\n## Defects of your previous record\n\nThe validator returned it. Write `record.jsonl` again without these defects:\n" + "".join(f"- {e}\n" for e in errs))
    return d


#: What a node repair may not write: the harness attaches these from the planned record, so a
#: repaired record cannot change the law, the id or the segmentation the siblings share.
FIXED_NODE_KEYS = ("node_id", "law_refs", "segmentation")


@dataclass
class Repair:
    """What a repair session's `record.jsonl` says: `revised` (its record in `records`), `withdrawn`
    (its `withdrawal`, `{span, kind, missing, nearest, ...}` or `{missing}`, and for a concept split the
    replacement records in `records`), `missing` (no record written) or `malformed` (the parser's
    `message`). `validation` is the validator's verdict on a revised record: None before it ran, []
    when it accepted, else the defects (a record that stayed malformed after the re-ask is one)."""
    kind: str
    records: list = field(default_factory=list)
    withdrawal: dict | None = None
    message: str = ""
    validation: list[str] | None = None

    @property
    def accepted(self) -> bool:
        return self.kind == "revised" and self.validation == []


def read_repair(d: Path, concept: bool) -> Repair:
    """The one reader of a node or concept repair's `record.jsonl`, with the validator's verdict
    from `validation.txt` beside it. A node record takes `node_id`, `law_refs` and the segmentation
    from the planned record the harness saved (`planned.json`); a concept record's users are the
    loop's to derive."""
    from ..model.blueprint import Node, normalize_concept
    vf = d / "validation.txt"
    validation = None
    if vf.exists():
        v = vf.read_text(encoding="utf-8").strip()
        validation = [] if v == "accept" else v.splitlines()
    f = d / "record.jsonl"
    lines = [l for l in f.read_text(encoding="utf-8").splitlines() if l.strip()] if f.exists() else []
    if not lines:
        return Repair("missing", validation=validation)
    rows = []
    for i, line in enumerate(lines, 1):
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError as e:
            return Repair("malformed", message=f"line {i} of record.jsonl is not JSON: {e}", validation=validation)
    if not all(isinstance(r, dict) for r in rows):
        return Repair("malformed", message="every line of record.jsonl is one JSON object", validation=validation)
    first = rows[0]
    if first.get("withdraw"):
        w = first["withdraw"]
        wd = dict(w) if isinstance(w, dict) else {"missing": str(w)}
        named = set(first.get("replaced_by") or []) if concept and isinstance(first.get("replaced_by"), list) else set()
        reps = [ConceptRecord(normalize_concept({**r, "used_by": []})) for r in rows[1:]
                if r.get("concept_id") in named and r.get("concept_id") != first.get("concept_id")] if concept else []
        return Repair("withdrawn", records=reps, withdrawal=wd, validation=validation)
    if concept:
        if not isinstance(first.get("concept_id"), str):
            return Repair("malformed", message="the revised record names no `concept_id`", validation=validation)
        return Repair("revised", records=[ConceptRecord({**normalize_concept(first), "used_by": []})], validation=validation)
    pf = d / "planned.json"
    r = first
    if pf.exists():
        planned = json.loads(pf.read_text(encoding="utf-8"))
        r = {**{k: planned[k] for k in FIXED_NODE_KEYS if k in planned}, **{k: v for k, v in r.items() if k not in FIXED_NODE_KEYS}}
    if not isinstance(r.get("node_id"), str):
        return Repair("malformed", message="the revised record has no node to revise", validation=validation)
    return Repair("revised", records=[Node(r)], validation=validation)


def settle_identity(plan_dir: Path, taken: dict[str, str]) -> tuple[dict[str, list[str]], list[str]]:
    """The plan's node records, made safe to key by id before anything is built from them. `taken`
    maps the ids already in use this iteration (carried and repaired records) to what holds them; an
    accepted node's id is not among them, since a plan may re-emit an accepted node unchanged and the
    validator decides that. A node record that does not match the record schema,
    or whose id another record of the plan holds with different content, or that `taken` holds, is
    taken out of `blueprint.jsonl` and its law returned to its planner with the reason (a validator
    defect); a node record repeated identically is kept once. A concept proposed again under one id
    with the same contract is kept once with the users of both; with a different contract, the first
    record (the earliest batch's: the root law's) stands and the laws of the later record's users are
    returned. The session's file is kept as
    `blueprint.as_written.jsonl`, and the step reads it on a resume, so it is applied once. Returns
    ({law: reasons}, notes)."""
    from ..checks import validate_a
    bp, kept_file = plan_dir / "blueprint.jsonl", plan_dir / "blueprint.as_written.jsonl"
    if not bp.exists():
        return {}, []
    if not kept_file.exists():
        kept_file.write_bytes(bp.read_bytes())
    rows = [json.loads(l) for l in kept_file.read_text(encoding="utf-8").splitlines() if l.strip()]
    defects: dict[str, list[str]] = {}
    notes: list[str] = []
    by_id: dict[str, list[dict]] = {}
    out: list[dict] = []
    concepts: dict[str, dict] = {}
    contract = lambda r: " ".join(str(r.get("contract", "")).split())
    users = lambda r: [u for u in r.get("used_by") or [] if isinstance(u, str)] if isinstance(r.get("used_by"), list) else []
    later_users: dict[str, list[str]] = {}
    for r in rows:
        if "node_id" not in r:
            cid = r.get("concept_id")
            if not isinstance(cid, str) or cid not in concepts:
                if isinstance(cid, str):
                    concepts[cid] = r
                out.append(r); continue
            first = concepts[cid]
            if contract(first) == contract(r):
                first["used_by"] = sorted(set(users(first)) | set(users(r)))
                notes.append(f"concept `{cid}`: proposed again with the same contract; kept once, with the users of both")
            else:
                later_users.setdefault(cid, []).extend(users(r))
            continue
        refs = r.get("law_refs")
        law = refs[0] if isinstance(refs, list) and refs and isinstance(refs[0], str) else None
        errs = validate_a.schema_errors(validate_a.record_id(r, "node_id"), json.loads(json.dumps(r)), validate_a.NODE_SCHEMA)
        if errs:
            if law:
                defects.setdefault(law, []).extend(errs)
            else:
                notes.append("a node record names no law and is dropped: " + "; ".join(errs[:3]))
            continue
        by_id.setdefault(r["node_id"], []).append(r)
    for nid, recs in by_id.items():
        laws = sorted({r["law_refs"][0] for r in recs})
        if nid in taken:
            for law in laws:
                defects.setdefault(law, []).append(f"{nid}: the id is already held by {taken[nid]}; a plan record never reuses it")
            continue
        distinct = {json.dumps(r, sort_keys=True) for r in recs}
        if len(distinct) > 1:
            for law in laws:
                defects.setdefault(law, []).append(f"{nid}: {len(recs)} different records under one id; a node id names one record")
            continue
        if len(recs) > 1:
            notes.append(f"`{nid}`: written {len(recs)} times identically; kept once")
        out.append(recs[0])
    law_of = {nid: recs[0]["law_refs"][0] for nid, recs in by_id.items()}
    for cid, us in later_users.items():
        for law in sorted({law_of[u] for u in us if u in law_of} - {law_of[u] for u in users(concepts[cid]) if u in law_of}):
            defects.setdefault(law, []).append(f"concept `{cid}`: proposed again with a different contract; the first record of this "
                                               "iteration stands, so reuse it by its id or propose a concept under a new id")
    for law in defects:                         # a returned law's other nodes go back with it
        out = [r for r in out if "node_id" not in r or r["law_refs"][0] != law]
    bp.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in out), encoding="utf-8")
    return defects, notes


def _record_digest(r: dict) -> str:
    import hashlib
    from ..model.blueprint import normalize_concept
    body = normalize_concept(r) if "concept_id" in r and "node_id" not in r else r
    return hashlib.sha256(json.dumps(body, sort_keys=True, ensure_ascii=False).encode()).hexdigest()[:24]


def record_origins(plan_dir: Path, batches: list[tuple[Path, list[str]]]) -> None:
    """Where each plan record came from, written before the batches are merged or their records
    deduplicated: `origins.json` maps a record's content digest to its batch, its position in it and
    the batch's laws. A record the validator returns goes back through it, never through an id or a
    `used_by` it may have written malformed."""
    from ..store import jsonl
    out: dict[str, dict] = {}
    for d, laws in batches:
        f = d / "blueprint.jsonl"
        lines = [l for l in f.read_text(encoding="utf-8").splitlines() if l.strip()] if f.exists() else []
        for i, line in enumerate(lines, 1):
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if isinstance(r, dict):
                out.setdefault(_record_digest(r), {"batch": d.name, "position": i, "laws": list(laws)})
    jsonl.write_atomic(plan_dir / "origins.json", json.dumps(out, indent=1))


def origin_of(plan_dir: Path, raw: dict) -> dict | None:
    """The batch a plan record came from (`record_origins`), or None."""
    f = plan_dir / "origins.json"
    return json.loads(f.read_text(encoding="utf-8")).get(_record_digest(raw)) if f.exists() else None


def merge_batches(run: Run, batch_dirs: list[Path]) -> Path:
    """The batches' outputs concatenated under `iter/plan/`, in batch order, which validation reads;
    `settle_identity` then resolves records that share an id."""
    plan_dir = run.iter / "plan"
    plan_dir.mkdir(parents=True, exist_ok=True)
    for name in PLAN_OUTPUTS:
        parts = [(d, (d / name).read_text(encoding="utf-8")) for d in batch_dirs if (d / name).exists()]
        if name == "PLAN.md":
            text = "\n".join(f"<!-- {d.name} -->\n{t.rstrip()}\n" for d, t in parts)
        else:
            text = "".join(l + "\n" for _d, t in parts for l in t.splitlines() if l.strip())
        (plan_dir / name).write_text(text, encoding="utf-8")
    return plan_dir


def operator_notes(plan_dir: Path) -> list[dict]:
    """The notes a plan session wrote for the operator: each item of the `## For the operator`
    sections of a `PLAN.md` (a top-level list item, or a paragraph outside a list), in order, with
    its source directory, its ordinal within those sections (from 1) and a digest of the sections'
    whole content. A directory holding batch directories (`batch-*`) is a merged plan: its own
    `PLAN.md` concatenates theirs, so the notes are read from each batch, never from the merge. A
    source with no such section, or no `PLAN.md`, has no note."""
    import hashlib
    import re
    batches = sorted(d for d in plan_dir.glob("batch-*") if d.is_dir() and (d / "PLAN.md").is_file())
    if batches:
        return [n for d in batches for n in operator_notes(d)]
    f = plan_dir / "PLAN.md"
    if not f.is_file():
        return []
    heading, end = re.compile(r"^##\s+For the operator\b", re.I), re.compile(r"^#{1,2}\s")
    item = re.compile(r"^(?:[-*+]|\d+[.)])\s+")
    sections: list[list[str]] = []
    for line in f.read_text(encoding="utf-8").splitlines():
        if heading.match(line):
            sections.append([])
        elif end.match(line) and sections and sections[-1] is not None:
            sections.append(None)                           # a later heading closes the section
        elif sections and sections[-1] is not None:
            sections[-1].append(line.rstrip())
    sections = [s for s in sections if s is not None]
    if not sections:
        return []
    digest = hashlib.sha256("\n\n".join("\n".join(s).strip() for s in sections).encode("utf-8")).hexdigest()[:16]
    notes: list[list[str]] = []
    for body in sections:
        fresh = True                                        # the next unindented line starts a note
        for line in body:
            if not line.strip() or line.startswith("#"):        # a subheading inside the section is no note
                fresh = True
                continue
            starts = not line[0].isspace() and (item.match(line) or fresh)
            if starts or not notes:
                notes.append([item.sub("", line, count=1) if item.match(line) else line.strip()])
            else:
                notes[-1].append(line)
            fresh = False
    out = []
    for k, lines in enumerate(notes, 1):
        rest = [l for l in lines[1:]]
        pad = min((len(l) - len(l.lstrip()) for l in rest), default=0)
        text = "\n".join([lines[0].strip()] + ["  " + l[pad:] for l in rest])
        out.append({"source": plan_dir, "ordinal": k, "text": text, "section_digest": digest})
    return out
