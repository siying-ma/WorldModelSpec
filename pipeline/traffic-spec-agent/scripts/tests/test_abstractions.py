"""Approved abstractions: the ontology's catalogue parsed by id, a plan's `abstraction` narrowing held
to it (an unknown id or a missing span is returned), the skeleton rendering the record's ids into the
rule, and a rule that rests on one carried as partial coverage through the scoring and the label
check: still compared with its labels, never counted as full statutory alignment. Every check is
static; no model is called."""
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from harness.checks import validate_a
from harness.lean import skeleton
from harness.model import ontology
from harness.model.blueprint import Node
from harness.phases import label_check
from harness.store import paths
from recorded import scoring
from scripts.tests import test_label_check as T

ABS = "equipment_specification_of_observed_use"


def record(narrowings: list[dict]) -> Node:
    return Node({"node_id": "L_9_o1", "law_refs": ["L-9"],
                 "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"},
                                  {"id": "o1", "role": "obligation", "text": "shall show lamps"},
                                  {"id": "d1", "role": "definitional", "text": "meeting the requirements [DEF-X]"}],
                 "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "o1", "atoms": ["sig.hazard_lamps"]}],
                 "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
                 "narrowings": narrowings})


class Catalogue(unittest.TestCase):
    def test_both_ontologies_list_the_abstraction_and_no_atom_is_mistaken_for_one(self):
        for f in ("ATOMS.md", "ATOMS_train.md"):
            o = ontology.load(paths.REPO / "ontology" / f)
            self.assertIn(ABS, o.abstractions, f)
            self.assertIn("partial coverage", o.abstractions[ABS])
            self.assertFalse(set(o.abstractions) & set(o.atoms))


class Validator(unittest.TestCase):
    CAT = {ABS: "scope"}

    def test_a_catalogued_abstraction_on_a_span_is_accepted(self):
        n = record([{"span": "d1", "kind": "abstraction", "abstraction": ABS, "why": "an equipment specification"}])
        self.assertEqual(validate_a.check_narrowings(n, None, "", self.CAT), [])
        self.assertEqual(n.abstractions(), [ABS])
        raw = {**n.raw, "applicability": "a", "obligation": "o", "scenarios": []}
        self.assertEqual(validate_a.schema_errors("L_9_o1", raw, validate_a.NODE_SCHEMA), [])

    def test_an_unknown_id_is_returned(self):
        n = record([{"span": "d1", "kind": "abstraction", "abstraction": "not_in_the_catalogue", "why": "w"}])
        errs = validate_a.check_narrowings(n, None, "", self.CAT)
        self.assertTrue(any("no approved abstraction" in e for e in errs), errs)
        self.assertTrue(validate_a.check_narrowings(record([{"span": "d1", "kind": "abstraction", "why": "w"}]), None, "", self.CAT))
        self.assertTrue(validate_a.check_narrowings(record([{"span": "d1", "kind": "abstraction", "abstraction": ABS, "why": "w"}]), None, ""))

    def test_the_span_and_the_why_are_required(self):
        errs = validate_a.check_narrowings(record([{"span": "x9", "kind": "abstraction", "abstraction": ABS, "why": "w"}]), None, "", self.CAT)
        self.assertTrue(any("unknown span" in e for e in errs), errs)
        errs = validate_a.check_narrowings(record([{"span": "d1", "kind": "abstraction", "abstraction": ABS}]), None, "", self.CAT)
        self.assertTrue(any("no `why`" in e for e in errs), errs)

    def test_the_skeleton_renders_the_record_ids(self):
        src = skeleton.rule_skeleton(record([{"span": "d1", "kind": "abstraction", "abstraction": ABS, "why": "w"}]))
        self.assertIn(f'abstractions := ["{ABS}"] }}', src)
        self.assertIn("abstractions := [] }", skeleton.rule_skeleton(record([])))


def lines(abstractions: list[str], verdict: str = "compliant") -> list[str]:
    return [json.dumps(d) for d in (
        {"kind": "rule", "rule": "R1", "support": "supported", "absent": [], "abstractions": abstractions,
         "partial_coverage": bool(abstractions)},
        {"kind": "grounding", "rule": "R1", "grounding": {"x": 1}, "episode": {"verdict": verdict, "reasons": []}},
        {"kind": "subject", "ego": [1], "binders": {"R1": "x"}})]


class Scoring(unittest.TestCase):
    def test_partial_coverage_is_compared_and_counted_apart(self):
        part = scoring.score("a", "L", "compliant", scoring.rule_results(lines([ABS])), {"R1": "L"})
        full = scoring.score("b", "M", "compliant", scoring.rule_results(lines([])), {"R1": "M"})
        miss = scoring.score("c", "L", "violated", scoring.rule_results(lines([ABS])), {"R1": "L"})
        self.assertEqual((part.status, part.abstractions, part.partial_coverage), ("match", [ABS], True))
        self.assertEqual((full.status, full.abstractions), ("match", []))
        self.assertEqual(miss.status, "mismatch")                     # still compared with its label
        s = scoring.summary([part, full, miss])
        self.assertEqual((s["labelled"], s["matched"]), (1, 1))      # full statutory alignment: b only
        self.assertEqual({k: s["partial_coverage"][k] for k in ("labelled", "matched")}, {"labelled": 2, "matched": 1})
        self.assertEqual(s["partial_coverage"]["abstractions"], [ABS])
        self.assertEqual(part.to_dict()["abstractions"], [ABS])


class LabelCheck(T._Fixture):
    def test_an_aligned_law_under_an_abstraction_is_reported_as_partial_coverage(self):
        spec = {**T.OK, "abstractions": {"R1": [ABS]}}
        c = self.check([("a", "L", "compliant", False, spec), ("b", "L", "compliant", False, spec)])
        self.assertEqual(c.outcome, "aligned")                       # routed like any other law
        self.assertEqual((c.scope, c.abstractions), ("partial_coverage", [ABS]))
        self.assertEqual(c.summary["labelled"], 0)
        self.assertEqual(c.summary["partial_coverage"]["matched"], 2)
        self.assertEqual(c.to_dict()["scope"], "partial_coverage")

    def test_a_law_without_one_is_full(self):
        c = self.check([("a", "L", "compliant", False, T.OK)])
        self.assertEqual((c.outcome, c.scope, c.abstractions, c.summary["labelled"]), ("aligned", "full", [], 1))

    def test_the_evidence_names_the_abstraction(self):
        spec = {**T.BAD, "abstractions": {"R2": [ABS]}}
        c = self.check([("a", "L", "compliant", False, spec)])
        self.assertEqual(c.outcome, "mismatch")
        self.assertIn(f"approved abstraction(s) {ABS}", label_check.render_evidence(c))


if __name__ == "__main__":
    unittest.main()
