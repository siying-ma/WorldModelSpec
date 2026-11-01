"""A history-boundary witness: a scenario the plan declares, beside the four standard ones, whose
trace lacks the history the rule would need, so the rule stays unknown for a window truncated at the
trace's start. The plan names the boundary, the skeleton writes it into the witness, and the gate
holds the witness to the plan; Core's `Scenario.run` admits that truncation for it and nothing else
(pinned in `TrafficSpec/Tests/HistoryBoundary.lean`)."""
import unittest

from harness.checks import gate, validate_a
from harness.lean import skeleton
from harness.model.blueprint import Node
from scripts.tests.test_review_routing import ONTO


def node(**extra) -> Node:
    scenarios = [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
                 {"name": "idle", "expected": "not_applicable"}, {"name": "blind", "expected": "unknown", "masked": ["kin.speed"]}]
    scenarios += extra.pop("more", [])
    return Node({"node_id": "L_1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                 "segmentation": [{"id": "s1", "role": "obligation", "text": "stop"}],
                 "elements": [{"span": "s1", "atoms": ["kin.speed"]}], "scenarios": scenarios, **extra})


def boundary_errors(n: Node) -> list[str]:
    return [e for e in validate_a.check_scenarios(n, ONTO) if "history boundary" in e]


class Plan(unittest.TestCase):
    def test_a_boundary_beside_the_four_expecting_unknown_is_admitted(self):
        n = node(more=[{"name": "recording_starts_mid_approach", "expected": "unknown",
                        "boundary": "the approach before the recording began"}])
        self.assertEqual(boundary_errors(n), [])

    def test_a_boundary_on_a_standard_scenario_is_refused(self):
        n = node()
        for s in n.get("scenarios"):
            if s["name"] == "blind":
                s["boundary"] = "the past"
        self.assertEqual(len(boundary_errors(n)), 1)
        self.assertIn("only a scenario beside the four standard ones", boundary_errors(n)[0])

    def test_a_boundary_on_a_decided_scenario_is_refused(self):
        n = node(more=[{"name": "late", "expected": "violated", "boundary": "the approach before the recording"}])
        self.assertIn("a history-boundary scenario expects unknown", boundary_errors(n)[0])

    def test_an_empty_boundary_is_refused(self):
        n = node(more=[{"name": "late", "expected": "unknown", "boundary": "  "}])
        self.assertIn("declares an empty history boundary", boundary_errors(n)[0])

    def test_the_schema_types_the_boundary(self):
        rec = {"node_id": "L_1", "law_refs": ["L-1"], "applicability": "a", "obligation": "o",
               "segmentation": [{"id": "s1", "text": "stop", "role": "obligation"}], "elements": [{"span": "s1"}],
               "binders": [{"name": "v"}], "scenarios": [{"name": "late", "expected": "unknown", "boundary": 3}]}
        self.assertTrue(any("scenarios[0].boundary" in e for e in validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA)))
        rec["scenarios"][0]["boundary"] = "the approach before the recording"
        self.assertFalse(any("boundary" in e for e in validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA)))


class Skeleton(unittest.TestCase):
    def test_the_witness_helper_takes_a_boundary_and_a_planned_one_is_written(self):
        n = node(more=[{"name": "late", "expected": "unknown", "boundary": "the approach\nbefore the recording"}])
        text = skeleton.witness_skeleton(n)
        self.assertIn('    (absent : List String := []) (boundary : String := "") : Scenario :=', text.splitlines())
        self.assertIn('    boundary := boundary }', text.splitlines())
        self.assertIn('witness "late" lateTrace (.unknown []) (boundary := "the approach before the recording")', text)
        self.assertNotIn('witness "blind" blindTrace (.unknown []) ["kin.speed"] (boundary', text)


class Gate(unittest.TestCase):
    def test_the_witness_and_the_plan_declare_the_same_boundaries(self):
        self.assertEqual(gate.boundary_defects({"late"}, {"late"}), [])
        self.assertEqual(gate.boundary_defects({"blind"}, set()), ["blind: the witness declares a history boundary the plan does not"])
        self.assertEqual(gate.boundary_defects(set(), {"late"}), ["late: the plan declares a history boundary the witness does not"])


if __name__ == "__main__":
    unittest.main()
