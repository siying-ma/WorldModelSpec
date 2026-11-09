"""An act a concept record declares is checked against what the code does with it: a window
boundary needs the declared window formal to be the length of a window behind the judged
observation in the body as Core expands it (a window ahead, a horizon of projected motion or a
formal forwarded elsewhere is no look-back); an event boundary needs an operator that starts at an
observed event, which is a capability precheck and no proof of which onset anchors the act. A
node's window occasion reads the window its act is actually called with. The declaration is part
of what callers rely on under the concept's id. The Lean-backed tests are skipped, and so not
verified, where the toolchain or the built Core is absent."""
import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.lean import lean
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord, Node
from harness.model.reading import Reading
from harness.phases import candidate, label_repair
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests.test_gate_phases import Ran, _library
from scripts.tests.test_review_routing import ONTO

WIN = {"boundary": "window", "window": "w"}
EVENT = {"boundary": "event"}


def prim(name: str, *params) -> dict:
    return {"quantity": name, "args": [{"var": "u"}], "params": [{"param": p} for p in params]}


class WindowSupport(unittest.TestCase):
    """The window formal must stand as the length of a look-back, by operator position and direction."""

    def test_a_projection_horizon_is_no_look_back(self):
        body = {"quantity": "prim_closest_approach_time", "args": [{"var": "u"}, {"var": "v"}], "params": [{"param": "w"}]}
        self.assertTrue(gate.act_support_defects(WIN, body))

    def test_a_window_ahead_is_no_look_back(self):
        body = {"within": "time", "length": {"param": "w"}, "subject": "u", "body": {"atom": "ru_car", "args": [{"var": "u"}], "params": []}}
        self.assertTrue(gate.act_support_defects(WIN, body))
        self.assertTrue(gate.act_support_defects(WIN, {"until_within": "time", "length": {"param": "w"}, "subject": "u",
                                                       "hold": {"atom": "a"}, "reach": {"atom": "b"}}))

    def test_a_window_behind_is_a_look_back(self):
        self.assertEqual(gate.act_support_defects(WIN, {"holds_for": "time", "length": {"param": "w"}, "subject": "u",
                                                         "body": {"atom": "a"}}), [])
        self.assertEqual(gate.act_support_defects(WIN, {"at_last": "time", "length": {"param": "w"}, "subject": "u",
                                                         "when": {"atom": "a"}, "body": {"atom": "b"}}), [])
        self.assertEqual(gate.act_support_defects(WIN, {"cmp": "ge", "lhs": prim("prim_heading_change", "w"), "rhs": {"param": "least"}}), [])

    def test_another_use_or_another_parameter_is_no_look_back(self):
        self.assertTrue(gate.act_support_defects(WIN, {"cmp": "le", "lhs": {"since_rise": {"atom": "a"}}, "rhs": {"param": "w"}}))
        self.assertTrue(gate.act_support_defects(WIN, {"holds_for": "time", "length": {"param": "other"}, "subject": "u",
                                                       "body": {"atom": "a"}}))
        self.assertTrue(gate.act_support_defects(WIN, {"holds_for": "path", "length": {"param": "w"}, "subject": "u",
                                                       "body": {"atom": "a"}}))

    def test_every_primitive_has_a_known_parameter_role(self):
        known = set(gate.LOOKBACK_PRIMITIVE_PARAMS) | gate.NO_LOOKBACK_PRIMITIVES
        self.assertEqual(known, {i.replace(".", "_") for i in ONTO.primitive_ids})
        self.assertFalse(set(gate.LOOKBACK_PRIMITIVE_PARAMS) & gate.NO_LOOKBACK_PRIMITIVES)

    def test_an_event_boundary_needs_an_onset_operator(self):
        onset = {"since": [{"not": {"rises": {"atom": "a"}}}, {"rises": {"atom": "a"}}]}
        self.assertEqual(gate.act_support_defects(EVENT, onset), [])
        self.assertTrue(gate.act_support_defects(EVENT, prim("prim_heading_change", "w")))
        self.assertTrue(gate.act_support_defects(WIN, onset))
        self.assertEqual(gate.act_support_defects(None, prim("prim_heading_change", "w")), [])


def heading_since(step: dict | None = None, onset: dict | None = None) -> dict:
    return {"heading_since": "u", "max_step": step or {"param": "step"}, "onset": onset or {"atom": "a", "args": [{"var": "u"}], "params": []}}


class HeadingSinceSupport(unittest.TestCase):
    """`heading_since` reads from the latest rise of its onset: it starts at an observed event, wherever it
    stands in the body; its step bound is a sampling standard, never the length of a window behind."""

    def test_inside_abs(self):
        body = {"cmp": "ge", "lhs": {"abs": heading_since()}, "rhs": {"param": "least"}}
        self.assertEqual(gate.act_support_defects(EVENT, body), [])

    def test_inside_arithmetic(self):
        body = {"cmp": "ge", "lhs": {"sub": [heading_since(), {"mul": [{"param": "k"}, heading_since()]}]}, "rhs": {"param": "least"}}
        self.assertEqual(gate.act_support_defects(EVENT, body), [])

    def test_no_onset_operator_is_still_refused(self):
        body = {"cmp": "ge", "lhs": {"abs": prim("prim_heading_change", "w")}, "rhs": {"param": "least"}}
        self.assertTrue(gate.act_support_defects(EVENT, body))

    def test_the_step_bound_is_no_window(self):
        body = {"cmp": "ge", "lhs": {"abs": heading_since({"param": "w"})}, "rhs": {"param": "least"}}
        self.assertTrue(gate.act_support_defects(WIN, body))
        self.assertEqual(gate.act_support_defects(EVENT, body), [])


PROBE = '''import TrafficSpec.Core.Language.Concept
import TrafficSpec.Core.Language.Export
open TrafficSpec Lean

def callee : Concept :=
  { id := "drv.motion.turned_over", contract := "c", args := [("x", .track)],
    params := [⟨"span", .second⟩, ⟨"least", .degree⟩],
    body := .formula (.cmp (.quantity "prim_heading_change" [.var "x"] [.param "span"]) .ge (.param "least")) }
def ahead : Concept :=
  { id := "drv.motion.near_ahead", contract := "c", args := [("x", .track), ("y", .track)],
    params := [⟨"horizon", .second⟩, ⟨"gap", .second⟩],
    body := .formula (.cmp (.quantity "prim_closest_approach_time" [.var "x", .var "y"] [.param "horizon"]) .le (.param "gap")) }
def turnedSince : Concept :=
  { id := "drv.motion.turned_since", contract := "c", args := [("x", .track)],
    params := [⟨"step", .second⟩, ⟨"least", .degree⟩],
    body := .formula (.cmp (.abs (.headingSince "x" (.param "step") (.cmp (.measure "kin_speed" [.var "x"]) .gt (.lit Q.zero .metrePerSecond))))
                           .ge (.param "least")) }
def caller : Formula := .derived "drv_motion_turned_since" [.var "u"] [.param "w", .param "least"]
def fwd : Formula := .derived "drv_motion_turned_over" [.var "u"] [.param "w", .param "least"]
def nofwd : Formula := .and (.derived "drv_motion_turned_over" [.var "u"] [.param "other", .param "least"])
                            (.derived "drv_motion_near_ahead" [.var "u", .var "u"] [.param "w", .param "other"])
def rule (ps : List TrafficSpec.Term) : Rule :=
  { id := "N", laws := ["L"], binders := [⟨"v", .tt⟩], applicability := .rises (.derived "drv_motion_turned_over" [.var "v"] ps),
    obligation := .derived "drv_motion_turned_over" [.var "v"] ps }
def main : IO Unit := do
  let cs := [callee, ahead, turnedSince]
  IO.println s!"FWD\\t{(Formula.toJson (Concept.expand cs fwd)).compress}"
  IO.println s!"NOFWD\\t{(Formula.toJson (Concept.expand cs nofwd)).compress}"
  IO.println s!"HSINCE\\t{(Formula.toJson (Concept.expand cs caller)).compress}"
  IO.println s!"RULE_A\\t{(Rule.toJson (rule [.param "p.a", .param "p.least"])).compress}"
'''


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class OnCoreOutput(unittest.TestCase):
    """The checks read what Core prints: the expanded concept body (a forwarded formal stands where
    the callee reads it) and a rule's calls with their actuals at their formals' positions."""

    @classmethod
    def setUpClass(cls):
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "probe.lean"
            f.write_text(PROBE, encoding="utf-8")
            code, out = lean.lean_run(paths.LIBRARY, f, timeout=600)
        cls.rows = {l.split("\t", 1)[0]: json.loads(l.split("\t", 1)[1]) for l in out.splitlines() if "\t" in l}
        assert {"FWD", "NOFWD", "RULE_A", "HSINCE"} <= set(cls.rows), out[-2000:]

    def test_a_formal_forwarded_to_a_look_back_supports_the_window(self):
        self.assertEqual(gate.act_support_defects(WIN, self.rows["FWD"]), [])

    def test_a_formal_forwarded_to_a_horizon_does_not(self):
        self.assertTrue(gate.act_support_defects(WIN, self.rows["NOFWD"]))

    def test_heading_since_in_a_called_concept_supports_an_event(self):
        self.assertIn("heading_since", json.dumps(self.rows["HSINCE"]))      # Core inlined the callee
        self.assertEqual(gate.act_support_defects(EVENT, self.rows["HSINCE"]), [])
        self.assertTrue(gate.act_support_defects(WIN, self.rows["HSINCE"]))  # `w` reached only the step bound

    def test_the_occasion_window_is_bound_to_the_actual_argument(self):
        concepts = {"drv.motion.turned_over": {"params": [{"name": "span", "unit": "s"}, {"name": "least", "unit": "deg"}],
                                               "act": {"boundary": "window", "window": "span"}}}
        good, bad = occasion_node("p.a"), occasion_node("p.b")
        self.assertEqual(gate.occasion_window_defects(good, self.rows["RULE_A"], concepts), [])
        errs = gate.occasion_window_defects(bad, self.rows["RULE_A"], concepts)
        self.assertEqual(len(errs), 2, errs)                          # both calls pass `p.a`, the occasion reads `p.b`


def occasion_node(window: str, acts=("drv.motion.turned_over",)) -> Node:
    act = list(acts) if len(acts) > 1 else acts[0]
    return Node({"node_id": "N", "law_refs": ["L"], "params": ["p.a", "p.b", "p.least"],
                 "occasion": {"act": act, "window": window, "spans": {}}})


def call(cid: str, *params) -> dict:
    return {"derived": cid.replace(".", "_"), "args": [{"var": "v"}], "params": [{"param": p} for p in params]}


class OccasionWindowBinding(unittest.TestCase):
    """Two legal time parameters: the concept is called with A, so an occasion over B is refused."""
    CONCEPTS = {"drv.motion.turn": {"params": [{"name": "span", "unit": "s"}, {"name": "settle", "unit": "s"}],
                                    "act": {"boundary": "window", "window": "span"}},
                "drv.motion.reverse": {"params": [{"name": "span", "unit": "s"}], "act": {"boundary": "window", "window": "span"}},
                "drv.motion.untimed": {"params": [{"name": "span", "unit": "s"}]}}

    def test_the_window_actually_passed_is_the_occasion_s(self):
        rule = {"obligation": call("drv.motion.turn", "p.a", "p.b")}
        self.assertEqual(gate.occasion_window_defects(occasion_node("p.a", ["drv.motion.turn"]), rule, self.CONCEPTS), [])
        errs = gate.occasion_window_defects(occasion_node("p.b", ["drv.motion.turn"]), rule, self.CONCEPTS)
        self.assertTrue(errs and "for its window `span`" in errs[0], errs)

    def test_alternative_acts_each_take_the_occasion_s_window(self):
        node = occasion_node("p.a", ["drv.motion.turn", "drv.motion.reverse"])
        rule = {"or": [call("drv.motion.turn", "p.a", "p.b"), call("drv.motion.reverse", "p.a")]}
        self.assertEqual(gate.occasion_window_defects(node, rule, self.CONCEPTS), [])
        rule = {"or": [call("drv.motion.turn", "p.a", "p.b"), call("drv.motion.reverse", "p.b")]}
        errs = gate.occasion_window_defects(node, rule, self.CONCEPTS)
        self.assertEqual(len(errs), 1, errs)
        self.assertIn("drv.motion.reverse", errs[0])

    def test_an_act_that_is_not_called_or_not_declared_cannot_be_bound(self):
        self.assertTrue(gate.occasion_window_defects(occasion_node("p.a", ["drv.motion.turn"]), {"obligation": "tt"}, self.CONCEPTS))
        self.assertTrue(gate.occasion_window_defects(occasion_node("p.a", ["drv.motion.untimed"]),
                                                     {"obligation": call("drv.motion.untimed", "p.a")}, self.CONCEPTS))

    def test_an_event_occasion_binds_no_window(self):
        node = Node({"node_id": "N", "law_refs": ["L"], "occasion": {"act": "drv.motion.turn", "boundary": "event"}})
        self.assertEqual(gate.occasion_window_defects(node, {"obligation": "tt"}, self.CONCEPTS), [])


class ActUnderTheSameId(unittest.TestCase):
    """The act declaration is part of a concept's interface: deleting, adding or changing any part
    of it under the same id is refused, and is no local change a repair may write itself."""
    ACT = {"boundary": "window", "window": "span", "onset": "begins", "recognition": "is complete",
           "extent": "while it lasts", "history": "nothing before"}
    REC = {"concept_id": "drv.motion.turn", "kind": "formula", "contract": "c", "args": [{"name": "u", "sort": "track"}],
           "params": [{"name": "span", "unit": "s"}, {"name": "other", "unit": "s"}], "elements": [], "act": ACT}

    def changed(self, **act) -> dict:
        new = copy.deepcopy(self.REC)
        new["act"] = {**self.ACT, **act}
        return new

    def refused(self, new: dict) -> None:
        self.assertTrue(candidate.same_id_defects(self.REC, new), new.get("act"))
        self.assertTrue(label_repair.not_local("concept", self.REC, new), new.get("act"))

    def test_deletion_and_addition(self):
        bare = copy.deepcopy(self.REC); del bare["act"]
        self.refused(bare)
        self.assertTrue(candidate.same_id_defects(bare, self.REC))
        self.assertTrue(label_repair.not_local("concept", bare, self.REC))

    def test_each_part(self):
        self.refused(self.changed(boundary="event"))
        self.refused(self.changed(window="other"))
        for k in ("onset", "recognition", "extent", "history"):
            self.refused(self.changed(**{k: "something else"}))

    def test_whitespace_alone_is_no_change(self):
        same = self.changed(onset="  begins ")
        self.assertEqual(candidate.same_id_defects(self.REC, same), [])
        self.assertEqual(label_repair.not_local("concept", self.REC, same), [])


# A concept that declares a window act over `w`, its body `BODY`.
CID = "drv.motion.gate_act_test"
CONTRACT = "The road user's measured speed stays at or below the tolerance over the window."
CONCEPT = f'''import TrafficSpec.Core.Language.Concept

namespace {nodeid.concept_namespace(CID)}

def aU : Arg := .var "u"
def body : Formula := BODY

def concept : Concept :=
  {{ id := "{CID}"
    contract := "{CONTRACT}"
    definition := none
    args := [("u", .track)]
    params := [⟨"tol", .metrePerSecond⟩, ⟨"w", .second⟩]
    body := .formula body
    residues := []
    narrowings := []
    supersedes := none }}

end {nodeid.concept_namespace(CID)}
'''
WITNESSES = f'''import {nodeid.concept_module(CID)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.concept_witness_namespace(CID)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def creep : Q := Units.micrometresPerSecond 1500000

def inst : Concept.Instance :=
  {{ name := "{CID}@w", concept := "{CID}", literals := [], nats := [],
    params := [("tol", .lit (Units.micrometresPerSecond 200000) .metrePerSecond), ("w", .lit (Units.seconds 1) .second)], bounds := none }}

def instances : List Concept.Instance := [inst]

def structures : List Structure :=
  [ Build.lane 11 [(m (-60), m (-5)), (m 60, m (-5)), (m 60, m 5), (m (-60), m 5)] Build.east ]

def drive (sp : Q) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (Q.add (m (-2)) (Q.mul sp (Q.ofInt (Int.ofNat k))), Q.zero) Build.east sp (m 2, m 1, m 1) ]
      structures []

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := inst.name, trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("u", 1)], expected := expected }}

def scenarios : List Scenario :=
  [ witness "holds" (drive Q.zero) .compliant, witness "fails" (drive creep) .violated,
    witness "blind" (drive creep) (.unknown []) ["kin.speed"] ]

end {nodeid.concept_witness_namespace(CID)}
'''
SPEED = '.cmp (.measure "kin_speed" [aU]) .le (.param "tol")'
RECORD = {"concept_id": CID, "contract": CONTRACT, "kind": "formula", "args": [{"name": "u", "sort": "track"}],
          "params": [{"name": "tol", "unit": "m/s"}, {"name": "w", "unit": "s"}],
          "elements": [{"span": "measured speed", "atoms": ["kin.speed"]}], "residues": [], "literals": [],
          "act": {"boundary": "window", "window": "w", "onset": "measured speed", "recognition": "over the window",
                  "extent": "stays at or below", "history": "over the window"}}


def concept_gate(body: str) -> gate.Verdict:
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.concept_path(CID), nodeid.concept_witness_path(CID)]
        for rel, src in zip(files, (CONCEPT.replace("BODY", body), WITNESSES)):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        ran = Ran(files, {f"import {nodeid.concept_module(CID)}", f"import {nodeid.concept_witness_module(CID)}"})
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            return gate.run_concept_gate(ConceptRecord(copy.deepcopy(RECORD)), Reading(Path(t) / "reading.json"), {}, work, 0, 5,
                                         accepted={})


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class ConceptGate(unittest.TestCase):
    """The real concept gate refuses a window act whose body looks ahead over its window, and lets
    one that looks behind over it through to its witnesses."""

    def test_a_window_ahead_is_a_declaration_mismatch(self):
        v = concept_gate(f'.within .time (.param "w") "u" ({SPEED})')
        self.assertEqual(v.verdict, "DECLARATION_MISMATCH", v.details)
        self.assertIn("window behind", v.details[0])

    def test_a_window_behind_passes_the_act_check(self):
        v = concept_gate(f'.holdsFor .time (.param "w") "u" ({SPEED})')
        self.assertIn(v.verdict, ("OK", "WITNESS_FAIL", "VACUOUS"), v.details)
        self.assertFalse(any("declares a window act" in d for d in v.details), v.details)


if __name__ == "__main__":
    unittest.main()
