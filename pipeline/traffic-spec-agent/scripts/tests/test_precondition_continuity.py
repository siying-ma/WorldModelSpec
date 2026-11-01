"""A condition that refers to an act stated elsewhere, checked on the production interfaces: the plan
and repair templates rendered with the records a law planned again is shown; a planned branch that
expects `not_applicable` through the validator, the witness skeleton and the gate's own harness
program, run on real Lean (a wrong planned verdict fails); and the boundary table of
`fixtures/precondition_continuity.lean`, run on real Lean. The Lean tests are skipped, and so not
verified, where the toolchain or the built Core is absent."""
import copy
import json
import re
import shutil
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

from harness.agents import render
from harness.checks import gate, validate_a
from harness.lean import lean, skeleton
from harness.model import nodeid
from harness.model.blueprint import Node
from harness.model.reading import Reading
from harness.phases import plan
from harness.store import paths
from scripts.tests.test_plan_records import smoke23_duties, smoke23_world
from scripts.tests.test_review_routing import ONTO

FIXTURE = Path(__file__).with_name("fixtures") / "precondition_continuity.lean"
CORE_BUILT = (paths.LIBRARY / ".lake" / "build" / "lib" / "lean" / "TrafficSpec" / "Core" / "Evidence" / "Adequacy.olean").exists()
TOOLCHAIN = shutil.which("lake") is not None and CORE_BUILT
SKIP = "the Lean toolchain or the built Core is absent: not verified"


class Render(unittest.TestCase):
    """The real templates, filled with the records of a law planned again."""

    def test_the_plan_prompt_shows_every_node_of_the_plan_and_the_rule(self):
        with smoke23_world() as (run, law):
            values = {k: f"({k})" for k in plan.PLACEHOLDERS}
            values["previous_records"] = plan.previous_records(run, [law])
            values["aggregate_atom"], values["anchors"] = "ru.aggregate", "rel.occupies"
            text = render.render("plan.md", values)
        section = text.split("## Your previous record of these laws", 1)[1].split("(user_hints)", 1)[0]
        ids = [nid for nid, _w in smoke23_duties()]
        for nid in ids:
            self.assertIn(f"`{nid}` — its duty", section)
        self.assertEqual(section.count(f"composes `{ids[0]}` as compliance"), 2)
        self.assertIn("carries that referent with every qualification", " ".join(text.split()))

    def test_the_repair_prompt_shows_the_siblings_read_only(self):
        with smoke23_world() as (run, law):
            _k, entries, _u = plan.law_history(run, law)
            node = Node(entries[1].versions[-1][1])
            siblings = [Node(e.versions[-1][1]) for e in entries]
            block = plan.repair_context(run, node, law, siblings)
            values = {k: f"({k})" for k in plan.PLACEHOLDERS_NODE_REPAIR}
            values["node"] = "## The node\n\n(the record)\n" + block
            values["aggregate_atom"], values["anchors"] = "ru.aggregate", "rel.occupies"
            text = render.render("node_repair.md", values)
        ids = [nid for nid, _w in smoke23_duties()]
        self.assertIn(f"`{ids[0]}` — its duty", text)
        self.assertIn("as coded in iteration 2", text)
        self.assertNotIn(f"`{ids[1]}` — its duty", block)        # the node itself is shown once, as the record


# A neutral caller: within a junction, a speed bound that holds after a halt on the stop line that
# marks the entrance of a lane entering that junction, the halt read in a window behind.
NODE_ID = "TEST_PRECOND_9_o2"
RULE = f'''/- A neutral caller for the gate's planned-branch check. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(NODE_ID)}

def vV : Arg := .var "v"
def halted : Formula := .cmp (.measure "kin_speed" [vV]) .le (.lit Q.zero .metrePerSecond)
def onLineOf : Formula :=
  .existsRegion (.lit "stop_line") "l" (.and (.atom "rel_occupies" [vV, .var "l"] [])
    (.existsRegion (.lit "lane") "a" (.and (.atom "st_entrance_of" [.var "l", .var "a"] [])
      (.atom "st_lane_enters" [.var "a", .var "j"] []))))
def applicability : Formula :=
  .existsRegion (.lit "intersection") "j" (.and (.atom "rel_occupies" [vV, .var "j"] [])
    (.not (.holdsFor .time (.param "p.halt_window") "v" (.not (.and halted onLineOf)))))
def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")

def rule : Rule :=
  {{ id := "{NODE_ID}"
    laws := ["TEST-PRECOND-9"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }} ]
    applicability := applicability
    obligation := obligation }}

end {nodeid.rule_namespace(NODE_ID)}
'''
WITNESS = f'''/- Its witnesses: lane 4 (x 60-100) enters junction 6 (x 100-120); stop line 5 (x 96-98) marks it. -/
import {nodeid.rule_module(NODE_ID)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(NODE_ID)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def lane : Structure := Build.lane 4 [(m 60, m 0), (m 100, m 0), (m 100, m 4), (m 60, m 4)] Build.east (enters := some 6)
def line : Structure := {{ Build.rect 5 .stopLine (m 96) (m 0) (m 98) (m 4) with entranceOf := [4], entranceObserved := true }}
def junction : Structure := Build.rect 6 .intersection (m 100) (m (-10)) (m 120) (m 14)

def drive (path : List (Int × Q)) : Trace :=
  Build.trace path.length 0 (Units.seconds 1) fun k t =>
    let (x, sp) := path.getD k (0, Q.zero)
    Build.scene t (some 1) [Build.user 1 [.motorVehicle] (m x, m 2) Build.east sp (m 2, m 1, m 1)] [lane, line, junction] []

def fast : Q := Units.metres 8
def crawl : Q := Units.metres 1

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{NODE_ID}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("v", 1)], expected := expected }}

def scenarios : List Scenario :=
  [ witness "forbid" (drive [(90, fast), (97, Q.zero), (97, Q.zero), (105, fast)]) .violated
  , witness "permit" (drive [(90, fast), (97, Q.zero), (97, Q.zero), (105, crawl)]) .compliant
  , witness "idle" (drive [(70, fast), (78, fast), (86, fast), (94, fast)]) .notApplicable
  , witness "blind" (drive [(90, fast), (97, Q.zero), (97, Q.zero), (105, fast)]) (.unknown []) ["st.entrance_of"]
  , witness "branch_1" (drive [(80, fast), (88, Q.zero), (88, Q.zero), (105, fast)]) BRANCH ]

end {nodeid.witness_namespace(NODE_ID)}
'''
RECORD = {"node_id": NODE_ID, "law_refs": ["TEST-PRECOND-9"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
          "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
          "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "t1", "role": "trigger", "text": "within the junction"},
                           {"id": "c1", "role": "condition", "text": "after such a stop"},
                           {"id": "o1", "role": "obligation", "text": "proceed slowly"}],
          "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}, {"span": "t1", "atoms": ["st.intersection", "rel.occupies"]},
                       {"span": "c1", "atoms": ["kin.speed", "st.stop_line", "st.lane", "st.entrance_of", "st.lane_enters"]},
                       {"span": "o1", "atoms": ["kin.speed"]}],
          "params": ["p.halt_window", "p.crawl"], "applicability": "a", "obligation": "o",
          "scenarios": [{"name": "forbid", "expected": "violated"}, {"name": "permit", "expected": "compliant"},
                        {"name": "idle", "expected": "not_applicable"}, {"name": "blind", "expected": "unknown", "masked": ["st.entrance_of"]},
                        {"name": "branch_1", "expected": "not_applicable",
                         "narrative": "the subject halts on the lane short of the line, then enters the junction fast"}]}


def _split(src: str) -> tuple[list[str], str]:
    lines = src.splitlines()
    return [l for l in lines if l.startswith("import ")], "\n".join(l for l in lines if not l.startswith("import "))


def standalone(work: Path, targets, own, namespaces, harness: Path, register=None, phase="witnesses", timeout=gate.GATE_DEADLINE):
    """The gate's toolchain step without writing into the library: the node's two files and the
    gate's own harness program elaborated as one file against the built Core, and run in `phase`."""
    lib = paths.LIBRARY
    r_imp, r_body = _split((lib / nodeid.rule_path(NODE_ID)).read_text())
    w_imp, w_body = _split((lib / nodeid.witness_path(NODE_ID)).read_text())
    h_imp, h_body = _split(harness.read_text())
    own_modules = {f"import {nodeid.rule_module(NODE_ID)}", f"import {nodeid.witness_module(NODE_ID)}"}
    imports = list(dict.fromkeys(i for i in r_imp + w_imp + h_imp if i not in own_modules))
    f = work / "standalone.lean"
    f.write_text("\n".join(imports) + "\n" + r_body + "\n" + w_body + "\n" + h_body, encoding="utf-8")
    code, out = lean.lean_run(REAL_LIBRARY, f, timeout=timeout, args=() if phase == "witnesses" else (phase,))
    return "", out


REAL_LIBRARY = paths.LIBRARY


@unittest.skipUnless(TOOLCHAIN, SKIP)
class PlannedBranchThroughTheGate(unittest.TestCase):
    """A planned branch expecting `not_applicable` passes the validator's scenario check, is written
    into the witness skeleton with that verdict, and is held to it by the gate."""

    def gate(self, planned: str, declared: str):
        rec = copy.deepcopy(RECORD)
        rec["scenarios"][-1]["expected"] = planned
        with tempfile.TemporaryDirectory() as t:
            lib, work = Path(t) / "library", Path(t) / "work"
            for rel, src in ((nodeid.rule_path(NODE_ID), RULE), (nodeid.witness_path(NODE_ID), WITNESS.replace("BRANCH", declared))):
                (lib / rel).parent.mkdir(parents=True, exist_ok=True)
                (lib / rel).write_text(src, encoding="utf-8")
            work.mkdir()
            (work / "registry.json").write_text(json.dumps({"nodes": [], "concepts": []}))
            (Path(t) / "reading.json").write_text(json.dumps({"params": [
                {"name": "p.halt_window", "value": 3, "unit": "s", "convention": "fixture"},
                {"name": "p.crawl", "value": 3, "unit": "m/s", "convention": "fixture"}], "aggregates": []}))
            dirs = {"LIBRARY": lib, "RULES_DIR": lib / "TrafficSpec" / "Rules", "CONCEPTS_DIR": lib / "TrafficSpec" / "Concepts",
                    "WITNESS_DIR": lib / "TrafficSpecWitness", "CONCEPT_WITNESS_DIR": lib / "TrafficSpecWitness" / "Concepts"}
            with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                    mock.patch.object(gate, "_toolchain", standalone):
                return gate.run_gate(Node(rec), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted_concepts={})

    def test_the_validator_and_the_skeleton_take_the_planned_verdict(self):
        self.assertEqual(validate_a.check_scenarios(Node(copy.deepcopy(RECORD)), ONTO), [])
        self.assertIn('witness "branch_1" branch_1Trace .notApplicable', skeleton.witness_skeleton(Node(copy.deepcopy(RECORD))))

    def test_a_planned_not_applicable_branch_passes(self):
        v = self.gate("not_applicable", ".notApplicable")
        self.assertEqual(v.verdict, "OK", v.details)
        self.assertIn("5 witnesses", v.details[0])

    def test_a_wrong_planned_verdict_fails(self):
        v = self.gate("compliant", ".notApplicable")
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any("branch_1: the witness declares not_applicable, the plan requires compliant" in d for d in v.details), v.details)
        v = self.gate("compliant", ".compliant")
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any(re.search(r"branch_1: .*expected compliant, got not_applicable", d) for d in v.details), v.details)


@unittest.skipUnless(TOOLCHAIN, SKIP)
class BoundaryTable(unittest.TestCase):
    """Every `#guard` of the fixture holds on real Lean; a fixture whose guard is falsified fails."""

    def run_fixture(self, text: str) -> tuple[int, str]:
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "fixture.lean"
            f.write_text(text, encoding="utf-8")
            return lean.run(["lake", "env", "lean", str(f)], paths.LIBRARY, 600)

    def test_the_boundaries_hold(self):
        code, out = self.run_fixture(FIXTURE.read_text(encoding="utf-8"))
        self.assertEqual(code, 0, out)
        self.assertNotIn("error", out)

    def test_a_falsified_guard_fails(self):
        text = FIXTURE.read_text(encoding="utf-8").replace(
            '#guard ok (sc "full" "short of the line" haltShort .notApplicable)', '#guard ok (sc "full" "short of the line" haltShort .violated)')
        code, out = self.run_fixture(text)
        self.assertNotEqual(code, 0)
        self.assertIn("did not evaluate to `true`", out)


if __name__ == "__main__":
    unittest.main()
