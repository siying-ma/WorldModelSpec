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
from .store import paths
from .lean import index_sync, lean
from .model import blueprint, corpus, ontology
from .checks import validate_a
from .model.reading import Reading, write_template
from .store.state import Options
from .model.mapping import MappingIndex

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
             mode: str = "train", base_run: str | None = None, plan_batch: int = 8, judge_samples: int = 1,
             workers: int = 1, reader_model: str | None = None, plan_turns: int = 40, restart: bool = False,
             concept_attempts: int = 3, node_attempts: int = 2) -> int:
        """`mode` is `train` (concepts may supersede) or `test` (add-only over `base_run`, whose accepted
        nodes and concepts are loaded read-only). `plan_batch` is the most laws one plan session is given;
        `judge_samples` the number of independent judge sessions a node's review runs; `workers` the coding
        sessions run at once; `reader_model` the blind reader's model; `plan_turns` the turn cap of a plan or
        repair session; `restart` discards an interrupted iteration instead of resuming it; `concept_attempts`
        the coding attempts a concept gets (the first and its repairs), separate from the laws' `plan_attempts`;
        `node_attempts` the coding attempts a node gets (the first and one after a node repair session)."""
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
                       mode=mode, base_run=base_run, plan_batch=max(1, int(plan_batch)), judge_samples=max(1, int(judge_samples)),
                       workers=max(1, int(workers)), reader_model=reader_model, plan_turns=max(4, int(plan_turns)), restart=restart,
                       concept_attempts=max(1, int(concept_attempts)), node_attempts=max(1, int(node_attempts)))
        print(json.dumps(run_loop(opts), indent=1))
        return 0

    def validate(self, blueprint_file: str = "", run_id: str = "", laws: str = DEFAULT_LAWS,
                 ontology_file: str = DEFAULT_ONTOLOGY, reading: str = "readings/default.json") -> int:
        """Validator A over a blueprint file, no sessions. With `--run_id` it is the check the loop
        runs: the run's accepted nodes and concepts, mapping index, reading (with the draft's
        `aggregates.jsonl` applied) and the `PLAN.md` disputes beside the blueprint. Without a run it
        is context-free: no accepted node, concept or mapping is known, so a composition of an
        accepted node or a call of a catalogued concept is reported as unknown."""
        from .checks import aggregates
        from .phases import validate as validate_phase
        from .store.state import Run
        if run_id:
            run = Run.load(run_id)
            bp = _p(blueprint_file) if blueprint_file else _latest_blueprint(run)
            plan_dir = bp.parent
            law_list = corpus.load_laws(run.opts.laws)
            defs = corpus.load_definitions(run.opts.laws)
            onto = ontology.load(run.opts.ontology)
            agg_ok, agg_errs = aggregates.validate(aggregates.load(plan_dir / "aggregates.jsonl"), defs, onto, Reading(run.opts.reading))
            reading_obj = Reading(run.reading_file).with_aggregates(agg_ok)
        else:
            if not blueprint_file:
                raise SystemExit("give --blueprint_file, or --run_id for a run's latest plan")
            bp = _p(blueprint_file); plan_dir = bp.parent
            law_list = corpus.load_laws(_p(laws))
            defs = corpus.load_definitions(_p(laws))
            onto = ontology.load(_p(ontology_file))
            agg_ok, agg_errs = aggregates.validate(aggregates.load(plan_dir / "aggregates.jsonl"), defs, onto, Reading(_p(reading)))
            reading_obj = Reading(_p(reading)).with_aggregates(agg_ok)
            run = None
        bad = 0
        for e in agg_errs:
            print(f"reject  aggregate: {e}"); bad += 1
        for r in agg_ok:
            print(f"accept  aggregate `{r['word']}` ← {r['definition']} ({len(r['classes'])} members)")
        by_id = {l.id: l for l in law_list}
        _nodes, _concepts, outcomes, c_outcomes = validate_phase.validate_a_for_run(run, plan_dir, by_id, reading_obj, defs, onto=onto, blueprint_file=bp)
        for o in c_outcomes:
            print(f"{o.kind:7s} concept {o.concept.id}")
            for r in o.reasons: print("        ", r)
            bad += o.kind != validate_a.ACCEPT
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
        from .lean import surface as surface_mod
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
        from .store.ledger import Ledger
        ledger = Ledger(paths.run_dir(run_id) / "ledger.jsonl", [], 2)
        out = ledger.reopen([l.strip() for l in laws.split(",") if l.strip()] or None)
        ledger.save()
        # a reopened law is planned afresh: its held nodes and its node-repair entries are dropped
        dfile = paths.run_dir(run_id) / "deferred_nodes.jsonl"
        if dfile.exists():
            kept = [l for l in dfile.read_text(encoding="utf-8").splitlines() if l.strip() and not (set(json.loads(l).get("law_refs", [])) & set(out))]
            dfile.write_text("".join(k + "\n" for k in kept), encoding="utf-8")
        nfile = paths.run_dir(run_id) / "node_ledger.jsonl"
        if nfile.exists():
            kept = [l for l in nfile.read_text(encoding="utf-8").splitlines() if l.strip() and json.loads(l).get("law") not in out]
            nfile.write_text("".join(k + "\n" for k in kept), encoding="utf-8")
        print(f"reopened {len(out)}: {', '.join(out)}"); return 0

    def status(self, run_id: str) -> int:
        f = paths.run_dir(run_id) / "summary.json"
        print(f.read_text() if f.exists() else "no run"); return 0

    def doctor(self, verbose: bool = False) -> int:
        sys.path.insert(0, str(paths.REPO))
        from scripts.diagnostics import doctor as doctor_mod
        return doctor_mod.run(paths.REPO, paths.LIBRARY, verbose)

    def split(self, use: str = "status") -> int:
        """Activate the `train` or `full` variant of the Core library, or report which is active."""
        from .tools import split as split_mod
        if use == "status":
            print(split_mod.active()); return 0
        copied = split_mod.activate(use)
        index_sync.write_index()
        ok, out = lean.lake_build(paths.LIBRARY)
        print(f"{use}: {len(copied)} files swapped; " + ("library builds" if ok else "BUILD FAILED\n" + out[-3000:]))
        return 0 if ok else 1

    def score_split(self, run_id: str, split_atoms: str = "laws/audit_and_scripts/split_atoms.json") -> int:
        from .tools.score_split import score
        print(json.dumps(score(run_id, _p(split_atoms)), indent=1)); return 0


def _latest_blueprint(run) -> Path:
    iters = sorted(p for p in run.dir.glob("iter-*") if (p / "plan" / "blueprint.jsonl").exists())
    if not iters:
        raise SystemExit(f"run `{run.opts.run_id}` has no plan yet; give --blueprint_file")
    return iters[-1] / "plan" / "blueprint.jsonl"


def main() -> None:
    fire.Fire(Cli)


if __name__ == "__main__":
    main()
