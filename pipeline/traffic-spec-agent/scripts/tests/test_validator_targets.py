"""What a plan may compose, as the validator sees it in the run (`validate_a_for_run`): the other
planned laws' active plan records (held, or under a node repair) are known targets, so a law may be
planned on a node not yet published and coded once it is; a published node its law's current plan no
longer lists is superseded, and `check_compositions` refuses it as it refuses a fenced one."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import validate_a
from harness.model.blueprint import Node
from harness.phases import validate as validate_phase
from harness.store.ledger import Ledger
from scripts.tests.test_candidate import Base, node_rec, world

P1, P2, Q1, C1 = "TEST_VT_1_o1", "TEST_VT_1_o2", "TEST_VT_2", "TEST_VT_3"
LP, LQ, LC = "TEST-VT-1", "TEST-VT-2", "TEST-VT-3"


def comp(nid, *rules):
    return node_rec(nid, compositions=[{"span": "o1", "rule": r, "as": "condition", "map": {"v": "v"}} for r in rules])


class Targets(Base):

    def run_with(self):
        return world({}, {P1: comp(P1)})

    def ledger(self, run) -> Ledger:
        led = Ledger(run.ledger_file, [LP, LQ, LC], 2)
        led.mark_planned(LP, [P1, P2], 1)
        led.mark_planned(LQ, [Q1], 1); led.return_law(LQ, ["r"], 1)
        run.law_entries = led.entries
        run.deferred_nodes = [comp(P2), comp(Q1)]                  # P2 held in P's plan; Q1 held, its law returned
        return led

    def captured(self, run, plan_nodes):
        seen = {}

        def validate(nodes, laws, onto, reading, index, accepted, accepted_concepts, plan_concepts, known_nodes=None, **k):
            seen["known"] = sorted(n.id for n in known_nodes or [])
            seen["accepted"] = {i: bool(n.get("superseded")) for i, n in accepted.items()}
            return []
        with tempfile.TemporaryDirectory() as t, mock.patch.object(validate_a, "validate", validate), \
                mock.patch.object(validate_a, "validate_concepts", lambda *a, **k: []):
            (Path(t) / "blueprint.jsonl").write_text("".join(json.dumps(n) + "\n" for n in plan_nodes))
            (Path(t) / "aggregates.jsonl").write_text("")
            validate_phase.validate_a_for_run(run, Path(t), {}, None, [])
        return seen

    def test_other_planned_laws_active_plan_records_are_known(self):
        with self.run_with() as (run, _lib):
            self.ledger(run)
            seen = self.captured(run, [comp(C1, P2)])
        self.assertEqual(seen["known"], [P2])                   # P's held node; never Q's (its law is planned again)
        self.assertEqual(seen["accepted"], {P1: False})

    def test_a_published_node_left_out_of_its_laws_plan_is_superseded(self):
        with self.run_with() as (run, _lib):
            led = self.ledger(run)
            led.entries[LP].nodes = [P2]
            seen = self.captured(run, [comp(C1, P1)])
        self.assertEqual(seen["accepted"], {P1: True})

    def test_check_compositions_refuses_a_superseded_target(self):
        c = Node(comp(C1, P1))
        ok = validate_a.check_compositions(c, {P1: Node(comp(P1))})
        bad = validate_a.check_compositions(c, {P1: Node({**comp(P1), "superseded": True})})
        self.assertFalse([e for e in ok if "superseded" in e])
        self.assertTrue(any("superseded" in e for e in bad), bad)


if __name__ == "__main__":
    unittest.main()
