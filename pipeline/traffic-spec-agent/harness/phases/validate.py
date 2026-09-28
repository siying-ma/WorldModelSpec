"""Validate: A (deterministic) then B (blind read + alignment judge) per surviving node."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from .. import blueprint, corpus, ontology, render, runner, validate_a
from ..blueprint import Node
from ..mapping import MappingIndex
from ..reading import Reading
from ..state import Run

PLACEHOLDERS_BLIND = ("formal_content", "ontology_subset")
PLACEHOLDERS_JUDGE = ("law_and_segmentation", "blind_reading", "claims")


@dataclass
class NodeVerdict:
    node: Node
    kind: str                     # accept | return | block
    reasons: list[str] = field(default_factory=list)
    gaps: list[dict] = field(default_factory=list)
    judge: dict | None = None


def disputes_of(plan_dir: Path) -> set[str]:
    from ..mapping import normalize
    p = plan_dir / "PLAN.md"
    if not p.exists():
        return set()
    text = p.read_text(encoding="utf-8")
    if "## Disputes" not in text:
        return set()
    block = text.split("## Disputes", 1)[1].split("\n## ", 1)[0]
    import re
    return {normalize(q) for q in re.findall(r"`([^`]+)`", block)}


def formal_content(n: Node) -> str:
    keep = {k: n.raw.get(k) for k in ("binders", "applicability", "obligation", "elements", "operationalizations", "compositions", "assumptions", "residues")}
    for e in keep.get("elements") or []:
        e.pop("justification", None)   # the reader sees the mapping, not the argument for it
    return json.dumps(keep, ensure_ascii=False, indent=1)


def _session(run: Run, out_dir: Path, label: str, prompt: str) -> dict | None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{label}_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return None
    code, result, _ = runner.run_claude(prompt, cwd=out_dir, stream_path=out_dir / f"{label}_session.jsonl",
                                        max_turns=6, model=run.opts.model, effort=run.opts.judge_effort,
                                        max_budget_usd=run.opts.session_budget_usd, timeout_seconds=900)
    text = (result or {}).get("result", "") or ""
    (out_dir / f"{label}_result.txt").write_text(text, encoding="utf-8")
    return render.extract_json(text)


def judge_node(run: Run, n: Node, law: corpus.Law, onto: ontology.Ontology, out_dir: Path, reading_ρ=None) -> tuple[bool, list[str], dict | None]:
    reading = _session(run, out_dir, "blind", render.render("blind_read.md", {
        "formal_content": formal_content(n),
        "ontology_subset": onto.subset_text(n.claimed_atoms())}))
    if reading is None:
        return (True, ["judge skipped (dry run or no output)"], None) if run.opts.dry_run else (False, ["blind reader produced no JSON"], None)
    seg = "\n".join(f"- `{s['id']}` ({s['role']}): {s['text']}" for s in n.get("segmentation", []))
    claims = json.dumps({k: n.raw.get(k, []) for k in ("elements", "operationalizations", "assumptions", "compositions", "residues")}, ensure_ascii=False, indent=1)
    verdict = _session(run, out_dir, "judge", render.render("alignment_judge.md", {
        "law_and_segmentation": f"**{law.id}** — {law.title}\n\n{law.text}\n\nSpans:\n{seg}\n",
        "blind_reading": json.dumps(reading, ensure_ascii=False, indent=1),
        "claims": claims}))
    if verdict is None:
        return False, ["judge produced no JSON"], None
    # mechanical checks on the judge's output
    spans = n.spans()
    reasons, notes = [], []
    rows = verdict.get("spans", [])
    ids = {r.get("id") for r in rows}
    for sid, s in spans.items():
        if s.get("role") in blueprint.SUBSTANTIVE and s.get("role") != "reference" and sid not in ids:
            reasons.append(f"judge gave no verdict for span {sid}")
    reading_text = _flat(reading)
    for r in rows:
        if r.get("id") not in spans:
            reasons.append(f"judge names unknown span {r.get('id')}")
        if r.get("verdict") in ("approximated", "contradicted", "missing"):
            reasons.append(f"span {r.get('id')} {r.get('verdict')}: {r.get('quote', '')}")
        if r.get("quote") and _norm(r["quote"]) not in reading_text:
            notes.append(f"judge quote for span {r.get('id')} is not verbatim from the blind reading")
    # an assertion that rests on something the node claims is a judgement about a span, not an extra
    claimed = claimed_closure(n, onto)
    for x in verdict.get("extra", []):
        rel = str(x.get("relies_on", ""))
        if any(c in rel for c in claimed):
            notes.append(f"extra (rests on a claimed id, ignored): {x.get('assertion')}")
        else:
            reasons.append(f"extra assertion: {x.get('assertion')} (relies on {rel})")
    aligned = not reasons and not any(r.get("verdict") in ("approximated", "contradicted", "missing") for r in rows)
    (out_dir / "judge_notes.txt").write_text("\n".join(notes), encoding="utf-8")
    return aligned, reasons, verdict


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


def claimed_closure(n: Node, onto: ontology.Ontology) -> set[str]:
    """Ids the node claims, atoms its claimed concepts read, and the classes of the reading's
    aggregates whose words the elements use."""
    from .. import surface
    out = set(n.claimed_atoms())
    reads = surface.derived_reads()
    for c in list(out):
        for lean_name in reads.get(c.replace(".", "_"), []):
            aid = surface.atom_id_of(lean_name, onto.atom_ids)
            if aid:
                out.add(aid)
    return out


def run_validate(run: Run, plan_dir: Path, laws: dict[str, corpus.Law], reading: Reading) -> list[NodeVerdict]:
    out_dir = run.iter / "validate"
    out_dir.mkdir(parents=True, exist_ok=True)
    nodes = blueprint.load(plan_dir / "blueprint.jsonl")
    onto = ontology.load(run.opts.ontology)
    index = MappingIndex(run.mapping_file)
    accepted = {k: Node(v) for k, v in run.accepted_nodes.items()}
    outcomes = validate_a.validate(nodes, laws, onto, reading, index, accepted, disputes_of(plan_dir))
    verdicts: list[NodeVerdict] = []
    for o in outcomes:
        if o.kind != validate_a.ACCEPT or not run.opts.judge:
            verdicts.append(NodeVerdict(o.node, o.kind, o.reasons, o.gaps)); continue
        aligned, reasons, judge = judge_node(run, o.node, laws[o.node.law], onto, out_dir / o.node.id)
        verdicts.append(NodeVerdict(o.node, "accept" if aligned else "judge", reasons, [], judge))
    (out_dir / "verdicts.jsonl").write_text("".join(json.dumps({"node_id": v.node.id, "kind": v.kind, "reasons": v.reasons, "gaps": v.gaps}, ensure_ascii=False) + "\n" for v in verdicts), encoding="utf-8")
    return verdicts
