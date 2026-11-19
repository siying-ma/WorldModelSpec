"""A case on a span an `unless` composition scopes inherits the suspension: where the composed rule
applies, the case does not hold. The gate holds it twice. Statically, the case's `when` reads the
composed rule with the record's map, variable by variable, negated (`gate.composition_read_defects`).
Behaviourally, on the witness `unless_<case>` the composed rule (the library's, with the record's
map) must apply at some observation, else the suspension is not verified; at those observations the
case does not hold with the library's rules and holds on the same trace with the composed rule's
applicability removed (`unlessControls` in the gate harness). The plan owes the witness
(`validate_a`). The gate cases run on real Lean; they are skipped where the toolchain or the built
Core is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate, validate_a
from harness.model import nodeid
from harness.model.blueprint import Node, unless_case_checks
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests.test_gate_phases import Ran, _library

NODE, TARGET = "TEST_SUSPEND_9", "TEST_YIELD_9"
IN_JUNCTION = '(.existsRegion (.lit "intersection") "j" (.atom "rel_occupies" [vV, .var "j"] []))'
PED = '(.existsUser "p" (.and (.atom "ru_pedestrian" [.var "p"] []) (.not (.same (.var "p") vV))))'
SUSPENDED = f'(.not (.ruleApplies "{TARGET}" [("v", "v")]))'
CORRECT = SUSPENDED
FLIPPED = f'(.ruleApplies "{TARGET}" [("v", "v")])'
WRONG_BINDER = f'(.not (.ruleApplies "{TARGET}" [("v", "w")]))'
OR_BRANCH = f'(.or {IN_JUNCTION} {SUSPENDED})'

TARGET_RULE = f'''/- The composed rule: a vehicle in the junction while a pedestrian is about stays at rest. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(TARGET)}

def vV : Arg := .var "v"

def rule : Rule :=
  {{ id := "{TARGET}"
    laws := ["{TARGET.replace('_', '-')}"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }} ]
    applicability := .and {PED} {IN_JUNCTION}
    obligation := .cmp (.measure "kin_speed" [vV]) .le (.lit Q.zero .metrePerSecond) }}

end {nodeid.rule_namespace(TARGET)}
'''


def node_rule(when: str) -> str:
    return f'''/- A permission whose condition an `unless` suspends. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(NODE)}

def vV : Arg := .var "v"
def moving : Formula := .cmp (.measure "kin_speed" [vV]) .gt (.lit Q.zero .metrePerSecond)

def rule : Rule :=
  {{ id := "{NODE}"
    laws := ["{NODE.replace('_', '-')}"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }},
                 {{ name := "w", cls := .atom "ru_motor_vehicle" [.var "w"] [] }} ]
    applicability := .and {IN_JUNCTION} (.not (.same vV (.var "w")))
    obligation := .tt
    permission := true
    cases := [ {{ name := "pass", kind := .permits, shown := moving, when := {when} }} ] }}

end {nodeid.rule_namespace(NODE)}
'''


def node_witness(scenarios: str) -> str:
    return f'''/- Lane 4 (x 60-100) enters junction 6 (x 100-120); vehicle 3 waits on the lane; a pedestrian, when
   present, stands at x 110. -/
import {nodeid.rule_module(NODE)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(NODE)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def lane : Structure := Build.lane 4 [(m 60, m 0), (m 100, m 0), (m 100, m 4), (m 60, m 4)] Build.east (enters := some 6)
def junction : Structure := Build.rect 6 .intersection (m 100) (m (-10)) (m 120) (m 14)
def car (x : Int) (sp : Q) : RoadUser := Build.user 1 [.motorVehicle] (m x, m 2) Build.east sp (m 2, m 1, m 1)
def other : RoadUser := Build.user 3 [.motorVehicle] (m 70, m 2) Build.east Q.zero (m 2, m 1, m 1)
def walker : RoadUser := Build.user 2 [.pedestrian] (m 110, m 8) Build.north Q.zero (m 1, m 1, m 1)
def scene (us : List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _ t => Build.scene t (some 1) us [lane, junction] []

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{NODE}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("v", 1), ("w", 3)], expected := expected }}

def scenarios : List Scenario := {scenarios}

end {nodeid.witness_namespace(NODE)}
'''


BASE = '''
  [ witness "permit" (scene [car 110 (m 5), other]) .compliant
  , witness "idle" (scene [car 70 (m 5), other]) .notApplicable
  , witness "blind" (scene [car 110 (m 5), other]) (.unknown []) ["rel.occupies"]'''
WITH_PEDESTRIAN = '\n  , witness "unless_pass" (scene [car 110 (m 5), other, walker]) .compliant'
WITHOUT_PEDESTRIAN = '\n  , witness "unless_pass" (scene [car 110 (m 5), other]) .compliant'
WITNESS = node_witness(BASE + WITH_PEDESTRIAN + " ]")

RECORD = {
    "node_id": NODE, "law_refs": [NODE.replace("_", "-")], "permission": True,
    "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
    "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}, {"name": "w", "class_elements": ["ru.motor_vehicle"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "t1", "role": "condition", "text": "within the junction"},
                     {"id": "p1", "role": "permission", "text": "may move ahead of another vehicle"},
                     {"id": "r1", "role": "reference", "text": "except as otherwise provided"}],
    "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "t1", "atoms": ["st.intersection", "rel.occupies"]},
                 {"span": "p1", "atoms": ["kin.speed"]}],
    "compositions": [{"span": "r1", "rule": TARGET, "map": {"v": "v"}, "as": "unless", "scopes": "t1"}],
    "cases": [{"span": "t1", "name": "pass", "kind": "permits", "situation": "the vehicle is within the junction"}],
    "params": [], "applicability": "a", "obligation": "o",
    "scenarios": [{"name": "permit", "expected": "compliant"}, {"name": "idle", "expected": "not_applicable"},
                  {"name": "blind", "expected": "unknown", "masked": ["rel.occupies"]},
                  {"name": "unless_pass", "expected": "compliant", "narrative": "a pedestrian is about, so the composed rule applies"}]}


def run_gate(rule: str, witness: str = WITNESS, rec: dict = RECORD) -> gate.Verdict:
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        (work / "registry.json").write_text(json.dumps({"nodes": [TARGET, NODE], "concepts": []}))
        files = [nodeid.rule_path(TARGET), nodeid.rule_path(NODE), nodeid.witness_path(NODE)]
        own = {f"import {nodeid.rule_module(TARGET)}", f"import {nodeid.rule_module(NODE)}", f"import {nodeid.witness_module(NODE)}"}
        for rel, src in zip(files, [TARGET_RULE, rule, witness]):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", Ran(files, own)):
            return gate.run_gate(Node(copy.deepcopy(rec)), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted_concepts={})


def unless_lines(v: gate.Verdict) -> list[str]:
    return [d for d in v.details if d.startswith("unless pass:")]


class Plan(unittest.TestCase):
    def test_the_record_owes_the_witness(self):
        self.assertEqual([u["witness"] for u in unless_case_checks(RECORD)], ["unless_pass"])
        rec = copy.deepcopy(RECORD)
        rec["scenarios"] = [s for s in rec["scenarios"] if s["name"] != "unless_pass"]
        errs = validate_a.check_rule_sets(Node(rec), {"halt"})
        self.assertTrue(any("scenario `unless_pass` missing" in e for e in errs), errs)
        self.assertFalse(any("unless_pass" in e for e in validate_a.check_rule_sets(Node(copy.deepcopy(RECORD)), {"halt"})))

    def test_several_compositions_scoping_one_span_number_their_witnesses(self):
        rec = copy.deepcopy(RECORD)
        rec["compositions"].append({"span": "r1", "rule": "TEST_OTHER_9", "map": {"v": "v"}, "as": "unless", "scopes": "t1", "case": "c"})
        got = unless_case_checks(rec)
        self.assertEqual([(u["witness"], u["rule"], u["rule_case"]) for u in got],
                         [("unless_pass_1", TARGET, None), ("unless_pass_2", "TEST_OTHER_9", "c")])


class StaticReads(unittest.TestCase):
    """The rendered `when` against the record's map, on the rule's JSON alone."""

    def when(self, formula: dict) -> list[str]:
        return gate.composition_read_defects(Node(RECORD), {"cases": [{"name": "pass", "when": formula}]})

    def test_the_record_map_passes(self):
        self.assertEqual(self.when({"not": {"rule_applies": TARGET, "map": {"v": "v"}}}), [])

    def test_another_binding_is_refused(self):
        got = self.when({"not": {"rule_applies": TARGET, "map": {"v": "w"}}})
        self.assertTrue(any("reads rule_applies `TEST_YIELD_9` map {'v': 'w'}" in e for e in got), got)
        self.assertTrue(any("does not read `TEST_YIELD_9` as unless: rule_applies `TEST_YIELD_9` map {'v': 'v'}" in e for e in got), got)

    def test_no_read_is_refused(self):
        self.assertTrue(self.when({"atom": "kin_speed"}))

    def test_a_named_case_is_read_as_that_case(self):
        rec = copy.deepcopy(RECORD)
        rec["compositions"][0]["case"] = "yield"
        def when(f):
            return gate.composition_read_defects(Node(rec), {"cases": [{"name": "pass", "when": f}]})
        self.assertEqual(when({"not": {"rule_case": TARGET, "case": "yield", "map": {"v": "v"}}}), [])
        self.assertTrue(when({"not": {"rule_applies": TARGET, "map": {"v": "v"}}}))


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class Gate(unittest.TestCase):

    def test_the_suspension_in_the_when_passes(self):
        v = run_gate(node_rule(CORRECT))
        self.assertEqual(v.verdict, "OK", v.details)

    def test_flipped_polarity_fails_statically_and_on_the_witness(self):
        v = run_gate(node_rule(FLIPPED))
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("case `pass` when reads rule_applies `TEST_YIELD_9` map {'v': 'v'}, where its holding can only bring" in d
                            for d in v.details), v.details)
        with mock.patch.object(gate, "composition_read_defects", lambda *a: []):
            v = run_gate(node_rule(FLIPPED))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("the case holds, or is unknown, where `TEST_YIELD_9` applies" in d for d in unless_lines(v)), v.details)

    def test_the_wrong_binder_fails_statically_and_on_the_witness(self):
        v = run_gate(node_rule(WRONG_BINDER))
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("reads rule_applies `TEST_YIELD_9` map {'w': 'v'}" in d or "map {'v': 'w'}" in d for d in v.details), v.details)
        with mock.patch.object(gate, "composition_read_defects", lambda *a: []):
            v = run_gate(node_rule(WRONG_BINDER))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("the case holds, or is unknown, where `TEST_YIELD_9` applies" in d for d in unless_lines(v)), v.details)

    def test_the_rule_in_an_or_branch_fails(self):
        v = run_gate(node_rule(OR_BRANCH))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("the case holds, or is unknown, where `TEST_YIELD_9` applies" in d for d in unless_lines(v)), v.details)

    def test_a_missing_witness_is_not_verified(self):
        rec = copy.deepcopy(RECORD)
        rec["scenarios"] = [s for s in rec["scenarios"] if s["name"] != "unless_pass"]
        v = run_gate(node_rule(CORRECT), node_witness(BASE + " ]"), rec)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("not verified: the witness unless_pass" in d for d in unless_lines(v)), v.details)

    def test_a_witness_where_the_rule_does_not_apply_is_not_verified(self):
        v = run_gate(node_rule(CORRECT), node_witness(BASE + WITHOUT_PEDESTRIAN + " ]"))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("not verified: `TEST_YIELD_9` applies at no observation of unless_pass" in d for d in unless_lines(v)), v.details)


if __name__ == "__main__":
    unittest.main()
