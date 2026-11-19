"""Validate A: the deterministic checks over a blueprint, before any code is written."""
from __future__ import annotations
import re
from dataclasses import dataclass, field
from ..model import acquisition, nodeid
from ..model.blueprint import (Node, ConceptRecord, span_offsets, PLANNED_NARROWING_KINDS, ABSTRACTION, ROLES, SUBSTANTIVE, SCENARIOS, GAP_KINDS, SCOPE_GAP, AS_KINDS, DEFINITION, concepts_of,
                               RULE_SET_OPS, RULE_SCOPES, standard_scenarios, CASE_KINDS, CASE_SPAN_ROLES, EXCEPTION_KINDS,
                               stop_witness_names, purpose_witness_names, unless_case_checks,
                        normalize_verdict, CONCEPT_SCENARIOS, CONCEPT_KINDS, ARG_SORTS)
from ..model.units import FACTORS, stated_figures, to_core, unsupported_figures
from ..model import corpus
from ..model import definitions as definitions_mod
from ..model.corpus import Law
from ..model.mapping import MappingIndex
from ..model.ontology import AGGREGATE, Ontology
from .aggregates import NOT_CLASSES, road_user_classes
from ..model.reading import Reading, DECLARED_ID, FACT_TERMS, declared_items, fact_terms_defects, meaning_citations, same_meaning

ACCEPT, RETURN, FAIL = "accept", "return", "fail"
_STRIP = re.compile(r"[\s\.,;:()\[\]“”\"'‘’—–-]+")


def _bare(t: str) -> str:
    return _STRIP.sub("", re.sub(r"\[[A-Z]+-[^\]]+\]", "", t)).lower()


@dataclass
class Outcome:
    node: Node
    kind: str
    reasons: list[str] = field(default_factory=list)
    gaps: list[dict] = field(default_factory=list)
    proposals: list[dict] = field(default_factory=list)   # parameter proposals the harness enters in the reading when the node is accepted
    filed: list[dict] = field(default_factory=list)       # gaps the harness files for the record itself (`outside_duty_gaps`, `lifted_case_gaps`)
    notes: list[str] = field(default_factory=list)        # findings for the operator's review that return nothing


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


def check_accounting(node: Node, corpus_ids: set[str] | None = None) -> list[str]:
    errs = []
    spans = node.spans()
    carriers: dict[str, list[str]] = {sid: [] for sid in spans}
    for key in ("elements", "operationalizations", "assumptions", "intentions", "facts", "compositions", "rule_sets", "residues"):
        for item in node.get(key, []):
            sid = item.get("span")
            if sid not in spans:
                errs.append(f"{node.id}: {key} entry refers to unknown span {sid!r}")
            else:
                carriers[sid].append(key)
    for g in node.get("gaps", []):                  # a gap annotates a span its nearest atoms carry; it carries nothing
        sid = g.get("span")
        if sid not in spans:
            errs.append(f"{node.id}: gaps entry refers to unknown span {sid!r}")
        elif not {"elements", "operationalizations"} & set(carriers[sid]):
            errs.append(f"{node.id}: gap on span {sid}, which no element or operationalization carries: map the span to its nearest "
                        "atoms or concepts, and let the gap name what is missing")
    for sid, s in spans.items():
        role, n = s.get("role"), len(carriers[sid])
        if role == "reference":
            # a reference names one or several rules: one composition per rule named, or one residue; never
            # the node's own atoms, which would restate the named rule instead of composing it
            if n == 0 or (set(carriers[sid]) != {"compositions"} and carriers[sid] != ["residues"]):
                errs.append(f"{node.id}: reference span {sid} is carried by compositions (one per rule it names) or by one residue, never by "
                            f"{sorted(set(carriers[sid]) - {'compositions'}) or 'nothing'}: a reference to a rule composes that rule, "
                            "a reference that only borrows words is a `definition` reference")
            if corpus_ids and "residues" in carriers[sid]:
                named = [i for i in corpus.cited_law_ids(s.get("text", "")) if i in corpus_ids]
                if named:
                    errs.append(f"{node.id}: reference span {sid} names {named}, law(s) of this corpus, and is carried by a residue; "
                                "a reference to a law of the corpus is a composition (`as` exception, condition, compliance or unless), or a "
                                "`definition` reference where it only borrows that law's words")
        elif role in SUBSTANTIVE and n != 1:
            errs.append(f"{node.id}: span {sid} ({role}) is carried by {n} entries, must be exactly one"
                        + (" — words that need two carriers need another cut of the text: a repair withdraws the record as a plan defect "
                           "(`kind: \"plan\"`)" if n > 1 else ""))
        elif role == "sibling" and n != 0:
            errs.append(f"{node.id}: sibling span {sid} belongs to another node of the same law and carries nothing here")
        if role == "definitional" and n == 0 and not re.search(r"\[DEF-", s.get("text", "")):
            errs.append(f"{node.id}: definitional span {sid} cites no definition and carries nothing")
    return errs


#: The phrases by which a law's words require compliance with, or apply or except, the law they then
#: name in brackets: an unambiguous normative reference, as opposed to words that only mention or
#: borrow from another law ("as described in", "pursuant to the criteria set forth in").
NORMATIVE_PHRASE = r"(?:(?:except\s+)?as\s+(?:otherwise\s+)?provided\s+in|in\s+compliance\s+with|as\s+required\s+(?:by|pursuant\s+to))"
#: The words of a citation, and nothing else: unit words, designators (a number with its letters and
#: dotted parts, or a letter or number in parentheses, then any further levels in parentheses written
#: against it: "2(a)", "(2)(a)", "484B.287(1)(b)"), a code's upper-case abbreviation, "of this section"
#: and the list words inside one designation ("(1) or (2)", "(a) to (f)").
_CITATION_WORD = (r"(?:(?:sub)?sections?|(?:sub)?paragraphs?|chapters?|titles?|(?-i:[A-Z]{2,6})|of|this|and|or|to"
                  r"|(?:[0-9]+[A-Za-z]*(?:\.[0-9]+[A-Za-z]*)*|\([A-Za-z0-9]+\))(?:\([A-Za-z0-9]+\))*)")
_CITATION = rf"(?:{_CITATION_WORD}\s+)*"
#: What the rule a compliance phrase points at may be called before its citation.
_OBJECT = r"(?:the\s+(?:manner\s+prescribed|provisions|requirements)\s+(?:in|of)\s+)?"
_BRACKET = r"\[[^\]]*\]"
#: A further citation of the same list: a comma, "and", "or" or "and/or", then citation words.
_LIST_JOIN = rf"(?:\s*,\s*(?:(?:and/or|and|or)\s+)?|\s+(?:and/or|and|or)\s+){_CITATION}{_BRACKET}"
NORMATIVE_REFERENCE = re.compile(rf"\b{NORMATIVE_PHRASE}\s+{_OBJECT}{_CITATION}{_BRACKET}(?:{_LIST_JOIN})*", re.IGNORECASE)


def normative_references(text: str, own: str) -> list[tuple[int, int, list[str]]]:
    """The unambiguous normative references of a law's posted text: a normative phrase, then only
    citation words and a bracket naming a law, then further citations joined only by a list
    connector. Any other word (a new clause, a subject, a borrowing phrase, a noun with its own
    qualifier) ends the reference, or leaves no reference when it comes before the first bracket.
    Each as (start, end, the law ids its brackets name other than the law's own); a phrase whose
    brackets name no other law is left out."""
    out = []
    for m in NORMATIVE_REFERENCE.finditer(text):
        named = [i for i in corpus.cited_law_ids(m.group(0)) if i != own]
        if named:
            out.append((m.start(), m.end(), named))
    return out


def _carried_targets(node: Node, sids: list[str], known: dict[str, Node]) -> set[str]:
    """The laws whose nodes `node`'s execution compositions on spans `sids` compose: a target the
    validator knows counts unless it is fenced; a rule it does not know counts for the law its id
    names, since that composition's own defect is the unknown target (`check_compositions`), which
    the loop holds on that law when the law waits for the operator and returns otherwise."""
    out = set()
    for c in node.dependencies():
        r = c.get("rule")
        if c.get("span") not in sids or not isinstance(r, str) or not r:
            continue
        if r not in known:
            out.add(nodeid.law_of(r)[0])
        elif not known[r].get("fenced"):
            out.add(known[r].law)
    return out


def check_reference_positions(node: Node, law: Law, law_ids: set[str] | None = None,
                              known: dict[str, Node] | None = None, law_nodes: list[Node] | None = None) -> list[str]:
    """Read from the law's text, not from the plan's roles: every span of the record that overlaps an
    unambiguous normative reference is a `reference` span (or a `sibling` span), and it is carried by
    execution compositions or a residue, never by a `definition` reference. Each law the reference
    names that is a law of the corpus (`law_ids`) is the target of at least one execution composition
    of a usable node (known, not fenced): on this record's reference spans there, or, where this
    record marks the whole position `sibling`, on the spans of the law's other nodes (`law_nodes`)
    that overlap it. How the targets combine is the plan's; none is dropped. A law outside the corpus
    follows the residue rule."""
    errs = []
    known = known or {}
    offs = span_offsets(node.get("segmentation", []), law.text)
    spans = node.spans()
    defined = {c.get("span") for c in node.definition_references()}
    for a, z, named in normative_references(law.text, law.id):
        words = " ".join(law.text[a:z].split())
        overlap = [sid for sid, (i, j) in offs.items() if i < z and a < j]
        mine = [sid for sid in overlap if spans.get(sid, {}).get("role") != "sibling"]
        in_corpus = [lid for lid in named if lid in (law_ids or set())]
        if mine and all(spans.get(sid, {}).get("role") == "reference" for sid in mine) and node.dependencies():
            targets = _carried_targets(node, mine, known)
            composed = any(c.get("span") in mine for c in node.dependencies())
            for lid in in_corpus if composed else []:      # none composed: the carrier rules already refuse it
                if lid not in targets:
                    errs.append(f"{node.id}: the normative reference “{words[:120]}” names {lid}, and no composition of a usable node on its "
                                f"span {'/'.join(mine)} composes a node of {lid}: each law the reference names is composed (how they "
                                "combine is stated by the compositions' kinds), even one not yet accepted")
        elif overlap and not mine and in_corpus:
            carriers: dict[str, set[str]] = {}
            for m in law_nodes or []:
                if m.id == node.id:
                    continue
                m_offs, m_spans = span_offsets(m.get("segmentation", []), law.text), m.spans()
                sids = [sid for sid, (i, j) in m_offs.items() if i < z and a < j and m_spans.get(sid, {}).get("role") != "sibling"]
                if sids:
                    carriers[m.id] = _carried_targets(m, sids, known)
            missing = [lid for lid in in_corpus if lid not in set().union(*carriers.values())] if carriers else []
            if missing:                                   # no carrier at all: `check_decomposition` refuses the sibling span
                errs.append(f"{node.id}: marks the normative reference “{words[:120]}” `sibling`, but the nodes that segment it "
                            f"({', '.join(sorted(carriers))}) compose no usable node of {missing}: a sibling carries a reference only "
                            "by composing a usable node of each law it names")
        for sid in mine:
            role = spans.get(sid, {}).get("role")
            if role != "reference":
                errs.append(f"{node.id}: span {sid} ({role}) covers the normative reference “{words[:120]}” to {named}; these words require "
                            "the named rule to be complied with, to apply or not to apply: cut them into a `reference` span carried by "
                            "compositions of the named law's nodes (or by a residue where that law is outside the corpus)")
            elif sid in defined:
                errs.append(f"{node.id}: reference span {sid} “{words[:120]}” cannot be carried by a `definition` reference: its words "
                            f"require the rule of {named} to be complied with, to apply or not to apply, which an execution composition "
                            "states (`exception`, `condition`, `compliance` or `unless`)")
    return errs


def outside_duty_gaps(node: Node, law: Law, law_ids: set[str] | None = None) -> list[dict]:
    """An obligation node whose every obligation span is followed at once by a `reference` span
    carried by a residue, over a normative reference whose named laws all lie outside the corpus
    (`law_ids`), has no duty left to code once those references are set aside: the duty is what
    those laws require. That is a question of the corpus's scope, not a defect of the plan: the
    harness files one `scope` gap on each such obligation span, the record is not coded, and its law
    is blocked on them while its other nodes are coded and kept."""
    order = [s for s in node.get("segmentation", []) if isinstance(s, dict)]
    duties = [i for i, s in enumerate(order) if s.get("role") == "obligation"]
    if not duties or law_ids is None:
        return []
    offs = span_offsets(order, law.text)
    residues = {str(r.get("span")) for r in node.get("residues", []) if isinstance(r, dict)}
    outside: dict[str, list[str]] = {}
    for a, z, named in normative_references(law.text, law.id):
        if named and not any(lid in law_ids for lid in named):
            for sid, (i, j) in offs.items():
                if i < z and a < j:
                    outside.setdefault(sid, []).extend(n for n in named if n not in outside.get(sid, []))
    follows = []
    for i in duties:
        nxt = order[i + 1] if i + 1 < len(order) else {}
        sid, ref = str(order[i].get("id")), str(nxt.get("id"))
        if (nxt.get("role") != "reference" or ref not in residues or ref not in outside or sid not in offs or ref not in offs
                or law.text[offs[sid][1]:offs[ref][0]].strip()):
            return []
        follows.append((sid, ref))
    return [{"span": sid, "kind": SCOPE_GAP, "nearest": [],
             "proposal": f"the duty of span {sid}, qualified by span {ref}, is to act as {outside[ref]} require, and no law it names is "
                         "in the corpus: the words leave no duty of their own to code. A scope decision: bring the named law into the "
                         "corpus (the gap is retired by that revision), or take the duty out of scope (rejected, with where the "
                         "decision lives)"} for sid, ref in follows]


#: The words between which a defined term stands as a noun phrase of its own, as opposed to a part of
#: a compound that names something narrower ("an official vehicle", "a traffic incident management
#: vehicle"): before it a determiner, a quantifier or a list connector; after it a connector, a
#: preposition, a relative word or a verb that a noun phrase ends before.
_NOUN_PHRASE_START = {"a", "an", "the", "any", "every", "each", "all", "other", "another", "such", "no", "or", "and", "nor"}
_NOUN_PHRASE_END = {"or", "and", "nor", "other", "than", "which", "that", "who", "whose", "of", "in", "on", "at", "to", "from", "with",
                    "by", "for", "upon", "within", "when", "while", "if", "unless", "except", "is", "are", "shall", "may", "must",
                    "being", "described", "operated", "driven", "used"}


def standalone_terms(words: str, terms: list[str]) -> set[str]:
    """The defined terms the words use as noun phrases of their own: the term's tokens in order
    (longest term first, its last word in singular or plural form, as the definitions table matches
    them), at the start of a clause or after a word of `_NOUN_PHRASE_START`, and at the end of the
    clause or before a word of `_NOUN_PHRASE_END`."""
    by_len = sorted({tuple(t.split()) for t in terms}, key=lambda t: -len(t))
    out: set[str] = set()
    for clause in re.split(r"[.,;:!?()\[\]\n“”\"]", definitions_mod._INLINE.sub(" ", words)):
        toks, i = definitions_mod.tokens(clause), 0
        while i < len(toks):
            hit = next((t for t in by_len if i + len(t) <= len(toks) and list(t[:-1]) == toks[i:i + len(t) - 1]
                        and definitions_mod._same(t[-1], toks[i + len(t) - 1])), None)
            j = i + len(hit) if hit else i
            if hit and (i == 0 or toks[i - 1] in _NOUN_PHRASE_START) and (j == len(toks) or toks[j] in _NOUN_PHRASE_END):
                out.add(" ".join(hit))
            i = j if hit else i + 1
    return out


def check_admitted_aggregates(node: Node, rows: list[dict] | None, reading: Reading) -> list[str]:
    """A span whose words use, as a noun phrase of its own (`standalone_terms`), a defined term that
    the definitions table resolves for the node's law (`rows`) to a definition whose aggregate the
    reading admits claims that aggregate, `ru.aggregate=<id>`, on its element: an element that carries
    such a span with a road-user class atom and without that aggregate has replaced the admitted
    aggregate by a class atom."""
    admitted = {(a.get("definition"), a.get("term")): a["id"] for a in getattr(reading, "data", {}).get("aggregates", [])
                if isinstance(a, dict) and a.get("id")}
    resolved = {r["term"]: admitted[(r.get("definition"), r["term"])] for r in rows or []
                if r.get("status") == "resolved" and isinstance(r.get("term"), str) and (r.get("definition"), r["term"]) in admitted}
    if not resolved:
        return []
    spans, errs = node.spans(), []
    for e in node.get("elements", []):
        if not isinstance(e, dict) or not isinstance(e.get("atoms"), list):
            continue
        atoms = [a for a in e["atoms"] if isinstance(a, str)]
        classes = [a for a in atoms if a.startswith("ru.") and a.split("=", 1)[0] not in NOT_CLASSES]
        words = (spans.get(e.get("span")) or {}).get("text", "")
        if not classes or not isinstance(words, str):
            continue
        for term in sorted(standalone_terms(words, sorted(resolved))):
            aid = resolved[term]
            if f"{AGGREGATE}={aid}" not in atoms:
                errs.append(f"{node.id}: span {e.get('span')} “{' '.join(words.split())[:120]}” uses the defined term “{term}”, which the "
                            f"definitions table resolves to the admitted aggregate `{aid}`, and its element claims {classes} instead: "
                            f"claim `{AGGREGATE}={aid}` in the span's element and in `class_elements`; an admitted aggregate is never "
                            "replaced by a class atom")
    return errs


def fence_words(ev: dict) -> str:
    """Why a fenced version may not be used, in the words a returned record carries."""
    reason = (ev or {}).get("reason")
    if reason == "dependency_defect":
        return "a version an adjudicated counterexample found defective"
    if reason == "gate":
        return f"a version today's gates reject ({str((ev or {}).get('evidence', ''))[:160]})"
    if reason == "context":
        return "a version whose dependency context changed and that no longer meets its obligations"
    if reason == "dependency":
        return f"a version that calls the fenced `{(ev or {}).get('provider')}`"
    return "a fenced version"


def check_closed_set(node: Node, onto: Ontology, concept_ids: set[str] | None = None,
                     fenced: dict[str, dict] | None = None) -> tuple[list[str], list[dict]]:
    """Unknown ids: a gap when the node proposes one for that span, a rejection otherwise. A concept
    id is known when it is accepted (this run's or the base run's) or proposed in this plan."""
    errs, gaps = [], []
    concept_ids = concept_ids or set()
    proposed = {g.get("span") for g in node.gaps()}
    for e in node.get("elements", []):
        for ident in list(e.get("atoms", [])) + list(e.get("derived", [])):
            if ident.startswith("ru.aggregate"):
                continue          # its id is checked against the reading with every other claim
            if not onto.knows(ident) and ident not in concept_ids:
                if e.get("span") in proposed:
                    errs.append(f"{node.id}: span {e.get('span')} carries a gap and maps to `{ident}`, which does not exist: map the span "
                                "to its nearest atoms or concepts and let the gap's proposal name what is missing")
                elif nodeid.is_concept_id(ident):
                    errs.append(f"{node.id}: concept `{ident}` is neither accepted nor proposed in this plan (a concept record for span {e.get('span')})")
                else:
                    errs.append(f"{node.id}: `{ident}` is not in the ontology and no gap is proposed for span {e.get('span')}")
    for b in [node.get("subject") or {}] + list(node.get("binders", [])):     # a binder's class is claimed like an element
        for ident in b.get("class_elements", []):
            if not ident.startswith("ru.aggregate") and not onto.knows(ident) and ident not in concept_ids:
                errs.append(f"{node.id}: the class of binder `{b.get('binder', b.get('name'))}` names `{ident}`, which is not in the ontology")
    claims = node.claimed_atoms()
    fenced = fenced or {}
    errs += [f"{node.id}: concept `{c}` is {fence_words(fenced[c])}: supersede it or map the words around it"
             for c in sorted(claims & set(fenced))]
    for o in node.get("operationalizations", []):
        cs = concepts_of(o)
        if not cs:
            errs.append(f"{node.id}: operationalization on span {o.get('span')} names no concept")
        for c in cs:
            if c not in onto.primitive_ids and c not in onto.atom_ids and c not in concept_ids:
                errs.append(f"{node.id}: operationalization concept `{c}` is neither a concept, a primitive nor an atom")
    constructors = formula_constructors()
    for g in node.gaps():
        if g.get("kind") not in GAP_KINDS:
            errs.append(f"{node.id}: gap kind {g.get('kind')!r} not in {sorted(GAP_KINDS)}")
        before = len(errs)                      # a gap with a defect below is not filed; every defect is named
        if not g.get("proposal") or not g.get("nearest"):
            errs.append(f"{node.id}: gap for span {g.get('span')} lacks a proposal or its nearest atoms")
        proposal = str(g.get("proposal") or "")
        named = re.match(r"\s*\|?\s*`((?:ru|kin|st|dev|sig|env|rel|prim)\.[a-z_]+)`", proposal)
        if g.get("kind") == "atom" and named and onto.knows(named.group(1)):
            errs.append(f"{node.id}: the gap on span {g.get('span')} proposes `{named.group(1)}`, which the ontology already has: map the span to it")
        op = re.match(r"\s*`(?:Formula\.|Term\.|Measure\.)?\.?(\w+)", proposal)
        if g.get("kind") == "operator" and op and op.group(1) in constructors:
            errs.append(f"{node.id}: the gap on span {g.get('span')} proposes `{op.group(1)}`, which the formula language already has: "
                        "write the span with it")
        if len(errs) == before:
            gaps.append(g)
    return errs, gaps


def formula_constructors() -> set[str]:
    """The constructor names of the formula language (`Formula`, `Term`, `Measure`), read from Core:
    what an `operator` gap may not propose again."""
    from ..lean import surface
    text = surface.formula_language()
    return {c for line in text.splitlines() if line.lstrip().startswith("|") for c in re.findall(r"\|\s*(\w+)", line)}


_PARAM = re.compile(r"^p\.[a-z][a-z0-9_]*$")


def proposal_conflicts_of(nodes: list[Node]) -> dict[str, list[str]]:
    """One parameter, one value, one meaning: a later node of the plan that proposes a name an
    earlier node proposed with another value or unit, or with the same value and unit under another
    convention (compared with whitespace normalised), is returned, naming both. The `source` is where
    the figure comes from, not what the parameter means: it is not compared."""
    seen: dict[str, tuple] = {}
    out: dict[str, list[str]] = {}
    for n in nodes:
        for pr in n.get("param_proposals", []):
            if not isinstance(pr, dict) or not pr.get("name"):
                continue
            key = (pr.get("value"), pr.get("unit"))
            convention = " ".join(str(pr.get("convention", "")).split())
            if pr["name"] not in seen:
                seen[pr["name"]] = (key, convention, n.id)
                continue
            (v, u), c, nid = seen[pr["name"]]
            if (v, u) != key:
                out.setdefault(n.id, []).append(f"{n.id}: proposes `{pr['name']}` = {pr.get('value')} {pr.get('unit')}, and node {nid} proposed it as {v} {u}; "
                                                "one parameter has one value — propose it with the same value, unit and convention, or use another name for another bound")
            elif c != convention:
                out.setdefault(n.id, []).append(f"{n.id}: proposes `{pr['name']}` with the convention {convention!r}, and node {nid} proposed it with the convention {c!r}; "
                                                "one parameter has one meaning — propose the same convention, or use another name for a different meaning")
    return out


def check_standards(node: Node, reading: Reading, foreign_params: set[str] | frozenset = frozenset()) -> tuple[list[str], list[dict]]:
    """Errors, and the parameter proposals: a parameter the reading lacks is proposed by the node
    (`param_proposals`: name, unit, value, convention, source) and the harness enters it in the
    reading as a proposal the operator reviews; a parameter neither the reading has nor the node
    proposes returns the node. A proposed value may not be a figure the law states. A value the
    catalogue holds is named as it is, unless a node of this law proposed it, the operator has not
    reviewed it, and no node of another law (`foreign_params`) names the parameter, and the proposal
    keeps its convention: a proposal of a catalogued name under another convention (whitespace
    aside) is refused whatever its value and unit, reviewed or not, since a name means one thing. A
    parameter an
    acquisition profile names (the step bound of `heading_since`) is the operator's: no node proposes
    it or a value for it."""
    errs, proposals = [], []
    spans = node.spans()
    op_spans = {o.get("span") for o in node.get("operationalizations", [])}
    # a standard an accepted rule already bounds is carried by composing that rule
    composed = {c.get("span") for c in node.compositions() if c.get("as") == "compliance"}
    for sid, s in spans.items():
        if s.get("role") == "standard" and sid not in op_spans and sid not in composed:
            errs.append(f"{node.id}: standard span {sid} has no operationalization")
    for o in node.get("operationalizations", []):
        if not o.get("params"):
            errs.append(f"{node.id}: operationalization on span {o.get('span')} names no parameter — a standard is a bound the reading sets; "
                        "a structural test with no magnitude approximates it (name the parameter even if the reading lacks it, or file a gap)")
    for o in node.get("operationalizations", []):
        sid = o.get("span")
        stated = stated_figures(spans.get(sid, {}).get("text", ""))
        declared = set()
        for lit in node.literals():
            if lit.get("span") == sid:
                try:
                    declared.add(to_core(lit.get("value"), lit.get("unit", "")))
                except (KeyError, ValueError, TypeError):
                    pass
        for p in o.get("params", []):
            rp = reading.params.get(p)
            try:
                value = to_core(rp["value"], rp["unit"]) if rp else None
            except (KeyError, ValueError, TypeError):
                value = None
            words = next((f.words for f in stated if (f.core, f.value) == value), None)
            if words:
                also = " as well as the declared literal" if value in declared else ""
                errs.append(f"{node.id}: span {sid} states `{words}`, and the operationalization bounds it with `{p}`{also}, "
                            f"whose reading value is the same figure; a figure the law states is a literal on its span, never a "
                            f"reading parameter (declare it in `literals` and drop `{p}`, or name a parameter for what the text does not state)")
    stated_all = {(f.core, f.value) for s in spans.values() for f in stated_figures(s.get("text", ""))}
    for sid, sp in spans.items():
        for u in unsupported_figures(sp.get("text", "")):
            errs.append(f"{node.id}: span {sid} states `{u.words}`, which the harness cannot read as a figure; the operator extends the "
                        "figure parser (`harness/model/units.py`) before this law can be checked")
    proposed = {pr.get("name"): pr for pr in node.get("param_proposals", []) if isinstance(pr, dict)}
    reserved = acquisition.reserved_parameters()
    for name, pr in proposed.items():
        if name in reserved:
            errs.append(f"{node.id}: `{name}` is the `heading_since` step parameter of acquisition profile(s) "
                        f"{', '.join(reserved[name])}: the operator enters and reviews its value; no plan or repair proposes it "
                        "or a value for it — name it as it is")
            continue
        if not name or not _PARAM.match(str(name)):
            errs.append(f"{node.id}: proposed parameter {name!r} is not of the form `p.<snake_case>`")
        if pr.get("unit") not in FACTORS:
            errs.append(f"{node.id}: proposed parameter `{name}` has unit {pr.get('unit')!r}; use one of {sorted(FACTORS)}")
        if not isinstance(pr.get("value"), (int, float)):
            errs.append(f"{node.id}: proposed parameter `{name}` needs a numeric `value`, a provisional figure from the named convention")
        if not str(pr.get("convention", "")).strip() or not str(pr.get("source", "")).strip():
            errs.append(f"{node.id}: proposed parameter `{name}` needs a `convention` (what the value bounds and how) and a `source` (where such figures come from)")
        if name in reading.params:
            have = reading.params[name]
            revisable = Reading.own_proposal(have, node.law) and name not in foreign_params
            if _ws(have.get("convention")) != _ws(pr.get("convention")):
                errs.append(f"{node.id}: proposed parameter `{name}` is already in the catalogue as {have.get('value')} {have.get('unit')} with the convention "
                            f"{_ws(have.get('convention'))!r}, and the node proposes it with the convention {_ws(pr.get('convention'))!r}; one parameter "
                            "has one meaning — name the catalogued parameter as it is, without proposing it, or use another name for a different meaning")
            elif (have.get("value"), have.get("unit")) != (pr.get("value"), pr.get("unit")) and not revisable:
                errs.append(f"{node.id}: proposed parameter `{name}` is already in the catalogue as {have.get('value')} {have.get('unit')}; name it, do not propose another value")
        if name not in node.params():
            errs.append(f"{node.id}: proposed parameter `{name}` is bound by no operationalization or `params` entry of the node")
        try:
            if pr.get("unit") in FACTORS and isinstance(pr.get("value"), (int, float)) and to_core(pr["value"], pr["unit"]) in stated_all:
                errs.append(f"{node.id}: proposed parameter `{name}` equals a figure the law states; a stated figure is a literal on its span, never a parameter")
        except (KeyError, ValueError, TypeError):
            pass
    for p in node.params():
        if not reading.has(p):
            if p in reserved:
                if p not in proposed:
                    errs.append(f"{node.id}: `{p}` is the `heading_since` step parameter of acquisition profile(s) "
                                f"{', '.join(reserved[p])} and the reading lacks it: the operator enters its reviewed value")
            elif p in proposed:
                proposals.append(proposed[p])
            else:
                errs.append(f"{node.id}: parameter `{p}` is in no catalogue and the node proposes none: add it to `param_proposals` "
                            "(name, unit, value, convention, source) or name a catalogued parameter")
    for ident in sorted(node.claimed_atoms()):
        if ident == "ru.aggregate":
            errs.append(f"{node.id}: a bare `ru.aggregate` is claimed: claim `ru.aggregate=<aggregate id>` wherever the record "
                        "names it (an element, an operationalization's concepts, the occasion), with the id the definitions table admits")
        if ident.startswith("ru.aggregate="):
            aid = ident.split("=", 1)[1]
            if "::" not in aid:
                errs.append(f"{node.id}: `{ident}` names no aggregate id: claim `ru.aggregate=<definition id>::<term>` as the definitions "
                            "table admits it, or a law-local `<law id>:<span>::<term>`")
            elif not aid.startswith("DEF-") and not aid.startswith(node.law + ":"):
                errs.append(f"{node.id}: the law-local aggregate `{aid}` belongs to another law")
            elif aid not in reading.aggregate_ids() and aid not in getattr(reading, "pending_ids", set()) \
                    and not (getattr(reading, "pending_aggregates", False) and aid.startswith("DEF-")):
                errs.append(f"{node.id}: aggregate `{aid}` is not admitted: claim an id the definitions table admits, or write the "
                            "law-local aggregate in `aggregates.jsonl`")
    return errs, proposals


from ..model.ontology import ANCHORS


def check_anchoring(node: Node) -> list[str]:
    """A node that reads a road feature or a device must be able to tie it to a binder: it claims an
    anchoring atom. Without one, every region the rule quantifies over is any region of the scene.
    A structure atom read on a road user alone (Core declares no region or device argument for it)
    names no feature to tie."""
    from ..lean import surface
    claimed = {c.split("=")[0] for c in node.claimed_atoms()}
    features = sorted(c for c in claimed if (c.startswith("st.") or c.startswith("dev."))
                      and {"region", "device"} & set(surface.atom_sorts(c.replace(".", "_"))))
    if features and not (claimed & ANCHORS):
        return [f"{node.id}: the record claims {features[:4]} but no anchoring atom ({sorted(ANCHORS)}) — a record-level check: the record must "
                "claim an atom that can tie a feature to a road user (`rel.occupies`, `st.region_geometry`, …) on the span that places the "
                "subject; whether each quantified feature is so tied is checked on the formula at the gate"]
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
    elements' atoms, what its claimed primitives read, and, transitively, what the concepts it
    references read."""
    from ..lean import surface
    prim_reads = surface.primitive_reads()
    out: dict[str, set[str]] = {cid: set(rec.get("reads", [])) for cid, rec in accepted.items()}
    planned = {c.id: c for c in plan}
    def go(cid: str, seen: tuple[str, ...]) -> set[str]:
        if cid in out:
            return out[cid]
        c = planned.get(cid)
        if c is None or cid in seen:
            return set()
        acc = {a.split("=")[0] for a in c.claimed_atoms() if a.split("=")[0] in onto.atom_ids}
        for r in c.refs() | {a for a in c.claimed_atoms() if a in onto.primitive_ids}:
            for lean_name in prim_reads.get(r.replace(".", "_"), []):
                aid = surface.atom_id_of(lean_name, onto.atom_ids)
                if aid:
                    acc.add(aid)
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
        elif lit.get("value") == 0:
            errs.append(f"{node.id}: literal on span {sid} is zero; a zero is never declared — it may appear in any formula and the gate never collects one")
        elif lit.get("unit") not in FACTORS:
            errs.append(f"{node.id}: literal on span {sid} has unit {lit.get('unit')!r}; use one of {sorted(FACTORS)}")
    return errs


def check_scenarios(node: Node, onto: Ontology, concept_atoms: dict[str, set[str]] | None = None) -> list[str]:
    errs = []
    scs = {s.get("name"): s for s in node.get("scenarios", [])}
    for name, exp in standard_scenarios(node).items():
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
    for name, s in scs.items():
        if s.get("boundary") is None:
            # `Scenario.run` admits an unknown witness only for atoms its manifest masks or, on a
            # history-boundary witness, a window truncated at the trace start; only `blind`
            # carries masked atoms into its witness, so any other unknown has no admitted reason
            if name not in SCENARIOS and normalize_verdict(s.get("expected")) == "unknown":
                errs.append(f"{node.id}: scenario `{name}` expects unknown, but declares no history boundary and is not `blind`: its "
                            "witness masks no atom, and the gate admits an unknown witness only for an atom its manifest masks or, "
                            "with a declared `boundary`, a window truncated at the trace start — an undeclared assumption or "
                            "intention, a missing parameter or an undefined concept leaves no witness that can pass")
            continue
        if name in SCENARIOS:
            errs.append(f"{node.id}: scenario `{name}` declares a history boundary; only a scenario beside the four standard ones may")
            continue
        if normalize_verdict(s.get("expected")) != "unknown":
            errs.append(f"{node.id}: scenario `{name}` declares a history boundary and expects {s.get('expected')!r}; a history-boundary scenario expects unknown")
        if not str(s.get("boundary")).strip():
            errs.append(f"{node.id}: scenario `{name}` declares an empty history boundary; it names the history its trace lacks")
    return errs


OCCASIONS = {"at_recognition", "some_moment", "throughout"}
OCCASION_ROLES = {"trigger", "condition", "exception"}
#: Where an act's stretch begins: a window of fixed length behind its recognition (`window`, the
#: default when a record names none), or the act's observed onset (`event`).
BOUNDARIES = {"window", "event"}
#: What a concept that declares an act states in its contract, each in words of the contract.
ACT_WORDS = {"onset": "observed beginning", "recognition": "point of recognition", "extent": "extent (how long it holds, or what ends it)",
             "history": "history boundary for conduct before the act"}


def acts_over_time(node: Node, acts: dict[str, dict] | None = None) -> list[str]:
    """The concepts the obligation span maps to that recognize an act over a stretch of time: those
    whose record declares it (`act`, in `acts` by concept id). Nothing else makes a concept an act:
    neither a parameter in a unit of time, which may bound a sampling or a recognition, nor the
    temporal operators of its body. Such an act is recognized only after it has been under way."""
    spans = node.spans()
    out = []
    for e in node.get("elements", []):
        if spans.get(e.get("span"), {}).get("role") != "obligation":
            continue
        out += [c for c in e.get("derived", []) if c in (acts or {})]
    return out


#: Kinematic atoms that say nothing of motion: the clock and the body's size.
STATIC_KIN = {"kin.time", "kin.extent"}


def reads_motion(ids: list[str], onto: Ontology, concept_atoms: dict[str, set[str]]) -> bool:
    """Whether a set of claimed ids reads the motion of a road user: a kinematic atom other than the
    clock or the body's size, a primitive (each integrates motion), or a concept that reads one."""
    def motion(a: str) -> bool:
        return a.startswith("kin.") and a not in STATIC_KIN
    for i in ids:
        if motion(i) or i in onto.primitive_ids:
            return True
        if any(motion(a) for a in concept_atoms.get(i, set())):
            return True
    return False


def occasion_requirements(acts: list[str], scoped: list[str]) -> str:
    """Everything the occasion of an act observed over time requires, stated at once, so that a
    record returned for one part of it learns every other part in the same message."""
    return (f"declare `occasion` {{act, boundary, window | onset and recognition, under_way, spans}}: `act` the obligation's concept "
            f"whose record declares an act ({', '.join(f'`{a}`' for a in acts) or 'none found'}), or the list of them where the obligation "
            "names alternative acts; `boundary` the boundary those records declare: `window`, with `window` the act's window "
            "parameter, which the node names, or `event`, for an act no window of fixed length bounds, with `onset` an element "
            "{words, atoms, derived, justification} mapping what marks the act's observed beginning, `recognition` the words saying "
            "where the act is recognized, no `window`, and, where the formula language cannot write that boundary, `gap` the span "
            "of the record's `operator` gap; `spans` saying, for each trigger, condition and exception span "
            f"the node maps ({', '.join(f'`{k}`' for k in scoped) or 'none'}), whether it is read `at_recognition` (where the act is "
            "recognized), `some_moment` (at some moment while the act is under way) or `throughout` (at every moment while it is under "
            "way). Where a span is read `some_moment` or `throughout`, also: `under_way`, an element {words, atoms, derived, "
            "justification} whose atoms or concepts read the road user's motion (a kinematic atom other than the clock or the body's "
            "size, a primitive, or a concept that reads one), never a place or a region alone; and, for each such span, the scenarios "
            "`occasion_<span>`, in which it holds for part of the act only, and `occasion_<span>_outside`, in which it holds only "
            "before the act began (read `some_moment`) or throughout the act but not before it (read `throughout`), the two expecting "
            "different verdicts")


def check_occasion(node: Node, acts_declared: dict[str, dict], onto: Ontology | None = None,
                   concept_ids: set[str] | None = None, concept_atoms: dict[str, set[str]] | None = None) -> list[str]:
    """A node whose obligation names an act (a concept whose record declares `act`; `acts_declared`
    maps each such concept id to its declaration), and whose rule reads trigger,
    condition or exception spans, declares when each of those spans is read relative to the act:
    where the act is recognized, at some moment while it is under way, or throughout it. Where the
    obligation names alternative acts, `act` lists them and they share the boundary, `under_way` and
    the scenarios. The boundary is the one the acts' records declare: a window parameter the node
    names (`window`), or the act's observed onset (`event`), an element claimed and coded like any
    other, with the words saying where the act is recognized; a window is never required of an act
    whose record declares an event boundary. Where the formula language cannot write an event boundary,
    `gap` names the span of the record's `operator` gap, which the coder confirms. A span read
    while the act is under way needs `under_way`, an element mapping the words that say the act is
    in progress to atoms or concepts that read the road user's motion (where the act is or is not
    under way is what the reading turns on, so it is claimed and coded like any element), and two
    scenarios that pin the reading: `occasion_<span>`, in which the span holds for part of the act
    only, and `occasion_<span>_outside`, in which it holds only before the act began (read
    `some_moment`) or throughout the act but not before it (read `throughout`). The two must expect
    different verdicts: a rule that cannot tell the act from the stretch before it decides them
    alike. The first message of a returned record states all of these requirements
    (`occasion_requirements`); the messages after it name each one the record misses."""
    spans = node.spans()
    acts = acts_over_time(node, acts_declared)
    scoped = sorted({e.get("span") for e in node.get("elements", []) if spans.get(e.get("span"), {}).get("role") in OCCASION_ROLES})
    occ = node.get("occasion")
    if occ is None:
        if acts and scoped:
            return [f"{node.id}: the obligation names `{acts[0]}`, an act observed over time, and the rule reads span(s) {scoped}: "
                    + occasion_requirements(acts, scoped)]
        return []
    if not isinstance(occ, dict):
        return [f"{node.id}: `occasion` must be an object; " + occasion_requirements(acts, scoped)]
    errs = []
    act = occ.get("act")
    named = act if isinstance(act, list) else [act]       # alternatives the obligation names share one occasion
    if not named or any(a not in acts for a in named):
        errs.append(f"{node.id}: occasion `act` must be the concept of the obligation span whose record declares an act (`act`), "
                    f"or the list of them when the obligation names alternative acts ({acts or 'none here'}); got {act!r}")
    boundary = node.occasion_boundary()
    declared = {a: (acts_declared or {}).get(a, {}).get("boundary") for a in named if a in acts}
    other = {a: b for a, b in declared.items() if b != boundary}
    if other:
        errs.append(f"{node.id}: occasion `boundary` is {boundary!r}, but the record of {sorted(other)} declares "
                    + ", ".join(f"`{a}`: {b!r}" for a, b in sorted(other.items()))
                    + "; the occasion states the boundary its acts declare, and alternative acts share one")
    if boundary == "window":
        if occ.get("window") not in node.params():
            errs.append(f"{node.id}: occasion `window` must be a parameter the node names (the act's window), got {occ.get('window')!r}")
        errs += [f"{node.id}: occasion `{k}` belongs to `boundary: \"event\"`; a window boundary names only `window`"
                 for k in ("onset", "recognition", "gap") if k in occ]
    elif boundary == "event":
        if "window" in occ:
            errs.append(f"{node.id}: occasion `window` belongs to `boundary: \"window\"`; an event boundary is the act's `onset`, and a "
                        "justified observation or recognition bound is a parameter of the act's concept")
        on = occ.get("onset")
        ids = (list(on.get("atoms") or []) + list(on.get("derived") or [])) if isinstance(on, dict) else []
        if not isinstance(on, dict) or not _ws(on.get("words")) or not _ws(on.get("justification")) or not ids:
            errs.append(f"{node.id}: occasion `onset` must be an element {{words, atoms, derived, justification}}: the words that "
                        "mark the act's observed beginning, mapped to at least one atom or concept the rule reads")
        else:
            unknown = [i for i in ids if onto is not None and not onto.knows(i) and i not in (concept_ids or set())]
            if unknown:
                errs.append(f"{node.id}: occasion `onset` names {unknown}, neither atoms of the ontology nor concepts of the catalogue or this plan")
        if not _ws(occ.get("recognition")):
            errs.append(f"{node.id}: occasion `recognition` must state where the act is recognized")
        if "gap" in occ and not any(g.get("span") == occ["gap"] and g.get("kind") == "operator" for g in node.gaps() if isinstance(g, dict)):
            errs.append(f"{node.id}: occasion `gap` names span {occ['gap']!r}, which carries no `operator` gap of this record; the gap "
                        "states the boundary the formula language cannot write")
    read = occ.get("spans")
    if not isinstance(read, dict):
        errs.append(f"{node.id}: occasion `spans` must map each trigger, condition or exception span to one of {sorted(OCCASIONS)}")
        read = {}
    errs += [f"{node.id}: occasion names span `{k}`, which is not a trigger, condition or exception span the node maps" for k in read if k not in scoped]
    errs += [f"{node.id}: occasion does not say when span `{k}` is read" for k in scoped if k not in read]
    errs += [f"{node.id}: occasion of span `{k}` is {v!r}, not one of {sorted(OCCASIONS)}" for k, v in read.items() if v not in OCCASIONS]
    during = sorted(k for k, v in read.items() if v in ("some_moment", "throughout"))
    if during:
        uw = occ.get("under_way")
        if not isinstance(uw, dict) or not _ws(uw.get("words")) or not _ws(uw.get("justification")):
            errs.append(f"{node.id}: occasion `under_way` must be an element {{words, atoms, derived, justification}}: the words that "
                        "say the act is in progress, mapped to what the rule reads to tell an observation inside the act from one before it")
        else:
            ids = list(uw.get("atoms", [])) + list(uw.get("derived", []))
            unknown = [i for i in ids if onto is not None and not onto.knows(i) and i not in (concept_ids or set())]
            if unknown:
                errs.append(f"{node.id}: occasion `under_way` names {unknown}, neither atoms of the ontology nor concepts of the catalogue or this plan")
            known = [i for i in ids if i not in unknown]
            if onto is not None and not reads_motion(known, onto, concept_atoms or {}):
                errs.append(f"{node.id}: occasion `under_way` reads no motion of the road user ({known or 'nothing'}): a place, a region "
                            "or a constant cannot tell the act from the stretch before it — map it to a kinematic atom, a primitive, "
                            "or a concept that reads one")
    scs = {sc.get("name"): sc for sc in node.get("scenarios", [])}
    for k in during:
        a_, b_ = f"occasion_{k}", f"occasion_{k}_outside"
        if a_ not in scs:
            errs.append(f"{node.id}: span `{k}` is read `{read[k]}`; add scenario `{a_}`, in which it holds for part of the act only")
        if b_ not in scs:
            where = "only before the act began" if read[k] == "some_moment" else "throughout the act but not before it"
            errs.append(f"{node.id}: span `{k}` is read `{read[k]}`; add scenario `{b_}`, in which it holds {where}")
        if a_ in scs and b_ in scs and normalize_verdict(scs[a_].get("expected")) == normalize_verdict(scs[b_].get("expected")):
            errs.append(f"{node.id}: scenarios `{a_}` and `{b_}` expect the same verdict; the reading of span `{k}` must decide them apart")
    if errs:
        return [f"{node.id}: the occasion of the act is incomplete. It requires: " + occasion_requirements(acts, scoped)] + errs
    return errs


def head_role(node: Node) -> str:
    """The role of the span a node is the node of: its obligation, or, for a permission node, its
    permission."""
    return "permission" if node.get("permission") else "obligation"


def claimed_obligation(node: Node, law_text: str) -> tuple[int, int] | None:
    """Where in the law the one obligation span this node carries (by an element, an
    operationalization or a residue) lies, a permission node's permission span counting as its
    obligation: a duty is its occurrence, so two duties in identical words are two."""
    spans, offs = node.spans(), span_offsets(node.get("segmentation", []), law_text)
    carried = [e.get("span") for key in ("elements", "operationalizations", "residues") for e in node.get(key, [])]
    head = head_role(node)
    at = {offs[sid] for sid in carried if sid in spans and spans[sid].get("role") == head and sid in offs}
    return next(iter(at)) if len(at) == 1 else None


SCOPE_ROLES = {"trigger", "subject", "condition", "exception"}


def check_residue_scope(node: Node) -> list[str]:
    """A residue on a span that decides when the rule applies would make the rule apply where the
    law does not. Such a span the vocabulary cannot carry is carried by an assumption only for a
    legal region class or a calendar or clock condition, by a declared intention or an observable
    reading only where their rules allow, or mapped to its nearest atoms with a gap. The one residue
    accepted there is one whose span adds no restriction (the duty is the same whether or not its
    words hold), marked `scope: none`."""
    errs = []
    spans = node.spans()
    for r in node.get("residues", []):
        role = spans.get(r.get("span"), {}).get("role")
        if role in SCOPE_ROLES and r.get("scope") != "none":
            errs.append(f"{node.id}: residue on span {r.get('span')} ({role}) — a {role} the vocabulary cannot carry is carried by an "
                        f"assumption only for a legal region class or a calendar or clock condition, by a declared intention or an "
                        f"observable reading only where their rules allow, or mapped to its nearest atoms with a gap; a residue here "
                        f"makes the rule apply where the law does not. A span that adds no restriction (the duty is the same whether "
                        f"or not its words hold) carries `\"scope\": \"none\"` with a `why` saying why")
    return errs


NARROWABLE_ROLES = {"obligation", "standard"}


#: A narrowing that reads a word with no observable counterpart through the conduct or feature it refers
#: to, and the closed list of what such a word may be.
OBSERVABLE_READING = "observable_reading"
OBSERVABLE_CATEGORIES = {"intention", "perception", "status", "purpose", "agency"}
#: The family of road-user identity classes (`ru.`, the aggregates included): an atom of it states
#: what a road user is, never what it does, why, what it perceives or what a feature on the road shows.
IDENTITY_FAMILY = "ru."
#: The categories an identity class never carries, each with what the ontology reads it through, in
#: its own words: a purpose, a perception and an imminent movement through conduct or its outcome, a
#: legal status through the feature on the road that displays it. Agency is not among them: who
#: controls a vehicle is read through that vehicle's controlled motion, so a subject's class naming the
#: bound vehicle is the reading itself.
OBSERVABLE_THROUGH = {
    "purpose": "a span that turns on one is read through the conduct or the outcome it governs: [...] a purpose by the conduct it explains",
    "perception": "a span that turns on one is read through the conduct or the outcome it governs: [...] a duty to perceive, ascertain or "
                  "make sure by the outcome the check is there to secure (the movement made with the clearances the reading sets)",
    "intention": "a span that turns on one is read through the conduct or the outcome it governs: an imminent movement (\"about to …\") "
                 "by the movement it leads to",
    "status": "The feature's presence on the road is the observable evidence of that status: a rule reads the feature and presumes the status",
}


def span_carriers(node: Node, sid) -> list[str]:
    """The ids that carry span `sid`: its elements' atoms and derived concepts, and its
    operationalizations' concepts."""
    out: list[str] = []
    for e in node.get("elements", []) or []:
        if isinstance(e, dict) and e.get("span") == sid:
            out += [i for key in ("atoms", "derived") for i in (e.get(key) or []) if isinstance(i, str)]
    for o in node.get("operationalizations", []) or []:
        if isinstance(o, dict) and o.get("span") == sid:
            out += [i for i in concepts_of(o) if isinstance(i, str)]
    return out


def identity_only(ids: list[str]) -> bool:
    """The carriers are road-user identity classes and nothing else: no atom of another family, no
    concept, no primitive."""
    return bool(ids) and all(i.startswith(IDENTITY_FAMILY) for i in ids)


def identity_and_more(ids: list[str]) -> bool:
    """The carriers mix road-user identity classes with ids of another family."""
    return any(i.startswith(IDENTITY_FAMILY) for i in ids) and not identity_only(ids)


def check_declarations(node: Node, catalogue: dict[str, str], fact_terms: dict[str, dict] | None = None) -> list[str]:
    """The node's declared facts against the run's one catalogue of ids (`catalogue`: id ↦ meaning,
    the reading's declarations and those of the nodes validated before this one; `fact_terms`: a
    `fact.*` id ↦ its kind, subjects, `true_when` and `false_when`). An assumption's id is
    `asm.<name>`, an intention's `int.<name>` and a declared fact's `fact.<name>`. An id the catalogue
    has is reused: it may omit its meaning (and a fact its terms), which the harness writes into the
    record; a meaning or a term it gives is the catalogue's. An id the catalogue lacks gives its
    meaning (and a fact its terms: a kind of the closed list, `one` or `pair` subjects, and what a
    source must hold to declare it true and false), and joins the catalogue for the nodes validated
    after this one. A declared intention or fact is carried on a span that decides when the rule
    applies (trigger, subject, condition, exception). A span carrying an intention carries no
    observable reading of an intention; a span carrying a declared fact carries no observable reading
    and no gap: the words are read as declared, or through conduct, never both. The meaning an id
    resolves to (its own, or the catalogue's for a reused id), and a fact's terms, state the fact or
    state the source supplies: one that cites a law, a definition or a provision is refused, and a
    new id with such a meaning does not join the catalogue."""
    errs = []
    fact_terms = {} if fact_terms is None else fact_terms
    spans = node.spans()
    narrowed = {(n.get("span"), n.get("category")) for n in node.get("narrowings", []) if n.get("kind") == OBSERVABLE_READING}
    gapped = {g.get("span") for g in node.get("gaps", []) if isinstance(g, dict)}
    for key, prefix in (("assumptions", "asm."), ("intentions", "int."), ("facts", "fact.")):
        for d in node.get(key, []):
            cid, meaning = d.get("id"), _ws(d.get("meaning"))
            well_formed = bool(DECLARED_ID.match(cid or "")) and cid.startswith(prefix)
            given = {k: _ws(d.get(k)) for k in FACT_TERMS if _ws(d.get(k))} if key == "facts" else {}
            if not well_formed:
                errs.append(f"{node.id}: {key} id `{cid}` is not `{prefix}<snake_case name>`")
            if well_formed and cid in catalogue:
                if meaning and not same_meaning(meaning, catalogue[cid]):
                    errs.append(f"{node.id}: `{cid}` means {catalogue[cid]!r} in the catalogue, here {meaning!r}: reuse the id without a "
                                "meaning, or propose a new id for another meaning")
                else:
                    d["meaning"] = catalogue[cid]
                    if cited := meaning_citations(catalogue[cid]):
                        errs.append(f"{node.id}: the catalogue's meaning of `{cid}` cites {', '.join(cited)}: a declared fact's meaning states "
                                    "the fact or state the source supplies, never a law, a defined word's reading or whether a duty "
                                    "applies; propose a new id whose meaning states only that fact")
                if key == "facts":
                    have = fact_terms.get(cid) or {}
                    clash = [k for k, v in given.items() if not same_meaning(v, _ws(have.get(k)))]
                    if clash:
                        errs.append(f"{node.id}: `{cid}` gives {', '.join(clash)} other than the catalogue's: reuse the id without its "
                                    "terms, or propose a new id")
                    else:
                        d.update({k: have[k] for k in FACT_TERMS if have.get(k) is not None})
            elif not meaning:
                errs.append(f"{node.id}: `{cid}` is in no catalogue and gives no meaning: reuse a catalogued id, or give the new id its meaning")
            elif cited := meaning_citations(" ".join([meaning, *given.values()])):
                errs.append(f"{node.id}: the meaning of `{cid}` cites {', '.join(cited)}: a declared fact's meaning states the fact or "
                            "state the source supplies, never a law, a defined word's reading or whether a duty applies")
            elif key == "facts" and (bad := fact_terms_defects(d)):
                errs.append(f"{node.id}: the new declared fact `{cid}` " + "; ".join(bad) + ": a declared fact states its kind (one of "
                            "the closed list), whether it is of one road user or an ordered pair, and what a source must hold to declare "
                            "it true and to declare it false")
            elif well_formed:
                catalogue[cid] = meaning
                if key == "facts":
                    fact_terms[cid] = {k: d.get(k) for k in FACT_TERMS}
            if key in ("intentions", "facts"):
                what = "intention" if key == "intentions" else "declared fact"
                role = spans.get(d.get("span"), {}).get("role")
                if role not in SCOPE_ROLES:
                    errs.append(f"{node.id}: {what} `{cid}` on span {d.get('span')} ({role}); a {what} is carried on a "
                                "trigger, subject, condition or exception span")
            if key == "intentions" and (d.get("span"), "intention") in narrowed:
                errs.append(f"{node.id}: span {d.get('span')} carries the intention `{cid}` and an observable reading of an intention; "
                            "the words are read as declared, or through conduct, not both")
            if key == "facts":
                if any(s == d.get("span") for s, _ in narrowed):
                    errs.append(f"{node.id}: span {d.get('span')} carries the declared fact `{cid}` and an observable reading; the words "
                                "are read as declared, or through conduct, not both")
                if d.get("span") in gapped:
                    errs.append(f"{node.id}: span {d.get('span')} carries the declared fact `{cid}` and a gap; the declared fact carries "
                                "the words, so no gap is filed on them")
    return errs


def check_narrowings(node: Node, rejected_gaps: dict[str, dict] | None = None, law_text: str = "",
                     abstractions: dict[str, str] | None = None) -> list[str]:
    """A narrowing is a disclosed reading of a span the plan carries by an element or an
    operationalization: the span exists, has role obligation or standard, is so carried, and the
    narrowing says why. An `observable_reading` (a word with no observable counterpart, read through
    the conduct or feature it refers to, of a category in the closed list) may also be declared on a
    trigger, subject, condition or exception span an element carries. A reading of a purpose, a
    perception, an intention or a status is never carried by road-user identity classes alone: a
    class is no conduct and no feature. Otherwise a span that decides
    when the rule applies is never narrowed; a span nothing
    carries is a residue or a gap, not a narrowing. A narrowing of either kind may name in `gap` a
    rejected gap of the ledger (`rejected_gaps`: id ↦ {laws, occurrence}): the operator's decision
    that the span is carried as it is. It must be a gap decided on this law, and the narrowing's span
    must overlap the words the gap was filed on (its `occurrence`, `<law>@<digest>:<start>-<end>`);
    a gap recorded without an occurrence is checked for its law only. An `abstraction` declares words
    of a span omitted under an approved abstraction: it names a span of the record, an id of the
    ontology's catalogue (`abstractions`: id ↦ scope), and why the words are of that kind."""
    errs = []
    spans = node.spans()
    carried = {x.get("span") for key in ("elements", "operationalizations") for x in node.get(key, [])}
    offsets = span_offsets(node.get("segmentation", []), law_text) if law_text else {}
    for n in node.get("narrowings", []):
        sid, role = n.get("span"), spans.get(n.get("span"), {}).get("role")
        gap = n.get("gap")
        if gap is not None:
            errs += _cited_gap_errors(node, sid, gap, rejected_gaps or {}, offsets)
        if n.get("kind") == ABSTRACTION:                 # words omitted under an approved abstraction: partial coverage
            if sid not in spans:
                errs.append(f"{node.id}: abstraction refers to unknown span {sid!r}; it is declared on the span whose words it omits")
            if n.get("abstraction") not in (abstractions or {}):
                errs.append(f"{node.id}: abstraction on span {sid} names {n.get('abstraction')!r}, which is no approved abstraction of the "
                            f"ontology's catalogue ({', '.join(sorted(abstractions or {})) or 'none'}); words of no approved kind are "
                            "carried, or stay a gap")
            if not _ws(n.get("why")):
                errs.append(f"{node.id}: abstraction on span {sid} states no `why` (why its words are of the abstraction's kind)")
            continue
        if n.get("kind") == OBSERVABLE_READING:          # a word with no observable counterpart, read through conduct
            if sid not in spans:
                errs.append(f"{node.id}: narrowing refers to unknown span {sid!r}")
            elif role not in SCOPE_ROLES | NARROWABLE_ROLES:
                errs.append(f"{node.id}: observable reading on span {sid} ({role}); it is declared on a span that decides when the rule applies or on its duty")
            elif sid not in carried:
                errs.append(f"{node.id}: observable reading on span {sid}, which no element carries: the element maps the conduct or feature the words are read through")
            elif n.get("category") in OBSERVABLE_THROUGH and identity_only(ids := span_carriers(node, sid)):
                through = OBSERVABLE_THROUGH[n.get("category")]
                errs.append(f"{node.id}: observable reading on span {sid} ({n.get('category')}) is carried only by road-user identity classes "
                            f"({', '.join(ids)}); a class states what a road user is, never what it does, why, what it perceives or what a "
                            f"feature on the road shows, so it is no evidence for these words"
                            + f". The ontology reads them so: \"{through}\""
                            + ". Carry the span by the conduct or the feature the words are read through; where no observable conduct or "
                              "feature tells the words apart, map the span to its nearest atoms with a gap, or let the rule stay unknown")
            if n.get("category") not in OBSERVABLE_CATEGORIES:
                errs.append(f"{node.id}: observable reading on span {sid} has category {n.get('category')!r}, not one of {sorted(OBSERVABLE_CATEGORIES)}")
            if not _ws(n.get("why")):
                errs.append(f"{node.id}: observable reading on span {sid} states no `why` (which conduct or feature the words are read through)")
            continue
        if n.get("kind") not in (None, "reading"):
            errs.append(f"{node.id}: narrowing on span {sid} has kind {n.get('kind')!r}; a plan's narrowing is `reading`, `{OBSERVABLE_READING}` or `{ABSTRACTION}`")
        if sid not in spans:
            errs.append(f"{node.id}: narrowing refers to unknown span {sid!r}")
        elif role in SCOPE_ROLES:
            errs.append(f"{node.id}: narrowing on span {sid} ({role}) — a span that decides when the rule applies is carried as its words say, assumed, or a gap; narrowed, the rule applies where the law does not")
        elif role not in NARROWABLE_ROLES:
            errs.append(f"{node.id}: narrowing on span {sid} ({role}); a narrowing is declared on an obligation or standard span")
        elif sid not in carried:
            errs.append(f"{node.id}: narrowing on span {sid}, which no element or operationalization carries; words nothing carries are a residue or a gap")
        if not _ws(n.get("why")):
            errs.append(f"{node.id}: narrowing on span {sid} states no `why`")
    return errs


def _cited_gap_errors(node: Node, sid, gap, rejected_gaps: dict[str, dict], offsets: dict[str, tuple[int, int]]) -> list[str]:
    row = rejected_gaps.get(gap) if isinstance(gap, str) else None
    if row is None:
        return [f"{node.id}: narrowing on span {sid} names gap {gap!r}, which is no rejected gap of the ledger"]
    if node.law not in row["laws"]:
        return [f"{node.id}: narrowing on span {sid} names gap {gap}, which was decided on {sorted(row['laws'])}, not on this law"]
    occ = re.fullmatch(r".*:(\d+)-(\d+)", str(row.get("occurrence") or ""))
    at = offsets.get(str(sid))
    if occ and at and not (at[0] < int(occ.group(2)) and int(occ.group(1)) < at[1]):
        return [f"{node.id}: narrowing on span {sid} names gap {gap}, which the operator decided on other words of the law "
                f"(characters {occ.group(1)}–{occ.group(2)}); a decision settles only the words it was filed on"]
    return []


_OCCURRENCE = re.compile(r"^(?P<law>.+)@[^@:]*:(?P<start>\d+)-(?P<end>\d+)$")
#: What carries a span's words in a record (a residue does not: it names words the record leaves out).
_CARRIERS = ("elements", "operationalizations", "assumptions", "intentions", "facts", "compositions", "rule_sets")


def check_gap_resolutions(node: Node, law_text: str, ledger_gaps: list[dict]) -> list[str]:
    """A gap of the ledger is withdrawn only by a record that answers the operator's decision on it.
    For each gap filed on this law (its `occurrence`, `<law>@<digest>:<start>-<end>`), a record whose
    spans that carry the gap's words carry no gap there withdraws it: the gap must be decided
    (`retired` or `rejected`) and `gap_resolutions` must name it with one of those spans and a
    non-empty `basis`. Every `gap_resolutions` entry names a gap of the ledger decided on this law and
    a span of the record that holds the words the gap was filed on. An entry proves only the link
    between the operator's decision and the record, never that the new representation is right: no
    semantics is checked here. A ledger with no gap of the law (a fresh run) asks nothing."""
    errs: list[str] = []
    rows = {str(r.get("id")): r for r in ledger_gaps if isinstance(r, dict) and r.get("id")}
    spans = node.spans()
    offsets = span_offsets(node.get("segmentation", []), law_text)
    entries = [x for x in node.get("gap_resolutions") or [] if isinstance(x, dict)]
    for x in entries:
        gid, sid = x.get("gap"), x.get("span")
        r = rows.get(str(gid))
        if r is None:
            errs.append(f"{node.id}: `gap_resolutions` names gap {gid!r}, which is no gap of the ledger")
        elif node.law not in r.get("law_refs", []):
            errs.append(f"{node.id}: `gap_resolutions` names gap {gid}, which was filed on {sorted(r.get('law_refs', []))}, not on this law")
        elif r.get("state") not in ("retired", "rejected"):
            errs.append(f"{node.id}: `gap_resolutions` names gap {gid}, which the operator has not decided (it is {r.get('state')}): "
                        "an undecided gap is withdrawn by no record")
        if sid not in spans:
            errs.append(f"{node.id}: `gap_resolutions` entry for gap {gid} names span {sid!r}, which is no span of the record")
        elif r is not None and node.law in r.get("law_refs", []):
            m = _OCCURRENCE.match(str(r.get("occurrence") or ""))
            at = offsets.get(str(sid))
            if m and at and not (at[0] < int(m["end"]) and int(m["start"]) < at[1]):
                errs.append(f"{node.id}: `gap_resolutions` entry for gap {gid} names span {sid}, which does not hold the words the gap "
                            f"was filed on (characters {m['start']}–{m['end']}): an entry answers the gap on its own words")
        if not _ws(x.get("basis")):
            errs.append(f"{node.id}: `gap_resolutions` entry for gap {gid} states no `basis` (the atom or revision that retired it, "
                        "or the reading the rejection allows)")
    carried = {x.get("span") for key in _CARRIERS for x in node.get(key) or [] if isinstance(x, dict)}
    gapped = {g.get("span") for g in node.gaps() if isinstance(g, dict)}
    for gid, r in sorted(rows.items()):
        m = _OCCURRENCE.match(str(r.get("occurrence") or ""))
        if not m or m["law"] != node.law:
            continue
        start, end = int(m["start"]), int(m["end"])
        over = sorted(str(sid) for sid, (a, b) in offsets.items() if a < end and start < b)
        if not over or gapped & set(over):
            continue                                    # the words are not in the record, or it still carries a gap on them
        at = [sid for sid in over if sid in carried]
        if not at:
            continue                                    # the record does not carry those words (a sibling's, or another node's)
        if r.get("state") not in ("retired", "rejected"):
            errs.append(f"{node.id}: span(s) {at} carry the words of gap {gid} (characters {start}–{end}) without it, and the operator "
                        f"has not decided it (it is {r.get('state')}): the record carries the gap there until the operator decides it")
            continue
        if not any(x.get("gap") == gid and x.get("span") in at and _ws(x.get("basis")) for x in entries):
            errs.append(f"{node.id}: span(s) {at} carry the words of gap {gid} (characters {start}–{end}), which the operator "
                        f"{r.get('state')}, without it: name it in `gap_resolutions` as {{gap: {gid}, span: one of {at}, basis: the "
                        "atom or revision that retired it, or the reading the rejection allows}")
    return errs


def check_reemission(node: Node, accepted: dict[str, Node], law_text: str) -> list[str]:
    """A node the run already accepted is never re-planned: a record under its id must carry the
    same obligation span and the same atoms (a re-emission the harness will not code again)."""
    acc = accepted.get(node.id)
    if acc is None:
        return []
    if claimed_obligation(node, law_text) != claimed_obligation(acc, law_text) or node.claimed_atoms() != acc.claimed_atoms():
        return [f"{node.id}: already accepted, and this record differs from the accepted one (obligation span or atoms); "
                f"an accepted node is not re-planned — re-emit it unchanged or leave it out, and re-plan the returned nodes only"]
    return []


def check_identity(node: Node, law_nodes: list[Node], law: Law) -> list[str]:
    """The node id is the derivation from the law id and the ordinal of its obligation among the
    obligations the law's nodes carry, in text order."""
    if not node.get("law_refs") or node.law != law.id:
        return [f"{node.id}: law_refs must start with the law it segments"]
    if not any(s.get("role") == head_role(node) for s in node.get("segmentation", [])):
        return [f"{node.id}: no {head_role(node)} span"]
    mine = claimed_obligation(node, law.text)
    if mine is None:
        return [f"{node.id}: a node carries exactly one obligation span (by an element, an operationalization or a residue)"]
    ordered = sorted({claimed_obligation(n, law.text) for n in law_nodes} - {None})
    total, ordinal = len(ordered), ordered.index(mine) + 1
    expected = nodeid.derive(law.id, ordinal, total)
    if node.id != expected:
        return [f"{node.id}: node id must be `{expected}` — the law's nodes carry {total} obligation(s), this one is number {ordinal} in text order"]
    return []


def check_decomposition(nodes: list[Node], law: Law) -> list[str]:
    """Across the nodes of one law: obligation spans (by their occurrence in the law) partitioned, one
    node each; a span one node marks `sibling` is another node's obligation or claimed span."""
    errs = []
    seen: dict[tuple, str] = {}
    offs = {n.id: span_offsets(n.get("segmentation", []), law.text) for n in nodes}
    for n in nodes:
        carried = {e.get("span") for key in ("elements", "operationalizations", "residues", "compositions", "rule_sets", "assumptions", "intentions", "facts") for e in n.get(key, [])}
        for s in n.get("segmentation", []):
            if s.get("role") == "obligation" and s["id"] in carried and s["id"] in offs[n.id]:
                key = offs[n.id][s["id"]]
                if key in seen and seen[key] != n.id:
                    errs.append(f"{law.id}: obligation `{s['text'][:60]}` is claimed by both {seen[key]} and {n.id}")
                seen[key] = n.id
    segmented = {n.id: [offs[n.id][s["id"]] for s in n.get("segmentation", []) if s.get("role") != "sibling" and s["id"] in offs[n.id]]
                 for n in nodes}
    for n in nodes:
        for s in n.get("segmentation", []):
            if s.get("role") == "sibling":
                at = offs[n.id].get(s["id"])
                if at is None or not any(a < at[1] and at[0] < z for m in nodes if m.id != n.id for a, z in segmented[m.id]):
                    errs.append(f"{n.id}: sibling span {s['id']} `{s['text'][:60]}` is no other node's span (a sibling span is one another node of the same law carries)")
    return errs


def check_segment_roles(node: Node, index: MappingIndex) -> list[str]:
    """The role of a law's words is fixed with its segmentation once a node of the law is accepted:
    a sibling planned later segments the same words alike. (How another law maps the same words is
    no constraint: the index is shown to the planner as information.)"""
    errs = []
    for e in node.get("elements", []):
        sid = e.get("span")
        text = node.spans().get(sid, {}).get("text", "")
        prior_e = index.entry(text) if text.strip() else None
        role = node.spans().get(sid, {}).get("role")
        if prior_e and prior_e.get("role") and role and prior_e["role"] != role and nodeid.law_of(prior_e["node"])[0] == node.law:
            errs.append(f"{node.id}: span {sid} `{text[:60]}` has role {role}; accepted node {prior_e['node']} of the same law segments these words "
                        f"as {prior_e['role']}, and the role of words is fixed with the segmentation once a node of the law is accepted")
    return errs


def resolve_rule_ids(node: Node, known: dict[str, Node]) -> list[str]:
    """`rule` names a node; a law id (dashes) is rewritten to its node when the law has one node. A
    `definition` reference names no rule and is left as it is."""
    errs = []
    for c in node.dependencies():
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


UNKNOWN_TARGET = re.compile(r"^(?P<node>\S+): composes `(?P<rule>[^`]*)`, which is neither accepted nor in this plan$")


def unknown_target(node_id: str, rule) -> str:
    """The defect of an execution composition whose rule is no node the validator knows (accepted, or
    in this plan); `UNKNOWN_TARGET` reads the rule back from it."""
    return f"{node_id}: composes `{rule}`, which is neither accepted nor in this plan"


MISSING_CASE = re.compile(r"^(?P<node>\S+): composes case `(?P<case>[^`]*)` of `(?P<rule>[^`]*)`, which declares no such case$")


def missing_case(node_id: str, rule, case) -> str:
    """The defect of a composition naming a case its target does not declare: never read as absent;
    `MISSING_CASE` reads the target and the case back from it, for the target's planner."""
    return f"{node_id}: composes case `{case}` of `{rule}`, which declares no such case"


def check_compositions(node: Node, known: dict[str, Node], sources: dict[str, str] | None = None) -> list[str]:
    """Each composition's kind and target: an execution dependency names a rule that resolves; a
    `definition` reference is checked against its source (`check_definition_reference`)."""
    errs = resolve_rule_ids(node, known)
    for c in node.compositions():
        if c.get("as") not in AS_KINDS:
            errs.append(f"{node.id}: composition on span {c.get('span')} has `as` {c.get('as')!r}; must be one of {sorted(AS_KINDS)}")
        if c.get("as") == DEFINITION:
            errs += check_definition_reference(node, c, sources or {})
            continue
        if not c.get("rule"):
            errs.append(f"{node.id}: composition on span {c.get('span')} (as {c.get('as')}) names no `rule`; an execution "
                        "dependency names the node it composes")
            continue
        scopes = c.get("scopes")
        if c.get("as") == "unless":
            role = node.spans().get(scopes, {}).get("role")
            if role not in ("exception", "condition"):
                errs.append(f"{node.id}: composition on span {c.get('span')} is `unless` and must name in `scopes` an exception or condition span of this node; "
                            f"`scopes` is {scopes!r}" + (f" ({role})" if role else ""))
            elif any(isinstance(r, dict) and r.get("span") == scopes for r in node.get("residues", [])):
                errs.append(f"{node.id}: composition on span {c.get('span')} is `unless` and scopes span {scopes}, which a residue carries: a "
                            "residue adds no restriction, so suspending it changes nothing; carry the span (a permission as a `permits` "
                            "case) or drop the `unless`")
        elif scopes is not None:
            errs.append(f"{node.id}: composition on span {c.get('span')} has `scopes` {scopes!r}; only an `unless` composition scopes a span")
        target = known.get(c.get("rule"))
        if target is None:
            errs.append(unknown_target(node.id, c.get("rule")))
            continue
        named = [i for i in corpus.cited_law_ids(node.spans().get(c.get("span"), {}).get("text", "")) if i != node.law]
        if named and target.law not in named:
            errs.append(f"{node.id}: composition on span {c.get('span')} composes `{target.id}` of law {target.law}, but the span names {named}: "
                        "a reference that names a law composes a node of that law")
        if target.get("fenced"):
            errs.append(f"{node.id}: composes `{target.id}`, {fence_words(target.get('fenced'))}: its law is planned again, compose its new node")
        elif target.get("superseded"):
            errs.append(f"{node.id}: composes `{target.id}`, which its law's current plan no longer lists (superseded): compose a node of that plan")
        if c.get("case") is not None:
            if c.get("as") not in ("exception", "condition", "unless"):
                errs.append(f"{node.id}: composition on span {c.get('span')} names a case and is `{c.get('as')}`; a case is read as an exception, a condition or an unless")
            elif not any(x.get("name") == c.get("case") for x in target.get("cases", []) or [] if isinstance(x, dict)):
                errs.append(missing_case(node.id, target.id, c.get("case")))
        names = {b["name"] for b in target.get("binders", [])}
        mapped = set((c.get("map") or {}).keys())
        if mapped != names:
            errs.append(f"{node.id}: composition of `{target.id}` maps {sorted(mapped)}, its binders are {sorted(names)}")
    return errs


def _class_pair_shares(src: str, tgt: str, reading: Reading, classes: set[str]) -> bool | None:
    """Whether the class elements `src` (of the road user mapped) and `tgt` (of the composed binder)
    name a class in common: None where the record does not say. A class atom (an attribute value of
    one counts as the class) names its own class. An admitted aggregate names its included and
    unresolved classes, and, on the side read against a class atom or as the composed binder, the
    classes it covers. Two different class atoms, and an aggregate the reading has not admitted, say
    nothing."""
    def side(e: str) -> tuple[str, set[str], set[str]] | None:
        if e.startswith("ru.aggregate="):
            a = reading.aggregate(e.split("=", 1)[1]) if hasattr(reading, "aggregate") else None
            if not isinstance(a, dict):
                return None
            holds = {c for k in ("included", "unresolved") for c in a.get(k) or [] if isinstance(c, str)}
            covered = {c.get("class") for c in a.get("covered") or [] if isinstance(c, dict)}
            return "aggregate", holds, holds | covered
        base = e.split("=", 1)[0]
        return ("class", {base}, {base}) if base in classes else None
    s, t = side(src), side(tgt)
    if s is None or t is None:
        return None
    if s[0] == t[0] == "class":
        return True if s[1] == t[1] else None
    return bool((s[2] if t[0] == "class" else s[1]) & t[2])


def role_class_notes(node: Node, known: dict[str, Node], reading: Reading, onto: Ontology) -> list[str]:
    """Notes for the operator, never a return: each binder of this node that an execution composition
    maps onto a binder of the composed rule while no pair of their class elements names a class in
    common (`_class_pair_shares`). Disjoint class lists do not make the map impossible: one road user
    may carry several classes, and the ontology states no two classes that cannot be carried together,
    so whether a road user of one is never of the other is the operator's to judge. A variable the
    coder quantifies over, a binder without class elements and a pair the record does not decide get
    no note; a map whose keys are not the composed rule's binders is `check_compositions`'s return."""
    classes = set(road_user_classes(onto))
    mine = {b.get("name"): b.get("class_elements") or [] for b in node.get("binders", []) if isinstance(b, dict)}
    notes = []
    for c in node.dependencies():
        target = known.get(c.get("rule"))
        if target is None or not isinstance(c.get("map"), dict):
            continue
        theirs = {b.get("name"): b.get("class_elements") or [] for b in target.get("binders", []) if isinstance(b, dict)}
        for tb, var in c["map"].items():
            src, tgt = mine.get(var) or [], theirs.get(tb) or []
            if src and tgt and all(v is False for v in (_class_pair_shares(s, t, reading, classes) for s in src for t in tgt)):
                notes.append(f"{node.id}: composition on span {c.get('span')} maps `{var}` (classes {src}) onto the binder `{tb}` of "
                             f"`{target.id}` (classes {tgt}), whose class lists name no class in common; one road user may carry "
                             "several classes and the ontology states none exclusive, so the map is not refused: for the operator's review")
    return notes


def check_rule_sets(node: Node, conducts: set[str], purposes: set[str] | frozenset = frozenset()) -> list[str]:
    """The record's rule-set operators and cases. A `required_by` names a conduct Core declares; a
    `lawful` names its scope, and an aggregate id exactly where the scope is a class's. Each one's
    road user is a binder of the node, or a road user the coding agent quantifies over (any other
    name). A case is named (lower-case, unique in the node), states its situation and sits on a span
    of its kind's roles (`CASE_SPAN_ROLES`); a `requires` case names a conduct Core declares. A node
    that reads a rule-set operator declares no `requires` case: a rule that reads one is in no set,
    so the case would never be read. A permission node has no obligation span and declares only
    `permits` cases; a line that only permits is a permission node."""
    errs = []
    spans = node.spans()
    for x in node.get("rule_sets", []):
        where = f"{node.id}: rule-set operator on span {x.get('span')}"
        if x.get("op") == "required_by":
            if x.get("conduct") not in conducts:
                errs.append(f"{where} requires conduct {x.get('conduct')!r}; one of {sorted(conducts)}")
            if x.get("scope") is not None or x.get("aggregate") is not None:
                errs.append(f"{where} is `required_by`: it ranges over every case requiring its conduct and names no scope")
        elif x.get("op") == "lawful":
            if x.get("conduct") is not None:
                errs.append(f"{where} is `lawful`: it names a scope, not a conduct")
            scope = x.get("scope", "every")
            classed = scope in ("subject_class", "as_class", "as_class_purpose")
            if not classed and x.get("aggregate") is not None:
                errs.append(f"{where} has scope {scope} and names no aggregate")
            if classed and "::" not in str(x.get("aggregate") or ""):
                errs.append(f"{where} has scope {scope}, which names an aggregate id (`<definition id>::<term>`)")
            if (scope in ("purpose", "as_class_purpose")) != (x.get("purpose") is not None) or \
                    (x.get("purpose") is not None and x.get("purpose") not in purposes):
                errs.append(f"{where}: a purpose scope names one of Core's purposes {sorted(purposes)}, and no other scope names one")
    for d in node.get("purposes", []):
        if d.get("purpose") not in purposes:
            errs.append(f"{node.id}: purpose {d.get('purpose')!r} is none of Core's {sorted(purposes)}")
        if d.get("span") not in spans:
            errs.append(f"{node.id}: purpose {d.get('purpose')} names span {d.get('span')!r}, which is no span of the node")
        if not _ws(d.get("why")):
            errs.append(f"{node.id}: purpose {d.get('purpose')} states no why: the words that make the rule one for it")
    planned = {x.get("name") for x in node.get("scenarios", [])}
    owed = [n for c in node.get("cases", []) if c.get("kind") == "requires" and c.get("conduct") == "halt" for n in stop_witness_names(c)]
    owed += [n for d in node.get("purposes", []) for n in purpose_witness_names(str(d.get("purpose")))]
    for n in owed:
        if n not in planned:
            errs.append(f"{node.id}: scenario `{n}` missing: a case requiring a halt is held to a halt, a drive and a creep in one "
                        "situation, and a purpose to the pair that turns on it")
    for u in unless_case_checks(node):
        if u["witness"] not in planned:
            errs.append(f"{node.id}: scenario `{u['witness']}` missing: case `{u['case']}` sits on a span an `unless` of `{u['rule']}` "
                        "scopes, and is held to a witness on which that rule applies to the road users the composition maps")
    names = [c.get("name") for c in node.get("cases", [])]
    for c in node.get("cases", []):
        where = f"{node.id}: case `{c.get('name')}` on span {c.get('span')!r}"
        role = spans.get(c.get("span"), {}).get("role")
        if role not in CASE_SPAN_ROLES.get(c.get("kind"), set()):
            errs.append(f"{where} ({role}); a `{c.get('kind')}` case is stated on a span of role {sorted(CASE_SPAN_ROLES.get(c.get('kind'), set()))}")
        if c.get("kind") == "requires" and c.get("conduct") not in conducts:
            errs.append(f"{where} requires conduct {c.get('conduct')!r}; one of {sorted(conducts)}")
        if c.get("kind") == "permits" and c.get("conduct") is not None:
            errs.append(f"{where} permits an act its situation and rule state; it names no conduct")
        if not re.fullmatch(r"[a-z0-9_]+", str(c.get("name") or "")):
            errs.append(f"{where}: a case name is lower-case letters, digits and `_`")
        if names.count(c.get("name")) > 1:
            errs.append(f"{where}: two cases of the node share the name")
        if not _ws(c.get("situation")):
            errs.append(f"{where} states no situation")
    if any(c.get("kind") == "requires" for c in node.get("cases", [])) and node.get("rule_sets"):
        errs.append(f"{node.id}: declares a case requiring a conduct and reads a rule-set operator; a node that reads one is in no set, so the case would never be read")
    roles = {s.get("role") for s in spans.values()}
    if node.get("permission"):
        if "obligation" in roles:
            errs.append(f"{node.id}: a permission node has no obligation span; a line with a duty is a node of that duty")
        if not any(c.get("kind") == "permits" for c in node.get("cases", [])) or any(c.get("kind") == "requires" for c in node.get("cases", [])):
            errs.append(f"{node.id}: a permission node declares the cases it permits and requires nothing")
    elif "permission" in roles and "obligation" not in roles:
        errs.append(f"{node.id}: the line only permits: it is a permission node (`permission: true`), never a prohibition of everything else and never a residue")
    return errs


def check_exception_kinds(node: Node) -> list[str]:
    """Every `exception` span states once in `exception_kinds` what the rule says where it occurs:
    `meets_duty` (acting that way meets the requirement) or `lifts_duty` (the duty does not apply);
    no other span states one. There is no default: a span without it goes back to the planner."""
    errs = []
    spans = node.spans()
    named = [str(e.get("span")) for e in node.get("exception_kinds", []) or [] if isinstance(e, dict)]
    for sid, s in spans.items():
        if s.get("role") == "exception" and sid not in named:
            errs.append(f"{node.id}: exception span {sid} states no kind in `exception_kinds`: where the exception occurs, does the rule "
                        "say that acting this way meets the requirement (`meets_duty`) or that the duty does not apply now (`lifts_duty`)?")
    for sid in dict.fromkeys(named):
        if spans.get(sid, {}).get("role") != "exception":
            errs.append(f"{node.id}: `exception_kinds` names span {sid!r}, which is no exception span of the node")
        elif named.count(sid) > 1:
            errs.append(f"{node.id}: `exception_kinds` states the kind of span {sid} more than once")
    return errs


OPTION_2 = ("Core does not separate a rule's own exceptions from its applicability (option 2, not implemented), so a case "
            "on an exception that lifts the duty cannot be read by another rule")


def lifted_case_gaps(node: Node, known: dict[str, Node]) -> list[dict]:
    """The operator gaps the harness files for a record that needs a case on an exception recorded
    as `lifts_duty`: its own `permits` case on such a span, or a composition naming a case its
    target declares on one. Neither can be coded: the case would hold where the rule is not
    applicable, which no case of Core expresses. The finding is structural, on the recorded kind;
    it rules nothing on the law's reading. The record is not coded and its law waits for the
    operator, who decides the kind or the requirement."""
    out = []
    for c in node.get("cases", []) or []:
        if isinstance(c, dict) and c.get("kind") == "permits" and node.spans().get(c.get("span"), {}).get("role") == "exception" \
                and node.exception_kind(c.get("span")) == "lifts_duty":
            out.append({"span": c.get("span"), "kind": "operator", "nearest": [],
                        "proposal": f"case `{c.get('name')}` sits on exception span {c.get('span')}, recorded as `lifts_duty`, and permits an "
                                    f"act another rule may read: an unimplemented requirement for the operator. {OPTION_2}"})
    for c in node.dependencies():
        target = known.get(c.get("rule"))
        if c.get("case") is None or target is None:
            continue
        on = next((x.get("span") for x in target.get("cases", []) or [] if isinstance(x, dict) and x.get("name") == c.get("case")), None)
        if on is not None and target.spans().get(on, {}).get("role") == "exception" and target.exception_kind(on) == "lifts_duty":
            out.append({"span": c.get("span"), "kind": "operator", "nearest": [],
                        "proposal": f"the composition on span {c.get('span')} reads case `{c.get('case')}` of `{target.id}`, which that rule "
                                    f"declares on its exception span {on}, recorded as `lifts_duty`: an unimplemented requirement for the "
                                    f"operator. {OPTION_2}"})
    return out


def check_definition_reference(node: Node, c: dict, sources: dict[str, str]) -> list[str]:
    """A `definition` reference names a source and the words it borrows, never a rule: no `rule`,
    `map` or `scopes`; its span is a `reference` span; `source` is a law or a posted definition of the
    run's active corpus (`sources`: id → posted text; nothing outside it is read), one the span names
    in brackets when it names any; `quote` occurs verbatim in that text (whitespace aside)."""
    errs, at = [], f"{node.id}: definition reference on span {c.get('span')}"
    for key in ("rule", "map", "scopes"):
        if c.get(key) is not None:
            errs.append(f"{at} has `{key}`; a definition reference names a source and its quoted words, never a rule — a reference "
                        "whose rule must apply, hold or be complied with is an exception, condition, compliance or unless composition")
    span = node.spans().get(c.get("span"), {})
    if span and span.get("role") != "reference":
        errs.append(f"{at}: the span's role is {span.get('role')}; a definition reference is carried on a `reference` span")
    src, quote = c.get("source"), _ws(c.get("quote"))
    if not isinstance(src, str) or not src.strip():
        return errs + [f"{at} names no `source` (the law or posted definition whose words it borrows)"]
    if not quote:
        errs.append(f"{at} quotes nothing: `quote` holds the borrowed words, verbatim from `{src}`")
    named = corpus.bracketed_ids(span.get("text", ""))
    if named and src not in named:
        errs.append(f"{at} names source `{src}`, which the span does not name; it names {named}")
    if src not in sources:
        return errs + [f"{at}: `{src}` is no law or posted definition of this run's corpus, so its words cannot be borrowed; "
                       "carry the words as this law's own, or propose a gap"]
    if quote and quote not in _ws(sources[src]):
        errs.append(f"{at}: the quote “{quote[:120]}” does not occur verbatim in `{src}`")
    if not src.startswith("DEF-") and not _ws(c.get("why")):
        errs.append(f"{at} borrows from the law `{src}` and states no `why`: say which qualifiers it borrows and why that law's rule need "
                    "not apply, hold or be complied with here (where it must, the reference is an execution composition)")
    return errs


def check_source_spans(node: Node) -> list[str]:
    """The pairing of borrowed words with the elements that carry them: every `source_spans` entry
    is a span of this record carried by a `definition` reference, the element's justification quotes
    the words each one borrows, and every `definition` reference is used by some element."""
    errs = []
    refs: dict[str, list[dict]] = {}
    for c in node.definition_references():
        refs.setdefault(c.get("span"), []).append(c)
    used: set[str] = set()
    for e in node.get("elements", []):
        listed = e.get("source_spans")
        if listed is None:
            continue
        if not listed:
            errs.append(f"{node.id}: element on span {e.get('span')} has an empty `source_spans`; leave it out where the element borrows no words")
        for sid in listed:
            if sid not in refs:
                what = "no span of this record" if sid not in node.spans() else "not carried by a `definition` reference"
                errs.append(f"{node.id}: element on span {e.get('span')} names `{sid}` in `source_spans`, {what}")
                continue
            used.add(sid)
            for c in refs[sid]:
                if _ws(c.get("quote")) and _ws(c.get("quote")) not in _ws(e.get("justification")):
                    errs.append(f"{node.id}: element on span {e.get('span')} draws on `{sid}` but its justification does not quote the "
                                f"borrowed words “{_ws(c.get('quote'))[:120]}” of `{c.get('source')}`")
    for sid in sorted(set(refs) - used, key=str):
        errs.append(f"{node.id}: definition reference on span {sid} is used by no element: the element whose words are the "
                    "borrowed ones names it in `source_spans`, or the span is no definition reference")
    return errs


#: The words that open a composition cycle's reason (`acyclic`).
CYCLE = "composition cycle:"


def cycle_components(nodes: dict[str, Node]) -> list[list[str]]:
    """The composition cycles among `nodes`, along their raw composition edges: each strongly
    connected component of more than one node, and each node that composes itself, its members
    sorted. A node that only reaches a cycle is no member."""
    graph = {n.id: [str(c.get("rule")) for c in n.dependencies() if c.get("rule") in nodes] for n in nodes.values()}
    index: dict[str, int] = {}
    low: dict[str, int] = {}
    on: set[str] = set()
    stack: list[str] = []
    out: list[list[str]] = []

    def strong(v: str) -> None:
        index[v] = low[v] = len(index)
        stack.append(v); on.add(v)
        for w in sorted(graph[v]):
            if w not in index:
                strong(w); low[v] = min(low[v], low[w])
            elif w in on:
                low[v] = min(low[v], index[w])
        if low[v] == index[v]:
            comp = []
            while True:
                w = stack.pop(); on.discard(w); comp.append(w)
                if w == v:
                    break
            if len(comp) > 1 or v in graph[v]:
                out.append(sorted(comp))
    for v in sorted(graph):
        if v not in index:
            strong(v)
    return sorted(out)


def acyclic(nodes: dict[str, Node]) -> list[tuple[str, list[str]]]:
    """Each composition cycle (`cycle_components`) as (its reason, its members): the reason names the
    members and the edges between them, and belongs to the members alone."""
    out = []
    for comp in cycle_components(nodes):
        edges = sorted(f"{a} → {c.get('rule')}" for a in comp for c in nodes[a].dependencies() if c.get("rule") in comp)
        out.append((f"{CYCLE} members {comp}; edges {edges}", comp))
    return out


class ValidatorFault(RuntimeError):
    """A check raised on a record that matched the schema: the validator's defect, never the
    planner's. The run stops uncharged with the record's id and the traceback."""
    def __init__(self, ident: str, trace: str):
        super().__init__(f"the validator failed on `{ident}`: {trace.strip().splitlines()[-1]}")
        self.trace = f"record: {ident}\n{trace}"


def _guarded(ident: str, check, *args):
    import traceback
    try:
        return check(*args)
    except Exception:
        raise ValidatorFault(ident, traceback.format_exc())


def identifier_collisions(ident: str, groups: dict[str, list[str]]) -> list[str]:
    """Names the code generator turns into Lean identifiers (`_ident`): two names of one group that
    are equal, or that become the same identifier, cannot both be written."""
    from ..lean.skeleton import _ident as lean_ident
    errs = []
    for what, names in groups.items():
        seen: dict[str, str] = {}
        for name in names:
            key = lean_ident(name)
            if key in seen:
                errs.append(f"{ident}: {what} `{seen[key]}` and `{name}` " + ("repeat" if seen[key] == name else f"both become the identifier `{key}`")
                            + "; name them apart")
            else:
                seen[key] = name
    return errs


def validate(nodes: list[Node], laws: dict[str, Law], onto: Ontology, reading: Reading,
             index: MappingIndex, accepted: dict[str, Node],
             accepted_concepts: dict[str, dict] | None = None, plan_concepts: list[ConceptRecord] | None = None,
             known_nodes: list[Node] | None = None, rejected_gaps: dict[str, dict] | None = None,
             prior_nodes: list[Node] | None = None, sources: dict[str, str] | None = None,
             ledger_gaps: list[dict] | None = None, resolved_terms: dict[str, list[dict]] | None = None) -> list[Outcome]:
    """`known_nodes` are nodes of the same iteration's other plan batches: a composition may name
    them, they are not validated here. `sources` holds the posted text of every law and posted
    definition of the run's active corpus, by id: what a `definition` reference may borrow from
    (absent, the laws given here). `prior_nodes` are those of them validated before these (the
    earlier batches): the ids they declare are in the catalogue these nodes reuse. `rejected_gaps` maps each rejected gap of the ledger to the
    laws it was decided on and the occurrence it was filed on (`{laws, occurrence}`). `ledger_gaps` are
    the rows of the run's gap ledger, each with its state (`check_gap_resolutions`). `resolved_terms`
    are the definitions table's rows by law (`check_admitted_aggregates`)."""
    outcomes: list[Outcome] = []
    accepted_concepts = accepted_concepts or {}
    plan_concepts = plan_concepts or []
    malformed = {id(n): schema_errors(record_id(n.raw, "node_id"), n.raw, NODE_SCHEMA) for n in nodes}
    for n in nodes:
        if malformed[id(n)]:
            outcomes.append(Outcome(n, RETURN, malformed[id(n)]))
    nodes = [n for n in nodes if not malformed[id(n)]]
    known_nodes = [n for n in known_nodes or [] if not schema_errors("?", n.raw, NODE_SCHEMA)]
    proposal_conflicts = _guarded("the plan's nodes", proposal_conflicts_of, list(known_nodes) + nodes)   # earlier batches first
    concept_ids = set(accepted_concepts) | {c.id for c in plan_concepts}
    concept_atoms = _guarded("the plan's concepts", concept_atom_map, onto, accepted_concepts, plan_concepts)
    acts_declared = {cid: rec["act"] for cid, rec in accepted_concepts.items() if isinstance(rec.get("act"), dict)}
    acts_declared.update({c.id: c.get("act") for c in plan_concepts if isinstance(c.get("act"), dict)})
    known = dict(accepted); known.update({n.id: n for n in (known_nodes or [])}); known.update({n.id: n for n in nodes})
    for n in nodes:
        _guarded(n.id, resolve_rule_ids, n, known)
    by_law: dict[str, list[Node]] = {}
    for n in nodes:
        by_law.setdefault(n.get("law_refs", ["?"])[0], []).append(n)
    plan_ids = {n.id for n in nodes}
    ids = [n.id for n in nodes]
    repeated = {i for i in ids if ids.count(i) > 1}
    # the law's nodes, for identity and decomposition: this plan's, and the accepted ones it leaves out
    for a in accepted.values():
        if a.law in by_law and a.id not in plan_ids:
            by_law[a.law].append(a)
    cycle_errs = _guarded("the plan's compositions", acyclic, known)
    if sources is None:
        sources = {i: l.text for i, l in laws.items()}
    declared = reading.declarations() if hasattr(reading, "declarations") else {}
    catalogue = {i: _ws(d.get("meaning")) for i, d in declared.items()}
    fact_terms = {i: {k: d.get(k) for k in FACT_TERMS} for i, d in declared.items() if i.startswith("fact.")}
    for m in prior_nodes or []:                          # nodes of earlier batches were validated before these
        for d in declared_items(m):
            if d.get("id") and _ws(d.get("meaning")):
                catalogue.setdefault(d["id"], _ws(d["meaning"]))
                if d["id"].startswith("fact.") and not fact_terms_defects(d):
                    fact_terms.setdefault(d["id"], {k: d.get(k) for k in FACT_TERMS})
    from ..lean import surface
    conducts, purposes = surface.conducts(), surface.purposes()
    def one(n: Node) -> Outcome:
        errs = []
        refs = n.get("law_refs", ["?"])
        law = laws.get(refs[0]) if refs else None
        if law is None:
            errs.append(f"{n.id}: law {n.get('law_refs')} is not in the corpus given to this run")
        if errs:
            return Outcome(n, RETURN, errs)
        binders = [b.get("name") for b in n.get("binders", [])]
        if not binders:
            errs.append(f"{n.id}: no binders — the subject is always a binder")
        elif (n.get("subject") or {}).get("binder") not in (None, binders[0]):
            errs.append(f"{n.id}: the subject binder `{(n.get('subject') or {}).get('binder')}` must come first in `binders`")
        if n.id in repeated:
            errs.append(f"{n.id}: more than one record of this plan has this id; a node id names one record")
        errs += identifier_collisions(n.id, {"binder": binders, "parameter": sorted(set(n.params()))})
        errs += check_segmentation(n, law)
        errs += check_accounting(n, set(laws))
        closed_errs, gaps = check_closed_set(n, onto, concept_ids, {c: r["fenced"] for c, r in accepted_concepts.items() if r.get("fenced")})
        errs += closed_errs
        foreign = {p for m in list(accepted.values()) + list(nodes) + list(known_nodes or []) if m.law != n.law for p in m.params()}
        std_errs, proposals = check_standards(n, reading, foreign)
        errs += std_errs + proposal_conflicts.get(n.id, [])
        errs += check_anchoring(n)
        errs += check_scenarios(n, onto, concept_atoms)
        errs += check_occasion(n, acts_declared, onto, concept_ids, concept_atoms)
        errs += check_literals(n)
        errs += check_identity(n, by_law[law.id], law)
        errs += [e for e in check_decomposition(by_law[law.id], law) if re.search(rf"(?<![\w]){re.escape(n.id)}(?![\w])", e)]   # law-wide, each error to the nodes it names
        errs += check_segment_roles(n, index)
        errs += check_admitted_aggregates(n, (resolved_terms or {}).get(law.id), reading)
        errs += check_compositions(n, known, sources)
        errs += check_rule_sets(n, conducts, purposes)
        errs += check_exception_kinds(n)
        lifted = lifted_case_gaps(n, known)
        notes = role_class_notes(n, known, reading, onto) + [f"{n.id}: {g['proposal']}" for g in lifted]
        errs += check_reference_positions(n, law, set(laws) | {m.law for m in known.values()}, known, by_law[law.id])
        scope = outside_duty_gaps(n, law, set(laws) | {m.law for m in known.values()}) + lifted
        errs += check_source_spans(n)
        errs += check_residue_scope(n)
        errs += check_narrowings(n, rejected_gaps, law.text, onto.abstractions)
        errs += check_gap_resolutions(n, law.text, ledger_gaps or [])
        errs += check_declarations(n, catalogue, fact_terms)
        errs += check_reemission(n, accepted, law.text)
        errs += check_region_places(n.id, n.claimed_atoms(), onto)
        errs += [reason for reason, members in cycle_errs if n.id in members]
        obligation_residue = any(n.spans().get(r.get("span"), {}).get("role") == "obligation" for r in n.get("residues", []))
        # the obligation itself in a residue closes the law: the vocabulary cannot carry the duty, and
        # no re-plan changes that, unless the duty is one only laws outside the corpus give (a scope gap).
        # A record that carries a gap, its own or one the harness files for it (`filed`), is accepted here:
        # the loop files its gaps at registration and blocks its law on them, and the record is never coded
        if obligation_residue and not gaps and not scope:
            return Outcome(n, FAIL, [f"{n.id}: the obligation itself is a residue — not expressible"] + errs, notes=notes)
        elif errs:
            return Outcome(n, RETURN, errs, gaps, notes=notes)
        else:
            return Outcome(n, ACCEPT, proposals=proposals, gaps=gaps + scope, filed=scope, notes=notes)

    for n in nodes:
        outcomes.append(_guarded(n.id, one, n))
    return outcomes


# ---------------------------------------------------------------------------------------------
# Concepts: the record of a concept a plan proposes, checked like a node's
# ---------------------------------------------------------------------------------------------
_IDENT = re.compile(r"^[a-z][a-z0-9_]*$")


@dataclass
class ConceptOutcome:
    concept: ConceptRecord
    kind: str                     # accept | return
    reasons: list[str] = field(default_factory=list)


def _ws(text: str) -> str:
    return " ".join(str(text or "").split())


def record_id(raw, key: str) -> str:
    """A record's id as an error message names it: the id when it is a string, else a placeholder."""
    v = raw.get(key) if isinstance(raw, dict) else None
    return v if isinstance(v, str) and v.strip() else f"(a record whose `{key}` is {_found(v)})"


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


#: The record schemas: every field the harness reads as a key, an identifier, a string or a
#: sequence, with its type, for a node and a concept record. A key ending in `?` is optional: absent,
#: or null (a null optional field is removed, so it reads as absent). `id` is a non-empty string,
#: `str` a string, `unit` a unit the harness knows, `bool` and `any` as named, a set one of its words; `[t]` a list of `t`
#: (`[t, n]`: of at least `n` entries), `{...}` an object with those fields (`*` any key), and a
#: tuple the alternatives. A record that
#: does not match is returned with every mismatch named by its path, before any check reads it.
_ELEMENT = {"span": "id", "atoms?": ["id"], "derived?": ["id"], "justification?": "str", "source_spans?": ["id"]}
_SCENARIO = {"name": "id", "expected": "str", "narrative?": "str", "masked?": ["id"]}
#: A node's scenario may also name the history its trace lacks (`boundary`), for a witness that stays unknown for it.
_NODE_SCENARIO = {**_SCENARIO, "boundary?": "str"}
NODE_SCHEMA = {
    "node_id": "id", "law_refs": ["id", 1], "applicability": "str", "obligation": "str",
    "subject?": {"binder": "id", "class_elements?": ["str"]},
    "segmentation": [{"id": "id", "text": "str", "role": "str"}],
    "elements": [_ELEMENT],
    "operationalizations?": [{"span": "id", "standard?": "str", "concepts?": ["id"], "concept?": "id", "params?": ["id"],
                              "convention?": "str", "surrogate?": "bool"}],
    "assumptions?": [{"span": "id", "id": "id", "meaning?": "str"}],
    "intentions?": [{"span": "id", "id": "id", "meaning?": "str"}],
    "facts?": [{"span": "id", "id": "id", "meaning?": "str", "kind?": "str", "subjects?": "str", "true_when?": "str", "false_when?": "str"}],
    "compositions?": [{"span": "id", "rule?": "id", "map?": {"*": "str"}, "as": "str", "scopes?": "id", "source?": "id", "quote?": "str", "why?": "str",
                       "case?": "id"}],
    "rule_sets?": [{"span": "id", "op": RULE_SET_OPS, "who": "id", "conduct?": "str", "scope?": RULE_SCOPES, "aggregate?": "id",
                    "purpose?": "str", "why?": "str"}],
    "purposes?": [{"purpose": "str", "span": "id", "why": "str"}],
    "cases?": [{"span": "id", "name": "id", "kind": CASE_KINDS, "conduct?": "str", "situation": "str"}],
    "exception_kinds?": [{"span": "id", "kind": EXCEPTION_KINDS}],
    "permission?": "bool",
    "residues?": [{"span": "id", "why?": "str", "scope?": "str"}],
    "binders": [{"name": "id", "class_elements?": ["str"]}],
    "params?": ["id"],
    "narrowings?": [{"span": "id", "why?": "str", "kind?": PLANNED_NARROWING_KINDS, "category?": "str", "gap?": "id", "abstraction?": "id"}],
    "scenarios": [_NODE_SCENARIO],
    "occasion?": {"act?": ("id", ["id"]), "boundary?": BOUNDARIES, "window?": "id", "spans?": {"*": "str"},
                  "onset?": {"words?": "str", "atoms?": ["id"], "derived?": ["id"], "justification?": "str"},
                  "recognition?": "str", "gap?": "id",
                  "under_way?": {"words?": "str", "atoms?": ["id"], "derived?": ["id"], "params?": ["id"], "justification?": "str"}},
    "literals?": [{"span": "id", "text": "str", "value?": "any", "unit?": "str"}],
    "param_proposals?": [{"name": "id", "unit?": "str", "value?": "any", "convention?": "any", "source?": "any"}],
    "gaps?": [{"span": "id", "kind?": "str", "proposal?": "any", "nearest?": "any"}],
    "gap_resolutions?": [{"gap": "id", "span": "id", "basis?": "str"}],
}
CONCEPT_SCHEMA = {
    "concept_id": "id", "kind": "str", "contract": "str", "definition?": "str",
    "args": [{"name": "id", "sort": "str", "values?": ["str"]}],
    "params": [{"name": "id", "unit": "unit", "meaning?": "str"}],
    "act?": {"boundary": BOUNDARIES, "window?": "id", "onset": "str", "recognition": "str", "extent": "str", "history": "str"},
    "elements": [{"span?": "str", "atoms?": ["id"], "concepts?": ["id"], "justification?": "str"}],
    "residues?": [{"span?": "str", "why?": "str"}],
    "literals?": [{"value?": "any", "unit?": "str", "why?": "str"}],
    "scenarios": [_SCENARIO],
    "used_by?": ["id"], "supersedes?": "id", "counterexample?": {"narrative?": "str", "expected?": "str"},
    "differs_from?": {"concept?": "id", "why?": "str"},
}
_TYPE_WORDS = {"id": "a non-empty string", "str": "a string", "unit": "a unit the harness knows", "bool": "true or false"}


def _describe(want) -> str:
    if isinstance(want, (set, frozenset)):
        return "one of " + ", ".join(f"`{w}`" for w in sorted(want))
    if isinstance(want, tuple):
        return " or ".join(_describe(w) for w in want)
    if isinstance(want, list):
        least = f" (at least {want[1]})" if len(want) > 1 else ""
        return (f"a list of {_describe(want[0]).removeprefix('a ').removeprefix('an ')}s" if isinstance(want[0], str) else "a list of objects") + least
    if isinstance(want, dict):
        return "an object"
    return _TYPE_WORDS.get(want, want)


def _found(v) -> str:
    if isinstance(v, list):
        inner = sorted({type(x).__name__ for x in v})
        return f"a list holding {', '.join(inner)}" if inner else "an empty list"
    return "null" if v is None else repr(v) if isinstance(v, str) and not v else type(v).__name__


def schema_errors(ident: str, raw, schema: dict) -> list[str]:
    """Every place the record departs from `schema`, by its path (`binders[0].class_elements`), with
    what was found and what is wanted; a null optional field is removed from the record first."""
    errs: list[str] = []

    def fits(v, want) -> bool:
        if isinstance(want, (set, frozenset)):
            return isinstance(v, str) and v in want
        if isinstance(want, tuple):
            return any(fits(v, w) for w in want)
        if isinstance(want, list):
            return isinstance(v, list) and len(v) >= (want[1] if len(want) > 1 else 0)
        if isinstance(want, dict):
            return isinstance(v, dict)
        return {"id": lambda: isinstance(v, str) and bool(v.strip()), "str": lambda: isinstance(v, str),
                "unit": lambda: isinstance(v, str) and v in FACTORS, "bool": lambda: isinstance(v, bool),
                "any": lambda: True}[want]()

    def check(v, want, path: str) -> None:
        if isinstance(want, tuple):
            for w in want:
                if fits(v, w):
                    return check(v, w, path)
            errs.append(f"{ident}: `{path}` must be {_describe(want)}, not {_found(v)}")
            return
        if not fits(v, want):
            errs.append(f"{ident}: `{path}` must be {_describe(want)}, not "
                        + (repr(v) if isinstance(want, (set, frozenset)) and isinstance(v, str) else _found(v)))
            return
        if isinstance(want, list):
            for i, x in enumerate(v):
                check(x, want[0], f"{path}[{i}]")
        elif isinstance(want, dict):
            obj(v, want, path + ".")

    def obj(d: dict, spec: dict, prefix: str) -> None:
        if "*" in spec:
            for k, x in d.items():
                check(x, spec["*"], f"{prefix}{k}")
            return
        for key, want in spec.items():
            name, optional = key.rstrip("?"), key.endswith("?")
            if d.get(name) is None and name in d and optional:
                del d[name]
            if name not in d:
                if not optional:
                    errs.append(f"{ident}: missing field `{prefix}{name}`")
                continue
            check(d[name], want, f"{prefix}{name}")

    if not isinstance(raw, dict):
        return [f"{ident}: a record must be a JSON object, not {_found(raw)}"]
    obj(raw, schema, "")
    return errs


QUOTE_WORDS = 3
_QUOTED = re.compile(r'[\"\u201c]([^\"\u201c\u201d]+)[\"\u201d]')


def quotes_definition(contract: str, definition: str) -> bool:
    """Whether the contract carries, between double quotation marks, a verbatim run of at least
    `QUOTE_WORDS` words of the definition's text (whitespace normalised)."""
    d = _ws(definition).lower()
    for q in _QUOTED.findall(contract):
        q = _ws(q).lower()
        if len(q.split()) >= QUOTE_WORDS and q in d:
            return True
    return False


def literal_value_errors(cid: str, formal: str, values: list[str]) -> list[str]:
    """Every value of a literal formal is a spelling of one of Core's enumerations: these are the
    spellings `Rule.check` accepts for a quantifier's kind or a literal argument."""
    import difflib
    from ..lean import surface
    spellings = surface.enumeration_spellings()
    known = {s for ss in spellings.values() for s in ss}
    errs = []
    for v in values:
        if v in known:
            continue
        near = difflib.get_close_matches(v, sorted(known), n=3, cutoff=0.5)
        hint = f"; nearest: {near}" if near else ""
        errs.append(f"{cid}: literal formal `{formal}` admits `{v}`, which spells no enumeration value of Core (the enumerations table lists them){hint}")
    return errs


def kind_claim_errors(c: ConceptRecord, formal: str, values: list[str]) -> list[str]:
    """A literal formal whose admissible spellings are all region kinds (or all device kinds) is the
    kind a quantifier ranges over. The gate counts the concept as reading the kind atom of every
    spelling (the reads are taken over every instance), so the record claims each of them."""
    from ..lean import surface
    spellings = surface.enumeration_spellings()
    for enum, prefix in (("StructureKind", "st."), ("DeviceKind", "dev.")):
        if values and all(v in spellings.get(enum, ()) for v in values):
            missing = [prefix + v for v in values if (prefix + v).replace(".", "_") not in c.claimed_names()]
            if missing:
                return [f"{c.id}: literal formal `{formal}` admits the kinds {values}, so the body reads the kind atom of each; "
                        f"claim {missing} on the element that maps the words naming the place or device"]
    return []


_REGION_KINDS: dict[int, frozenset] = {}


def region_kinds(onto: Ontology) -> frozenset:
    """The region kinds of the active ontology, from the atoms' signatures: an atom read true or
    false of one region."""
    key = id(onto)
    if key not in _REGION_KINDS:
        from ..lean import surface
        _REGION_KINDS[key] = frozenset(r["atom"] for r in surface.case_catalogue(onto) if r.get("atom") and r["unit"] == "true / false"
                                       and any(re.fullmatch(r"\w+\(region\)", s) for s in r["signatures"]))
    return _REGION_KINDS[key]


def check_region_places(ident: str, claims: set[str], onto: Ontology) -> list[str]:
    """A record that reads a region claims, for every region argument of each atom or primitive it
    claims, a kind that can bind that argument, since a region quantifier names its kind: a kind
    whose regions (its own and those of every kind refining it) include one Core admits at that
    argument (`surface.region_argument_kinds`: the kinds Core declares a region there may have,
    `TraceLint.regionArgKinds`), and any kind where Core declares any. An export that fails or
    lacks an argument raises, so the validator faults. A region
    kind is not held to it: it names its own region. How the region is tied to the road user
    (occupancy, distance, a device governing it) is the formula's, and the gate checks that every
    quantified region is anchored to a binder (`UNANCHORED_VARIABLE`). A concept that takes a region
    formal is not held to it: the caller's quantifier names that region's kind. An atom with a name
    that reads no region (two road users in contact, beside a road user and a structure) is not held
    to it either, since a claim does not say which name the formula reads; the gate holds the
    formula's own quantifier kinds to Core's admitted kinds (`gate.region_kind_defects`)."""
    from ..lean import surface
    kinds = region_kinds(onto)
    parent = surface.kind_refinements()

    def covers(k: str) -> set[str]:             # what a quantifier over `k` ranges over: `k` and every kind refining it
        def under(j: str | None) -> bool:
            while j and j != k:
                j = parent.get(j)
            return j == k
        return {j.removeprefix("st.") for j in kinds if under(j.removeprefix("st."))}
    claimed_kinds = sorted(c.removeprefix("st.") for c in claims & kinds)
    ids = {c.split("=")[0] for c in claims}
    by_atom: dict[str, list[list[frozenset[str] | None]]] = {}
    for _name, (aid, signatures) in surface.region_argument_kinds(onto).items():
        if aid in ids and aid not in kinds:
            by_atom.setdefault(aid, []).extend(signatures)
    for row in surface.case_catalogue(onto):            # a name of the atom that reads no region asks for no kind
        if row.get("atom") in by_atom and any("region" not in surface._signature_args(s) for s in row["signatures"]):
            by_atom[row["atom"]].append([])
    needs = []
    for aid in sorted(by_atom):
        best = None
        for admitted in by_atom[aid]:            # an atom read through any of its names and signatures
            missing = [(i, adm) for i, adm in enumerate(admitted)
                       if not any(adm is None or covers(k) & adm for k in claimed_kinds)]
            if best is None or len(missing) < len(best):
                best = missing
        for i, adm in best or []:
            if adm is None:
                needs.append(f"`{aid}` (region argument {i + 1}): any kind of region it is read on (for example `st.roadway`)")
            else:
                fit = sorted(f"`{k}`" for k in kinds if covers(k.removeprefix("st.")) & adm)
                needs.append(f"`{aid}` (region argument {i + 1}): one of {', '.join(fit)}")
    if not needs:
        return []
    return [f"{ident}: a region quantifier names its kind, so every region a claimed atom reads needs a claimed kind that can bind it "
            f"(claimed kinds: {', '.join(f'`st.{k}`' for k in claimed_kinds) or 'none'}); claim, on the span that names each place: "
            + "; ".join(needs)]


def check_concept(c: ConceptRecord, defs: dict[str, dict], onto: Ontology, accepted: dict[str, dict],
                  plan_ids: set[str], nodes: dict[str, Node], concept_atoms: dict[str, set[str]], mode: str) -> list[str]:
    errs: list[str] = []
    cid = c.id
    errs += identifier_collisions(cid, {"argument": [a["name"] for a in c.args()], "parameter": [p["name"] for p in c.params()]})
    errs += [f"{cid}: it calls `{r}`, {fence_words(accepted[r]['fenced'])}: call its successor or another concept"
             for r in sorted(c.refs()) if (accepted.get(r) or {}).get("fenced")]
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
        elif not quotes_definition(contract, defs[d].get("text", "")):
            errs.append(f"{cid}: a definition-born contract quotes, in double quotation marks, at least {QUOTE_WORDS} consecutive words of `{d}`; the rest is the planner's observable statement, with every tolerance and window a parameter")
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
        elif s == "literal":
            errs += literal_value_errors(cid, str(n), a["values"]) + kind_claim_errors(c, str(n), a["values"])
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
    # an act: the contract states its onset, its recognition, its extent and its history boundary,
    # and its formals carry what the boundary needs
    act = c.get("act")
    if isinstance(act, dict):
        errs += [f"{cid}: `act.{k}` must be words of the contract, verbatim: the contract states the act's {what}"
                 for k, what in ACT_WORDS.items() if not _ws(act.get(k)) or _ws(act.get(k)) not in contract]
        times = [p.get("name") for p in c.params() if FACTORS.get(str(p.get("unit")), ("",))[0] == "second"]
        if act.get("boundary") == "window" and act.get("window") not in times:
            errs.append(f"{cid}: `act.window` must name the concept's parameter in a unit of time that bounds the act "
                        f"({times or 'none declared'}); got {act.get('window')!r}")
        elif act.get("boundary") == "event" and "window" in act:
            errs.append(f"{cid}: an event boundary names no `act.window`: the act runs from its observed onset; a justified sampling "
                        "or recognition bound stays a parameter whose meaning says so")
    # elements: contract words → atoms and concepts
    if not c.elements():
        errs.append(f"{cid}: no elements: the contract's words map to nothing")
    if not any(a.get("sort") == "region" for a in c.args()):
        errs += check_region_places(cid, c.claimed_atoms(), onto)
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
            elif r in onto.primitive_ids:
                continue
            elif r not in accepted and r not in plan_ids:
                errs.append(f"{cid}: references `{r}`, neither accepted, a primitive, nor in this plan")
        if not _ws(e.get("justification")):
            errs.append(f"{cid}: element on {e.get('span')!r} has no justification")
    for r in c.get("residues", []):
        if not _ws(r.get("why")):
            errs.append(f"{cid}: a residue states no `why`")
    # literals
    for lit in c.literals():
        if not isinstance(lit.get("value"), (int, float)) or lit.get("unit") not in FACTORS or not _ws(lit.get("why")):
            errs.append(f"{cid}: a literal needs a numeric value, a unit in {sorted(FACTORS)} and a `why` (a geometric constant, or a figure the definition states)")
        elif lit.get("value") == 0:
            errs.append(f"{cid}: a literal of zero is never declared — it may appear in any body and the gate never collects one")
    declared = set()
    for lit in c.literals():
        try:
            declared.add(to_core(lit.get("value"), lit.get("unit")))
        except (KeyError, TypeError, ValueError):
            pass
    for u in unsupported_figures(str(c.get("contract", ""))):
        errs.append(f"{cid}: the contract states \"{u.words}\", which the harness cannot read as a figure: write the figure in digits")
    for core, v, words, _start in stated_figures(str(c.get("contract", ""))):   # a figure the contract states is one the body writes
        if (core, v) not in declared:
            errs.append(f"{cid}: the contract states \"{words}\" but `literals` does not declare it — declare it, or "
                        "name a parameter for it and say so in the contract")
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
    # users: those present must claim it; a recorded user no longer in the plan (its law was returned
    # or blocked since) is not the concept's defect, and the loop derives the users from the plan
    for nid in c.used_by():
        n = nodes.get(nid)
        if n is None:
            continue
        if cid not in n.claimed_atoms():
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
        if old in accepted and accepted[old].get("fenced") and not ce:
            pass                                          # a fenced version is superseded on its fence: the fence's evidence stands for a counterexample
        elif not isinstance(ce, dict) or normalize_verdict(ce.get("expected", "")) not in ("compliant", "violated") or not _ws(ce.get("narrative")):
            errs.append(f"{cid}: a supersession carries a `counterexample` scenario (narrative, expected compliant|violated) on which the old body contradicts the contract")
    # near-duplicates of the catalogue: same sorts and reads, no stated difference
    sorts = sorted((a.get("sort") or "") for a in c.args())
    reads = concept_atoms.get(cid, set())
    for oid, rec in accepted.items():
        if oid == old or rec.get("fenced"):              # a fenced version is no catalogue entry to reuse
            continue
        if sorted(a.get("sort", "") for a in rec.get("args", [])) == sorts and set(rec.get("reads", [])) == reads and reads:
            if not _ws((c.get("differs_from") or {}).get("why")) or (c.get("differs_from") or {}).get("concept") != oid:
                errs.append(f"{cid}: same argument sorts and the same atoms as accepted `{oid}`; reuse it, or state `differs_from: {{concept, why}}`")
    return errs


def validate_concepts(plan: list[ConceptRecord], defs: list[dict], onto: Ontology, accepted: dict[str, dict],
                      nodes: list[Node], mode: str = "train") -> list[ConceptOutcome]:
    by_def = {d.get("id"): d for d in defs}
    out = []
    malformed = {id(c): schema_errors(record_id(c.raw, "concept_id"), c.raw, CONCEPT_SCHEMA) for c in plan}
    for c in plan:
        if malformed[id(c)]:
            out.append(ConceptOutcome(c, RETURN, malformed[id(c)]))
    plan = [c for c in plan if not malformed[id(c)]]
    nodes_by_id = {n.raw["node_id"]: n for n in nodes if isinstance(n.raw, dict) and isinstance(n.raw.get("node_id"), str)}
    plan_ids = {c.id for c in plan}
    ids = [c.id for c in plan]
    dup = {i for i in ids if ids.count(i) > 1}
    concept_atoms = _guarded("the plan's concepts", concept_atom_map, onto, accepted, plan)
    cycles = _guarded("the plan's concepts", concept_refs_acyclic, plan, accepted)
    for c in plan:
        errs = _guarded(c.id, check_concept, c, by_def, onto, accepted, plan_ids, nodes_by_id, concept_atoms, mode)
        if c.id in dup:
            errs.append(f"{c.id}: proposed twice in this plan")
        errs += [f"concept cycle: {x}" for x in cycles if c.id in x]
        out.append(ConceptOutcome(c, RETURN if errs else ACCEPT, errs))
    return out
