"""CLI: python -m harness <command>.

  init          write the readings template, regenerate the registries, build the library (--fresh: archive the nodes and concepts first)
  loop          run plan → validate → code → integrate → feedback
  validate      validate A over a blueprint file, no sessions
  gate          the gate for one node (what a coding session calls)
  surface       print the generated Core surface a coding session is shown
  index         regenerate Index.lean and TrafficSpecWitness.lean (rules, concepts, witnesses)
  verify        rebuild the library and run every witness, against a run's reading
  label_check   score a run's frozen library on the labelled training recordings
  status        the run's ledger counts
  reopen        put a run's failed or decision-blocked laws back to open
  gap           list the gaps, or record the operator's decision on one
  split         activate the train or full variant of Core
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

DEFAULT_LAWS = "laws/example/train/laws.jsonl"
DEFAULT_ONTOLOGY = "ontology/ATOMS_train.md"
DEFAULT_READING = str((paths.READINGS / "default.json").relative_to(paths.REPO))
DEFAULT_DATASET = "../datasets/demo-accepted-191-core-v2-train"


def _candidate_view(run):
    """The run as the candidate a session runs in holds it (its environment names the candidate's
    directory): its records, reading, mapping index and library; the run itself otherwise."""
    import os
    from .phases import candidate
    area = os.environ.get(candidate.CANDIDATE_ENV)
    if not area:
        return run
    sc = json.loads((Path(area) / "scope.json").read_text(encoding="utf-8"))
    view = candidate._view(run, Path(area), Path(sc["base_reading"]))
    view.accepted_nodes, view.accepted_concepts = sc["accepted_nodes"], sc["accepted_concepts"]
    for k, v in paths.library_layout(Path(sc["tree"]) / "library").items():
        setattr(paths, k, v)                           # this command reads the candidate's library, for its whole life
    return view


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
    `params` and `declarations` entry still marked `proposed` is moved out of each reading in
    `paths.READINGS` into `results/<snapshot>/reading_proposals.json` (a declaration under
    `<reading>#declarations`), so a planner is shown only what the operator wrote or reviewed.
    Returns the count removed per reading."""
    import datetime
    dest = paths.RESULTS / moved_name(snapshot) / "reading_proposals.json"
    archive = json.loads(dest.read_text(encoding="utf-8")) if dest.exists() else {}
    removed: dict[str, int] = {}
    for f in sorted(paths.READINGS.glob("*.json")):
        data = json.loads(f.read_text(encoding="utf-8"))
        keep = [x for x in data.get("params", []) if not x.get("proposed")]
        gone = [x for x in data.get("params", []) if x.get("proposed")]
        keep_d = [x for x in data.get("declarations", []) if not x.get("proposed")]
        gone_d = [x for x in data.get("declarations", []) if x.get("proposed")]
        if not gone and not gone_d:
            continue
        data["params"] = keep
        if "declarations" in data:
            data["declarations"] = keep_d
        f.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        day = datetime.datetime.now().strftime("%Y-%m-%d")
        if gone:
            archive.setdefault(f.name, []).extend([{**x, "archived": day} for x in gone])
        if gone_d:
            archive.setdefault(f"{f.name}#declarations", []).extend([{**x, "archived": day} for x in gone_d])
        removed[f.name] = len(gone) + len(gone_d)
    if removed:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(json.dumps(archive, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return removed


class Cli:
    def init(self, reading: str = DEFAULT_READING, fresh: bool = False, snapshot: str = "") -> int:
        """Write the readings template, regenerate the registries, build. `--fresh` first moves every
        node and concept out of the library into `results/<snapshot>/library_snapshot/` (the run they
        belong to; a timestamped name when not given), and every unreviewed parameter proposal out of
        the readings into `results/<snapshot>/reading_proposals.json`, and moves every resolved gap to
        `results/<the run that proposed it>/gaps.jsonl`, so a new run starts from an empty library, a
        reading the operator wrote or reviewed, and an empty gap ledger. It refuses, before it moves
        anything, while a gap is open: the last round's gaps are decided first."""
        from .store import owner
        from .store.gaps import GapLedger
        owner.acquire_for_command("init")
        gone_gaps = GapLedger(paths.GAPS_DIR).start_round(paths.RESULTS) if fresh else []   # first: it refuses before anything moves
        write_template(_p(reading))
        if fresh:
            snapshot = moved_name(snapshot)          # one name for the archives, also when it is a timestamp
            moved = snapshot_library(snapshot)
            print(f"moved {len(moved)} file(s) to results/{snapshot}/library_snapshot/" if moved else "library already empty")
            gone = archive_proposals(snapshot)
            print(("archived unreviewed proposals: " + ", ".join(f"{k} ({v})" for k, v in gone.items())
                   + f" → results/{snapshot}/reading_proposals.json") if gone else "readings carry no unreviewed proposal")
            print(("archived resolved gap(s): " + ", ".join(f"{g} → results/{r}/gaps.jsonl" for g, r in gone_gaps))
                  if gone_gaps else "the gap ledger is empty")
        index_sync.write_index()
        code, out = lean.lake_build(paths.LIBRARY); ok = code == 0
        print("library builds" if ok else out[-2000:])
        return 0 if ok else 1

    def loop(self, run_id: str, **given) -> int:
        """Run the loop. Every option of `Options` may be given as `--<name> <value>`; an option left
        out takes the value the run's saved `options.json` holds (a resume), else its default. An
        option given explicitly counts as given even when it equals the default. A resume whose
        corpus, ontology, Core, prompts, base reading or base run differ from the saved run stops
        before any record is rewritten (the loop checks the digests).

        The options: `laws`, `ontology_file`, `reading`, `model`; `mode` (`train`: concepts may
        supersede; `test`: add-only over `base_run`, read-only); `max_iterations` (iterations, not
        launches); `plan_attempts`, `concept_attempts`, `node_attempts` (the attempt budgets);
        `repeat_limit` (consecutive open counts of one upheld case that block its law for the
        operator); `gate_budget`; `plan_batch`, `workers`, `plan_turns`, `max_turns`, `session_timeout`;
        `model` (the Claude model of every planning, coding and judge session); the efforts; `session_budget_usd`, `repair_budget_usd`, `judge_budget_usd` (each role's cap), `session_retries`, `retry_wait`; `reviewer_model`
        (required), `review_effort`, `allow_same_vendor`, `review_checks`, `review_submissions`,
        `review_passes`, `max_divergences`, `reviewer_max_output_tokens`, `openai_budget_usd`,
        `model_prices`; `feedback` (`review`: a node is accepted on its behaviour review; `labels`: that review
        and its Stage A/B are suspended, the concept review stays, the frozen library is scored by `label_check`),
        `aggregate_verifier_model` (required under `labels`), `aggregate_verifier_effort`,
        `aggregate_verifier_budget_usd`; `label_repair` (under `labels`: each law whose plan is gated is checked on
        the training recordings inside the loop and routed by its outcome) with `label_dataset` (those recordings,
        by default the training package); `definition_precedence`; `restart` (discard an interrupted iteration);
        `dry_run`; `force_takeover`. Returns 0 only when the run ends `complete`."""
        from dataclasses import fields
        from .loop import run_loop
        names = {f.name for f in fields(Options)} | {"ontology_file"}
        unknown = sorted(set(given) - names)
        if unknown:
            raise SystemExit(f"unknown option(s): {', '.join(unknown)}")
        if "ontology_file" in given:
            given["ontology"] = given.pop("ontology_file")
        saved_f = paths.run_dir(run_id) / "options.json"
        saved = json.loads(saved_f.read_text(encoding="utf-8")) if saved_f.exists() else {}
        if saved.get("base_reading"):
            saved["reading"] = saved["base_reading"]
        kw = {k: v for k, v in saved.items() if k in names and k not in ("run_id", "restart", "force_takeover", "dry_run")}
        kw.update(given)
        kw.setdefault("laws", DEFAULT_LAWS); kw.setdefault("ontology", DEFAULT_ONTOLOGY); kw.setdefault("reading", DEFAULT_READING)
        if kw.get("label_repair") and not kw.get("label_dataset"):
            kw["label_dataset"] = DEFAULT_DATASET
        for k in ("laws", "ontology", "reading", "definition_precedence", "model_prices", "label_dataset"):
            if kw.get(k):
                kw[k] = _p(str(kw[k]))
        if kw.get("label_dataset"):
            kw["label_dataset"] = str(kw["label_dataset"])
        kw.setdefault("definition_precedence", _p("config/definition_precedence.json"))
        kw.setdefault("model_prices", _p("config/model_prices.json"))
        for k in ("plan_effort", "code_effort", "judge_effort", "review_effort", "aggregate_verifier_effort"):
            if k in kw:
                kw[k] = kw[k] or None
        opts = Options(run_id=run_id, **kw)
        if opts.mode not in ("train", "test"):
            raise SystemExit("mode must be `train` or `test`")
        if opts.mode == "test" and not opts.base_run:
            raise SystemExit("a test run names the training run it starts from: --base_run <run id>")
        for k, lo in (("plan_batch", 1), ("workers", 1), ("plan_turns", 4), ("concept_attempts", 1), ("node_attempts", 1),
                      ("repeat_limit", 1), ("reviewer_max_output_tokens", 1), ("max_divergences", 1), ("review_checks", 0),
                      ("review_submissions", 1), ("review_passes", 1)):
            setattr(opts, k, max(lo, int(getattr(opts, k))))
        if opts.openai_budget_usd is not None:
            opts.openai_budget_usd = float(opts.openai_budget_usd)
        if opts.aggregate_verifier_budget_usd is not None:
            opts.aggregate_verifier_budget_usd = float(opts.aggregate_verifier_budget_usd)
        opts.session_timeout = float(opts.session_timeout)
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
            run = _candidate_view(run)                 # a plan session run inside a candidate validates against the candidate
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
        # the draft's own law-local aggregates: checked for structure and ownership, and those that pass are pending
        from .checks import aggregates as agg_checks
        draft_laws = {n.law for n in blueprint.load(bp) if isinstance(n.get("law_refs"), list) and n.get("law_refs")}
        reading_obj.pending_ids = set()
        try:
            draft_aggs = agg_checks.load(plan_dir / "aggregates.jsonl")
        except ValueError as e:
            print(f"reject  aggregates.jsonl: {e}"); bad += 1; draft_aggs = []
        for r in draft_aggs:
            aid = str(r.get("aggregate_id", "")) if isinstance(r, dict) else ""
            law_id = aid.split(":", 1)[0]
            errs = ([f"`{aid}` is not a law-local id `<law id>:<span>::<term>`"] if not agg_checks.law_local(aid) else
                    [f"`{aid}` belongs to {law_id}, which has no node in this draft"] if law_id not in draft_laws or law_id not in by_id else
                    agg_checks.record_defects(r, onto, {law_id: " ".join(by_id[law_id].text.split())}))
            if errs:
                print(f"reject  aggregate {aid}")
                for e in errs: print("        ", e)
                bad += 1
            else:
                reading_obj.pending_ids.add(aid)
        # the other plan batches of the same iteration that already exist: their nodes may be composed and their
        # concepts called, as the loop's merged validation will see them
        sib_nodes, sib_concepts, prior_nodes = [], [], []
        if plan_dir.name.startswith("batch-"):
            for d in sorted(plan_dir.parent.glob("batch-*")):
                if d != plan_dir and (d / "blueprint.jsonl").exists():
                    try:
                        got = blueprint.load(d / "blueprint.jsonl")
                        sib_nodes += got; sib_concepts += blueprint.load_concepts(d / "blueprint.jsonl")
                        if d.name < plan_dir.name:       # the loop validates the batches in this order
                            prior_nodes += got
                    except ValueError:
                        pass
        _nodes, _concepts, outcomes, c_outcomes = validate_phase.validate_a_for_run(run, plan_dir, by_id, reading_obj, defs, onto=onto, blueprint_file=bp,
                                                                                    extra_concepts=sib_concepts or None, known_nodes=sib_nodes or None,
                                                                                    prior_nodes=prior_nodes or None)
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
        """The gate for one node or one concept (`node_id` is either id). Run from a coding session,
        it passes only while the run that started the session owns the library; run on its own, it
        takes the library like any mutating command."""
        import os
        from .phases.code import gate_from_cli
        from .store import owner
        if os.environ.get(owner.ENV):
            owner.check_delegated()
        else:
            owner.acquire_for_command("gate")
        v = gate_from_cli(run_id, node_id)
        print(v.verdict)
        for d in v.details: print("  ", d)
        return 0 if v.verdict == "OK" else 1

    def surface(self) -> int:
        """Print the Core surface a coding session is shown (generated from the library)."""
        from .lean import surface as surface_mod
        print(surface_mod.core_surface()); return 0

    def index(self) -> int:
        """Regenerate the registries; it takes the library like any mutating command."""
        from .store import owner
        owner.acquire_for_command("index")
        index_sync.write_index(); print(f"{len(index_sync.node_ids())} rule(s) registered"); return 0

    def label_check(self, run_id: str, dataset: str = DEFAULT_DATASET, laws: str = "", jobs: int = 4,
                    deadline_s: float = 900, memory_gb: float = 24, explain_s: float = 300) -> int:
        """Score a run's frozen library on the training recordings: every law of the run's corpus that
        the dataset holds, its accepted rules run on each of its recordings (`harness/phases/label_check.py`),
        each law's outcome (aligned, mismatch, failed, unverified) and the evidence for every eligible
        recording that does not match. Run once the loop has stopped; nothing it finds reaches a plan,
        a repair or the run's notes. Writes `results/<run>/label_check/`: `summary.json` (the versions
        it is bound to and every law's outcome and coverage), `laws/<law>.json`, `evidence/<law>.md`,
        `judgment_calls.json`, and the whole Explain reports under `explain/`. Each law's record and its
        summary line also carry the source report of its recordings (`recorded/source_check.py`, kept
        once per recording in the run's `source_check.json`), which changes no outcome."""
        import hashlib
        from .phases import label_check as lc
        from .store import owner
        from .store.state import Run
        from .model.blueprint import Node
        from .loop import semantic_inputs
        from recorded import dataset as dataset_mod, source_check
        owner.acquire_for_command("label_check")
        run = Run.load(run_id)
        moved = lc.drift(run.dir)
        if moved:
            raise SystemExit("the library is not the one the run left; nothing is scored:\n  " + "\n  ".join(moved[:20])
                             + (f"\n  … and {len(moved) - 20} more" if len(moved) > 20 else ""))
        ds = dataset_mod.Dataset(_p(dataset))
        ledger = {e["law"]: e for e in (json.loads((run.dir / "state.json").read_text(encoding="utf-8")).get("ledger") or [])}
        accepted = {nid for nid, rec in run.all_nodes().items() if not rec.get("fenced")}
        corpus_laws = {l.id for l in corpus.load_laws(run.opts.laws)}
        wanted = [x for x in str(laws).split(",") if x] if laws else sorted({r["law_id"] for r in ds.rows} & corpus_laws)
        code, out = lean.lake_build(paths.LIBRARY, targets=["monitor", "explain"])
        if code != 0:
            raise SystemExit("the monitor or explain does not build:\n" + out[-2000:])
        bin_ = paths.LIBRARY / ".lake/build/bin"
        sha = lambda f: hashlib.sha256(Path(f).read_bytes()).hexdigest()
        out_dir = paths.run_dir(run_id) / "label_check"
        lim = lc.Limits(deadline_s=float(deadline_s), memory_gb=float(memory_gb), explain_s=float(explain_s), jobs=int(jobs))
        results, judgment = {}, []
        rows = [r for r in ds.rows if r["law_id"] in set(wanted)]
        sources = source_check.ensure(run.dir / "source_check.json", ds, [r["recording_id"] for r in rows],
                                      {r["recording_id"]: {"trace": r["trace_sha256"], "manifest": r["manifest_sha256"]} for r in rows},
                                      jobs=lc.SOURCE_CHECK_JOBS)
        frozen_sha = hashlib.sha256((run.dir / "frozen" / "manifest.json").read_bytes()).hexdigest()
        for law in wanted:
            entry = ledger.get(law, {})
            rules = sorted(entry.get("nodes") or [])                 # the law's final plan, accepted or not
            unavailable = {r: ("fenced" if r in run.fenced else f"not accepted; the law is {entry.get('state')}")
                           for r in rules if r not in accepted}
            chk = lc.check_law(law, rules, {r: law for r in rules}, ds, bin_ / "monitor", bin_ / "explain",
                               run.reading_file, lim, out_dir / "explain", unavailable)
            chk.source_check = source_check.summary({r["recording_id"]: sources.get(r["recording_id"]) for r in rows if r["law_id"] == law})
            (out_dir / "laws").mkdir(parents=True, exist_ok=True)
            (out_dir / "evidence").mkdir(parents=True, exist_ok=True)
            (out_dir / "laws" / f"{law}.json").write_text(json.dumps(chk.to_dict(), indent=1) + "\n", encoding="utf-8")
            (out_dir / "evidence" / f"{law}.md").write_text(lc.render_evidence(chk), encoding="utf-8")
            judgment += lc.judgment_table(chk)
            results[law] = {"outcome": chk.outcome, "rules": rules, "not_run": unavailable, **chk.coverage,
                            "counts": chk.summary["counts"], "notes": chk.notes,
                            "source_check": {k: v for k, v in chk.source_check.items() if k != "per_recording"}}
            print(f"{law:22s} {chk.outcome:10s} rules {len(rules)}  plain {chk.coverage['matched']}/{chk.coverage['eligible']} match")
        summary = {"run": run_id, "data_version": ds.data_version, "dataset": str(_p(dataset)), "frozen_manifest_sha256": frozen_sha,
                   "semantic_inputs": semantic_inputs(run.opts),
                   "monitor_sha256": sha(bin_ / "monitor"), "explain_sha256": sha(bin_ / "explain"),
                   "reading_sha256": sha(run.reading_file), "limits": lim.__dict__,
                   "outcomes": {k: sum(v["outcome"] == k for v in results.values()) for k in lc.OUTCOMES}, "laws": results}
        (out_dir / "summary.json").write_text(json.dumps(summary, indent=1) + "\n", encoding="utf-8")
        (out_dir / "judgment_calls.json").write_text(json.dumps(judgment, indent=1) + "\n", encoding="utf-8")
        print(json.dumps(summary["outcomes"]))
        return 0

    def verify(self, run_id: str) -> int:
        """Evaluate a run's own context: every accepted record of its effective view (its base
        chain's and its own) held to today's gates, a record the gate rejects fenced with what calls
        it; then the active selection (every record not fenced) in the registries, every witness
        against the run's reading, the accepted records whose files the library lacks, and those
        whose dependency context changed (their obligations certified again). The active selection's
        result and each fenced record's recorded failure are reported apart; exits 0 only when the
        active selection verifies and nothing is fenced."""
        from .phases.integrate import verify_library, recheck_contexts, admission_recheck, fence_closure, AdmissionUnavailable
        from .store import owner
        from .store.state import Run
        from .loop import semantic_inputs, refresh_inactive, effective_laws, context_base
        from .model import nodeid
        owner.acquire_for_command("verify")
        run = Run.load(run_id)
        reading = Reading(run.reading_file)
        sem = semantic_inputs(run.opts)
        work = paths.RESULTS / "_verify"; work.mkdir(parents=True, exist_ok=True)
        try:
            admission_recheck(run, reading, {"core": sem["core"], "ontology": sem["ontology"]})
        except AdmissionUnavailable as e:
            print(f"infrastructure: the admission recheck did not run: {e}"); return 1
        _ok, failing, unresolved = recheck_contexts(run, reading, context_base(run.opts, sem),
                                                    effective_laws(run, {l.id: l for l in corpus.load_laws(run.opts.laws)}))
        fence_closure(run)
        refresh_inactive(run)
        active_nodes = sorted(i for i in run.all_nodes() if i not in run.fenced)
        active_concepts = sorted(c for c in run.all_concepts() if c not in run.fenced)
        missing = [i for i in active_nodes if not (paths.LIBRARY / nodeid.rule_path(i)).exists()]
        missing += [c for c in active_concepts if not (paths.LIBRARY / nodeid.concept_path(c)).exists()]
        status, problems, _owners = verify_library(work, reading, active_nodes, active_concepts)
        problems = problems + [f"accepted, but its files are not in the library: `{i}`" for i in missing] + failing + unresolved
        good = status == "verified" and not missing and not failing and not unresolved
        print(f"active selection ({len(active_nodes)} node(s), {len(active_concepts)} concept(s)): "
              + ("OK" if good else f"{status}\n" + "\n".join(problems)))
        if run.fenced:
            print(f"fenced ({len(run.fenced)}), each with its recorded failure:")
            for ident, ev in sorted(run.fenced.items()):
                print(f"  `{ident}` ({ev.get('kind')}, {ev.get('reason')}): {str(ev.get('evidence', ''))[:400]}")
        return 0 if good and not run.fenced else 1

    def reopen(self, run_id: str, laws: str = "") -> int:
        """Operator action: put a run's failed laws (or any law not accepted or blocked on a gap) back to `open`
        with a fresh attempt budget (all, or a comma list); a failed concept only those laws used is cleared, and
        a concept's gate-cost counts and hold start again once none of the laws its hold paused is still paused;
        a concept still held is named with the laws it still waits on."""
        from .store import owner
        from .store.ledger import Ledger, ConceptLedger, NodeLedger
        from .store.state import Run, commit_state
        from .model import nodeid
        owner.acquire_for_command("reopen")
        run = Run.load(run_id)                    # the projections are completed from the run's snapshot first
        ledger = Ledger(run.ledger_file, [], run.opts.plan_attempts)
        node_ledger = NodeLedger(run.node_ledger_file, run.opts.node_attempts)
        concept_ledger = ConceptLedger(run.concept_ledger_file, run.opts.concept_attempts)
        names = laws if isinstance(laws, (list, tuple)) else str(laws).split(",")   # the command line may give a list
        out = ledger.reopen([str(l).strip() for l in names if str(l).strip()] or None)
        # a reopened law is planned afresh: its held nodes and its node entries (repairs, judge counts) are dropped
        run.deferred_nodes = [d for d in run.deferred_nodes if not (set(d.get("law_refs", [])) & set(out))]
        for law in out:
            node_ledger.drop_law(law)
        # a failed concept that only the reopened laws used gets a fresh start with them
        freed = [cid for cid, e in concept_ledger.entries.items() if e.state == "failed" and e.used_by
                 and all(nodeid.law_of(str(u))[0] in out for u in e.used_by)]
        concept_ledger.forget(freed)
        released, waiting = concept_ledger.release(out, ledger.paused())
        commit_state(run, ledger, concept_ledger, node_ledger)
        print(f"reopened {len(out)}: {', '.join(out)}" + (f"; failed concepts cleared: {', '.join(freed)}" if freed else "")
              + (f"; concepts released from their gate-cost hold: {', '.join(released)}" if released else "")
              + "".join(f"; concept {cid} stays held: the laws its hold paused still wait ({', '.join(ls)}); reopen them too, "
                        f"before the next loop, to release it (python -m harness reopen {run_id} --laws {','.join(ls)})"
                        for cid, ls in waiting.items())); return 0

    def gap(self, action: str = "list", gap_id: str = "", state: str = "", decision: str = "", retired_by: str = "",
            resolved_by: str = "", manifest: str = "") -> int:
        """`gap list` prints every gap with its latest decision; `gap decide <id> --state
        retired|rejected|accepted --decision "<words>"` appends the operator's decision (the only
        writer of decisions; the harness appends proposals only), a retirement with `--retired_by`
        (the revision that carries the span), a rejection with `--resolved_by` (where the decision now
        lives in the pipeline, or `particular`); `gap archive [--manifest <file.json>]` ends the round
        by hand, as a new run does: every resolved gap moves to the results of the run that proposed
        it (`manifest`, {gap id: run}, names it for a row that does not)."""
        from .store.gaps import GapLedger
        ledger = GapLedger(paths.GAPS_DIR)
        if action == "list":
            print(ledger.render()); return 0
        if action == "decide":
            if not gap_id or not state or not decision:
                raise SystemExit("gap decide <id> --state <retired|rejected|accepted> --decision \"<words>\" [--retired_by|--resolved_by ...]")
            ledger.decide(gap_id, state, decision, retired_by, resolved_by)
            print(f"{gap_id}: {state}"); return 0
        if action == "archive":
            from .store.owner import acquire_for_command
            acquire_for_command("gap archive")
            names = json.loads(_p(manifest).read_text(encoding="utf-8")) if manifest else {}
            moved = ledger.start_round(paths.RESULTS, names)
            print("\n".join(f"{g} → results/{r}/gaps.jsonl" for g, r in moved) or "the gap ledger is empty"); return 0
        raise SystemExit("gap list | gap decide <id> --state ... --decision ... | gap archive [--manifest <file.json>]")

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
        from .store import owner
        owner.acquire_for_command("split")
        copied = split_mod.activate(use)
        index_sync.write_index()
        code, out = lean.lake_build(paths.LIBRARY); ok = code == 0
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
    """Run a command; a command's integer result is the process's exit status."""
    code = fire.Fire(Cli)
    if isinstance(code, int) and not isinstance(code, bool):
        sys.exit(code)


if __name__ == "__main__":
    main()
