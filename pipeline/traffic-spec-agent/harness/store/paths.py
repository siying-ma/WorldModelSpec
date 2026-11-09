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
#: The corpus and split tools (`nrs_tools`) the doctor runs. A run's checkout is the WorldModelSpec layout,
#: which carries them in `pipeline/ontology_provenance/`, beside this directory.
ONTOLOGY_TOOLS = REPO.parent / "ontology_provenance"


def ontology_tool(name: str) -> Path | None:
    """The source of `nrs_tools.<name>` the doctor imports: the one beside this directory
    (`ONTOLOGY_TOOLS`), else the first on the import path (`PYTHONPATH`); None when neither has it."""
    for d in [ONTOLOGY_TOOLS, *(Path(x) for x in sys.path if x)]:
        f = d / "nrs_tools" / f"{name}.py"
        if f.is_file():
            return f.resolve()
    return None


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


#: What a run's directory may hold before its first launch: the law subset `scripts/subset_laws.py`
#: writes into `results/<run>/laws/` for a run over part of the corpus.
SUBSET_FILES = {"laws.jsonl", "definitions.jsonl"}


def run_is_new(run_dir: Path) -> bool:
    """A new run id: its results directory does not exist, or holds nothing but its law subset (a
    `laws` directory of `SUBSET_FILES` only). Anything else is an existing run, resumed only on its
    own metadata. The one rule, for the loop, its command line and the launcher."""
    if not run_dir.exists():
        return True
    return all(e.name == "laws" and e.is_dir() and all(x.name in SUBSET_FILES and x.is_file() for x in e.iterdir())
               for e in run_dir.iterdir())


def iter_dir(run_id: str, n: int) -> Path:
    return run_dir(run_id) / f"iter-{n:03d}"


#: The repository roots a run's saved paths may have been written under on other machines (or in
#: other checkouts): a run records each root it ran at, and `local` maps a saved absolute path under
#: one of them to this repository.
FOREIGN_ROOTS: list[str] = []


def register_roots(roots) -> None:
    """Add the roots a run recorded (its `options.json` `repo_roots`), the longest first."""
    for r in roots or []:
        r = str(r).rstrip("/")
        if r and r != str(REPO) and r not in FOREIGN_ROOTS:
            FOREIGN_ROOTS.append(r)
    FOREIGN_ROOTS.sort(key=len, reverse=True)


def stored(p) -> str:
    """How an operational path is saved in a run's state: relative to the repository when it lies
    in it (so a clone at another root reads it), else absolute."""
    if p is None or p == "":
        return ""
    q = Path(p)
    try:
        return q.resolve().relative_to(REPO.resolve()).as_posix() if q.is_absolute() else q.as_posix()
    except ValueError:
        return str(q)


def local(s) -> Path:
    """The path a saved operational path names in this repository: a relative one is the
    repository's; an absolute one under this repository is itself; an absolute one under a root the
    run recorded (`register_roots`) is the same place under this repository, whether or not that
    other checkout is still readable here; any other is outside every checkout and keeps its meaning."""
    q = Path(str(s))
    if not q.is_absolute():
        return REPO / q
    if q == REPO or q.is_relative_to(REPO):
        return q
    for root in FOREIGN_ROOTS:
        if str(q) == root or str(q).startswith(root + "/"):
            return REPO / str(q)[len(root):].lstrip("/")
    return q
