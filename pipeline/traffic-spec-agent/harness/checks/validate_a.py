"""Validate A: the deterministic checks of design §4 over a blueprint."""
from __future__ import annotations
import re
from dataclasses import dataclass, field
from ..model import nodeid
from ..model.blueprint import (Node, ConceptRecord, REQUIRED, ROLES, SUBSTANTIVE, SCENARIOS, GAP_KINDS, AS_KINDS, concepts_of,
                        normalize_verdict, CONCEPT_REQUIRED, CONCEPT_SCENARIOS, CONCEPT_KINDS, ARG_SORTS)
from ..model.units import FACTORS
from ..model.corpus import Law
from ..model.mapping import MappingIndex, normalize
from ..model.ontology import Ontology
from ..model.reading import Reading

ACCEPT, RETURN, BLOCK = "accept", "return", "block"
_STRIP = re.compile(r"[\s\.,;:()\[\]“”\"'‘’—–-]+")


def _bare(t: str) -> str:
    return _STRIP.sub("", re.sub(r"\[[A-Z]+-[^\]]+\]", "", t)).lower()


@dataclass
class Outcome:
    node: Node
    kind: str
    reasons: list[str] = field(default_factory=list)
    gaps: list[dict] = field(default_factory=list)


def check_segmentation(node: Node, law: Law) -> list[str]:
    errs = []
    spans = node.get("segmentation", [])
    if not spans:
        return [f"{node.id}: no segmentation"]
    ids = [s.get("id") for s in spans]
    if len(set(ids)) != len(ids):
        errs.append(f"{node.id}: duplicate span ids")
    pos, covered = 0, []
    for s in spans:
        t = s.get("text", "")
        if s.get("role") not in ROLES:
            errs.append(f"{node.id}: span {s.get('id')} has role {s.get('role')!r}, not one of {sorted(ROLES)}")
        i = law.text.find(t, pos)
        if not t or i < 0:
            if t and law.text.find(t) >= 0:
                errs.append(f"{node.id}: span {s.get('id')} is out of order or overlaps a previous span")
            else:
                errs.append(f"{node.id}: span {s.get('id')} is not a verbatim substring of the law")
            continue
        covered.append(t); pos = i + len(t)
    if _bare("".join(covered)) != _bare(law.text):
        errs.append(f"{node.id}: the spans do not cover the whole text (missing or overlapping words)")
    return errs


def check_accounting(node: Node) -> list[str]:
    errs = []
    spans = node.spans()
    carriers: dict[str, list[str]] = {sid: [] for sid in spans}
    for key in ("elements", "operationalizations", "assumptions", "compositions", "residues", "gaps"):
        for item in node.get(key, []):
            sid = item.get("span")
            if sid not in spans:
                errs.append(f"{node.id}: {key} entry refers to unknown span {sid!r}")
            else:
                carriers[sid].append(key)
    for sid, s in spans.items():
        role, n = s.get("role"), len(carriers[sid])
        if role == "reference":
            # a reference names one or several rules: one composition per rule named, or one residue/gap
            if n == 0 or (n > 1 and set(carriers[sid]) != {"compositions"}):
                errs.append(f"{node.id}: reference span {sid} must be carried by compositions (one per rule it names) or by one residue or gap")
        elif role in SUBSTANTIVE and n != 1:
            errs.append(f"{node.id}: span {sid} ({role}) is carried by {n} entries, must be exactly one")
        elif role == "sibling" and n != 0:
            errs.append(f"{node.id}: sibling span {sid} belongs to another node of the same law and carries nothing here")
        if role == "definitional" and n == 0 and not re.search(r"\[DEF-", s.get("text", "")):
            errs.append(f"{node.id}: definitional span {sid} cites no definition and carries nothing")
    return errs


def check_closed_set(node: Node, onto: Ontology, concept_ids: set[str] | None = None) -> tuple[list[str], list[dict]]:
    """Unknown ids: a gap when the node proposes one for that span, a rejection otherwise. A concept
    id is known when it is accepted (this run's or the base run's) or proposed in this plan."""
    errs, gaps = [], []
    concept_ids = concept_ids or set()
    proposed = {g.get("span") for g in node.gaps()}
    for e in node.get("elements", []):
        for ident in list(e.get("atoms", [])) + list(e.get("derived", [])):
            if ident.startswith("ru.aggregate"):
                if "=" not in ident:
                    errs.append(f"{node.id}: `ru.aggregate` names no word on span {e.get('span')} (write `ru.aggregate=<word>`)")
                continue          # the word itself is checked against the reading
            if not onto.knows(ident) and ident not in concept_ids:
                if e.get("span") in proposed:
                    continue
                if nodeid.is_concept_id(ident):
                    errs.append(f"{node.id}: concept `{ident}` is neither accepted nor proposed in this plan (a concept record for span {e.get('span')})")
                else:
                    errs.append(f"{node.id}: `{ident}` is not in the ontology and no gap is proposed for span {e.get('span')}")
    for o in node.get("operationalizations", []):
        cs = concepts_of(o)
        if not cs:
            errs.append(f"{node.id}: operationalization on span {o.get('span')} names no concept")
        for c in cs:
            if c not in onto.primitive_ids and c not in onto.atom_ids and c not in concept_ids:
                errs.append(f"{node.id}: operationalization concept `{c}` is neither a concept, a primitive nor an atom")
    for g in node.gaps():
        if g.get("kind") not in GAP_KINDS:
            errs.append(f"{node.id}: gap kind {g.get('kind')!r} not in {sorted(GAP_KINDS)}")
        if not g.get("proposal") or not g.get("nearest"):
            errs.append(f"{node.id}: gap for span {g.get('span')} lacks a proposal or its nearest atoms")
        else:
            gaps.append(g)
    return errs, gaps


def check_standards(node: Node, reading: Reading) -> tuple[list[str], list[dict]]:
    """Errors, and the value gaps: a parameter the reading lacks blocks the node until the operator
    sets it; it never returns the node, so a planner has no reason to bound a standard without one."""
    errs, gaps = [], []
    spans = node.spans()
    op_spans = {o.get("span") for o in node.get("operationalizations", [])}
    for sid, s in spans.items():
        if s.get("role") == "standard" and sid not in op_spans:
            errs.append(f"{node.id}: standard span {sid} has no operationalization")
    for o in node.get("operationalizations", []):
        if not o.get("params"):
            errs.append(f"{node.id}: operationalization on span {o.get('span')} names no parameter — a standard is a bound the reading sets; "
                        "a structural test with no magnitude approximates it (name the parameter even if the reading lacks it, or file a gap)")
    for p in node.params():
        if not reading.has(p):
            ops = [o for o in node.get("operationalizations", []) if p in o.get("params", [])]
            o = ops[0] if ops else {}
            gaps.append({"span": o.get("span", ""), "kind": "value", "parameter": p,
                         "proposal": f"reading parameter `{p}`: {o.get('convention', 'convention as the node states it')}",
                         "nearest": list(concepts_of(o)) if o else []})
    for ident in sorted(node.claimed_atoms()):
        if ident.startswith("ru.aggregate="):
            w = ident.split("=", 1)[1]
            if w not in reading.aggregate_words():
                errs.append(f"{node.id}: aggregate word `{w}` is not declared by the reading (its `aggregates`)")
    return errs, gaps


ANCHORS = {"rel.occupies", "st.region_geometry"}


def check_anchoring(node: Node) -> list[str]:
    """A node that reads a road feature or a device must be able to tie it to a binder: it claims an
    anchoring atom. Without one, every region the rule quantifies over is any region of the scene."""
    claimed = {c.split("=")[0] for c in node.claimed_atoms()}
    features = sorted(c for c in claimed if c.startswith("st.") or c.startswith("dev."))
    if features and not (claimed & ANCHORS):
        return [f"{node.id}: claims {features[:4]} but no anchoring atom ({sorted(ANCHORS)}): a feature the rule reads must be the subject's, not any in the scene — claim `rel.occupies` (or `st.region_geometry`) on the span that places the subject on it"]
    return []


def readable_atoms(node: Node, onto: Ontology, concept_atoms: dict[str, set[str]] | None = None) -> set[str]:
    """Atoms the node reads: those it claims, those its claimed primitives read, and those its
    claimed concepts read (`concept_atoms`, id → atom ids)."""
    from ..lean import surface
    reads = surface.primitive_reads()
    out = {c.split("=")[0] for c in node.claimed_atoms() if c.split("=")[0] in onto.atom_ids}
    for c in node.claimed_atoms():
        for lean_name in reads.get(c.replace(".", "_"), []):
            aid = surface.atom_id_of(lean_name, onto.atom_ids)
            if aid:
                out.add(aid)
        out |= (concept_atoms or {}).get(c, set())
    return out


def concept_atom_map(onto: Ontology, accepted: dict[str, dict], plan: list[ConceptRecord]) -> dict[str, set[str]]:
    """Atom ids each concept reads: an accepted concept's recorded `reads`; a planned concept's
    elements' atoms plus, transitively, those of the concepts it references."""
    out: dict[str, set[str]] = {cid: set(rec.get("reads", [])) for cid, rec in accepted.items()}
    planned = {c.id: c for c in plan}
    def go(cid: str, seen: tuple[str, ...]) -> set[str]:
        if cid in out:
            return out[cid]
        c = planned.get(cid)
        if c is None or cid in seen:
            return set()
        acc = {a.split("=")[0] for a in c.claimed_atoms() if a.split("=")[0] in onto.atom_ids}
        for r in c.refs():
            acc |= go(r, seen + (cid,))
        out[cid] = acc
        return acc
    for cid in planned:
        go(cid, ())
    return out


def check_literals(node: Node) -> list[str]:
    errs = []
    spans = node.spans()
    for lit in node.literals():
        sid = lit.get("span")
        if sid not in spans:
            errs.append(f"{node.id}: literal refers to unknown span {sid!r}")
        elif lit.get("text", "") not in spans[sid].get("text", ""):
            errs.append(f"{node.id}: literal text {lit.get('text')!r} is not in span {sid}")
        if not isinstance(lit.get("value"), (int, float)) or not lit.get("unit"):
            errs.append(f"{node.id}: literal on span {sid} needs a numeric value and a unit")
        elif lit.get("unit") not in FACTORS:
            errs.append(f"{node.id}: literal on span {sid} has unit {lit.get('unit')!r}; use one of {sorted(FACTORS)}")
    return errs


def check_scenarios(node: Node, onto: Ontology, concept_atoms: dict[str, set[str]] | None = None) -> list[str]:
    errs = []
    scs = {s.get("name"): s for s in node.get("scenarios", [])}
    for name, exp in SCENARIOS.items():
        if name not in scs:
            errs.append(f"{node.id}: scenario `{name}` missing")
        elif normalize_verdict(scs[name].get("expected")) != exp:
            errs.append(f"{node.id}: scenario `{name}` expects {scs[name].get('expected')!r}, must be {exp!r}")
        else:
            scs[name]["expected"] = exp
    blind = scs.get("blind", {})
    if blind:
        masked = blind.get("masked")
        if not isinstance(masked, list) or not masked or not all(isinstance(m, str) for m in masked):
            errs.append(f"{node.id}: the blind scenario's `masked` must be a list of atom ids, got {masked!r}")
        elif not (set(masked) & readable_atoms(node, onto, concept_atoms)):
            errs.append(f"{node.id}: the blind scenario masks {masked}, none of which the node reads (claimed, or read by a claimed concept)")
    return errs


def claimed_obligation(node: Node) -> str | None:
    """The text of the one obligation span this node carries (element, operationalization or residue)."""
    spans = node.spans()
    carried = [e.get("span") for key in ("elements", "operationalizations", "residues") for e in node.get(key, [])]
    texts = {spans[sid]["text"] for sid in carried if sid in spans and spans[sid].get("role") == "obligation"}
    return next(iter(texts)) if len(texts) == 1 else None


def check_identity(node: Node, law_nodes: list[Node], law: Law) -> list[str]:
    """The node id is the derivation from the law id and the ordinal of its obligation among the
    obligations the law's nodes carry, in text order."""
    if not node.get("law_refs") or node.law != law.id:
        return [f"{node.id}: law_refs must start with the law it segments"]
    if not any(s.get("role") == "obligation" for s in node.get("segmentation", [])):
        return [f"{node.id}: no obligation span"]
    mine = claimed_obligation(node)
    if mine is None:
        return [f"{node.id}: a node carries exactly one obligation span (by an element, an operationalization or a residue)"]
    texts = {claimed_obligation(n) for n in law_nodes} - {None}
    ordered = sorted(texts, key=lambda t: law.text.find(t))
    total, ordinal = len(ordered), ordered.index(mine) + 1
    expected = nodeid.derive(law.id, ordinal, total)
    if node.id != expected:
        return [f"{node.id}: node id must be `{expected}` — the law's nodes carry {total} obligation(s), this one is number {ordinal} in text order"]
    return []


def check_decomposition(nodes: list[Node], law: Law) -> list[str]:
    """Across the nodes of one law: obligation spans (by their words) partitioned, one node each; a
    span one node marks `sibling` is another node's obligation or claimed span."""
    errs = []
    seen: dict[str, str] = {}
    claimed_texts: dict[str, set[str]] = {}
    for n in nodes:
        carried = {e.get("span") for key in ("elements", "operationalizations", "residues", "compositions", "assumptions") for e in n.get(key, [])}
        claimed_texts[n.id] = {normalize(s["text"]) for s in n.get("segmentation", []) if s["id"] in carried}
        for s in n.get("segmentation", []):
            if s.get("role") == "obligation" and s["id"] in carried:
                key = normalize(s["text"])
                if key in seen and seen[key] != n.id:
                    errs.append(f"{law.id}: obligation `{s['text'][:60]}` is claimed by both {seen[key]} and {n.id}")
                seen[key] = n.id
    segmented: dict[str, set[str]] = {n.id: {normalize(s["text"]) for s in n.get("segmentation", []) if s.get("role") != "sibling"} for n in nodes}
    for n in nodes:
        for s in n.get("segmentation", []):
            if s.get("role") == "sibling":
                key = normalize(s["text"])
                if not any(key in segmented[m.id] for m in nodes if m.id != n.id):
                    errs.append(f"{n.id}: sibling span {s['id']} `{s['text'][:60]}` is no other node's span; a connective that belongs to no duty is `boilerplate`")
    return errs


def check_consistency(node: Node, index: MappingIndex, plan_index: dict[str, tuple[set[str], str]], disputes: set[str]) -> list[str]:
    errs = []
    for e in node.get("elements", []):
        sid = e.get("span")
        text = node.spans().get(sid, {}).get("text", "")
        atoms = set(e.get("atoms", [])) | set(e.get("derived", []))
        key = normalize(text)
        if not key:
            continue
        prior = index.lookup(text)
        if prior is not None and prior != atoms and key not in disputes:
            errs.append(f"{node.id}: span {sid} maps `{text[:60]}` to {sorted(atoms)}, an accepted node mapped it to {sorted(prior)}; no dispute recorded")
        if key in plan_index and plan_index[key][0] != atoms and key not in disputes:
            errs.append(f"{node.id}: span {sid} maps `{text[:60]}` differently from node {plan_index[key][1]} in this plan")
        plan_index.setdefault(key, (atoms, node.id))
    return errs


def resolve_rule_ids(node: Node, known: dict[str, Node]) -> list[str]:
    """`rule` names a node; a law id (dashes) is rewritten to its node when the law has one node."""
    errs = []
    for c in node.compositions():
        rid = str(c.get("rule", ""))
        if rid in known:
            continue
        as_node = rid.replace("-", "_")
        if as_node in known:
            c["rule"] = as_node; continue
        siblings = sorted(k for k in known if re.fullmatch(re.escape(as_node) + r"_o\d+", k))
        if len(siblings) == 1:
            c["rule"] = siblings[0]
        elif siblings:
            errs.append(f"{node.id}: composition on span {c.get('span')} names law `{rid}`, which has nodes {siblings}; name the node")
    return errs


def check_compositions(node: Node, known: dict[str, Node]) -> list[str]:
    errs = resolve_rule_ids(node, known)
    for c in node.compositions():
        if c.get("as") not in AS_KINDS:
            errs.append(f"{node.id}: composition on span {c.get('span')} has `as` {c.get('as')!r}; must be one of {sorted(AS_KINDS)}")
        target = known.get(c.get("rule"))
        if target is None:
            errs.append(f"{node.id}: composes `{c.get('rule')}`, which is neither accepted nor in this plan")
            continue
        names = {b["name"] for b in target.get("binders", [])}
        mapped = set((c.get("map") or {}).keys())
        if mapped != names:
            errs.append(f"{node.id}: composition of `{target.id}` maps {sorted(mapped)}, its binders are {sorted(names)}")
    return errs


def acyclic(nodes: dict[str, Node]) -> list[str]:
    graph = {n.id: [c.get("rule") for c in n.compositions()] for n in nodes.values()}
    state: dict[str, int] = {}
    cycles = []

    def visit(u: str, stack: list[str]) -> None:
        state[u] = 1
        for v in graph.get(u, []):
            if v not in graph:
                continue
            if state.get(v) == 1:
                cycles.append(" → ".join(stack + [u, v]))
            elif state.get(v) is None:
                visit(v, stack + [u])
        state[u] = 2

    for u in graph:
        if state.get(u) is None:
            visit(u, [])
    return [f"composition cycle: {c}" for c in cycles]


def validate(nodes: list[Node], laws: dict[str, Law], onto: Ontology, reading: Reading,
             index: MappingIndex, accepted: dict[str, Node], disputes: set[str],
             accepted_concepts: dict[str, dict] | None = None, plan_concepts: list[ConceptRecord] | None = None) -> list[Outcome]:
    outcomes: list[Outcome] = []
    accepted_concepts = accepted_concepts or {}
    plan_concepts = plan_concepts or []
    concept_ids = set(accepted_concepts) | {c.id for c in plan_concepts}
    concept_atoms = concept_atom_map(onto, accepted_concepts, plan_concepts)
    known = dict(accepted); known.update({n.id: n for n in nodes})
    for n in nodes:
        resolve_rule_ids(n, known)
    plan_index: dict[str, tuple[set[str], str]] = {}
    by_law: dict[str, list[Node]] = {}
    for n in nodes:
        by_law.setdefault(n.get("law_refs", ["?"])[0], []).append(n)
    cycle_errs = acyclic(known)
    for n in nodes:
        errs = [f"{n.id}: missing field `{k}`" for k in REQUIRED if k not in n.raw]
        law = laws.get(n.get("law_refs", ["?"])[0])
        if law is None:
            errs.append(f"{n.id}: law {n.get('law_refs')} is not in the corpus given to this run")
        if errs:
            outcomes.append(Outcome(n, RETURN, errs)); continue
        binders = [b.get("name") for b in n.get("binders", [])]
        if not binders:
            errs.append(f"{n.id}: no binders — the subject is always a binder")
        elif (n.get("subject") or {}).get("binder") not in (None, binders[0]):
            errs.append(f"{n.id}: the subject binder `{(n.get('subject') or {}).get('binder')}` must come first in `binders`")
        errs += check_segmentation(n, law)
        errs += check_accounting(n)
        closed_errs, gaps = check_closed_set(n, onto, concept_ids)
        errs += closed_errs
        std_errs, std_gaps = check_standards(n, reading)
        errs += std_errs; gaps += std_gaps
        errs += check_anchoring(n)
        errs += check_scenarios(n, onto, concept_atoms)
        errs += check_literals(n)
        errs += check_identity(n, by_law[law.id], law)
        errs += check_decomposition(by_law[law.id], law)
        errs += check_consistency(n, index, plan_index, disputes)
        errs += check_compositions(n, known)
        errs += [c for c in cycle_errs if n.id in c]
        obligation_residue = any(n.spans().get(r.get("span"), {}).get("role") == "obligation" for r in n.get("residues", []))
        if errs:
            outcomes.append(Outcome(n, RETURN, errs))
        elif gaps:
            outcomes.append(Outcome(n, BLOCK, [f"{n.id}: {len(gaps)} span(s) ground in nothing"], gaps))
        elif obligation_residue:
            outcomes.append(Outcome(n, RETURN, [f"{n.id}: the obligation itself is a residue — not expressible"]))
        else:
            outcomes.append(Outcome(n, ACCEPT))
    return outcomes


# ---------------------------------------------------------------------------------------------
# Concepts (DERIVED_CONCEPTS_PLAN §5.1, §6, §7.4, §8)
# ---------------------------------------------------------------------------------------------
_IDENT = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass
class ConceptOutcome:
    concept: ConceptRecord
    kind: str                     # accept | return
    reasons: list[str] = field(default_factory=list)


def _ws(text: str) -> str:
    return " ".join(str(text or "").split())


def concept_refs_acyclic(plan: list[ConceptRecord], accepted: dict[str, dict]) -> list[str]:
    graph = {c.id: sorted(c.refs()) for c in plan}
    graph.update({cid: sorted(rec.get("refs", [])) for cid, rec in accepted.items() if cid not in graph})
    state: dict[str, int] = {}
    cycles: list[str] = []

    def visit(u: str, stack: list[str]) -> None:
        state[u] = 1
        for v in graph.get(u, []):
            if v not in graph:
                continue
            if state.get(v) == 1:
                cycles.append(" → ".join(stack + [u, v]))
            elif state.get(v) is None:
                visit(v, stack + [u])
        state[u] = 2

    for u in graph:
        if state.get(u) is None:
            visit(u, [])
    return cycles


def check_concept(c: ConceptRecord, defs: dict[str, dict], onto: Ontology, accepted: dict[str, dict],
                  plan_ids: set[str], nodes: dict[str, Node], concept_atoms: dict[str, set[str]], mode: str) -> list[str]:
    errs = [f"{c.id}: missing field `{k}`" for k in CONCEPT_REQUIRED if k not in c.raw]
    if errs:
        return errs
    cid = c.id
    if not nodeid.is_concept_id(cid):
        errs.append(f"{cid}: not of the form drv.<family>.<name> with family in {list(nodeid.CONCEPT_FAMILIES)} and a snake_case name (digits only in a final `_v<n>`)")
    if cid in accepted:
        errs.append(f"{cid}: already accepted; reuse it, or supersede it as `{cid.split('_v')[0]}_v<n+1>` with `supersedes` and a counterexample")
    if c.get("kind") not in CONCEPT_KINDS:
        errs.append(f"{cid}: kind {c.get('kind')!r} not in {sorted(CONCEPT_KINDS)}")
    contract = _ws(c.get("contract"))
    if not contract:
        errs.append(f"{cid}: empty contract")
    d = c.get("definition")
    if d:
        if d not in defs:
            errs.append(f"{cid}: definition `{d}` is not among the definitions given")
        elif contract != _ws(defs[d].get("text", "")):
            errs.append(f"{cid}: a definition-born contract is the definition's text verbatim (`{d}`)")
    # formals
    names = [a.get("name") for a in c.args()]
    if len(set(names)) != len(names):
        errs.append(f"{cid}: duplicate formal argument")
    for a in c.args():
        n, s = a.get("name"), a.get("sort")
        if not n or not _IDENT.match(str(n)):
            errs.append(f"{cid}: formal `{n}` is not a snake_case identifier")
        if s not in ARG_SORTS:
            errs.append(f"{cid}: formal `{n}` has sort {s!r}, not one of {sorted(ARG_SORTS)}")
        if s == "literal" and not (isinstance(a.get("values"), list) and a["values"] and all(isinstance(v, str) for v in a["values"])):
            errs.append(f"{cid}: literal formal `{n}` needs `values`, the admissible spellings")
    pnames = [p.get("name") for p in c.params()]
    if len(set(pnames)) != len(pnames):
        errs.append(f"{cid}: duplicate formal parameter")
    for p in c.params():
        n = p.get("name")
        if not n or not _IDENT.match(str(n)):
            errs.append(f"{cid}: parameter `{n}` is not a snake_case identifier (a formal, never a reading's `p.…`)")
        if p.get("unit") not in FACTORS:
            errs.append(f"{cid}: parameter `{n}` has unit {p.get('unit')!r}; use one of {sorted(FACTORS)}")
        if not _ws(p.get("meaning")):
            errs.append(f"{cid}: parameter `{n}` states no meaning")
    # elements: contract words → atoms and concepts
    if not c.elements():
        errs.append(f"{cid}: no elements: the contract's words map to nothing")
    for e in c.elements():
        span = _ws(e.get("span"))
        if not span or span not in contract:
            errs.append(f"{cid}: element span {e.get('span')!r} is not a verbatim part of the contract")
        for ident in e.get("atoms", []):
            if ident.startswith("ru.aggregate"):
                continue
            if not onto.knows(ident):
                errs.append(f"{cid}: `{ident}` is not in the ontology")
        for r in e.get("concepts", []):
            if r == cid:
                errs.append(f"{cid}: references itself")
            elif r not in accepted and r not in plan_ids:
                errs.append(f"{cid}: references `{r}`, neither accepted nor in this plan")
        if not _ws(e.get("justification")):
            errs.append(f"{cid}: element on {e.get('span')!r} has no justification")
    for r in c.get("residues", []):
        if not _ws(r.get("why")):
            errs.append(f"{cid}: a residue states no `why`")
    # literals
    for lit in c.literals():
        if not isinstance(lit.get("value"), (int, float)) or lit.get("unit") not in FACTORS or not _ws(lit.get("why")):
            errs.append(f"{cid}: a literal needs a numeric value, a unit in {sorted(FACTORS)} and a `why` (a geometric constant, or a figure the definition states)")
    # scenarios
    scs = {s.get("name"): s for s in c.get("scenarios", [])}
    for name, exp in CONCEPT_SCENARIOS.items():
        if name not in scs:
            errs.append(f"{cid}: scenario `{name}` missing")
        elif normalize_verdict(scs[name].get("expected")) != exp:
            errs.append(f"{cid}: scenario `{name}` expects {scs[name].get('expected')!r}, must be {exp!r}")
        else:
            scs[name]["expected"] = exp
    blind = scs.get("blind", {})
    if blind:
        masked = blind.get("masked")
        if not isinstance(masked, list) or not masked:
            errs.append(f"{cid}: the blind scenario's `masked` must be a non-empty list of atom ids")
        elif not (set(masked) & concept_atoms.get(cid, set())):
            errs.append(f"{cid}: the blind scenario masks {masked}, none of which the concept reads")
    # users
    for nid in c.used_by():
        n = nodes.get(nid)
        if n is None:
            errs.append(f"{cid}: `used_by` names `{nid}`, not a node of this plan")
        elif cid not in {d for e in n.get("elements", []) for d in e.get("derived", [])} | {x for o in n.get("operationalizations", []) for x in concepts_of(o)}:
            errs.append(f"{cid}: node `{nid}` does not claim it")
    # supersession
    old = c.get("supersedes")
    if old:
        if mode == "test":
            errs.append(f"{cid}: a test run adds concepts and supersedes none; record the defect of `{old}` instead")
        if old not in accepted:
            errs.append(f"{cid}: supersedes `{old}`, which is not an accepted concept")
        elif _ws(accepted[old].get("contract")) != contract:
            errs.append(f"{cid}: a supersession keeps the contract; a different contract is a new concept under a new name")
        ce = c.get("counterexample")
        if not isinstance(ce, dict) or normalize_verdict(ce.get("expected", "")) not in ("compliant", "violated") or not _ws(ce.get("narrative")):
            errs.append(f"{cid}: a supersession carries a `counterexample` scenario (narrative, expected compliant|violated) on which the old body contradicts the contract")
    # near-duplicates of the catalogue: same sorts and reads, no stated difference
    sorts = sorted((a.get("sort") or "") for a in c.args())
    reads = concept_atoms.get(cid, set())
    for oid, rec in accepted.items():
        if oid == old:
            continue
        if sorted(a.get("sort", "") for a in rec.get("args", [])) == sorts and set(rec.get("reads", [])) == reads and reads:
            if not _ws((c.get("differs_from") or {}).get("why")) or (c.get("differs_from") or {}).get("concept") != oid:
                errs.append(f"{cid}: same argument sorts and the same atoms as accepted `{oid}`; reuse it, or state `differs_from: {{concept, why}}`")
    return errs


def validate_concepts(plan: list[ConceptRecord], defs: list[dict], onto: Ontology, accepted: dict[str, dict],
                      nodes: list[Node], mode: str = "train") -> list[ConceptOutcome]:
    by_def = {d.get("id"): d for d in defs}
    nodes_by_id = {n.id: n for n in nodes}
    plan_ids = {c.id for c in plan}
    ids = [c.id for c in plan]
    dup = {i for i in ids if ids.count(i) > 1}
    concept_atoms = concept_atom_map(onto, accepted, plan)
    cycles = concept_refs_acyclic(plan, accepted)
    out = []
    for c in plan:
        errs = check_concept(c, by_def, onto, accepted, plan_ids, nodes_by_id, concept_atoms, mode)
        if c.id in dup:
            errs.append(f"{c.id}: proposed twice in this plan")
        errs += [f"concept cycle: {x}" for x in cycles if c.id in x]
        out.append(ConceptOutcome(c, RETURN if errs else ACCEPT, errs))
    return out
