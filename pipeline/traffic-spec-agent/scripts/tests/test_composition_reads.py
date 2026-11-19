"""Every execution composition is read in the rule as the record composes it
(`gate.composition_read_defects`): each read of a composed rule carries the record's map, variable by
variable, and the leaf and sign its kind names; a binder the map names is not bound again by a
quantifier around the read, and a road user the rule quantifies over is bound there once; every
composition is read. With one pedestrian in a scene a reading of "any pedestrian" and of the
record's pedestrian agree, so only a static check or a two-pedestrian witness tells them apart. The
gate cases run on real Lean; they are skipped where the toolchain or the built Core is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.model import nodeid
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests.test_gate_phases import Ran, _library

NODE, TARGET = "TEST_GIVEWAY_9", "TEST_WALKER_9"
IN_JUNCTION = '(.existsRegion (.lit "intersection") "j" (.atom "rel_occupies" [.var "{x}", .var "j"] []))'

# The composed rule: a pedestrian in the junction while a vehicle is about keeps walking.
TARGET_RULE = f'''/- The composed rule. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(TARGET)}

def rule : Rule :=
  {{ id := "{TARGET}"
    laws := ["{TARGET.replace('_', '-')}"]
    binders := [ {{ name := "subject", cls := .atom "ru_pedestrian" [.var "subject"] [] }},
                 {{ name := "v", cls := .atom "ru_motor_vehicle" [.var "v"] [] }} ]
    applicability := {IN_JUNCTION.format(x="subject")}
    obligation := .cmp (.measure "kin_speed" [.var "subject"]) .gt (.lit Q.zero .metrePerSecond) }}

end {nodeid.rule_namespace(TARGET)}
'''

#: The record's reading: the exception holds where the composed rule applies to this rule's pedestrian `p`.
CORRECT = f'(.not (.ruleApplies "{TARGET}" [("subject", "p"), ("v", "subject")]))'
#: Any pedestrian in the scene, not `p`.
ANY_PEDESTRIAN = (f'(.not (.existsUser "q" (.and (.atom "ru_pedestrian" [.var "q"] []) '
                  f'(.ruleApplies "{TARGET}" [("subject", "q"), ("v", "subject")]))))')
#: The record's map, but `p` bound again by a quantifier around the read: any pedestrian again.
SHADOWED = (f'(.not (.existsUser "p" (.and (.atom "ru_pedestrian" [.var "p"] []) '
            f'(.ruleApplies "{TARGET}" [("subject", "p"), ("v", "subject")]))))')
SWAPPED = f'(.not (.ruleApplies "{TARGET}" [("subject", "subject"), ("v", "p")]))'
#: A road user the rule quantifies over, as a record mapping the composed pedestrian to `q` states it.
QUANTIFIED = ANY_PEDESTRIAN


def node_rule(exception: str, binders: str = "subject_and_p") -> str:
    bs = {"subject_and_p": '[ { name := "subject", cls := .atom "ru_motor_vehicle" [.var "subject"] [] },\n'
                           '                 { name := "p", cls := .atom "ru_pedestrian" [.var "p"] [] } ]',
          "subject": '[ { name := "subject", cls := .atom "ru_motor_vehicle" [.var "subject"] [] } ]'}[binders]
    return f'''/- A vehicle in the junction stays at rest, except where the composed rule applies. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(NODE)}

def rule : Rule :=
  {{ id := "{NODE}"
    laws := ["{NODE.replace('_', '-')}"]
    binders := {bs}
    applicability := .and {IN_JUNCTION.format(x="subject")} {exception}
    obligation := .cmp (.measure "kin_speed" [.var "subject"]) .le (.lit Q.zero .metrePerSecond) }}

end {nodeid.rule_namespace(NODE)}
'''


def node_witness(grounding: str) -> str:
    return f'''/- Lane 4 (x 60-100) enters junction 6 (x 100-120); the car is track 1, pedestrian 2 stands on the
   lane, pedestrian 3, when present, in the junction. -/
import {nodeid.rule_module(NODE)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(NODE)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def lane : Structure := Build.lane 4 [(m 60, m 0), (m 100, m 0), (m 100, m 4), (m 60, m 4)] Build.east (enters := some 6)
def junction : Structure := Build.rect 6 .intersection (m 100) (m (-10)) (m 120) (m 14)
def car (x : Int) (sp : Q) : RoadUser := Build.user 1 [.motorVehicle] (m x, m 2) Build.east sp (m 2, m 1, m 1)
def walker (tr : TrackId) (x : Int) : RoadUser := Build.user tr [.pedestrian] (m x, m 8) Build.north (m 1) (m 1, m 1, m 1)
def scene (us : List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _ t => Build.scene t (some 1) us [lane, junction] []

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{NODE}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := {grounding}, expected := expected }}

def scenarios : List Scenario :=
  [ witness "forbid" (scene [car 110 (m 5), walker 2 70]) .violated
  , witness "permit" (scene [car 110 Q.zero, walker 2 70]) .compliant
  , witness "idle" (scene [car 70 (m 5), walker 2 70]) .notApplicable
  , witness "blind" (scene [car 110 (m 5), walker 2 70]) (.unknown []) ["rel.occupies"]
  , witness "excepted" (scene [car 110 (m 5), walker 2 110]) .notApplicable
  , witness "two_pedestrians" (scene [car 110 (m 5), walker 2 70, walker 3 112]) {{TWO}} ]

end {nodeid.witness_namespace(NODE)}
'''


SCENARIOS = [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
             {"name": "idle", "expected": "not_applicable"}, {"name": "blind", "expected": "unknown", "masked": ["rel.occupies"]},
             {"name": "excepted", "expected": "not_applicable", "narrative": "the pedestrian is in the junction"},
             {"name": "two_pedestrians", "expected": "violated", "narrative": "another pedestrian is in the junction"}]

RECORD = {
    "node_id": NODE, "law_refs": [NODE.replace("_", "-")],
    "subject": {"binder": "subject", "class_elements": ["ru.motor_vehicle"]},
    "binders": [{"name": "subject", "class_elements": ["ru.motor_vehicle"]}, {"name": "p", "class_elements": ["ru.pedestrian"]}],
    "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "t1", "role": "condition", "text": "within the junction"},
                     {"id": "c1", "role": "condition", "text": "a pedestrian"},
                     {"id": "o1", "role": "obligation", "text": "shall stay at rest"},
                     {"id": "r1", "role": "reference", "text": "except as otherwise provided"}],
    "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "t1", "atoms": ["st.intersection", "rel.occupies"]},
                 {"span": "c1", "atoms": ["ru.pedestrian"]}, {"span": "o1", "atoms": ["kin.speed"]}],
    "compositions": [{"span": "r1", "rule": TARGET, "map": {"subject": "p", "v": "subject"}, "as": "exception"}],
    "params": [], "applicability": "a", "obligation": "o", "scenarios": SCENARIOS}


def quantified_record() -> dict:
    """The record mapping the composed pedestrian to `q`, a road user the coder quantifies over."""
    rec = copy.deepcopy(RECORD)
    rec["binders"] = rec["binders"][:1]
    rec["compositions"][0]["map"] = {"subject": "q", "v": "subject"}
    rec["scenarios"] = [s | {"expected": "not_applicable"} if s["name"] == "two_pedestrians" else s for s in rec["scenarios"]]
    return rec


def run_gate(rule: str, rec: dict = RECORD, two: str = ".violated") -> gate.Verdict:
    grounding = '[("subject", 1), ("p", 2)]' if any(b["name"] == "p" for b in rec["binders"]) else '[("subject", 1)]'
    witness = node_witness(grounding).replace("{TWO}", two)
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


def leaf(kind: str, m: dict, case: str | None = None) -> dict:
    return {kind: TARGET, "map": m} | ({"case": case} if case else {})


NOT = lambda f: {"not": f}
EXISTS = lambda v, f: {"exists_user": v, "body": f}
FORALL = lambda v, f: {"forall_user": v, "body": f}
PED = lambda v: {"atom": "ru_pedestrian", "args": [{"var": v}], "params": []}
BINDERS = [{"name": "subject", "cls": "tt"}, {"name": "p", "cls": "tt"}]
MAP = {"subject": "p", "v": "subject"}


def defects(rec: dict, applicability=None, obligation="tt", binders=BINDERS, cases=()) -> list[str]:
    return gate.composition_read_defects(Node(rec), {"binders": binders, "applicability": applicability or "tt",
                                                      "obligation": obligation, "cases": list(cases)})


def with_comp(**kw) -> dict:
    rec = copy.deepcopy(RECORD)
    rec["compositions"][0].update(kw)
    return rec


class StaticReads(unittest.TestCase):
    """The rendered rule against the record's compositions, on the rule's JSON alone."""

    def test_the_record_map_passes(self):
        self.assertEqual(defects(RECORD, NOT(leaf("rule_applies", MAP))), [])

    def test_any_pedestrian_is_refused(self):
        got = defects(RECORD, NOT(EXISTS("q", {"and": [PED("q"), leaf("rule_applies", {"subject": "q", "v": "subject"})]})))
        self.assertTrue(any("reads rule_applies `TEST_WALKER_9` map {'subject': 'q', 'v': 'subject'}" in e for e in got), got)
        self.assertTrue(any(e.startswith("no formula of the rule reads `TEST_WALKER_9`") for e in got), got)

    def test_a_binder_bound_again_around_the_read_is_refused(self):
        got = defects(RECORD, NOT(EXISTS("p", {"and": [PED("p"), leaf("rule_applies", MAP)]})))
        self.assertEqual(len(got), 1, got)
        self.assertIn("inside a user quantifier that binds `p` again", got[0])

    def test_a_swapped_map_is_refused(self):
        got = defects(RECORD, NOT(leaf("rule_applies", {"subject": "subject", "v": "p"})))
        self.assertTrue(any("map {'subject': 'subject', 'v': 'p'}" in e for e in got), got)

    def test_the_leaf_follows_the_kind(self):
        self.assertTrue(defects(RECORD, leaf("rule_applies", MAP)))                              # an exception not negated
        self.assertTrue(defects(RECORD, NOT(leaf("rule", MAP))))                                 # compliance's leaf
        cond = with_comp(**{"as": "condition"})
        self.assertEqual(defects(cond, leaf("rule_applies", MAP)), [])
        got = defects(cond, NOT(leaf("rule_applies", MAP)))                                      # a condition written as an exception
        self.assertTrue(any("as condition: rule_applies `TEST_WALKER_9`" in e for e in got), got)
        comp = with_comp(**{"as": "compliance"})
        self.assertEqual(defects(comp, obligation={"or": ["tt", leaf("rule", MAP)]}), [])
        self.assertTrue(defects(comp, obligation={"or": ["tt", leaf("rule_applies", MAP)]}))     # applicability alone is no compliance

    def test_a_named_case_is_read_as_that_case(self):
        rec = with_comp(case="crossing")
        self.assertEqual(defects(rec, NOT(leaf("rule_case", MAP, "crossing"))), [])
        self.assertTrue(defects(rec, NOT(leaf("rule_applies", MAP))))
        self.assertTrue(defects(rec, NOT(leaf("rule_case", MAP, "other"))))

    def test_the_sign_is_towards_a_violation(self):
        """An exception read in the obligation's guard of a quantified road user lifts the duty for
        that road user; the same read negated in the obligation would bring a violation instead."""
        rec = quantified_record()
        m = {"subject": "q", "v": "subject"}
        sel = {"and": [PED("q"), NOT(leaf("rule_applies", m))]}
        guard = FORALL("q", {"implies": [sel, "ff"]})
        self.assertEqual(defects(rec, EXISTS("q", sel), obligation=guard, binders=BINDERS[:1]), [])
        self.assertEqual(defects(rec, NOT(EXISTS("q", {"or": [leaf("rule_applies", m), "ff"]})), binders=BINDERS[:1]), [])
        got = defects(rec, EXISTS("q", sel), obligation=FORALL("q", {"and": [sel, "tt"]}), binders=BINDERS[:1])
        self.assertTrue(any(e.startswith("the obligation reads") for e in got), got)
        got = defects(RECORD, {"rises": NOT(leaf("rule_applies", MAP))})
        self.assertTrue(any("where its holding can bring or remove a violation" in e for e in got), got)

    def test_a_read_inside_a_duration_keeps_its_sign_only_under_gt(self):
        """`durationWithin … gt b` grows with the time its formula holds, so a read inside it keeps the
        sign around it; under any other comparison the read can bring or remove a violation."""
        dur = lambda body, op="gt": {"duration_within": body, "length": {"param": "p.w"}, "step": {"param": "p.step"},
                                     "op": op, "bound": {"param": "p.b"}}
        self.assertEqual(defects(RECORD, dur(NOT(leaf("rule_applies", MAP)))), [])          # an exception, read inside
        self.assertEqual(defects(RECORD, NOT(dur(leaf("rule_applies", MAP)))), [])          # the negation outside
        got = defects(RECORD, dur(leaf("rule_applies", MAP)))                               # an exception not negated
        self.assertTrue(any("where its holding can only bring a violation" in e for e in got), got)
        cond = with_comp(**{"as": "condition"})
        self.assertEqual(defects(cond, dur(leaf("rule_applies", MAP))), [])
        self.assertTrue(defects(cond, NOT(dur(leaf("rule_applies", MAP)))))
        for op in ("ge", "eq", "le", "lt"):
            got = defects(RECORD, dur(NOT(leaf("rule_applies", MAP)), op))
            self.assertTrue(any("where its holding can bring or remove a violation" in e for e in got), (op, got))
            got = defects(cond, dur(leaf("rule_applies", MAP), op))
            self.assertTrue(any("where its holding can bring or remove a violation" in e for e in got), (op, got))

    def test_a_quantified_road_user_is_bound_once(self):
        rec = quantified_record()
        m = {"subject": "q", "v": "subject"}
        self.assertEqual(defects(rec, NOT(EXISTS("q", {"and": [PED("q"), leaf("rule_applies", m)]})), binders=BINDERS[:1]), [])
        got = defects(rec, NOT(EXISTS("q", {"and": [PED("q"), EXISTS("q", leaf("rule_applies", m))]})), binders=BINDERS[:1])
        self.assertEqual(len(got), 1, got)
        self.assertIn("inside 2 quantifiers that bind `q`", got[0])

    def test_a_compliance_may_place_its_observation(self):
        """`atLast (.ruleApplies R m) (.rule R m)`, or it beside the window's `holdsFor (.not (.ruleApplies
        R m))` in an `or`, places the observation compliance is judged at; that `ruleApplies` anywhere
        else is refused, and it never counts as the compliance's read."""
        rec = with_comp(**{"as": "compliance"})
        win = {"length": {"param": "p.w"}, "subject": "subject"}
        at = {"at_last": "time", **win, "when": leaf("rule_applies", MAP), "body": leaf("rule", MAP)}
        nowhere = {"holds_for": "time", **win, "body": NOT(leaf("rule_applies", MAP))}
        self.assertEqual(defects(rec, obligation=at), [])
        self.assertEqual(defects(rec, obligation={"or": [at, nowhere]}), [])                      # the shape of a recorded rule
        self.assertEqual(defects(rec, obligation={"or": [nowhere, at]}), [])
        refused = lambda **kw: [e for e in defects(rec, **kw) if "reads rule_applies `TEST_WALKER_9`" in e]
        self.assertTrue(refused(obligation={"or": [leaf("rule", MAP), leaf("rule_applies", MAP)]}))   # an unrelated disjunct
        self.assertTrue(refused(applicability=leaf("rule_applies", MAP), obligation=leaf("rule", MAP)))  # the applicability
        self.assertTrue(refused(applicability=NOT(leaf("rule_applies", MAP)), obligation=at))
        self.assertTrue(refused(obligation={"or": [at, {**nowhere, "length": {"param": "p.other"}}]}))  # another window
        self.assertTrue(refused(obligation={"and": [at, nowhere]}))                                   # not the alternative
        self.assertTrue(refused(obligation={**at, "body": {"and": [leaf("rule", MAP), "tt"]}}))       # its body is not the read
        got = defects(rec, obligation={"at_last": "time", **win, "when": leaf("rule_applies", MAP), "body": "tt"})
        self.assertTrue(any(e.startswith("no formula of the rule reads `TEST_WALKER_9` as compliance") for e in got), got)
        other = {"subject": "subject", "v": "p"}
        bad = {**at, "when": leaf("rule_applies", other), "body": leaf("rule", other)}
        self.assertTrue(any("map {'subject': 'subject', 'v': 'p'}" in e for e in defects(rec, obligation={"or": [at, bad]})))

    def test_every_composition_is_read(self):
        got = defects(RECORD, "tt")
        self.assertEqual(len(got), 1, got)
        self.assertTrue(got[0].startswith("no formula of the rule reads `TEST_WALKER_9` as exception"), got)

    def test_reads_in_cases_are_held(self):
        cases = [{"name": "c", "when": leaf("rule_applies", MAP), "shown": "tt"}]
        got = defects(RECORD, NOT(leaf("rule_applies", MAP)), cases=cases)
        self.assertTrue(any(e.startswith("case `c` when reads") for e in got), got)
        cases[0]["when"] = NOT(leaf("rule_applies", MAP))
        self.assertEqual(defects(RECORD, NOT(leaf("rule_applies", MAP)), cases=cases), [])

    def test_a_record_without_execution_compositions_has_nothing_to_check(self):
        rec = copy.deepcopy(RECORD)
        rec["compositions"] = [{"span": "r1", "as": "definition", "source": "X", "quote": "y"}]
        self.assertEqual(defects(rec, leaf("rule_applies", MAP)), [])


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class Gate(unittest.TestCase):

    def test_the_record_binding_passes(self):
        v = run_gate(node_rule(CORRECT))
        self.assertEqual(v.verdict, "OK", v.details)

    def test_any_pedestrian_fails_statically_and_on_two_pedestrians(self):
        v = run_gate(node_rule(ANY_PEDESTRIAN))
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("map {'subject': 'q', 'v': 'subject'}" in d for d in v.details), v.details)
        with mock.patch.object(gate, "composition_read_defects", lambda *a: []):
            v = run_gate(node_rule(ANY_PEDESTRIAN))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any(d.startswith("two_pedestrians: expected violated, got not_applicable") for d in v.details), v.details)

    def test_a_binder_bound_again_fails(self):
        v = run_gate(node_rule(SHADOWED))
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("inside a user quantifier that binds `p` again" in d for d in v.details), v.details)

    def test_a_swapped_map_fails(self):
        v = run_gate(node_rule(SWAPPED))
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("map {'subject': 'subject', 'v': 'p'}" in d for d in v.details), v.details)

    def test_a_condition_written_as_an_exception_fails(self):
        rec = with_comp(**{"as": "condition"})
        v = run_gate(node_rule(CORRECT), rec)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertTrue(any("as condition: rule_applies `TEST_WALKER_9`" in d for d in v.details), v.details)

    def test_a_quantified_road_user_as_the_record_maps_it_passes(self):
        v = run_gate(node_rule(QUANTIFIED, binders="subject"), quantified_record(), two=".notApplicable")
        self.assertEqual(v.verdict, "OK", v.details)


if __name__ == "__main__":
    unittest.main()
