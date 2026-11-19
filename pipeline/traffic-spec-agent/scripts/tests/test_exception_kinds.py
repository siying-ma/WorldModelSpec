"""Each `exception` span of a node record states what the rule says where the exception occurs
(`exception_kinds`): `meets_duty`, acting that way meets the requirement, written in the
obligation beside the duty, so the verdict there is compliant; `lifts_duty`, the duty does not
apply then, written in the applicability, negated, so the verdict is not applicable. The planner
states the kind; there is no default (`validate_a.check_exception_kinds`). A case another rule reads
on a `lifts_duty` exception would hold where the rule is not applicable, which no case of Core
expresses: the harness files an operator gap for it and the record is not coded
(`validate_a.lifted_case_gaps`). The skeleton lists each exception span where its kind is written.
The gate cases run on real Lean: a crossing prohibition whose exception (a marked crosswalk)
meets the duty, its `permits` case and a caller reading that case, and a prohibition whose
exception (within an intersection) lifts it; they are skipped where the toolchain or the built Core
is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate, validate_a
from harness.lean import skeleton
from harness.model import nodeid
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests import test_rule_sets as RS
from scripts.tests.test_gate_phases import Ran, _library

CROSS, YIELD, LIFT = "TEST_CROSS_9", "TEST_YIELD_9", "TEST_LIFT_9"
IN_LANE = '(.existsRegion (.lit "lane") "l" (.atom "rel_occupies" [vS, .var "l"] []))'
IN_JUNCTION = '(.existsRegion (.lit "intersection") "j" (.atom "rel_occupies" [vS, .var "j"] []))'
IN_MARKED = '(.existsRegion (.lit "crosswalk") "w" (.and (.atom "rel_occupies" [vS, .var "w"] []) (.atom "st_crosswalk_marked" [.var "w"] [])))'
MOVING = '(.cmp (.measure "kin_speed" [vS]) .gt (.lit Q.zero .metrePerSecond))'


def rule(node: str, cls: str, app: str, obl: str, cases: str = "[]") -> str:
    return f'''/- A fixture rule for the exception kinds. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(node)}

def vS : Arg := .var "subject"

def rule : Rule :=
  {{ id := "{node}"
    laws := ["{node.replace('_', '-')}"]
    binders := [ {{ name := "subject", cls := .atom "{cls}" [vS] [] }} ]
    applicability := {app}
    obligation := {obl}
    cases := {cases} }}

end {nodeid.rule_namespace(node)}
'''


def witness(node: str, who: int, scenarios: str) -> str:
    return f'''/- Lane 4 (x 60-100) enters junction 6 (x 100-120); crosswalk 7 (x 80-84) across the lane is marked,
   crosswalk 8 (x 66-70) is not. The pedestrian is track 1, walking north; the vehicle is track 3. -/
import {nodeid.rule_module(node)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(node)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def lane : Structure := Build.lane 4 [(m 60, m 0), (m 100, m 0), (m 100, m 4), (m 60, m 4)] Build.east (enters := some 6)
def junction : Structure := Build.rect 6 .intersection (m 100) (m (-10)) (m 120) (m 14)
def marked : Structure := {{ Build.rect 7 .crosswalk (m 80) (m 0) (m 84) (m 4) with marked := some true }}
def unmarked : Structure := {{ Build.rect 8 .crosswalk (m 66) (m 0) (m 70) (m 4) with marked := some false }}
def ped (x y : Int) (sp : Q) : RoadUser := Build.user 1 [.pedestrian] (m x, m y) Build.north sp (m 1, m 1, m 1)
def car (sp : Q) : RoadUser := Build.user 3 [.motorVehicle] (m 62, m 2) Build.east sp (m 1, m 1, m 1)
def scene (us : List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _ t => Build.scene t (some 1) us [lane, junction, marked, unmarked] []

def w (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{node}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("subject", {who})], expected := expected }}

def scenarios : List Scenario := {scenarios}

end {nodeid.witness_namespace(node)}
'''


SCEN = [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
        {"name": "idle", "expected": "not_applicable"}, {"name": "blind", "expected": "unknown", "masked": ["kin.speed"]}]

# A crossing prohibition whose exception, a marked crosswalk, meets the duty: crossing there complies.
CROSS_CASE = f'[ {{ name := "in_marked_crosswalk", kind := .permits, shown := {MOVING}, when := {IN_MARKED} }} ]'
CROSS_RULE = rule(CROSS, "ru_pedestrian", f".and {IN_LANE} {MOVING}", f".or (.not {MOVING}) {IN_MARKED}", CROSS_CASE)
CROSS_WITNESS = witness(CROSS, 1, '''
  [ w "forbid" (scene [ped 90 2 (m 1)]) .violated
  , w "permit" (scene [ped 82 2 (m 1)]) .compliant
  , w "idle" (scene [ped 90 2 Q.zero]) .notApplicable
  , w "blind" (scene [ped 90 2 (m 1)]) (.unknown []) ["kin.speed"]
  , w "branch_1" (scene [ped 68 2 (m 1)]) .violated ]''')
CROSS_RECORD = {
    "node_id": CROSS, "law_refs": ["TEST-CROSS-9"], "subject": {"binder": "subject", "class_elements": ["ru.pedestrian"]},
    "binders": [{"name": "subject", "class_elements": ["ru.pedestrian"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "a pedestrian"}, {"id": "t1", "role": "trigger", "text": "upon a roadway"},
                     {"id": "o1", "role": "obligation", "text": "shall not cross"},
                     {"id": "e1", "role": "exception", "text": "except in a marked crosswalk"}],
    "elements": [{"span": "s1", "atoms": ["ru.pedestrian"]}, {"span": "t1", "atoms": ["st.lane", "rel.occupies"]},
                 {"span": "o1", "atoms": ["kin.speed"]}, {"span": "e1", "atoms": ["st.crosswalk"]}],
    "exception_kinds": [{"span": "e1", "kind": "meets_duty"}],
    "cases": [{"span": "e1", "name": "in_marked_crosswalk", "kind": "permits", "situation": "the pedestrian crosses in a marked crosswalk"}],
    "params": [], "applicability": "a", "obligation": "o",
    "scenarios": SCEN + [{"name": "branch_1", "expected": "violated", "narrative": "crossing in an unmarked crosswalk"}]}

# A driver yields while a pedestrian is in a crosswalk, except in the case the crossing rule permits.
PED_IN_CROSSWALK = ('(.and (.atom "ru_pedestrian" [.var "p"] []) (.and (.existsRegion (.lit "crosswalk") "w" (.atom "rel_occupies" [.var "p", .var "w"] []))'
                    ' (.existsRegion (.lit "lane") "l" (.and (.atom "rel_occupies" [vS, .var "l"] []) (.atom "rel_occupies" [.var "p", .var "l"] [])))))')
YIELD_RULE = rule(YIELD, "ru_motor_vehicle",
                  f'(.existsUser "p" (.and {PED_IN_CROSSWALK} (.not (.ruleCase "{CROSS}" "in_marked_crosswalk" [("subject", "p")]))))',
                  f"(.not {MOVING})")
YIELD_WITNESS = witness(YIELD, 3, '''
  [ w "forbid" (scene [ped 68 2 (m 1), car (m 5)]) .violated
  , w "permit" (scene [ped 68 2 (m 1), car Q.zero]) .compliant
  , w "idle" (scene [ped 90 2 (m 1), car (m 5)]) .notApplicable
  , w "blind" (scene [ped 68 2 (m 1), car (m 5)]) (.unknown []) ["kin.speed"]
  , w "branch_1" (scene [ped 82 2 (m 1), car (m 5)]) .notApplicable ]''')
YIELD_RECORD = {
    "node_id": YIELD, "law_refs": ["TEST-YIELD-9"], "subject": {"binder": "subject", "class_elements": ["ru.motor_vehicle"]},
    "binders": [{"name": "subject", "class_elements": ["ru.motor_vehicle"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "the driver"}, {"id": "c1", "role": "condition", "text": "while a pedestrian is in a crosswalk on its lane"},
                     {"id": "o1", "role": "obligation", "text": "shall yield"},
                     {"id": "r1", "role": "reference", "text": "except as provided in the crossing rule"}],
    "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "c1", "atoms": ["ru.pedestrian", "st.crosswalk", "st.lane", "rel.occupies"]},
                 {"span": "o1", "atoms": ["kin.speed"]}],
    "compositions": [{"span": "r1", "rule": CROSS, "map": {"subject": "p"}, "as": "exception", "case": "in_marked_crosswalk"}],
    "params": [], "applicability": "a", "obligation": "o",
    "scenarios": SCEN + [{"name": "branch_1", "expected": "not_applicable", "narrative": "the pedestrian crosses in the marked crosswalk"}]}

# A crossing prohibition whose exception, within an intersection, lifts the duty there.
LIFT_RULE = rule(LIFT, "ru_pedestrian", f".and (.or {IN_LANE} {IN_JUNCTION}) (.not {IN_JUNCTION})", f"(.not {MOVING})")
LIFT_WITNESS = witness(LIFT, 1, '''
  [ w "forbid" (scene [ped 90 2 (m 1)]) .violated
  , w "permit" (scene [ped 90 2 Q.zero]) .compliant
  , w "idle" (scene [ped 90 30 (m 1)]) .notApplicable
  , w "blind" (scene [ped 90 2 (m 1)]) (.unknown []) ["kin.speed"]
  , w "branch_1" (scene [ped 110 2 (m 1)]) .notApplicable ]''')
LIFT_RECORD = {
    "node_id": LIFT, "law_refs": ["TEST-LIFT-9"], "subject": {"binder": "subject", "class_elements": ["ru.pedestrian"]},
    "binders": [{"name": "subject", "class_elements": ["ru.pedestrian"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "a pedestrian"}, {"id": "t1", "role": "trigger", "text": "upon a roadway"},
                     {"id": "o1", "role": "obligation", "text": "shall not cross"},
                     {"id": "e1", "role": "exception", "text": "this does not apply within an intersection"}],
    "elements": [{"span": "s1", "atoms": ["ru.pedestrian"]}, {"span": "t1", "atoms": ["st.lane", "rel.occupies"]},
                 {"span": "o1", "atoms": ["kin.speed"]}, {"span": "e1", "atoms": ["st.intersection"]}],
    "exception_kinds": [{"span": "e1", "kind": "lifts_duty"}],
    "params": [], "applicability": "a", "obligation": "o",
    "scenarios": SCEN + [{"name": "branch_1", "expected": "not_applicable", "narrative": "the pedestrian crosses within the intersection"}]}


def run_gate(node: str, files: dict[str, str], rec: dict, registry: list[str]) -> tuple[gate.Verdict, list[str]]:
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        (work / "registry.json").write_text(json.dumps({"nodes": registry, "concepts": []}))
        for rel, src in files.items():
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        own = {f"import {nodeid.rule_module(n)}" for n in registry} | {f"import {nodeid.witness_module(node)}"}
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", Ran(list(files), own)):
            v = gate.run_gate(Node(copy.deepcopy(rec)), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted_concepts={})
            out = (work / "gate_harness.out").read_text() if (work / "gate_harness.out").exists() else ""
            return v, [l for l in out.splitlines() if l.startswith(("SCEN\t", "CASE\t"))]


def scen(rows: list[str]) -> dict[str, str]:
    """Each witness's verdict as the gate computed it."""
    return {r.split("\t")[1]: r.split("\t")[3] for r in rows if r.startswith("SCEN\t")}


class Validator(unittest.TestCase):
    """A record whose exception span carries a `permits` case, on the rule-set fixture's text."""

    def record(self, kind: str | None) -> dict:
        r = RS.record(rule_sets=[], cases=[{"span": "e1", "name": "may_go", "kind": "permits", "situation": "the crossing is clear"}])
        r["elements"].append({"span": "e1", "atoms": ["kin.speed"]})
        r.pop("exception_kinds", None)
        if kind is not None:
            r["exception_kinds"] = [{"span": "e1", "kind": kind}]
        return r

    def test_an_exception_without_its_kind_goes_back_to_the_planner(self):
        out = RS.validate(self.record(None))
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any("exception span e1 states no kind in `exception_kinds`" in r for r in out.reasons), out.reasons)

    def test_a_kind_on_another_span_or_twice_or_unknown_is_refused(self):
        n = Node(self.record("meets_duty"))
        n.raw["exception_kinds"] += [{"span": "o1", "kind": "meets_duty"}, {"span": "e1", "kind": "lifts_duty"}]
        got = validate_a.check_exception_kinds(n)
        self.assertTrue(any("names span 'o1', which is no exception span" in e for e in got), got)
        self.assertTrue(any("states the kind of span e1 more than once" in e for e in got), got)
        out = RS.validate({**self.record(None), "exception_kinds": [{"span": "e1", "kind": "maybe"}]})
        self.assertEqual(out.kind, validate_a.RETURN, out.reasons)
        self.assertTrue(any("exception_kinds[0].kind" in r for r in out.reasons), out.reasons)

    def test_a_permits_case_on_an_exception_that_meets_the_duty_is_accepted(self):
        out = RS.validate(self.record("meets_duty"))
        self.assertEqual((out.kind, out.reasons, out.filed), (validate_a.ACCEPT, [], []))

    def test_a_permits_case_on_an_exception_that_lifts_the_duty_is_filed_for_the_operator(self):
        out = RS.validate(self.record("lifts_duty"))
        self.assertEqual((out.kind, out.reasons), (validate_a.ACCEPT, []))           # not returned: the planner cannot remove it
        self.assertEqual([(g["span"], g["kind"]) for g in out.filed], [("e1", "operator")])   # filed: the record is not coded
        self.assertIn("unimplemented requirement for the operator", out.filed[0]["proposal"])
        self.assertIn("option 2, not implemented", out.filed[0]["proposal"])
        self.assertTrue(any("unimplemented requirement" in x for x in out.notes), out.notes)

    def test_a_caller_reading_a_case_on_an_exception_that_lifts_the_duty_is_filed(self):
        target = Node({**copy.deepcopy(LIFT_RECORD), "cases": [{"span": "e1", "name": "inside", "kind": "permits", "situation": "s"}]})
        caller = Node({**copy.deepcopy(YIELD_RECORD), "compositions": [
            {"span": "r1", "rule": LIFT, "map": {"subject": "p"}, "as": "exception", "case": "inside"}]})
        got = validate_a.lifted_case_gaps(caller, {LIFT: target, YIELD: caller})
        self.assertEqual([(g["span"], g["kind"]) for g in got], [("r1", "operator")])
        self.assertIn(f"reads case `inside` of `{LIFT}`", got[0]["proposal"])
        self.assertEqual([(g["span"], g["kind"]) for g in validate_a.lifted_case_gaps(target, {LIFT: target})], [("e1", "operator")])
        # the same composition of a case on an exception that meets the duty is no finding
        self.assertEqual(validate_a.lifted_case_gaps(Node(copy.deepcopy(YIELD_RECORD)), {CROSS: Node(copy.deepcopy(CROSS_RECORD))}), [])


class Skeleton(unittest.TestCase):
    def test_each_exception_span_is_listed_where_its_kind_is_written(self):
        src = skeleton.rule_skeleton(Node(copy.deepcopy(CROSS_RECORD)))
        app = next(l for l in src.splitlines() if l.startswith("/-- Applicability:"))
        obl = next(l for l in src.splitlines() if l.startswith("/-- Obligation:"))
        self.assertIn("e1 (exception, meets_duty: beside the duty)", obl)
        self.assertNotIn("e1", app)
        src = skeleton.rule_skeleton(Node(copy.deepcopy(LIFT_RECORD)))
        app = next(l for l in src.splitlines() if l.startswith("/-- Applicability:"))
        obl = next(l for l in src.splitlines() if l.startswith("/-- Obligation:"))
        self.assertIn("e1 (exception, lifts_duty: negated)", app)
        self.assertNotIn("e1", obl)


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class Gate(unittest.TestCase):

    def test_an_exception_that_meets_the_duty_with_its_permits_case(self):
        v, rows = run_gate(CROSS, {nodeid.rule_path(CROSS): CROSS_RULE, nodeid.witness_path(CROSS): CROSS_WITNESS}, CROSS_RECORD, [CROSS])
        self.assertEqual(v.verdict, "OK", v.details)
        got = scen(rows)
        self.assertEqual(got["permit"], "compliant")          # crossing in the marked crosswalk
        self.assertEqual(got["forbid"], "violated")           # crossing outside any crosswalk
        self.assertEqual(got["branch_1"], "violated")         # crossing in an unmarked crosswalk
        self.assertEqual(got["idle"], "not_applicable")       # not crossing
        self.assertIn("CASE\tpermit\t0\tpositive", rows)      # the case holds there, the act is shown, the rule compliant

    def test_a_caller_reading_that_case(self):
        files = {nodeid.rule_path(CROSS): CROSS_RULE, nodeid.rule_path(YIELD): YIELD_RULE, nodeid.witness_path(YIELD): YIELD_WITNESS}
        v, rows = run_gate(YIELD, files, YIELD_RECORD, [CROSS, YIELD])
        self.assertEqual(v.verdict, "OK", v.details)
        got = scen(rows)
        self.assertEqual(got["branch_1"], "not_applicable")   # the pedestrian crosses in the marked crosswalk: the exception fires
        self.assertEqual(got["forbid"], "violated")           # in an unmarked crosswalk: the driver's duty stands

    def test_an_exception_that_lifts_the_duty(self):
        v, rows = run_gate(LIFT, {nodeid.rule_path(LIFT): LIFT_RULE, nodeid.witness_path(LIFT): LIFT_WITNESS}, LIFT_RECORD, [LIFT])
        self.assertEqual(v.verdict, "OK", v.details)
        self.assertEqual(scen(rows)["branch_1"], "not_applicable")   # crossing within the intersection


if __name__ == "__main__":
    unittest.main()
