"""The coding stages' scheduler: each item's coding, gate, review and outcome are one task, at most
`workers` at once, and an item is submitted only once every node it composes and every concept it
calls is accepted, as the loop's own thread has applied it.

The real loop runs in the scripted world of `test_recovery` (its sessions, gates and reviews are
stubs keyed by the record and the iteration); a session is held back here by waiting for a
condition on the committed snapshot, so a scheduler that waited for the whole stage would time out.
"""
import hashlib
import json
import tempfile
import time
import unittest
from pathlib import Path
from unittest import mock

from harness import loop
from harness.agents import session
from harness.checks import gate
from harness.model import nodeid
from harness.phases import code as code_phase, review as review_phase
from harness.store import paths
from harness.store.budget import BudgetPaused
from scripts.tests.test_recovery import Crash, World, Fixture, _iteration_of, compositions, concept, decisions, node


def committed() -> dict:
    """The progress of the iteration as the snapshot holds it."""
    f = paths.RESULTS / "r" / "state.json"
    return (json.loads(f.read_text()).get("prog") or {}) if f.exists() else {}


def wait_for(cond, timeout: float = 30.0) -> bool:
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if cond():
            return True
        time.sleep(0.02)
    return False


def subject(out_dir) -> tuple[str, int]:
    d = Path(out_dir)
    ident = loop._concept_id_of_dirname(d.name) if d.name.startswith("concept__") else d.name
    return ident, _iteration_of(d)


class Sessions:
    """A wrapper around the scripted coding session: `before(ident, iteration)` runs first, `after`
    once the session has written its files."""

    def __init__(self, before=None, after=None):
        self.before, self.after, self.real = before, after, session.run

    def __call__(self, prompt, cwd=None, out_dir=None, opts=None, **kw):
        if self.before:
            self.before(*subject(out_dir))
        out = self.real(prompt, cwd=cwd, out_dir=out_dir, opts=opts, **kw)
        if self.after:
            self.after(*subject(out_dir))
        return out


def decided(kind: str, ident: str, state: str = "OK"):
    return lambda: committed().get(kind, {}).get(ident) == state


def laws3(w_extra=None) -> World:
    w = World({"L-1": "shall stop.", "L-2": "shall yield.", "L-3": "shall slow."})
    w.plans = {f"L-{i}": [node(f"L_{i}", t, f"L-{i}")] for i, t in ((1, "shall stop."), (2, "shall yield."), (3, "shall slow."))}
    return w


class RollingScheduler(unittest.TestCase):

    def test_a_stuck_task_does_not_delay_the_others(self):
        """L_1's session does not finish until L_2 and L_3, coded beside it and after it, have been
        reviewed and decided: two workers, one of them held the whole time."""
        w = laws3()
        seen = {}

        def before(ident, it):
            if (ident, it) == ("L_1", 1):
                seen["others"] = wait_for(lambda: decided("nodes", "L_2")() and decided("nodes", "L_3")())
        with Fixture(w, workers=2) as f:
            with mock.patch.object(session, "run", Sessions(before)):
                self.assertEqual(f.drive(), ["complete"])
            st = f.state()
        self.assertTrue(seen["others"], "L_2 and L_3 were not decided while L_1's session ran")
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_1", "L_2", "L_3"])
        self.assertEqual(w.calls[("code", "L_1", 1)], 1)

    def test_a_dependent_starts_only_once_its_provider_is_accepted(self):
        """L_6 composes L_7: with four workers free, L_6's session starts only after L_7, slowed down,
        is accepted."""
        w = World({"L-6": "shall merge.", "L-7": "shall slow."})
        w.plans = {"L-6": [node("L_6", "shall merge.", "L-6", compositions=["L_7"])], "L-7": [node("L_7", "shall slow.", "L-7")]}
        seen = {}

        def before(ident, it):
            if ident == "L_7":
                time.sleep(0.3)
            if ident == "L_6":
                seen["provider"] = committed().get("nodes", {}).get("L_7")
        with Fixture(w, workers=4) as f:
            with mock.patch.object(session, "run", Sessions(before)):
                self.assertEqual(f.drive(), ["complete"])
        self.assertEqual(seen["provider"], "OK")
        calls = [e[1:3] for e in w.log if e[0] == "call" and e[1] == "code"]
        self.assertLess(calls.index(("code", "L_7")), calls.index(("code", "L_6")))

    def test_a_dependent_of_a_returned_provider_is_held_not_coded(self):
        """L_7's gate returns it in iteration 1: L_6, which composes it, is never coded in that
        iteration and is held uncharged; both are accepted once L_7 is repaired."""
        w = compositions()
        with Fixture(w, workers=4) as f:
            f.drive()
            st = f.state()
        self.assertEqual(w.calls[("code", "L_6", 1)], 0)
        self.assertEqual(w.calls[("code", "L_6", 2)], 1)
        led = {e["law"]: (e["state"], e["attempts"]) for e in st["ledger"]}
        self.assertEqual((led["L-6"], led["L-7"]), (("accepted", 0), ("accepted", 0)))

    def test_a_concept_chain_is_coded_in_order(self):
        """stop calls halt, which calls slow, and L_3 uses stop: each is coded only once the one it
        calls is accepted, with every worker free."""
        w = World({"L-3": "shall halt."})
        w.plans = {"L-3": [concept("drv.motion.slow", users=["L_3"]), concept("drv.motion.halt", calls=["drv.motion.slow"], users=["L_3"]),
                           concept("drv.motion.stop", calls=["drv.motion.halt"], users=["L_3"]),
                           node("L_3", "shall halt.", "L-3", derived=["drv.motion.stop"])]}
        callee = {"drv.motion.halt": ("concepts", "drv.motion.slow"), "drv.motion.stop": ("concepts", "drv.motion.halt"),
                  "L_3": ("concepts", "drv.motion.stop")}
        seen = {}

        def before(ident, it):
            if ident == "drv.motion.slow":
                time.sleep(0.3)
            if ident in callee:
                kind, c = callee[ident]
                seen[ident] = committed().get(kind, {}).get(c)
        with Fixture(w, workers=4) as f:
            with mock.patch.object(session, "run", Sessions(before)):
                self.assertEqual(f.drive(), ["complete"])
            st = f.state()
        self.assertEqual(seen, {"drv.motion.halt": "OK", "drv.motion.stop": "OK", "L_3": "OK"})
        order = [e[2] for e in w.log if e[0] == "call" and e[1] == "code"]
        self.assertEqual(order, ["drv.motion.slow", "drv.motion.halt", "drv.motion.stop", "L_3"])
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_3"])


class ScopeBesideOtherTasks(unittest.TestCase):
    """The gate's own scope check (`gate.scope_stray`) on the files the loop records for each task
    (`concurrent.json`: cumulative, written by the loop's thread)."""

    def run_world(self, w: World, before=None, after=None) -> dict:
        verdicts = {}
        with Fixture(w, workers=2) as f:
            scripted = gate.run_gate

            def run_gate(n, reading, baseline, d, budget_used=0, budget=0, accepted_concepts=None, acquisition=None):
                own = {gate.lib_rel(nodeid.rule_path(n.id)), gate.lib_rel(nodeid.witness_path(n.id))}
                stray = gate.scope_stray(baseline, own, Path(d))
                v = gate.Verdict("SCOPE_VIOLATION", stray) if stray else scripted(n, reading, baseline, d, budget_used, budget, accepted_concepts)
                verdicts[(n.id, _iteration_of(Path(d)))] = (v.verdict, v.details)
                return v
            with mock.patch.object(gate, "run_gate", run_gate), mock.patch.object(session, "run", Sessions(before, after)):
                f.drive()
            self.concurrent = json.loads((paths.RESULTS / "r" / "iter-001" / "code" / "L_1" / "concurrent.json").read_text())
            self.reading = json.loads((f.root / "reading.json").read_text())
        return verdicts

    def test_a_task_started_later_and_still_running_is_not_its_violation(self):
        """L_3 starts after L_1 (once L_2 ends) and writes its files; L_1 gates while L_3's session
        still runs: L_3's files are not L_1's violation."""
        w = laws3()
        seen = {}

        def before(ident, it):
            if (ident, it) == ("L_1", 1):
                seen["L_3 wrote"] = wait_for(lambda: seen.get("L_3 files"))

        def after(ident, it):
            if (ident, it) == ("L_3", 1):
                seen["L_3 files"] = True
                seen["L_1 first"] = wait_for(decided("nodes", "L_1"))
        verdicts = self.run_world(w, before, after)
        self.assertTrue(seen["L_3 wrote"] and seen["L_1 first"])
        self.assertEqual(verdicts[("L_1", 1)], ("OK", []))
        self.assertEqual(verdicts[("L_3", 1)], ("OK", []))
        self.assertIn(gate.lib_rel(nodeid.rule_path("L_3")), self.concurrent)

    def test_a_task_that_ended_before_it_gates_is_not_its_violation(self):
        """L_2 (started with L_1) and L_3 (started while L_1 ran) are coded, accepted and their files
        kept before L_1 gates: none of that is L_1's. L_3's parameter proposal entered the reading
        before the stage started, so the reading is no file the stage writes beside a session."""
        w = laws3()
        w.plans["L-3"][0]["params"] = ["p.pause"]
        w.plans["L-3"][0]["param_proposals"] = [{"name": "p.pause", "value": 2.0, "unit": "s", "convention": "c", "source": "s"}]
        seen = {}

        def before(ident, it):
            if (ident, it) == ("L_1", 1):
                seen["L_3"] = wait_for(decided("nodes", "L_3"))
        verdicts = self.run_world(w, before)
        self.assertTrue(seen["L_3"], "L_3 was not decided while L_1's session ran")
        self.assertEqual(verdicts[("L_1", 1)], ("OK", []))
        self.assertEqual([p["name"] for p in self.reading["params"]], ["p.pause"])
        for i in ("L_2", "L_3"):
            self.assertIn(gate.lib_rel(nodeid.rule_path(i)), self.concurrent)
        self.assertNotIn("reading.json", self.concurrent)
        self.assertTrue({"library/TrafficSpec/Gaps/proposals.jsonl", "library/TrafficSpec/Gaps/counter.txt"} <= set(self.concurrent))

    def test_a_file_of_no_overlapping_task_is_still_its_violation(self):
        """L_2 composes L_1, so it is not coded while L_1's session runs: L_1's session writing L_2's
        rule file is a scope violation."""
        w = World({"L-1": "shall stop.", "L-2": "shall yield."})
        w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")], "L-2": [node("L_2", "shall yield.", "L-2", compositions=["L_1"])]}

        def before(ident, it):
            if (ident, it) == ("L_1", 1):
                p = paths.LIBRARY / nodeid.rule_path("L_2")
                p.parent.mkdir(parents=True, exist_ok=True)
                p.write_text("-- written by another session\n")
        verdicts = self.run_world(w, before)
        self.assertEqual(verdicts[("L_1", 1)], ("SCOPE_VIOLATION", [gate.lib_rel(nodeid.rule_path("L_2"))]))
        self.assertNotIn(gate.lib_rel(nodeid.rule_path("L_2")), self.concurrent)


class UnlockOnlyAfterApply(unittest.TestCase):
    """What a task's outcome decides is applied by the loop's own thread before any item it could
    unlock is considered."""

    def test_a_concept_fenced_during_the_stage_unlocks_no_new_caller(self):
        """L_1's coder shows the concept the three nodes use defective (upheld): it is fenced while L_2
        runs; L_3, not started, is never coded on it and goes back to its planner uncharged."""
        w = World({"L-1": "shall stop.", "L-2": "shall yield.", "L-3": "shall slow."})
        w.plans = {"L-1": [concept("drv.motion.slow", users=["L_1", "L_2", "L_3"]), node("L_1", "shall stop.", "L-1", derived=["drv.motion.slow"])],
                   "L-2": [node("L_2", "shall yield.", "L-2", derived=["drv.motion.slow"])],
                   "L-3": [node("L_3", "shall slow.", "L-3", derived=["drv.motion.slow"])]}

        def report(run, task, reached):
            if Path(task).name == "L_1":
                return review_phase.DependencyReport("upheld", concept="drv.motion.slow", line="scripted counterexample")
            return review_phase.DependencyReport("none")

        def before(ident, it):
            if (ident, it) == ("L_2", 1):
                wait_for(decided("nodes", "L_1", "DEPENDENCY"))
        with Fixture(w, workers=2, max_iterations=1) as f:
            with mock.patch.object(loop, "report_of", report), mock.patch.object(session, "run", Sessions(before)):
                f.drive()
            prog, st = committed(), f.state()
        self.assertEqual(prog["nodes"]["L_1"], "DEPENDENCY")
        self.assertEqual(prog["nodes"]["L_3"], "FENCED_PROVIDER")
        self.assertEqual(w.calls[("code", "L_3", 1)], 0)
        self.assertEqual(w.calls[("code", "L_2", 1)], 1)     # running when the fence came: it drains
        self.assertIn("drv.motion.slow", st["fenced"])
        self.assertEqual({e["law"]: e["attempts"] for e in st["ledger"]}["L-3"], 0)

    def test_a_sibling_failure_stops_the_unstarted_siblings_and_drains_the_running(self):
        """L-5's first node is returned by its gate (a scope violation: the law goes back to its
        planner, charged once); the second, already running, ends with its gate; the third, not
        started, is never coded."""
        w = World({"L-5": "shall stop. shall yield. shall slow."})
        w.plans = {"L-5": [node(f"L_5_o{i}", "shall stop. shall yield. shall slow.", "L-5") for i in (1, 2, 3)]}
        w.gate[("L_5_o1", 1)] = "SCOPE_VIOLATION"

        def before(ident, it):
            if (ident, it) == ("L_5_o2", 1):
                wait_for(decided("nodes", "L_5_o1", "SCOPE_VIOLATION"))
        with Fixture(w, workers=2, max_iterations=1) as f:
            with mock.patch.object(session, "run", Sessions(before)):
                f.drive()
            prog, st = committed(), f.state()
        self.assertEqual((prog["nodes"]["L_5_o1"], prog["nodes"]["L_5_o2"], prog["nodes"]["L_5_o3"]), ("SCOPE_VIOLATION", "OK", "LAW_CLOSED"))
        self.assertEqual(w.calls[("code", "L_5_o3", 1)], 0)
        self.assertEqual(w.calls[("code", "L_5_o2", 1)], 1)
        led = {e["law"]: e for e in st["ledger"]}["L-5"]
        self.assertEqual((led["state"], led["attempts"]), ("returned", 1))

    def test_a_budget_pause_stops_new_tasks_drains_the_running_and_resumes_the_rest(self):
        """L_1's dependency-defect report is paused on the budget while L_2 runs and L_3 waits: L_2
        ends with its gate, L_3 is not started, and the resume takes L_1 up again from its saved
        verdict (no new coding session) and codes L_3."""
        w = laws3()
        state = {}

        def report(run, task, reached):
            if Path(task).name == "L_1" and not state.get("paused"):
                state["paused"] = True
                raise BudgetPaused("scripted: the budget is spent")
            return scripted(run, task, reached)

        def before(ident, it):
            if (ident, it) == ("L_2", 1):
                wait_for(lambda: state.get("paused"))
        with Fixture(w, workers=2) as f:
            scripted = loop.report_of
            with mock.patch.object(loop, "report_of", report), mock.patch.object(session, "run", Sessions(before)):
                self.assertEqual(f.drive(launches=1), ["paused_budget"])
                first = committed()
                self.assertEqual(w.calls[("code", "L_3", 1)], 0)
                self.assertEqual(f.drive(), ["complete"])
            st = f.state()
        self.assertEqual(first["nodes"], {"L_2": "OK"})                    # L_1 undecided, L_3 not started
        self.assertEqual((w.calls[("code", "L_1", 1)], w.calls[("code", "L_2", 1)], w.calls[("code", "L_3", 1)]), (1, 1, 1))
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_1", "L_2", "L_3"])

    def test_an_outage_stops_new_tasks_and_drains_the_running(self):
        """L_1's coding session does not run (the session is unavailable) while L_2 runs and L_3 waits:
        L_2 ends with its gate, L_1 and L_3 are held uncharged and coded in the next iteration."""
        w = laws3()
        w.gate[("L_1", 1)] = "outage"

        def before(ident, it):
            if (ident, it) == ("L_2", 1):
                wait_for(decided("nodes", "L_1", "PAUSED"))
        with Fixture(w, workers=2) as f:
            with mock.patch.object(session, "run", Sessions(before)):
                self.assertEqual(f.drive(launches=1), ["infrastructure_failure"])
                first = committed()
                self.assertEqual(f.drive(), ["complete"])
            st = f.state()
        self.assertEqual(first["nodes"], {"L_1": "PAUSED", "L_2": "OK", "L_3": "PAUSED"})
        self.assertEqual(w.calls[("code", "L_3", 1)], 0)
        self.assertEqual(w.calls[("code", "L_2", 1)], 1)
        self.assertEqual({e["law"]: e["attempts"] for e in st["ledger"]}, {"L-1": 0, "L-2": 0, "L-3": 0})
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_1", "L_2", "L_3"])


class ReadingStability(unittest.TestCase):

    def test_a_saved_concept_review_is_reused_after_another_concept_ran_beside_it(self):
        """`drv.motion.slow`'s review is saved, keyed on what it read, and the process stops before
        its outcome is committed, while `drv.motion.halt` is reviewed beside it; L-3's node, which
        proposes a parameter, is planned in the same iteration. The resume finds the same reading and
        reuses the review: no second review call, and every record is accepted."""
        w = World({"L-1": "shall stop.", "L-2": "shall yield.", "L-3": "shall slow."})
        w.plans = {"L-1": [concept("drv.motion.slow", users=["L_1"]), node("L_1", "shall stop.", "L-1", derived=["drv.motion.slow"])],
                   "L-2": [concept("drv.motion.halt", users=["L_2"]), node("L_2", "shall yield.", "L-2", derived=["drv.motion.halt"])],
                   "L-3": [node("L_3", "shall slow.", "L-3")]}
        w.plans["L-3"][0]["params"] = ["p.pause"]
        w.plans["L-3"][0]["param_proposals"] = [{"name": "p.pause", "value": 2.0, "unit": "s", "convention": "c", "source": "s"}]
        seen, state = {}, {}

        def review(run, c, extras, out_dir):
            from harness.model.reading import Reading
            key = hashlib.sha256(json.dumps([c.id, Reading(run.reading_file).data], sort_keys=True).encode()).hexdigest()
            saved = Path(out_dir) / "stub_outcome.json"
            if saved.exists() and json.loads(saved.read_text()) == key:
                return review_phase.ReviewOutcome("accepted")           # the saved review, as its inputs match
            out = scripted(run, c, extras, out_dir)
            Path(out_dir).mkdir(parents=True, exist_ok=True)
            saved.write_text(json.dumps(key))
            if c.id == "drv.motion.slow" and not state.get("stopped"):
                state["stopped"] = True
                w.dead = True
                raise Crash("stop after the concept's review was saved")
            return out

        def before(ident, it):
            if ident == "drv.motion.halt":
                seen["beside started"] = True
            if (ident, it) == ("drv.motion.slow", 1):
                seen["waited"] = wait_for(lambda: seen.get("beside started"))
        with Fixture(w, workers=2) as f:
            scripted = review_phase.review_concept
            with mock.patch.object(review_phase, "review_concept", review), mock.patch.object(session, "run", Sessions(before)):
                self.assertEqual(f.drive(), ["crash", "complete"])
            st = f.state()
        self.assertTrue(seen["waited"])
        self.assertEqual(w.calls[("review", "drv.motion.slow", 1)], 1)
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_1", "L_2", "L_3"])
        self.assertEqual(sorted(st["accepted_concepts"]), ["drv.motion.halt", "drv.motion.slow"])


class UnjudgedVerdicts(unittest.TestCase):
    """A saved gate verdict that judged nothing (`INFRA`: the toolchain or the run's own stop) is not
    reused on resume; the candidate it left is gated again without a new session."""

    def test_which_saved_verdicts_are_reused(self):
        with tempfile.TemporaryDirectory() as t:
            lib, d = Path(t) / "library", Path(t) / "task"
            lib.mkdir(); d.mkdir()
            rels = ("a.lean", "b.lean")
            with mock.patch.object(paths, "LIBRARY", lib):
                for r in rels:
                    (lib / r).write_text("candidate\n")
                code_phase._save_verdict(d, gate.Verdict(gate.INFRA, ["the build was stopped (run_stop) before evaluation"]), rels, "ctx")
                self.assertIsNone(code_phase._finished_verdict(d, rels, "ctx"))
                code_phase._save_verdict(d, gate.Verdict("OK", []), rels, "ctx")
                self.assertEqual(code_phase._finished_verdict(d, rels, "ctx").verdict, "OK")
                code_phase._save_verdict(d, gate.Verdict("CHECK_FAIL", ["x"]), rels, "ctx")
                self.assertEqual(code_phase._finished_verdict(d, rels, "ctx").verdict, "CHECK_FAIL")

    def test_a_gate_stopped_by_the_run_is_gated_again_on_resume_without_a_session(self):
        """The harness's gate of L_1 is cut off by the run's stop (`INFRA`, saved) and the process
        dies after the rollback: the resume gates the kept candidate again and accepts it in the same
        iteration, with one coding session."""
        w = World({"L-1": "shall stop."})
        w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")]}
        gates = []
        with Fixture(w, workers=1) as f:
            scripted = gate.run_gate

            def run_gate(n, reading, baseline, d, *a, **k):
                gates.append(_iteration_of(Path(d)))
                if len(gates) == 1:
                    w.crash_at = w.ticks + 1                    # the process dies at the rollback that follows
                    return gate.Verdict(gate.INFRA, ["the build was stopped (run_stop) before evaluation"])
                return scripted(n, reading, baseline, d, *a, **k)
            with mock.patch.object(gate, "run_gate", run_gate):
                self.assertEqual(f.drive(), ["crash", "complete"])
            st = f.state()
        self.assertEqual(gates, [1, 1])
        self.assertEqual(w.calls[("code", "L_1", 1)], 1)
        self.assertEqual(sorted(st["accepted_nodes"]), ["L_1"])
        self.assertEqual(st["iterations_allocated"], ["iter-001"])


class StopBetweenRollbackAndCommit(unittest.TestCase):
    """The window between an outcome's rollback and its commit: a stop there leaves a saved `OK`
    verdict whose files have left the library, so the resume codes the node again (its verdict no
    longer describes the library). One task at a time or several, the decisions are those of an
    uninterrupted run."""

    @staticmethod
    def world():
        """L-1's node passes its gate in iteration 1, but its coder's dependency-defect report cannot be
        judged there (`deferred`): its candidate is rolled back and the node held."""
        w = World({"L-1": "shall stop.", "L-2": "shall yield."})
        w.plans = {"L-1": [node("L_1", "shall stop.", "L-1")], "L-2": [node("L_2", "shall yield.", "L-2")]}

        def report(run, task, reached):
            if (Path(task).name, run.iteration) == ("L_1", 1):
                return review_phase.DependencyReport("deferred", reasons=["scripted: the adjudication stayed invalid"])
            return review_phase.DependencyReport("none")
        return w, report

    def test_the_resume_codes_the_rolled_back_node_once_more_and_decides_the_same(self):
        ref_w, ref_report = self.world()
        with Fixture(ref_w) as f:
            with mock.patch.object(loop, "report_of", ref_report):
                self.assertEqual(f.drive()[-1], "complete")
            ref = f.state()
        for workers in (1, 4):
            with self.subTest(workers=workers):
                w, report = self.world()
                real = code_phase.rollback

                def rollback(node_id, *a, **k):                # the process stops right after L_1's first rollback
                    out = real(node_id, *a, **k)
                    if node_id == "L_1" and not w.calls[("stopped", "-", 0)]:
                        w.calls[("stopped", "-", 0)] += 1
                        w.dead = True
                        raise Crash("stop between the rollback and its commit")
                    return out
                with Fixture(w, workers=workers) as f:
                    with mock.patch.object(loop, "report_of", report), mock.patch.object(code_phase, "rollback", rollback):
                        statuses = f.drive()
                    st = f.state()
                self.assertEqual(statuses[0], "crash")
                self.assertEqual(w.calls[("code", "L_1", 1)], 2)
                self.assertEqual(decisions(st), decisions(ref))


if __name__ == "__main__":
    unittest.main()
