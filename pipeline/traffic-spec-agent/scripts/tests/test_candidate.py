"""The candidate transaction: changes to the run's library checked on an isolated copy with every
record they reach, and published whole or not at all.

Most tests run on a small library of their own with stand-ins for Lean (the gate's toolchain step
returns a verdict, the whole-library build is not run) and for the validator; the gate's own scope
check, the registries, the readings, the snapshot and the journal are the real ones. One test builds
a candidate on a copy of the working library with the real Lean toolchain; it is skipped, and so not
verified, where the toolchain or the built Core is absent."""
import copy
import json
import shutil
import tempfile
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.lean import index_sync
from harness.model import nodeid
from harness.phases import candidate as cand
from harness.phases import integrate
from harness.store import jsonl, paths
from harness.store.state import Options, Run, record_digest
from scripts.tests.test_review_routing import ONTO

CA, CB, CD, CE = "drv.motion.cand_a", "drv.motion.cand_b", "drv.motion.cand_d", "drv.motion.cand_e"
NN, NM, NQ = "TEST_CAND_1", "TEST_CAND_2", "TEST_CAND_3"
BASE = {"core": "core-v", "ontology": "onto-v"}


def concept_rec(cid: str, refs=(), contract: str | None = None, values=None) -> dict:
    args = [{"name": "u", "sort": "track"}] + ([{"name": "side", "sort": "literal", "values": list(values)}] if values else [])
    return {"concept_id": cid, "contract": contract or f"The road user's measured speed, as {cid} states it.", "kind": "formula",
            "args": args, "params": [], "elements": [{"span": "measured speed", "atoms": ["kin.speed"], "concepts": list(refs)}],
            "residues": [], "literals": []}


def node_rec(nid: str, concepts=(), **extra) -> dict:
    return {"node_id": nid, "law_refs": [nodeid.law_of(nid)[0]], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
            "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
            "segmentation": [{"id": "o1", "role": "obligation", "text": "proceed slowly"}],
            "elements": [{"span": "o1", "atoms": ["kin.speed"], "derived": list(concepts)}], "params": [], **extra}


def files(kind: str, ident: str, mark: str = "v1") -> dict[str, str]:
    """A record's two files as the gate's scope, import and namespace checks read them."""
    if kind == "concept":
        a, b = cand.own_files(kind, ident)
        return {a: f"import TrafficSpec.Core.Language.Concept\nnamespace {nodeid.concept_namespace(ident)}\n-- {mark}\nend {nodeid.concept_namespace(ident)}\n",
                b: f"import {nodeid.concept_module(ident)}\nimport TrafficSpec.Core.Evidence.Builders\n"
                   f"namespace {nodeid.concept_witness_namespace(ident)}\nend {nodeid.concept_witness_namespace(ident)}\n"}
    a, b = cand.own_files(kind, ident)
    return {a: f"import TrafficSpec.Core.Language.Rule\nnamespace {nodeid.rule_namespace(ident)}\n-- {mark}\nend {nodeid.rule_namespace(ident)}\n",
            b: f"import {nodeid.rule_module(ident)}\nimport TrafficSpec.Core.Evidence.Builders\n"
               f"namespace {nodeid.witness_namespace(ident)}\nend {nodeid.witness_namespace(ident)}\n"}


def passing(txn, nodes, concepts):
    return [cand.CheckResult("validate", r.id, "pass") for r in list(concepts) + list(nodes)]


class Gates:
    """The gate's toolchain step as a stand-in: every call names the library it ran in and the record."""

    def __init__(self, verdicts: dict[str, str] | None = None):
        self.calls, self.verdicts = [], verdicts or {}

    def __call__(self, work, targets, own, namespaces, harness, register=None, phase="witnesses", timeout=gate.GATE_DEADLINE):
        ident = next(t for t in targets if t != "TrafficSpec.Index")
        self.calls.append((str(paths.LIBRARY), ident))
        if register is not None:
            register()
        return gate.Verdict(self.verdicts.get(ident, "OK"), ["stand-in toolchain"])


def tree_bytes(*roots: Path) -> dict[str, bytes]:
    out = {}
    for root in roots:
        for p in sorted(root.rglob("*")):
            if p.is_file() and ".lake" not in p.parts and "iter-001" not in p.parts:
                out[str(p)] = p.read_bytes()
    return out


@contextmanager
def world(concepts: dict[str, dict], nodes: dict[str, dict], library: Path | None = None, reading: dict | None = None):
    """A run `r` whose accepted records are `concepts` and `nodes`, each with its two files, in a
    library of its own (a copy of `library` when given), with its committed snapshot; the harness's
    library and results locations point at it."""
    with tempfile.TemporaryDirectory(dir=paths.RESULTS / "_verify" if library else None) as t:
        t = Path(t)
        lib = t / "library"
        if library is not None:
            shutil.copytree(library, lib, symlinks=True, ignore=shutil.ignore_patterns(".run.lock", ".run.owner.json"))
        else:
            shutil.copytree(paths.CORE, lib / "TrafficSpec" / "Core")              # its sources only: the gate reads Core's tables
            for f in ("lean-toolchain", "lakefile.lean", "lake-manifest.json"):
                shutil.copy2(paths.LIBRARY / f, lib / f)
        for d in ("Rules", "Concepts"):
            if (lib / "TrafficSpec" / d).exists():
                shutil.rmtree(lib / "TrafficSpec" / d)
        if (lib / "TrafficSpecWitness").exists():
            shutil.rmtree(lib / "TrafficSpecWitness")
        (lib / ".inactive.json").write_text(json.dumps({"run": "r", "ids": []}))
        base_reading = lib / "TrafficSpec" / "Readings" / "base_test.json"
        base_reading.parent.mkdir(parents=True, exist_ok=True)
        base_reading.write_text(json.dumps(reading or {"params": [], "aggregates": []}))
        for kind, recs in (("concept", concepts), ("node", nodes)):
            for ident in recs:
                for rel, text in files(kind, ident).items():
                    (lib / rel).parent.mkdir(parents=True, exist_ok=True)
                    (lib / rel).write_text(text)
        layout = {**paths.library_layout(lib), "RESULTS": t / "results"}
        with mock.patch.multiple(paths, **layout):
            (t / "laws.jsonl").write_text("".join(json.dumps({"id": law, "title": law, "text": "A driver shall proceed slowly.", "source": "test"}) + "\n"
                                                  for law in sorted({r["law_refs"][0] for r in nodes.values()})))
            (t / "definitions.jsonl").write_text("")
            run = Run(Options(run_id="r", laws=t / "laws.jsonl", ontology=ONTO.path, reading=base_reading, model="m"))
            run.dir.mkdir(parents=True)
            run.iteration = 1
            shutil.copy2(base_reading, run.reading_file)
            jsonl.write_atomic(run.state_file, json.dumps({"schema": 1, "run_id": "r", "iteration": 1, "ledger": [], "concept_ledger": [],
                                                           "node_ledger": [], "accepted_nodes": nodes, "accepted_concepts": concepts,
                                                           "fenced": {}, "fence_history": []}))
            run.restore_state()
            run.load_accepted()
            index_sync.write_index()
            yield run, lib


def standard() -> tuple[dict, dict]:
    """A concept used by a concept used by a rule (A ← B ← N), an unrelated concept D and its rule
    M, and a concept E with its rule Q."""
    concepts = {CA: concept_rec(CA), CB: concept_rec(CB, [CA]), CD: concept_rec(CD), CE: concept_rec(CE)}
    nodes = {NN: node_rec(NN, [CB]), NM: node_rec(NM, [CD]), NQ: node_rec(NQ, [CE])}
    return concepts, nodes


class Txn:
    """A transaction opened with the scheduling paused, the gate's toolchain and the whole-library
    build stood in for, and the given validator and hooks."""

    def __init__(self, run, validator=passing, hooks=(), gates: Gates | None = None):
        self.run, self.validator, self.hooks = run, validator, hooks
        self.gates = gates or Gates()
        self.sched = cand.Scheduling()

    def __enter__(self) -> cand.Candidate:
        self.stack = [self.sched.pause(), mock.patch.object(gate, "_toolchain", self.gates),
                      mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set()))]
        for c in self.stack:
            c.__enter__()
        self.txn = cand.Candidate.open(self.run, base=BASE, validator=self.validator, hooks=self.hooks, scheduling=self.sched)
        return self.txn

    def __exit__(self, *exc):
        try:
            self.txn.__exit__(*exc)
        finally:
            for c in reversed(self.stack):
                c.__exit__(None, None, None)
        return False


class Base(unittest.TestCase):
    def setUp(self):
        cand._OPEN.clear()                   # a test that failed with a transaction open does not hold the next one
        self.addCleanup(cand._OPEN.clear)


class Commit(Base):

    def test_a_multi_record_change_is_committed_whole(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            t = Txn(run)
            with t as txn:
                new_a = files("concept", CA, "v2")
                new_n = node_rec(NN, [CB], narrowings=[{"span": "o1", "why": "read as measured", "kind": "reading"}])
                txn.apply([cand.Change("concept", CA, concepts[CA], new_a),
                           cand.Change("node", NN, new_n, files("node", NN, "v2"))])
                for rel in new_a:
                    self.assertEqual((lib / rel).read_text(), files("concept", CA)[rel])          # production untouched before the commit
                results = txn.verify()
                self.assertTrue(all(r.status == "pass" for r in results), results)
                self.assertEqual({s for c, s in [(r.check, r.subject) for r in results] if c == "gate"}, {CA, CB, NN})
                self.assertEqual({lib_ for lib_, _i in t.gates.calls}, {str(txn.library)})
                out = txn.commit()
            self.assertEqual(out["changed"], {CA: "concept", NN: "node"})
            for rel, text in {**new_a, **files("node", NN, "v2")}.items():
                self.assertEqual((lib / rel).read_text(), text)
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual(snap["accepted_nodes"][NN]["narrowings"], new_n["narrowings"])
            self.assertIn("accepted_in", snap["accepted_concepts"][CA])
            self.assertEqual(record_digest(snap["accepted_concepts"][CB]), record_digest(concepts[CB]))   # reached, checked, not rewritten
            self.assertEqual(snap["accepted_concepts"][CB]["callers"], [NN])
            self.assertEqual(jsonl.read_json(run.dir / cand.JOURNAL, {})["status"], "applied")
            self.assertEqual([json.loads(l)["node_id"] for l in run.accepted_file.read_text().splitlines()], [NN, NM, NQ])
            self.assertIn(nodeid.rule_module(NN), paths.INDEX_FILE.read_text())
            self.assertEqual(jsonl.read_json(txn.area / "status.json", {})["status"], "committed")
            self.assertFalse((txn.library / ".lake").exists())

    def test_a_rollback_leaves_production_as_it_was(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            before = tree_bytes(lib, run.dir)
            with Txn(run, gates=Gates({nodeid.rule_module(NN): "WITNESS_FAIL"})) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                txn.stage_rulings([{"subject": CA, "ruling": "upheld"}])
                results = txn.verify()
                self.assertEqual([r.status for r in results if r.subject == NN], ["pass", "fail"])
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()
                txn.rollback("a caller's witness failed")
            self.assertEqual(tree_bytes(lib, run.dir), before)
            self.assertFalse((run.dir / cand.JOURNAL).exists())
            self.assertFalse((run.dir / "rulings.jsonl").exists())
            st = jsonl.read_json(txn.area / "status.json", {})
            self.assertEqual((st["status"], st["reason"]), ("rolled_back", "a caller's witness failed"))
            self.assertTrue((txn.area / "checks.jsonl").exists() and (txn.area / "rulings.jsonl").exists())   # kept as diagnostics

    def test_a_transaction_left_open_is_rolled_back(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            before = tree_bytes(lib, run.dir)
            with self.assertRaises(RuntimeError):
                with Txn(run) as txn:
                    txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                    raise RuntimeError("stopped")
            self.assertEqual(txn.status, "rolled_back")
            self.assertEqual(tree_bytes(lib, run.dir), before)


class Crash(Base):
    class Stop(BaseException):
        pass

    def _committed_world(self):
        concepts, nodes = standard()
        new = {**files("concept", CA, "v2"), **files("node", NN, "v2")}
        new_n = node_rec(NN, [CB], params=["p.cand_window"])
        return concepts, nodes, new, new_n

    def test_a_stop_after_the_commit_point_is_completed_by_recovery(self):
        concepts, nodes, new, new_n = self._committed_world()
        with world(concepts, nodes) as (run, lib):
            real, n = cand._replace, {"k": 0}

            def stop_after_two(src, dst):
                if n["k"] == 2:
                    raise self.Stop()
                n["k"] += 1
                real(src, dst)
            with mock.patch.object(cand, "_replace", stop_after_two), self.assertRaises(self.Stop):
                with Txn(run) as txn:
                    txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2")),
                               cand.Change("node", NN, new_n, files("node", NN, "v2"))])
                    txn.verify()
                    txn.commit()
            on_disk = {rel: (lib / rel).read_text() for rel in new}
            self.assertNotEqual(on_disk, new)                                   # the stop left a mixed library
            self.assertEqual(jsonl.read_json(run.state_file, {})["accepted_nodes"][NN], nodes[NN])
            cand._OPEN.discard("r")                                             # the stopped process held it
            fresh = Run(run.opts)
            self.assertIn("completed", cand.recover(fresh))
            self.assertEqual({rel: (lib / rel).read_text() for rel in new}, new)
            self.assertEqual(jsonl.read_json(run.state_file, {})["accepted_nodes"][NN]["params"], ["p.cand_window"])
            self.assertEqual(json.loads(run.accepted_file.read_text().splitlines()[0])["params"], ["p.cand_window"])
            self.assertEqual(jsonl.read_json(run.dir / cand.JOURNAL, {})["status"], "applied")
            self.assertEqual(jsonl.read_json(txn.area / "status.json", {})["status"], "committed")
            self.assertIsNone(cand.recover(fresh))                              # applied once

    def test_a_stop_before_the_commit_point_leaves_the_old_version(self):
        concepts, nodes, new, new_n = self._committed_world()
        with world(concepts, nodes) as (run, lib):
            before = tree_bytes(lib, run.dir)
            real = cand.jsonl.write_atomic

            def stop_at_journal(path, text):
                if Path(path).name == cand.JOURNAL:
                    raise self.Stop()
                real(path, text)
            with mock.patch.object(cand.jsonl, "write_atomic", stop_at_journal), self.assertRaises(self.Stop):
                with Txn(run) as txn:
                    txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2")),
                               cand.Change("node", NN, new_n, files("node", NN, "v2"))])
                    txn.verify()
                    txn.commit()
            cand._OPEN.discard("r")
            self.assertIsNone(cand.recover(Run(run.opts)))
            self.assertEqual(tree_bytes(lib, run.dir), before)
            self.assertEqual(jsonl.read_json(txn.area / "status.json", {})["status"], "abandoned")
            self.assertFalse((txn.library / ".lake").exists())


class Closure(Base):

    def test_an_indirect_caller_is_reached(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, _lib):
            with Txn(run) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                aff = txn.affected()
                self.assertEqual(list(aff.closure)[0], CA)                     # the changed records first
                self.assertEqual(set(aff.closure), {CA, CB, NN})               # not D, M, E or Q
                self.assertEqual(aff.why[CB], [f"reaches `{CA}`"])
                self.assertEqual(aff.why[NN], [f"reaches `{CA}`"])
                self.assertEqual(aff.laws, [nodeid.law_of(NN)[0]])

    def test_gates_run_in_the_candidate_in_dependency_order(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            gates = Gates()
            with Txn(run, gates=gates) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                txn.verify()
                self.assertEqual([i for _l, i in gates.calls], [nodeid.concept_module(CA), nodeid.concept_module(CB), nodeid.rule_module(NN)])
                self.assertEqual({l for l, _i in gates.calls}, {str(txn.library)})
                reg = json.loads((txn.area / "gates" / NN / "registry.json").read_text())
                self.assertEqual((reg["nodes"], reg["concepts"]), ([NN], [CA, CB]))      # its own dependency selection
            self.assertEqual(paths.LIBRARY, lib)

    def test_a_caller_of_a_withdrawn_record_is_reached_through_the_library_before(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, _lib):
            with Txn(run, validator=passing) as txn:
                txn.apply([cand.Change("concept", CE, None)])
                aff = txn.affected()
                self.assertEqual(aff.removed, {CE})
                self.assertIn(NQ, aff.closure)
                self.assertIn(f"reaches `{CE}`", aff.why[NQ])
                self.assertNotIn(CE, aff.closure)

    def test_a_reading_value_reaches_the_rules_that_read_it(self):
        concepts, nodes = standard()
        nodes[NM] = node_rec(NM, [CD], params=["p.cand_window"])
        with world(concepts, nodes, reading={"params": [{"name": "p.cand_window", "value": 3, "unit": "s", "convention": "t", "source": "t",
                                                         "proposed": f"r/iter-001 {NQ}"}], "aggregates": []}) as (run, _lib):
            with Txn(run) as txn:
                txn.apply([], params=[{"name": "p.cand_window", "value": 5, "unit": "s", "convention": "t", "source": "t"}],
                          origin=f"r/iter-001 {NQ}")
                aff = txn.affected()
                self.assertEqual(set(aff.closure), {NM})
                self.assertEqual(aff.why[NM], ["its dependency context changed"])


class Scope(Base):

    def test_a_change_outside_a_records_own_files_is_refused_whole(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            with Txn(run) as txn:
                before = tree_bytes(txn.library)
                core = {"TrafficSpec/Core/Vocab/Atoms.lean": "-- changed\n"}
                with self.assertRaisesRegex(cand.ChangeRefused, "outside the record's own files"):
                    txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2")),
                               cand.Change("node", NN, nodes[NN], {**files("node", NN, "v2"), **core})])
                self.assertEqual(tree_bytes(txn.library), before)
                self.assertEqual(txn.changed, {})

    def test_a_file_written_in_the_candidate_outside_the_write_set_fails_the_gate(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            with Txn(run) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                (txn.library / nodeid.concept_path(CD)).write_text("-- written behind the transaction's back\n")
                results = txn.verify()
                gates = {r.subject: r for r in results if r.check == "gate"}
                self.assertEqual(gates[CA].status, "fail")
                self.assertEqual(gates[CA].details[0], "SCOPE_VIOLATION")
                self.assertIn(f"library/{nodeid.concept_path(CD)}", gates[CA].details[1])
                self.assertEqual((gates[CB].status, gates[NN].status), ("not_run", "not_run"))
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()

    def test_inherited_records_and_accepted_concept_interfaces_are_refused(self):
        concepts, nodes = standard()
        concepts[CD] = concept_rec(CD, values=["left"])
        with world(concepts, nodes) as (run, lib):
            run.base_concepts = {"drv.motion.cand_base": concept_rec("drv.motion.cand_base")}
            with Txn(run) as txn:
                cases = [(cand.Change("concept", CA, {**concepts[CA], "contract": concepts[CA]["contract"] + " Always."}), "contract"),
                         (cand.Change("concept", CD, concept_rec(CD, values=["left", "right"])), "args"),
                         (cand.Change("concept", CA, {**concepts[CA], "params": [{"name": "tol", "unit": "m/s"}]}), "params"),
                         (cand.Change("concept", "drv.motion.cand_base", concept_rec("drv.motion.cand_base")), "read-only")]
                for ch, why in cases:
                    with self.assertRaisesRegex(cand.ChangeRefused, why):
                        txn.apply([ch])
                same = {**concepts[CA], "contract": concepts[CA]["contract"].replace(" ", "\n")}   # whitespace only: still another text
                with self.assertRaisesRegex(cand.ChangeRefused, "contract"):
                    txn.apply([cand.Change("concept", CA, same, files("concept", CA, "v2"))])
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])   # the body only
                self.assertEqual(txn.changed, {CA: "concept"})


class Gate(Base):
    """The single-task scope check is the one it was: only the task's own files and the files its task
    directory tolerates may change; a candidate's scope holds only inside the candidate's library."""

    def test_the_single_task_scope_is_unchanged(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t) / "repo"
            (root / "library" / "TrafficSpec").mkdir(parents=True)
            for f in ("a.lean", "b.lean", "c.lean"):
                (root / "library" / "TrafficSpec" / f).write_text("x")
            work = Path(t) / "work"
            work.mkdir()
            with mock.patch.multiple(paths, REPO=root, **paths.library_layout(root / "library")):
                base = gate.repo_digest()
                for f in ("a.lean", "b.lean", "c.lean"):
                    (root / "library" / "TrafficSpec" / f).write_text("y")
                own = {"library/TrafficSpec/a.lean"}
                self.assertEqual(gate.scope_stray(base, own, work), ["library/TrafficSpec/b.lean", "library/TrafficSpec/c.lean"])
                (work / "concurrent.json").write_text(json.dumps(["library/TrafficSpec/b.lean"]))
                self.assertEqual(gate.scope_stray(base, own, work), ["library/TrafficSpec/c.lean"])
                scope = gate.CandidateScope(root / "elsewhere", frozenset({"library/TrafficSpec/c.lean"}))
                with gate.candidate_scope(scope):
                    stray = gate.scope_stray(base, own, work)
                self.assertEqual(len(stray), 1)
                self.assertIn("candidate scope", stray[0])
                self.assertEqual(gate.scope_stray(base, own, work), ["library/TrafficSpec/c.lean"])   # the scope ended with its block

    def test_the_candidate_scope_tolerates_its_write_set_only(self):
        with tempfile.TemporaryDirectory() as t:
            tree = Path(t) / "tree"
            (tree / "library" / "TrafficSpec").mkdir(parents=True)
            for f in ("a.lean", "b.lean", "c.lean"):
                (tree / "library" / "TrafficSpec" / f).write_text("x")
            base = gate.repo_digest(tree)
            for f in ("a.lean", "b.lean", "c.lean"):
                (tree / "library" / "TrafficSpec" / f).write_text("y")
            (Path(t) / "work").mkdir()
            (Path(t) / "work" / "concurrent.json").write_text(json.dumps(["library/TrafficSpec/c.lean"]))   # not read in a candidate
            with mock.patch.multiple(paths, **paths.library_layout(tree / "library")), \
                    gate.candidate_scope(gate.CandidateScope(tree, frozenset({"library/TrafficSpec/b.lean"}))):
                # a record's own file is tolerated only when the transaction declared it
                self.assertEqual(gate.scope_stray(base, {"library/TrafficSpec/a.lean"}, Path(t) / "work"),
                                 ["library/TrafficSpec/a.lean", "library/TrafficSpec/c.lean"])


class Baseline(Base):

    def test_a_commit_is_refused_when_the_production_baseline_moved(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            with Txn(run) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                txn.verify()
                (lib / nodeid.concept_path(CD)).write_text("-- a write to production while the candidate was open\n")
                with self.assertRaisesRegex(cand.CommitRefused, r"baseline moved.*tree"):
                    txn.commit()
                self.assertEqual(txn.status, "open")
                txn.rollback("baseline moved")
            self.assertEqual((lib / nodeid.concept_path(CA)).read_text(), files("concept", CA)[nodeid.concept_path(CA)])

    def test_the_drain_is_a_precondition_of_open_and_commit(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            sched = cand.Scheduling()
            with self.assertRaisesRegex(cand.NotDrained, "not paused"):
                cand.Candidate.open(run, base=BASE, validator=passing, hooks=(), scheduling=sched)
            with sched.task():
                with self.assertRaisesRegex(cand.NotDrained, "still running"):
                    with sched.pause(timeout=0.05):
                        pass
            self.assertFalse(sched.paused)
            with mock.patch.object(gate, "_toolchain", Gates()), \
                    mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())):
                with sched.pause():
                    txn = cand.Candidate.open(run, base=BASE, validator=passing, hooks=(), scheduling=sched)
                    with self.assertRaises(cand.NotDrained):
                        with sched.task():
                            pass
                    txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                    txn.verify()
                with self.assertRaisesRegex(cand.NotDrained, "not paused"):
                    txn.commit()                                  # scheduling resumed before the commit
                with sched.pause():
                    txn.commit()
            self.assertEqual((lib / nodeid.concept_path(CA)).read_text(), files("concept", CA, "v2")[nodeid.concept_path(CA)])

    def test_results_are_bound_to_the_versions_they_ran_on(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            with Txn(run) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                results = txn.verify()
                self.assertEqual(set(results[0].versions), {"candidate", "core", "toolchain", "reading", "gate", "data", "label_contract",
                                                            "scoring", "limits"})
                txn.bind(data="data-v1")
                with self.assertRaisesRegex(cand.CommitRefused, "data"):
                    txn.commit()
                txn.verify()
                txn.apply([cand.Change("node", NN, node_rec(NN, [CB], params=[]), files("node", NN, "v3"))])
                with self.assertRaisesRegex(cand.CommitRefused, "not verified"):
                    txn.commit()
                txn.verify()
                txn.commit()

    def test_the_default_hooks_review_the_concept_and_refuse_until_the_label_check_runs(self):
        from harness.phases import review
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib), \
                mock.patch.object(review, "review_concept", lambda run_, rec, extras, out: review.ReviewOutcome("accepted")):
            with Txn(run, hooks=cand.DEFAULT_HOOKS) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                results = txn.verify()
                hooked = {(r.check, r.subject): r.status for r in results if r.check not in ("gate", "validate", "witnesses")}
                self.assertEqual(hooked, {("concept_review", CA): "pass", ("context", CB): "pass", ("context", NN): "pass",
                                          ("label_non_regression", nodeid.law_of(NN)[0]): "not_run"})
                with self.assertRaisesRegex(cand.CommitRefused, "label_non_regression"):
                    txn.commit()

    def test_a_failed_validation_gates_nothing_that_depends_on_it(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            gates = Gates()
            refuse_b = lambda txn, nodes_, concepts_: [cand.CheckResult("validate", r.id, "fail" if r.id == CB else "pass", ["stub"])
                                                       for r in list(concepts_) + list(nodes_)]
            with Txn(run, validator=refuse_b, gates=gates) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2"))])
                results = txn.verify()
                self.assertEqual([i for _l, i in gates.calls], [nodeid.concept_module(CA)])
                self.assertEqual({r.subject: r.status for r in results if r.check == "gate"}, {CA: "pass", CB: "not_run", NN: "not_run"})


class Readings(Base):
    PROPOSAL = {"name": "p.cand_window", "value": 4, "unit": "s", "convention": "a stand-in convention", "source": "test"}

    def test_reading_proposals_stay_in_the_candidate_until_it_commits(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            base_file = Path(run.opts.reading)
            prod = (run.reading_file.read_text(), base_file.read_text())
            new_n = node_rec(NN, [CB], params=["p.cand_window"], param_proposals=[self.PROPOSAL],
                             assumptions=[{"id": "asm.cand_test", "meaning": "the scene is lit"}])
            with Txn(run) as txn:
                txn.apply([cand.Change("node", NN, new_n, files("node", NN, "v2"))])
                self.assertEqual(txn.reading.params["p.cand_window"]["value"], 4)
                self.assertIn("asm.cand_test", txn.reading.declarations())
                self.assertEqual((run.reading_file.read_text(), base_file.read_text()), prod)
                txn.verify()
                self.assertEqual((run.reading_file.read_text(), base_file.read_text()), prod)
                txn.rollback("not wanted")
            self.assertEqual((run.reading_file.read_text(), base_file.read_text()), prod)
            with Txn(run) as txn:
                txn.apply([cand.Change("node", NN, new_n, files("node", NN, "v2"))])
                txn.verify()
                txn.commit()
            for f in (run.reading_file, base_file):
                d = json.loads(f.read_text())
                self.assertEqual([p["name"] for p in d["params"]], ["p.cand_window"])
                self.assertEqual([x["id"] for x in d["declarations"]], ["asm.cand_test"])


    def test_a_declaration_with_another_meaning_is_refused(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            with Txn(run) as txn:
                txn.apply([], declarations=[{"id": "asm.cand_test", "meaning": "the scene is lit"}], origin=f"r/iter-001 {NN}")
                with self.assertRaisesRegex(cand.ChangeRefused, "asm.cand_test"):
                    txn.apply([], declarations=[{"id": "asm.cand_test", "meaning": "the scene is dark"}], origin=f"r/iter-001 {NN}")
                with self.assertRaisesRegex(cand.ChangeRefused, "asm.cand_test"):
                    txn.apply([cand.Change("node", NN, node_rec(NN, [CB], assumptions=[{"id": "asm.cand_test", "meaning": "the scene is dark"}]))])
                self.assertEqual(txn.reading.declarations()["asm.cand_test"]["meaning"], "the scene is lit")


@unittest.skipUnless(shutil.which("lake") and (paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core" / "Evidence"
                                                / "Adequacy.olean").exists(), "the Lean toolchain or the built Core is absent: not verified")
class RealLean(Base):
    """A candidate that adds a concept and a rule to a copy of the working library: both gated with
    the real toolchain in the candidate's own copy, the whole candidate registry built with every
    witness, then committed to the copy that stands for production."""

    def test_a_tiny_candidate_builds_gates_and_commits(self):
        from scripts.tests import test_gate_phases as G
        from scripts.tests import test_precondition_continuity as P
        (paths.RESULTS / "_verify").mkdir(parents=True, exist_ok=True)
        reading = {"params": [{"name": "p.halt_window", "value": 3, "unit": "s", "convention": "fixture"},
                              {"name": "p.crawl", "value": 3, "unit": "m/s", "convention": "fixture"}], "aggregates": []}
        with world({}, {}, library=paths.LIBRARY, reading=reading) as (run, lib):
            c_files = dict(zip(cand.own_files("concept", G.CID),
                               (G.CONCEPT.replace("UNIT", ".metrePerSecond"), G.CONCEPT_WITNESS.replace("SCENARIOS", "\n  , ".join((G.HOLDS, G.FAILS, G.BLIND))))))
            n_files = dict(zip(cand.own_files("node", P.NODE_ID), (P.RULE, P.WITNESS.replace("BRANCH", ".notApplicable"))))
            sched = cand.Scheduling()
            with sched.pause():
                with cand.Candidate.open(run, base=BASE, validator=passing, hooks=(), scheduling=sched) as txn:
                    txn.apply([cand.Change("concept", G.CID, copy.deepcopy(G.CONCEPT_RECORD), c_files),
                               cand.Change("node", P.NODE_ID, copy.deepcopy(P.RECORD), n_files)])
                    results = txn.verify()
                    self.assertEqual([(r.check, r.subject, r.status) for r in results],
                                     [("validate", G.CID, "pass"), ("validate", P.NODE_ID, "pass"), ("gate", G.CID, "pass"),
                                      ("gate", P.NODE_ID, "pass"), ("witnesses", "library", "pass")], [r.details for r in results])
                    txn.commit()
            for rel, text in {**c_files, **n_files}.items():
                self.assertEqual((lib / rel).read_text(), text)
            snap = jsonl.read_json(run.state_file, {})
            self.assertEqual(snap["accepted_concepts"][G.CID]["reads"], ["kin.speed"])
            self.assertIn(P.NODE_ID, snap["accepted_nodes"])
            index = paths.INDEX_FILE.read_text()
            self.assertIn(nodeid.concept_module(G.CID), index)
            self.assertIn(nodeid.rule_module(P.NODE_ID), index)


if __name__ == "__main__":
    unittest.main()
