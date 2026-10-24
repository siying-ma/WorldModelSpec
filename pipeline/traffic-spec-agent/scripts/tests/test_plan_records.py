"""Development regression tests for the planner's records: the nested schema, unique identities
across a plan, generated-identifier collisions, a validator fault, the one repair reader, and gaps
as annotations of a mapped span."""
import copy
import json
import tempfile
import unittest
from pathlib import Path

from harness.checks import validate_a
from harness.model.blueprint import Node
from harness.phases import plan

NODE = {"node_id": "L_1", "law_refs": ["L-1"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
        "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
        "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop"}],
        "elements": [{"span": "s1", "atoms": ["kin.speed"], "derived": [], "justification": "j"}],
        "applicability": "a", "obligation": "o", "params": [], "scenarios": [{"name": "forbid", "expected": "violated", "narrative": "n"}]}


class Schema(unittest.TestCase):
    """Each field below, malformed, is returned with a message by the schema check; none stops the validator."""
    def errs(self, path, value):
        rec = copy.deepcopy(NODE)
        o = rec
        for k in path[:-1]:
            o = o[k]
        o[path[-1]] = value
        return validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA)

    def test_reproduced_cases_are_returned_with_their_path(self):
        self.assertEqual(self.errs(("elements", 0, "atoms"), None), [])          # a null optional list is absent
        self.assertEqual(self.errs(("elements", 0, "span"), []), ["L_1: `elements[0].span` must be a non-empty string, not an empty list"])
        self.assertTrue(self.errs(("elements", 0, "atoms"), [{}]))
        self.assertTrue(self.errs(("segmentation",), [{"role": "obligation"}]))
        self.assertTrue(self.errs(("law_refs",), []))
        self.assertTrue(self.errs(("compositions",), [{"span": "s1", "rule": [], "as": "condition"}]))
        self.assertTrue(self.errs(("occasion",), {"under_way": {"atoms": "kin.speed"}}))
        self.assertTrue(self.errs(("param_proposals",), [{"name": [], "unit": "m"}]))

    def test_a_null_optional_field_is_absent(self):
        rec = {**copy.deepcopy(NODE), "residues": None, "elements": [{"span": "s1", "atoms": ["kin.speed"], "derived": None}]}
        self.assertEqual(validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA), [])
        self.assertNotIn("residues", rec)
        self.assertNotIn("derived", rec["elements"][0])

    def test_a_missing_required_list_fails_explicitly(self):
        rec = copy.deepcopy(NODE); del rec["elements"]
        self.assertEqual(validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA), ["L_1: missing field `elements`"])


class Identity(unittest.TestCase):
    def settle(self, rows, taken=None):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            (d / "blueprint.jsonl").write_text("".join(json.dumps(r) + "\n" for r in rows))
            defects, notes = plan.settle_identity(d, taken or {})
            kept = [json.loads(l) for l in (d / "blueprint.jsonl").read_text().splitlines() if l.strip()]
            again = plan.settle_identity(d, taken or {})           # applied once: a resume reads the session's file
            self.assertEqual(again[0], defects)
            return defects, notes, kept

    def test_an_identical_repeat_is_kept_once(self):
        defects, notes, kept = self.settle([NODE, NODE])
        self.assertEqual((defects, len(kept)), ({}, 1))
        self.assertTrue(notes)

    def test_conflicting_records_under_one_id_return_the_law(self):
        other = {**copy.deepcopy(NODE), "obligation": "o2"}
        defects, _notes, kept = self.settle([NODE, other])
        self.assertEqual((list(defects), kept), (["L-1"], []))

    def test_an_id_already_held_returns_the_law(self):
        defects, _n, kept = self.settle([NODE], {"L_1": "an accepted node"})
        self.assertIn("an accepted node", defects["L-1"][0])

    def test_a_concept_proposed_again_differently_returns_the_later_users(self):
        n2 = {**copy.deepcopy(NODE), "node_id": "L_2", "law_refs": ["L-2"]}
        c1 = {"concept_id": "drv.motion.x", "contract": "one", "used_by": ["L_1"]}
        c2 = {"concept_id": "drv.motion.x", "contract": "two", "used_by": ["L_2"]}
        defects, _n, kept = self.settle([NODE, n2, c1, c2])
        self.assertEqual(list(defects), ["L-2"])
        self.assertEqual([r.get("contract") for r in kept if "concept_id" in r], ["one"])

    def test_the_validator_returns_a_repeated_id(self):
        out = validate_a.validate([Node(copy.deepcopy(NODE)), Node(copy.deepcopy(NODE))], {}, None, None, None, {})
        self.assertTrue(all(any("more than one record" in r or "not in the corpus" in r for r in o.reasons) for o in out))


class Collisions(unittest.TestCase):
    def test_generated_identifiers_collide(self):
        errs = validate_a.identifier_collisions("n", {"parameter": ["p.stop_line", "p.stop.line"]})
        self.assertIn("pStopLine", errs[0])


class Fault(unittest.TestCase):
    def test_a_checker_bug_is_a_validator_fault(self):
        saved = validate_a.check_literals
        validate_a.check_literals = lambda n: 1 / 0
        try:
            with self.assertRaises(validate_a.ValidatorFault) as e:
                validate_a._guarded("L_1", validate_a.check_literals, Node(NODE))
            self.assertIn("ZeroDivisionError", e.exception.trace)
        finally:
            validate_a.check_literals = saved


class RepairReader(unittest.TestCase):
    def read(self, text, concept=False, validation=None):
        with tempfile.TemporaryDirectory() as t:
            d = Path(t)
            if text is not None:
                (d / "record.jsonl").write_text(text)
            (d / "planned.json").write_text(json.dumps(NODE))
            if validation is not None:
                (d / "validation.txt").write_text(validation)
            return plan.read_repair(d, concept)

    def test_four_outcomes(self):
        self.assertEqual(self.read(None).kind, "missing")
        self.assertEqual(self.read("{not json").kind, "malformed")
        w = self.read(json.dumps({"withdraw": {"span": "s1", "kind": "atom", "missing": "x"}}))
        self.assertEqual((w.kind, w.withdrawal["span"]), ("withdrawn", "s1"))
        r = self.read(json.dumps({"obligation": "o2"}), validation="accept")
        self.assertEqual((r.kind, r.records[0].id, r.accepted), ("revised", "L_1", True))
        self.assertFalse(self.read(json.dumps({"obligation": "o2"}), validation="L_1: defect").accepted)

    def test_a_concept_split(self):
        rows = [{"concept_id": "drv.motion.a", "withdraw": "two notions", "replaced_by": ["drv.motion.b"]},
                {"concept_id": "drv.motion.b", "contract": "b"}]
        r = self.read("".join(json.dumps(x) + "\n" for x in rows), concept=True)
        self.assertEqual((r.kind, [c.id for c in r.records]), ("withdrawn", ["drv.motion.b"]))


class GapAnnotation(unittest.TestCase):
    def test_a_gap_annotates_a_mapped_span(self):
        mapped = {**copy.deepcopy(NODE), "gaps": [{"span": "s1", "kind": "atom", "proposal": "x"}]}
        self.assertEqual(validate_a.check_accounting(Node(mapped)), [])
        unmapped = {**mapped, "elements": []}
        self.assertTrue(any("no element or operationalization carries" in e for e in validate_a.check_accounting(Node(unmapped))))



class StatedFigures(unittest.TestCase):
    """A stated figure is read as a whole phrase, with its value and where it starts."""
    def read(self, text):
        from harness.model.units import stated_figures
        return [(f.words, float(f.value), f.start) for f in stated_figures(text)]

    def test_compound_words_fractions_decimals_and_units(self):
        self.assertEqual(self.read("within four hundred feet of"), [("four hundred feet", 121.92, 7)])
        self.assertEqual(self.read("twenty-four feet wide")[0][:2], ("twenty-four feet", 7.3152))
        self.assertEqual(self.read("1/2 mile")[0][1], 804.672)
        self.assertEqual(self.read("one and one-half miles")[0][1], 2414.016)
        self.assertEqual(self.read("twelve feet")[0][1], 3.6576)
        self.assertEqual(self.read("15 mph")[0][1], 6.7056)
        self.assertEqual(self.read("2.5 seconds")[0][1], 2.5)
        self.assertEqual(self.read("1,000 feet")[0][1], 304.8)
        self.assertEqual(self.read("from a half hour after")[0][:2], ("half hour", 1800.0))

    def test_no_figure_and_surrounding_text(self):
        self.assertEqual(self.read("the 2 lanes of a highway"), [])
        self.assertEqual(self.read("at a speed of 25 miles per hour, unless"), [("25 miles per hour", 11.176, 14)])

    def test_an_unreadable_phrase_is_typed_never_silent(self):
        from harness.model.units import stated_figures, unsupported_figures
        self.assertEqual(stated_figures("one two feet"), [])
        self.assertEqual([u.words for u in unsupported_figures("one two feet")], ["one two feet"])


class SmallerChecks(unittest.TestCase):
    """Scoped canonical forms, decomposition errors per node, one narrowing schema, anchoring at each level."""
    def test_an_aggregate_binds_its_condition_and_its_term(self):
        from harness.lean.render_formula import canonical
        agg = lambda v, w: {"cmp": "gt", "lhs": {"aggregate": "count", "var": v, "where": {"atom": "p", "args": [{"var": "u"}, {"var": w}]},
                                                  "of": {"lit": 1}}, "rhs": {"lit": 0}}
        self.assertEqual(canonical(agg("w", "w"), ["u"], []), canonical(agg("z", "z"), ["u"], []))
        self.assertNotEqual(canonical(agg("w", "w"), ["u"], []), canonical(agg("z", "w"), ["u"], []))

    def test_shadowing(self):
        from harness.lean.render_formula import canonical
        nest = lambda a, b, c: {"exists_user": a, "body": {"exists_user": b, "body": {"atom": "p", "args": [{"var": c}]}}}
        self.assertEqual(canonical(nest("x", "x", "x"), [], []), canonical(nest("y", "x", "x"), [], []))
        self.assertNotEqual(canonical(nest("x", "x", "x"), [], []), canonical(nest("x", "y", "x"), [], []))

    def test_decomposition_errors_name_their_nodes(self):
        from harness.model import corpus
        law = corpus.Law("L-1", "", "shall stop. shall yield.", "")
        a = Node({"node_id": "L_1_o1", "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop."},
                                                        {"id": "s2", "role": "sibling", "text": "shall yield."}],
                  "elements": [{"span": "s1"}]})
        b = Node({"node_id": "L_1_o2", "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop."},
                                                        {"id": "s2", "role": "sibling", "text": "shall yield."}],
                  "elements": [{"span": "s1"}]})
        errs = validate_a.check_decomposition([a, b], law)
        self.assertTrue(any("L_1_o1" in e and "L_1_o2" in e for e in errs))

    def test_one_narrowing_schema(self):
        from harness.model.blueprint import NARROWING_KINDS, PLANNED_NARROWING_KINDS, CONCEPT_NARROWING_KINDS
        self.assertTrue(PLANNED_NARROWING_KINDS < NARROWING_KINDS and CONCEPT_NARROWING_KINDS < NARROWING_KINDS)
        rec = {**copy.deepcopy(NODE), "narrowings": [{"span": "s1", "kind": "no_atom"}]}
        self.assertTrue(validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA))

    def test_record_anchoring_is_a_record_level_check(self):
        rec = copy.deepcopy(NODE)
        rec["elements"][0]["atoms"] = ["st.curvature"]
        errs = validate_a.check_anchoring(Node(rec))
        self.assertTrue(errs and "record-level" in errs[0] and "formula at the gate" in errs[0])
        rec["elements"][0]["atoms"] = ["st.curvature", "rel.occupies"]
        self.assertEqual(validate_a.check_anchoring(Node(rec)), [])

    def test_formula_anchoring_follows_shared_variables(self):
        from harness.checks.gate import unanchored_variables
        # `r` is tied to the binder `v` through a shared atom; `q` shares an atom only with `w`, which is quantified and untied
        groups = [["?r"], ["v", "r"], ["?q"], ["?w"], ["q", "w"]]
        self.assertEqual(unanchored_variables(groups, ["v"]), ["q", "w"])
        self.assertEqual(unanchored_variables(groups + [["w", "$"]], ["v"]), [])

if __name__ == "__main__":
    unittest.main()
