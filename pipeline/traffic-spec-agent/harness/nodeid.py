"""Node identity is derived from the law id, never chosen. A concept's id is chosen by the plan in
the fixed grammar `drv.<family>.<name>`; its paths follow from the id."""
from __future__ import annotations
import re

IDENT = re.compile(r"^[A-Za-z][A-Za-z0-9_]*$")


def derive(law_id: str, ordinal: int = 1, total: int = 1) -> str:
    base = law_id.replace("-", "_")
    if not IDENT.match(base):
        raise ValueError(f"law id {law_id!r} does not derive a Lean identifier")
    return base if total <= 1 else f"{base}_o{ordinal}"


def law_of(node_id: str) -> tuple[str, int]:
    """The law id (as spelled in the corpus) and ordinal a node id derives from."""
    m = re.match(r"^(.*?)(?:_o(\d+))?$", node_id)
    base, o = m.group(1), int(m.group(2) or 1)
    return base.replace("_", "-"), o


def body(node_id: str) -> str:
    """The source-body prefix, for grouping files: the first two id segments (a body and a chapter)."""
    parts = node_id.split("_")
    return "_".join(parts[:2]) if len(parts) >= 2 else parts[0]


def rule_module(node_id: str) -> str:
    return f"TrafficSpec.Rules.{body(node_id)}.{node_id}"


def rule_path(node_id: str) -> str:
    return f"TrafficSpec/Rules/{body(node_id)}/{node_id}.lean"


def rule_namespace(node_id: str) -> str:
    return f"TrafficSpec.Rules.{node_id}"


def witness_module(node_id: str) -> str:
    return f"TrafficSpecWitness.{body(node_id)}.{node_id}"


def witness_path(node_id: str) -> str:
    return f"TrafficSpecWitness/{body(node_id)}/{node_id}.lean"


def witness_namespace(node_id: str) -> str:
    return f"TrafficSpecWitness.{node_id}"


# ---------------------------------------------------------------------------------------------
# Concepts: `drv.<family>.<name>`, files under Concepts/<family>/<name>.lean
# ---------------------------------------------------------------------------------------------
CONCEPT_FAMILIES = ("motion", "position", "lane", "interaction", "road", "control", "user", "env")
CONCEPT_ID = re.compile(r"^drv\.(" + "|".join(CONCEPT_FAMILIES) + r")\.([a-z][a-z_]*[a-z])(_v[1-9]\d*)?$")


def is_concept_id(ident: str) -> bool:
    return bool(CONCEPT_ID.match(ident))


def concept_parts(cid: str) -> tuple[str, str]:
    """(family, name) of a well-formed concept id; the name keeps its `_v<n>` suffix."""
    m = CONCEPT_ID.match(cid)
    if not m:
        raise ValueError(f"{cid!r} is not a concept id (drv.<family>.<name>)")
    return m.group(1), m.group(2) + (m.group(3) or "")


def concept_lean_name(cid: str) -> str:
    return cid.replace(".", "_")


def concept_module(cid: str) -> str:
    fam, name = concept_parts(cid)
    return f"TrafficSpec.Concepts.{fam}.{name}"


def concept_path(cid: str) -> str:
    fam, name = concept_parts(cid)
    return f"TrafficSpec/Concepts/{fam}/{name}.lean"


def concept_namespace(cid: str) -> str:
    return concept_module(cid)


def concept_witness_module(cid: str) -> str:
    fam, name = concept_parts(cid)
    return f"TrafficSpecWitness.Concepts.{fam}.{name}"


def concept_witness_path(cid: str) -> str:
    fam, name = concept_parts(cid)
    return f"TrafficSpecWitness/Concepts/{fam}/{name}.lean"


def concept_witness_namespace(cid: str) -> str:
    return concept_witness_module(cid)


def concept_id_of_path(path: str) -> str:
    """The concept id a `Concepts/<family>/<name>.lean` path carries (either tree)."""
    parts = path.replace("\\", "/").split("/")
    i = parts.index("Concepts")
    return "drv." + parts[i + 1] + "." + parts[i + 2].removesuffix(".lean")
