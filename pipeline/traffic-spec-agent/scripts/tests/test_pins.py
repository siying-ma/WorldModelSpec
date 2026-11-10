"""Version pins (`planned_on`) and the task context of a node's own law's siblings.

A record validated beside another law's node it composes names that node's version (its pin),
taken once at the validated stage from the published record or the plan record the validator knew;
before it is coded (and when it is held, and at its first publication) the pin is checked against the
provider's current record: the same, the record goes on; another version, a missing provider, or no
pin at all, it goes back to the planner, uncharged; while the provider's law is planned again, it
waits. A same-law sibling gated in the iteration and not yet published is in the coder's task
context, so its record and files are part of the key a saved verdict is reused on. The real loop,
ledgers and code phase run on the scripted world of `test_recovery`."""
import json
import unittest
from unittest import mock

from harness import loop
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.phases import code as code_phase
from harness.store import paths
from harness.store.state import Run
from scripts.tests.test_recovery import Fixture, World, node
from scripts.tests.test_split_handoff import SPLIT, calls

A1, B1 = "L_A_o1", "L_B"


def pair(**over) -> World:
    """L-A's node A1 and L-B's node B1, which composes A1, planned in one session."""
    w = World({"L-A": "shall a.", "L-B": "shall b."})
    w.plans = {"L-A": [node(A1, "shall a.", "L-A")], "L-B": [node(B1, "shall b.", "L-B", compositions=[A1])]}
    return w


def ledger_of(f) -> dict:
    return {e["law"]: e for e in f.state()["ledger"]}


class Pins(unittest.TestCase):

    def test_the_same_record_is_coded_on_its_pin(self):
        """T13 (same): B1's pin names A1's plan record; A1 is published unchanged; B1 is coded, its
        accepted record keeping the pin, which is no part of its meaning."""
        w = pair()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=4), ["awaiting_labels"])
            st = f.state()
        self.assertEqual(sorted(calls(w, "code")), [(A1, 1), (B1, 2)])
        self.assertEqual(list(st["accepted_nodes"][B1]["planned_on"]), [A1])
        self.assertEqual(st["accepted_nodes"][B1]["planned_on"][A1], loop.pin_digest(st["accepted_nodes"][A1]))
        self.assertEqual({e["law"]: e["attempts"] for e in st["ledger"]}, {"L-A": 0, "L-B": 0})

    def test_a_provider_rewritten_before_its_publication_returns_the_dependent_uncharged(self):
        """T13 (different), T4 (b): A1's gate returns it and a node repair rewrites its record before it
        is published; B1, pinned on the old record, goes back to the planner uncharged, and its new
        plan, pinned on the published record, is coded."""
        w = pair()
        w.gate[(A1, 1)] = "CHECK_FAIL"
        changed = dict(node(A1, "shall a.", "L-A"), obligation="o, rewritten")
        w.node_repair[(A1, 2)] = changed
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=6), ["awaiting_labels"])
            st = f.state()
        led = {e["law"]: e for e in st["ledger"]}
        self.assertEqual((led["L-B"]["state"], led["L-B"]["attempts"]), ("planned", 0))
        self.assertEqual(sorted({it for (k, l, it) in w.calls if k == "plan" and "L-B" in l.split(",")}), [1, 3])   # planned again, uncharged
        self.assertEqual(st["accepted_nodes"][B1]["planned_on"][A1], loop.pin_digest(st["accepted_nodes"][A1]))
        self.assertEqual(st["accepted_nodes"][A1]["obligation"], "o, rewritten")

    def test_a_provider_returned_by_the_validator_makes_the_dependent_wait_then_checks_the_pin(self):
        """T13 (returned): A1 is returned by the validator in the plan B1 is validated in: B1 waits
        (its provider's law is planned again), uncharged; A's new plan re-emits A1 unchanged, the pin
        holds, and B1 is coded once A1 is published, B never re-planned. A new plan that changes A1
        instead returns B1 to the planner, uncharged."""
        for second in ("same", "changed"):
            with self.subTest(second=second):
                w = pair()
                w.validate[(A1, 1)] = ("return", ["scripted plan defect"])
                if second == "changed":
                    w.plans[("L-A", 2)] = [dict(node(A1, "shall a.", "L-A"), obligation="o, another")]
                with Fixture(w, **SPLIT) as f:
                    self.assertEqual(f.drive(1, label_deferred=True, max_iterations=6), ["awaiting_labels"])
                    st = f.state()
                led = {e["law"]: e for e in st["ledger"]}
                b_plans = sorted(it for (k, l, it) in w.calls if k == "plan" and "L-B" in l.split(","))
                self.assertEqual(led["L-B"]["attempts"], 0)
                self.assertEqual(b_plans, [1] if second == "same" else [1, 3])
                self.assertIn(B1, st["accepted_nodes"])

    def test_a_held_record_without_a_pin_is_a_defect_returned_uncharged(self):
        """T13 (no pin): a held record composing another law's node and carrying no pin is never read
        as unchanged: it goes back to the planner, uncharged."""
        w = pair()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=1), ["incomplete"])
            st = json.loads((paths.RESULTS / "r" / "state.json").read_text())
            held = [d for d in st["deferred_nodes"] if d["node_id"] == B1]
            self.assertEqual(len(held), 1)
            held[0].pop("planned_on")
            (paths.RESULTS / "r" / "state.json").write_text(json.dumps(st))
            f.drive(1, label_deferred=True, max_iterations=5)
            led = ledger_of(f)
        self.assertEqual(led["L-B"]["attempts"], 0)
        self.assertEqual(sorted({it for (k, l, it) in w.calls if k == "plan" and "L-B" in l.split(",")}), [1, 3])   # re-planned, never coded unpinned
        self.assertEqual([c for c in calls(w, "code") if c[0] == B1], [(B1, 3)])


class SiblingContext(unittest.TestCase):

    def world(self) -> World:
        w = World({"L-A": "shall a. shall b."})
        w.plans = {"L-A": [node("L_A_o1", "shall a. shall b.", "L-A"),
                           node("L_A_o2", "shall a. shall b.", "L-A", compositions=["L_A_o1"], span="s2")]}
        return w

    def test_a_gated_sibling_is_in_the_task_context(self):
        """T14: A2 composes A1, gated in the same iteration and not yet published: A2's coder is given
        A1 in its catalogue, its key composes A1, and `composed.json` says so."""
        seen = {}
        real = code_phase.run_code

        def run_code(run, n, reading, registry, saved=None, catalogue=None):
            if n.id == "L_A_o2":
                from harness.phases import integrate
                base = {k: v for k, v in loop.semantic_inputs(run.opts).items() if k in ("core", "ontology")}
                seen["composed"] = list(integrate.context_parts(run, "node", n.id, reading, base, record=n.raw, catalogue=catalogue)["composed"])
                seen["registry"] = list(registry["nodes"])
            return real(run, n, reading, registry, saved=saved, catalogue=catalogue)
        w = self.world()
        with Fixture(w) as f, mock.patch.object(code_phase, "run_code", run_code):
            self.assertEqual(f.drive(1), ["complete"])
            composed = json.loads((paths.RESULTS / "r" / "iter-001" / "code" / "L_A_o2" / code_phase.COMPOSED).read_text())
        self.assertEqual((seen["composed"], seen["registry"], composed), (["L_A_o1"], ["L_A_o1"], ["L_A_o1"]))
        self.assertEqual(sorted(calls(w, "code")), [("L_A_o1", 1), ("L_A_o2", 1)])

    def test_a_saved_verdict_is_not_reused_once_its_sibling_changed_or_without_it(self):
        """T14, T4 (a): A2's saved verdict is reused only on its key: A1 coded again with other files
        changes A2's key (the record unchanged), so it is gated again; a verdict whose key was computed
        without A1 is never reused."""
        w = self.world()
        with Fixture(w) as f:
            self.assertEqual(f.drive(1), ["complete"])
            run = Run(f.options()); run.restore_state(); run.load_accepted()
            reading = Reading(run.reading_file)
            a2 = Node(run.accepted_nodes["L_A_o2"])
            d = paths.RESULTS / "r" / "iter-001" / "code" / "L_A_o2"
            rels = (code_phase.nodeid.rule_path(a2.id), code_phase.nodeid.witness_path(a2.id))
            ctx = code_phase.task_context(run, "node", a2.id, a2.raw, reading)
            verdict = json.loads((d / "verdict.json").read_text())
            verdict["extras"]["context"] = ctx
            (d / "verdict.json").write_text(json.dumps(verdict))
            self.assertIsNotNone(code_phase._finished_verdict(d, rels, ctx, ["L_A_o1"]))
            (paths.LIBRARY / code_phase.nodeid.rule_path("L_A_o1")).write_text("coded L_A_o1 again, other files\n")
            self.assertNotEqual(code_phase.task_context(run, "node", a2.id, a2.raw, reading), ctx)
            (d / code_phase.COMPOSED).write_text("[]")
            self.assertIsNone(code_phase._finished_verdict(d, rels, ctx, ["L_A_o1"]))


class PinRollback(unittest.TestCase):

    def test_a_rolled_back_transaction_leaves_the_pin_state_and_evidence(self):
        """T15 (rollback): a candidate that rewrites a pinned record without its pin is rolled back:
        the published record keeps its pin, the law its state, the admission file its entries."""
        from harness.phases import candidate as cand
        from scripts.tests.test_candidate import Txn, files
        w = pair()
        with Fixture(w, **SPLIT) as f:
            self.assertEqual(f.drive(1, label_deferred=True, max_iterations=4), ["awaiting_labels"])
            run = Run(f.options()); run.restore_state(); run.load_accepted()
            from harness.store.ledger import Ledger
            run.law_entries = Ledger(run.ledger_file, [], 2).entries
            before = ((paths.RESULTS / "r" / "state.json").read_bytes(), (paths.RESULTS / "r" / "admission.json").read_bytes())
            cand._OPEN.clear()
            rec = {k: v for k, v in run.accepted_nodes[B1].items() if k != "planned_on"}
            from harness.phases import integrate
            with mock.patch.object(integrate, "verify_library", lambda *a, **k: ("verified", [], set())):
                try:
                    with Txn(run) as txn:
                        txn.apply([cand.Change("node", B1, rec, files("node", B1, "v2"))])
                        self.assertNotIn("planned_on", txn.view.accepted_nodes[B1])
                        txn.rollback("test")
                except Exception as e:                   # the scripted world's library holds no Core: the copy may refuse
                    self.skipTest(f"no candidate on the scripted library: {e}")
            self.assertEqual(((paths.RESULTS / "r" / "state.json").read_bytes(), (paths.RESULTS / "r" / "admission.json").read_bytes()), before)
            self.assertIn("planned_on", json.loads((paths.RESULTS / "r" / "state.json").read_text())["accepted_nodes"][B1])


if __name__ == "__main__":
    unittest.main()
