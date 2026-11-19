"""Declared facts (`fact.*`) in the harness: a planner's record carries them on a span that decides
when the rule applies, with a kind of the closed list and subjects that admit it, and what a source
must hold to declare them true and false; a reuse takes the catalogue's terms; the reading enters
them `proposed` with their terms, the doctor lists them, the run's report lists each with the laws
that read it, and the skeleton, the prose and the scoring know them."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

from harness.checks import validate_a
from harness.lean import render_formula, skeleton
from harness.model.blueprint import Node
from harness.model.reading import Reading, declared_items, declaration_entry, fact_terms_defects, reading_defects
from harness.phases import observable_view
from harness.phases.plan import declaration_catalogue
from recorded import scoring

TERMS = {"meaning": "the road user is performing an official duty of a public office at the time",
         "kind": "duty", "subjects": "user",
         "true_when": "a dispatch or scenario record states the road user is on such a duty at the time",
         "false_when": "a dispatch or scenario record states the road user is on no such duty at the time"}


def node(facts=(), role="exception", narrowings=(), gaps=()) -> Node:
    return Node({"node_id": "L_1", "law_refs": ["L-1"], "binders": [{"name": "v"}],
                 "segmentation": [{"id": "s1", "role": "obligation", "text": "shall stop"}, {"id": "s2", "role": role, "text": "except on duty"}],
                 "elements": [{"span": "s1", "atoms": ["kin.speed"]}], "facts": [dict(d) for d in facts],
                 "narrowings": list(narrowings), "gaps": list(gaps)})


class Validation(unittest.TestCase):
    def test_a_new_fact_joins_with_its_terms_and_a_reuse_takes_them(self):
        cat, terms = {}, {}
        self.assertEqual(validate_a.check_declarations(node([{"span": "s2", "id": "fact.on_duty", **TERMS}]), cat, terms), [])
        self.assertEqual(cat["fact.on_duty"], TERMS["meaning"])
        self.assertEqual(terms["fact.on_duty"]["kind"], "duty")
        reuse = node([{"span": "s2", "id": "fact.on_duty"}])
        self.assertEqual(validate_a.check_declarations(reuse, cat, terms), [])
        self.assertEqual({k: reuse.get("facts")[0][k] for k in TERMS}, TERMS)            # the catalogue's terms are written in
        clash = node([{"span": "s2", "id": "fact.on_duty", "kind": "emergency"}])
        self.assertTrue(any("other than the catalogue's" in e for e in validate_a.check_declarations(clash, cat, terms)))

    def test_a_new_fact_states_every_term(self):
        for drop in ("kind", "subjects", "true_when", "false_when"):
            d = {"span": "s2", "id": "fact.x", **{k: v for k, v in TERMS.items() if k != drop}}
            cat = {}
            self.assertTrue(any("new declared fact" in e for e in validate_a.check_declarations(node([d]), cat, {})), drop)
            self.assertEqual(cat, {}, drop)                                                   # it joins no catalogue

    def test_the_kinds_and_subjects_are_closed_lists(self):
        for kind in ("disabled", "vehicle_class", "district", "intention"):                   # a state, a class, a place, an intention
            self.assertTrue(fact_terms_defects({**TERMS, "kind": kind}))
        self.assertTrue(fact_terms_defects({**TERMS, "subjects": "one"}))
        self.assertTrue(fact_terms_defects({**TERMS, "kind": "map_record", "subjects": "user"}))     # a map record is of a region
        self.assertTrue(fact_terms_defects({**TERMS, "kind": "duty", "subjects": "region"}))         # a road user's fact names it
        self.assertTrue(fact_terms_defects({**TERMS, "kind": "consent", "subjects": "user"}))        # a consent is between two
        for kind, subjects in (("map_record", "region"), ("consent", "user_pair"), ("permit", "user_region"), ("assignment", "user_region")):
            self.assertEqual(fact_terms_defects({**TERMS, "kind": kind, "subjects": subjects}), [], kind)

    def test_role_prefix_and_no_second_reading(self):
        self.assertTrue(any("trigger, subject, condition or exception" in e
                            for e in validate_a.check_declarations(node([{"span": "s1", "id": "fact.x", **TERMS}]), {}, {})))
        self.assertTrue(any("`fact.<snake_case name>`" in e
                            for e in validate_a.check_declarations(node([{"span": "s2", "id": "asm.x", **TERMS}]), {}, {})))
        dual = node([{"span": "s2", "id": "fact.x", **TERMS}], narrowings=[{"span": "s2", "kind": "observable_reading", "category": "status", "why": "w"}])
        self.assertTrue(any("not both" in e for e in validate_a.check_declarations(dual, {}, {})))
        gapped = node([{"span": "s2", "id": "fact.x", **TERMS}], gaps=[{"span": "s2", "kind": "atom"}])
        self.assertTrue(any("no gap is filed" in e for e in validate_a.check_declarations(gapped, {}, {})))

    def test_terms_that_cite_a_law_are_refused(self):
        d = {"span": "s2", "id": "fact.x", **TERMS, "true_when": "the vehicle holds a permit under NRS 484B.117"}
        self.assertTrue(any("cites" in e for e in validate_a.check_declarations(node([d]), {}, {})))

    def test_accounting_and_schema(self):
        n = node([{"span": "s2", "id": "fact.x", **TERMS}])
        self.assertFalse([e for e in validate_a.check_accounting(n) if "s2" in e])
        self.assertEqual(validate_a.schema_errors("L_1", json.loads(json.dumps(n.raw)), {"facts?": validate_a.NODE_SCHEMA["facts?"]}), [])
        self.assertEqual([d["id"] for d in declared_items({"assumptions": [{"id": "asm.a"}], "facts": [{"id": "fact.b"}]})], ["asm.a", "fact.b"])
        self.assertEqual(set(declaration_entry({"id": "fact.b", **TERMS, "span": "s2"})), {"id", *TERMS})
        self.assertEqual(set(declaration_entry({"id": "asm.a", "meaning": "m", "span": "s2"})), {"id", "meaning"})


class ReadingAndReports(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.path = self.root / "reading.json"
        self.path.write_text(json.dumps({"params": [], "aggregates": []}))

    def tearDown(self):
        self.tmp.cleanup()

    def test_entered_proposed_with_its_terms(self):
        added = Reading.add_declarations(self.path, [{"id": "fact.on_duty", **TERMS}], "r/iter-001 L_1")
        self.assertEqual(len(added), 1)
        entry = Reading(self.path).declarations()["fact.on_duty"]
        self.assertEqual({k: entry[k] for k in TERMS}, TERMS)
        self.assertEqual(entry["proposed"], "r/iter-001 L_1")
        self.assertEqual(reading_defects(json.loads(self.path.read_text())), [])
        self.assertTrue(reading_defects({"declarations": [{"id": "fact.y", "meaning": "m"}]}))       # a fact without its terms
        self.assertIn("fact.on_duty", declaration_catalogue(Reading(self.path)))
        self.assertIn("true when:", declaration_catalogue(Reading(self.path)))

    def test_the_doctor_lists_an_unreviewed_fact_with_its_terms(self):
        from scripts.diagnostics.doctor import Doctor, REVIEW
        lib = self.root / "library"
        (lib / "TrafficSpec" / "Readings").mkdir(parents=True)
        (lib / "TrafficSpec" / "Readings" / "x.json").write_text(json.dumps(
            {"params": [], "declarations": [{"id": "fact.on_duty", **TERMS, "proposed": "r/iter-001 L_1"}]}))
        r = Doctor(self.root, lib).reading_proposals_reviewed()
        self.assertEqual(r.status, REVIEW)
        self.assertTrue(any("fact.on_duty" in line and "duty, user" in line for line in r.sources))

    def test_the_report_lists_each_fact_with_the_laws_that_read_it(self):
        records = {"N_1": ("iter-001/plan/blueprint.jsonl", {"law_refs": ["L-1"], "facts": [{"span": "s", "id": "fact.on_duty"}]}),
                   "N_2": ("accepted_nodes.jsonl", {"law_refs": ["L-2"], "facts": [{"span": "s", "id": "fact.on_duty"}]}),
                   "N_3": ("accepted_nodes.jsonl", {"law_refs": ["L-3"]})}
        text = observable_view.render_declared_facts(observable_view.declared_facts(records, {"fact.on_duty": {"id": "fact.on_duty", **TERMS}}))
        self.assertIn("`fact.on_duty` (duty, user)", text)
        self.assertIn("laws `L-1`, `L-2`", text)
        self.assertNotIn("L-3", text)


class Surfaces(unittest.TestCase):
    def test_skeleton_prose_and_scoring(self):
        n = Node({"node_id": "L_1", "law_refs": ["L-1"], "binders": [{"name": "v", "class_elements": []}], "segmentation": [],
                  "elements": [], "scenarios": [], "facts": [{"span": "s1", "id": "fact.t"}, {"span": "s2", "id": "fact.t"}]})
        self.assertIn('    facts := ["fact.t"]', skeleton.rule_skeleton(n).splitlines())
        self.assertEqual(render_formula.formula({"fact": "fact.t", "args": [{"var": "v"}, {"var": "r"}]}, {}),
                         "the source declares `fact.t` true of `v`, `r`")
        self.assertEqual(render_formula.formula({"not": {"fact": "fact.t", "args": [{"var": "v"}]}}, {}),
                         "the source declares `fact.t` false of `v`")
        self.assertEqual(scoring.REASONS["fact_missing"], ("declaration", "data"))


if __name__ == "__main__":
    unittest.main()
