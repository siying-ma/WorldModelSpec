"""Recovery: a loop stopped at any point and resumed ends where an uninterrupted loop ends.

The real loop, ledgers, state snapshot, coding phase (its task directories, saved verdicts and
rollbacks), integration and feedback run in a temporary repository; the sessions, the gates, the
concept reviews, the aggregates, the doctor, the owner lock and Lean are scripted, each outcome keyed by the
record and the iteration, never by the launch. Every scenario runs once to its end; then, for every
point it passed (each snapshot commit, each projection written after it, each session's effects,
each file restore), it is run again stopped at that point and resumed, and the stable state at the
end (ledgers, accepted and held records, gaps, the library's files, the operator's notices, the
iterations allocated) must be the reference's. A session whose outcome was committed (in the
snapshot, or as a task's saved verdict) is never launched again.
"""
import collections
import contextlib
import json
import shutil
import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import openai_runner, render, session
from harness.checks import gate, validate_a
from harness.lean import index_sync, lean, surface
from harness.model import definitions as definitions_mod, nodeid, ontology, units  # noqa: F401  (units: read from Core before paths move)
from harness.model.blueprint import Node, ConceptRecord
from harness.phases import aggregate as aggregate_phase, code as code_phase, integrate as integrate_phase
from harness.phases import plan as plan_phase, review as review_phase, validate as validate_phase
from harness.store import jsonl, owner, paths
from harness.store.state import Options

PATH_NAMES = ("REPO", "LIBRARY", "CORE", "RULES_DIR", "CONCEPTS_DIR", "WITNESS_DIR", "CONCEPT_WITNESS_DIR", "INDEX_FILE",
              "WITNESS_ROOT_FILE", "RESULTS", "READINGS", "GAPS_DIR", "USER_HINTS")
PROJECTIONS = {"ledger.jsonl", "concept_ledger.jsonl", "node_ledger.jsonl", "accepted_nodes.jsonl", "accepted_concepts.jsonl"}
ATOMS = {"kin.speed", "rel.occupies", "st.lane"}


class Crash(BaseException):
    """The process dies here: nothing after it runs, and no handler of the loop sees it."""


def node(nid, law_text, law, *, derived=(), compositions=(), span="s1"):
    return {"node_id": nid, "law_refs": [law], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
            "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
            "segmentation": [{"id": span, "role": "obligation", "text": law_text}],
            "elements": [{"span": span, "atoms": ["kin.speed"], "derived": list(derived), "justification": "j"}],
            "compositions": [{"span": span, "rule": r, "as": "condition"} for r in compositions],
            "applicability": "a", "obligation": "o", "params": [],
            "scenarios": [{"name": "forbid", "expected": "violated", "narrative": "n"}]}


def concept(cid, *, calls=(), users=()):
    return {"concept_id": cid, "kind": "predicate", "contract": f"{cid} holds", "args": [{"name": "v", "sort": "track"}], "params": [],
            "elements": [{"atoms": ["kin.speed"], "concepts": list(calls)}], "used_by": list(users)}


class World:
    """The scripted outcomes of every session and check, and the log of what ran."""

    def __init__(self, laws: dict[str, str]):
        self.laws = laws
        self.plans: dict = {}            # (law, iteration) or law -> records the plan writes for it
        self.validate: dict = {}         # (id, iteration) -> (kind, reasons)
        self.gate: dict = {}             # (id, iteration) -> verdict, or "PANIC" (a reproduced panic)
        self.review: dict = {}           # (concept id, iteration) -> "accepted" | "returned" | ("deferred", stage) | "outage"
        self.node_repair: dict = {}      # (id, iteration) -> record raw | {"withdraw": {...}} | None
        self.concept_repair: dict = {}
        self.integration_fail: dict = {}  # iteration -> ids whose files fail the library's verification
        self.integration_infra = 0             # the first library verifications whose toolchain does not run
        self.launch = 0
        self.verify_calls = collections.Counter()   # launch -> library verifications
        self.context_failing: dict = {}   # iteration -> notices
        self.late_fence: set = set()      # concepts the context check fences once they are accepted
        self.admission: dict = {}         # id -> the verdict today's gates give an accepted record
        self.admitted = collections.Counter()   # id -> admission rechecks run (cache misses)
        self.broken: set = set()          # records whose files break the library build when a registry carries them
        self.calls = collections.Counter()
        self.log: list[tuple] = []
        self.crash_at: int | None = None
        self.fail_write_at: int | None = None
        self.ticks = 0
        self.dead = False
        self.uncommitted = collections.Counter()   # at the stop: the session calls whose outcome was not committed
        self.before_stop = collections.Counter()   # the session calls made before the stop
        self.lock = threading.RLock()              # tasks run in worker threads: one tick at a time

    def tick(self, *label):
        with self.lock:
            if self.dead:
                raise Crash("dead")
            self.ticks += 1
            self.log.append(label)
            if self.crash_at == self.ticks:
                self.uncommitted = uncommitted_calls(self.log, self.ticks)
                self.before_stop = collections.Counter(self.calls)
                self.dead = True
                raise Crash(label)

    def call(self, kind, ident, it):
        with self.lock:
            if self.dead:
                raise Crash("dead")
            self.calls[(kind, ident, it)] += 1
            self.tick("call", kind, ident, it)

    def plan_for(self, law, it):
        return self.plans.get((law, it), self.plans.get(law, []))


def _iteration_of(d: Path) -> int:
    for p in [d, *d.parents]:
        if p.name.startswith("iter-"):
            return int(p.name.split("-")[1])
    raise ValueError(d)


class Fixture:
    """A temporary repository with the scripted world patched in."""

    def __init__(self, world: World, **opt):
        self.w = world
        self.tmp = Path(tempfile.mkdtemp(prefix="recovery-"))
        self.root = self.tmp / "repo"
        self.opt = opt
        lib = self.root / "library"
        self.dirs = {"REPO": self.root, "LIBRARY": lib, "CORE": lib / "TrafficSpec" / "Core", "RULES_DIR": lib / "TrafficSpec" / "Rules",
                     "CONCEPTS_DIR": lib / "TrafficSpec" / "Concepts", "WITNESS_DIR": lib / "TrafficSpecWitness",
                     "CONCEPT_WITNESS_DIR": lib / "TrafficSpecWitness" / "Concepts", "INDEX_FILE": lib / "TrafficSpec" / "Index.lean",
                     "WITNESS_ROOT_FILE": lib / "TrafficSpecWitness.lean", "RESULTS": self.root / "results",
                     "READINGS": lib / "TrafficSpec" / "Readings", "GAPS_DIR": lib / "TrafficSpec" / "Gaps", "USER_HINTS": self.root / "USER_HINTS.md"}
        for k in ("CORE", "RESULTS", "READINGS", "GAPS_DIR"):
            self.dirs[k].mkdir(parents=True, exist_ok=True)
        (self.dirs["CORE"] / "Core.lean").write_text("-- core\n")
        laws_dir = self.root / "corpus"
        laws_dir.mkdir()
        (laws_dir / "laws.jsonl").write_text("".join(json.dumps({"id": l, "title": l, "text": t, "source": "s"}) + "\n" for l, t in world.laws.items()))
        (laws_dir / "definitions.jsonl").write_text("")
        (self.root / "reading.json").write_text(json.dumps({"params": []}))
        (self.root / "ontology.md").write_text("# ontology\n")
        (self.root / "precedence.json").write_text("{}")
        self.stack = contextlib.ExitStack()

    def options(self, **over) -> Options:
        kw = dict(run_id="r", laws=self.root / "corpus" / "laws.jsonl", ontology=self.root / "ontology.md", reading=self.root / "reading.json",
                  model="claude-test", reviewer_model="gpt-test", aggregate_verifier_model="gpt-test", max_iterations=3, workers=1, plan_batch=8,
                  definition_precedence=self.root / "precedence.json")
        kw.update(self.opt)
        kw.update(over)
        return Options(**kw)

    def __enter__(self):
        w, s = self.w, self.stack
        for k in PATH_NAMES:
            s.enter_context(mock.patch.object(paths, k, self.dirs[k]))
        real_write = jsonl.write_atomic

        def locked(fn):                          # an effect and its tick are one step: no task runs past the stop
            def run(*a, **k):
                with w.lock:
                    return fn(*a, **k)
            return run

        def write_atomic(path, text):
            name = Path(path).name
            if w.dead:
                raise Crash("dead")
            if name == "state.json" and w.fail_write_at is not None:
                w.fail_write_at -= 1
                if w.fail_write_at == 0:
                    raise OSError("disk full")
            real_write(path, text)
            if name == "state.json":
                w.tick("commit")
            elif name in PROJECTIONS:
                w.tick("projection", name)
        s.enter_context(mock.patch.object(jsonl, "write_atomic", locked(write_atomic)))
        s.enter_context(mock.patch.object(jsonl.os, "fsync", lambda fd: None))      # durability is not what is tested here
        real_append = jsonl.append_atomic

        def append_atomic(path, row):
            if w.dead:
                raise Crash("dead")
            real_append(path, row)
        s.enter_context(mock.patch.object(jsonl, "append_atomic", locked(append_atomic)))
        fake_onto = mock.Mock(atom_ids=sorted(ATOMS), primitive_ids=[])
        s.enter_context(mock.patch.object(ontology, "load", lambda p: fake_onto))
        s.enter_context(mock.patch.object(ontology, "anchors_text", lambda *a, **k: ""))
        s.enter_context(mock.patch.object(surface, "core_atom_ids", lambda: sorted(ATOMS)))
        s.enter_context(mock.patch.object(surface, "core_surface", lambda *a, **k: ""))
        s.enter_context(mock.patch.object(surface, "primitive_reads", lambda: {}))
        s.enter_context(mock.patch.object(render, "render", lambda *a, **k: "prompt"))
        s.enter_context(mock.patch.object(loop, "doctor_ok", lambda: None))
        s.enter_context(mock.patch.object(owner, "acquire", lambda *a, **k: "nonce"))
        s.enter_context(mock.patch.object(openai_runner, "available", lambda: True))
        s.enter_context(mock.patch.object(definitions_mod, "write_table", lambda *a, **k: None))
        s.enter_context(mock.patch.object(definitions_mod, "load_table", lambda *a, **k: {}))
        s.enter_context(mock.patch.object(definitions_mod, "precedence_digest", lambda p: "p"))
        s.enter_context(mock.patch.object(index_sync, "write_index", lambda *a, **k: None))
        s.enter_context(mock.patch.object(lean, "library_lock", lambda *a, **k: contextlib.nullcontext()))
        s.enter_context(mock.patch.object(lean, "lake_build", lambda *a, **k: (0, "")))
        s.enter_context(mock.patch.object(code_phase, "worked_example", lambda run: ""))
        s.enter_context(mock.patch.object(code_phase, "concept_example", lambda *a: ""))

        def aggregate_call(name, value):
            def f(run, *a, **k):
                w.call(name, "-", run.iteration)
                return value
            return f
        s.enter_context(mock.patch.object(aggregate_phase, "check_admissions", lambda *a, **k: ([], [])))
        s.enter_context(mock.patch.object(aggregate_phase, "prepare", aggregate_call("aggregate_prepare", ([], [], {}, None))))
        s.enter_context(mock.patch.object(aggregate_phase, "admit", aggregate_call("aggregate_admit", ([], [], []))))
        s.enter_context(mock.patch.object(aggregate_phase, "correct_claims", lambda *a, **k: ([], {})))
        s.enter_context(mock.patch.object(aggregate_phase, "claimed_ids", lambda nodes: {}))

        def run_plan(run, laws, defs, tag="", pending=None, label_repair=False):
            d = run.iter / "plan" / (tag or "")
            d.mkdir(parents=True, exist_ok=True)
            rows = [r for l in laws for r in w.plan_for(l.id, run.iteration)]
            (d / "blueprint.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
            (d / "aggregates.jsonl").write_text("")
            (d / "PLAN.md").write_text("plan\n")
            w.call("plan", ",".join(sorted(l.id for l in laws)), run.iteration)
            return d
        s.enter_context(mock.patch.object(plan_phase, "run_plan", run_plan))

        def run_validate(run, plan_dir, by_id, reading, defs, extra_concepts=None, extra_nodes=None, extra_validate_nodes=None):
            from harness.model import blueprint
            seen, out = set(), []
            for n in blueprint.load(plan_dir / "blueprint.jsonl") + list(extra_validate_nodes or []):
                if n.id not in seen:
                    seen.add(n.id)
                    kind, reasons = w.validate.get((n.id, run.iteration), ("accept", []))
                    out.append(mock.Mock(node=n, kind=kind, reasons=list(reasons)))
            cs, cseen = [], set()
            for c in blueprint.load_concepts(plan_dir / "blueprint.jsonl") + list(extra_concepts or []):
                if c.id not in cseen:
                    cseen.add(c.id)
                    kind, reasons = w.validate.get((c.id, run.iteration), ("accept", []))
                    cs.append(mock.Mock(concept=c, kind=kind, reasons=list(reasons)))
            return out, cs
        s.enter_context(mock.patch.object(validate_phase, "run_validate", run_validate))

        def write_files(rels, text):
            for rel in rels:
                p = paths.LIBRARY / rel
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text(text)

        def write_skeletons(n):
            write_files((nodeid.rule_path(n.id), nodeid.witness_path(n.id)), "skeleton\n")
            return "skeleton", "skeleton"

        def write_concept_skeletons(c):
            write_files((nodeid.concept_path(c.id), nodeid.concept_witness_path(c.id)), "skeleton\n")
            return "skeleton", "skeleton"
        s.enter_context(mock.patch.object(code_phase, "write_skeletons", write_skeletons))
        s.enter_context(mock.patch.object(code_phase, "write_concept_skeletons", write_concept_skeletons))

        def session_run(prompt, cwd=None, out_dir=None, opts=None, **kw):
            if w.dead:
                raise Crash("dead")
            d = Path(out_dir)
            it = _iteration_of(d)
            if d.name.startswith("concept__"):
                ident = loop._concept_id_of_dirname(d.name)
                rels = (nodeid.concept_path(ident), nodeid.concept_witness_path(ident))
            else:
                ident = d.name
                rels = (nodeid.rule_path(ident), nodeid.witness_path(ident))
            if w.gate.get((ident, it)) == "outage":
                w.call("code", ident, it)
                raise session.SessionUnavailable("scripted outage")
            write_files(rels, f"coded {ident} {it}\n")
            w.call("code", ident, it)
            return {}
        s.enter_context(mock.patch.object(session, "run", locked(session_run)))

        def admitted(ident, d):                  # an admission recheck at a loop start, not a coding task
            if "admission" not in Path(d).parts:
                return None
            w.admitted[ident] += 1
            w.tick("admission", ident)
            return w.admission.get(ident, "OK")

        def failing(v):                          # `PANIC`: a panic the gate reproduced in isolation
            return gate.Verdict(gate.GATE_TIMEOUT, ["scripted panic"], extras={"panic": ["PANIC at scripted"]}) if v == "PANIC" \
                else gate.Verdict(v, [f"scripted {v}"])

        def run_gate(n, reading, baseline, d, budget_used=0, budget=0, accepted_concepts=None, acquisition=None):
            v = admitted(n.id, d) or w.gate.get((n.id, _iteration_of(Path(d))), "OK")
            return gate.Verdict(v, [], extras={"rule_json": {"id": n.id}}) if v == "OK" else failing(v)

        def run_concept_gate(rec, reading, baseline, d, budget_used=0, budget=0, mode="train", accepted=None):
            v = admitted(rec.id, d) or w.gate.get((rec.id, _iteration_of(Path(d))), "OK")
            return gate.Verdict(v, [], extras={"reads": ["kin.speed"], "refs": sorted(rec.refs()), "body_json": {"c": rec.id}}) \
                if v == "OK" else failing(v)
        s.enter_context(mock.patch.object(gate, "run_gate", run_gate))
        s.enter_context(mock.patch.object(gate, "run_concept_gate", run_concept_gate))
        real_restore = code_phase._restore

        def restore(work, baseline, rels, keep_final=True):
            if w.dead:                           # a task beside the one that stopped the process does no more
                raise Crash("dead")
            real_restore(work, baseline, rels, keep_final)
            w.tick("restore", Path(work).name)
        s.enter_context(mock.patch.object(code_phase, "_restore", locked(restore)))

        def outcome(o, ident):
            if o == "outage":
                raise session.SessionUnavailable("scripted review outage")
            if o == "returned":
                return review_phase.ReviewOutcome("returned", reasons=[f"scripted upheld on {ident}"])
            if isinstance(o, tuple) and o[0] == "deferred":
                return review_phase.ReviewOutcome("deferred", reasons=["scripted deferral"], defer_stage=o[1])
            return review_phase.ReviewOutcome("accepted")

        def review_concept(run, c, extras, out_dir):
            o = w.review.get((c.id, run.iteration), "accepted")
            w.call("review", c.id, run.iteration)
            return outcome(o, c.id)
        s.enter_context(mock.patch.object(review_phase, "review_concept", review_concept))

        def run_node_repair(run, nrec, reasons, last_task, law, defs, siblings, reading, onto):
            d = run.iter / "repair" / nrec.id
            d.mkdir(parents=True, exist_ok=True)
            (d / "planned.json").write_text(json.dumps(nrec.raw))
            r = w.node_repair.get((nrec.id, run.iteration), nrec.raw)
            if r is not None:
                (d / "record.jsonl").write_text(json.dumps(r) + "\n")
            (d / "validation.txt").write_text("accept")
            w.call("node_repair", nrec.id, run.iteration)
            return d

        def run_repair(run, rec, reasons, last_task, defs, users):
            d = run.iter / "repair" / ("concept__" + rec.id)
            d.mkdir(parents=True, exist_ok=True)
            r = w.concept_repair.get((rec.id, run.iteration), {k: v for k, v in rec.raw.items() if k != "used_by"})
            if r is not None:
                (d / "record.jsonl").write_text(json.dumps(r) + "\n")
            (d / "validation.txt").write_text("accept")
            w.call("concept_repair", rec.id, run.iteration)
            return d
        s.enter_context(mock.patch.object(plan_phase, "run_node_repair", run_node_repair))
        s.enter_context(mock.patch.object(plan_phase, "run_repair", run_repair))

        def verify_library(work, reading, only_nodes=None, only_concepts=None):
            it = _iteration_of(Path(work))
            w.verify_calls[w.launch] += 1
            if w.integration_infra > 0:
                w.integration_infra -= 1
                return "infrastructure", ["scripted: the build did not run"], set()
            on_disk = lambda i: (paths.LIBRARY / (nodeid.concept_path(i) if nodeid.is_concept_id(i) else nodeid.rule_path(i))).exists()
            bad = {i for i in w.integration_fail.get(it, set()) if on_disk(i)}
            bad |= {i for i in w.broken if on_disk(i) and i not in index_sync.inactive()}     # a registered record that does not build
            return ("failed", [f"{i}\tscripted witness failure" for i in sorted(bad)], bad) if bad else ("verified", [], set())
        s.enter_context(mock.patch.object(integrate_phase, "verify_library", verify_library))
        def recheck_contexts(run, reading, base, laws):
            failing = list(w.context_failing.get(run.iteration, []))
            for i in sorted(w.late_fence):
                if i in run.all_concepts() and i not in run.fenced:
                    run.fence(i, "concept", "context", evidence="scripted: an upheld challenge holds again")
                    failing.append(f"`{i}`: scripted")
            return [], failing, []
        s.enter_context(mock.patch.object(integrate_phase, "recheck_contexts", recheck_contexts))
        return self

    def __exit__(self, *exc):
        self.stack.close()
        shutil.rmtree(self.tmp, ignore_errors=True)
        return False

    # -- driving and reading the run
    def drive(self, launches: int = 4, **over) -> list[str]:
        """Launch the loop as an operator would: again after a stop for a session that did not run
        (or a crash), until it ends otherwise or the launches are spent."""
        statuses = []
        for _ in range(launches):
            self.w.launch += 1
            try:
                res = loop.run_loop(self.options(**over))
            except Crash:
                self.w.dead = False
                self.w.crash_at = None
                statuses.append("crash")
                continue
            except OSError as e:
                statuses.append(f"oserror:{e}")
                continue
            statuses.append(res["status"])
            if res["status"] != "infrastructure_failure":
                break
        return statuses

    def state(self) -> dict:
        rd = paths.RESULTS / "r"
        st = json.loads((rd / "state.json").read_text())
        keys = ("iteration", "ledger", "concept_ledger", "node_ledger", "accepted_nodes", "accepted_concepts",
                "deferred_nodes", "deferred_concepts", "aggregate_failures", "fenced")
        out = {k: st.get(k) for k in keys}
        if self.opt.get("workers", 1) > 1:                       # tasks end in any order: a ledger's rows are a set
            for k in ("ledger", "concept_ledger", "node_ledger"):
                out[k] = sorted(out[k] or [], key=lambda d: json.dumps(d, sort_keys=True))
        for k in ("deferred_nodes", "deferred_concepts"):        # held records are a set
            out[k] = sorted(out[k] or [], key=lambda d: json.dumps(d, sort_keys=True))
        out["stage"] = st["prog"].get("stage")
        summary = json.loads((rd / "summary.json").read_text()) if (rd / "summary.json").exists() else {}
        out["status"] = (summary.get("status"), summary.get("stop_reason"))
        gaps = paths.GAPS_DIR / "proposals.jsonl"
        out["gaps"] = sorted(json.dumps({k: v for k, v in json.loads(l).items() if k not in ("proposed_at", "time")}, sort_keys=True)
                             for l in gaps.read_text().splitlines() if l.strip()) if gaps.exists() else []
        out["library"] = sorted(str(p.relative_to(paths.LIBRARY)) for p in paths.LIBRARY.rglob("*.lean") if paths.CORE not in p.parents)
        out["to_user"] = sorted(set(l for l in (rd / "TO_USER.md").read_text().splitlines() if l.strip())) if (rd / "TO_USER.md").exists() else []
        out["iterations_allocated"] = sorted(p.name for p in rd.glob("iter-*"))
        # the projections are what the snapshot holds
        for name, key in (("ledger.jsonl", "ledger"), ("concept_ledger.jsonl", "concept_ledger"), ("node_ledger.jsonl", "node_ledger")):
            rows = [json.loads(l) for l in (rd / name).read_text().splitlines() if l.strip()] if (rd / name).exists() else []
            assert rows == st.get(key, []), f"{name} is not the snapshot's"
        return json.loads(json.dumps(out).replace(str(self.tmp), "<tmp>"))


def prepare(build, w: World, f: "Fixture") -> None:
    """A scenario's earlier runs (`build.before`), before the run it checks; their ticks and calls
    are not the checked run's."""
    if hasattr(build, "before"):
        crash, w.crash_at = w.crash_at, None
        build.before(f, w)
        w.crash_at, w.ticks, w.log, w.calls = crash, 0, [], collections.Counter()


def reference(build) -> tuple[dict, list[tuple], collections.Counter, list[str]]:
    w = build()
    with Fixture(w, **getattr(build, "opts", {})) as f:
        prepare(build, w, f)
        statuses = f.drive()
        return f.state(), list(w.log), collections.Counter(w.calls), statuses


def uncommitted_calls(log: list[tuple], upto: int) -> collections.Counter:
    """The session calls whose outcome is not yet committed at tick `upto` (1-based): those after
    the last snapshot commit, and the coding and review calls of an item of the snapshot's
    iteration whose decision the snapshot does not hold (a task running beside others whose outcome
    was committed after its call), less the coding sessions whose saved verdict a resume reuses (a
    failing verdict, or a passing one whose files are still in the library). An outcome the
    snapshot does not hold did not happen, and is redone."""
    last_commit = max([i for i, e in enumerate(log[:upto]) if e[0] == "commit"] or [-1])
    sf = paths.RESULTS / "r" / "state.json"
    snap = json.loads(sf.read_text()) if sf.exists() else {}
    prog = snap.get("prog") or {}
    decided = set(prog.get("nodes", {})) | set(prog.get("concepts", {}))
    out = collections.Counter()
    for i, e in enumerate(log[:upto]):
        if e[0] == "call":
            _, kind, ident, it = e
            if i <= last_commit and not (kind in ("code", "review") and it == snap.get("iteration") and ident not in decided):
                continue
            if kind == "code":                     # a saved verdict the resume can still reuse is committed
                is_c = nodeid.is_concept_id(ident)
                d = paths.RESULTS / "r" / f"iter-{it:03d}" / "code" / (code_phase.concept_dirname(ident) if is_c else ident)
                rels = (nodeid.concept_path(ident), nodeid.concept_witness_path(ident)) if is_c else (nodeid.rule_path(ident), nodeid.witness_path(ident))
                try:                                # a verdict another task is writing at the stop is not yet saved
                    saved = json.loads((d / "verdict.json").read_text()).get("extras", {}).get("context") if (d / "verdict.json").exists() else None
                except json.JSONDecodeError:
                    saved = None
                if code_phase._finished_verdict(d, rels, saved) is not None:     # a resume on an unchanged context reuses it
                    continue
            out[(kind, ident, it)] += 1
    return out


def concepts_and_dependencies() -> World:
    """L-3's node calls a concept that calls another (an indirect dependency): both concepts are
    coded in waves, then the node. The first concept is returned by its review once and repaired,
    while the node waits for it uncharged."""
    w = World({"L-3": "shall halt."})
    w.plans = {"L-3": [concept("drv.motion.slow", users=["L_3"]), concept("drv.motion.halt", calls=["drv.motion.slow"], users=["L_3"]),
                       node("L_3", "shall halt.", "L-3", derived=["drv.motion.halt"])]}
    w.review[("drv.motion.slow", 1)] = "returned"
    return w


def compositions() -> World:
    """L-4 fails at validation; L-5, whose node composes L-4's, is not coded and not charged: it waits
    on the operator's decision on L-4 (`decision:L-4`), its record unchanged. L-6's node composes L-7's,
    which the gate returns and a repair fixes, so L-6's node is held one iteration (no attempt)."""
    w = World({"L-4": "shall signal.", "L-5": "shall wait.", "L-6": "shall merge.", "L-7": "shall slow."})
    w.plans = {"L-4": [node("L_4", "shall signal.", "L-4")], "L-5": [node("L_5", "shall wait.", "L-5", compositions=["L_4"])],
               "L-6": [node("L_6", "shall merge.", "L-6", compositions=["L_7"])], "L-7": [node("L_7", "shall slow.", "L-7")]}
    w.validate[("L_4", 1)] = (validate_a.FAIL, ["scripted: not expressible"])
    w.gate[("L_7", 1)] = "CHECK_FAIL"
    return w


def integration() -> World:
    """The library does not verify with L-8's concept: the concept is rejected at integration and
    the node that calls it waits; a changed dependency context is named to the operator; the
    concept is repaired, and both are accepted the next iteration."""
    w = World({"L-8": "shall keep right."})
    w.plans = {"L-8": [concept("drv.lane.keep_right", users=["L_8"]), node("L_8", "shall keep right.", "L-8", derived=["drv.lane.keep_right"])]}
    w.integration_fail = {1: {"drv.lane.keep_right"}}
    w.context_failing = {1: ["`L_0`: an obligation no longer holds after a context change"]}
    return w


def outages() -> World:
    """L-9's and L-10's coding sessions do not run in iteration 1: the run stops, keeping the work,
    and the next launch finishes; no attempt is charged."""
    w = World({"L-9": "shall stop.", "L-10": "shall yield."})
    w.plans = {"L-9": [node("L_9", "shall stop.", "L-9")], "L-10": [node("L_10", "shall yield.", "L-10")]}
    w.gate[("L_9", 1)] = "outage"
    w.gate[("L_10", 1)] = "outage"
    return w


def siblings() -> World:
    """L-11's two nodes are both returned by their gates; the first one's repair withdraws it as a
    plan defect, so the law returns to the planner and the second repair is not run; the law's
    next plan is accepted. A plan record of a law the session was not given is not registered."""
    text = "shall stop. shall yield."
    o1, o2 = node("L_11_o1", text, "L-11"), node("L_11_o2", text, "L-11")
    o1["segmentation"] = [{"id": "s1", "role": "obligation", "text": "shall stop."}, {"id": "s2", "role": "sibling", "text": "shall yield."}]
    o2["segmentation"] = [{"id": "s1", "role": "sibling", "text": "shall stop."}, {"id": "s2", "role": "obligation", "text": "shall yield."}]
    o2["elements"] = [{"span": "s2", "atoms": ["kin.speed"], "derived": [], "justification": "j"}]
    w = World({"L-11": text})
    w.plans = {"L-11": [o1, o2, node("L_99", "shall go.", "L-99")]}
    w.gate[("L_11_o1", 1)] = w.gate[("L_11_o2", 1)] = "CHECK_FAIL"
    w.node_repair[("L_11_o1", 2)] = {"withdraw": {"span": "s1", "kind": "plan", "missing": "the text needs another cut"}}
    return w


def integration_outage() -> World:
    """The library's verification does not run in the first launch: nothing is decided, and the next
    launch verifies the library before anything is accepted."""
    w = World({"L-12": "shall signal."})
    w.plans = {"L-12": [node("L_12", "shall signal.", "L-12")]}
    w.integration_infra = 1
    return w


def same_iteration_replan() -> World:
    """L-13's node is returned by its gate; in iteration 2 its repair withdraws it as a plan defect
    (the law is returned and charged), the law is planned again in the same iteration and that plan
    is returned by the validator: one attempt, not two. Iteration 3's plan is accepted."""
    w = World({"L-13": "shall slow."})
    w.plans = {"L-13": [node("L_13", "shall slow.", "L-13")]}
    w.gate[("L_13", 1)] = "CHECK_FAIL"
    w.node_repair[("L_13", 2)] = {"withdraw": {"span": "s1", "kind": "plan", "missing": "the text needs another cut"}}
    w.validate[("L_13", 2)] = ("return", ["scripted plan defect"])
    return w


def parameter_notice() -> World:
    """L-14's node proposes a parameter before it is coded: the operator's notice of it is sent once,
    whatever stop falls between the proposal's write and the next commit."""
    w = World({"L-14": "shall pause."})
    n = node("L_14", "shall pause.", "L-14")
    n["params"] = ["p.pause"]
    n["param_proposals"] = [{"name": "p.pause", "value": 2.0, "unit": "s", "convention": "a pause convention", "source": "a source"}]
    w.plans = {"L-14": [n]}
    return w


def rejected_node() -> World:
    """L-15's first plan holds a node whose `derived` entry is malformed, with a concept only that node
    would call: the record's schema returns the law at registration, nothing reads the node's fields,
    and the concept is not coded. Iteration 2's plan is accepted. (A returned record that reaches
    validation is covered at the iteration's level in `test_loop_and_owner_guards`.)"""
    w = World({"L-15": "shall creep."})
    bad = node("L_15", "shall creep.", "L-15")
    bad["elements"][0]["derived"] = [["drv.motion.creep"]]
    w.plans = {("L-15", 1): [bad, concept("drv.motion.creep", users=["L_15"])], ("L-15", 2): [node("L_15", "shall creep.", "L-15")]}
    w.validate[("L_15", 1)] = ("return", ["scripted: a `derived` entry is not an id"])
    return w


def last_iteration() -> World:
    """The iteration bound is reached with work left: a resume finishes the last iteration and
    allocates none after it."""
    return life_cycle()


last_iteration.opts = {"max_iterations": 1}


class Interruptions:
    """Run a scenario to its end, then stopped at each point it passed and resumed."""

    def interrupt_everywhere(self, build, points=None, never=()) -> tuple[dict, int]:
        """`never`: session calls a decision committed before them rules out, whatever the stop."""
        ref, log, ref_calls, _statuses = reference(build)
        n = len(log)
        self.assertGreater(n, 5)
        for k in (points or range(1, n + 1)):
            w = build()
            w.crash_at = k
            with Fixture(w, **getattr(build, "opts", {})) as f:
                prepare(build, w, f)
                statuses = f.drive(launches=6)
                where = f"a stop at tick {k}/{n} {log[k - 1]}"
                self.assertTrue("crash" in statuses or k > w.ticks, where)   # tasks side by side may end in fewer ticks
                got = f.state()
            for key in ref:
                if key == "to_user":                  # no notice is lost; a session retried after the stop may add its own
                    self.assertLessEqual(set(ref[key]), set(got[key]), f"a notice was lost after {where}")
                else:
                    self.assertEqual(got[key], ref[key], f"{key} differs after {where}")
            for key in never:
                self.assertEqual(w.calls[key], 0, f"{key} ran after {where}")
            for key, c in (w.calls - w.before_stop).items():   # a session whose outcome was committed is never launched again
                if w.before_stop[key]:
                    self.assertLessEqual(c, w.uncommitted[key], f"{key} ran {c} more time(s), {w.uncommitted[key]} uncommitted, after {where}")
        return ref, n


# ---------------------------------------------------------------------------------------------
# Scenarios: each builds its world afresh, so every run sees the same outcomes
# ---------------------------------------------------------------------------------------------
def life_cycle() -> World:
    """L-1's node is returned by its gate, repaired and accepted; L-2's plan is returned by the
    validator, planned again and accepted."""
    w = World({"L-1": "shall stop.", "L-2": "shall yield."})
    w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")], "L-2": [node("L_2", "shall yield.", "L-2")]}
    w.gate[("L_1", 1)] = "CHECK_FAIL"
    w.validate[("L_2", 1)] = ("return", ["scripted plan defect"])
    return w


def fenced_base() -> World:
    """A base run accepted a concept that today's gates reject, and a node calling it; the
    continuation re-plans that node's law: the concept is fenced, out of every registry (a
    registered copy would break the build), and a successor without a counterexample is planned,
    coded and integrated."""
    w = World({"L-1": "shall stop.", "L-2": "shall yield."})
    w.broken = {"drv.motion.creep"}
    return w


def _fenced_base_before(f: "Fixture", w: World) -> None:
    from scripts.subset_laws import subset
    corpus = f.root / "corpus" / "laws.jsonl"
    w.plans = {"L-1": [concept("drv.motion.creep", users=["L_1"]), node("L_1", "shall stop.", "L-1", derived=["drv.motion.creep"])],
               "L-2": [node("L_2", "shall yield.", "L-2")]}
    w.broken = set()
    loop.run_loop(f.options(run_id="A"))
    w.broken = {"drv.motion.creep"}
    w.admission["drv.motion.creep"] = "WITNESS_FAIL"
    successor = {**concept("drv.motion.creep_v2", users=["L_1"]), "supersedes": "drv.motion.creep", "contract": "drv.motion.creep holds"}
    w.plans = {"L-1": [successor, node("L_1", "shall stop.", "L-1", derived=["drv.motion.creep_v2"])]}
    f.opt.update(laws=subset("r", corpus, ["L-1"]), base_run="A")


fenced_base.before = _fenced_base_before


class Recovery(Interruptions, unittest.TestCase):
    """The interruption check, scenario by scenario."""

    def test_a_fenced_base_record_and_its_successor(self):
        ref, n = self.interrupt_everywhere(fenced_base)
        self.assertEqual(sorted(ref["accepted_concepts"]), ["drv.motion.creep_v2"])
        self.assertEqual(sorted(ref["accepted_nodes"]), ["L_1"])
        self.assertEqual(ref["accepted_nodes"]["L_1"]["elements"][0]["derived"], ["drv.motion.creep_v2"])
        self.assertEqual(ref["fenced"]["drv.motion.creep"]["reason"], "gate")
        self.assertEqual(ref["status"][0], "complete")

    def test_life_cycle(self):
        ref, n = self.interrupt_everywhere(life_cycle)
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-1"]["state"], led["L-2"]["state"]), ("accepted", "accepted"))
        self.assertEqual(led["L-1"]["attempts"], 0)                # a node repair is no attempt of the law
        self.assertEqual(led["L-2"]["attempts"], 1)

    def test_concepts_and_dependencies(self):
        ref, n = self.interrupt_everywhere(concepts_and_dependencies)
        self.assertEqual(sorted(ref["accepted_concepts"]), ["drv.motion.halt", "drv.motion.slow"])
        self.assertEqual(sorted(ref["accepted_nodes"]), ["L_3"])
        self.assertEqual([e["attempts"] for e in ref["ledger"]], [0])

    def test_compositions(self):
        ref, n = self.interrupt_everywhere(compositions)
        led = {e["law"]: (e["state"], e["attempts"]) for e in ref["ledger"]}
        self.assertEqual(led, {"L-4": ("failed", 0), "L-5": ("blocked", 0), "L-6": ("accepted", 0), "L-7": ("accepted", 0)})
        l5 = next(e for e in ref["ledger"] if e["law"] == "L-5")
        self.assertEqual(l5["gaps"], ["decision:L-4"])
        self.assertIn("composes ['L_4'], whose law(s) wait for the operator", l5["reasons"][0])

    def test_integration(self):
        ref, n = self.interrupt_everywhere(integration)
        self.assertEqual((sorted(ref["accepted_concepts"]), sorted(ref["accepted_nodes"])), (["drv.lane.keep_right"], ["L_8"]))
        self.assertTrue(any("no longer holds after a context change" in l for l in ref["to_user"]))

    def test_an_integration_that_did_not_run_decides_nothing(self):
        w = integration_outage()
        with Fixture(w) as f:
            self.assertEqual(f.drive(), ["infrastructure_failure", "complete"])
            st = f.state()
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_12"])
        self.assertEqual(w.verify_calls[2], 1)                    # accepted only after the library verified
        self.interrupt_everywhere(integration_outage)

    def test_outages_keep_the_work_uncharged(self):
        ref, n = self.interrupt_everywhere(outages)
        self.assertEqual({e["law"]: (e["state"], e["attempts"]) for e in ref["ledger"]}, {"L-9": ("accepted", 0), "L-10": ("accepted", 0)})

    def test_siblings(self):
        ref, n = self.interrupt_everywhere(siblings, never=[("node_repair", "L_11_o2", 2)])   # the law was returned by its sibling's repair
        self.assertEqual(sorted(ref["accepted_nodes"]), ["L_11_o1", "L_11_o2"])
        self.assertNotIn("L_99", json.dumps(ref["ledger"]))

    def test_the_last_iteration_is_finished_not_followed(self):
        ref, n = self.interrupt_everywhere(last_iteration)
        self.assertEqual(ref["iterations_allocated"], ["iter-001"])

    def test_a_withdrawal_and_a_new_plan_of_one_iteration_are_one_attempt(self):
        ref, n = self.interrupt_everywhere(same_iteration_replan)
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-13"]["state"], led["L-13"]["attempts"]), ("accepted", 1))
        self.assertEqual(ref["iterations_allocated"], ["iter-001", "iter-002", "iter-003"])

    def test_a_returned_malformed_node_is_routed_by_its_law_at_every_stop(self):
        ref, n = self.interrupt_everywhere(rejected_node, never=[("code", "drv.motion.creep", 1)])
        led = {e["law"]: e for e in ref["ledger"]}
        self.assertEqual((led["L-15"]["state"], led["L-15"]["attempts"]), ("accepted", 1))
        self.assertNotIn("drv.motion.creep", json.dumps(ref["concept_ledger"]))

    def test_a_parameter_notice_survives_every_stop_once(self):
        def notices(text: str) -> int:
            return sum(1 for l in text.splitlines() if "`p.pause`" in l)
        ref, log, _calls, _st = reference(parameter_notice)
        self.assertEqual(sum(1 for l in ref["to_user"] if "`p.pause`" in l), 1)
        for k in range(1, len(log) + 1):
            w = parameter_notice()
            w.crash_at = k
            with Fixture(w) as f:
                f.drive(launches=6)
                rd = paths.RESULTS / "r"
                to_user, auto = (rd / "TO_USER.md").read_text(), (rd / "AUTO_NOTES.md").read_text()
                where = f"a stop at tick {k}/{len(log)} {log[k - 1]}"
                self.assertEqual(notices(to_user), 1, f"the operator's notice after {where}")
                self.assertEqual(notices(auto), 1, f"the next plan's note after {where}")



def with_workers(build, workers: int = 4):
    """The scenario with `workers` tasks running side by side."""
    def b() -> World:
        return build()
    b.__name__ = build.__name__
    b.opts = {**getattr(build, "opts", {}), "workers": workers}
    if hasattr(build, "before"):
        b.before = build.before
    return b


def decisions(st: dict) -> dict:
    """What a run decided, whatever order its tasks ended in."""
    return {"ledger": {e["law"]: (e["state"], e["attempts"], e.get("gaps")) for e in st["ledger"]},
            "nodes": sorted(st["accepted_nodes"]), "concepts": sorted(st["accepted_concepts"]), "fenced": sorted(st["fenced"] or {}),
            "held": sorted(json.dumps(d, sort_keys=True) for d in st["deferred_nodes"] + st["deferred_concepts"]),
            **{k: st[k] for k in ("gaps", "library", "iterations_allocated", "status")}}


class ConcurrentRecovery(Interruptions, unittest.TestCase):
    """The interruption check with four tasks running side by side: an uninterrupted run decides as
    one task at a time does, and a stop at any point, resumed, ends where it ends, with no session
    whose outcome was committed launched again."""

    def check(self, build, never=()):
        ref, _ = self.interrupt_everywhere(with_workers(build), never=never)
        self.assertEqual(decisions(ref), decisions(reference(build)[0]))

    def test_life_cycle(self):
        self.check(life_cycle)

    def test_concepts_and_dependencies(self):
        self.check(concepts_and_dependencies)

    def test_compositions(self):
        self.check(compositions)

    def test_outages(self):
        self.check(outages)

    def test_siblings(self):
        self.check(siblings, never=[("node_repair", "L_11_o2", 2)])

    def test_integration(self):
        self.check(integration)

def tree_bytes(root: Path) -> dict[str, bytes]:
    return {str(f.relative_to(root)): f.read_bytes() for f in sorted(root.rglob("*")) if f.is_file()}


class Persistence(unittest.TestCase):
    """What a resume takes from the run, and what it refuses."""

    def test_options_on_resume(self):
        """A resume takes every option it is not given from the run's saved options; one given
        explicitly, a default included, is taken as given."""
        from harness.__main__ import Cli
        w = life_cycle()
        w.crash_at = 60
        with Fixture(w) as f:
            given = dict(laws=str(f.root / "corpus" / "laws.jsonl"), ontology_file=str(f.root / "ontology.md"), reading=str(f.root / "reading.json"),
                         definition_precedence=str(f.root / "precedence.json"), model="claude-test", reviewer_model="gpt-test",
                         max_iterations=3, workers=4, plan_batch=2, aggregate_verifier_model="gpt-test")
            seen = []
            real = loop.run_loop

            def capture(opts):
                seen.append(opts)
                try:
                    return real(opts)
                except Crash:
                    w.dead, w.crash_at = False, None
                    return {"status": "crash"}
            with mock.patch.object(loop, "run_loop", capture):
                Cli().loop("r", **given)                          # the first launch, stopped part-way
                Cli().loop("r")                                   # a resume naming no option
                Cli().loop("r", workers=4, plan_batch=2)          # a resume naming the saved values
                Cli().loop("r", workers=1)                        # a resume naming the default explicitly
        first, omitted, same, explicit = seen
        self.assertEqual(omitted, first)
        self.assertEqual(same, first)
        self.assertEqual((explicit.workers, explicit.plan_batch), (1, 2))

    def test_a_changed_semantic_input_stops_before_any_write(self):
        w = life_cycle()
        w.crash_at = 60
        with Fixture(w) as f:
            self.assertEqual(f.drive(launches=1), ["crash"])
            before = tree_bytes(paths.RESULTS)
            laws = f.root / "corpus" / "laws.jsonl"
            laws.write_text(laws.read_text() + json.dumps({"id": "L-9", "title": "L-9", "text": "shall go.", "source": "s"}) + "\n")
            with self.assertRaises(SystemExit) as cm:
                loop.run_loop(f.options())
            self.assertIn("built against other inputs (corpus changed)", str(cm.exception))
            self.assertEqual(tree_bytes(paths.RESULTS), before)

    def test_a_failed_snapshot_write_keeps_the_previous_snapshot(self):
        """Every snapshot write in turn fails after its temporary file is written: the snapshot on
        disk is the previous commit, whole, and the resume ends where an uninterrupted run ends —
        a write that fails just after an iteration's directory is allocated costs no iteration."""
        ref, *_ = reference(life_cycle)
        writes = {"n": 0}
        w = life_cycle()
        with Fixture(w) as f:
            real_replace = jsonl.os.replace

            def count(src, dst):
                if Path(dst).name == "state.json":
                    writes["n"] += 1
                real_replace(src, dst)
            with mock.patch.object(jsonl.os, "replace", count):
                f.drive()
        self.assertGreater(writes["n"], 20)
        for k in range(1, writes["n"] + 1):
            w = life_cycle()
            with Fixture(w) as f:
                real_replace = jsonl.os.replace
                seen = {"n": 0, "before": None}

                def replace(src, dst):
                    if Path(dst).name == "state.json":
                        seen["n"] += 1
                        if seen["n"] == k:
                            seen["before"] = Path(dst).read_bytes() if Path(dst).exists() else None
                            raise OSError("no space left on device")
                    real_replace(src, dst)
                with mock.patch.object(jsonl.os, "replace", replace):
                    with self.assertRaises(OSError):
                        loop.run_loop(f.options())
                sf = paths.RESULTS / "r" / "state.json"
                snap = sf.read_bytes() if sf.exists() else None
                self.assertEqual(snap, seen["before"])
                if snap is not None:
                    json.loads(snap)
                self.assertEqual(f.drive()[-1], "complete")
                got = f.state()
            for key in ref:
                if key != "to_user":
                    self.assertEqual(got[key], ref[key], f"{key} after a failed write at commit {k}")

    def test_a_damaged_audit_file_is_kept_as_it_is(self):
        w = life_cycle()
        with Fixture(w) as f:
            rd = paths.RESULTS / "r"
            f.drive(launches=1, max_iterations=1)                  # a run with its options and snapshot
            (rd / "rulings.jsonl").write_bytes(b'{"schema": "case/1"}\nnot json\n')
            before = (rd / "rulings.jsonl").read_bytes()
            self.assertEqual(loop.run_loop(f.options())["status"], "data_integrity_failure")
            self.assertEqual((rd / "rulings.jsonl").read_bytes(), before)

    def test_reopen_plans_the_law_afresh(self):
        """Laws closed in iteration 1 and reopened by the operator are planned again with a fresh
        budget, their node ids reused, their node-ledger entries dropped."""
        from harness.__main__ import Cli
        w = compositions()
        with Fixture(w) as f:
            self.assertEqual(f.drive()[-1], "complete")
            Cli().reopen("r", laws="L-4,L-5")
            led = {e["law"]: e for e in f.state()["ledger"]}
            self.assertEqual((led["L-4"]["state"], led["L-4"]["attempts"], led["L-5"]["state"]), ("open", 0, "open"))
            self.assertEqual(f.drive(max_iterations=4)[-1], "complete")
            st = f.state()
        led = {e["law"]: (e["state"], e["attempts"]) for e in st["ledger"]}
        self.assertEqual(led, {"L-4": ("accepted", 0), "L-5": ("accepted", 0), "L-6": ("accepted", 0), "L-7": ("accepted", 0)})
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_4", "L_5", "L_6", "L_7"])


class Ownership(unittest.TestCase):
    """One process owns the library: a second loop, and a mutating command, are refused while it lives."""

    def test_a_second_owner_is_refused(self):
        import os, subprocess, sys
        lib = Path(tempfile.mkdtemp(prefix="owner-"))
        env = {k: v for k, v in os.environ.items() if k != owner.ENV}
        prog = ("import sys, time; from pathlib import Path; from harness.store import paths, owner; paths.LIBRARY = Path(sys.argv[1]); "
                "{call}; print('held', flush=True); time.sleep(float(sys.argv[2]))")
        holder = subprocess.Popen([sys.executable, "-c", prog.format(call="owner.acquire('r1')"), str(lib), "30"], cwd=paths.REPO,
                                  env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        try:
            self.assertEqual(holder.stdout.readline().strip(), "held")
            for call in ("owner.acquire('r2')", "owner.acquire_for_command('reopen')"):
                r = subprocess.run([sys.executable, "-c", prog.format(call=call), str(lib), "0"], cwd=paths.REPO, env=env,
                                   capture_output=True, text=True, timeout=60)
                self.assertNotEqual(r.returncode, 0, call)
                self.assertIn("another process owns the library", r.stderr, call)
        finally:
            holder.kill(); holder.wait(); holder.stdout.close(); holder.stderr.close()
            shutil.rmtree(lib, ignore_errors=True)
        r = subprocess.run([sys.executable, "-c", prog.format(call="owner.acquire('r3')"), str(lib), "0"], cwd=paths.REPO, env=env,
                           capture_output=True, text=True, timeout=60)
        self.assertEqual(r.returncode, 0, r.stderr)                 # the lock dies with its owner


if __name__ == "__main__":
    unittest.main()
