"""The failure boundaries of the candidate transaction and the in-loop label check, each injected
and shown refused: a withdrawn sibling never shrinks a law's duties (the full plan is required); the
training inputs are bound to their content (labels, traces, manifests, index, splits, limits); a
committed check that is missing is no empty baseline; the production baseline is taken before the
copy and the copy checked against it; a commit a stopped process left is completed or refused at the
library's ownership boundary; an accepted concept's contract is compared verbatim; and the resource
rules (a law known incomplete runs no monitor, concurrency from memory, an isolated copy).

Synthetic libraries and datasets only; the monitor and Explain are the label check's stand-ins, the
gate's toolchain and the whole-library build are stood in for."""
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.phases import candidate as cand
from harness.phases import label_check as lc
from harness.store import jsonl, paths
from harness.store.state import Run
from scripts.tests.test_candidate import CA, CD, NN, Base, Txn, files, node_rec, passing, standard, world
from scripts.tests.test_label_check import FAKE_EXPLAIN, FAKE_MONITOR, make_dataset, set_label, write_exe
from scripts.tests.test_label_repair import L, N, RECS, prior, setting


class FullPlan(Base):
    """F1: the label hook takes every law's whole final plan; a node withdrawn without a new plan
    leaves the law incomplete, which loses its decided recordings, and is refused."""

    def _world(self):
        law, a, b = "TEST-SHRINK-1", "TEST_SHRINK_1_o1", "TEST_SHRINK_1_o2"
        return law, a, b, world({}, {a: node_rec(a), b: node_rec(b)})

    def test_withdrawing_a_sibling_does_not_shrink_the_law(self):
        law, a, b, w = self._world()
        with w as (run, lib), tempfile.TemporaryDirectory() as t:
            t = Path(t)
            ds = make_dataset(t / "data", [("r", law, "compliant", False, {a: [["compliant", {"x": 1}]], b: [["violated", {"x": 1}]]})])
            mon, exp = write_exe(t / "monitor", FAKE_MONITOR), write_exe(t / "explain", FAKE_EXPLAIN)
            ctx = lc.training_context(run.dir, [law], ds.path, lc.Limits(deadline_s=5, memory_gb=1, explain_s=5, jobs=1))
            ctx.seen = {k: v for k, v in ctx.seen.items()}
            before = lc.check_law(law, [a, b], {a: law, b: law}, ds, mon, exp, run.reading_file, ctx.limits)
            self.assertEqual(before.outcome, "mismatch")
            hook = lc.label_hook(ctx, {law: before.to_dict()}, {law: [a, b]}, target=law)
            with mock.patch.object(lc, "build_tools", lambda lib_: (mon, exp)), Txn(run, hooks=(hook,)) as txn:
                ctx.bind(txn)
                txn.apply([cand.Change("node", b, None)])
                results = [r for r in txn.verify() if r.check == "label_non_regression"]
                self.assertEqual(results[0].status, "fail")
                self.assertEqual(txn.label_checks[law].rules, [a, b])
                self.assertEqual(txn.label_checks[law].outcome, "incomplete")
                with self.assertRaises(cand.CommitRefused):
                    txn.commit()

    def test_a_law_without_its_plan_is_not_judged(self):
        law, a, b, w = self._world()
        with w as (run, lib), tempfile.TemporaryDirectory() as t:
            ds = make_dataset(Path(t) / "data", [("r", law, "compliant", False, {})])
            ctx = lc.training_context(run.dir, [law], ds.path)
            hook = lc.label_hook(ctx, {}, {}, target=law)
            with Txn(run, hooks=(hook,)) as txn:
                ctx.bind(txn)
                txn.apply([cand.Change("node", b, node_rec(b), files("node", b, "v2"))])
                results = [r for r in txn.verify() if r.check == "label_non_regression"]
                self.assertEqual((results[0].status, results[0].details), ("unavailable", ["no authoritative plan of the law was given"]))

    def test_a_replan_with_no_node_is_refused(self):
        from harness.phases import label_repair, plan
        from scripts.tests.test_label_repair_session import repair, repairing

        def empty_plan(view, laws, defs, tag="", pending=None, label_repair=False):
            d = view.iter / "plan" / tag
            d.mkdir(parents=True, exist_ok=True)
            (d / "blueprint.jsonl").write_text("")
            return d
        withdraw = {"node_id": N[5], "withdraw": {"kind": "plan", "missing": "a new cut"}}
        with repairing(outputs={"record.jsonl": json.dumps(withdraw)}) as (run, ledger, training, by_id), \
                mock.patch.object(plan, "run_plan", empty_plan):
            self.assertEqual(repair(run, ledger, training, by_id), "rolled_back")
            self.assertIn("has no node", run.label_states[L[5]]["last_repair"]["outcome"])
            self.assertIn(N[5], run.accepted_nodes)


class Inputs(unittest.TestCase):
    """F2 and F7: the comparison set is bound to the inputs' content and the execution limits."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.t = Path(self.tmp.name)
        self.ds = make_dataset(self.t / "data", [("a", "TEST-LAW", "compliant", False, {}), ("b", "TEST-LAW", "violation", True, {})])
        (self.t / "run").mkdir()
        self.first = lc.training_context(self.t / "run", ["TEST-LAW"], self.ds.path)
        self.saved = (self.t / "run" / "comparison_set.json").read_bytes()

    def tearDown(self):
        self.tmp.cleanup()

    def again(self, limits=None):
        return lc.training_context(self.t / "run", ["TEST-LAW"], self.ds.path, limits)

    def refused(self, why: str, limits=None):
        with self.assertRaisesRegex(SystemExit, why):
            self.again(limits)
        self.assertEqual((self.t / "run" / "comparison_set.json").read_bytes(), self.saved)

    def test_each_case_is_bound_by_content(self):
        c = self.first.fixed["cases"]["a"]
        self.assertEqual((c["verdict"], c["judgment_call"]), ("compliant", False))
        self.assertTrue(all(len(c[k]) == 64 for k in ("label", "trace", "manifest")))
        self.assertTrue(self.first.fixed["index"] and "limits" in self.first.fixed)
        self.again()                                                            # unchanged inputs resume

    def test_a_flipped_label_is_refused(self):
        set_label(self.ds, "a", "violation")
        self.refused("recording a")

    def test_a_changed_trace_or_manifest_is_refused(self):
        for k in ("trace", "manifest"):
            f = self.ds.files("a")[k]
            old = f.read_text()
            f.write_text(old[:-1] + ',"x":1}')
            self.refused(f"a: its {k} is not the one the dataset states")
            f.write_text(old)

    def test_a_changed_index_is_refused(self):
        idx = self.ds.path / "INDEX.csv"
        idx.write_text(idx.read_text() + "\r\n")                             # the same rows, another file
        self.refused("index")

    def test_files_that_differ_from_the_index_are_refused_at_the_first_launch(self):
        import csv
        idx = self.ds.path / "INDEX.csv"
        rows = list(csv.DictReader(idx.open()))
        rows[0]["trace_sha256"] = "0" * 64
        with idx.open("w") as f:
            w = csv.DictWriter(f, list(rows[0]))
            w.writeheader(); w.writerows(rows)
        (self.t / "run2").mkdir()
        with self.assertRaisesRegex(SystemExit, "not the one the dataset states"):
            lc.training_context(self.t / "run2", ["TEST-LAW"], self.ds.path)

    def test_inputs_that_drift_during_the_run_are_refused(self):
        self.first.check_inputs(["a", "b"])
        f = self.ds.files("a")["trace"]
        f.write_text('{"scenes":[], "later": true}')
        with self.assertRaisesRegex(ValueError, "trace changed"):
            self.first.check_inputs(["a"])

    def test_a_label_that_changes_during_the_run_is_refused(self):
        self.first.check_inputs(["b"])
        set_label(self.ds, "a", "violation")
        with self.assertRaisesRegex(ValueError, "index .* changed"):
            self.first.check_inputs(["b"])

    def test_other_limits_are_another_configuration(self):
        self.refused("limits", lc.Limits(deadline_s=1800, memory_gb=48))

    def test_a_performance_goal_needs_the_same_limits(self):
        p = {**prior({"a": "deadline"}), "versions": {"limits": "x"}}
        n = {**prior({"a": "match"}), "versions": {"limits": "y"}}
        self.assertFalse(lc.compare(p, n, "performance")["ok"])
        self.assertTrue(lc.compare(p, {**n, "versions": {"limits": "x"}}, "performance")["ok"])


class MissingCheck(unittest.TestCase):
    """F3: a committed check the state names but the run does not hold stops the comparison."""

    def test_missing_wrong_law_and_changed_checks_are_integrity_failures(self):
        with tempfile.TemporaryDirectory() as t:
            t = Path(t)
            self.assertEqual(lc.committed_checks(t, {"LAW": {"state": "waiting"}}), {})      # never checked: no baseline, no error
            with self.assertRaisesRegex(jsonl.DataIntegrityError, "missing"):
                lc.committed_checks(t, {"LAW": {"check": "missing.json"}})
            (t / "c.json").write_text(json.dumps({"law_id": "OTHER"}))
            with self.assertRaisesRegex(jsonl.DataIntegrityError, "not the committed"):
                lc.committed_checks(t, {"LAW": {"check": "c.json"}})
            (t / "c.json").write_text(json.dumps({"law_id": "LAW"}))
            with self.assertRaisesRegex(jsonl.DataIntegrityError, "not the one recorded"):
                lc.committed_checks(t, {"LAW": {"check": "c.json", "check_sha": "0" * 64}})


class CopyRace(Base):
    """F4: production changed while the candidate was copied is refused at the open."""

    def test_a_write_during_the_copy_refuses_the_candidate(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            real = cand.subprocess.run
            args_seen = []

            def copy_then_write(*a, **k):
                args_seen.append(a[0])
                p = real(*a, **k)
                if a and a[0][0] == "cp":
                    for rel, text in files("concept", CD, "changed during the copy").items():
                        (lib / rel).write_text(text)
                return p
            sched = cand.Scheduling()
            with mock.patch.object(cand.subprocess, "run", copy_then_write), sched.pause():
                with self.assertRaisesRegex(cand.NotDrained, "changed while candidate"):
                    cand.Candidate.open(run, base={"core": "c", "ontology": "o"}, validator=passing, hooks=(), scheduling=sched)
            self.assertIn("--reflink=auto", args_seen[0])                        # an isolated copy-on-write copy where it can
            self.assertNotIn(run.opts.run_id, cand._OPEN)


class Boundary(Base):
    """F5: a commit stopped after its commit point is completed by the next owner of the library,
    whichever command takes it, and refused to a reader."""

    class Stop(BaseException):
        pass

    def _stopped(self, run, concepts, nodes):
        real, n = cand._replace, {"k": 0}

        def stop_after_two(src, dst):
            if n["k"] == 2:
                raise self.Stop()
            n["k"] += 1
            real(src, dst)
        with mock.patch.object(cand, "_replace", stop_after_two), self.assertRaises(self.Stop):
            with Txn(run) as txn:
                txn.apply([cand.Change("concept", CA, concepts[CA], files("concept", CA, "v2")),
                           cand.Change("node", NN, nodes[NN], files("node", NN, "v2"))])
                txn.verify()
                txn.commit()
        cand._OPEN.discard(run.opts.run_id)
        import dataclasses
        (run.dir / "options.json").write_text(json.dumps(dataclasses.asdict(run.opts), default=str))

    def test_a_reader_is_refused_and_an_owner_completes_it(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            self._stopped(run, concepts, nodes)
            self.assertIsNotNone(cand.pending())
            with self.assertRaisesRegex(SystemExit, "committed and not yet applied"):
                Run.load(run.opts.run_id)
            with mock.patch.object(cand.owner, "holds", lambda: True):
                loaded = Run.load(run.opts.run_id)
            self.assertIsNone(cand.pending())
            self.assertIn("-- v2", (lib / cand.own_files("node", NN)[0]).read_text())
            self.assertIn("-- v2", (lib / cand.own_files("concept", CA)[0]).read_text())
            self.assertEqual(jsonl.read_json(run.dir / cand.JOURNAL, {})["status"], "applied")
            self.assertEqual(loaded.accepted_nodes[NN], nodes[NN])

    def test_any_command_that_takes_the_library_completes_it(self):
        concepts, nodes = standard()
        with world(concepts, nodes) as (run, lib):
            self._stopped(run, concepts, nodes)
            prog = ("import sys; from pathlib import Path; from harness.store import paths, owner; "
                    "[setattr(paths, k, v) for k, v in paths.library_layout(Path(sys.argv[1])).items()]; "
                    "paths.RESULTS = Path(sys.argv[2]); owner.acquire('command:index')")
            env = {k: v for k, v in os.environ.items() if k not in (cand.owner.ENV, cand.owner.LIB_ENV)}
            r = subprocess.run([sys.executable, "-c", prog, str(lib), str(paths.RESULTS)], cwd=paths.REPO, env=env,
                               capture_output=True, text=True, timeout=120)
            self.assertEqual(r.returncode, 0, r.stderr[-800:])
            self.assertIn("its commit was completed", r.stdout)
            self.assertIsNone(cand.pending())
            self.assertIn("-- v2", (lib / cand.own_files("node", NN)[0]).read_text())


class Verbatim(unittest.TestCase):
    """F6: an accepted concept's contract is compared as written."""

    def test_whitespace_is_a_change_of_the_contract(self):
        concepts, _ = standard()
        old = concepts[CA]
        self.assertTrue(cand.same_id_defects(old, {**old, "contract": old["contract"].replace(" ", "\n")}))
        self.assertEqual(cand.same_id_defects(old, dict(old)), [])


class Resources(Base):

    def test_a_law_known_incomplete_runs_no_monitor(self):
        def forbidden(*a, **k):
            raise AssertionError("a monitor or Explain ran for a law that cannot be complete")
        recs = [r for r in RECS if r[1] == L[3]]
        with setting(recs) as (run, ledger, training, t):
            run.fenced[N[3]] = {"kind": "node", "reason": "gate", "run": "r"}
            for k in (1, 2, 4, 5):
                ledger.entries[L[k]].state = "accepted"
            with mock.patch.object(lc, "build_tools", forbidden), mock.patch.object(lc, "check_law", forbidden), \
                    mock.patch.object(cand.Candidate, "open", forbidden):
                routed = loop.label_route(run, ledger, training, [])
            self.assertEqual(routed, {L[3]: "waiting"})
            chk = json.loads((run.dir / run.label_states[L[3]]["check"]).read_text())
            self.assertEqual([s["status"] for s in chk["scored"]], ["incomplete"])

    def test_concurrency_follows_the_memory_available(self):
        self.assertEqual(lc.jobs_for(1e9), 1)
        self.assertGreaterEqual(lc.jobs_for(0.001), 1)
        with tempfile.TemporaryDirectory() as t:
            ds = make_dataset(Path(t) / "data", [("a", "TEST-LAW", "compliant", False, {})])
            (Path(t) / "run").mkdir()
            ctx = lc.training_context(Path(t) / "run", ["TEST-LAW"], ds.path, lc.Limits(memory_gb=1e9, jobs=8))
            self.assertEqual(ctx.limits.jobs, 1)


if __name__ == "__main__":
    unittest.main()
