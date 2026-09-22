"""CLI: python -m harness <command>.

  init          write the readings template, regenerate the registries, build the library
  loop          run plan → validate → code → integrate → feedback
  validate      validate A over a blueprint file, no sessions
  gate          the gate for one node (what a coding session calls)
  index         regenerate Index.lean and TrafficSpecWitness.lean
  verify        rebuild the library and run every witness
  status        the run's ledger counts
  doctor        the artifact cross-checks
  score-split   score a test run against the split's test-only atoms
"""
from __future__ import annotations
import json
import sys
from pathlib import Path
import fire
from . import paths, index_sync, lean, blueprint, corpus, ontology, validate_a
from .reading import Reading, write_template
from .state import Options
from .mapping import MappingIndex

DEFAULT_LAWS = "laws/full_list/laws.jsonl"
DEFAULT_ONTOLOGY = "ontology/ATOMS.md"


def _p(s: str) -> Path:
    p = Path(s)
    return p if p.is_absolute() else (paths.REPO / p)


class Cli:
    def init(self, reading: str = "readings/default.json") -> int:
        write_template(_p(reading))
        index_sync.write_index()
        ok, out = lean.lake_build(paths.LIBRARY)
        print("library builds" if ok else out[-2000:])
        return 0 if ok else 1

    def loop(self, run_id: str, laws: str = DEFAULT_LAWS, ontology_file: str = DEFAULT_ONTOLOGY,
             reading: str = "readings/default.json", model: str | None = None, max_iterations: int = 3,
             plan_attempts: int = 2, gate_budget: int = 6, judge: bool = True, dry_run: bool = False) -> int:
        from .loop import run_loop
        opts = Options(run_id=run_id, laws=_p(laws), ontology=_p(ontology_file), reading=_p(reading), model=model,
                       max_iterations=max_iterations, plan_attempts=plan_attempts, gate_budget=gate_budget,
                       judge=judge, dry_run=dry_run)
        print(json.dumps(run_loop(opts), indent=1))
        return 0

    def validate(self, blueprint_file: str, laws: str = DEFAULT_LAWS, ontology_file: str = DEFAULT_ONTOLOGY,
                 reading: str = "readings/default.json") -> int:
        nodes = blueprint.load(_p(blueprint_file))
        by_id = {l.id: l for l in corpus.load_laws(_p(laws))}
        outcomes = validate_a.validate(nodes, by_id, ontology.load(_p(ontology_file)), Reading(_p(reading)),
                                       MappingIndex(_p(blueprint_file).with_name("mapping.json")), {}, set())
        bad = 0
        for o in outcomes:
            print(f"{o.kind:7s} {o.node.id}")
            for r in o.reasons: print("        ", r)
            for g in o.gaps: print("   gap  ", g.get("kind"), g.get("span"), str(g.get("proposal"))[:80])
            bad += o.kind != validate_a.ACCEPT
        return 1 if bad else 0

    def gate(self, run_id: str, node_id: str) -> int:
        from .phases.code import gate_from_cli
        v = gate_from_cli(run_id, node_id)
        print(v.verdict)
        for d in v.details: print("  ", d)
        return 0 if v.verdict == "OK" else 1

    def index(self) -> int:
        index_sync.write_index(); print(f"{len(index_sync.node_ids())} rule(s) registered"); return 0

    def verify(self, reading: str = "readings/default.json") -> int:
        from .phases.integrate import verify_library
        work = paths.RESULTS / "_verify"; work.mkdir(parents=True, exist_ok=True)
        ok, problems = verify_library(work, Reading(_p(reading)))
        print("OK" if ok else "\n".join(problems)); return 0 if ok else 1

    def reopen(self, run_id: str, laws: str = "") -> int:
        """Operator action: put a run's failed laws back to `open` with a fresh attempt budget (all, or a comma list)."""
        from .ledger import Ledger
        ledger = Ledger(paths.run_dir(run_id) / "ledger.jsonl", [], 2)
        out = ledger.reopen([l.strip() for l in laws.split(",") if l.strip()] or None)
        ledger.save(); print(f"reopened {len(out)}: {', '.join(out)}"); return 0

    def status(self, run_id: str) -> int:
        f = paths.run_dir(run_id) / "summary.json"
        print(f.read_text() if f.exists() else "no run"); return 0

    def doctor(self, verbose: bool = False) -> int:
        sys.path.insert(0, str(paths.REPO))
        from scripts.diagnostics import doctor as doctor_mod
        return doctor_mod.run(paths.REPO, paths.LIBRARY, verbose)

    def split(self, use: str = "status") -> int:
        """Activate the `train` or `full` variant of the Core library, or report which is active."""
        from . import split as split_mod
        if use == "status":
            print(split_mod.active()); return 0
        copied = split_mod.activate(use)
        index_sync.write_index()
        ok, out = lean.lake_build(paths.LIBRARY)
        print(f"{use}: {len(copied)} files swapped; " + ("library builds" if ok else "BUILD FAILED\n" + out[-3000:]))
        return 0 if ok else 1

    def score_split(self, run_id: str, split_atoms: str = "laws/audit_and_scripts/split_atoms.json") -> int:
        from .score_split import score
        print(json.dumps(score(run_id, _p(split_atoms)), indent=1)); return 0


def main() -> None:
    fire.Fire(Cli)


if __name__ == "__main__":
    main()
