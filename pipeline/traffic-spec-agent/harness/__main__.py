"""CLI: python -m harness <command>.

  init          write the readings template, regenerate the registries, build the library (--fresh: archive the nodes and concepts first)
  loop          run plan → validate → code → integrate → feedback
  validate      validate A over a blueprint file, no sessions
  gate          the gate for one node (what a coding session calls)
  surface       print the generated Core surface a coding session is shown
  index         regenerate Index.lean and TrafficSpecWitness.lean (rules, concepts, witnesses)
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


def moved_name(snapshot: str) -> str:
    import datetime
    return snapshot or ("library_snapshot_" + datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S"))


def snapshot_library(snapshot: str) -> list[Path]:
    """Move every rule, concept and witness file out of the library, keeping the tree layout."""
    import shutil
    dest = paths.RESULTS / moved_name(snapshot) / "library_snapshot"
    moved: list[Path] = []
    for root in (paths.RULES_DIR, paths.CONCEPTS_DIR, paths.WITNESS_DIR):
        if not root.exists():
            continue
        for f in sorted(root.rglob("*.lean")):
            rel = f.relative_to(paths.LIBRARY)
            target = dest / rel
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(f), str(target)); moved.append(rel)
        for d in sorted((d for d in root.rglob("*") if d.is_dir()), key=lambda d: len(d.parts), reverse=True):
            if not any(d.iterdir()):
                d.rmdir()
    return moved


class Cli:
    def init(self, reading: str = "readings/default.json", fresh: bool = False, snapshot: str = "") -> int:
        """Write the readings template, regenerate the registries, build. `--fresh` first moves every
        node and concept out of the library into `results/<snapshot>/library_snapshot/` (the run they
        belong to; a timestamped name when not given), so a new run starts from an empty library."""
        write_template(_p(reading))
        if fresh:
            moved = snapshot_library(snapshot)
            print(f"moved {len(moved)} file(s) to results/{snapshot or moved_name(snapshot)}/library_snapshot/" if moved else "library already empty")
        index_sync.write_index()
        ok, out = lean.lake_build(paths.LIBRARY)
        print("library builds" if ok else out[-2000:])
        return 0 if ok else 1

    def loop(self, run_id: str, laws: str = DEFAULT_LAWS, ontology_file: str = DEFAULT_ONTOLOGY,
             reading: str = "readings/default.json", model: str | None = None, max_iterations: int = 3,
             plan_attempts: int = 2, gate_budget: int = 6, judge: bool = True, dry_run: bool = False,
             max_turns: int = 80, plan_effort: str = "high", code_effort: str = "high", judge_effort: str = "medium",
             session_budget_usd: float | None = None, session_retries: int = 2, retry_wait: float = 900.0,
             mode: str = "train", base_run: str | None = None) -> int:
        """`mode` is `train` (concepts may supersede) or `test` (add-only over `base_run`, whose accepted
        nodes and concepts are loaded read-only)."""
        from .loop import run_loop
        if mode not in ("train", "test"):
            raise SystemExit("mode must be `train` or `test`")
        if mode == "test" and not base_run:
            raise SystemExit("a test run names the training run it starts from: --base_run <run id>")
        opts = Options(run_id=run_id, laws=_p(laws), ontology=_p(ontology_file), reading=_p(reading), model=model,
                       max_iterations=max_iterations, plan_attempts=plan_attempts, gate_budget=gate_budget,
                       judge=judge, dry_run=dry_run, max_turns=max_turns, plan_effort=plan_effort or None,
                       code_effort=code_effort or None, judge_effort=judge_effort or None,
                       session_budget_usd=session_budget_usd, session_retries=session_retries, retry_wait=retry_wait,
                       mode=mode, base_run=base_run)
        print(json.dumps(run_loop(opts), indent=1))
        return 0

    def validate(self, blueprint_file: str, laws: str = DEFAULT_LAWS, ontology_file: str = DEFAULT_ONTOLOGY,
                 reading: str = "readings/default.json") -> int:
        from . import aggregates
        nodes = blueprint.load(_p(blueprint_file))
        by_id = {l.id: l for l in corpus.load_laws(_p(laws))}
        onto = ontology.load(_p(ontology_file))
        base = Reading(_p(reading))
        agg_ok, agg_errs = aggregates.validate(aggregates.load(_p(blueprint_file).with_name("aggregates.jsonl")),
                                               corpus.load_definitions(_p(laws)), onto, base)
        bad = 0
        for e in agg_errs:
            print(f"reject  aggregate: {e}"); bad += 1
        for r in agg_ok:
            print(f"accept  aggregate `{r['word']}` ← {r['definition']} ({len(r['classes'])} members)")
        concepts = blueprint.load_concepts(_p(blueprint_file))
        c_outcomes = validate_a.validate_concepts(concepts, corpus.load_definitions(_p(laws)), onto, {}, nodes)
        for o in c_outcomes:
            print(f"{o.kind:7s} concept {o.concept.id}")
            for r in o.reasons: print("        ", r)
            bad += o.kind != validate_a.ACCEPT
        outcomes = validate_a.validate(nodes, by_id, onto, base.with_aggregates(agg_ok),
                                       MappingIndex(_p(blueprint_file).with_name("mapping.json")), {}, set(),
                                       {}, [o.concept for o in c_outcomes if o.kind == validate_a.ACCEPT])
        for o in outcomes:
            print(f"{o.kind:7s} {o.node.id}")
            for r in o.reasons: print("        ", r)
            for g in o.gaps: print("   gap  ", g.get("kind"), g.get("span"), str(g.get("proposal"))[:80])
            bad += o.kind != validate_a.ACCEPT
        return 1 if bad else 0

    def gate(self, run_id: str, node_id: str) -> int:
        """The gate for one node or one concept (`node_id` is either id)."""
        from .phases.code import gate_from_cli
        v = gate_from_cli(run_id, node_id)
        print(v.verdict)
        for d in v.details: print("  ", d)
        return 0 if v.verdict == "OK" else 1

    def surface(self) -> int:
        """Print the Core surface a coding session is shown (generated from the library)."""
        from . import surface as surface_mod
        print(surface_mod.core_surface()); return 0

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
