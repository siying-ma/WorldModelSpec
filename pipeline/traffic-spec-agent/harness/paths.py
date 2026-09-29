"""Where things are. One place, so a move is one edit."""
from __future__ import annotations
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]          # traffic-spec-agent/
LIBRARY = REPO / "library"
CORE = LIBRARY / "TrafficSpec" / "Core"
RULES_DIR = LIBRARY / "TrafficSpec" / "Rules"
CONCEPTS_DIR = LIBRARY / "TrafficSpec" / "Concepts"
WITNESS_DIR = LIBRARY / "TrafficSpecWitness"
CONCEPT_WITNESS_DIR = WITNESS_DIR / "Concepts"
INDEX_FILE = LIBRARY / "TrafficSpec" / "Index.lean"
WITNESS_ROOT_FILE = LIBRARY / "TrafficSpecWitness.lean"
ONTOLOGY_DIR = REPO / "ontology"
PROMPTS = REPO / "prompts"
RESULTS = REPO / "results"
READINGS = REPO / "readings"
GAP_LEDGER = REPO / "gaps" / "ledger.jsonl"
USER_HINTS = REPO / "USER_HINTS.md"
TO_USER = REPO / "TO_USER.md"


def run_dir(run_id: str) -> Path:
    return RESULTS / run_id


def iter_dir(run_id: str, n: int) -> Path:
    return run_dir(run_id) / f"iter-{n:03d}"
