"""Plan: one session writes blueprint.jsonl and PLAN.md for the plannable laws; the gaps its records propose are filed by the harness in the gap ledger."""
from __future__ import annotations
from dataclasses import dataclass, field
import json
from pathlib import Path
from ..checks import aggregates
from ..model import corpus, definitions as definitions_mod, ontology
from ..agents import render, session
from ..store import paths
from ..store.gaps import GapLedger
from ..model.mapping import MappingIndex
from ..model.reading import Reading
from ..lean import surface
from . import review as review_phase
from ..model.blueprint import ConceptRecord
from ..store.state import Run


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
                "parameters", "gaps", "feedback", "upheld", "previous_records", "user_hints", "anchors", "aggregate_atom")
PLACEHOLDERS_REPAIR = ("concept", "verdict", "task_result", "final_files", "ontology", "formula_language", "concept_language", "concepts",
                       "definition", "users")
PLACEHOLDERS_NODE_REPAIR = ("law", "node", "verdict", "upheld", "coder_narrowings", "task_result", "final_files", "ontology", "formula_language",
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
    text = surface.concepts_table({k: v for k, v in concepts.items() if not v.get("fenced")})
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
    rows = []
    for n in run.all_nodes().values():
        atoms = sorted({a for e in n.get("elements", []) for a in e.get("atoms", []) + e.get("derived", [])})
        rows.append(f"| `{n['node_id']}` | {', '.join(n['law_refs'])} | {', '.join(b['name'] for b in n['binders'])} | {', '.join(atoms)} | accepted |")
    for n in pending or []:
        atoms = sorted({a for e in n.get("elements", []) for a in e.get("atoms", []) + e.get("derived", [])})
        rows.append(f"| `{n['node_id']}` | {', '.join(n['law_refs'])} | {', '.join(b['name'] for b in n.get('binders', []))} | {', '.join(atoms)} | planned this iteration, not yet accepted |")
    if not rows:
        return "(the library carries no accepted node yet)\n"
    return "\n".join(["| node | law | binders | atoms claimed | state |", "|---|---|---|---|---|"] + rows) + "\n"


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
    """The parameters the nodes of earlier batches of this iteration proposed: a later batch names
    them instead of proposing again, and a second proposal under one name must carry the same
    value and unit."""
    rows: dict[str, tuple] = {}
    for n in pending or []:
        if "node_id" not in n:
            continue
        for pr in n.get("param_proposals", []):
            if isinstance(pr, dict) and pr.get("name"):
                rows.setdefault(pr["name"], (pr.get("value"), pr.get("unit"), " ".join(str(pr.get("convention", "")).split()), n["node_id"]))
    if not rows:
        return ""
    out = ["", "### Parameters proposed this iteration by an earlier batch (name them; a second proposal under one name carries the same value and unit)",
           "| parameter | value | unit | convention | node |", "|---|---|---|---|---|"]
    for name, (v, u, c, nid) in sorted(rows.items()):
        out.append(f"| `{name}` | {v} | {u} | {c[:120]} | {nid} |")
    return "\n".join(out) + "\n"


def previous_records(run: Run, laws: list[corpus.Law]) -> str:
    """For each law planned again, the records its nodes were last coded from in this run, each with
    its gate verdict: the latest earlier iteration that coded a node of the law, all of that
    iteration's nodes of the law. Empty for a law no earlier iteration coded."""
    out: list[str] = []
    for law in laws:
        for it in range(run.iteration - 1, 0, -1):
            code = paths.iter_dir(run.opts.run_id, it) / "code"
            nodes = []
            for d in sorted(code.glob("*/node.json")) if code.exists() else []:
                raw = json.loads(d.read_text(encoding="utf-8"))
                if (raw.get("law_refs") or [None])[0] == law.id:
                    v = json.loads((d.parent / "verdict.json").read_text(encoding="utf-8")) if (d.parent / "verdict.json").exists() else {}
                    nodes.append((raw, v))
            if nodes:
                out += [f"### `{law.id}`, as coded in iteration {it}", ""]
                for raw, v in nodes:
                    out += [f"`{raw.get('node_id')}`: gate {v.get('verdict', 'not run')}"
                            + (f" — {'; '.join(str(x) for x in (v.get('details') or [])[:2])[:300]}" if v.get("details") else ""),
                            "", "```json", json.dumps(raw, ensure_ascii=False, indent=1), "```", ""]
                break
    if not out:
        return ""
    return "## Your previous record of these laws\n\n" + "\n".join(out) + "\n"


def run_plan(run: Run, laws: list[corpus.Law], defs: list[dict], tag: str = "", pending: list[dict] | None = None) -> Path:
    """One plan session over `laws`. With a `tag` the session writes under `iter/plan/<tag>/` (one
    batch of several); `pending` lists the nodes and concept records earlier batches of this
    iteration planned, so a law that names one of their laws can compose the node by its id and
    reuse the concept by its id. A batch directory that already holds a session result and a
    blueprint is a finished batch: it is returned as it is, without a session."""
    plan_dir = run.iter / "plan" / tag if tag else run.iter / "plan"
    plan_dir.mkdir(parents=True, exist_ok=True)
    if session.finished(plan_dir) and (plan_dir / "blueprint.jsonl").exists():
        return plan_dir
    onto = ontology.load(run.opts.ontology)
    values = {
        "laws": corpus.render_laws(laws),
        "definitions": definitions_block(run, laws),
        "ontology": onto.text,
        "formula_language": surface.formula_language(),
        "concept_language": surface.concept_language(),
        "library_summary": library_summary(run, [n for n in pending or [] if "node_id" in n]),
        "concepts": concept_catalogue(run) + pending_concepts_table(pending),
        "mapping_index": MappingIndex(run.mapping_file).render() + pending_mappings_table(pending),
        "parameters": parameter_catalogue(Reading(run.reading_file)) + pending_proposals_table(pending)
                      + declaration_catalogue(Reading(run.reading_file), pending),
        "gaps": GapLedger(paths.GAPS_DIR).render({l.id for l in corpus.load_laws(run.opts.laws)}, run.opts.base_run),
        "feedback": run.read_notes(),
        "upheld": review_phase.upheld_block(run, {l.id for l in laws}),
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
                deny=session.deny_rules("plan"), tools=session.PLAN_TOOLS,
                env=session.harness_env(), relaunch=clear)      # raises SessionUnavailable when it never ran
    return plan_dir


PLAN_OUTPUTS = ("blueprint.jsonl", "aggregates.jsonl", "PLAN.md")


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
        "concepts": surface.concepts_table(run.all_concepts()), "definition": definition,
        "users": ", ".join(f"`{u.get('node_id')}`" for u in users) or "(none recorded)"})
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
    ask = prompt
    for attempt in ("", "_again"):
        session.run(ask, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.plan_turns, effort=run.opts.plan_effort, label="session" + attempt,
                    allow=[f"{t}({session._abs(d)}/**)" for t in ("Read",) + session.WRITE_TOOLS], deny=session.deny_rules("plan"),
                    tools=session.REPAIR_TOOLS, env=session.harness_env(),
                    relaunch=lambda: (d / "record.jsonl").unlink(missing_ok=True))
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
        ask = prompt + "\n\n## Defects of your previous record\n\nThe validator returned it. Write `record.jsonl` again without these defects:\n" + "".join(f"- {e}\n" for e in errs)
    return d


def run_node_repair(run: Run, node, reasons: list[str], last_task: Path, law: corpus.Law, defs: list[dict],
                    siblings: list, reading: Reading, onto) -> Path:
    """One repair session for a node the gate or the review returned: it sees the law and its
    segmentation, the record, the verdict, the coder's result note and final files, the ontology,
    the catalogue and the reading, and writes a revised record (segmentation unchanged) or a
    withdrawal to `record.jsonl` in its own directory. The record is validated in the plan's
    context (the law's accepted and held siblings) with one re-ask; `validation.txt` records the
    outcome. Returns the directory."""
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
    rendered = last_task / "review" / "rendered_rule.md"
    if rendered.exists():
        verdict += f"\n\nThe rule the review read, rendered from the code:\n```\n{rendered.read_text(encoding='utf-8')[-8000:]}\n```"
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in node.get("segmentation", []))
    editable = {k: v for k, v in node.raw.items() if k not in FIXED_NODE_KEYS}
    prompt = render.render("node_repair.md", {
        "law": f"## The law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans (the segmentation; fixed, not part of the record you write):\n{seg}\n",
        "node": "## The node\n\n```json\n" + json.dumps(editable, ensure_ascii=False, indent=1) + "\n```\n"
                + GapLedger(paths.GAPS_DIR).cited_block(node.raw),
        "verdict": verdict, "upheld": review_phase.upheld_block(run, {law.id}), "coder_narrowings": coder_block, "task_result": note,
        "final_files": "\n".join(finals) or "(no file was left)", "ontology": onto.text, "formula_language": surface.formula_language(),
        "concept_language": surface.concept_language(), "concepts": surface.concepts_table(run.all_concepts()),
        "parameters": "## Parameters\n\n" + parameter_catalogue(reading) + declaration_catalogue(reading),
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
    ask = prompt
    for attempt in ("", "_again"):
        session.run(ask, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.plan_turns, effort=run.opts.plan_effort, label="session" + attempt,
                    allow=[f"{t}({session._abs(d)}/**)" for t in ("Read",) + session.WRITE_TOOLS], deny=session.deny_rules("plan"),
                    tools=session.REPAIR_TOOLS, env=session.harness_env(),
                    relaunch=lambda: (d / "record.jsonl").unlink(missing_ok=True))
        rep = read_repair(d, concept=False)
        if rep.kind == "withdrawn" and (rep.withdrawal or {}).get("kind") == "concept" and not attempt:
            from ..loop import concept_deps, reached_concepts
            _d, bad = review_phase.report_form(run, d, reached_concepts(run, concept_deps(node)))
            if bad:                                       # a report in the wrong form is returned once, before anything is run
                ask = prompt + "\n\n## Defects of your report\n\nWrite `dependency_defect.json` again without these defects:\n" + "".join(f"- {e}\n" for e in bad)
                continue
        if rep.kind in ("withdrawn", "missing"):
            return d
        if rep.kind == "malformed":
            errs = [f"record.jsonl could not be read: {rep.message}"]
            (d / "validation.txt").write_text("\n".join(errs), encoding="utf-8")
            if attempt:
                return d
            ask = prompt + "\n\n## Defects of your previous record\n\nWrite `record.jsonl` again as one JSON object:\n" + "".join(f"- {e}\n" for e in errs)
            continue
        rec2 = rep.records[0]
        errs = []
        others = [s for s in siblings if s.id != node.id]
        outcomes = validate_a.validate([rec2] + others, laws, onto, reading, index, accepted, run.all_concepts(), [],
                                       rejected_gaps=GapLedger(paths.GAPS_DIR).rejected())
        errs += [r for o in outcomes if o.node.id == node.id for r in o.reasons]
        # a mapping the repair changed on words a sibling also carries: the same-words rule lands on the sibling, and is the repair's to keep or dispute
        errs += [f"{node.id}: your mapping of shared words differs from the held sibling's — {r}" for o in outcomes if o.node.id != node.id
                 for r in o.reasons if f"differently from node {node.id}" in r]
        (d / "validation.txt").write_text("\n".join(errs) or "accept", encoding="utf-8")
        if not errs or attempt:
            return d
        ask = prompt + "\n\n## Defects of your previous record\n\nThe validator returned it. Write `record.jsonl` again without these defects:\n" + "".join(f"- {e}\n" for e in errs)
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
