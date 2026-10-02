"""Validate: A (deterministic) over a plan, and the alignment review of a coded node or concept.

Validator A runs on the blueprint before any code and decides `accept`, `return` or `block` per
node. The review runs on a node once its gate returned `OK`: the rule's formulas, rendered as
prose with the contracts of every name they use and no law text, are read blind, and a judge
compares that reading with the law span by span. A concept is reviewed the same way against its
contract. Every session here goes through `session.run`, so a session the account or the API
refused is relaunched and, if it still does not run, raises `SessionUnavailable` for the loop
to defer the law without counting an attempt.
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

PLACEHOLDERS_BLIND = ("rendered_rule", "contracts")
PLACEHOLDERS_JUDGE = ("law_and_segmentation", "blind_reading", "claims", "contracts", "aggregates")
PLACEHOLDERS_CONCEPT_BLIND = ("rendered_body", "contracts")
PLACEHOLDERS_CONCEPT_JUDGE = ("contract", "definition", "blind_reading", "motivating_spans", "supersession")
MISALIGNED = ("approximated", "contradicted", "missing")
JUDGE_VERDICTS = {"covered", "approximated", "contradicted", "missing", "carried"}
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
                       extra_validate_nodes: list[Node] | None = None
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
    outcomes = validate_a.validate(nodes, laws, onto, reading, index, accepted, disputes_of(plan_dir), accepted_concepts, valid_concepts)
    return nodes, concepts, outcomes, concept_outcomes


def run_validate(run: Run, plan_dir: Path, laws: dict[str, corpus.Law], reading: Reading,
                 defs: list[dict] | None = None, extra_concepts: list[ConceptRecord] | None = None,
                 extra_nodes: list[Node] | None = None, extra_validate_nodes: list[Node] | None = None) -> tuple[list[NodeVerdict], list[validate_a.ConceptOutcome]]:
    """Validator A over the plan's concepts and nodes (and the repaired concept records, whose
    users may be nodes held from an earlier iteration). The alignment review of a node comes after
    its code (`review_node`), since the formulas are what is judged."""
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
def _session(run: Run, out_dir: Path, label: str, prompt: str, check=None) -> tuple[dict | None, list[str]]:
    """One reader or judge session, with no write tool: its JSON and the schema defects that remain.
    `check(parsed)` names the defects of an answer; an answer with defects is asked for once more
    with the defects appended, and the second answer stands with whatever defects it keeps (the
    caller decides what they mean). A session that ran and wrote no JSON is asked once more; a
    second silence is `SessionUnavailable`, never a verdict on the node. In a dry run `(None, [])`."""
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{label}_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return None, []
    ask = prompt
    parsed, errs = None, []
    for attempt in ("", "_again"):
        record = session.run(ask, cwd=out_dir, out_dir=out_dir, opts=run.opts, max_turns=6,
                             effort=run.opts.judge_effort, label=label + attempt, timeout=900,
                             allow=[], disallowed_tools=session.NO_TOOLS,
                             model=(run.opts.reader_model or run.opts.model) if label.startswith("blind") else run.opts.model)
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
        raise session.SessionUnavailable(f"{label}: the session ran twice and produced no JSON")
    return parsed, errs


# ---------------------------------------------------------------------------------------------
# What a reader and a judge are told the names mean
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


def aggregates_table(aggregates: dict[str, list[str]]) -> str:
    if not aggregates:
        return "(the node claims no aggregate word)\n"
    return "\n".join(f"- `{w}` covers: {', '.join(classes) or '(no class declared)'}" for w, classes in sorted(aggregates.items())) + "\n"


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
# The review of a coded node: blind read of the rendered rule, then the judge against the law
# ---------------------------------------------------------------------------------------------
def review_node(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, reading: Reading, rule_json: dict | None,
                coder_narrowings: list[dict], out_dir: Path) -> tuple[bool, list[str], dict | None]:
    """Whether the coded rule, read without the law, says what the law says. The reader sees the
    formulas rendered as prose and the contracts; the judge sees the law with its segmentation,
    the reading, the node's claims (the plan's residues and narrowings, and the coder's narrowings
    apart from them), the contracts and the aggregate memberships. A judge answer the harness cannot read is asked for once more and then
    counts against the node; with `judge_samples` above one, every judge must find the node
    aligned. Raises `SessionUnavailable` when a session never ran."""
    from ..lean import render_formula
    glosses = glosses_for(n, onto, run)
    aggs = aggregates_for(n, reading)
    if rule_json is None:
        return False, ["the gate exported no rule to review"], None
    rendered = render_formula.render_rule(rule_json, glosses)
    reading_json, reader_errs = _session(run, out_dir, "blind", render.render("blind_read.md", {
        "rendered_rule": rendered, "contracts": contracts_table(glosses, aggs)}), check=reading_defects)
    if reading_json is None:
        return True, ["review skipped (dry run)"], None
    (out_dir / "rendered_rule.md").write_text(rendered, encoding="utf-8")
    if reader_errs:
        return False, [f"blind reading malformed: {e}" for e in reader_errs], None
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in n.get("segmentation", []))
    claims = {k: n.raw.get(k, []) for k in ("elements", "operationalizations", "assumptions", "compositions")}
    claims["elements"] = [{k: v for k, v in e.items() if k != "justification"} for e in claims["elements"]]
    claims["residues_declared_by_the_plan"] = n.raw.get("residues", [])
    claims["narrowings_declared_by_the_plan"] = n.raw.get("narrowings", [])
    claims["narrowings_by_the_coder"] = coder_narrowings
    prompt = render.render("alignment_judge.md", {
        "law_and_segmentation": f"**{law.id}** — {law.title}\n\n{law.text}\n\nSpans:\n{seg}\n",
        "blind_reading": json.dumps(reading_json, ensure_ascii=False, indent=1),
        "claims": json.dumps(claims, ensure_ascii=False, indent=1),
        "contracts": contracts_table(glosses, aggs), "aggregates": aggregates_table(aggs)})
    claimed = claimed_closure(n, onto) | set(glosses)
    reading_text = _flat(reading_json)
    carried = plan_carriers(n)
    check = lambda v: judge_defects(v, n, reading_text, carried)
    samples = max(1, int(getattr(run.opts, "judge_samples", 1)))
    all_reasons: list[str] = []
    last = None
    for k in range(samples):
        label = "judge" if k == 0 else f"judge{k + 1}"
        verdict, errs = _session(run, out_dir, label, prompt, check=check)
        if verdict is None:
            return True, ["review skipped (dry run)"], None
        last = verdict
        reasons, notes = judge_reasons(verdict, errs, claimed)
        (out_dir / f"{label}_notes.txt").write_text("\n".join(notes), encoding="utf-8")
        all_reasons += [f"[{label}] {r}" for r in reasons] if samples > 1 else reasons
    return not all_reasons, all_reasons, last


def plan_carriers(n: Node) -> set[str]:
    """Spans the plan carries by a residue, an assumption or a composition: the only spans a judge
    may mark `carried`."""
    return {x.get("span") for key in ("residues", "assumptions", "compositions") for x in n.get(key, [])}


def reading_defects(reading: dict) -> list[str]:
    errs = []
    for k in ("who", "when", "must"):
        if not isinstance(reading.get(k), str) or not reading.get(k, "").strip():
            errs.append(f"`{k}` must be a non-empty string")
    for k in ("unless", "assumes", "unknown_when", "relies_on"):
        if k in reading and not isinstance(reading[k], list):
            errs.append(f"`{k}` must be a list")
    return errs


def judge_defects(verdict: dict, n: Node, reading_text: str, carried: set[str]) -> list[str]:
    """What a judge's answer gets wrong as an answer: a span judged twice or not at all, a verdict
    word outside the five, a `carried` on a span the plan does not carry, a decided verdict with no
    verbatim quote from the reading, a top-level verdict that disagrees with the rows."""
    errs = []
    rows = verdict.get("spans")
    if not isinstance(rows, list):
        return ["`spans` must be a list of {id, verdict, quote}"]
    spans = n.spans()
    judged = [s for s, sp in spans.items() if sp.get("role") in blueprint.SUBSTANTIVE and sp.get("role") != "reference"]
    seen: list[str] = []
    for r in rows:
        if not isinstance(r, dict):
            errs.append("a row is not an object"); continue
        sid, v, q = r.get("id"), r.get("verdict"), r.get("quote")
        if sid not in spans:
            errs.append(f"span `{sid}` does not exist"); continue
        if sid in seen:
            errs.append(f"span `{sid}` is judged twice")
        seen.append(sid)
        if v not in JUDGE_VERDICTS:
            errs.append(f"span `{sid}`: verdict `{v}` is not one of {sorted(JUDGE_VERDICTS)}")
        if v == "carried" and sid not in carried:
            errs.append(f"span `{sid}`: `carried`, but the plan carries it by no residue, assumption or composition")
        if v in ("covered", "carried", "approximated", "contradicted"):
            if not isinstance(q, str) or not q.strip():
                errs.append(f"span `{sid}`: `{v}` needs a verbatim quote from the reading")
            elif _norm(q) not in reading_text:
                errs.append(f"span `{sid}`: the quote is not verbatim from the blind reading")
    for sid in judged:
        if sid not in seen:
            errs.append(f"span `{sid}` has no verdict")
    by_quote: dict[str, list[tuple[str, str]]] = {}
    for r in rows:
        if isinstance(r, dict) and isinstance(r.get("quote"), str) and r.get("verdict") in ("covered", "approximated", "contradicted"):
            by_quote.setdefault(_norm(r["quote"]), []).append((str(r.get("id")), str(r.get("verdict"))))
    for q, group in by_quote.items():
        if len({v for _, v in group}) > 1:
            errs.append("spans " + ", ".join(f"`{s}`" for s, _ in group) + " are decided by one quote with different verdicts; one sentence of the reading cannot both cover and approximate — quote the words that decide each span")
    extra = verdict.get("extra", [])
    if not isinstance(extra, list) or any(not isinstance(x, dict) or not x.get("assertion") or not x.get("relies_on") for x in extra):
        errs.append("`extra` must be a list of {assertion, relies_on}")
    top = verdict.get("verdict")
    expect = "misaligned" if (any(isinstance(r, dict) and r.get("verdict") in MISALIGNED for r in rows) or (isinstance(extra, list) and extra)) else "aligned"
    if top not in ("aligned", "misaligned"):
        errs.append("`verdict` must be `aligned` or `misaligned`")
    elif top != expect:
        errs.append(f"`verdict` is `{top}` but the rows say `{expect}`")
    return errs


def judge_reasons(verdict: dict, defects: list[str], claimed: set[str]) -> tuple[list[str], list[str]]:
    """The reasons a judge's answer returns the node, and the notes that do not. A remaining schema
    defect is a reason: a verdict the harness cannot read certifies nothing."""
    reasons = [f"judge output malformed: {e}" for e in defects]
    notes = []
    rows = verdict.get("spans") if isinstance(verdict.get("spans"), list) else []
    for r in rows:
        if isinstance(r, dict) and r.get("verdict") in MISALIGNED:
            reasons.append(f"span {r.get('id')} {r.get('verdict')}: {r.get('quote', '')}")
    extra = verdict.get("extra") if isinstance(verdict.get("extra"), list) else []
    for x in extra:
        if not isinstance(x, dict):
            continue
        rel = str(x.get("relies_on", ""))
        if any(c in rel for c in claimed):
            notes.append(f"extra (rests on a claimed id, ignored): {x.get('assertion')}")
        else:
            reasons.append(f"extra assertion: {x.get('assertion')} (relies on {rel})")
    if verdict.get("verdict") == "misaligned" and not reasons:
        reasons.append("the judge returned `misaligned` with no misaligned span and no extra")
    return reasons, notes


def _norm(t: str) -> str:
    import re
    t = re.sub(r"\s+", " ", str(t)).strip().lower()
    return t.replace("’", "'").replace("“", '"').replace("”", '"').replace("…", "...")


def _flat(obj) -> str:
    if isinstance(obj, dict):
        return " ".join(_flat(v) for v in obj.values())
    if isinstance(obj, list):
        return " ".join(_flat(v) for v in obj)
    return _norm(obj)


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


def review_concept(run: Run, rec: ConceptRecord, extras: dict, out_dir: Path, nodes: list[Node],
                   defs: list[dict]) -> tuple[bool, list[str], dict | None]:
    """The alignment check a concept gets once its body exists: the expanded body rendered as prose,
    read blind, judged against the contract (and, for a fresh concept, the spans that motivated it).
    A supersession's judge sees no law. Raises `SessionUnavailable` when a session never ran."""
    from ..lean import render_formula
    onto = ontology.load(run.opts.ontology)
    glosses = {aid: onto.contract(aid) for aid in extras.get("reads", [])}
    for cid, crec in run.all_concepts().items():
        glosses[cid] = " ".join(str(crec.get("contract", "")).split())
    rendered = render_formula.render_concept({"args": [{"name": a["name"], "sort": {"sort": a["sort"], "values": a.get("values", [])}} for a in rec.args()],
                                              "params": [{"name": p["name"], "unit": p["unit"]} for p in rec.params()],
                                              "kind": rec.get("kind"), "body": extras.get("body_json")}, glosses)
    contracts = "\n".join(f"- `{k}`: {v}" for k, v in sorted(glosses.items()) if v) or "(none)"
    reading_json, _e = _session(run, out_dir, "blind", render.render("concept_blind.md", {"rendered_body": rendered, "contracts": contracts}))
    if reading_json is None:
        return True, ["review skipped (dry run)"], None
    definition = ""
    if rec.get("definition"):
        d = next((x for x in defs if x.get("id") == rec.get("definition")), None)
        definition = f"`{rec.get('definition')}`: {d.get('text', '')}" if d else f"`{rec.get('definition')}` (text not given)"
    supersession = rec.get("supersedes") or ""
    spans = "(none: a supersession is judged against the contract alone)" if supersession else ("\n".join(f"- {s}" for s in motivating_spans(rec, nodes)) or "(none)")
    verdict, errs = _session(run, out_dir, "judge", render.render("concept_judge.md", {
        "contract": " ".join(str(rec.get("contract", "")).split()), "definition": definition or "(none)",
        "blind_reading": json.dumps(reading_json, ensure_ascii=False, indent=1), "motivating_spans": spans,
        "supersession": f"supersedes `{supersession}`" if supersession else "a fresh concept"}),
        check=lambda v: ([] if v.get("verdict") in CONCEPT_VERDICTS else [f"`verdict` must be one of {sorted(CONCEPT_VERDICTS)}"])
                        + ([] if v.get("family") in ("fits", "misfiled") else ["`family` must be `fits` or `misfiled`"]))
    if verdict is None:
        return True, ["review skipped (dry run)"], None
    reasons = [f"judge output malformed: {e}" for e in errs]
    if verdict.get("verdict") != "accept":
        reasons.append(f"{verdict.get('verdict')}: " + "; ".join(str(r) for r in verdict.get("reasons", [])[:4]))
    if verdict.get("family") not in (None, "fits"):
        reasons.append(f"family: {verdict.get('family')}")
    return not reasons, reasons, verdict
