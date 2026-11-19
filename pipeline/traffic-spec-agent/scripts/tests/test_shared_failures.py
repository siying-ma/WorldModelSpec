"""One `CHECK_FAIL` line repeated across laws pauses the run (`paused_defect`): a line counts with the node's
own id replaced, only when it names the node, once per law, in one iteration; at the third law the node
stage submits no further session and the run stops once the running ones end. The gates are charged as
any gate is, so laws that made the same fixable mistake keep their counts; the pause is recorded with the
raw lines, the nodes and the spend; the resume takes up what the iteration left and the same line never
pauses the run again."""
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import test_recovery as R                                  # noqa: E402

from harness.store import paths, shared_failures          # noqa: E402
from harness.store.shared_failures import PAUSES, SharedFailures, signature   # noqa: E402

LAWS = ["L-1", "L-2", "L-3", "L-4"]


def line(nid: str) -> str:
    return f"{nid}: aggregate `DEF-X::vehicle` lists `ru.mass`, which is not a road-user class"


def repeated() -> R.World:
    """Four laws, one node each; every gate of both iterations fails on the same check."""
    w = R.World({law: "shall stop." for law in LAWS})
    w.plans = {law: [R.node(law.replace("-", "_"), "shall stop.", law)] for law in LAWS}
    for law in LAWS:
        nid = law.replace("-", "_")
        for it in (1, 2, 3):
            w.gate[(nid, it)] = ("CHECK_FAIL", [line(nid)])
    return w


class Signatures(unittest.TestCase):

    def test_only_the_nodes_own_id_is_replaced(self):
        self.assertEqual(signature("N_1", "N_1: x"), "<node>: x")
        self.assertEqual(signature("N_1", "N_1 binder `v`: x"), "<node> binder `v`: x")
        self.assertEqual(signature("N_1", "N_1_o2: x"), "N_1_o2: x")                   # a sibling node keeps its id
        self.assertEqual(signature("N_1", "composes N_10: x"), "composes N_10: x")   # another node keeps its id
        self.assertEqual(signature("N_1", "M_N_1: x"), "M_N_1: x")

    def test_counting(self):
        with tempfile.TemporaryDirectory() as t:
            sf = SharedFailures(Path(t), {})
            note = "the evaluation was stopped at its deadline; the rows printed before it decide this verdict"
            sig = signature("L_1", line("L_1"))
            sf.record("L-1", "L_1", "CHECK_FAIL", [line("L_1"), note])
            sf.record("L-1", "L_1_o2", "CHECK_FAIL", [line("L_1_o2")])      # a second node of the same law
            sf.record("L-2", "L_2", "WITNESS_FAIL", [line("L_2")])          # only CHECK_FAIL counts
            sf.record("L-2", "L_2", "CHECK_FAIL", [line("L_2")])
            self.assertEqual(sf.due(), [])
            sf.record("L-3", "L_3", "CHECK_FAIL", [line("L_3")])
            self.assertEqual(sf.due(), [sig])
            self.assertNotIn(note, sf.seen)                                 # names no node
            self.assertEqual(SharedFailures(Path(t), sf.seen).due(), [sig])  # a resume of the iteration finds it
            sf.pause([sig], 1, lambda n: Path(t) / n)
            self.assertEqual(sf.due(), [])
            self.assertEqual(SharedFailures(Path(t), sf.seen).due(), [])     # once paused, never again


class Pause(unittest.TestCase):

    def test_three_laws_pause_the_run_charged_as_usual(self):
        w = repeated()
        with R.Fixture(w) as f:
            first = f.drive(launches=1)
            st = f.state()
            pauses = [json.loads(x) for x in (paths.RESULTS / "r" / PAUSES).read_text().splitlines()]
            summary = json.loads((paths.RESULTS / "r" / "summary.json").read_text())
        self.assertEqual(first, ["paused_defect"])
        self.assertEqual(summary["status"], "paused_defect")
        self.assertIn("charged as usual", summary["stop_reason"])
        self.assertEqual([w.calls[("code", n, 1)] for n in ("L_1", "L_2", "L_3", "L_4")], [1, 1, 1, 0])   # nothing submitted after it
        self.assertEqual(len(pauses), 1)
        occ = pauses[0]["occurrences"][signature("L_1", line("L_1"))]
        self.assertEqual(sorted(occ), ["L-1", "L-2", "L-3"])
        self.assertEqual(occ["L-2"]["L_2"]["lines"], [line("L_2")])
        self.assertTrue(occ["L-2"]["L_2"]["task"].endswith("iter-001/code/L_2"))
        self.assertIn("anthropic", pauses[0]["spent_usd"])
        nodes = {e["node"]: e for e in st["node_ledger"]}
        self.assertEqual({n: (nodes[n]["state"], nodes[n]["attempts"]) for n in ("L_1", "L_2", "L_3")},
                         {n: ("returned", 1) for n in ("L_1", "L_2", "L_3")})                   # as any CHECK_FAIL: sent to repair

    def test_the_same_failure_without_the_pause_is_charged_the_same(self):
        """The pause changes when sessions start, never what a gate costs a law: every law ends with the
        counts it has when nothing pauses."""
        w = repeated()
        with R.Fixture(w) as f:
            for _ in range(3):                                # a pause ends a launch: the operator resumes
                f.drive(launches=1)
            paused = f.state()
        w = repeated()
        with mock.patch.object(shared_failures, "SHARED_FAILURE_LAWS", 99), R.Fixture(w) as f:
            f.drive(launches=1)
            plain = f.state()
        for k in ("ledger", "node_ledger"):
            strip = lambda rows: sorted((json.dumps({x: v for x, v in r.items() if x not in ("reasons", "last_task")}, sort_keys=True)
                                         for r in rows), key=str)
            self.assertEqual(strip(paused[k]), strip(plain[k]), k)

    def test_the_resume_takes_up_the_iteration_and_the_line_never_pauses_again(self):
        w = repeated()
        with R.Fixture(w) as f:
            statuses = f.drive(launches=1) + f.drive(launches=1)
            rows = [json.loads(x) for x in (paths.RESULTS / "r" / PAUSES).read_text().splitlines()]
            st = f.state()
        self.assertEqual(statuses[0], "paused_defect")
        self.assertNotEqual(statuses[1], "paused_defect")
        self.assertEqual(w.calls[("code", "L_4", 1)], 1)                                         # coded in the resumed iteration
        self.assertEqual([w.calls[("code", n, 1)] for n in ("L_1", "L_2", "L_3")], [1, 1, 1])   # never coded again
        self.assertEqual(len([r for r in rows if "signatures" in r]), 1)
        self.assertEqual([r["answered"] for r in rows if "answered" in r], [1])                  # the resume answered it, once
        self.assertGreaterEqual(st["iteration"], 2)



class Interrupted(R.Interruptions, unittest.TestCase):

    def test_a_stop_anywhere_resumes_to_the_same_pause(self):
        """The count lives in the iteration's committed progress: a stop at any point before the pause
        resumes to the same pause, with the same ledgers."""
        self.interrupt_everywhere(repeated)

if __name__ == "__main__":
    unittest.main()
