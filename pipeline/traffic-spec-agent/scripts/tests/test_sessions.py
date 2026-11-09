"""Development regression tests for session launches and process ownership: the stop event, each
task's retry budget kept on disk, cut-off sessions, rejected requests, structured refusals, process
groups, a coding task's baseline on a relaunch, and the gate's attribution of a toolchain failure."""
import dataclasses
import json
import os
import subprocess
import sys
import tempfile
import time
import unittest
from unittest import mock
from pathlib import Path
from types import SimpleNamespace

from harness.agents import openai_runner, runner, session
from harness.store import budget, owner, paths
from harness.store.state import Options

ONTO = Path(__file__).resolve().parents[2] / "ontology" / "ATOMS_train.md"


class Launches(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, runner.run_claude, openai_runner.run_openai, dict(budget._BUDGETS))
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        prices = self.d / "prices.json"
        prices.write_text(json.dumps({"gpt-x": {"input_usd_per_million": 1, "cached_input_usd_per_million": 0.1, "output_usd_per_million": 2}}))
        self.opts = Options(run_id="t", laws=self.d / "laws.jsonl", ontology=ONTO, reading=self.d / "reading.json", model="opus",
                            session_retries=1, retry_wait=0, model_prices=prices, reviewer_max_output_tokens=100)
        budget._BUDGETS.clear()
        self.launches = 0
        owner.STOP.clear()

    def tearDown(self):
        paths.RESULTS, runner.run_claude, openai_runner.run_openai, b = self.saved
        budget._BUDGETS.clear(); budget._BUDGETS.update(b)
        owner.STOP.clear()
        self.tmp.cleanup()

    def claude(self, *results):
        """`run_claude` answering each launch with the next (code, result, timed_out)."""
        seq = list(results)

        def fake(prompt, cwd, stream_path, **kw):
            self.launches += 1
            stream_path.write_text("")
            return seq.pop(0)
        runner.run_claude = fake

    OK = (0, {"type": "result", "subtype": "success", "num_turns": 9, "usage": {"output_tokens": 50}, "result": "done"}, False)
    REFUSED = (0, {"type": "result", "subtype": "success", "is_error": True, "num_turns": 7, "api_error_status": 529,
                   "usage": {"output_tokens": 50}, "result": "Overloaded"}, False)
    CUT = (0, {"type": "result", "subtype": "error_max_turns", "is_error": True, "num_turns": 80, "usage": {"output_tokens": 50},
               "result": ""}, False)

    def go(self, **kw):
        return session.run("p", self.d, self.d, self.opts, max_turns=10, effort=None, **kw)

    def test_no_launch_once_the_run_is_stopping(self):
        self.claude(self.OK)
        owner.STOP.set()
        with self.assertRaises(session.SessionUnavailable):
            self.go()
        self.assertEqual(self.launches, 0)

    def test_a_refusal_at_any_turn_is_a_session_that_did_not_run(self):
        self.claude(self.REFUSED, self.OK)
        rec = self.go()
        self.assertEqual((self.launches, rec["attempt"]), (2, 2))

    def test_the_allowance_holds_within_a_loop_launch_and_renews_with_the_next(self):
        self.claude(self.REFUSED, self.REFUSED)
        with self.assertRaises(session.SessionUnavailable):
            self.go()                                      # two launches: the first and its one relaunch
        self.claude(self.REFUSED)
        with self.assertRaises(session.SessionUnavailable):
            self.go()                                      # the same loop launch: no launch at all
        self.assertEqual(self.launches, 2)
        saved = owner._RECORD
        owner._RECORD = {"nonce": "next-loop-launch"}       # the operator's relaunch: a new generation
        try:
            self.claude(self.REFUSED, self.REFUSED, self.OK)
            with self.assertRaises(session.SessionUnavailable):
                self.go()                                  # a new allowance of two launches
        finally:
            owner._RECORD = saved
        self.assertEqual(self.launches, 4)
        self.assertEqual(sorted(f.name for f in self.d.glob("session_result*.json")),
                         ["session_result.json", "session_result.retry1.json", "session_result.retry2.json",
                          "session_result.retry3.json"])

    def test_a_cut_off_is_returned_without_relaunch_and_relaunched_with_one(self):
        self.claude(self.CUT)
        self.assertEqual(self.go()["cut_off"], "the session stopped at its turn cap")
        self.assertEqual(session.cut_off_of(self.d), "the session stopped at its turn cap")
        restored = []
        self.claude(self.CUT, self.OK)
        sub = self.d / "code"; sub.mkdir()
        rec = session.run("p", sub, sub, self.opts, max_turns=10, effort=None, relaunch=lambda: None,
                          relaunch_cut_off=lambda: (restored.append(1), "")[1])
        self.assertEqual((rec["cut_off"], restored), (None, [1]))

    def test_a_coding_session_cut_off_at_every_launch_is_returned_not_an_outage(self):
        """A session that ran and was cut off each time (its own work too slow for its time) is
        returned with `cut_off` once its relaunches are spent: the caller's gate judges what it
        left. Only a session that did not run is an outage."""
        restored = []
        self.claude(self.CUT, self.CUT, self.CUT)
        sub = self.d / "code"; sub.mkdir()
        rec = session.run("p", sub, sub, self.opts, max_turns=10, effort=None, relaunch=lambda: None,
                          relaunch_cut_off=lambda: (restored.append(1), "")[1])
        self.assertEqual(rec["cut_off"], "the session stopped at its turn cap")
        self.assertEqual((self.launches, len(restored)), (self.opts.session_retries + 1, self.opts.session_retries))

    def test_a_cut_off_relaunches_without_waiting_and_a_refusal_waits(self):
        """`retry_wait` is for a limit or an outage to clear; a session that ran and was cut off has
        nothing to wait for."""
        self.opts = dataclasses.replace(self.opts, retry_wait=7)
        slept = []
        sub = self.d / "code"; sub.mkdir()
        with mock.patch.object(session.time, "sleep", side_effect=lambda s: slept.append(s)):
            self.claude(self.CUT, self.OK)
            session.run("p", sub, sub, self.opts, max_turns=10, effort=None, relaunch=lambda: None, relaunch_cut_off=lambda: "")
            self.claude(self.REFUSED, self.OK)
            session.run("p", self.d, self.d, self.opts, max_turns=10, effort=None)
        self.assertEqual(slept, [0.0, 7])

    def test_a_rejected_request_is_reported_and_never_retried(self):
        calls = []

        def fake(prompt, *, model, stream_path, **kw):
            calls.append(1)
            stream_path.write_text(json.dumps({"type": "error", "error": "BadRequestError: unsupported parameter"}) + "\n")
            return openai_runner.BAD_REQUEST, None, False
        openai_runner.run_openai = fake
        with self.assertRaises(session.BadRequest) as e:
            self.go(model="gpt-x", tools=[])
        self.assertEqual(len(calls), 1)
        self.assertIn("unsupported parameter", str(e.exception))

    def test_a_timeout_with_no_answer_did_not_run(self):
        answers = [(1, None, True), (0, {"type": "result", "result": "{}", "num_turns": 1, "usage": {"output_tokens": 3}}, False)]

        def fake(prompt, *, model, stream_path, **kw):
            stream_path.write_text("")
            return answers.pop(0)
        openai_runner.run_openai = fake
        rec = self.go(model="gpt-x", tools=[])
        self.assertEqual(rec["attempt"], 2)


class Classification(unittest.TestCase):
    def test_a_rejected_rate_limit_event_is_a_refusal(self):
        with tempfile.TemporaryDirectory() as t:
            s = Path(t) / "s.jsonl"
            s.write_text(json.dumps({"type": "rate_limit_event", "rate_limit_info": {"status": "rejected", "rateLimitType": "seven_day"}}) + "\n")
            res = {"type": "result", "subtype": "success", "num_turns": 30, "usage": {"output_tokens": 900}, "result": "partial"}
            self.assertIn("seven_day rejected", runner.session_failure(0, res, False, s))

    def test_cut_offs(self):
        self.assertEqual(runner.cut_off(None, True), "the session timed out")
        self.assertIsNone(runner.cut_off({"subtype": "success", "terminal_reason": "completed"}, False))
        self.assertIsNone(runner.session_failure(0, {"subtype": "error_max_turns", "is_error": True, "num_turns": 1,
                                                     "usage": {"output_tokens": 5}}, False))


class ProcessGroups(unittest.TestCase):
    def test_a_lean_timeout_ends_the_whole_group(self):
        from harness.lean import lean
        with tempfile.TemporaryDirectory() as t:
            pidfile = Path(t) / "child"
            code, out = lean.run(["sh", "-c", f"sleep 60 & echo $! > {pidfile}; wait"], Path(t), timeout=1)
            self.assertEqual(code, 124)
            child = int(pidfile.read_text())
            time.sleep(0.2)
            self.assertFalse(Path(f"/proc/{child}").exists() and "Z" not in Path(f"/proc/{child}/stat").read_text().split()[2])

    def test_a_marked_process_is_ended(self):
        env = {**os.environ, "TRAFFIC_SPEC_TEST_MARK": "m1"}
        p = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"], env=env, start_new_session=True)
        try:
            time.sleep(0.2)
            self.assertIn(p.pid, owner._carrying("TRAFFIC_SPEC_TEST_MARK", "m1"))
            owner.kill_marked("TRAFFIC_SPEC_TEST_MARK", "m1")
            self.assertEqual(p.wait(timeout=5), -9)
        finally:
            if p.poll() is None:
                p.kill()


class TaskBaseline(unittest.TestCase):
    """A coding task started again (a resume, a relaunch) puts its files back as they were before its
    first launch, keeps no `final/` from the unfinished session, and continues its gate budget."""
    def test_restart_restores_and_keeps_the_count(self):
        from harness.phases import code
        with tempfile.TemporaryDirectory() as t:
            saved = (paths.LIBRARY, code.gate.repo_digest, code.index_sync.write_index)
            lib = Path(t) / "library"; (lib / "TrafficSpec" / "Rules").mkdir(parents=True)
            paths.LIBRARY = lib
            code.gate.repo_digest = lambda: {code.gate.lib_rel(p.relative_to(lib).as_posix()): "x" for p in lib.rglob("*.lean")}
            code.index_sync.write_index = lambda **kw: None
            try:
                rels = ("TrafficSpec/Rules/A.lean",)
                (lib / rels[0]).write_text("before")
                work = Path(t) / "task"; work.mkdir()
                code._start(work, rels)
                (lib / rels[0]).write_text("half written")
                (work / "gate_runs.txt").write_text("3")
                code._start(work, rels)
                self.assertEqual((lib / rels[0]).read_text(), "before")
                self.assertEqual((work / "gate_runs.txt").read_text(), "3")
                self.assertFalse((work / "final").exists())
            finally:
                paths.LIBRARY, code.gate.repo_digest, code.index_sync.write_index = saved



class SessionEnvironment(unittest.TestCase):
    """A Claude session gets only its declared tools and no auto memory."""
    def test_the_command_line_and_environment(self):
        seen = {}

        class FakeProc:
            pid, returncode = 4242, 0
            stdin = SimpleNamespace(write=lambda t: None, close=lambda: None)

            def __init__(self, cmd, **kw):
                seen["cmd"], seen["env"] = cmd, kw["env"]
                self.start_new_session = kw.get("start_new_session")

            def wait(self, timeout=None):
                return 0
        saved = runner.subprocess.Popen
        runner.subprocess.Popen = FakeProc
        try:
            with tempfile.TemporaryDirectory() as t:
                runner.run_claude("p", Path(t), Path(t) / "s.jsonl", tools=["Read", "Edit"])
                runner.run_claude("p", Path(t), Path(t) / "s2.jsonl", tools=[])
                tool_less = seen["cmd"]
        finally:
            runner.subprocess.Popen = saved
        self.assertEqual(seen["env"].get("CLAUDE_CODE_DISABLE_AUTO_MEMORY"), "1")
        self.assertNotIn("OPENAI_API_KEY", seen["env"])
        i = tool_less.index("--tools")
        self.assertEqual(tool_less[i + 1], "")
        self.assertNotIn("--disallowedTools", tool_less)

class GateAttribution(unittest.TestCase):
    """A toolchain failure is the candidate's only on evidence that names it."""
    OWN = {"TrafficSpec/Rules/X/R.lean", "TrafficSpecWitness/X/R.lean"}
    NS = ("TrafficSpec.Rules.R.", "TrafficSpecWitness.R.")

    def setUp(self):
        from harness.checks import gate
        from harness.lean import lean
        self.gate, self.lean = gate, lean
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name) / "library"; (self.lib / "TrafficSpec").mkdir(parents=True)
        (self.lib / "TrafficSpec" / "Index.lean").write_text("def allRules : List Rule := [\n  TrafficSpec.Rules.R.rule\n]\n")
        self.work = Path(self.tmp.name) / "task"; self.work.mkdir()
        self.saved = (paths.LIBRARY, lean.lake_build, lean.lean_run)
        paths.LIBRARY = self.lib

    def tearDown(self):
        paths.LIBRARY, self.lean.lake_build, self.lean.lean_run = self.saved
        owner.STOP.clear()
        self.tmp.cleanup()

    def run_with(self, builds, runs):
        builds, runs = list(builds), list(runs)
        self.lean.lake_build = lambda lib, targets: builds.pop(0)
        self.lean.lean_run = lambda lib, f, **k: runs.pop(0)
        return self.gate._toolchain(self.work, ["T"], self.OWN, self.NS, self.work / "gate_harness.lean")

    DONE = (0, "DECL\t{}\nDONE")

    def verdict(self, r):
        return r.verdict if isinstance(r, self.gate.Verdict) else "ran"

    def test_errors_are_attributed_by_place(self):
        own = (1, "error: TrafficSpec/Rules/X/R.lean:3:2: unknown identifier\nerror: build failed")
        core = (1, "error: TrafficSpec/Core/Language/Rule.lean:9:1: unexpected token\nerror: build failed")
        registry = (1, "error: TrafficSpec/Index.lean:2:2: type mismatch\nerror: build failed")
        self.assertEqual(self.verdict(self.run_with([own], [])), "BUILD_FAIL")
        self.assertEqual(self.verdict(self.run_with([core], [])), self.gate.INFRA)
        self.assertEqual(self.verdict(self.run_with([registry], [])), "BUILD_FAIL")
        self.assertEqual(self.verdict(self.run_with([(1, "error: build failed")], [])), self.gate.INFRA)

    def test_a_deadline_is_the_candidates_only_during_evaluation(self):
        late = (124, "TIMEOUT: lake env lean exceeded 900s\nDECL\t{}")
        early = (124, "TIMEOUT: lake env lean exceeded 900s")
        self.assertEqual(self.verdict(self.run_with([(0, "")], [late])), "ran")       # `harness_failure` makes it GATE_TIMEOUT
        self.assertEqual(self.gate.harness_failure(late[1]).verdict, self.gate.GATE_TIMEOUT)
        self.assertEqual(self.verdict(self.run_with([(0, "")], [early])), self.gate.INFRA)
        self.assertEqual(self.verdict(self.run_with([(124, "TIMEOUT: lake build exceeded 1800s")], [])), self.gate.INFRA)

    def test_a_stop_is_never_the_candidates(self):
        self.assertEqual(self.verdict(self.run_with([(0, "")], [(-15, "DECL\t{}")])), self.gate.INFRA)
        owner.STOP.set()
        self.assertEqual(self.verdict(self.run_with([(0, "")], [(-9, "DECL\t{}")])), self.gate.INFRA)

    def test_a_resource_failure_is_reproduced_once(self):
        killed = (-9, "DECL\t{}")
        self.assertEqual(self.verdict(self.run_with([(0, ""), (0, "")], [killed, self.DONE])), "ran")
        self.assertEqual(self.verdict(self.run_with([(0, ""), (0, "")], [killed, killed])), self.gate.GATE_TIMEOUT)

    def test_a_panic_fails_the_gate_and_is_reported(self):
        panic = (0, "DECL\t{}\nError: index out of bounds\nbacktrace:\nDONE")
        v = self.run_with([(0, ""), (0, "")], [panic, panic])
        self.assertEqual(v.verdict, self.gate.GATE_TIMEOUT)
        self.assertTrue(v.extras["panic"])
        rows = [json.loads(l) for l in (self.work / "toolchain.jsonl").read_text().splitlines()]
        self.assertEqual([r["phase"] for r in rows if r["phase"] in ("build", "harness")], ["build", "harness", "build", "harness"])



class GateChecks(unittest.TestCase):
    """A claim covers its own atom only; a contradicted relation or an empty window fails a witness;
    a cosine slot holds a cosine; a reading is read whole or not at all."""
    def test_a_claim_never_covers_an_atom_that_shares_its_prefix(self):
        from harness.checks import gate
        self.assertEqual(gate.owner_name("st_lane_direction"), "st_lane_direction")
        self.assertEqual(gate.owner_name("dev_traffic_signal_shows"), "dev_traffic_signal")
        self.assertEqual(gate.owner_name("drv_motion_halted"), "drv_motion_halted")

    def test_witness_trace_defects(self):
        from harness.checks import gate
        rows = {"RELCHECK": [["forbid", "0", "1-2", "rel_same_direction: differs"]], "NOWINDOW": [["idle"]]}
        out = gate.witness_trace_defects(lambda tag: rows.get(tag, []))
        self.assertEqual(len(out), 2)
        self.assertIn("judges nothing", out[1])

    def test_a_cosine_slot_takes_a_cosine(self):
        from harness.checks import gate
        reading = SimpleNamespace(params={"p.align": {"name": "p.align", "value": 15, "unit": "deg"},
                                          "p.cos": {"name": "p.cos", "value": 0.97, "unit": "ratio"}})
        bad = {"atom": "rel_same_direction", "params": [{"param": "p.align"}]}
        good = {"atom": "rel_same_direction", "params": [{"param": "p.cos"}]}
        self.assertTrue(gate.slot_range_defects(bad, reading))
        self.assertEqual(gate.slot_range_defects(good, reading), [])
        concept = {"drv.interaction.x": {"params": [{"name": "tol", "unit": "ratio"}],
                                         "body_json": {"atom": "rel_oncoming", "params": [{"param": "tol"}]}}}
        call = {"derived": "drv_interaction_x", "params": [{"param": "p.align"}]}
        self.assertTrue(gate.slot_range_defects(call, reading, concept))
        deep = bad
        for _ in range(5000):                          # no nesting hides a slot
            deep = {"not": deep}
        self.assertTrue(gate.slot_range_defects(deep, reading))
        deep_call = call
        for _ in range(5000):
            deep_call = {"not": deep_call}
        self.assertTrue(gate.slot_range_defects(deep_call, reading, concept))

    def test_a_reading_is_read_whole(self):
        from harness.model.reading import reading_defects
        self.assertEqual(reading_defects({"params": [{"name": "p.a", "value": 1, "unit": "ft"}], "aggregates": []}), [])
        self.assertEqual(len(reading_defects({"params": [{"name": "p.a", "value": float("inf"), "unit": "furlong"},
                                                         {"name": "p.a", "value": 1, "unit": "m"}]})), 3)

if __name__ == "__main__":
    unittest.main()
