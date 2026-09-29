"""Plan: one session writes blueprint.jsonl, PLAN.md and gaps/proposed.jsonl for the plannable laws."""
from __future__ import annotations
from pathlib import Path
from .. import aggregates, corpus, ontology, render, paths, session
from ..gaps import GapLedger
from ..mapping import MappingIndex
from ..reading import Reading
from ..state import Run


def parameter_catalogue(reading: Reading) -> str:
    if not reading.params:
        return "(the reading names no parameters yet: every concept parameter you need goes under `## For the operator`)\n"
    out = ["| parameter | unit | convention |", "|---|---|---|"]
    for name, p in sorted(reading.params.items()):
        out.append(f"| `{name}` | {p.get('unit', '')} | {p.get('convention', '')} |")
    out += ["", "Legal aggregates the run's reading declares so far — a span using one of these words claims the atom "
            "`ru.aggregate=<word>` and nothing else; a word not listed is derived by you from its definition "
            "(`aggregates.jsonl`) before any node claims it:", "", aggregates.render(reading)]
    return "\n".join(out) + "\n"

PLACEHOLDERS = ("laws", "definitions", "ontology", "library_summary", "concepts", "mapping_index", "parameters", "gaps", "feedback", "user_hints")


def concept_catalogue(run: Run) -> str:
    from .. import surface, nodeid
    text = surface.concepts_table(run.all_concepts())
    if run.opts.mode == "test":
        text += "\nThis run adds concepts and supersedes none: a catalogued concept whose body contradicts its contract is reported under `## Concept defects` in `PLAN.md`, not replaced.\n"
    return text + f"\nConcept families (the fixed grammar `drv.<family>.<name>`): {', '.join(nodeid.CONCEPT_FAMILIES)}.\n"


def library_summary(run: Run) -> str:
    if not run.all_nodes():
        return "(the library carries no accepted node yet)\n"
    out = ["| node | law | binders | atoms claimed |", "|---|---|---|---|"]
    for n in run.all_nodes().values():
        atoms = sorted({a for e in n.get("elements", []) for a in e.get("atoms", []) + e.get("derived", [])})
        out.append(f"| `{n['node_id']}` | {', '.join(n['law_refs'])} | {', '.join(b['name'] for b in n['binders'])} | {', '.join(atoms)} |")
    return "\n".join(out) + "\n"


def run_plan(run: Run, laws: list[corpus.Law], defs: list[dict]) -> Path:
    plan_dir = run.iter / "plan"
    plan_dir.mkdir(parents=True, exist_ok=True)
    onto = ontology.load(run.opts.ontology)
    values = {
        "laws": corpus.render_laws(laws),
        "definitions": corpus.render_definitions(defs),
        "ontology": onto.text,
        "library_summary": library_summary(run),
        "concepts": concept_catalogue(run),
        "mapping_index": MappingIndex(run.mapping_file).render(),
        "parameters": parameter_catalogue(Reading(run.reading_file)),
        "gaps": GapLedger(paths.GAP_LEDGER).render(),
        "feedback": run.read_notes(),
        "user_hints": run.read_hints(),
    }
    prompt = render.render("plan.md", values)
    validate_cmd = (f"cd {paths.REPO} && python -m harness validate --blueprint_file {plan_dir / 'blueprint.jsonl'} "
                    f"--laws {run.opts.laws} --ontology_file {run.opts.ontology} --reading {run.opts.reading}")
    prompt += ("\n\n## Where to write\n\nWorking directory: this directory. Write `aggregates.jsonl`, `blueprint.jsonl`, `PLAN.md` and "
               "`proposed_gaps.jsonl` here, as files, by hand. Read and write nothing else.\n\n"
               "## Checking a draft\n\nThe deterministic validator the harness will run is available to you on a draft:\n\n"
               f"```\n{validate_cmd}\n```\n\nIt prints one line per node (`accept`, `return`, `block`, `judge`) with the reasons. "
               "Run it once the file is complete, fix what it names, and stop when every node is `accept` or `block`. "
               "It is the only program you run; the self-check is yours, the schema check is its.\n")
    (plan_dir / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return plan_dir
    session.run(prompt, cwd=plan_dir, out_dir=plan_dir, opts=run.opts, max_turns=run.opts.max_turns,
                effort=run.opts.plan_effort, label="session")      # raises SessionUnavailable when it never ran
    return plan_dir
