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

DEFAULT_LAWS = "laws/example/train/laws.jsonl"
DEFAULT_ONTOLOGY = "ontology/ATOMS_train.md"
DEFAULT_READING = str((paths.READINGS / "default.json").relative_to(paths.REPO))


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


def archive_proposals(snapshot: str) -> dict[str, int]:
    """A fresh library starts from a reading without the previous run's unreviewed proposals: every
    `params` entry still marked `proposed` is moved out of each reading in `paths.READINGS` into
    `results/<snapshot>/reading_proposals.json`, so a planner is shown only what the operator wrote
    or reviewed. Returns the count removed per reading."""
    import datetime
    dest = paths.RESULTS / moved_name(snapshot) / "reading_proposals.json"
    archive = json.loads(dest.read_text(encoding="utf-8")) if dest.exists() else {}
    removed: dict[str, int] = {}
    for f in sorted(paths.READINGS.glob("*.json")):
        data = json.loads(f.read_text(encoding="utf-8"))
        keep = [x for x in data.get("params", []) if not x.get("proposed")]
        gone = [x for x in data.get("params", []) if x.get("proposed")]
        if not gone:
            continue
        data["params"] = keep
        f.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        archive.setdefault(f.name, []).extend([{**x, "archived": datetime.datetime.now().strftime("%Y-%m-%d")} for x in gone])
        removed[f.name] = len(gone)
    if removed:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(archive, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return removed


def archive_gaps(snapshot: str) -> int:
    """A fresh library starts from a gap ledger without the previous run's undecided rows: every
    row still `proposed` or `accepted` is moved to `results/<snapshot>/gaps_undecided.jsonl`; the
    decided rows (`retired`, `rejected`) and the id counter stay, so a new run is shown the
    operator's decisions and never reuses an id. Returns the count moved."""
    from .store.gaps import GapLedger
    ledger = GapLedger(paths.GAP_LEDGER)
    gone = [r for r in ledger.rows if r.get("state") in ("proposed", "accepted")]
    if not gone:
        return 0
    dest = paths.RESULTS / moved_name(snapshot) / "gaps_undecided.jsonl"
    dest.parent.mkdir(parents=True, exist_ok=True)
    with dest.open("a", encoding="utf-8") as f:
        for r in gone:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    ledger.rows = [r for r in ledger.rows if r not in gone]
    ledger.save()
    return len(gone)


class Cli:
    def init(self, reading: str = DEFAULT_READING, fresh: bool = False, snapshot: str = "") -> int:
        """Write the readings template, regenerate the registries, build. `--fresh` first moves every
        node and concept out of the library into `results/<snapshot>/library_snapshot/` (the run they
        belong to; a timestamped name when not given), and every unreviewed parameter proposal out of
        the readings into `results/<snapshot>/reading_proposals.json`, and every undecided gap row
        into `results/<snapshot>/gaps_undecided.jsonl`, so a new run starts from an empty library, a
        reading the operator wrote or reviewed, and a gap ledger of decisions only."""
        write_template(_p(reading))
        if fresh:
            snapshot = moved_name(snapshot)          # one name for the three archives, also when it is a timestamp
            moved = snapshot_library(snapshot)
            print(f"moved {len(moved)} file(s) to results/{snapshot}/library_snapshot/" if moved else "library already empty")
            gone = archive_proposals(snapshot)
            print(("archived unreviewed proposals: " + ", ".join(f"{k} ({v})" for k, v in gone.items())
                   + f" → results/{snapshot}/reading_proposals.json") if gone else "readings carry no unreviewed proposal")
            gaps_gone = archive_gaps(snapshot)
            print(f"archived {gaps_gone} undecided gap row(s) → results/{snapshot}/gaps_undecided.jsonl" if gaps_gone else "the gap ledger holds no undecided row")
        index_sync.write_index()
        ok, out = lean.lake_build(paths.LIBRARY)
        print("library builds" if ok else out[-2000:])
        return 0 if ok else 1

    def loop(self, run_id: str, laws: str = DEFAULT_LAWS, ontology_file: str = DEFAULT_ONTOLOGY,
             reading: str = DEFAULT_READING, model: str | None = None, max_iterations: int = 3,
             plan_attempts: int = 2, gate_budget: int = 6, dry_run: bool = False,
             max_turns: int = 80, plan_effort: str = "high", code_effort: str = "high", judge_effort: str = "medium",
             session_budget_usd: float | None = None, session_retries: int = 2, retry_wait: float = 900.0,
             mode: str = "train", base_run: str | None = None, plan_batch: int = 8,
             workers: int = 1, plan_turns: int = 40, restart: bool = False,
             concept_attempts: int = 3, node_attempts: int = 2, repeat_limit: int = 3,
             reviewer_model: str | None = None, review_effort: str = "high",
             allow_same_vendor: bool = False, definition_precedence: str = "config/definition_precedence.json",
             openai_budget_usd: float | None = None, reviewer_max_output_tokens: int = 64000, max_divergences: int = 3,
             model_prices: str = "config/model_prices.json", stall_stop: bool = True,
             review_checks: int = 8, review_submissions: int = 3, review_passes: int = 2) -> int:
        """`mode` is `train` (concepts may supersede) or `test` (add-only over `base_run`, whose accepted
        nodes and concepts are loaded read-only). `plan_batch` is the most laws one plan session is given;
        `workers` the coding sessions run at once;
        `reviewer_model` the second vendor's model of the behaviour review (required); `plan_turns` the turn cap of a plan or
        repair session; `restart` discards an interrupted iteration instead of resuming it; `concept_attempts`
        the coding attempts a concept gets (the first and its repairs), separate from the laws' `plan_attempts`;
        `node_attempts` the coding attempts a node gets (the first and one after a node repair session); `repeat_limit`
        the number of times the same upheld divergence on the same words of a node, across the law's plans and repairs,
        blocks the law for the operator; `definition_precedence` the operator's declared definition precedence;
        `openai_budget_usd` the run-wide limit on the second vendor's calls (reached, the run pauses and resumes under the
        same run id once raised), `reviewer_max_output_tokens` each such call's output limit, `max_divergences` the most
        divergences one review answer may carry, `model_prices` the operator's price table; `review_checks` and
        `review_submissions` the checks and the submissions of one reviewer session, `review_passes` the independent
        reviewer sessions of one rule review (their challenges joined); `stall_stop` ends the run
        after any iteration from the second on that accepts nothing and leaves no remedy awaiting its first try. Returns 0 only when the run
        ends `complete` (every law accepted, blocked or failed)."""
        from .loop import run_loop
        if mode not in ("train", "test"):
            raise SystemExit("mode must be `train` or `test`")
        if mode == "test" and not base_run:
            raise SystemExit("a test run names the training run it starts from: --base_run <run id>")
        opts = Options(run_id=run_id, laws=_p(laws), ontology=_p(ontology_file), reading=_p(reading), model=model,
                       max_iterations=max_iterations, plan_attempts=plan_attempts, gate_budget=gate_budget,
                       dry_run=dry_run, max_turns=max_turns, plan_effort=plan_effort or None,
                       code_effort=code_effort or None, judge_effort=judge_effort or None,
                       session_budget_usd=session_budget_usd, session_retries=session_retries, retry_wait=retry_wait,
                       mode=mode, base_run=base_run, plan_batch=max(1, int(plan_batch)),
                       workers=max(1, int(workers)), plan_turns=max(4, int(plan_turns)), restart=restart,
                       concept_attempts=max(1, int(concept_attempts)), node_attempts=max(1, int(node_attempts)),
                       repeat_limit=max(1, int(repeat_limit)), reviewer_model=reviewer_model, review_effort=review_effort or None,
                       allow_same_vendor=allow_same_vendor, definition_precedence=_p(definition_precedence),
                       openai_budget_usd=float(openai_budget_usd) if openai_budget_usd is not None else None,
                       reviewer_max_output_tokens=max(1, int(reviewer_max_output_tokens)), max_divergences=max(1, int(max_divergences)),
                       model_prices=_p(model_prices), stall_stop=bool(stall_stop),
                       review_checks=max(0, int(review_checks)), review_submissions=max(1, int(review_submissions)),
                       review_passes=max(1, int(review_passes)))
        result = run_loop(opts)
        print(json.dumps(result, indent=1))
        return 0 if result.get("status") == "complete" else 1

    def validate(self, blueprint_file: str = "", run_id: str = "", laws: str = DEFAULT_LAWS,
                 ontology_file: str = DEFAULT_ONTOLOGY, reading: str = DEFAULT_READING) -> int:
        """Validator A over a blueprint file, no sessions. With `--run_id` it is the check the loop
        runs: the run's accepted nodes and concepts, mapping index and reading with its admitted
        aggregates (a claim of a definition-scoped aggregate the selection has not admitted is left
        to the loop, which asks the selection role). Without a run it is context-free: no accepted
        node, concept, aggregate or mapping is known."""
        from .phases import validate as validate_phase
        from .store.state import Run
        if run_id:
            run = Run.load(run_id)
            bp = _p(blueprint_file) if blueprint_file else _latest_blueprint(run)
            plan_dir = bp.parent
            law_list = corpus.load_laws(run.opts.laws)
            defs = corpus.load_definitions(run.opts.laws)
            onto = ontology.load(run.opts.ontology)
            reading_obj = Reading(run.reading_file)
        else:
            if not blueprint_file:
                raise SystemExit("give --blueprint_file, or --run_id for a run's latest plan")
            bp = _p(blueprint_file); plan_dir = bp.parent
            law_list = corpus.load_laws(_p(laws))
            defs = corpus.load_definitions(_p(laws))
            onto = ontology.load(_p(ontology_file))
            reading_obj = Reading(_p(reading))
            run = None
        reading_obj.pending_aggregates = True
        bad = 0
        by_id = {l.id: l for l in law_list}
        # the other plan batches of the same iteration that already exist: their nodes may be composed and their
        # concepts called, as the loop's merged validation will see them
        sib_nodes, sib_concepts = [], []
        if plan_dir.name.startswith("batch-"):
            for d in sorted(plan_dir.parent.glob("batch-*")):
                if d != plan_dir and (d / "blueprint.jsonl").exists():
                    try:
                        sib_nodes += blueprint.load(d / "blueprint.jsonl"); sib_concepts += blueprint.load_concepts(d / "blueprint.jsonl")
                    except ValueError:
                        pass
        _nodes, _concepts, outcomes, c_outcomes = validate_phase.validate_a_for_run(run, plan_dir, by_id, reading_obj, defs, onto=onto, blueprint_file=bp,
                                                                                    extra_concepts=sib_concepts or None, known_nodes=sib_nodes or None)
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

    def verify(self, reading: str = DEFAULT_READING) -> int:
        from .phases.integrate import verify_library
        work = paths.RESULTS / "_verify"; work.mkdir(parents=True, exist_ok=True)
        ok, problems = verify_library(work, Reading(_p(reading)))
        print("OK" if ok else "\n".join(problems)); return 0 if ok else 1

    def reopen(self, run_id: str, laws: str = "") -> int:
        """Operator action: put a run's failed laws (or any law not accepted or blocked on a gap) back to `open`
        with a fresh attempt budget (all, or a comma list); a failed concept only those laws used is cleared."""
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
        # a failed concept that only the reopened laws used gets a fresh start with them
        from .store.ledger import ConceptLedger
        cfile = paths.run_dir(run_id) / "concept_ledger.jsonl"
        freed: list[str] = []
        if cfile.exists() and out:
            from .model import nodeid
            cl = ConceptLedger(cfile, 1)
            freed = [cid for cid, e in cl.entries.items() if e.state == "failed" and e.used_by
                     and all(nodeid.law_of(str(u))[0] in out for u in e.used_by)]
            cl.forget(freed); cl.save()
        print(f"reopened {len(out)}: {', '.join(out)}" + (f"; failed concepts cleared: {', '.join(freed)}" if freed else "")); return 0

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
