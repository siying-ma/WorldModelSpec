"""Node identity is derived from the law id, never chosen."""
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
