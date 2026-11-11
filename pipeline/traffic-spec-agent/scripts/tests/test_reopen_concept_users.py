"""The operator's `reopen` clears a failed concept only when every law that used it is reopened.

The concept ledger's users of a concept are derived at each plan from the nodes of that plan. A law
whose plan used the concept and is not planned again (closed at validation, here) must still count
as a user when the concept fails later under another law's plan: reopening only that other law
leaves the concept failed. Reopening both clears it, and a concept only the reopened law used is
cleared. A plan's users replace on the ledger only those of the laws the iteration planned."""
import json
import subprocess
import sys
import unittest
from pathlib import Path

from harness.store import paths
from harness.store.ledger import ConceptLedger
from scripts.tests import test_recovery as R

F = "drv.motion.shared"


def world() -> R.World:
    """L-1 and L-2 both use concept F in iteration 1; L-2's other node is closed at validation, so L-2
    fails and is not planned again. F's gate fails in every iteration: it is coded again with L-1's
    node alone and fails at its second attempt."""
    w = R.World({"L-1": "shall stop.", "L-2": "shall yield. shall go."})
    w.plans = {"L-1": [R.concept(F, users=["L_1"]), R.node("L_1", "shall stop.", "L-1", derived=[F])],
               "L-2": [R.node("L_2_o1", "shall yield.", "L-2", derived=[F]), R.node("L_2_o2", "shall go.", "L-2", span="s2")]}
    w.validate[("L_2_o2", 1)] = (R.validate_a.FAIL, ["scripted: not expressible"])
    for it in range(1, 5):
        w.gate[(F, it)] = "CHECK_FAIL"
    return w


class ReopenKeepsAConceptAnotherLawUsed(unittest.TestCase):
    def cli(self, f, *args):
        """The command line, as `python -m harness` runs it, on the fixture's scratch run."""
        dirs = {k: str(v) for k, v in f.dirs.items()}
        code = ("import json, runpy, sys\nfrom pathlib import Path\nfrom harness.store import paths\n"
                "import harness.model.units  # reads Core when imported, before the paths move\n"
                "for k, v in json.loads(sys.argv[1]).items(): setattr(paths, k, Path(v))\n"
                "sys.argv = ['harness'] + sys.argv[2:]\nrunpy.run_module('harness', run_name='__main__', alter_sys=True)\n")
        r = subprocess.run([sys.executable, "-c", code, json.dumps(dirs), *args], cwd=Path(__file__).resolve().parents[2],
                           capture_output=True, text=True, timeout=120)
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        return r.stdout

    def ledgers(self):
        rd = paths.RESULTS / "r"
        rows = lambda name: [json.loads(l) for l in (rd / name).read_text().splitlines() if l.strip()]
        return {d["law"]: d for d in rows("ledger.jsonl")}, {d["concept"]: d for d in rows("concept_ledger.jsonl")}

    def failed_run(self, f):
        f.drive()
        laws, cons = self.ledgers()
        self.assertEqual((laws["L-1"]["state"], laws["L-2"]["state"], cons[F]["state"]), ("failed", "failed", "failed"))
        self.assertEqual(laws["L-2"]["iteration"], 1)                    # L-2 was planned once, with F
        self.assertEqual(cons[F]["used_by"], ["L_2_o1", "L_1"])           # its use outlives the later plan of L-1

    def test_reopening_one_of_two_users_keeps_the_concept_failed(self):
        with R.Fixture(world(), concept_attempts=2, max_iterations=4) as f:
            self.failed_run(f)
            out = self.cli(f, "reopen", "r", "--laws", "L-1")
            laws, cons = self.ledgers()
        self.assertEqual(laws["L-1"]["state"], "open")
        self.assertNotIn("failed concepts cleared", out)
        self.assertEqual(cons[F]["state"], "failed")

    def test_reopening_every_user_clears_it(self):
        with R.Fixture(world(), concept_attempts=2, max_iterations=4) as f:
            self.failed_run(f)
            out = self.cli(f, "reopen", "r", "--laws", "L-1,L-2")
            rows = [json.loads(l) for l in (paths.RESULTS / "r" / "concept_ledger.jsonl").read_text().splitlines() if l.strip()]
        self.assertIn(f"failed concepts cleared: {F}", out)
        self.assertNotIn(F, [r["concept"] for r in rows])

    def test_a_concept_only_the_reopened_law_used_is_cleared(self):
        w = R.World({"L-1": "shall stop."})
        w.plans = {"L-1": [R.concept(F, users=["L_1"]), R.node("L_1", "shall stop.", "L-1", derived=[F])]}
        for it in range(1, 5):
            w.gate[(F, it)] = "CHECK_FAIL"
        with R.Fixture(w, concept_attempts=2, max_iterations=4) as f:
            f.drive()
            laws, cons = self.ledgers()
            self.assertEqual((laws["L-1"]["state"], cons[F]["state"], cons[F]["used_by"]), ("failed", "failed", ["L_1"]))
            out = self.cli(f, "reopen", "r", "--laws", "L-1")
            _laws, cons = self.ledgers()
        self.assertIn(f"failed concepts cleared: {F}", out)
        self.assertNotIn(F, cons)


class PlannedUsers(unittest.TestCase):
    """How a plan's users of a concept replace the ledger's."""

    def ledger(self):
        import tempfile
        t = tempfile.TemporaryDirectory(); self.addCleanup(t.cleanup)
        cl = ConceptLedger(Path(t.name) / "c.jsonl", 3)
        cl.planned(F, ["L_1", "L_2_o1"], 1)
        cl.returned(F, ["gate CHECK_FAIL"])
        return cl

    def test_a_law_planned_again_without_the_concept_leaves_its_users(self):
        cl = self.ledger()
        cl.planned(F, ["L_1"], 2, {"L-1", "L-2"})
        self.assertEqual(cl.entries[F].used_by, ["L_1"])

    def test_a_law_not_planned_again_keeps_its_users(self):
        cl = self.ledger()
        cl.planned(F, ["L_1"], 2, {"L-1"})
        self.assertEqual(cl.entries[F].used_by, ["L_2_o1", "L_1"])


class GivenWithoutANode(unittest.TestCase):
    def test_a_law_given_to_the_plan_without_a_node_drops_its_users(self):
        """L-1 and L-2 use the concept in iteration 1. In iteration 2 L-1 is given to the plan session,
        which writes no node for it (the law is returned), and L-3 plans the concept again: L-1's old
        user is dropped, its old plan being gone; L-2, closed and not given to the plan, keeps its user."""
        w = R.World({"L-1": "shall stop. shall wait.", "L-2": "shall yield. shall go.", "L-3": "shall slow."})
        w.plans = {("L-1", 1): [R.concept(F, users=["L_1_o1"]), R.node("L_1_o1", "shall stop.", "L-1", derived=[F]),
                                R.node("L_1_o2", "shall wait.", "L-1", span="s2")],
                   ("L-1", 2): [],
                   "L-2": [R.node("L_2_o1", "shall yield.", "L-2", derived=[F]), R.node("L_2_o2", "shall go.", "L-2", span="s2")],
                   ("L-3", 1): [R.node("L_3", "shall slow.", "L-3", derived=[F])],
                   ("L-3", 2): [R.concept(F, users=["L_3"]), R.node("L_3", "shall slow.", "L-3", derived=[F])]}
        w.validate[("L_1_o2", 1)] = ("return", ["scripted plan defect"])
        w.validate[("L_2_o2", 1)] = (R.validate_a.FAIL, ["scripted: not expressible"])
        w.validate[("L_3", 1)] = ("return", ["scripted plan defect"])
        w.gate[(F, 1)] = "CHECK_FAIL"
        with R.Fixture(w, max_iterations=2) as f:
            f.drive()
            rd = paths.RESULTS / "r"
            rows = lambda name: [json.loads(l) for l in (rd / name).read_text().splitlines() if l.strip()]
            laws, cons = {d["law"]: d for d in rows("ledger.jsonl")}, {d["concept"]: d for d in rows("concept_ledger.jsonl")}
        self.assertIn("the plan session produced no node for this law", laws["L-1"]["reasons"])
        self.assertEqual(laws["L-2"]["state"], "failed")
        self.assertEqual(cons[F]["used_by"], ["L_2_o1", "L_3"])


if __name__ == "__main__":
    unittest.main()
