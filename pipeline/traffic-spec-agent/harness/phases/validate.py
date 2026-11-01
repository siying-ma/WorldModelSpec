"""Validate: A (deterministic) over a plan, and the tool-less sessions the reviews share.

Validator A runs on the blueprint before any code and decides `accept`, `return` or `fail` per
node. `_session` runs one tool-less session with a schema check (the reviewers and the
adjudicators of `review.py` use it); it goes through `session.run`, so a session the account or
the API refused is relaunched and, if it still does not run, raises `SessionUnavailable` for the
loop to defer the law without counting an attempt.
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
from ..store import jsonl
from ..store.gaps import GapLedger
from ..store import paths



@dataclass
class NodeVerdict:
    node: Node
    kind: str                     # accept | return | fail
    reasons: list[str] = field(default_factory=list)


# ---------------------------------------------------------------------------------------------
# Validator A, in the run's context
# ---------------------------------------------------------------------------------------------
def validate_a_for_run(run: Run | None, plan_dir: Path, laws: dict[str, corpus.Law], reading: Reading, defs: list[dict],
                       onto: ontology.Ontology | None = None, blueprint_file: Path | None = None,
                       extra_concepts: list[ConceptRecord] | None = None, extra_nodes: list[Node] | None = None,
                       extra_validate_nodes: list[Node] | None = None, known_nodes: list[Node] | None = None,
                       prior_nodes: list[Node] | None = None) -> tuple[list[Node], list[ConceptRecord], list[validate_a.Outcome], list[validate_a.ConceptOutcome]]:
    """Validator A over the concepts and nodes of a blueprint, against everything the run knows:
    its accepted nodes and concepts, its mapping index (for the roles of a law's own words) and its
    mode. The loop and the `validate` command both call this, so a draft is checked by the
    check that will accept it. With no run, nothing is accepted and the mapping index is empty."""
    bp = blueprint_file or (plan_dir / "blueprint.jsonl")
    nodes = blueprint.load(bp) + list(extra_validate_nodes or [])          # repaired node records are validated with the plan's
    repaired_ids = {c.id for c in extra_concepts or []}                    # repaired records join the plan's, and a plan
    concepts = [c for c in blueprint.load_concepts(bp) if c.id not in repaired_ids] + list(extra_concepts or [])  # copy of one is dropped
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
    rejected = GapLedger.for_run(paths.GAPS_DIR, run).rejected()
    outcomes = validate_a.validate(nodes, laws, onto, reading, index, accepted, accepted_concepts, valid_concepts,
                                   known_nodes=known_nodes, rejected_gaps=rejected, prior_nodes=prior_nodes)
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
    verdicts = [NodeVerdict(o.node, o.kind, o.reasons) for o in outcomes]
    (out_dir / "verdicts.jsonl").write_text("".join(json.dumps({"node_id": o.node.id, "kind": o.kind, "reasons": o.reasons, "gaps": o.gaps, "proposals": o.proposals}, ensure_ascii=False) + "\n" for o in outcomes), encoding="utf-8")
    (out_dir / "concept_verdicts.jsonl").write_text("".join(json.dumps({"concept_id": o.concept.id, "kind": o.kind, "reasons": o.reasons}, ensure_ascii=False) + "\n" for o in concept_outcomes), encoding="utf-8")
    return verdicts, concept_outcomes


# ---------------------------------------------------------------------------------------------
# Sessions
# ---------------------------------------------------------------------------------------------
def answer_digest(run: Run, prompt: str, model: str | None = None, effort: str | None = None) -> str:
    """The identity of a tool-less session's answer: the digest of its full prompt, its model and its
    effort, as the session is launched with them."""
    import hashlib
    return hashlib.sha256(json.dumps({"prompt": prompt, "model": model or run.opts.model, "effort": effort or run.opts.judge_effort},
                                     sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


def _session(run: Run, out_dir: Path, label: str, prompt: str, check=None, model: str | None = None,
             effort: str | None = None, usage_label: str | None = None) -> tuple[dict | None, list[str]]:
    """One tool-less session: its JSON and the schema defects that remain. `check(parsed)` names the
    defects of an answer; an answer with defects is asked for once more with the defects appended,
    and the second answer stands whole, with whatever defects it keeps (the caller decides what
    they mean). A session
    that ran and wrote no JSON is asked once more; a second silence returns no answer with that
    defect, which the caller counts against the node. An answer without defects is kept with the
    digest of the prompt, model and effort (`<label>_answer.json`), and the same session asked again
    in the same directory on the same inputs takes it back without a call: a review resumed after a
    pause pays for no judgment it already has. `usage_label` names the session's rows in
    `usage.jsonl` (its subject included), `label` its files. In a dry run `(None, [])`."""
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / f"{label}_prompt.md").write_text(prompt, encoding="utf-8")
    if run.opts.dry_run:
        return None, []
    digest = answer_digest(run, prompt, model, effort)
    kept_file = out_dir / f"{label}_answer.json"
    try:
        kept = json.loads(kept_file.read_text(encoding="utf-8"))
        if kept.get("digest") == digest and isinstance(kept.get("answer"), dict) and not (check and list(check(kept["answer"]))):
            return kept["answer"], []
    except (OSError, json.JSONDecodeError):
        pass
    ask = prompt
    parsed, errs = None, []
    for attempt in ("", "_again"):
        record = session.run(ask, cwd=out_dir, out_dir=out_dir, opts=run.opts, max_turns=6,
                             effort=effort or run.opts.judge_effort, label=label + attempt, timeout=900,
                             allow=[], tools=[], model=model or run.opts.model,
                             usage_label=(usage_label + attempt) if usage_label else None)
        text = ((record.get("result") or {}).get("result", "") or "")
        (out_dir / f"{label}{attempt}_result.txt").write_text(text, encoding="utf-8")
        parsed = render.extract_json(text)
        if parsed is None:
            errs = ["no JSON object in the answer"]
        else:
            errs = list(check(parsed)) if check else []
            if not errs:
                jsonl.write_atomic(kept_file, json.dumps({"digest": digest, "answer": parsed}, ensure_ascii=False, indent=1))
                return parsed, []
        ask = prompt + "\n\n## Defects of your previous answer\n\nAnswer again, in the same schema, without these defects:\n" + "".join(f"- {e}\n" for e in errs)
    if parsed is None:
        return None, [f"{label}: no JSON object in the answer, twice"]
    return parsed, errs


# ---------------------------------------------------------------------------------------------
# What a reviewer is told the names mean
# ---------------------------------------------------------------------------------------------
def glosses_of(names, onto: ontology.Ontology, run: Run | None = None) -> dict[str, str]:
    """The contract of each id or Lean name: an accessor resolves to its atom as the gate's
    canonical form does (`st_region_geometry_distance` → `st.region_geometry`), a primitive to its
    `prim.*` row, a concept id to the run's catalogue, a declared-fact id (`asm.*`, `int.*`) to its
    meaning in the run's reading. The one path every contract a reviewer or a judge is shown goes
    through. A declared-fact id the reading does not mean is never left out: it breaks the invariant
    that every record is validated against the catalogue, and stops the run."""
    from ..lean import surface
    from ..model.reading import DECLARED_ID
    from ..store.jsonl import DataIntegrityError
    atom_ids = set(onto.atom_ids)
    concepts = run.all_concepts() if run is not None else {}
    declarations = Reading(run.reading_file).declarations() if run is not None else {}
    out: dict[str, str] = {}
    for name in names:
        name = str(name).split("=")[0]
        if DECLARED_ID.match(name):
            if not str((declarations.get(name) or {}).get("meaning") or "").strip():
                raise DataIntegrityError(run.reading_file if run is not None else Path("reading"), None,
                                         f"the declared id `{name}` has no meaning in the run's reading")
            out[name] = " ".join(declarations[name]["meaning"].split())
            continue
        if name in concepts:
            out[name] = " ".join(str(concepts[name].get("contract", "")).split())
            continue
        if name.startswith("drv_"):
            cid = next((c for c in concepts if c.replace(".", "_") == name), None)
            if cid:
                out[cid] = " ".join(str(concepts[cid].get("contract", "")).split())
            continue
        aid = name if "." in name else (name.replace("_", ".", 1) if name.startswith("prim_") else surface.atom_id_of(name, atom_ids))
        if aid and onto.contract(aid):
            out[aid] = onto.contract(aid)
    return out


def glosses_for(node: Node, onto: ontology.Ontology, run: Run) -> dict[str, str]:
    """Contracts of every id the node claims, what its claimed concepts and primitives read, and
    its compositions."""
    ids = set(claimed_closure(node, onto))
    for cid, rec in run.all_concepts().items():
        if cid in node.claimed_atoms():
            ids.add(cid)
            ids |= set(rec.get("reads", []))
    ids |= {d.get("id") for d in node.get("assumptions", []) + node.get("intentions", []) if d.get("id")}
    out = glosses_of(sorted(ids), onto, run)
    for c in node.compositions():
        out[c.get("rule", "")] = "another rule of the library; its verdict, or whether it applies, is read here"
    return out


def contracts_table(glosses: dict[str, str]) -> str:
    lines = ["| id | contract |", "|---|---|"]
    lines += [f"| `{k}` | {v} |" for k, v in sorted(glosses.items()) if v]
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
