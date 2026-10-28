"""Development regression tests: no gate, wait or stop the loop can do without — a record the run
accepted is not gated again at the next loop start, a timeout on one accepted record stops nothing,
and nothing a toolchain outage should stop is let through."""
import json
import sys
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_recovery as R                                  # noqa: E402

from harness import loop                                   # noqa: E402
from harness.phases import integrate                       # noqa: E402
from harness.store import paths                            # noqa: E402

CID = "drv.motion.creep"


def world():
    w = R.World({"L-1": "shall creep."})
    w.plans["L-1"] = [R.concept(CID, users=["L_1"]), R.node("L_1", "shall creep.", "L-1", derived=[CID])]
    return w


def changed_gate():
    """Another implementation of the gate: every admission key changes, as after a gate fix."""
    return mock.patch.object(integrate, "gate_digest", lambda: "another gate")


class AcceptedOnce(unittest.TestCase):

    def test_what_the_run_accepted_is_not_gated_again_at_the_next_start(self):
        w = world()
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            self.assertIn("L_1", json.loads((paths.RESULTS / "r" / "state.json").read_text())["accepted_nodes"])
            before = dict(w.admitted)
            f.drive(launches=1, max_iterations=2)
        self.assertEqual((w.admitted["L_1"] - before.get("L_1", 0), w.admitted[CID] - before.get(CID, 0)), (0, 0))

    def test_a_changed_context_gates_it_again(self):
        w = world()
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            before = dict(w.admitted)
            with changed_gate():
                f.drive(launches=1, max_iterations=2)
        self.assertGreater(w.admitted["L_1"], before.get("L_1", 0))


class TimeoutStopsNothing(unittest.TestCase):

    def test_a_timeout_on_an_accepted_record_keeps_it_and_the_run_goes_on(self):
        w = world()
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            w.admission["L_1"] = "GATE_TIMEOUT"
            with changed_gate():
                statuses = f.drive(launches=1, max_iterations=2)
            snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            cache = json.loads((paths.RESULTS / "r" / "admission.json").read_text())
            notes = (paths.RESULTS / "r" / "TO_USER.md").read_text() if (paths.RESULTS / "r" / "TO_USER.md").exists() else ""
        self.assertNotEqual(statuses[-1], "infrastructure_failure")
        self.assertIn("L_1", snap["accepted_nodes"])
        self.assertNotIn("L_1", snap["fenced"])
        self.assertNotEqual(cache["L_1"]["details"][:1], ["scripted GATE_TIMEOUT"])
        self.assertIn("not rechecked at this launch", notes + json.dumps(snap.get("pending_notices", [])))

    def test_a_toolchain_that_does_not_run_still_stops(self):
        w = world()
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            w.admission["L_1"] = "INFRA"
            with changed_gate():
                with self.assertRaises(SystemExit):
                    f.drive(launches=1, max_iterations=2)

    def test_a_rejection_still_fences(self):
        w = world()
        with R.Fixture(w, max_iterations=1) as f:
            f.drive(launches=1)
            w.admission[CID] = "WITNESS_FAIL"
            with changed_gate():
                try:
                    f.drive(launches=1, max_iterations=2)
                except SystemExit:
                    pass                                   # a kept node calling a fenced concept stops, by design
            snap = json.loads((paths.RESULTS / "r" / "state.json").read_text())
        self.assertIn(CID, snap["fenced"])


if __name__ == "__main__":
    unittest.main()
