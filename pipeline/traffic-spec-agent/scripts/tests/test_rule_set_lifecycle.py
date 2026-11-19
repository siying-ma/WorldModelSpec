"""The run lifecycle of rules that read rule sets, of case requests and of permissions.

- A law that reads a rule-set operator is checked against one library; when a member is added,
  changed or fenced its check is marked invalid at once and an accepted law loses its acceptance
  until the check runs again (no stale acceptance).
- A composition naming a case its target does not declare returns the target to its planner at most
  twice per (caller, target, case) and target version, and then files a gap on the caller: no loop.
- A law whose every node is a permission is accepted as generated, not label-aligned, never as an
  ordinary label acceptance.

The loop functions run on a real ledger with a minimal run object; nothing is gated or planned."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace as NS
from unittest import mock

from harness import loop
from harness.checks import validate_a
from harness.phases import case_requests
from harness.store.ledger import Ledger


def make_run(t: str, nodes: dict, label_repair: bool = True):
    return NS(dir=Path(t), label_states={}, fenced={}, iteration=3, opts=NS(label_repair=label_repair),
              all_nodes=lambda: nodes)


def ledger_with(t: str, plans: dict, states: dict) -> Ledger:
    led = Ledger(Path(t) / "ledger.jsonl", sorted(plans), 3)
    for law, nodes in plans.items():
        e = led.entries[law]
        e.state, e.nodes = states.get(law, "accepted"), list(nodes)
    return led


class SetReaders(unittest.TestCase):

    def setUp(self):
        self.t = tempfile.TemporaryDirectory()
        self.nodes = {"R": {"node_id": "R", "law_refs": ["L-R"], "rule_sets": [{"op": "required_by", "conduct": "halt"}]},
                      "M": {"node_id": "M", "law_refs": ["L-M"], "cases": [{"name": "c", "kind": "requires", "conduct": "halt"}]}}
        self.run = make_run(self.t.name, self.nodes)
        self.led = ledger_with(self.t.name, {"L-R": ["R"], "L-M": ["M"]}, {})

    def tearDown(self):
        self.t.cleanup()

    def test_an_unchanged_library_keeps_the_check(self):
        loop.record_set_digest(self.run, self.led, "L-R")
        self.assertEqual(loop.invalidate_set_readers(self.run, self.led, []), [])
        self.assertEqual(self.led.entries["L-R"].state, "accepted")

    def test_a_changed_member_invalidates_the_check_and_the_acceptance(self):
        loop.record_set_digest(self.run, self.led, "L-R")
        self.nodes["M"] = {**self.nodes["M"], "cases": [{"name": "c2", "kind": "requires", "conduct": "halt"}]}
        out = []
        self.assertEqual(loop.invalidate_set_readers(self.run, self.led, out), ["L-R"])
        self.assertEqual(self.led.entries["L-R"].state, "planned")                         # no stale acceptance
        st = self.run.label_states["L-R"]
        self.assertIn("a rule its rule-set operator reads changed", st["check_invalid"])
        self.assertEqual(st["state"], "waiting")
        self.assertNotIn("set_digest", st)
        self.assertEqual(loop.invalidate_set_readers(self.run, self.led, []), [])          # marked once
        self.assertEqual(self.led.entries["L-M"].state, "accepted")                        # the member's own law is untouched

    def test_an_added_or_fenced_member_invalidates_too(self):
        loop.record_set_digest(self.run, self.led, "L-R")
        self.nodes["N"] = {"node_id": "N", "law_refs": ["L-N"]}
        self.assertEqual(loop.invalidate_set_readers(self.run, self.led, []), ["L-R"])
        loop.record_set_digest(self.run, self.led, "L-R")
        self.led.entries["L-R"].state = "accepted"
        self.run.fenced["M"] = {"reason": "re-planned"}
        self.assertEqual(loop.invalidate_set_readers(self.run, self.led, []), ["L-R"])

    def test_a_law_reading_no_set_is_never_invalidated(self):
        self.run.label_states["L-M"] = {"set_digest": "x"}
        self.assertEqual(loop.invalidate_set_readers(self.run, self.led, []), [])

    def test_an_invalid_check_awaiting_repair_is_checked_again(self):
        self.run.label_states["L-R"] = {"state": "awaiting_label_repair", "nodes": ["R"], "check_invalid": "member changed"}
        self.led.entries["L-R"].state = "planned"
        with mock.patch.object(loop, "label_scope", lambda run: None), mock.patch.object(loop, "in_scope", lambda s, l: True), \
                mock.patch.object(loop, "stale_labels", lambda *a: set()), mock.patch.object(loop, "own_generated", lambda *a: True), \
                mock.patch.object(loop, "reached_laws", lambda *a: set()), mock.patch.object(loop, "Availability", lambda *a, **k: None):
            self.assertIn("L-R", loop.label_ready(self.run, self.led))
            self.run.label_states["L-R"].pop("check_invalid")
            self.assertNotIn("L-R", loop.label_ready(self.run, self.led))


class CaseRequests(unittest.TestCase):

    def test_two_returns_per_version_then_a_gap(self):
        st = {}
        self.assertEqual(case_requests.decide(st, "C", "T", "c", "v1"), ("return", 1))
        self.assertEqual(case_requests.decide(st, "C", "T", "c", "v1"), ("return", 2))
        self.assertEqual(case_requests.decide(st, "C", "T", "c", "v1"), ("gap", 2))
        self.assertEqual(case_requests.decide(st, "C", "T", "c", "v1"), ("gap", 2))          # never a third return
        self.assertEqual(case_requests.decide(st, "C", "T", "c", "v2"), ("return", 1))     # a new version is counted again
        self.assertEqual(case_requests.decide(st, "D", "T", "c", "v2"), ("return", 1))     # per caller

    def _route(self, t: str, nodes: dict, led: Ledger, state_before: dict | None = None):
        run = make_run(t, nodes)
        if state_before is not None:
            case_requests.save(Path(t) / "case_requests.json", state_before)
        gaps = NS(added=[])
        gaps.add = lambda proposal, run_id, it: (gaps.added.append(proposal), "G1")[1]
        gaps.decision = lambda gid: None
        reason = validate_a.missing_case("C_1", "T_1", "crossing")
        verdicts = {"L-C": [NS(kind="return", reasons=[reason], node=NS(id="C_1", law="L-C"))]}
        notes, to_user, filed = [], [], []
        blocked = loop.route_missing_cases(run, led, gaps, verdicts, lambda i: {"T_1": "L-T", "C_1": "L-C"}[i], "r", notes, to_user, filed)
        return blocked, gaps, run

    def test_the_target_is_returned_then_a_traceable_gap_on_the_caller(self):
        with tempfile.TemporaryDirectory() as t:
            nodes = {"T_1": {"node_id": "T_1", "law_refs": ["L-T"]}}
            led = ledger_with(t, {"L-T": ["T_1"], "L-C": ["C_1"]}, {"L-T": "accepted", "L-C": "planned"})
            blocked, gaps, run = self._route(t, nodes, led)
            self.assertEqual(blocked, set())
            self.assertEqual(led.entries["L-T"].state, "returned")                      # revoked, then returned to its planner
            self.assertEqual(led.entries["L-T"].attempts, 1)                             # the return counts an attempt
            led.entries["L-T"].state = "planned"
            blocked, gaps, run = self._route(t, nodes, led)
            self.assertEqual(blocked, set())
            led.entries["L-T"].state = "planned"
            blocked, gaps, run = self._route(t, nodes, led)                              # the third request of the same version
            self.assertEqual(blocked, {"L-C"})
            self.assertEqual(led.entries["L-C"].state, "blocked")
            self.assertEqual(led.entries["L-C"].gaps, ["G1"])
            p = gaps.added[0]
            self.assertEqual((p["kind"], p["node_id"], p["law_refs"]), ("case", "C_1", ["L-C"]))
            self.assertIn("`C_1` reads case `crossing` of `T_1`", p["proposal"])
            self.assertIn("after 2 returns", p["proposal"])
            st = json.loads((Path(t) / "case_requests.json").read_text())
            self.assertEqual(st["C_1|T_1|crossing"]["returns"], 2)

    def test_a_changed_target_is_asked_again(self):
        with tempfile.TemporaryDirectory() as t:
            nodes = {"T_1": {"node_id": "T_1", "law_refs": ["L-T"], "segmentation": [{"id": "o", "text": "a"}]}}
            led = ledger_with(t, {"L-T": ["T_1"], "L-C": ["C_1"]}, {"L-T": "planned", "L-C": "planned"})
            old = case_requests.target_version({"T_1": {"node_id": "T_1"}}, "T_1")
            blocked, _g, _r = self._route(t, nodes, led, {"C_1|T_1|crossing": {"version": old, "returns": 2, "gap": True}})
            self.assertEqual(blocked, set())                                             # the version changed: counted again
            self.assertEqual(led.entries["L-T"].state, "returned")


class Permissions(unittest.TestCase):

    def test_a_permission_only_law_is_generated_not_label_aligned(self):
        with tempfile.TemporaryDirectory() as t:
            nodes = {"P_1": {"node_id": "P_1", "law_refs": ["L-P"], "permission": True},
                     "D_1": {"node_id": "D_1", "law_refs": ["L-D"]}}
            run = make_run(t, nodes)
            led = ledger_with(t, {"L-P": ["P_1"], "L-D": ["D_1"]}, {"L-P": "planned", "L-D": "planned"})
            with mock.patch.object(loop, "Availability", lambda *a, **k: None), mock.patch.object(loop, "own_generated", lambda *a: True):
                self.assertEqual(loop.accept_permissions(run, led, []), ["L-P"])
            self.assertEqual(led.entries["L-P"].state, "accepted")
            self.assertEqual(run.label_states["L-P"]["state"], "generated_not_label_aligned")    # never an ordinary label acceptance
            self.assertEqual(led.entries["L-D"].state, "planned")                                # a duty waits for its label check
            self.assertTrue(loop.permission_only(run, "L-P", led))
            self.assertFalse(loop.permission_only(run, "L-D", led))


if __name__ == "__main__":
    unittest.main()
