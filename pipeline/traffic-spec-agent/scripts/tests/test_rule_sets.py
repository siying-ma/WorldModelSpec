"""Rule-set operators, cases and permissions at the plan, the gate and the label check.

Words that name no rule but the rules of the library as a whole are a rule-set operator on their
span (`rule_sets`): `required_by` (some rule requires the conduct of the road user here) or `lawful`
(the road user complies with every rule of a scope engaged for it). A node declares in `cases` the
situations its words provide for (a conduct its duty requires, an act it permits), which other
nodes read through `required_by` or a composition naming the case; a line that only permits is a
permission node. The validator holds the records to Core's vocabulary, to the case anchoring and to
the strata; the gate holds the rule's operators and cases to the record and each case to the rule's
own verdicts on its witnesses (positive and negative controls); the label check passes the sets that
may lack a rule to the monitor. The gate cases run on real Lean; they are skipped where the
toolchain or the built Core is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate, validate_a
from harness.lean import lean, render_formula, surface
from harness.model import nodeid
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests import test_reference_guards as G
from scripts.tests.test_gate_phases import Ran, _library

BRANCH = '  , witness "branch_1" (Build.trace 3 0 (Units.seconds 1) fun _ t => Build.scene t (some 1)\n      [Build.user 1 [.motorVehicle, .emergencyVehicle] (m 80, m 2) Build.east (m 5) (m 2, m 1, m 1), walker] [lane, junction] []) .compliant\n  , witness "blind"'

L = G.L
TEXT = "the driver shall not halt, except in compliance with law."


def record(**over) -> dict:
    r = {"node_id": "STA_900A_100_1", "law_refs": [L],
         "segmentation": [{"id": "s1", "text": "the driver", "role": "subject"},
                          {"id": "o1", "text": "shall not halt,", "role": "obligation"},
                          {"id": "e1", "text": "except in compliance with law.", "role": "exception"}],
         "elements": [{"span": "s1", "atoms": ["ru.subject"]}, {"span": "o1", "atoms": ["kin.speed"]}],
         "rule_sets": [{"span": "e1", "op": "required_by", "conduct": "halt", "who": "veh"}],
         "exception_kinds": [{"span": "e1", "kind": "meets_duty"}],
         "binders": [{"name": "veh"}], "applicability": "a", "obligation": "o", "scenarios": copy.deepcopy(G.SCENARIOS)}
    r.update(over)
    return r


def validate(raw: dict) -> validate_a.Outcome:
    return G.validate(raw, TEXT)


class Records(unittest.TestCase):

    def assertReturned(self, out, words: str):
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(words in r for r in out.reasons), out.reasons)

    def test_required_conduct_carries_its_span_and_waits_on_nothing(self):
        out = validate(record())
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertEqual(out.node.dependencies(), [])

    def test_a_conduct_core_does_not_declare(self):
        self.assertReturned(validate(record(rule_sets=[{"span": "e1", "op": "required_by", "conduct": "yield", "who": "veh"}])),
                            "requires conduct 'yield'")

    def test_an_operator_is_one_carrier_of_its_span(self):
        r = record()
        r["elements"].append({"span": "e1", "atoms": ["kin.speed"]})
        self.assertReturned(validate(r), "span e1 (exception) is carried by 2 entries")

    def test_a_class_scope_names_its_aggregate(self):
        self.assertReturned(validate(record(rule_sets=[{"span": "e1", "op": "lawful", "scope": "subject_class", "who": "veh"}])),
                            "names an aggregate id")
        out = validate(record(rule_sets=[{"span": "e1", "op": "lawful", "scope": "as_class", "aggregate": "DEF-1::vehicle", "who": "veh"}]))
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_an_unknown_operator_or_scope_is_refused_by_the_schema(self):
        self.assertReturned(validate(record(rule_sets=[{"span": "e1", "op": "complies", "who": "veh"}])), "rule_sets")
        self.assertReturned(validate(record(rule_sets=[{"span": "e1", "op": "lawful", "scope": "all", "who": "veh"}])), "rule_sets")

    def test_a_case_sits_on_a_span_of_its_kind_and_states_its_situation(self):
        case = {"span": "o1", "name": "halt_for_walker", "kind": "requires", "conduct": "halt", "situation": "a person is on the crossing ahead"}
        r = record(rule_sets=[], cases=[case])
        r["elements"].append({"span": "e1", "atoms": ["kin.speed"]})
        self.assertReturned(validate(r), "scenario `stop_halt_for_walker_halt` missing")   # a halt is held to its paired witnesses
        r["scenarios"] += [{"name": "stop_halt_for_walker_halt", "expected": "compliant"}, {"name": "stop_halt_for_walker_drive", "expected": "violated"}, {"name": "stop_halt_for_walker_creep", "expected": "violated"}]
        out = validate(r)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertReturned(validate({**r, "cases": [{**case, "span": "e1"}]}), "a `requires` case is stated on a span of role ['obligation']")
        self.assertReturned(validate({**r, "cases": [{**case, "situation": " "}]}), "states no situation")
        self.assertReturned(validate({**r, "cases": [{**case, "name": "Halt"}]}), "a case name is lower-case")
        self.assertReturned(validate({**r, "cases": [case, case]}), "share the name")
        permits = {"span": "e1", "name": "may_go", "kind": "permits", "situation": "the crossing is clear"}
        out = validate({**r, "cases": [permits]})
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))

    def test_a_node_that_reads_an_operator_declares_no_requires_case(self):
        out = validate(record(cases=[{"span": "o1", "name": "c", "kind": "requires", "conduct": "halt", "situation": "always"}]))
        self.assertReturned(out, "declares a case requiring a conduct and reads a rule-set operator")

    def test_a_permission_only_line_is_a_permission_node(self):
        text = "the driver may proceed when the way is clear."
        seg = [{"id": "s1", "text": "the driver", "role": "subject"}, {"id": "p1", "text": "may proceed", "role": "permission"},
               {"id": "c1", "text": "when the way is clear.", "role": "condition"}]
        r = record(segmentation=seg, rule_sets=[], exception_kinds=[], elements=[{"span": "s1", "atoms": ["ru.subject"]}, {"span": "p1", "atoms": ["kin.speed"]},
                                                                                  {"span": "c1", "atoms": ["kin.speed"]}])
        self.assertReturned(G.validate(r, text), "it is a permission node")
        perm = {**r, "permission": True, "cases": [{"span": "p1", "name": "proceed_when_clear", "kind": "permits", "situation": "the way is clear"}],
                "scenarios": [x for x in copy.deepcopy(G.SCENARIOS) if x["name"] != "forbid"]}
        out = G.validate(perm, text)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertReturned(G.validate({**perm, "cases": []}, text), "declares the cases it permits and requires nothing")

    def test_an_exception_reading_a_case_the_target_does_not_declare(self):
        known = G.accepted()
        r = G.record("Except as otherwise provided in subsection 2 [STA-900A-200-2],",
                     compositions=[{"span": "r1", "as": "exception", "rule": "STA_900A_200_2", "map": {"veh": "veh"}, "case": "crossing"}])
        out = G.validate(r, known=known)
        self.assertReturned(out, "composes case `crossing` of `STA_900A_200_2`, which declares no such case")
        self.assertTrue(any(validate_a.MISSING_CASE.match(x) for x in out.reasons))
        known["STA_900A_200_2"].raw["cases"] = [{"span": "o", "name": "crossing", "kind": "permits", "situation": "s"}]
        out = G.validate(r, known=known)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertEqual([c["rule"] for c in out.node.dependencies()], ["STA_900A_200_2"])      # still a dependency


class Purposes(unittest.TestCase):

    def assertReturned(self, out, words: str):
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any(words in r for r in out.reasons), out.reasons)

    def test_a_purpose_scope_names_a_purpose_of_core(self):
        ok = {"span": "e1", "op": "lawful", "scope": "purpose", "purpose": "device_instruction", "who": "veh"}
        out = validate(record(rule_sets=[ok]))
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertReturned(validate(record(rule_sets=[{**ok, "purpose": "anything"}])), "a purpose scope names one of Core's purposes")
        self.assertReturned(validate(record(rule_sets=[{**ok, "scope": "every"}])), "no other scope names one")
        both = {**ok, "scope": "as_class_purpose", "aggregate": "DEF-1::vehicle"}
        out = validate(record(rule_sets=[both]))
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertEqual(gate.rule_set_id(both), "#lawful:aspurpose:device_instruction:DEF-1::vehicle")

    def test_a_declared_purpose_names_its_span_and_why(self):
        r = record(purposes=[{"purpose": "standing_or_parking", "span": "o1", "why": "it forbids a halt"}])
        self.assertReturned(validate(r), "scenario `purpose_standing_or_parking_halt` missing")
        r["scenarios"] += [{"name": "purpose_standing_or_parking_halt", "expected": "violated"},
                           {"name": "purpose_standing_or_parking_move", "expected": "compliant"}]
        out = validate(r)
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))
        self.assertReturned(validate({**r, "purposes": [{"purpose": "x", "span": "o1", "why": "w"}]}), "is none of Core's")
        self.assertReturned(validate({**r, "purposes": [{"purpose": "standing_or_parking", "span": "zz", "why": "w"}]}), "no span of the node")

    def test_the_surface_lists_the_purposes(self):
        self.assertEqual(surface.purposes(), {"device_instruction", "standing_or_parking"})


class Surface(unittest.TestCase):

    def test_conducts_are_cores(self):
        self.assertEqual(surface.conducts(), {"halt"})

    def test_the_language_shows_the_operators_and_the_cases(self):
        self.assertIn("| requiredBy (conduct : Conduct) (who : String)", surface.formula_language())
        self.assertIn("inductive RuleScope", surface.formula_language())
        self.assertIn("structure RuleCase where", surface.rule_and_scenario())
        self.assertIn("inductive CaseKind", surface.rule_and_scenario())
        self.assertIn("| ruleCase (id : String) (name : String) (map : List (String × String))", surface.formula_language())
        self.assertIn("setMembers", surface.rule_and_scenario())

    def test_rendered_as_prose(self):
        self.assertEqual(render_formula.formula({"required_by": "halt", "who": "v"}, {}), "some rule of the library requires halt of `v` here")
        self.assertIn("read as binding `v` whatever its class",
                      render_formula.formula({"lawful": {"as_class": "D::vehicle"}, "who": "v"}, {}))

    def test_composition_ids_follow_core(self):
        self.assertEqual(gate.rule_set_id({"op": "required_by", "conduct": "halt"}), "#requiredBy:halt")
        self.assertEqual(gate.rule_set_id({"op": "lawful", "scope": "every"}), "#lawful:every")
        self.assertEqual(gate.rule_set_id({"op": "lawful", "scope": "subject_class", "aggregate": "D::x"}), "#lawful:class:D::x")
        self.assertEqual(gate.rule_set_id({"op": "lawful", "scope": "as_class", "aggregate": "D::x"}), "#lawful:as:D::x")
        self.assertEqual(gate.rule_set_id({"op": "lawful"}), "#lawful:every")                  # the scope's default

    def test_an_operator_without_an_id_is_refused(self):
        for bad in ({"op": "lawful", "scope": "class"}, {"op": "lawful", "scope": "subject_class"},
                    {"op": "lawful", "scope": "purpose"}, {"op": "lawful", "scope": "as_class_purpose", "purpose": "device_instruction"},
                    {"op": "required_by"}, {"op": "obeys", "scope": "every"}, {}):
            with self.assertRaises(ValueError, msg=bad):
                gate.rule_set_id(bad)
        node = Node({"node_id": "N", "rule_sets": [{"span": "e1", "op": "lawful", "scope": "class", "who": "v"},
                                                   {"span": "e2", "op": "lawful", "scope": "every", "who": "v"}]})
        got = gate.rule_set_defects(node)
        self.assertEqual(len(got), 1, got)
        self.assertIn("scope 'class' is none of Core's", got[0])
        from harness.phases import label_check as lc
        with self.assertRaises(ValueError):
            lc.incomplete_sets({"L1": {"nodes": ["A", "B"]}}, {"A": {"rule_sets": [{"op": "lawful", "scope": "class"}]}})

    def test_a_case_needs_its_controls(self):
        node = Node({"node_id": "N", "segmentation": [{"id": "o1", "role": "obligation"}],
                     "cases": [{"span": "o1", "name": "c", "kind": "requires", "conduct": "halt"}]})
        rows = [["forbid", "0", "positive"], ["permit", "0", "met"], ["idle", "0", "outside"]]
        self.assertEqual(gate.case_defects(node, [], rows), [])
        self.assertEqual(gate.case_defects(node, [], rows[1:]), ["case 0 (`c`, span o1): no witness exercises its `positive` control"])
        node.raw["segmentation"].append({"id": "e1", "role": "exception"})
        self.assertEqual(gate.case_defects(node, [], rows), ["case 0 (`c`, span o1): no witness exercises its `exception` control"])
        self.assertEqual(gate.case_defects(node, [["0", "w at 0: too wide"]], rows + [["x", "0", "exception"]]), ["case 0: w at 0: too wide"])

    def test_case_keys_follow_core(self):
        self.assertEqual(gate.case_key({"name": "c", "kind": {"requires": "halt"}}), gate.record_case_key({"name": "c", "kind": "requires", "conduct": "halt"}))
        self.assertEqual(gate.case_key({"name": "c", "kind": "permits"}), gate.record_case_key({"name": "c", "kind": "permits"}))


#: Core's composition ids of every rule-set operator, printed beside the record spelling of each
#: scope constructor (an exhaustive match: a scope Core adds fails to elaborate here), and Core's own
#: round trip (`ofId`, then `idOf`) of each id given as an argument.
CORE_IDS = """import TrafficSpec.Core.Language.Formula
open TrafficSpec

def recordScope : RuleScope → String
  | .every => "every" | .subjectClass _ => "subject_class" | .asClass _ => "as_class"
  | .purpose _ => "purpose" | .asClassPurpose _ _ => "as_class_purpose"

def main (args : List String) : IO Unit := do
  for k in Conduct.all do IO.println s!"ID\t{RuleSet.requiredId k}\trequired_by\t{k.toString}\t"
  let a := "DEF-1::vehicle"
  let scopes : List RuleScope := [.every, .subjectClass a, .asClass a] ++ Purpose.all.flatMap fun p => [.purpose p, .asClassPurpose a p]
  for sc in scopes do
    let p := match sc with | .purpose p | .asClassPurpose _ p => p.toString | _ => ""
    IO.println s!"ID\t{RuleSet.lawfulId sc}\tlawful\t{recordScope sc}\t{p}"
  for id in args do IO.println s!"BACK\t{id}\t{((RuleSet.ofId id).bind RuleSet.idOf).getD "none"}"
"""


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class CoreIds(unittest.TestCase):

    def test_every_scope_maps_to_the_id_core_gives_it(self):
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "core_ids.lean"
            f.write_text(CORE_IDS, encoding="utf-8")
            code, out = lean.lean_run(paths.LIBRARY, f)
            rows = [l.split("\t") for l in out.splitlines() if l.startswith("ID\t")]
            self.assertEqual(code, 0, out[-2000:])
            self.assertEqual({r[3] for r in rows if r[2] == "lawful"}, {"every", "subject_class", "as_class", "purpose", "as_class_purpose"},
                             out[-2000:])
            mine = []
            for _, core_id, op, what, purpose in rows:
                entry = {"op": op, "conduct": what} if op == "required_by" else \
                        {"op": op, "scope": what} | ({"aggregate": "DEF-1::vehicle"} if what != "every" and what != "purpose" else {}) \
                        | ({"purpose": purpose} if purpose else {})
                mine.append(gate.rule_set_id(entry))
                self.assertEqual(mine[-1], core_id, entry)
            code, out = lean.lean_run(paths.LIBRARY, f, args=tuple(mine))
            back = {r[1]: r[2] for r in (l.split("\t") for l in out.splitlines() if l.startswith("BACK\t"))}
            self.assertEqual(back, {i: i for i in mine}, out[-2000:])


class LabelCheck(unittest.TestCase):

    def test_sets_are_incomplete_while_a_law_is_missing(self):
        from harness.phases import label_check as lc
        acc = {"A": {"rule_sets": [{"op": "required_by", "conduct": "halt"}, {"op": "lawful", "scope": "every"}]}, "B": {}}
        both = ["#lawful:every", "#requiredBy:halt"]
        self.assertEqual(lc.incomplete_sets({"L1": {"nodes": ["A"]}, "L2": {"nodes": ["B"]}}, acc), [])
        self.assertEqual(lc.incomplete_sets({"L1": {"nodes": ["A"]}, "L2": {"nodes": ["B", "C"]}}, acc), both)     # C is not accepted
        self.assertEqual(lc.incomplete_sets({"L1": {"nodes": ["A"]}, "L3": {"nodes": []}}, acc), both)             # a law with no node
        self.assertEqual(lc.incomplete_sets({"L1": {"nodes": ["A"]}, "L2": {"nodes": ["B"]}}, {**acc, "B": {"fenced": {"reason": "x"}}}), both)
        self.assertEqual(lc.incomplete_sets({"L2": {"nodes": ["B", "C"]}}, {"B": {}}), [])                         # no set is read


# --- the gate, on real Lean -------------------------------------------------------------------------
CALLER = "TEST_RULESET_9"
MEMBER = "TEST_DEMAND_9"
PED = '.existsUser "p" (.and (.atom "ru_pedestrian" [.var "p"] []) (.not (.same (.var "p") vV)))'


def rule_source(node: str, applicability: str, obligation: str, cases: str = "[]") -> str:
    return f'''/- A neutral rule for the rule-set gate check. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(node)}

def vV : Arg := .var "v"
def halted : Formula := .cmp (.measure "kin_speed" [vV]) .le (.lit Q.zero .metrePerSecond)

def rule : Rule :=
  {{ id := "{node}"
    laws := ["{node.replace('_', '-')}"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }} ]
    applicability := {applicability}
    obligation := {obligation}
    cases := {cases} }}

end {nodeid.rule_namespace(node)}
'''


def witness_source(node: str, scenarios: str, members: str = "[]") -> str:
    return f'''/- Lane 4 (x 60-100) enters junction 6 (x 100-120); a pedestrian, when present, stands at x 110. -/
import {nodeid.rule_module(node)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(node)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def lane : Structure := Build.lane 4 [(m 60, m 0), (m 100, m 0), (m 100, m 4), (m 60, m 4)] Build.east (enters := some 6)
def junction : Structure := Build.rect 6 .intersection (m 100) (m (-10)) (m 120) (m 14)
def car (x : Int) (sp : Q) : RoadUser := Build.user 1 [.motorVehicle] (m x, m 2) Build.east sp (m 2, m 1, m 1)
def walker : RoadUser := Build.user 2 [.pedestrian] (m 110, m 8) Build.north Q.zero (m 1, m 1, m 1)
def scene (us : List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _ t => Build.scene t (some 1) us [lane, junction] []

def vV : Arg := .var "v"
def halted : Formula := .cmp (.measure "kin_speed" [vV]) .le (.lit Q.zero .metrePerSecond)
/-- The rule-set operators' rules in these witnesses: a halt is required while a pedestrian is about. -/
def waitForWalker : Rule :=
  {{ id := "fixture/wait", laws := [], binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }} ]
    applicability := {PED}, obligation := halted
    cases := [ {{ name := "wait", kind := .requires .halt, shown := halted }} ] }}

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{node}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("v", 1)], expected := expected, setMembers := {members} }}

def scenarios : List Scenario := {scenarios}

end {nodeid.witness_namespace(node)}
'''


IN_JUNCTION = '.existsRegion (.lit "intersection") "j" (.atom "rel_occupies" [vV, .var "j"] [])'
CALLER_RULE = rule_source(CALLER, IN_JUNCTION, '.or (.not halted) (.requiredBy .halt "v")')
CALLER_WITNESS = witness_source(CALLER, '''
  [ witness "forbid" (scene [car 110 Q.zero]) .violated
  , witness "permit" (scene [car 110 (m 5)]) .compliant
  , witness "idle" (scene [car 70 Q.zero]) .notApplicable
  , witness "blind" (scene [car 110 Q.zero]) (.unknown []) ["kin.speed"]
  , witness "branch_1" (scene [car 110 Q.zero, walker]) .compliant ]''', "[waitForWalker]")
CALLER_RECORD = {
    "node_id": CALLER, "law_refs": ["TEST-RULESET-9"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
    "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "t1", "role": "trigger", "text": "within the junction"},
                     {"id": "o1", "role": "obligation", "text": "shall not halt"},
                     {"id": "e1", "role": "exception", "text": "except where required"}],
    "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "t1", "atoms": ["st.intersection", "rel.occupies"]},
                 {"span": "o1", "atoms": ["kin.speed"]}],
    "rule_sets": [{"span": "e1", "op": "required_by", "conduct": "halt", "who": "v"}],
    "params": [], "applicability": "a", "obligation": "o",
    "scenarios": [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
                  {"name": "idle", "expected": "not_applicable"}, {"name": "blind", "expected": "unknown", "masked": ["kin.speed"]},
                  {"name": "branch_1", "expected": "compliant", "narrative": "the halt is one a rule of the witness's set requires"}]}

CASE = '[ { name := "wait_for_walker", kind := .requires .halt, shown := halted } ]'
MEMBER_RULE = rule_source(MEMBER, PED, "halted", CASE)
MEMBER_WITNESS = witness_source(MEMBER, '''
  [ witness "forbid" (scene [car 80 (m 5), walker]) .violated
  , witness "permit" (scene [car 80 Q.zero, walker]) .compliant
  , witness "idle" (scene [car 80 (m 5)]) .notApplicable
  , witness "blind" (scene [car 80 Q.zero, walker]) (.unknown []) ["kin.speed"]
  , witness "stop_wait_for_walker_halt" (scene [car 80 Q.zero, walker]) .compliant
  , witness "stop_wait_for_walker_drive" (scene [car 80 (m 5), walker]) .violated
  , witness "stop_wait_for_walker_creep" (scene [car 80 (m 1), walker]) .violated ]''')
MEMBER_RECORD = {
    "node_id": MEMBER, "law_refs": ["TEST-DEMAND-9"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
    "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "c1", "role": "condition", "text": "while a person stands by"},
                     {"id": "o1", "role": "obligation", "text": "shall stay at rest"}],
    "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "c1", "atoms": ["ru.pedestrian"]}, {"span": "o1", "atoms": ["kin.speed"]}],
    "cases": [{"span": "o1", "name": "wait_for_walker", "kind": "requires", "conduct": "halt", "situation": "a person stands by"}],
    "params": [], "applicability": "a", "obligation": "o",
    "scenarios": [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
                  {"name": "idle", "expected": "not_applicable"}, {"name": "blind", "expected": "unknown", "masked": ["kin.speed"]},
                  {"name": "stop_wait_for_walker_halt", "expected": "compliant"}, {"name": "stop_wait_for_walker_drive", "expected": "violated"},
                  {"name": "stop_wait_for_walker_creep", "expected": "violated"}]}


def run_gate(node: str, rule: str, witness: str, rec: dict) -> gate.Verdict:
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.rule_path(node), nodeid.witness_path(node)]
        own = {f"import {nodeid.rule_module(node)}", f"import {nodeid.witness_module(node)}"}
        for rel, src in zip(files, [rule, witness]):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", Ran(files, own)):
            return gate.run_gate(Node(copy.deepcopy(rec)), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted_concepts={})


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class Gate(unittest.TestCase):

    def test_a_caller_gated_on_its_own_members(self):
        v = run_gate(CALLER, CALLER_RULE, CALLER_WITNESS, CALLER_RECORD)
        self.assertEqual(v.verdict, "OK", v.details)

    def test_an_operator_the_record_does_not_declare(self):
        rec = copy.deepcopy(CALLER_RECORD)
        rec["rule_sets"] = []
        rec["elements"].append({"span": "e1", "atoms": ["kin.speed"]})
        v = run_gate(CALLER, CALLER_RULE, CALLER_WITNESS, rec)
        self.assertEqual(v.verdict, "DECLARATION_MISMATCH", v.details)
        self.assertTrue(any("rule-set operators ['#requiredBy:halt'] ≠ the node's []" in d for d in v.details), v.details)

    def test_an_operator_without_an_id_is_refused(self):
        rec = copy.deepcopy(CALLER_RECORD)
        rec["rule_sets"].append({"span": "e1", "op": "lawful", "scope": "class", "who": "v"})
        v = run_gate(CALLER, CALLER_RULE, CALLER_WITNESS, rec)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("scope 'class' is none of Core's" in d for d in v.details), v.details)

    def test_abstractions_are_held_to_the_record(self):
        abs_id = "equipment_specification_of_observed_use"
        rec = copy.deepcopy(MEMBER_RECORD)
        rec["narrowings"] = [{"span": "o1", "kind": "abstraction", "abstraction": abs_id, "why": "w"}]
        rule = MEMBER_RULE.replace("    cases := ", f'    abstractions := ["{abs_id}"]\n    cases := ', 1)
        v = run_gate(MEMBER, rule, MEMBER_WITNESS, rec)
        self.assertEqual(v.verdict, "OK", v.details)
        v = run_gate(MEMBER, MEMBER_RULE, MEMBER_WITNESS, rec)
        self.assertEqual(v.verdict, "DECLARATION_MISMATCH", v.details)
        self.assertTrue(any(f"abstractions [] ≠ the record's ['{abs_id}']" in d for d in v.details), v.details)
        v = run_gate(MEMBER, rule, MEMBER_WITNESS, MEMBER_RECORD)
        self.assertEqual(v.verdict, "DECLARATION_MISMATCH", v.details)

    def test_without_members_the_witness_that_needs_them_fails(self):
        v = run_gate(CALLER, CALLER_RULE, CALLER_WITNESS.replace("setMembers := [waitForWalker]", "setMembers := []"), CALLER_RECORD)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)

    def test_a_member_with_its_case_controlled(self):
        v = run_gate(MEMBER, MEMBER_RULE, MEMBER_WITNESS, MEMBER_RECORD)
        self.assertEqual(v.verdict, "OK", v.details)

    def test_a_case_that_never_holds_exercises_no_control(self):
        rule = MEMBER_RULE.replace("shown := halted }", "shown := halted, when := .ff }")
        v = run_gate(MEMBER, rule, MEMBER_WITNESS, MEMBER_RECORD)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("case 0 (`wait_for_walker`, span o1): no witness exercises its `positive` control" in d for d in v.details), v.details)

    def test_a_case_wider_than_the_duty(self):
        # the duty has an exception (an emergency vehicle need not stay at rest) the case ignores
        exempt = '(.atom "ru_emergency_vehicle" [vV] [])'
        rule = rule_source(MEMBER, PED, f".or halted {exempt}", CASE)
        witness = MEMBER_WITNESS.replace('  , witness "blind"', BRANCH)
        rec = copy.deepcopy(MEMBER_RECORD)
        rec["segmentation"].append({"id": "e1", "role": "exception", "text": "unless it is an emergency vehicle"})
        rec["elements"].append({"span": "e1", "atoms": ["ru.emergency_vehicle"]})
        rec["scenarios"].append({"name": "branch_1", "expected": "compliant", "narrative": "an emergency vehicle moves past the person"})
        v = run_gate(MEMBER, rule, witness, rec)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("holds and the conduct is not shown, but the rule is compliant: the case reaches beyond the duty" in d
                            for d in v.details), v.details)
        narrow = rule.replace("shown := halted }", f"shown := halted, when := .not {exempt} }}")
        v = run_gate(MEMBER, narrow, witness, rec)
        self.assertEqual(v.verdict, "OK", v.details)                       # the case follows the exception

    def test_a_purpose_held_to_its_pair(self):
        rule = MEMBER_RULE.replace("    cases := [", "    purposes := [.deviceInstruction]\n    cases := [")
        rec = {**copy.deepcopy(MEMBER_RECORD), "purposes": [{"purpose": "device_instruction", "span": "o1", "why": "w"}]}
        v = run_gate(MEMBER, rule, MEMBER_WITNESS, rec)              # no pair written
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("purpose device_instruction: the witnesses purpose_device_instruction_on and purpose_device_instruction_off "
                            "are not both written" in d for d in v.details), v.details)
        # a duty to stay at rest is no standing or parking constraint: at rest it is compliant
        rule = MEMBER_RULE.replace("    cases := [", "    purposes := [.standingOrParking]\n    cases := [")
        witness = MEMBER_WITNESS.replace('  , witness "stop_wait_for_walker_creep"',
                                         '  , witness "purpose_standing_or_parking_halt" (scene [car 80 Q.zero, walker]) .compliant\n'
                                         '  , witness "purpose_standing_or_parking_move" (scene [car 80 (m 5), walker]) .violated\n'
                                         '  , witness "stop_wait_for_walker_creep"')
        rec = {**copy.deepcopy(MEMBER_RECORD), "purposes": [{"purpose": "standing_or_parking", "span": "o1", "why": "w"}]}
        rec["scenarios"] += [{"name": "purpose_standing_or_parking_halt", "expected": "compliant"},
                             {"name": "purpose_standing_or_parking_move", "expected": "violated"}]
        v = run_gate(MEMBER, rule, witness, rec)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("the first witness is compliant, not violated: the duty does not turn on standing_or_parking" in d
                            for d in v.details), v.details)
        rec.pop("purposes")
        v = run_gate(MEMBER, MEMBER_RULE, MEMBER_WITNESS, {**rec, "purposes": [{"purpose": "standing_or_parking", "span": "o1", "why": "w"}]})
        self.assertEqual(v.verdict, "DECLARATION_MISMATCH", v.details)

    def test_a_case_met_by_creeping_requires_no_stop(self):
        rule = rule_source(MEMBER, PED, '(.cmp (.measure "kin_speed" [vV]) .le (.lit (Units.metres 2) .metrePerSecond))', CASE)
        rec = copy.deepcopy(MEMBER_RECORD)
        rec["literals"] = [{"span": "o1", "text": "shall stay at rest", "value": 2, "unit": "m/s"}]
        for x in rec["scenarios"]:
            if x["name"] == "stop_wait_for_walker_creep":
                x["expected"] = "compliant"
        witness = MEMBER_WITNESS.replace('witness "stop_wait_for_walker_creep" (scene [car 80 (m 1), walker]) .violated',
                                         'witness "stop_wait_for_walker_creep" (scene [car 80 (m 1), walker]) .compliant')
        v = run_gate(MEMBER, rule, witness, rec)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("creeping in the same situation is compliant, not violated: the duty is met short of a stop" in d
                            for d in v.details), v.details)

    def test_a_case_the_record_does_not_declare(self):
        rec = copy.deepcopy(MEMBER_RECORD)
        rec.pop("cases")
        v = run_gate(MEMBER, MEMBER_RULE, MEMBER_WITNESS, rec)
        self.assertEqual(v.verdict, "DECLARATION_MISMATCH", v.details)


if __name__ == "__main__":
    unittest.main()
