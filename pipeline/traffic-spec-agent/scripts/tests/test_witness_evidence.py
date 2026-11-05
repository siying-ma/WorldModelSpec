"""What a witness may be unknown for, checked where the harness can know it. `Scenario.run` admits an
unknown witness only for atoms its manifest masks or, on a history-boundary witness, a window
truncated at the trace start; only `blind` carries masked atoms into its witness. The validator
therefore returns a plan whose other scenario expects unknown without a boundary (the shape of the
smoke28 plan of 127-3, `branch_1`: unknown for an undeclared assumption); whether masking a planned
atom is enough is left to the gate, which runs the witness on real Lean. A witness the gate rejects
reaches the repair with the result the rule reached, its reasons and what the manifest masks. The
Lean tests are skipped, and so not verified, where the toolchain or the built Core is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate, validate_a
from harness.model import nodeid
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests.test_gate_phases import Ran, _library
from scripts.tests.test_review_routing import ONTO

STANDARD = [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
            {"name": "idle", "expected": "not_applicable"},
            {"name": "blind", "expected": "unknown", "masked": ["rel.surface_gap"],
             "narrative": "the source does not supply body gaps: rel.surface_gap is absent"}]


def plan(*more: dict) -> Node:
    """A following-distance node shaped as the smoke28 plans of 127-1 and 127-3: the gap read as
    `rel.surface_gap`, the blind scenario masking it, and `more` beside the four."""
    return Node({"node_id": "L_127", "law_refs": ["L-127"], "binders": [{"name": "v"}, {"name": "w"}],
                 "segmentation": [{"id": "s1", "role": "obligation", "text": "leave sufficient space"}],
                 "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle", "rel.surface_gap", "kin.speed"]}],
                 "scenarios": copy.deepcopy(STANDARD) + list(more)})


def unknown_errors(n: Node) -> list[str]:
    return [e for e in validate_a.check_scenarios(n, ONTO) if "expects unknown, but declares no history boundary" in e]


class Plan(unittest.TestCase):
    def test_the_smoke28_127_3_branch_unknown_for_an_assumption_is_returned(self):
        n = plan({"name": "branch_1", "expected": "unknown", "masked": [],
                  "narrative": "asm.way_outside_business_district is undeclared, so whether the duty applies is unknown"})
        errs = unknown_errors(n)
        self.assertEqual(len(errs), 1, errs)
        self.assertTrue(errs[0].startswith("L_127: scenario `branch_1` expects unknown"), errs)
        self.assertIn("an undeclared assumption", errs[0])

    def test_a_masked_list_on_another_scenario_is_no_route(self):
        # only `blind` carries `masked` into its witness (the skeleton and the gate's manifest check)
        errs = unknown_errors(plan({"name": "branch_1", "expected": "unknown", "masked": ["kin.speed"]}))
        self.assertEqual(len(errs), 1, errs)

    def test_an_occasion_scenario_is_held_alike(self):
        self.assertEqual(len(unknown_errors(plan({"name": "occasion_s1_outside", "expected": "Unknown"}))), 1)

    def test_the_smoke28_127_1_plan_and_its_blind_are_left_to_the_gate(self):
        # decided branches and a blind masking a read atom: whether the mask is enough is the gate's
        n = plan({"name": "branch_1", "expected": "violated"}, {"name": "branch_2", "expected": "compliant"})
        self.assertEqual(unknown_errors(n), [])
        self.assertFalse([e for e in validate_a.check_scenarios(n, ONTO) if "blind" in e])

    def test_a_history_boundary_scenario_is_left_to_the_gate(self):
        n = plan({"name": "history_boundary", "expected": "unknown", "boundary": "the approach before the recording"})
        self.assertEqual(validate_a.check_scenarios(n, ONTO), [])


class Rendering(unittest.TestCase):
    """The two rejections of smoke28, as `Scenario.run` wrote them, and what the repair now reads
    (before: `blind: blind: expected unknown, got compliant []`, and the 127-3 `branch_1` line with
    its name twice and no word of the manifest)."""

    def test_a_decided_blind(self):
        self.assertEqual(gate.witness_failure("blind", "blind: expected unknown, got compliant []", ["rel.surface_gap"]),
                         "blind: expected unknown, got compliant; the manifest masks rel.surface_gap")
        self.assertEqual(gate.witness_failure("blind", "blind: expected unknown, got violated []", ["rel.surface_gap"]),
                         "blind: expected unknown, got violated; the manifest masks rel.surface_gap")

    def test_an_unknown_for_a_reason_the_contract_does_not_admit(self):
        core = "branch_1: unknown for [assumption_missing:asm.way_outside_business_district], not for an atom the manifest masks"
        self.assertEqual(gate.witness_failure("branch_1", core, []),
                         "branch_1: unknown for [assumption_missing:asm.way_outside_business_district], "
                         "not for an atom the manifest masks; the manifest masks no atom")

    def test_the_reasons_of_an_unexpected_unknown_are_kept(self):
        self.assertEqual(gate.witness_failure("permit", "permit: expected compliant, got unknown [absent_atom:kin_speed, window_truncated:since]"),
                         "permit: expected compliant, got unknown for [absent_atom:kin_speed, window_truncated:since]")

    def test_any_other_message_is_kept_whole(self):
        msg = "b: a history-boundary witness, but no window is truncated at the trace start"
        self.assertEqual(gate.witness_failure("b", msg, []), msg + "; the manifest masks no atom")
        self.assertEqual(gate.witness_failure("x", "the trace is not admitted: y"), "x: the trace is not admitted: y")


# A neutral following duty: the gap between two motor vehicles is at least a parameter.
NODE_ID = "TEST_GAP_7"
RULE = f'''/- A neutral rule for the blind witness's evidence. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(NODE_ID)}

def vV : Arg := .var "v"
def vW : Arg := .var "w"

def rule : Rule :=
  {{ id := "{NODE_ID}"
    laws := ["TEST-GAP-7"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }}, {{ name := "w", cls := .atom "ru_motor_vehicle" [vW] [] }} ]
    applicability := .tt
    obligation := .cmp (.measure "rel_surface_gap" [vV, vW]) .ge (.param "p.gap") }}

end {nodeid.rule_namespace(NODE_ID)}
'''
# Two 4 m cars heading east, `w` ahead of `v`; BLIND is the blind witness.
WITNESS = f'''/- Its witnesses. -/
import {nodeid.rule_module(NODE_ID)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(NODE_ID)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def car (k : TrackId) (x : Int) : RoadUser := Build.user k [.motorVehicle] (m x, Q.zero) Build.east (m 10) (m 2, m 1, m 1)
def bike (k : TrackId) (x : Int) : RoadUser := Build.user k [.bicycle] (m x, Q.zero) Build.east (m 10) (m 1, m 1, m 1)
def pair (w : RoadUser) : Trace := [Build.scene 0 (some 1) [car 1 0, w] [] []]
/-- `v`'s extent unobserved, and so its occupancy: the source saw it but did not measure its body. -/
def sparse : Trace :=
  let s := Build.scene 0 (some 1) [{{ car 1 0 with kin := {{ (car 1 0).kin with extent := none }} }}, car 2 30] [] []
  [{{ s with occupancyObserved := [2] }}]

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{NODE_ID}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("v", 1), ("w", 2)], expected := expected }}

def scenarios : List Scenario :=
  [ witness "forbid" (pair (car 2 6)) .violated
  , witness "permit" (pair (car 2 30)) .compliant
  , witness "idle" (pair (bike 2 30)) .notApplicable
  , witness "blind" BLIND (.unknown []) ["rel.surface_gap"] ]

end {nodeid.witness_namespace(NODE_ID)}
'''
RECORD = {"node_id": NODE_ID, "law_refs": ["TEST-GAP-7"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
          "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}, {"name": "w", "class_elements": ["ru.motor_vehicle"]}],
          "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "o1", "role": "obligation", "text": "leave space"}],
          "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "o1", "atoms": ["rel.surface_gap"]}],
          "params": ["p.gap"], "applicability": "a", "obligation": "o", "scenarios": copy.deepcopy(STANDARD)}


def gap_gate(blind: str) -> gate.Verdict:
    """The neutral node through the gate, run on real Lean, its blind witness on trace `blind`."""
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.rule_path(NODE_ID), nodeid.witness_path(NODE_ID)]
        for rel, src in zip(files, (RULE, WITNESS.replace("BLIND", blind))):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [
            {"name": "p.gap", "value": 5, "unit": "m", "convention": "fixture"}], "aggregates": []}))
        ran = Ran(files, {f"import {nodeid.rule_module(NODE_ID)}", f"import {nodeid.witness_module(NODE_ID)}"})
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            return gate.run_gate(Node(copy.deepcopy(RECORD)), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted_concepts={})


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class SurfaceGapThroughTheGate(unittest.TestCase):
    """Masking `rel.surface_gap` removes a supplied gap only: with both footprints complete Core
    computes the gap and the blind witness is decided; with one body's extent unobserved the same
    manifest leaves it unknown for the masked atom, and the gate accepts the node."""

    def test_complete_footprints_decide_the_masked_gap(self):
        v = gap_gate("(pair (car 2 30))")
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertEqual(v.details, ["blind: expected unknown, got compliant; the manifest masks rel.surface_gap"])

    def test_an_unobserved_extent_leaves_the_masked_gap_unknown(self):
        v = gap_gate("sparse")
        self.assertEqual(v.verdict, "OK", v.details)
        self.assertIn("4 witnesses", v.details[0])


if __name__ == "__main__":
    unittest.main()
