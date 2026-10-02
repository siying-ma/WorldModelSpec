"""Plan: one session writes blueprint.jsonl, PLAN.md and gaps/proposed.jsonl for the plannable laws."""
from __future__ import annotations
import json
from pathlib import Path
from ..checks import aggregates
from ..model import corpus, ontology
from ..agents import render, session
from ..store import paths
from ..store.gaps import GapLedger
from ..model.mapping import MappingIndex
from ..model.reading import Reading
from ..model.blueprint import ConceptRecord
from ..store.state import Run


def parameter_catalogue(reading: Reading) -> str:
    if not reading.params:
        return ("(the catalogue is empty: every parameter a node needs is proposed in its `param_proposals` with unit, provisional value, convention and source)\n"
                "\nLegal aggregates the run's reading declares so far — a span using one of these words claims the atom "
                f"`{ontology.AGGREGATE}=<word>` and nothing else; a word not listed is derived by you from its definition "
                "(`aggregates.jsonl`) before any node claims it:\n\n" + aggregates.render(reading))
    out = ["| parameter | unit | convention |", "|---|---|---|"]
    for name, p in sorted(reading.params.items()):
        out.append(f"| `{name}` | {p.get('unit', '')} | {p.get('convention', '')} |")
    out += ["", "Legal aggregates the run's reading declares so far — a span using one of these words claims the atom "
            f"`{ontology.AGGREGATE}=<word>` and nothing else; a word not listed is derived by you from its definition "
            "(`aggregates.jsonl`) before any node claims it:", "", aggregates.render(reading)]
    return "\n".join(out) + "\n"

PLACEHOLDERS = ("laws", "definitions", "ontology", "library_summary", "concepts", "mapping_index", "parameters", "gaps", "feedback", "user_hints",
                "anchors", "aggregate_atom")
PLACEHOLDERS_REPAIR = ("concept", "verdict", "task_result", "final_files", "ontology", "concepts", "definition", "users")
PLACEHOLDERS_NODE_REPAIR = ("law", "node", "verdict", "coder_narrowings", "task_result", "final_files", "ontology", "concepts", "parameters", "anchors", "aggregate_atom")


def defined_term(d: dict) -> list[str]:
    """The term a posted definition defines: the first quoted phrase of its text, and the title's
    subject when the title reads "<term> defined"."""
    import re
    out = []
    m = re.search(r"“([^”]+)”|\"([^\"]+)\"", d.get("text", ""))
    if m:
        out.append((m.group(1) or m.group(2)).strip().lower())
    t = d.get("title", "").strip()
    if t.lower().endswith(" defined"):
        out.append(t[:-8].strip().lower())
    return sorted(set(out))


def definitions_for(laws: list[corpus.Law], defs: list[dict]) -> list[dict]:
    """The definitions a batch needs: every definition a batch law cites by its bracketed id,
    every definition whose defined term occurs in a batch law's text or title (the aggregate
    words come this way), and, one step further, every definition whose term occurs in a
    definition already selected. The rest of the folder is size and distraction."""
    import re
    text = " ".join((l.text + " " + l.title).lower() for l in laws)
    cited = {r for l in laws for r in corpus.LAW_REF.findall(l.text) if r.startswith("DEF-")}
    def occurs(terms: list[str], where: str) -> bool:
        return any(re.search(r"\b" + re.escape(t) + r"s?\b", where) for t in terms)
    chosen = [d for d in defs if d.get("id") in cited or occurs(defined_term(d), text)]
    ctext = " ".join(d.get("text", "").lower() for d in chosen)
    chosen += [d for d in defs if d not in chosen and occurs(defined_term(d), ctext)]
    return chosen


def concept_catalogue(run: Run) -> str:
    from ..lean import surface
    from ..model import nodeid
    text = surface.concepts_table(run.all_concepts())
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
    """The concept records earlier batches of this iteration proposed: a later batch reuses them by
    id and proposes none of them again."""
    recs = [r for r in pending or [] if "concept_id" in r and "node_id" not in r]
    if not recs:
        return ""
    out = ["", "### Concepts proposed this iteration by an earlier batch (not yet accepted; reuse by id, never re-propose; a differing record under the same id is dropped at the merge)",
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


def run_plan(run: Run, laws: list[corpus.Law], defs: list[dict], tag: str = "", pending: list[dict] | None = None) -> Path:
    """One plan session over `laws`. With a `tag` the session writes under `iter/plan/<tag>/` (one
    batch of several); `pending` lists the nodes and concept records earlier batches of this
    iteration planned, so a law that names one of their laws can compose the node by its id and
    reuse the concept by its id. A batch directory that already holds a session result and a
    blueprint is a finished batch: it is returned as it is, without a session."""
    plan_dir = run.iter / "plan" / tag if tag else run.iter / "plan"
    plan_dir.mkdir(parents=True, exist_ok=True)
    if (plan_dir / "session_result.json").exists() and (plan_dir / "blueprint.jsonl").exists():
        return plan_dir
    onto = ontology.load(run.opts.ontology)
    values = {
        "laws": corpus.render_laws(laws),
        "definitions": corpus.render_definitions(definitions_for(laws, defs)),
        "ontology": onto.text,
        "library_summary": library_summary(run, [n for n in pending or [] if "node_id" in n]),
        "concepts": concept_catalogue(run) + pending_concepts_table(pending),
        "mapping_index": MappingIndex(run.mapping_file).render() + pending_mappings_table(pending),
        "parameters": parameter_catalogue(Reading(run.reading_file)) + pending_proposals_table(pending),
        "gaps": GapLedger(paths.GAP_LEDGER).render({l.id for l in corpus.load_laws(run.opts.laws)}, run.opts.base_run),
        "feedback": run.read_notes(),
        "user_hints": run.read_hints(),
        "anchors": ontology.anchors_text(onto),
        "aggregate_atom": ontology.AGGREGATE,
    }
    prompt = render.render("plan.md", values)
    validate_cmd = f"python -m harness validate --run_id {run.opts.run_id} --blueprint_file {(plan_dir / 'blueprint.jsonl').resolve()}"
    prompt += (f"\n\n## Where to write\n\nWorking directory: `{plan_dir.resolve()}`. Write `aggregates.jsonl`, `blueprint.jsonl`, `PLAN.md` and "
               "`proposed_gaps.jsonl` there with the Write tool, as files, by hand. Everything you need is in this prompt: you read no "
               "other file, and the shell runs exactly one command, the validator below — any other command is denied.\n\n"
               "## Checking a draft\n\nThe deterministic validator the harness will run, with the run's accepted nodes, concepts, "
               "mapping index, reading and your `aggregates.jsonl` and `PLAN.md` disputes, is available to you on a draft:\n\n"
               f"```\n{validate_cmd}\n```\n\nRun it exactly as written. It prints one line per node (`accept`, `return`, `block`) with the reasons. "
               "Run it once the file is complete, fix what it names, and stop when every node is `accept` or `block`. "
               "It is the only program you run; the self-check is yours, the schema check is its.\n")
    (plan_dir / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return plan_dir
    session.run(prompt, cwd=plan_dir, out_dir=plan_dir, opts=run.opts, max_turns=run.opts.plan_turns,
                effort=run.opts.plan_effort, label="session", allow=session.plan_allow(plan_dir, validate_cmd),
                deny=session.deny_rules("plan"), disallowed_tools=session.NO_SEARCH,
                env=session.harness_env())      # raises SessionUnavailable when it never ran
    return plan_dir


PLAN_OUTPUTS = ("blueprint.jsonl", "aggregates.jsonl", "proposed_gaps.jsonl", "PLAN.md")


def run_repair(run: Run, rec: ConceptRecord, reasons: list[str], last_task: Path, defs: list[dict],
               users: list[dict]) -> Path:
    """One repair session for a concept the gate or the review returned: it sees the record, the
    verdict, the coder's result note and the files the coder left, the ontology, the catalogue and
    the definition (if the contract is one) — no law — and writes a revised record, or a
    withdrawal, to `record.jsonl` in its own directory. Returns that directory."""
    from ..lean import surface
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
        "ontology": onto.text, "concepts": surface.concepts_table(run.all_concepts()), "definition": definition,
        "users": ", ".join(f"`{u.get('node_id')}`" for u in users) or "(none recorded)"})
    prompt += (f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write `record.jsonl` there with the Write tool: one JSON "
               "object, the revised concept record with the same `concept_id`, or `{\"concept_id\": \"<id>\", \"withdraw\": \"<why the "
               "notion cannot be defined over this vocabulary>\"}`. Everything you may know is in this prompt: you read no file and "
               "the shell runs nothing.\n")
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return d
    from ..checks import validate_a
    from ..model.blueprint import Node
    ask = prompt
    for attempt in ("", "_again"):
        session.run(ask, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.plan_turns, effort=run.opts.plan_effort, label="session" + attempt,
                    allow=[f"{t}({session._abs(d)}/**)" for t in ("Read",) + session.WRITE_TOOLS], deny=session.deny_rules("plan"),
                    disallowed_tools=session.NO_SEARCH + ["Bash"], env=session.harness_env())
        rec2 = load_repair(d)
        if rec2 is None:
            return d                                     # withdrawn, or nothing written: the loop records it
        outcome = validate_a.validate_concepts([rec2], defs, onto, run.all_concepts(), [Node(u) for u in users], run.opts.mode)
        errs = [e for o in outcome for e in o.reasons]
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
    from ..lean import surface
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
    for name in ("judge_result.txt", "blind_result.txt"):
        f = last_task / "review" / name
        if f.exists():
            verdict += f"\n\n{name.split('_')[0]} output:\n```\n{f.read_text(encoding='utf-8')[-8000:]}\n```"
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in node.get("segmentation", []))
    editable = {k: v for k, v in node.raw.items() if k not in FIXED_NODE_KEYS}
    prompt = render.render("node_repair.md", {
        "law": f"## The law\n\n**{law.id}** — {law.title}\n\n{law.text}\n\nSpans (the segmentation; fixed, not part of the record you write):\n{seg}\n",
        "node": "## The node\n\n```json\n" + json.dumps(editable, ensure_ascii=False, indent=1) + "\n```\n",
        "verdict": verdict, "coder_narrowings": coder_block, "task_result": note, "final_files": "\n".join(finals) or "(no file was left)",
        "ontology": onto.text, "concepts": surface.concepts_table(run.all_concepts()),
        "parameters": "## Parameters\n\n" + parameter_catalogue(reading),
        "anchors": ontology.anchors_text(onto), "aggregate_atom": ontology.AGGREGATE})
    prompt += (f"\n\n## Where to write\n\nWorking directory: `{d.resolve()}`. Write `record.jsonl` there with the Write tool: one JSON "
               "object, the revised node record (the harness attaches `node_id`, `law_refs` and `segmentation` itself), or a withdrawal "
               "`{\"withdraw\": {\"span\": \"<span id>\", \"kind\": \"atom\" | \"operator\", \"missing\": \"<what the vocabulary lacks>\", "
               "\"nearest\": [\"<nearest id>: <the clause that excludes the span>\"]}}`. Everything you may know is in this prompt: you read no "
               "file and the shell runs nothing.\n")
    (d / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return d
    laws = {law.id: law}
    index = MappingIndex(run.mapping_file)
    accepted = {k: Node(v) for k, v in run.all_nodes().items()}
    ask = prompt
    for attempt in ("", "_again"):
        session.run(ask, cwd=d, out_dir=d, opts=run.opts, max_turns=run.opts.plan_turns, effort=run.opts.plan_effort, label="session" + attempt,
                    allow=[f"{t}({session._abs(d)}/**)" for t in ("Read",) + session.WRITE_TOOLS], deny=session.deny_rules("plan"),
                    disallowed_tools=session.NO_SEARCH + ["Bash"], env=session.harness_env())
        rec2 = load_node_repair(d)
        if rec2 is None:
            return d
        errs = []
        others = [s for s in siblings if s.id != node.id]
        outcomes = validate_a.validate([rec2] + others, laws, onto, reading, index, accepted, set(), run.all_concepts(), [])
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


def _repair_line(d: Path) -> dict | None:
    f = d / "record.jsonl"
    if not f.exists():
        return None
    for line in f.read_text(encoding="utf-8").splitlines():
        if line.strip():
            try:
                return json.loads(line)
            except json.JSONDecodeError:
                return None
    return None


def load_node_repair(d: Path):
    """The revised node record a repair session wrote, with `node_id`, `law_refs` and the
    segmentation taken from the planned record the harness saved beside it (`planned.json`);
    None when the session withdrew or wrote nothing."""
    from ..model.blueprint import Node
    r = _repair_line(d)
    if not isinstance(r, dict) or r.get("withdraw"):
        return None
    pf = d / "planned.json"
    if pf.exists():
        planned = json.loads(pf.read_text(encoding="utf-8"))
        r = {**r, **{k: planned[k] for k in FIXED_NODE_KEYS if k in planned}}
    if "node_id" not in r:
        return None
    return Node(r)


def load_node_withdrawal(d: Path) -> dict | None:
    """The withdrawal a repair session wrote, as `{span, kind, missing, nearest}`; a bare string
    becomes `{missing}`; None when the session did not withdraw."""
    r = _repair_line(d)
    if not isinstance(r, dict) or not r.get("withdraw"):
        return None
    w = r["withdraw"]
    return dict(w) if isinstance(w, dict) else {"missing": str(w)}


def load_repair(d: Path) -> ConceptRecord | None:
    """The revised record a repair session wrote, or None when it withdrew or wrote nothing."""
    f = d / "record.jsonl"
    if not f.exists():
        return None
    for line in f.read_text(encoding="utf-8").splitlines():
        if line.strip():
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                return None
            if r.get("withdraw") or "concept_id" not in r:
                return None
            from ..model.blueprint import normalize_concept
            return ConceptRecord(normalize_concept(r))
    return None


def merge_batches(run: Run, batch_dirs: list[Path]) -> Path:
    """The batches' outputs concatenated under `iter/plan/`, which validation reads. A concept two
    batches proposed under one id is kept once, as the first batch's record (the root law's) with
    the union of its users; a later batch's differing contract is dropped and the drop is noted in
    the merged `PLAN.md`, so the feedback names it."""
    plan_dir = run.iter / "plan"
    plan_dir.mkdir(parents=True, exist_ok=True)
    concepts: dict[str, dict] = {}
    conflicts: list[str] = []
    lines: dict[str, list[str]] = {name: [] for name in PLAN_OUTPUTS}
    for d in batch_dirs:
        for name in PLAN_OUTPUTS:
            f = d / name
            if not f.exists():
                continue
            text = f.read_text(encoding="utf-8")
            if name == "PLAN.md":
                lines[name].append(f"<!-- {d.name} -->\n{text.rstrip()}\n"); continue
            for line in text.splitlines():
                if not line.strip():
                    continue
                if name == "blueprint.jsonl":
                    try:
                        rec = json.loads(line)
                    except json.JSONDecodeError:
                        lines[name].append(line); continue
                    cid = rec.get("concept_id") if "node_id" not in rec else None
                    if cid and cid in concepts:
                        concepts[cid]["used_by"] = sorted(set(concepts[cid].get("used_by", [])) | set(rec.get("used_by", [])))
                        if " ".join(str(concepts[cid].get("contract", "")).split()) != " ".join(str(rec.get("contract", "")).split()):
                            conflicts.append(f"`{cid}`: {d.name} proposed it again with a different contract; the earlier batch's record is kept and {d.name}'s users are added to it")
                        continue
                    if cid:
                        concepts[cid] = rec
                        lines[name].append(None); continue      # placeholder, filled below with the merged record
                lines[name].append(line)
    out = []
    it = iter(concepts.values())
    for line in lines["blueprint.jsonl"]:
        out.append(json.dumps(next(it), ensure_ascii=False) if line is None else line)
    (plan_dir / "blueprint.jsonl").write_text("".join(l + "\n" for l in out), encoding="utf-8")
    for name in ("aggregates.jsonl", "proposed_gaps.jsonl"):
        (plan_dir / name).write_text("".join(l + "\n" for l in lines[name]), encoding="utf-8")
    if conflicts:
        lines["PLAN.md"].append("<!-- merge -->\n## Concepts proposed by more than one batch\n\n" + "\n".join(f"- {c}" for c in conflicts) + "\n")
    (plan_dir / "PLAN.md").write_text("\n".join(lines["PLAN.md"]), encoding="utf-8")
    return plan_dir
