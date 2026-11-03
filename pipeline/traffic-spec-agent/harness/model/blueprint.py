"""The blueprint records a plan session writes: one per node and one per concept, in the
same file, told apart by `node_id` / `concept_id`."""
from __future__ import annotations
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROLES = {"trigger", "subject", "obligation", "exception", "standard", "condition", "reference", "sibling", "definitional", "boilerplate"}
SUBSTANTIVE = {"trigger", "subject", "obligation", "exception", "standard", "condition", "reference"}
SCENARIOS = {"forbid": "violated", "permit": "compliant", "idle": "not_applicable", "blind": "unknown"}
#: Spellings of a verdict tag a plan may use; the validator normalizes them to the tag.
VERDICT_SPELLINGS = {"violated": "violated", "violation": "violated", "violates": "violated",
                     "compliant": "compliant", "compliance": "compliant", "complied": "compliant",
                     "not_applicable": "not_applicable", "notapplicable": "not_applicable", "not applicable": "not_applicable", "inapplicable": "not_applicable",
                     "unknown": "unknown"}
#: How a composed rule enters this node: its applicability negated (exception), its applicability
#: (condition), its compliance (compliance: "lawfully", "in the manner prescribed"), or its
#: applicability negated inside one exception or condition span of this node (unless: that span's
#: content does not hold where the composed rule applies; `scopes` names the span). These four are
#: execution dependencies: the node is coded, integrated and fenced with the rule it names.
EXECUTION_KINDS = {"exception", "condition", "compliance", "unless"}
#: A reference span that borrows words: `definition` names the source (a law or a posted definition
#: of the run's corpus) and the words quoted from it (`source`, `quote`), and never a rule. The
#: elements whose words are the borrowed ones name the span in `source_spans` and carry its meaning
#: with their own atoms; nothing of the source is executed, so it is no dependency.
DEFINITION = "definition"
AS_KINDS = EXECUTION_KINDS | {DEFINITION}
#: The kinds of a narrowing, one schema at the blueprint and the gate: a plan declares `reading` (the
#: default) or `observable_reading`; a coder adds `reading`, or `no_atom` / `no_operator` (the words
#: cannot be stated), and accounts for a planned `observable_reading`. A concept knows no
#: `observable_reading`: its words are a contract, not a law's.
NARROWING_KINDS = {"reading", "observable_reading", "no_atom", "no_operator"}
PLANNED_NARROWING_KINDS = {"reading", "observable_reading"}
CONCEPT_NARROWING_KINDS = {"reading", "no_atom", "no_operator"}
GAP_KINDS = {"atom", "operator"}   # the two ways the frozen vocabulary can fail a span: no atom (or enumeration value) carries it; no operator expresses it
#: A concept's witnesses: the body can hold, can fail, and stays unknown when a read atom is masked.
CONCEPT_SCENARIOS = {"holds": "compliant", "fails": "violated", "blind": "unknown"}
CONCEPT_KINDS = {"formula", "quantity"}
ARG_SORTS = {"track", "region", "literal", "nat"}


def span_offsets(segmentation: list, text: str) -> dict[str, tuple[int, int]]:
    """Where each span lies in the law's text, as character offsets: spans are verbatim substrings
    in order, so each is found after the one before. A span not found is left out."""
    out, pos = {}, 0
    for s in segmentation if isinstance(segmentation, list) else []:
        t = s.get("text") if isinstance(s, dict) else None
        i = text.find(t, pos) if isinstance(t, str) and t else -1
        if i >= 0:
            out[str(s.get("id"))] = (i, i + len(t)); pos = i + len(t)
    return out


def concepts_of(op: dict) -> list[str]:
    """The ids an operationalization bounds its standard with (`concepts`; a lone `concept` is accepted)."""
    cs = list(op.get("concepts") or [])
    if op.get("concept"):
        cs.append(op["concept"])
    return cs


def normalize_verdict(tag: str) -> str:
    return VERDICT_SPELLINGS.get(str(tag).strip().lower(), str(tag))


@dataclass
class Node:
    raw: dict[str, Any]

    def __getitem__(self, k: str) -> Any:
        return self.raw[k]

    def get(self, k: str, default: Any = None) -> Any:
        return self.raw.get(k, default)

    @property
    def id(self) -> str:
        return self.raw["node_id"]

    @property
    def law(self) -> str:
        return self.raw["law_refs"][0]

    def spans(self) -> dict[str, dict]:
        return {s["id"]: s for s in self.raw.get("segmentation", [])}

    def claimed_atoms(self) -> set[str]:
        """The ids the record claims: its elements', its operationalizations', what marks its
        occasion's act under way, and the class elements of its subject and its binders (each
        binder's class is a formula the rule reads). Only string ids are collected: a record whose
        fields are of another shape is the validator's to return, and reading it here never raises."""
        out: set[str] = set()

        def add(ids: Any) -> None:
            if isinstance(ids, (list, tuple)):
                out.update(i for i in ids if isinstance(i, str))
        dicts = lambda xs: [x for x in xs if isinstance(x, dict)] if isinstance(xs, list) else []
        for b in dicts(self.raw.get("binders")) + dicts([self.raw.get("subject")]):
            add(b.get("class_elements"))
        for e in dicts(self.raw.get("elements")):
            add(e.get("atoms"))
            add(e.get("derived"))
        for o in dicts(self.raw.get("operationalizations")):
            add(concepts_of(o) if isinstance(o.get("concepts") or [], list) else [o.get("concept")])
        uw = (self.raw.get("occasion") or {}).get("under_way") if isinstance(self.raw.get("occasion"), dict) else None
        if isinstance(uw, dict):                 # what marks the act under way is read by the rule, so it is claimed
            add(uw.get("atoms"))
            add(uw.get("derived"))
        return out

    def claimed_concepts(self) -> set[str]:
        """The pipeline concepts the record claims, wherever it claims them: its elements, its
        operationalizations and what marks its occasion's act under way."""
        from .nodeid import is_concept_id
        return {c for c in self.claimed_atoms() if is_concept_id(c)}

    def claimed_names(self) -> set[str]:
        """Claimed ids as Lean names (`family_name`); attribute values map to their atom."""
        return {c.split("=")[0].replace(".", "_") for c in self.claimed_atoms()}

    def compositions(self) -> list[dict]:
        """Every composition entry, the `definition` references included: what accounting, source
        validation, rendering and digests read."""
        return self.raw.get("compositions", [])

    def dependencies(self) -> list[dict]:
        """The compositions that are execution dependencies (every kind but `definition`): what
        ordering, scheduling, routing, integration, fencing and rule resolution follow."""
        return [c for c in self.compositions() if isinstance(c, dict) and c.get("as") != DEFINITION]

    def definition_references(self) -> list[dict]:
        """The `definition` references: the spans that borrow words from a source text."""
        return [c for c in self.compositions() if isinstance(c, dict) and c.get("as") == DEFINITION]

    def definition_sources(self) -> list[str]:
        """The source ids the record's `definition` references name, each once, in order."""
        return list(dict.fromkeys(str(c.get("source")) for c in self.definition_references() if c.get("source")))

    def params(self) -> list[str]:
        ps = list(self.raw.get("params", []))
        for o in self.raw.get("operationalizations", []):
            ps += o.get("params", [])
        return sorted(set(ps))

    def gaps(self) -> list[dict]:
        return self.raw.get("gaps", [])

    def literals(self) -> list[dict]:
        """Figures the law itself states, quoted from a span: {span, text, value, unit}."""
        return self.raw.get("literals", [])


@dataclass
class ConceptRecord:
    raw: dict[str, Any]

    def get(self, k: str, default: Any = None) -> Any:
        return self.raw.get(k, default)

    @property
    def id(self) -> str:
        return self.raw["concept_id"]

    def lean_name(self) -> str:
        return self.id.replace(".", "_")

    def args(self) -> list[dict]:
        return list(self.raw.get("args", []))

    def params(self) -> list[dict]:
        return list(self.raw.get("params", []))

    def elements(self) -> list[dict]:
        return list(self.raw.get("elements", []))

    def claimed_atoms(self) -> set[str]:
        """Atom ids the contract's elements map to (attribute values kept as `atom=value`)."""
        return {a for e in self.elements() for a in e.get("atoms", [])}

    def claimed_names(self) -> set[str]:
        return {c.split("=")[0].replace(".", "_") for c in self.claimed_atoms()}

    def refs(self) -> set[str]:
        """Concept ids the elements map to."""
        return {c for e in self.elements() for c in e.get("concepts", [])}

    def literals(self) -> list[dict]:
        return list(self.raw.get("literals", []))

    def used_by(self) -> list[str]:
        return list(self.raw.get("used_by", []))


def _records(path: Path) -> list[dict]:
    if not path.exists():
        return []
    out = []
    for i, line in enumerate(path.read_text(encoding="utf-8").splitlines()):
        if not line.strip():
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError as e:
            raise ValueError(f"{path}:{i + 1}: not JSON: {e}")
        if not isinstance(rec, dict):
            raise ValueError(f"{path}:{i + 1}: a record is a JSON object, not {type(rec).__name__}")
        out.append(rec)
    return out


def load(path: Path) -> list[Node]:
    """The node records of a blueprint file."""
    return [Node(r) for r in _records(path) if "node_id" in r]


def normalize_concept(r: dict) -> dict:
    """A concept record with its list fields in their object form: a residue written as a bare
    string, or as an object whose only text sits under a key other than `why`, becomes
    `{span, why}`."""
    out = dict(r)
    def residue(x):
        if not isinstance(x, dict):
            return {"span": "contract", "why": str(x)}
        if "why" not in x:
            texts = [v for k, v in x.items() if k != "span" and isinstance(v, str) and v.strip()]
            if len(texts) == 1:
                x = {"span": x.get("span", "contract"), "why": texts[0]}
        return x
    if isinstance(r.get("residues"), list):
        out["residues"] = [residue(x) for x in r["residues"]]
    return out


def load_concepts(path: Path) -> list[ConceptRecord]:
    """The concept records of a blueprint file."""
    return [ConceptRecord(normalize_concept(r)) for r in _records(path) if "concept_id" in r and "node_id" not in r]
