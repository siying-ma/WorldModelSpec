"""Development regression tests for the planner's records: the nested schema, unique identities
across a plan, generated-identifier collisions, a validator fault, the one repair reader, gaps
as annotations of a mapped span, and the earlier records a law planned again and a node repair are
shown (every node of the latest plan, later versions, true states, compositions by occurrence)."""
import contextlib
import copy
import json
import shutil
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.checks import validate_a
from harness.model import corpus
from harness.model.blueprint import Node
from harness.phases import plan
from harness.store import paths
from scripts.tests.test_review_routing import ONTO

#: the concept validator runs a Lean program over the built library (as test_precondition_continuity checks; it imports this module)
CORE_BUILT = shutil.which("lake") is not None and (paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core" / "Evidence" / "Adequacy.olean").exists()

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


class AllRequirementsAtOnce(unittest.TestCase):
    """A returned record learns every requirement of the item it misses in the first message: an
    early return never hides a further requirement of the same item."""
    PARAMS = {"drv.motion.turn": {"boundary": "window", "window": "window"}}     # the act each concept record declares

    def occasion_node(self, **occasion):
        rec = copy.deepcopy(NODE)
        rec["segmentation"].append({"id": "c1", "role": "condition", "text": "x"})
        rec["elements"] = [{"span": "s1", "atoms": [], "derived": ["drv.motion.turn"], "justification": "j"},
                           {"span": "c1", "atoms": ["kin.speed"], "derived": [], "justification": "j"}]
        rec["params"] = ["p.turn_window"]
        if occasion:
            rec["occasion"] = occasion
        return Node(rec)

    def requirements_named(self, msg):
        for part in ("`occasion`", "`window`", "`spans`", "`under_way`", "motion", "`occasion_<span>`", "`occasion_<span>_outside`",
                     "different verdicts"):
            self.assertIn(part, msg, part)

    def test_the_first_occasion_message_names_every_requirement(self):
        errs = validate_a.check_occasion(self.occasion_node(), self.PARAMS, ONTO, set(self.PARAMS), {})
        self.assertEqual(len(errs), 1)
        self.requirements_named(errs[0])
        errs = validate_a.check_occasion(self.occasion_node(act="drv.motion.turn", window="p.turn_window", spans={"c1": "some_moment"},
                                                            under_way={"words": "w", "atoms": ["st.lane"], "justification": "j"}),
                                         self.PARAMS, ONTO, set(self.PARAMS), {})
        self.requirements_named(errs[0])
        self.assertTrue(any("reads no motion" in e for e in errs) and any("`occasion_c1`" in e for e in errs)
                        and any("`occasion_c1_outside`" in e for e in errs))
        errs = validate_a.check_occasion(self.occasion_node(act="drv.motion.turn", window="p.turn_window", spans=["c1"]),
                                         self.PARAMS, ONTO, set(self.PARAMS), {})
        self.requirements_named(errs[0])

    def test_a_complete_occasion_passes(self):
        n = self.occasion_node(act="drv.motion.turn", window="p.turn_window", spans={"c1": "some_moment"},
                               under_way={"words": "w", "atoms": ["kin.yaw_rate"], "justification": "j"})
        n.raw["scenarios"] += [{"name": "occasion_c1", "expected": "violated"}, {"name": "occasion_c1_outside", "expected": "compliant"}]
        self.assertEqual(validate_a.check_occasion(n, self.PARAMS, ONTO, set(self.PARAMS), {}), [])

    def test_a_history_boundary_scenario_names_both_defects(self):
        rec = copy.deepcopy(NODE)
        rec["scenarios"].append({"name": "history_boundary", "expected": "violated", "boundary": " "})
        errs = [e for e in validate_a.check_scenarios(Node(rec), ONTO) if "history" in e]
        self.assertEqual(len(errs), 2)

    def test_a_malformed_declaration_still_has_its_span_checked(self):
        rec = copy.deepcopy(NODE)
        rec["intentions"] = [{"span": "s1", "id": "turn", "meaning": "m"}]
        errs = validate_a.check_declarations(Node(rec), {})
        self.assertTrue(any("is not `int." in e for e in errs) and any("trigger, subject, condition or exception span" in e for e in errs))

    def test_a_gap_names_every_defect(self):
        rec = {**copy.deepcopy(NODE), "gaps": [{"span": "s1", "kind": "atom", "proposal": "`kin.speed` for the words"}]}
        errs, gaps = validate_a.check_closed_set(Node(rec), ONTO)
        self.assertTrue(any("nearest" in e for e in errs) and any("already has" in e for e in errs))
        self.assertEqual(gaps, [])


class EventBoundary(unittest.TestCase):
    """An act is what a concept record declares (`act`), with its boundary: a window parameter or
    its observed onset. The occasion states the boundary its acts declare; an event boundary names
    the onset and the recognition and needs no window parameter. Nothing else makes a concept an
    act: a parameter in a unit of time is no declaration. The window form stays as it was."""
    TURN = "drv.motion.turn"
    WINDOW = {TURN: {"boundary": "window", "window": "turn_window"}}
    EVENT = {TURN: {"boundary": "event"}}
    ONSET = {"words": "begins to turn", "atoms": ["kin.yaw_rate"], "derived": [], "justification": "j"}
    UNDER_WAY = {"words": "while turning", "atoms": ["kin.yaw_rate"], "justification": "j"}

    def node(self, params=(), gaps=(), **occasion):
        rec = copy.deepcopy(NODE)
        rec["segmentation"].append({"id": "c1", "role": "condition", "text": "x"})
        rec["elements"] = [{"span": "s1", "atoms": [], "derived": [self.TURN], "justification": "j"},
                           {"span": "c1", "atoms": ["kin.speed"], "derived": [], "justification": "j"}]
        rec["params"] = list(params)
        rec["scenarios"] += [{"name": "occasion_c1", "expected": "violated"}, {"name": "occasion_c1_outside", "expected": "compliant"}]
        if gaps:
            rec["gaps"] = list(gaps)
        if occasion:
            rec["occasion"] = occasion
        return Node(rec)

    def check(self, n, acts=None):
        return validate_a.check_occasion(n, self.EVENT if acts is None else acts, ONTO, {self.TURN}, {})

    def event(self, **kw):
        occ = dict(act=self.TURN, boundary="event", onset=self.ONSET, recognition="where the turn is complete",
                   spans={"c1": "some_moment"}, under_way=self.UNDER_WAY)
        occ.update(kw)
        return {k: v for k, v in occ.items() if v is not None}

    def window(self, **kw):
        return dict(params=["p.turn_window"], act=self.TURN, window="p.turn_window", spans={"c1": "some_moment"},
                    under_way=self.UNDER_WAY, **kw)

    def test_a_declared_act_needs_an_occasion(self):
        errs = self.check(self.node())
        self.assertEqual(len(errs), 1)
        self.assertIn("`boundary`", errs[0]); self.assertIn("`event`", errs[0]); self.assertIn("`onset`", errs[0])

    def test_nothing_but_a_declaration_makes_an_act(self):
        self.assertEqual(self.check(self.node(), {}), [])                   # a time parameter alone declares nothing
        errs = self.check(self.node(**self.window()), {})
        self.assertTrue(any("declares an act (`act`)" in e for e in errs), errs)

    def test_a_complete_event_occasion_passes_with_no_window(self):
        self.assertEqual(self.check(self.node(**self.event())), [])

    def test_the_window_form_stays_valid(self):
        self.assertEqual(self.check(self.node(**self.window()), self.WINDOW), [])

    def test_the_occasion_states_the_boundary_its_acts_declare(self):
        errs = self.check(self.node(**self.window()), self.EVENT)
        self.assertTrue(any("declares `drv.motion.turn`: 'event'" in e for e in errs), errs)
        errs = self.check(self.node(**self.event()), self.WINDOW)
        self.assertTrue(any("declares `drv.motion.turn`: 'window'" in e for e in errs), errs)

    def test_an_event_occasion_names_each_missing_part(self):
        errs = self.check(self.node(params=["p.w"], **self.event(onset={"words": "w", "justification": "j"}, recognition=" ",
                                                                  window="p.w")))
        for part in ("`onset` must be an element", "`recognition` must state", "`window` belongs to"):
            self.assertTrue(any(part in e for e in errs), part)
        errs = self.check(self.node(**self.event(onset={**self.ONSET, "atoms": ["kin.no_such_atom"]})))
        self.assertTrue(any("occasion `onset` names" in e for e in errs), errs)

    def test_a_window_occasion_carries_no_event_fields(self):
        self.assertTrue(any("`onset` belongs to" in e for e in self.check(self.node(**self.window(onset=self.ONSET)), self.WINDOW)))

    def test_an_unwritable_boundary_names_an_operator_gap(self):
        gap = {"span": "s1", "kind": "operator", "proposal": "an onset-anchored heading change", "nearest": [self.TURN]}
        self.assertEqual(self.check(self.node(gaps=[gap], **self.event(gap="s1"))), [])
        errs = self.check(self.node(gaps=[{**gap, "kind": "atom"}], **self.event(gap="s1")))
        self.assertTrue(any("carries no `operator` gap" in e for e in errs), errs)

    def test_the_schema_admits_two_boundaries(self):
        rec = copy.deepcopy(NODE)
        rec["occasion"] = {"boundary": "since", "onset": {"atoms": "kin.yaw_rate"}}
        errs = validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA)
        self.assertTrue(any("occasion.boundary" in e for e in errs) and any("occasion.onset.atoms" in e for e in errs), errs)
        rec["occasion"] = self.event(gap="s1")
        self.assertEqual(validate_a.schema_errors("L_1", rec, validate_a.NODE_SCHEMA), [])

    def test_the_boundary_defaults_to_the_window(self):
        self.assertEqual(self.node(act=self.TURN, window="p.w").occasion_boundary(), "window")
        self.assertEqual(self.node(**self.event()).occasion_boundary(), "event")
        self.assertIsNone(self.node().occasion_boundary())

    def test_the_onset_is_claimed(self):
        n = self.node(**self.event(onset={**self.ONSET, "derived": ["drv.motion.turning"]}))
        self.assertTrue({"kin.yaw_rate", "drv.motion.turning"} <= n.claimed_atoms())
        self.assertIn("drv.motion.turning", n.claimed_concepts())


class ConceptAct(unittest.TestCase):
    """A concept that declares an act states its onset, recognition, extent and history boundary in
    its contract; a window boundary names the time parameter that bounds it, an event boundary none."""
    ONTO_NS = SimpleNamespace(knows=lambda i: True, contract=lambda i: "a contract", primitive_ids=set(), atom_ids=set())
    CONTRACT = ("the vehicle turns, from when it begins to turn until the turn is complete; it holds while the heading keeps "
                "changing, and conduct before the turn began is not read")
    WORDS = {"onset": "begins to turn", "recognition": "until the turn is complete", "extent": "while the heading keeps changing",
             "history": "conduct before the turn began is not read"}

    def errs(self, act, params=()):
        from harness.model.blueprint import ConceptRecord
        rec = ConceptRecord({"concept_id": "drv.motion.turn", "kind": "formula", "contract": self.CONTRACT,
                             "args": [{"name": "v", "sort": "track"}], "params": list(params),
                             "elements": [{"span": "the vehicle turns", "atoms": ["kin.yaw_rate"], "justification": "j"}],
                             "scenarios": [], "act": act})
        return [e for e in validate_a.check_concept(rec, {}, self.ONTO_NS, {}, set(), {}, {}, "train") if "`act." in e or "boundary" in e]

    @unittest.skipUnless(CORE_BUILT, "the Lean toolchain or the built Core is absent: not verified")
    def test_the_act_words_are_the_contract_s(self):
        self.assertEqual(self.errs({"boundary": "event", **self.WORDS}), [])
        errs = self.errs({"boundary": "event", **self.WORDS, "onset": "starts a manoeuvre", "extent": ""})
        self.assertTrue(any("`act.onset`" in e for e in errs) and any("`act.extent`" in e for e in errs), errs)

    @unittest.skipUnless(CORE_BUILT, "the Lean toolchain or the built Core is absent: not verified")
    def test_the_boundary_is_carried_by_the_formals(self):
        window = [{"name": "turn_window", "unit": "s", "meaning": "m"}]
        self.assertEqual(self.errs({"boundary": "window", "window": "turn_window", **self.WORDS}, window), [])
        self.assertTrue(self.errs({"boundary": "window", "window": "turn_window", **self.WORDS}))          # no such formal
        self.assertTrue(self.errs({"boundary": "window", "window": "gap", **self.WORDS},
                                  [{"name": "gap", "unit": "m", "meaning": "m"}]))                       # not a time
        self.assertTrue(self.errs({"boundary": "event", "window": "turn_window", **self.WORDS}, window))
        self.assertEqual(self.errs({"boundary": "event", **self.WORDS}, window), [])                    # a sampling bound may stay

    def test_the_schema_requires_every_part(self):
        raw = {"concept_id": "drv.motion.turn", "kind": "formula", "contract": "c", "args": [], "params": [], "elements": [],
               "scenarios": [], "act": {"boundary": "since", "onset": 3}}
        errs = validate_a.schema_errors("c", raw, validate_a.CONCEPT_SCHEMA)
        for part in ("act.boundary", "act.onset", "act.recognition", "act.extent", "act.history"):
            self.assertTrue(any(part in e for e in errs), part)


class FormulaRestrictions(unittest.TestCase):
    """The planner and the coder read one block of what a formula may not say, cut from Core's own
    comments: the static checks' contracts and the restricted constructors' doc comments."""
    def test_the_block_is_in_the_formula_language_both_roles_read(self):
        from harness.lean import surface
        block = surface.formula_restrictions()
        for name in ("`Rule.check`", "`Concept.check`", "`Term.div`", "`ArgSort.literal`"):
            self.assertIn(name, block)
        self.assertIn("measured atom", block)
        self.assertIn("only where a spelling is expected", block)
        language = surface.formula_language()
        self.assertIn(block, language)
        self.assertIn(language, surface.core_surface({}))
        listing = language.split("### What a formula may not say")[0]
        self.assertIn("| div (a b : Term)", listing)
        self.assertNotIn("bound on a product", listing)            # stated once, in the block
        self.assertNotIn("only where a spelling is expected", surface.concept_language())


class ClaimedAtoms(unittest.TestCase):
    def test_binder_classes_are_claimed(self):
        rec = {**copy.deepcopy(NODE), "subject": {"binder": "v", "class_elements": ["ru.subject", "ru.aggregate=D::vehicle"]},
               "binders": [{"name": "v", "class_elements": ["ru.subject", "ru.aggregate=D::vehicle"]},
                           {"name": "w", "class_elements": ["ru.pedestrian"]}]}
        n = Node(rec)
        self.assertTrue({"ru.subject", "ru.aggregate=D::vehicle", "ru.pedestrian", "kin.speed"} <= n.claimed_atoms())
        self.assertIn("ru_aggregate", n.claimed_names())
        rec["binders"][1]["class_elements"] = ["ru.no_such_class"]
        errs, _ = validate_a.check_closed_set(Node(rec), ONTO)
        self.assertTrue(any("ru.no_such_class" in e for e in errs))


# --- the earlier records a law planned again and a node repair are shown ---

TEXT = ("When a vehicle enters a junction, the driver shall stop at the line. After making such a stop, the driver "
        "shall proceed slowly, yielding to vehicles within the junction.")
LAW5 = corpus.Law("L-5", "A junction", TEXT, "")
CUTS = [("t1", "When a vehicle enters a junction,", "trigger"), ("s1", "the driver", "subject"), ("ob1", "shall stop at the line.", "obligation"),
        ("c1", "After making such a stop,", "condition"), ("s2", "the driver", "subject"), ("ob2", "shall proceed slowly,", "obligation"),
        ("ob3", "yielding to vehicles within the junction.", "obligation")]
SMOKE23 = Path(__file__).with_name("fixtures") / "precondition_smoke23.json"


def rec(nid: str, duty: str, comps=(), law: str = "L-5", cuts=CUTS, **extra) -> dict:
    """A node whose obligation span is `duty`; every other obligation span of the cut is a sibling."""
    seg = [{"id": i, "text": t, "role": ("obligation" if i == duty else "sibling") if r == "obligation" else r} for i, t, r in cuts]
    return {"node_id": nid, "law_refs": [law], "segmentation": seg, "elements": [], "applicability": f"{nid} applicability",
            "obligation": f"{nid} obligation", "compositions": [{"span": s, "rule": r, "map": {"v": "v"}, "as": a} for s, r, a in comps], **extra}


class World:
    """A run directory under a temporary results tree, written iteration by iteration."""
    def __init__(self, root: Path, laws=(LAW5,)):
        self.root = root
        self.accepted: dict = {}
        (root / "laws.jsonl").write_text("".join(json.dumps({"id": l.id, "title": l.title, "text": l.text, "source": l.source}) + "\n" for l in laws))
        self.run = SimpleNamespace(iteration=2, opts=SimpleNamespace(run_id="r", laws=root / "laws.jsonl"), all_nodes=lambda: self.accepted)

    def it(self, n: int) -> Path:
        return paths.iter_dir("r", n)

    def plan(self, n: int, *recs) -> None:
        f = self.it(n) / "plan" / "blueprint.jsonl"
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text("".join(json.dumps(r) + "\n" for r in recs))

    def validated(self, n: int, **kinds) -> None:
        f = self.it(n) / "validate" / "verdicts.jsonl"
        f.parent.mkdir(parents=True, exist_ok=True)
        with f.open("a") as h:
            for nid, (kind, reasons) in kinds.items():
                h.write(json.dumps({"node_id": nid, "kind": kind, "reasons": reasons}) + "\n")

    def coded(self, n: int, raw: dict, verdict: str = "OK", dirname: str | None = None) -> None:
        d = self.it(n) / "code" / (dirname or raw["node_id"])
        d.mkdir(parents=True, exist_ok=True)
        (d / "node.json").write_text(json.dumps(raw))
        (d / "verdict.json").write_text(json.dumps({"verdict": verdict, "details": [f"{verdict} detail"]}))

    def repaired(self, n: int, raw: dict, record: dict, validation: str = "accept") -> None:
        d = self.it(n) / "repair" / raw["node_id"]
        d.mkdir(parents=True, exist_ok=True)
        (d / "planned.json").write_text(json.dumps(raw))
        (d / "record.jsonl").write_text(json.dumps({k: v for k, v in record.items() if k not in plan.FIXED_NODE_KEYS}) + "\n")
        (d / "validation.txt").write_text(validation)


@contextlib.contextmanager
def world(laws=(LAW5,)):
    with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "RESULTS", Path(t) / "results"):
        yield World(Path(t), laws)


@contextlib.contextmanager
def smoke23_world():
    """smoke23's records of one law of three duties as they stood before its iteration-3 plan
    (read-only copies, trimmed where the fixture says), under a temporary results tree."""
    fx = json.loads(SMOKE23.read_text(encoding="utf-8"))
    with tempfile.TemporaryDirectory() as t, mock.patch.object(paths, "RESULTS", Path(t) / "results"):
        for rel, c in fx["files"].items():
            f = paths.run_dir("smoke23") / rel
            f.parent.mkdir(parents=True, exist_ok=True)
            if rel.endswith(".jsonl"):
                f.write_text("".join(json.dumps(x, ensure_ascii=False) + "\n" for x in (c if isinstance(c, list) else [c])), encoding="utf-8")
            else:
                f.write_text(c if isinstance(c, str) else json.dumps(c, ensure_ascii=False), encoding="utf-8")
        (Path(t) / "laws.jsonl").write_text(json.dumps(fx["law"], ensure_ascii=False) + "\n", encoding="utf-8")
        law = corpus.Law(**{k: fx["law"][k] for k in ("id", "title", "text", "source")})
        yield SimpleNamespace(iteration=3, opts=SimpleNamespace(run_id="smoke23", laws=Path(t) / "laws.jsonl"), all_nodes=lambda: {}), law


def entry_of(block: str, nid: str, words: str) -> str:
    """The lines of one node's entry in a rendered block: from its heading to the next heading."""
    head = next((i for i, l in enumerate(block.splitlines()) if l.startswith(f"`{nid}` — ") and words in l), None)
    if head is None:
        raise AssertionError(f"no entry of `{nid}` with {words!r} in the block:\n{block[:600]}")
    lines = block.splitlines()[head:]
    end = next((i for i, l in enumerate(lines[1:], 1) if l.startswith("`") and " — " in l), len(lines))
    return "\n".join(lines[:end])


O1 = rec("L_5_o1", "ob1")
O2 = rec("L_5_o2", "ob2", [("c1", "L_5_o1", "compliance")])
O3 = rec("L_5_o3", "ob3", [("c1", "L_5_o1", "compliance")])


class PreviousRecords(unittest.TestCase):
    def test_callers_never_coded_are_shown_with_their_compositions(self):
        with world() as w:
            w.plan(1, O1, O2, O3)
            w.validated(1, L_5_o1=("accept", []), L_5_o2=("accept", []), L_5_o3=("accept", []))
            w.coded(1, O1)
            block = plan.previous_records(w.run, [LAW5])
        for nid, words in (("L_5_o2", "shall proceed slowly"), ("L_5_o3", "yielding to vehicles")):
            e = entry_of(block, nid, words)
            self.assertIn("- iteration 1: planned; validator accept; not coded", e)
            self.assertIn("- state: not accepted, never coded", e)
            self.assertIn("- span `c1` “After making such a stop,” composes `L_5_o1` as compliance: its duty at characters 45–68; not accepted", e)
            self.assertIn("The record, as planned in iteration 1:", e)

    def test_a_later_repair_is_shown_over_the_plan_and_the_siblings_stay(self):
        with world() as w:
            w.plan(1, O1, O2, O3)
            w.coded(1, O1)
            w.repaired(2, O1, {**O1, "obligation": "the repaired obligation"})
            w.run.iteration = 3
            block = plan.previous_records(w.run, [LAW5])
        e = entry_of(block, "L_5_o1", "shall stop")
        self.assertIn("- iteration 2: repaired; the validator accepted the revision", e)
        self.assertIn("The record, as repaired in iteration 2:", e)
        self.assertIn('"obligation": "the repaired obligation"', e)
        self.assertNotIn('"obligation": "L_5_o1 obligation"', e)
        self.assertIn("It differs from the record planned in iteration 1 in: `obligation`.", e)
        self.assertIn("`L_5_o2` —", block)
        self.assertIn("`L_5_o3` —", block)

    def test_a_returned_repair_does_not_replace_the_coded_record(self):
        with world() as w:
            w.plan(1, O1, O2, O3)
            w.coded(1, O1)
            w.repaired(2, O1, {**O1, "obligation": "a refused revision"}, validation="L_5_o1: a defect")
            w.run.iteration = 3
            e = entry_of(plan.previous_records(w.run, [LAW5]), "L_5_o1", "shall stop")
        self.assertIn("the validator returned the revision: L_5_o1: a defect", e)
        self.assertIn("The record, as coded in iteration 1:", e)
        self.assertNotIn("a refused revision", e)

    def test_states_are_the_recorded_ones(self):
        with world() as w:
            w.plan(1, O1, O2, O3)
            w.validated(1, L_5_o1=("accept", []), L_5_o2=("return", ["L_5_o2: a defect"]), L_5_o3=("accept", []))
            w.coded(1, O1)
            w.coded(1, O3, verdict="WITNESS_FAIL")
            block = plan.previous_records(w.run, [LAW5])
            self.assertNotIn("state: accepted", block)
            self.assertIn("coded: gate OK (OK detail)\n", entry_of(block, "L_5_o1", "shall stop"))
            self.assertNotIn("review", block)                                    # a gated node's state is its gate's
            self.assertIn("- state: not accepted\n", entry_of(block, "L_5_o1", "shall stop") + "\n")
            self.assertIn("validator return: L_5_o2: a defect; not coded", entry_of(block, "L_5_o2", "proceed"))
            self.assertIn("gate WITNESS_FAIL (WITNESS_FAIL detail)\n", entry_of(block, "L_5_o3", "yielding"))
            w.accepted = {"L_5_o1": O1}
            block = plan.previous_records(w.run, [LAW5])
        self.assertIn("- state: accepted", entry_of(block, "L_5_o1", "shall stop"))
        self.assertEqual(block.count("- state: accepted"), 1)
        self.assertIn("composes `L_5_o1` as compliance: its duty at characters 45–68; accepted", block)

    def test_an_unreadable_record_is_named_never_skipped(self):
        with world() as w:
            w.plan(1, O1, O2, O3)
            w.plan(2, O1)
            (w.it(2) / "plan" / "blueprint.jsonl").write_text("{not json")
            w.coded(1, O1)
            (w.it(1) / "code" / "L_5_o1" / "verdict.json").write_text("{not json")
            w.coded(1, O2)
            (w.it(1) / "code" / "L_5_o2" / "node.json").write_text("{not json")
            w.run.iteration = 3
            block = plan.previous_records(w.run, [LAW5])
        self.assertIn("- the plan of iteration 2 could not be read", block)
        self.assertIn("- the coded record of `L_5_o2` in iteration 1 could not be read", block)
        self.assertIn("coded: the gate verdict could not be read", entry_of(block, "L_5_o1", "shall stop"))

    def test_a_renumbered_plan_is_matched_by_occurrence_never_by_suffix(self):
        o1 = rec("L_5_o1", "ob2", [("c1", "L_5_o9", "condition")])
        o2 = rec("L_5_o2", "ob3")
        with world() as w:
            w.plan(1, O1, O2, O3)
            w.coded(1, O1)
            w.coded(1, O2)
            w.plan(2, o1, o2)                                   # the cut changed: the ordinals moved
            w.coded(2, O2, dirname="L_5_o2")                   # an older record under an id the new plan reuses
            w.run.iteration = 3
            block = plan.previous_records(w.run, [LAW5])
        self.assertIn("the plan of iteration 2 and what followed", block)
        self.assertNotIn("iteration 1:", block)
        new = entry_of(block, "L_5_o2", "yielding to vehicles")
        self.assertIn("- state: not accepted, never coded", new)
        old = entry_of(block, "L_5_o2", "shall proceed slowly")
        self.assertIn("- iteration 2: coded: gate OK", old)
        self.assertIn('"node_id": "L_5_o2"', old)
        self.assertIn("composes `L_5_o9` as condition: missing: no record of this id", entry_of(block, "L_5_o1", "shall proceed slowly"))

    def test_identical_words_are_two_occurrences(self):
        text = "The driver shall signal. Later the driver shall signal."
        law = corpus.Law("L-6", "", text, "")
        cuts = [("s1", "The driver", "subject"), ("a", "shall signal.", "obligation"), ("c", "Later", "condition"),
                ("s2", "the driver", "subject"), ("b", "shall signal.", "obligation")]
        first, second = rec("L_6_o1", "a", law="L-6", cuts=cuts), rec("L_6_o2", "b", law="L-6", cuts=cuts)
        misnumbered = rec("L_6_o1", "b", law="L-6", cuts=cuts, obligation="the second occurrence under the first id")
        with world((law,)) as w:
            w.plan(1, first, second)
            w.coded(1, misnumbered)
            block = plan.previous_records(w.run, [law])
        self.assertIn("- state: not accepted, never coded", entry_of(block, "L_6_o1", "(characters 11–24)"))
        other = entry_of(block, "L_6_o1", "(characters 42–55)")
        self.assertIn("the second occurrence under the first id", other)
        self.assertIn("- iteration 1: coded", other)

    def test_a_reference_to_another_law_is_followed_and_a_missing_one_named(self):
        m1 = rec("M_1", "ob1", [("c1", "M_2", "condition"), ("c1", "M_3", "condition")], law="M-1")
        m2 = rec("M_2", "ob1", law="M-2")
        o2 = rec("L_5_o2", "ob2", [("c1", "M_1", "compliance")])
        laws = (LAW5, corpus.Law("M-1", "", TEXT, ""), corpus.Law("M-2", "", TEXT, ""))
        with world(laws) as w:
            w.plan(1, O1, o2, O3, m2)
            w.accepted = {"M_1": m1}
            block = plan.previous_records(w.run, [LAW5])
        tail = block.split("### Nodes of other laws these records compose", 1)[1]
        self.assertIn("composes `M_1` as compliance: a node of another law, below", block)
        self.assertIn("`M_1` (M-1) — its duty: “shall stop at the line.”", tail)
        self.assertIn("- state: accepted; the record as accepted", tail)
        self.assertIn("`M_2` (M-2)", tail)
        self.assertIn("- state: not accepted, not coded since; the record as planned in iteration 1", tail)
        self.assertIn("composes `M_3` as condition: missing: no record of this id", tail)
        self.assertEqual(tail.count("`M_1` (M-1)"), 1)

    def test_a_replan_may_drop_or_correct_a_composition(self):
        """No check holds a new plan to an earlier record's compositions: dropping one, or naming
        another node than an earlier wrong one, adds no defect."""
        def reasons(*recs):
            out = validate_a.validate([Node(copy.deepcopy(r)) for r in recs], {LAW5.id: LAW5}, ONTO, SimpleNamespace(), SimpleNamespace(), {})
            return {o.node.id: sorted(o.reasons) for o in out}
        kept = reasons(O1, O2, O3)
        dropped = reasons(O1, rec("L_5_o2", "ob2"), O3)
        self.assertTrue(set(dropped["L_5_o2"]) <= set(kept["L_5_o2"]), set(dropped["L_5_o2"]) - set(kept["L_5_o2"]))
        # an earlier plan composed the second node where the words refer to the first: the correction names no earlier target
        self.assertFalse([r for r in reasons(O1, O2, O3)["L_5_o3"] if "L_5_o2" in r])


class RepairContext(unittest.TestCase):
    def test_the_repair_prompt_shows_the_referenced_records(self):
        blocks = {}
        m1 = rec("M_1", "ob1", law="M-1", obligation="the other law's duty")
        o2 = rec("L_5_o2", "ob2", [("c1", "L_5_o1", "compliance"), ("c1", "M_1", "condition")])
        laws = (LAW5, corpus.Law("M-1", "", TEXT, ""))
        with world(laws) as w:
            w.plan(1, O1, o2, O3)
            w.coded(1, O1)
            w.coded(1, o2)
            w.accepted = {"M_1": m1}
            d = w.root / "iter"
            run = SimpleNamespace(iter=d, dir=d, iteration=2, mapping_file=d / "mapping.json", all_nodes=lambda: w.accepted,
                                  all_concepts=lambda: {}, law_entries={}, fenced={}, opts=SimpleNamespace(dry_run=True, plan_turns=1, plan_effort="low", run_id="r",
                                                                                 laws=w.root / "laws.jsonl"))
            last = d / "last"
            last.mkdir(parents=True)
            with mock.patch.object(plan.render, "render", lambda _name, b, **_k: blocks.update(b) or "prompt"), \
                    mock.patch.object(plan, "definitions_for", lambda _run, _laws: []):
                reading = SimpleNamespace(data={"params": []}, params=[], pending_aggregates=False)
                plan.run_node_repair(run, Node(o2), ["r"], last, LAW5, [], [Node(O1), Node(O3)], reading, ONTO)
        node = blocks["node"]
        o1 = entry_of(node, "L_5_o1", "shall stop")
        self.assertIn("- state: not accepted; the record as coded in iteration 1", o1)
        self.assertIn("- obligation: L_5_o1 obligation", o1)
        self.assertIn("`L_5_o3` —", node)
        self.assertIn("composes `L_5_o1` as compliance: its duty at characters 45–68; not accepted", node)
        self.assertIn("`M_1` (M-1)", node)
        self.assertIn("- obligation: the other law's duty", node)
        self.assertIn("- state: accepted; the record as accepted", node)


def smoke23_duties() -> list[tuple[str, str]]:
    """The fixture's plan of iteration 1: each node id with the first words of its obligation span."""
    fx = json.loads(SMOKE23.read_text(encoding="utf-8"))
    return [(r["node_id"], next(x["text"] for x in r["segmentation"] if x["role"] == "obligation")[:30])
            for r in fx["files"]["iter-001/plan/blueprint.jsonl"]]


class Smoke23Records(unittest.TestCase):
    """smoke23, a law of three duties before its iteration-3 plan: only the first node had been
    coded; the other two had been planned composing it and validated, never coded."""

    def test_the_uncoded_callers_are_shown(self):
        fx = json.loads(SMOKE23.read_text(encoding="utf-8"))
        (o1, w1), (o2, w2), (o3, w3) = smoke23_duties()
        self.assertEqual(fx["iteration_3_prompt"]["previous_record_nodes"], [o1])          # what the run showed
        with smoke23_world() as (run, law):
            block = plan.previous_records(run, [law])
        for nid, words in ((o2, w2), (o3, w3)):
            e = entry_of(block, nid, words)
            self.assertIn(f"composes `{o1}` as compliance", e)
            self.assertIn("- iteration 1: planned; validator accept; not coded", e)
            self.assertIn("- iteration 2: validator accept; not coded", e)
            self.assertIn("- state: not accepted, never coded", e)
        self.assertIn("the plan of iteration 1 and what followed", block)
        e1 = entry_of(block, o1, w1)
        self.assertIn("The record, as coded in iteration 2:", e1)
        self.assertIn("- iteration 2: repaired; the validator accepted the revision; validator accept; coded: gate OK", e1)
        self.assertNotIn("state: accepted", block)


if __name__ == "__main__":
    unittest.main()
