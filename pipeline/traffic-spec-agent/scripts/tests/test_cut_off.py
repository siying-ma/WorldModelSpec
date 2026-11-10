"""A coding session cut off before it finished leaves its candidate to its relaunch: the files are
not restored to the skeletons, the relaunch's prompt says so with the verdict of the last gate run,
and the relaunch may run the gate at least half the budget again. A session that did not run is
still relaunched from the baseline."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_recovery as R                                  # noqa: E402

from harness.agents import runner, session                  # noqa: E402
from harness.model import nodeid                            # noqa: E402
from harness.phases import code as code_phase               # noqa: E402
from harness.store import owner, paths                      # noqa: E402
from harness.store.state import RUN_VERSION, Options        # noqa: E402

ONTO = Path(__file__).resolve().parents[2] / "ontology" / "ATOMS_train.md"
OK = (0, {"type": "result", "subtype": "success", "num_turns": 9, "usage": {"output_tokens": 50}, "result": "done"}, False)
CUT = (0, {"type": "result", "subtype": "error_max_turns", "is_error": True, "num_turns": 80, "usage": {"output_tokens": 50},
           "result": ""}, False)
REFUSED = (0, {"type": "result", "subtype": "success", "is_error": True, "num_turns": 7, "api_error_status": 529,
               "usage": {"output_tokens": 50}, "result": "Overloaded"}, False)


class Relaunch(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.d = Path(self.tmp.name)
        self.saved = (paths.RESULTS, runner.run_claude)
        paths.RESULTS = self.d
        (self.d / "t").mkdir()
        self.opts = Options(run_id="t", laws=self.d / "laws.jsonl", ontology=ONTO, reading=self.d / "reading.json", model="opus",
                            session_retries=1, retry_wait=0)
        owner.STOP.clear()

    def tearDown(self):
        paths.RESULTS, runner.run_claude = self.saved
        self.tmp.cleanup()

    def launch(self, *answers):
        seq, prompts, calls = list(answers), [], []

        def fake(prompt, cwd, stream_path, **kw):
            prompts.append(prompt)
            stream_path.write_text("")
            return seq.pop(0)
        runner.run_claude = fake
        sub = self.d / "code"; sub.mkdir(exist_ok=True)
        session.run("p", sub, sub, self.opts, max_turns=10, effort=None, relaunch=lambda: calls.append("restore"),
                    relaunch_cut_off=lambda: (calls.append("keep"), " — the note")[1])
        return prompts, calls

    def test_a_cut_off_relaunch_carries_the_note_and_restores_nothing(self):
        self.assertEqual(self.launch(CUT, OK), (["p", "p — the note"], ["keep"]))

    def test_a_session_that_did_not_run_is_relaunched_from_the_baseline_as_written(self):
        self.assertEqual(self.launch(REFUSED, OK), (["p", "p"], ["restore"]))


class Note(unittest.TestCase):
    RELS = ("TrafficSpec/Rules/NRS_484B/NRS_484B_1_1.lean", "TrafficSpecWitness/NRS_484B/NRS_484B_1_1.lean")

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.lib = Path(self.tmp.name) / "library"
        self.saved = paths.LIBRARY
        paths.LIBRARY = self.lib
        for r in self.RELS:
            (self.lib / r).parent.mkdir(parents=True, exist_ok=True)
            (self.lib / r).write_text("the candidate")
        self.work = Path(self.tmp.name) / "task"; self.work.mkdir()

    def tearDown(self):
        paths.LIBRARY = self.saved
        self.tmp.cleanup()

    def note(self, used, last=None):
        (self.work / "gate_runs.txt").write_text(str(used))
        if last is not None:
            (self.work / "last_gate.json").write_text(json.dumps(last))
        return code_phase._cut_off_relaunch(self.work, self.RELS, 10)

    def test_the_relaunch_gets_half_the_budget_when_less_is_left(self):
        text = self.note(9, {"verdict": "CHECK_FAIL", "details": ["scenario branch_13 errs"]})
        self.assertEqual((self.work / "gate_runs.txt").read_text(), "5")
        self.assertIn("5 more time(s)", text)
        self.assertIn("used 9", text)
        self.assertIn("CHECK_FAIL", text)
        self.assertIn("scenario branch_13 errs", text)
        for r in self.RELS:
            self.assertEqual((self.lib / r).read_text(), "the candidate")
            self.assertIn(str((self.lib / r).resolve()), text)
        self.assertEqual((self.work / "relaunch_note.md").read_text(), text)

    def test_the_runs_left_stand_when_they_are_more(self):
        text = self.note(3)
        self.assertEqual((self.work / "gate_runs.txt").read_text(), "3")
        self.assertIn("7 more time(s)", text)
        self.assertIn("it ran no gate", text)


class Wiring(unittest.TestCase):
    """The coding phase hands the session a cut-off relaunch that keeps the files, and the CLI gate
    keeps its verdict for that relaunch."""

    def test_the_coding_phase_keeps_the_candidate_on_a_cut_off(self):
        w = R.World({"L-1": "shall creep."})
        w.plans["L-1"] = [R.node("L_1", "shall creep.", "L-1")]
        seen = []

        def session_run(prompt, cwd=None, out_dir=None, opts=None, relaunch_cut_off=None, **kw):
            rels = (nodeid.rule_path("L_1"), nodeid.witness_path("L_1"))
            for r in rels:
                (paths.LIBRARY / r).write_text("a candidate the cut-off launch left")
            note = relaunch_cut_off()
            seen.append(([(paths.LIBRARY / r).read_text() for r in rels], "relaunch after a cut-off" in note))
            return {}
        with R.Fixture(w, max_iterations=1) as f:
            with mock.patch.object(session, "run", session_run):
                f.drive(launches=1)
        self.assertEqual(seen, [(["a candidate the cut-off launch left"] * 2, True)])

    def test_the_sessions_gate_keeps_its_verdict(self):
        from harness.checks import gate
        with tempfile.TemporaryDirectory() as t:
            root = Path(t)
            task = root / "r" / "iter-001" / "code" / "L_1"; task.mkdir(parents=True)
            (task / "baseline.json").write_text("{}"); (task / "gate_runs.txt").write_text("2")
            (task / "node.json").write_text(json.dumps(R.node("L_1", "shall creep.", "L-1")))
            (root / "r" / "options.json").write_text(json.dumps({"reading": str(root / "reading.json"), "gate_budget": 10, "semantic": {"run_version": RUN_VERSION}}))
            (root / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
            with mock.patch.object(paths, "RESULTS", root), \
                    mock.patch.object(gate, "run_gate", lambda *a, **k: gate.Verdict("CHECK_FAIL", ["scenario x errs"])), \
                    mock.patch.object(code_phase, "cli_catalogue", lambda run_id: {}):
                code_phase.gate_from_cli("r", "L_1")
            self.assertEqual(json.loads((task / "last_gate.json").read_text()), {"verdict": "CHECK_FAIL", "details": ["scenario x errs"]})
            self.assertEqual((task / "gate_runs.txt").read_text(), "3")


if __name__ == "__main__":
    unittest.main()
