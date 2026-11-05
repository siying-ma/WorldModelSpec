"""Where things are. One place, so a move is one edit."""
from __future__ import annotations
import sys
from contextlib import contextmanager
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]          # traffic-spec-agent/
LIBRARY = REPO / "library"
CORE = LIBRARY / "TrafficSpec" / "Core"
RULES_DIR = LIBRARY / "TrafficSpec" / "Rules"
CONCEPTS_DIR = LIBRARY / "TrafficSpec" / "Concepts"
WITNESS_DIR = LIBRARY / "TrafficSpecWitness"
CONCEPT_WITNESS_DIR = WITNESS_DIR / "Concepts"
INDEX_FILE = LIBRARY / "TrafficSpec" / "Index.lean"
WITNESS_ROOT_FILE = LIBRARY / "TrafficSpecWitness.lean"
PROMPTS = REPO / "prompts"
RESULTS = REPO / "results"
READINGS = LIBRARY / "TrafficSpec" / "Readings"     # the parameter catalogues: written by the operator and the harness, beside the rules that name them
GAPS_DIR = LIBRARY / "TrafficSpec" / "Gaps"            # the harness's ledger of what the vocabulary cannot carry, beside the rules and concepts it concerns
USER_HINTS = REPO / "USER_HINTS.md"


def library_layout(library: Path) -> dict[str, Path]:
    """Every location of this module that lies in the library, for a library at `library`."""
    ts, w = library / "TrafficSpec", library / "TrafficSpecWitness"
    return {"LIBRARY": library, "CORE": ts / "Core", "RULES_DIR": ts / "Rules", "CONCEPTS_DIR": ts / "Concepts",
            "WITNESS_DIR": w, "CONCEPT_WITNESS_DIR": w / "Concepts", "INDEX_FILE": ts / "Index.lean",
            "WITNESS_ROOT_FILE": library / "TrafficSpecWitness.lean", "READINGS": ts / "Readings", "GAPS_DIR": ts / "Gaps"}


@contextmanager
def at_library(library: Path):
    """Point every library location of this module at another library (a candidate's copy) for the
    duration, and back after. The locations are module-wide: the caller holds the process alone
    (no other thread reads them meanwhile)."""
    me = sys.modules[__name__]
    saved = {k: getattr(me, k) for k in library_layout(library)}
    for k, v in library_layout(library).items():
        setattr(me, k, v)
    try:
        yield
    finally:
        for k, v in saved.items():
            setattr(me, k, v)


def run_dir(run_id: str) -> Path:
    return RESULTS / run_id


def iter_dir(run_id: str, n: int) -> Path:
    return run_dir(run_id) / f"iter-{n:03d}"
