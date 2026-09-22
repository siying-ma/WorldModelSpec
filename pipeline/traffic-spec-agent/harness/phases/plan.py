"""Plan: one session writes blueprint.jsonl, PLAN.md and gaps/proposed.jsonl for the plannable laws."""
from __future__ import annotations
import json
from pathlib import Path
from .. import corpus, ontology, render, runner, paths
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
    aggs = reading.data.get("aggregates", [])
    if aggs:
        out += ["", "Legal aggregates the reading declares (which classes a word covers):", ""]
        out += [f"- `{a['word']}`: {', '.join(a.get('classes', []))}" for a in aggs]
    return "\n".join(out) + "\n"

PLACEHOLDERS = ("laws", "definitions", "ontology", "library_summary", "mapping_index", "parameters", "gaps", "feedback", "user_hints")


def library_summary(run: Run) -> str:
    if not run.accepted_nodes:
        return "(the library carries no accepted node yet)\n"
    out = ["| node | law | binders | atoms claimed |", "|---|---|---|---|"]
    for n in run.accepted_nodes.values():
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
        "mapping_index": MappingIndex(run.mapping_file).render(),
        "parameters": parameter_catalogue(Reading(run.opts.reading)),
        "gaps": GapLedger(paths.GAP_LEDGER).render(),
        "feedback": run.read_notes(),
        "user_hints": run.read_hints(),
    }
    prompt = render.render("plan.md", values)
    prompt += ("\n\n## Where to write\n\nWorking directory: this directory. Write `blueprint.jsonl`, `PLAN.md` and "
               "`gaps/proposed.jsonl` here. Do not read or write anything outside it.\n")
    (plan_dir / "prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return plan_dir
    code, result, timed_out = runner.run_claude(prompt, cwd=plan_dir, stream_path=plan_dir / "session.jsonl",
                                                max_turns=run.opts.max_turns, model=run.opts.model,
                                                timeout_seconds=run.opts.session_timeout)
    (plan_dir / "session_result.json").write_text(json.dumps({"code": code, "timed_out": timed_out, "result": result}, ensure_ascii=False, indent=1), encoding="utf-8")
    return plan_dir
