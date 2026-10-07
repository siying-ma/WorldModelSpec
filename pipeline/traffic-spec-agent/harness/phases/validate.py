"""Validate: A (deterministic) over a plan, and the alignment review of a coded concept.

Validator A runs on the blueprint before any code and decides `accept`, `return` or `block` per
node. A concept, once its gate returned `OK`, has its body rendered as prose with the contracts of
every name it uses, and a judge compares that rendering with its contract. Every session here goes through
`session.run`, so a session the account or the API refused is relaunched and, if it still does not
run, raises `SessionUnavailable` for the loop to defer the law without counting an attempt.
"""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from ..model import blueprint, corpus, ontology
from ..agents import render, session
from ..checks import validate_a
from ..model.blueprint import Node, ConceptRecord
from ..model.mapping import MappingIndex
from ..model.reading import Reading
from ..store.state import Run
from ..store.gaps import GapLedger
from ..store import paths

PLACEHOLDERS_CONCEPT_JUDGE = ("contract", "definition", "rendered_body", "contracts", "narrowings", "motivating_spans", "supersession")
CONCEPT_VERDICTS = {"accept", "approximated", "contradicted", "not_general"}


@dataclass
class NodeVerdict:
    node: Node
    kind: str                     # accept | return | block
    reasons: list[str] = field(default_factory=list)
    gaps: list[dict] = field(default_factory=list)
    proposals: list[dict] = field(default_factory=list)   # parameter proposals the loop enters in the reading when the node is accepted


def disputes_of(plan_dir: Path) -> set[str]:
    from ..model.mapping import normalize
    p = plan_dir / "PLAN.md"
    if not p.exists():
        return set()
    text = p.read_text(encoding="utf-8")
    if "## Disputes" not in text:
        return set()
    block = text.split("## Disputes", 1)[1].split("\n## ", 1)[0]
    import re
    return {normalize(q) for q in re.findall(r"`([^`]+)`", block)}


# ---------------------------------------------------------------------------------------------
# Validator A, in the run's context
# ---------------------------------------------------------------------------------------------
def validate_a_for_run(run: Run | None, plan_dir: Path, laws: dict[str, corpus.Law], reading: Reading, defs: list[dict],
                       onto: ontology.Ontology | None = None, blueprint_file: Path | None = None,
                       extra_concepts: list[ConceptRecord] | None = None, extra_nodes: list[Node] | None = None,
                       extra_validate_nodes: list[Node] | None = None, known_nodes: list[Node] | None = None
                       ) -> tuple[list[Node], list[ConceptRecord], list[validate_a.Outcome], list[validate_a.ConceptOutcome]]:
    """Validator A over the concepts and nodes of a blueprint, against everything the run knows:
    its accepted nodes and concepts, its mapping index, its mode, and the disputes of the plan's
    `PLAN.md`. The loop and the `validate` command both call this, so a draft is checked by the
    check that will accept it. With no run, nothing is accepted and the mapping index is empty."""
    bp = blueprint_file or (plan_dir / "blueprint.jsonl")
    nodes = blueprint.load(bp) + list(extra_validate_nodes or [])          # repaired node records are validated with the plan's
    concepts = blueprint.load_concepts(bp) + list(extra_concepts or [])   # repaired records join the plan's
    users = nodes + list(extra_nodes or [])                               # held nodes may be a concept's users
    if run is not None:
        onto = onto or ontology.load(run.opts.ontology)
        index = MappingIndex(run.mapping_file)
        accepted = {k: Node(v) for k, v in run.all_nodes().items()}
        accepted_concepts = run.all_concepts()
        mode = run.opts.mode
    else:
        assert onto is not None, "an ontology is required without a run"
        index, accepted, accepted_concepts, mode = MappingIndex(plan_dir / "mapping.json"), {}, {}, "train"
    concept_outcomes = validate_a.validate_concepts(concepts, defs, onto, accepted_concepts, users, mode)
    valid_concepts = [o.concept for o in concept_outcomes if o.kind == validate_a.ACCEPT]
    rejected = {r["id"]: set(r.get("law_refs", [])) for r in GapLedger(paths.GAP_LEDGER).rows if r.get("state") == "rejected"}
    outcomes = validate_a.validate(nodes, laws, onto, reading, index, accepted, disputes_of(plan_dir), accepted_concepts, valid_concepts,
                                   known_nodes=known_nodes, rejected_gaps=rejected)
    return nodes, concepts, outcomes, concept_outcomes


def run_validate(run: Run, plan_dir: Path, laws: dict[str, corpus.Law], reading: Reading,
                 defs: list[dict] | None = None, extra_concepts: list[ConceptRecord] | None = None,
                 extra_nodes: list[Node] | None = None, extra_validate_nodes: list[Node] | None = None) -> tuple[list[NodeVerdict], list[validate_a.ConceptOutcome]]:
    """Validator A over the plan's concepts and nodes (and the repaired concept records, whose
    users may be nodes held from an earlier iteration). A node's review comes after its code, since
    the formulas are what is judged."""
    out_dir = run.iter / "validate"
    out_dir.mkdir(parents=True, exist_ok=True)
    _nodes, _concepts, outcomes, concept_outcomes = validate_a_for_run(run, plan_dir, laws, reading, defs or [],
                                                                       extra_concepts=extra_concepts, extra_nodes=extra_nodes,
                                                                       extra_validate_nodes=extra_validate_nodes)
    verdicts = [NodeVerdict(o.node, o.kind, o.reasons, o.gaps, o.proposals) for o in outcomes]
    (out_dir / "verdicts.jsonl").write_text("".join(json.dumps({"node_id": v.node.id, "kind": v.kind, "reasons": v.reasons, "gaps": v.gaps, "proposals": v.proposals}, ensure_ascii=False) + "\n" for v in verdicts), encoding="utf-8")
    (out_dir / "concept_verdicts.jsonl").write_text("".join(json.dumps({"concept_id": o.concept.id, "kind": o.kind, "reasons": o.reasons}, ensure_ascii=False) + "\n" for o in concept_outcomes), encoding="utf-8")
    return verdicts, concept_outcomes


# ---------------------------------------------------------------------------------------------
# Sessions
# ---------------------------------------------------------------------------------------------
def _session(run: Run, out_dir: Path, label: str, prompt: str, check=None, model: str | None = None,
             effort: str | None = None) -> tuple[dict | None, list[str]]:
    """One tool-less session: its JSON and the schema defects that remain. `check(parsed)` names the
    defects of an answer; an answer with defects is asked for once more with the defects appended,
    and the second answer stands whole, with whatever defects it keeps (the caller decides what
    they mean). A session
    that ran and wrote no JSON is asked once more; a second silence returns no answer with that
    defect, which the caller counts against the node. In a dry run `(None, [])`."""
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{label}_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return None, []
    ask = prompt
    parsed, errs = None, []
    for attempt in ("", "_again"):
        record = session.run(ask, cwd=out_dir, out_dir=out_dir, opts=run.opts, max_turns=6,
                             effort=effort or run.opts.judge_effort, label=label + attempt, timeout=900,
                             allow=[], disallowed_tools=session.NO_TOOLS, model=model or run.opts.model)
        text = ((record.get("result") or {}).get("result", "") or "")
        (out_dir / f"{label}{attempt}_result.txt").write_text(text, encoding="utf-8")
        parsed = render.extract_json(text)
        if parsed is None:
            errs = ["no JSON object in the answer"]
        else:
            errs = list(check(parsed)) if check else []
            if not errs:
                return parsed, []
        ask = prompt + "\n\n## Defects of your previous answer\n\nAnswer again, in the same schema, without these defects:\n" + "".join(f"- {e}\n" for e in errs)
    if parsed is None:
        return None, [f"{label}: no JSON object in the answer, twice"]
    return parsed, errs


# ---------------------------------------------------------------------------------------------
# What a reviewer is told the names mean
# ---------------------------------------------------------------------------------------------
def glosses_for(node: Node, onto: ontology.Ontology, run: Run) -> dict[str, str]:
    """Contracts of every id the node claims: atoms and primitives from the ontology, concepts
    from the run's catalogue, and every atom a claimed concept or primitive reads."""
    out: dict[str, str] = {}
    for aid in claimed_closure(node, onto):
        c = onto.contract(aid.split("=")[0])
        if c:
            out[aid.split("=")[0]] = c
    for cid, rec in run.all_concepts().items():
        if cid in node.claimed_atoms():
            out[cid] = " ".join(str(rec.get("contract", "")).split())
            for aid in rec.get("reads", []):
                c = onto.contract(aid)
                if c:
                    out[aid] = c
    for c in node.compositions():
        out[c.get("rule", "")] = "another rule of the library; its verdict, or whether it applies, is read here"
    return out


def aggregates_for(node: Node, reading: Reading) -> dict[str, list[str]]:
    """The classes each aggregate word the node claims covers, as the run's reading declares them."""
    words = sorted({c.split("=", 1)[1] for c in node.claimed_atoms() if c.startswith("ru.aggregate=")})
    return {w: reading.expand(w) for w in words}


def contracts_table(glosses: dict[str, str], aggregates: dict[str, list[str]]) -> str:
    lines = ["| id | contract |", "|---|---|"]
    lines += [f"| `{k}` | {v} |" for k, v in sorted(glosses.items()) if v]
    for w, classes in sorted(aggregates.items()):
        lines.append(f"| `ru.aggregate={w}` | the legal aggregate '{w}', which the reading declares to cover: {', '.join(classes) or '(no class declared)'} |")
    return "\n".join(lines) + "\n"


def claimed_closure(n: Node, onto: ontology.Ontology) -> set[str]:
    """Ids the node claims, and the atoms its claimed primitives read."""
    from ..lean import surface
    out = set(n.claimed_atoms())
    reads = surface.primitive_reads()
    for c in list(out):
        for lean_name in reads.get(c.replace(".", "_"), []):
            aid = surface.atom_id_of(lean_name, onto.atom_ids)
            if aid:
                out.add(aid)
    return out


# ---------------------------------------------------------------------------------------------
# The review of a coded concept
# ---------------------------------------------------------------------------------------------
def motivating_spans(rec: ConceptRecord, nodes: list[Node]) -> list[str]:
    """The law spans of this plan whose elements map to the concept: what the judge checks the
    contract is general beyond."""
    out = []
    for n in nodes:
        if n.id not in rec.used_by():
            continue
        spans = n.spans()
        for e in n.get("elements", []):
            if rec.id in e.get("derived", []):
                out.append(f"`{n.id}` {e.get('span')}: {spans.get(e.get('span'), {}).get('text', '')}")
        for o in n.get("operationalizations", []):
            if rec.id in blueprint.concepts_of(o):
                out.append(f"`{n.id}` {o.get('span')} (standard): {spans.get(o.get('span'), {}).get('text', '')}")
    return out


def concept_judge_defects(verdict: dict, haystack: str) -> list[str]:
    """Defects of a concept judge's answer: the verdict and family words, and for any verdict but
    `accept` a reason that quotes, verbatim, words of the rendering or the contract."""
    import re
    errs = [] if verdict.get("verdict") in CONCEPT_VERDICTS else [f"`verdict` must be one of {sorted(CONCEPT_VERDICTS)}"]
    if verdict.get("family") not in ("fits", "misfiled"):
        errs.append("`family` must be `fits` or `misfiled`")
    if verdict.get("verdict") in CONCEPT_VERDICTS - {"accept"}:
        hay = " ".join(haystack.split()).lower()
        quotes = [q for r in verdict.get("reasons", []) for q in re.findall(r'["\u201c]([^"\u201c\u201d]{6,})["\u201d]', str(r))]
        if not any(" ".join(q.split()).lower() in hay for q in quotes):
            errs.append("no reason quotes, verbatim between double quotation marks, the words of the rendering or the contract that decide it")
    return errs


def review_concept(run: Run, rec: ConceptRecord, extras: dict, out_dir: Path, nodes: list[Node],
                   defs: list[dict]) -> tuple[bool, list[str], dict | None]:
    """The alignment check a concept gets once its body exists: the expanded body rendered as prose
    and judged against the contract (and, for a fresh concept, the spans that motivated it); a
    supersession's judge sees no law. `accept` and `approximated` with a family that fits pass, the
    latter with its reasons recorded on the concept; `contradicted`, `not_general`, a misfiled
    family or a defect the judge keeps return it. Raises `SessionUnavailable` when the session never
    ran, or when the body uses a construct the renderer has no phrasing for."""
    from ..lean import render_formula
    onto = ontology.load(run.opts.ontology)
    glosses = {aid: onto.contract(aid) for aid in extras.get("reads", [])}
    for cid, crec in run.all_concepts().items():
        glosses[cid] = " ".join(str(crec.get("contract", "")).split())
    try:
        rendered = render_formula.render_concept({"args": [{"name": a["name"], "sort": {"sort": a["sort"], "values": a.get("values", [])}} for a in rec.args()],
                                                  "params": [{"name": p["name"], "unit": p["unit"]} for p in rec.params()],
                                                  "kind": rec.get("kind"), "body": extras.get("body_json")}, glosses)
    except render_formula.Unrendered as e:
        raise session.SessionUnavailable(f"the renderer has no phrasing for the {e} (harness/lean/render_formula.py)") from e
    (out_dir / "rendered_body.md").parent.mkdir(parents=True, exist_ok=True)
    (out_dir / "rendered_body.md").write_text(rendered, encoding="utf-8")
    contracts = "### Contracts\n\n" + ("\n".join(f"- `{k}`: {v}" for k, v in sorted(glosses.items()) if v) or "(none)")
    narrowed = [n for n in extras.get("narrowings_added", []) if isinstance(n, dict)]
    narrowings = "### The coder's narrowings\n\n" + ("\n".join(f"- on \"{n.get('span')}\": {n.get('why')}" for n in narrowed) or "(none)")
    definition = ""
    if rec.get("definition"):
        d = next((x for x in defs if x.get("id") == rec.get("definition")), None)
        definition = f"`{rec.get('definition')}`: {d.get('text', '')}" if d else f"`{rec.get('definition')}` (text not given)"
    supersession = rec.get("supersedes") or ""
    spans = "(none: a supersession is judged against the contract alone)" if supersession else ("\n".join(f"- {s}" for s in motivating_spans(rec, nodes)) or "(none)")
    contract = " ".join(str(rec.get("contract", "")).split())
    rendered_block = "### The rendering\n\n" + rendered
    verdict, errs = _session(run, out_dir, "judge", render.render("concept_judge.md", {
        "contract": contract, "definition": definition or "(none)", "rendered_body": rendered_block, "contracts": contracts,
        "narrowings": narrowings, "motivating_spans": spans,
        "supersession": f"supersedes `{supersession}`" if supersession else "a fresh concept"}),
        check=lambda v: concept_judge_defects(v, rendered + "\n" + contract))
    if verdict is None:
        if errs:
            return False, [f"judge: {e}" for e in errs], None
        return True, ["review skipped (dry run)"], None
    reasons = [f"judge output malformed: {e}" for e in errs]
    if verdict.get("verdict") not in ("accept", "approximated"):
        reasons.append(f"{verdict.get('verdict')}: " + "; ".join(str(r) for r in verdict.get("reasons", [])[:4]))
    if verdict.get("family") not in (None, "fits"):
        reasons.append(f"family: {verdict.get('family')}")
    return not reasons, reasons, verdict


def concept_approximations(verdict: dict | None) -> list[str]:
    """What an accepted concept's judge found it computes more narrowly or broadly than its contract."""
    return [str(r) for r in (verdict or {}).get("reasons", [])] if (verdict or {}).get("verdict") == "approximated" else []
