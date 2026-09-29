"""The blueprint records a plan session writes: one per node (design §2) and one per concept
(DERIVED_CONCEPTS_PLAN §5.1), in the same file, told apart by `node_id` / `concept_id`."""
from __future__ import annotations
import json
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

REQUIRED = ("node_id", "law_refs", "segmentation", "elements", "binders", "applicability", "obligation", "scenarios")
ROLES = {"trigger", "subject", "obligation", "exception", "standard", "condition", "reference", "sibling", "definitional", "boilerplate"}
SUBSTANTIVE = {"trigger", "subject", "obligation", "exception", "standard", "condition", "reference"}
SCENARIOS = {"forbid": "violated", "permit": "compliant", "idle": "not_applicable", "blind": "unknown"}
#: Spellings of a verdict tag a plan may use; the validator normalizes them to the tag.
VERDICT_SPELLINGS = {"violated": "violated", "violation": "violated", "violates": "violated",
                     "compliant": "compliant", "compliance": "compliant", "complied": "compliant",
                     "not_applicable": "not_applicable", "notapplicable": "not_applicable", "not applicable": "not_applicable", "inapplicable": "not_applicable",
                     "unknown": "unknown"}
#: How a composed rule enters this node: its applicability negated (exception), its applicability
#: (condition), or its compliance (compliance: "lawfully", "in the manner prescribed").
AS_KINDS = {"exception", "condition", "compliance"}
GAP_KINDS = {"atom", "value", "primitive", "operator", "definition", "unresolvable"}
#: A concept's witnesses: the body can hold, can fail, and stays unknown when a read atom is masked.
CONCEPT_SCENARIOS = {"holds": "compliant", "fails": "violated", "blind": "unknown"}
CONCEPT_KINDS = {"formula", "quantity"}
ARG_SORTS = {"track", "literal", "nat"}
CONCEPT_REQUIRED = ("concept_id", "kind", "contract", "args", "params", "elements", "scenarios")


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
        out: set[str] = set()
        for e in self.raw.get("elements", []):
            out.update(e.get("atoms", []))
            out.update(e.get("derived", []))
        for o in self.raw.get("operationalizations", []):
            out.update(concepts_of(o))
        return out

    def claimed_names(self) -> set[str]:
        """Claimed ids as Lean names (`family_name`); attribute values map to their atom."""
        return {c.split("=")[0].replace(".", "_") for c in self.claimed_atoms()}

    def compositions(self) -> list[dict]:
        return self.raw.get("compositions", [])

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
            out.append(json.loads(line))
        except json.JSONDecodeError as e:
            raise ValueError(f"{path}:{i + 1}: not JSON: {e}")
    return out


def load(path: Path) -> list[Node]:
    """The node records of a blueprint file."""
    return [Node(r) for r in _records(path) if "node_id" in r]


def load_concepts(path: Path) -> list[ConceptRecord]:
    """The concept records of a blueprint file."""
    return [ConceptRecord(r) for r in _records(path) if "concept_id" in r and "node_id" not in r]


def dump(path: Path, nodes: list[Node]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(n.raw, ensure_ascii=False) + "\n" for n in nodes), encoding="utf-8")
