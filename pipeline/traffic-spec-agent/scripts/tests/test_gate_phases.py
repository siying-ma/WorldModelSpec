"""The gate harness in two phases. The witness phase prints everything up to and including the
witnesses; the gate's own checks, in their order and with their verdicts, judge those rows, and only
when none rejects is the adequacy phase run, within what the witness phase left of the deadline. A
witness phase stopped at its deadline is judged on the rows it printed: what they already decide is
that verdict, a witness that did not run is never counted as passed, and only what they leave
undecided is `GATE_TIMEOUT`, as is a stop in the adequacy phase, its details saying where the
evaluation was. The node and concept harnesses run on real Lean; those tests are skipped, and so
not verified, where the toolchain or the built Core is absent."""
import copy
import json
import re
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.lean import lean
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord, Node
from harness.model.reading import Reading
from harness.store import owner, paths
from scripts.tests import test_precondition_continuity as P

REAL_LIBRARY = paths.LIBRARY
TIMEOUT = "TIMEOUT: lake env lean --run /w/standalone.lean exceeded 900s"


class Ran:
    """The gate's toolchain step without writing into the library: the subject's two files and the
    gate's own harness program elaborated as one file against the built Core and run in the phase
    asked; `replay(phase, output)` rewrites an output before the gate reads it. `phases` lists the
    phases run."""

    def __init__(self, files: list[str], own_modules: set[str], replay=None):
        self.files, self.own, self.replay, self.phases = files, own_modules, replay, []

    def __call__(self, work: Path, targets, own, namespaces, harness: Path, register=None, phase="witnesses", timeout=gate.GATE_DEADLINE):
        self.phases.append(phase)
        imports, bodies = [], []
        for text in [(paths.LIBRARY / f).read_text() for f in self.files] + [harness.read_text()]:
            imp, body = P._split(text)
            imports += [i for i in imp if i not in self.own]
            bodies.append(body)
        f = work / "standalone.lean"
        f.write_text("\n".join(dict.fromkeys(imports)) + "\n" + "\n".join(bodies), encoding="utf-8")
        out = lean.lean_run(REAL_LIBRARY, f, timeout=timeout, args=() if phase == "witnesses" else (phase,))[1]
        return "", self.replay(phase, out) if self.replay else out


def _library(t: str) -> tuple[Path, Path, dict]:
    lib, work = Path(t) / "library", Path(t) / "work"
    work.mkdir()
    (work / "registry.json").write_text(json.dumps({"nodes": [], "concepts": []}))
    return lib, work, {"LIBRARY": lib, "RULES_DIR": lib / "TrafficSpec" / "Rules", "CONCEPTS_DIR": lib / "TrafficSpec" / "Concepts",
                       "WITNESS_DIR": lib / "TrafficSpecWitness", "CONCEPT_WITNESS_DIR": lib / "TrafficSpecWitness" / "Concepts"}


def _tags(out: str) -> list[str]:
    """The tag of every row and end line a harness printed, runs of `OCC`, `LITERAL`, `MANIFEST`
    and `WITNESS` collapsed to one."""
    tags = [l.split("\t", 1)[0] + (("\t" + l.split("\t")[1]) if l.startswith("TIME\t") else "")
            for l in out.splitlines() if "\t" in l or l.startswith("DONE")]
    return [t for i, t in enumerate(tags) if i == 0 or t != tags[i - 1] or t not in ("OCC", "LITERAL", "MANIFEST", "WITNESS")]


def stop_after(row: str, change: tuple[str, str] | None = None):
    """A replay of the witness phase stopped at the deadline just after `row` (a prefix of a line),
    with one line changed first."""
    def replay(phase: str, out: str) -> str:
        if phase != "witnesses":
            raise AssertionError("the adequacy phase must not run")
        if change:
            assert change[0] in out, change[0]
            out = out.replace(change[0], change[1])
        lines = out.splitlines()
        k = next(i for i, l in enumerate(lines) if l.startswith(row))
        return "\n".join([TIMEOUT] + lines[:k + 1]) + "\n"
    return replay


def stop_in_adequacy(phase: str, out: str) -> str:
    """A replay of the adequacy phase stopped at the deadline once the check began."""
    if phase == "witnesses":
        return out
    lines = out.splitlines()
    k = next(i for i, l in enumerate(lines) if l.startswith("TIME\tadequacy_start"))
    return "\n".join([TIMEOUT.replace("900s", "897s")] + lines[:k + 1]) + "\n"


def node_gate(planned: str = "not_applicable", declared: str = ".notApplicable", replay=None, rule: str = P.RULE,
              edit=None, concept: str | None = None, aggregates: list | None = None,
              accepted: dict | None = None, composed: str | None = None, params: list | None = None,
              acquisition: str | None = None) -> tuple[gate.Verdict, str, list[str]]:
    """The fixture node of `test_precondition_continuity` through the gate, its last witness planned
    `planned` and declared `declared`; `edit` changes the record; `concept` is the source of the
    concept `CID`, registered beside the node; `aggregates` the reading's; `accepted` the catalogue;
    `composed` the source of the accepted node `COMPOSED_ID`, registered beside it; `params` more
    reading parameters; `acquisition` the run's acquisition profile.
    Returns the verdict, the harness output the task directory keeps, and the phases run."""
    rec = copy.deepcopy(P.RECORD)
    rec["scenarios"][-1]["expected"] = planned
    if edit:
        edit(rec)
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.rule_path(P.NODE_ID), nodeid.witness_path(P.NODE_ID)]
        sources = [rule, P.WITNESS.replace("BRANCH", declared)]
        own = {f"import {nodeid.rule_module(P.NODE_ID)}", f"import {nodeid.witness_module(P.NODE_ID)}"}
        if concept is not None:
            files, sources = [nodeid.concept_path(CID)] + files, [concept] + sources
            own.add(f"import {nodeid.concept_module(CID)}")
            (work / "registry.json").write_text(json.dumps({"nodes": [], "concepts": [CID]}))
        if composed is not None:                           # an accepted node the rule composes, registered beside it
            files, sources = [nodeid.rule_path(COMPOSED_ID)] + files, [composed] + sources
            own.add(f"import {nodeid.rule_module(COMPOSED_ID)}")
            (work / "registry.json").write_text(json.dumps({"nodes": [COMPOSED_ID], "concepts": []}))
        for rel, src in zip(files, sources):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [
            {"name": "p.halt_window", "value": 3, "unit": "s", "convention": "fixture"},
            {"name": "p.crawl", "value": 3, "unit": "m/s", "convention": "fixture"}] + list(params or []), "aggregates": aggregates or []}))
        ran = Ran(files, own, replay)
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            v = gate.run_gate(Node(rec), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted_concepts=accepted or {},
                              acquisition=acquisition)
        return v, (work / "gate_harness.out").read_text(), ran.phases


# A neutral concept: the road user's measured speed is at or below a tolerance the caller gives.
CID = "drv.motion.gate_rest_test"
CONTRACT = "The road user's measured speed is at or below the tolerance the caller gives."
CONCEPT = f'''/- A neutral concept for the gate's phase check. -/
import TrafficSpec.Core.Language.Concept

namespace {nodeid.concept_namespace(CID)}

def aU : Arg := .var "u"
def body : Formula := .cmp (.measure "kin_speed" [aU]) .le (.param "tol")

def concept : Concept :=
  {{ id := "{CID}"
    contract := "{CONTRACT}"
    definition := none
    args := [("u", .track)]
    params := [⟨"tol", UNIT⟩]
    body := .formula body
    residues := []
    narrowings := []
    supersedes := none }}

end {nodeid.concept_namespace(CID)}
'''
CONCEPT_BODY = '.cmp (.measure "kin_speed" [aU]) .le (.param "tol")'
# The same concept reading an aggregate in a `cond` guard whose branches agree: its verdicts are
# those of the neutral body, whatever the membership. The id reaches the body through the literal
# formal `w`, which the caller fills: a form the gate run alone accepts, and holds against the
# reading and the claims, but no route for a planner, since planning refuses a literal formal whose
# values are aggregate ids (`literal_value_errors`). `HARD_BODY` writes the id into the body itself,
# which the concept gate refuses.
AID = "DEF-TST-1::wagon"
AGG_ARGS = f'[("u", .track), ("w", .literal ["{AID}"])]'
AGG_BODY = ('.cmp (.cond (.atom "ru_aggregate" [aU, .var "w"] []) (.measure "kin_speed" [aU]) '
            '(.measure "kin_speed" [aU])) .le (.param "tol")')
HARD_BODY = (f'.cmp (.cond (.atom "ru_aggregate" [aU, .lit "{AID}"] []) (.measure "kin_speed" [aU]) '
             '(.measure "kin_speed" [aU])) .le (.param "tol")')
AGG_DECLARED = [{"id": AID, "included": ["ru.motor_vehicle"]}]
HARD_CODED = (f"{CID}: the body names the definition-scoped aggregate `{AID}` itself (here or in a concept it calls with that id); "
              "a shared concept names no aggregate, since membership depends on the definitions that govern each calling law: "
              "where the contract leaves a member's class to the calling law, expose that road user as a track formal, and the "
              "calling law states its class with its own admitted aggregate")


def concept_source(body: str = CONCEPT_BODY, unit: str = ".metrePerSecond", args: str | None = None) -> str:
    src = CONCEPT.replace("UNIT", unit).replace(f"def body : Formula := {CONCEPT_BODY}", f"def body : Formula := {body}")
    return src if args is None else src.replace('args := [("u", .track)]', f"args := {args}")


CONCEPT_WITNESS = f'''/- Its witnesses: one vehicle on a straight lane, at rest or creeping at 1.5 m/s. -/
import {nodeid.concept_module(CID)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.concept_witness_namespace(CID)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def creep : Q := Units.micrometresPerSecond 1500000

def inst : Concept.Instance :=
  {{ name := "{CID}@w", concept := "{CID}", literals := [], nats := [],
    params := [("tol", .lit (Units.micrometresPerSecond 200000) .metrePerSecond)], bounds := none }}

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
  [ SCENARIOS ]

end {nodeid.concept_witness_namespace(CID)}
'''
HOLDS, FAILS, BLIND = 'witness "holds" (drive Q.zero) .compliant', 'witness "fails" (drive creep) .violated', \
    'witness "blind" (drive creep) (.unknown []) ["kin.speed"]'
CONCEPT_RECORD = {"concept_id": CID, "contract": CONTRACT, "kind": "formula", "args": [{"name": "u", "sort": "track"}],
                  "params": [{"name": "tol", "unit": "m/s"}], "elements": [{"span": "measured speed", "atoms": ["kin.speed"]}],
                  "residues": [], "literals": []}


def concept_gate(scenarios=(HOLDS, FAILS, BLIND), replay=None, unit: str = ".metrePerSecond", body: str = CONCEPT_BODY,
                 claims: tuple = (), aggregates: list | None = None, formal: bool = False,
                 callee: tuple[str, str, list[str]] | None = None) -> tuple[gate.Verdict, str, list[str]]:
    """The neutral concept through the gate with these witnesses, its formal's unit `unit`, its body
    `body`; `claims` are added to the record's element, `aggregates` are the reading's. `formal` gives
    the concept the literal formal `w` admitting `AID`, which its witness instance fills with `AID`;
    `callee` (id, source, the atoms its record reads) is an accepted concept registered beside it,
    which the record's element maps to."""
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.concept_path(CID), nodeid.concept_witness_path(CID)]
        witness = CONCEPT_WITNESS.replace("SCENARIOS", "\n  , ".join(scenarios))
        if formal:
            witness = witness.replace("literals := []", f'literals := [("w", "{AID}")]')
        sources = [concept_source(body, unit, AGG_ARGS if formal else None), witness]
        own = {f"import {nodeid.concept_module(CID)}", f"import {nodeid.concept_witness_module(CID)}"}
        accepted = {}
        if callee is not None:
            files, sources = [nodeid.concept_path(callee[0])] + files, [callee[1]] + sources
            own.add(f"import {nodeid.concept_module(callee[0])}")
            (work / "registry.json").write_text(json.dumps({"nodes": [], "concepts": [callee[0]]}))
            accepted = {callee[0]: {"reads": callee[2], "params": []}}
        for rel, src in zip(files, sources):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": aggregates or []}))
        record = copy.deepcopy(CONCEPT_RECORD)
        record["elements"][0]["atoms"] += list(claims)
        if formal:
            record["args"] = record["args"] + [{"name": "w", "sort": "literal", "values": [AID]}]
        if callee is not None:
            record["elements"][0]["concepts"] = [callee[0]]
        ran = Ran(files, own, replay)
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            v = gate.run_concept_gate(ConceptRecord(record), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted=accepted)
        return v, (work / "gate_harness.out").read_text(), ran.phases


# A callee that a concept calls on its road user: whether the road user is a member of the aggregate.
CALLEE = "drv.motion.gate_member_test"


def callee_source(hard: bool) -> str:
    """The callee: with `hard`, it names `AID` in its own body; else it reads the id its literal formal is given."""
    args, arg = ('[("u", .track)]', f'.lit "{AID}"') if hard else (f'[("u", .track), ("w", .literal ["{AID}"])]', '.var "w"')
    return f'''/- A callee for the gate's aggregate-context check. -/
import TrafficSpec.Core.Language.Concept

namespace {nodeid.concept_namespace(CALLEE)}

def concept : Concept :=
  {{ id := "{CALLEE}"
    contract := "The road user is a member of the aggregate."
    definition := none
    args := {args}
    params := []
    body := .formula (.atom "ru_aggregate" [.var "u", {arg}] [])
    residues := []
    narrowings := []
    supersedes := none }}

end {nodeid.concept_namespace(CALLEE)}
'''


def calling(actual: str) -> str:
    """A body that calls the callee in its `cond` guard, giving it `actual` beside the road user."""
    return (f'.cmp (.cond (.derived "{CALLEE.replace(".", "_")}" [aU{actual}] []) (.measure "kin_speed" [aU]) '
            '(.measure "kin_speed" [aU])) .le (.param "tol")')


# A node whose obligation is the aggregate-reading concept with the tolerance `p.crawl`: the
# fixture's own obligation, read through the concept.
AGG_RULE = P.RULE.replace('def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")',
                          f'def obligation : Formula := .derived "drv_motion_gate_rest_test" [vV, .lit "{AID}"] [.param "p.crawl"]')
AGG_ACCEPTED = {CID: {"reads": ["kin.speed", "ru.aggregate"], "params": [{"name": "tol", "unit": "m/s"}]}}


# An accepted node whose obligation is that its vehicle is a member of `AID`, and a caller that
# composes it in a `cond` guard whose branches agree (the fixture's obligation, whatever the verdict
# of the composed rule).
COMPOSED_ID = "TEST_AGGREAD_9"
COMPOSED_RULE = f'''/- A composed node reading an aggregate. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(COMPOSED_ID)}

def rule : Rule :=
  {{ id := "{COMPOSED_ID}"
    laws := ["TEST-AGGREAD-9"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [.var "v"] [] }} ]
    applicability := .tt
    obligation := .atom "ru_aggregate" [.var "v", .lit "{AID}"] [] }}

end {nodeid.rule_namespace(COMPOSED_ID)}
'''
COMPOSING_RULE = P.RULE.replace('def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")',
                                f'def obligation : Formula := .cmp (.cond (.rule "{COMPOSED_ID}" [("v", "v")]) (.measure "kin_speed" [vV]) '
                                '(.measure "kin_speed" [vV])) .le (.param "p.crawl")')


def calls_concept(*claims: str):
    """The record edit: the obligation's span maps to the concept, with these claims beside it."""
    def edit(rec: dict) -> None:
        e = next(e for e in rec["elements"] if e["span"] == "o1")
        e["derived"] = [CID]
        e["atoms"] = list(e["atoms"]) + list(claims)
    return edit


WITNESSES_ONLY = ["witnesses"]
BOTH = ["witnesses", "adequacy"]


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class NodeHarness(unittest.TestCase):

    def test_the_success_path(self):
        v, out, phases = node_gate()
        self.assertEqual((v.verdict, phases), ("OK", BOTH), v.details)
        scen = [t for n in ("forbid", "permit", "idle", "blind", "branch_1") for t in ("SCEN", f"TIME\tscenario:{n}")]
        self.assertEqual(_tags(out), ["DECL", "RULEJSON", "RULEXJSON", "ATOMS", "COMPOSES", "AGGREGATES", "MANIFEST", "OCC",
                                      "TIME\toccurrences", "TIME\tchecks", "TIME\tlint"] + scen + ["TIME\twitnesses", "DONE_WITNESSES",
                                      "ADEQ_SIZE", "TIME\tadequacy_start", "TIME\tadequacy", "DONE"])
        self.assertIn(f"ADEQ_SIZE\t{P.NODE_ID}\t6\t4\n", out)       # six leaves; four witnesses expect a decided verdict

    def test_a_witness_failing_in_the_harness_ends_before_adequacy(self):
        v, out, phases = node_gate("compliant", ".compliant")
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertTrue(any(re.search(r"branch_1: .*expected compliant, got not_applicable", d) for d in v.details), v.details)
        self.assertNotIn("ADEQ", out)

    def test_a_witness_the_plan_rejects_ends_before_adequacy(self):
        v, _out, phases = node_gate("compliant", ".notApplicable")
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("branch_1: the witness declares not_applicable, the plan requires compliant", v.details)

    def test_a_missing_witness_ends_before_adequacy(self):
        v, _out, phases = node_gate(edit=lambda rec: rec["scenarios"].append({"name": "branch_2", "expected": "violated"}))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("branch_2: no witness of that name", v.details)

    def test_a_blind_manifest_mismatch_ends_before_adequacy(self):
        v, _out, phases = node_gate(edit=lambda rec: rec["scenarios"][3].update(masked=["st.lane"]))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("blind: the manifest masks ['st.entrance_of'], the node masks ['st.lane']", v.details)

    def test_a_static_error_keeps_its_verdict_over_a_failing_witness(self):
        rule = P.RULE.replace('def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")',
                              'def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.halt_window")')
        v, out, phases = node_gate("compliant", ".compliant", rule=rule)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("\nDIM\t", out)
        self.assertRegex(out, r"\nSCEN\tbranch_1\tcompliant\t\?")              # the witness failed too

    def test_an_aggregate_named_inside_a_term_is_held_against_the_reading(self):
        rule = P.RULE.replace('def obligation : Formula := .cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")',
                              'def obligation : Formula := .cmp (.cond (.atom "ru_aggregate" [vV, .lit "DEF-TST-1::wagon"] []) '
                              '(.measure "kin_speed" [vV]) (.measure "kin_speed" [vV])) .le (.param "p.crawl")')
        v, out, phases = node_gate(rule=rule)
        self.assertIn("\nAGGREGATES\tDEF-TST-1::wagon\n", out)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn(f"{P.NODE_ID}: aggregate `DEF-TST-1::wagon` is not declared by the reading", v.details)

    def test_an_undeclared_aggregate_read_through_a_concept_is_refused(self):
        v, out, phases = node_gate(rule=AGG_RULE, concept=concept_source(AGG_BODY, args=AGG_ARGS), edit=calls_concept(f"ru.aggregate={AID}"),
                                   accepted=AGG_ACCEPTED)
        self.assertIn(f"\nAGGREGATES\t{AID}\n", out)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn(f"{P.NODE_ID}: aggregate `{AID}` is not declared by the reading", v.details)

    def test_a_declared_aggregate_read_through_a_concept_and_not_claimed_is_refused(self):
        v, _out, phases = node_gate(rule=AGG_RULE, concept=concept_source(AGG_BODY, args=AGG_ARGS), edit=calls_concept(),
                                    aggregates=AGG_DECLARED, accepted=AGG_ACCEPTED)
        self.assertEqual((v.verdict, phases), ("UNCLAIMED_ATOM", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details, [f'ru_aggregate "{AID}" (the record claims no aggregate)'])

    def test_an_admitted_and_claimed_aggregate_read_through_a_concept_passes(self):
        v, out, phases = node_gate(rule=AGG_RULE, concept=concept_source(AGG_BODY, args=AGG_ARGS), edit=calls_concept(f"ru.aggregate={AID}"),
                                   aggregates=AGG_DECLARED, accepted=AGG_ACCEPTED)
        self.assertIn(f"\nAGGREGATES\t{AID}\n", out)
        self.assertEqual((v.verdict, phases), ("OK", BOTH), v.details)

    def test_an_id_the_caller_gives_is_held_against_the_callers_reading(self):
        v, out, phases = node_gate(rule=AGG_RULE, concept=concept_source(AGG_BODY, args=AGG_ARGS), edit=calls_concept(f"ru.aggregate={AID}"),
                                   aggregates=[{"id": "DEF-TST-1::cart", "included": ["ru.motor_vehicle"]}], accepted=AGG_ACCEPTED)
        self.assertIn(f"\nAGGREGATES\t{AID}\n", out)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn(f"{P.NODE_ID}: aggregate `{AID}` is not declared by the reading", v.details)

    # A composed node claims the aggregates it reads; its caller does not claim them again, and the
    # reading check still covers the whole composition closure.
    def test_a_composed_nodes_aggregate_is_not_claimed_again_by_its_caller(self):
        v, out, phases = node_gate(rule=COMPOSING_RULE, composed=COMPOSED_RULE, aggregates=AGG_DECLARED)
        self.assertIn("\nAGGREGATES\t\n", out)
        self.assertEqual((v.verdict, phases), ("OK", BOTH), v.details)

    def test_a_composed_nodes_undeclared_aggregate_is_refused_to_its_caller(self):
        v, _out, phases = node_gate(rule=COMPOSING_RULE, composed=COMPOSED_RULE)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn(f"{COMPOSED_ID}: aggregate `{AID}` is not declared by the reading", v.details)

    def test_a_witness_that_failed_before_the_deadline_is_a_witness_failure(self):
        v, _out, phases = node_gate(replay=stop_after("TIME\tscenario:permit", ("SCEN\tpermit\tcompliant\tcompliant\tok",
                                                                                 "SCEN\tpermit\tcompliant\tviolated\tok")))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details, ["permit: expected compliant, got violated",
                                     "the evaluation was stopped at its deadline; the rows printed before it decide this verdict; "
                                     "not run, never counted as passed: idle, blind, branch_1"])

    def test_a_deadline_in_the_witnesses_with_none_failed_is_a_timeout(self):
        v, _out, phases = node_gate(replay=stop_after("TIME\tscenario:permit"))
        self.assertEqual((v.verdict, phases), ("GATE_TIMEOUT", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details[0], TIMEOUT)
        self.assertEqual(v.details[1], "the evaluation was stopped in the witnesses, after 2 had finished")
        self.assertRegex(v.details[2], r"^2 witness\(es\) passed and 0 did not; the 2 that finished took ")
        self.assertEqual(v.details[3], "not run: idle, blind, branch_1")

    def test_a_deadline_in_the_adequacy_phase_is_a_timeout(self):
        v, _out, phases = node_gate(replay=stop_in_adequacy)
        self.assertEqual((v.verdict, phases), ("GATE_TIMEOUT", BOTH), v.details)
        self.assertEqual(v.details[0], TIMEOUT.replace("900s", "897s"))
        self.assertRegex(v.details[1], r"^the witness phase took \d+ s of the 900 s deadline; the adequacy phase had the \d+ s left$")
        self.assertEqual(v.details[2], "the evaluation was stopped in the adequacy check")
        self.assertRegex(v.details[3], r"^5 witness\(es\) passed and 0 did not")
        self.assertRegex(v.details[4], rf"^the adequacy check began [\d.]+ s after the adequacy phase's program started and did not finish: "
                                       rf"`{P.NODE_ID}` has 6 leaves, each replaced by true and by false and judged on its 4 decided witness\(es\)$")


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class ConceptHarness(unittest.TestCase):

    def test_the_success_path(self):
        v, out, phases = concept_gate()
        self.assertEqual((v.verdict, phases), ("OK", BOTH), v.details)
        scen = [t for n in ("holds", "fails", "blind") for t in ("SCEN", f"TIME\tscenario:{CID}@w/{n}")]
        self.assertEqual(_tags(out), ["DECL", "ATOMS", "READS", "AGGREGATES", "HARDAGG", "BODY", "WITNESS", "OCC", "INST", "TIME\tchecks", "TIME\tlint"] + scen
                         + ["TIME\twitnesses", "DONE_WITNESSES", "ADEQ_SIZE", "TIME\tadequacy_start", "TIME\tadequacy", "DONE"])
        self.assertIn(f"ADEQ_SIZE\t{CID}@w\t1\t2\n", out)

    def test_a_witness_failing_in_the_harness_ends_before_adequacy(self):
        v, out, phases = concept_gate((HOLDS, FAILS.replace(".violated", ".compliant"), BLIND))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertTrue(any(d.startswith("fails:") for d in v.details), v.details)
        self.assertNotIn("ADEQ", out)

    def test_a_witness_the_record_rejects_ends_before_adequacy(self):
        v, _out, phases = concept_gate(('witness "holds" (drive creep) .violated', FAILS, BLIND))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("holds: the witness declares violated, the record requires compliant", v.details)

    def test_a_missing_witness_ends_before_adequacy(self):
        v, _out, phases = concept_gate((HOLDS, FAILS))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("blind: no witness of that name", v.details)

    def test_a_static_error_keeps_its_verdict_over_a_failing_witness(self):
        v, out, phases = concept_gate((HOLDS, FAILS.replace(".violated", ".compliant"), BLIND), unit=".metre")
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn("\nDIM\t", out)
        self.assertRegex(out, r"\nSCEN\tfails\t\S+\tcompliant\t\?")

    def test_an_undeclared_aggregate_in_the_body_is_refused(self):
        v, out, phases = concept_gate(body=AGG_BODY, claims=(f"ru.aggregate={AID}",), formal=True)
        self.assertIn(f"\nAGGREGATES\t{AID}\n", out)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertIn(f"{CID}: aggregate `{AID}` is not declared by the reading", v.details)

    def test_a_declared_aggregate_in_the_body_not_claimed_by_its_id_is_refused(self):
        v, _out, phases = concept_gate(body=AGG_BODY, claims=("ru.aggregate",), aggregates=AGG_DECLARED, formal=True)
        self.assertEqual((v.verdict, phases), ("UNCLAIMED_ATOM", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details, [f'ru_aggregate "{AID}" (the record claims no aggregate)'])

    def test_an_admitted_and_claimed_aggregate_in_the_body_passes(self):
        v, out, phases = concept_gate(body=AGG_BODY, claims=(f"ru.aggregate={AID}",), aggregates=AGG_DECLARED, formal=True)
        self.assertIn(f"\nAGGREGATES\t{AID}\n", out)
        self.assertIn("\nHARDAGG\t\n", out)                      # the id comes through the formal
        self.assertEqual((v.verdict, phases), ("OK", BOTH), v.details)

    # A shared concept that writes a definition-scoped aggregate id into its body would apply that
    # membership to every law that calls it, whatever definition governs that law: refused, however
    # well the run's reading admits the id and the record claims it.
    def test_an_aggregate_id_written_into_the_body_is_refused_though_admitted_and_claimed(self):
        v, out, phases = concept_gate(body=HARD_BODY, claims=(f"ru.aggregate={AID}",), aggregates=AGG_DECLARED)
        self.assertIn(f"\nHARDAGG\t{AID}\n", out)
        self.assertEqual((v.verdict, phases), ("CHECK_FAIL", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details, [HARD_CODED])

    def test_an_aggregate_id_written_into_the_body_beside_a_formal_is_refused(self):
        v, _out, _phases = concept_gate(body=HARD_BODY, claims=(f"ru.aggregate={AID}",), aggregates=AGG_DECLARED, formal=True)
        self.assertEqual(v.verdict, "CHECK_FAIL", v.details)
        self.assertIn(HARD_CODED, v.details)

    def test_an_id_given_to_a_callee_as_a_literal_is_refused(self):
        v, out, _phases = concept_gate(body=calling(f', .lit "{AID}"'), claims=(f"ru.aggregate={AID}",), aggregates=AGG_DECLARED,
                                       callee=(CALLEE, callee_source(hard=False), ["ru.aggregate"]))
        self.assertIn(f"\nHARDAGG\t{AID}\n", out)
        self.assertEqual((v.verdict, v.details), ("CHECK_FAIL", [HARD_CODED]))

    def test_a_callee_that_names_the_id_itself_makes_its_caller_refused(self):
        v, _out, _phases = concept_gate(body=calling(""), claims=(f"ru.aggregate={AID}",), aggregates=AGG_DECLARED,
                                        callee=(CALLEE, callee_source(hard=True), ["ru.aggregate"]))
        self.assertEqual((v.verdict, v.details), ("CHECK_FAIL", [HARD_CODED]))

    def test_a_formal_forwarded_to_a_callee_passes(self):
        v, out, phases = concept_gate(body=calling(', .var "w"'), claims=(f"ru.aggregate={AID}",), aggregates=AGG_DECLARED, formal=True,
                                      callee=(CALLEE, callee_source(hard=False), ["ru.aggregate"]))
        self.assertIn(f"\nAGGREGATES\t{AID}\n", out)
        self.assertIn("\nHARDAGG\t\n", out)
        self.assertEqual((v.verdict, phases), ("OK", BOTH), v.details)

    def test_a_witness_that_failed_before_the_deadline_is_a_witness_failure(self):
        v, _out, phases = concept_gate(replay=stop_after(f"TIME\tscenario:{CID}@w/holds", (f"SCEN\tholds\t{CID}@w\tcompliant\tcompliant\tok",
                                                                                            f"SCEN\tholds\t{CID}@w\tcompliant\tviolated\tok")))
        self.assertEqual((v.verdict, phases), ("WITNESS_FAIL", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details, ["holds: expected compliant, got violated",
                                     "the evaluation was stopped at its deadline; the rows printed before it decide this verdict; "
                                     f"not run, never counted as passed: fails ({CID}@w), blind ({CID}@w)"])

    def test_a_deadline_in_the_witnesses_with_none_failed_is_a_timeout(self):
        v, _out, phases = concept_gate(replay=stop_after(f"TIME\tscenario:{CID}@w/holds"))
        self.assertEqual((v.verdict, phases), ("GATE_TIMEOUT", WITNESSES_ONLY), v.details)
        self.assertEqual(v.details[1], "the evaluation was stopped in the witnesses, after 1 had finished")
        self.assertEqual(v.details[3], f"not run: fails ({CID}@w), blind ({CID}@w)")

    def test_a_deadline_in_the_adequacy_phase_is_a_timeout(self):
        v, _out, phases = concept_gate(replay=stop_in_adequacy)
        self.assertEqual((v.verdict, phases), ("GATE_TIMEOUT", BOTH), v.details)
        self.assertEqual(v.details[2], "the evaluation was stopped in the adequacy check")
        self.assertRegex(v.details[4], rf"`{CID}@w` has 1 leaves, each replaced by true and by false and judged on its 2 decided witness\(es\)$")


class TheGeneratedHarnesses(unittest.TestCase):
    """One program per subject: the witness phase without an argument, the adequacy phase with
    `adequacy`; a concept's supersession check belongs to the witness phase."""

    def test_the_phases(self):
        node = gate._harness_source("L_1", Path("/r.json"), ("", ""))
        concept = gate._concept_harness_source("drv.motion.halted_a", Path("/r.json"), ("", ""))
        for src in (node, concept):
            self.assertIn("def main (args : List String) : IO Unit := do", src)
            branch = src.index('if args == ["adequacy"] then')
            self.assertLess(branch, src.index("Adequacy.unexercised"))
            self.assertLess(src.index("Adequacy.unexercised"), src.index('IO.println "DONE"\n    return'))
            self.assertLess(src.index('IO.println "DONE"\n    return'), src.index("SCEN\\t"))
            self.assertTrue(src.rstrip().endswith('IO.println "DONE_WITNESSES"'))
        self.assertLess(concept.index("TIME\\twitnesses"), concept.index("DIFF\\t"))


class SharedDeadline(unittest.TestCase):
    """The adequacy phase runs with what the witness phase left of the deadline."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.work = Path(self.tmp.name)
        self.asked = []

    def tearDown(self):
        self.tmp.cleanup()

    def spent(self, seconds: float):
        with open(self.work / "toolchain.jsonl", "a") as f:
            f.write(json.dumps({"phase": "build", "seconds": 300.0}) + "\n")
            f.write(json.dumps({"phase": "harness", "seconds": seconds}) + "\n")

    def toolchain(self, **k):
        self.asked.append(k)
        return "", "ADEQ_SIZE\tL_1\t3\t2\nDONE\n"

    def test_the_rest_of_the_deadline(self):
        self.spent(850.0)
        self.assertEqual(gate.adequacy_phase(self.work, self.toolchain, "DONE_WITNESSES\n"), "ADEQ_SIZE\tL_1\t3\t2\nDONE\n")
        self.assertEqual(self.asked, [{"phase": "adequacy", "timeout": 50.0}])
        self.assertTrue((self.work / "gate_harness.out").read_text().endswith("DONE\n"))

    def test_nothing_left(self):
        self.spent(900.0)
        v = gate.adequacy_phase(self.work, self.toolchain, "TIME\tchecks\t1\nTIME\tlint\t1\nTIME\twitnesses\t899000\nDONE_WITNESSES\n")
        self.assertEqual(v.verdict, gate.GATE_TIMEOUT)
        self.assertEqual(v.details[0], "the witness phase took 900 s of the 900 s deadline; none was left for the adequacy check")
        self.assertEqual(self.asked, [])


class AdequacyPhaseToolchain(unittest.TestCase):
    """The adequacy phase's run: no build, the phase's argument and deadline, and the resource-failure
    rerun in isolation as for the witness phase."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.work = Path(self.tmp.name) / "task"; self.work.mkdir()
        self.saved = (paths.LIBRARY, lean.lake_build, lean.lean_run)
        paths.LIBRARY = Path(self.tmp.name)
        lean.lake_build = lambda *a, **k: (_ for _ in ()).throw(AssertionError("the adequacy phase does not build"))

    def tearDown(self):
        paths.LIBRARY, lean.lake_build, lean.lean_run = self.saved
        owner.STOP.clear()
        self.tmp.cleanup()

    def run_with(self, *runs):
        runs, self.calls = list(runs), []

        def run(lib, f, timeout=None, args=()):
            self.calls.append((timeout, args))
            return runs.pop(0)
        lean.lean_run = run
        return gate._toolchain(self.work, ["T"], set(), ("X.",), self.work / "gate_harness.lean", phase="adequacy", timeout=42.0)

    def test_the_argument_and_the_deadline(self):
        self.assertEqual(self.run_with((0, "ADEQ_SIZE\tL\t1\t1\nDONE")), ("", "ADEQ_SIZE\tL\t1\t1\nDONE"))
        self.assertEqual(self.calls, [(42.0, ("adequacy",))])
        rows = [json.loads(l) for l in (self.work / "toolchain.jsonl").read_text().splitlines()]
        self.assertEqual([r["phase"] for r in rows if "seconds" in r], ["harness_adequacy"])

    def test_a_resource_failure_is_reproduced_once(self):
        killed = (-9, "ADEQ_SIZE\tL\t1\t1")
        self.assertEqual(self.run_with(killed, (0, "DONE")), ("", "DONE"))
        v = self.run_with(killed, killed)
        self.assertEqual(v.verdict, gate.GATE_TIMEOUT)
        self.assertEqual(len(self.calls), 2)

    def test_a_deadline_before_any_row_is_the_gates_to_classify(self):
        late = (124, "TIMEOUT: lake env lean exceeded 3s")
        self.assertEqual(self.run_with(late), ("", late[1]))


NODE_ROWS = [TIMEOUT, "DECL\t{}", "RULEJSON\t{}", "ATOMS\tkin_speed", "MANIFEST\tforbid\t", "MANIFEST\tpermit\t", "MANIFEST\tidle\t",
             "TIME\toccurrences\t1", "TIME\tchecks\t40", "TIME\tlint\t300"]


class TimeoutDetails(unittest.TestCase):
    """What a harness stopped at its deadline had printed, as the timeout's details."""

    def test_a_stop_in_the_witnesses(self):
        rows = NODE_ROWS + ["SCEN\tforbid\tviolated\tviolated\tok", "TIME\tscenario:forbid\t1200",
                            "SCEN\tpermit\tcompliant\tcompliant\tok", "TIME\tscenario:permit\t2500"]
        v = gate.harness_failure("\n".join(rows) + "\n")
        self.assertEqual(v.verdict, gate.GATE_TIMEOUT)
        self.assertEqual(v.details, [TIMEOUT, "the evaluation was stopped in the witnesses, after 2 had finished",
                                     "2 witness(es) passed and 0 did not; the 2 that finished took 3.7 s in all, the slowest `permit` 2.5 s",
                                     "not run: idle"])
        self.assertFalse(any("window operator" in d or "quantifier" in d for d in v.details))

    def test_a_stop_in_the_static_checks(self):
        v = gate.harness_failure("\n".join(NODE_ROWS[:8]) + "\n")
        self.assertEqual(v.details[1:3], ["the evaluation was stopped in the static checks",
                                          "0 witness(es) passed and 0 did not; the 0 that finished took 0.0 s"])

    def test_a_concept_stop_in_the_supersession_check(self):
        rows = [TIMEOUT, "DECL\t{}", "WITNESS\tholds\tc@w", "TIME\tchecks\t20", "TIME\tlint\t30",
                "SCEN\tholds\tc@w\tcompliant\tcompliant\tok", "TIME\tscenario:c@w/holds\t400", "TIME\twitnesses\t401"]
        v = gate.harness_failure("\n".join(rows) + "\n")
        self.assertEqual(v.details[1:], ["the evaluation was stopped in the supersession check",
                                         "1 witness(es) passed and 0 did not; the 1 that finished took 0.4 s in all, the slowest `c@w/holds` 0.4 s"])

    def test_a_stop_in_adequacy_gives_its_start_and_input_only(self):
        rows = [TIMEOUT, "DECL\t{}", "TIME\tchecks\t20", "TIME\tlint\t30", "SCEN\tholds\tc@w\tcompliant\tcompliant\tok",
                "TIME\tscenario:c@w/holds\t400", "TIME\twitnesses\t401", "DONE_WITNESSES",
                "ADEQ_SIZE\tc@w\t40\t2", "ADEQ_SIZE\tc@v\t12\t2", "TIME\tadequacy_start\t1100"]
        v = gate.harness_failure("\n".join(rows) + "\n")
        self.assertEqual(v.details[1], "the evaluation was stopped in the adequacy check")
        self.assertEqual(v.details[-1], "the adequacy check began 1.1 s after the adequacy phase's program started and did not finish: "
                                        "`c@w` has 40 leaves, each replaced by true and by false and judged on its 2 decided witness(es); "
                                        "`c@v` has 12 leaves, each replaced by true and by false and judged on its 2 decided witness(es)")


# ── The concept interface: what a caller can state about what a concept denotes ─────────────────
#
# A file of road users: the concept below counts every road user of the scene that keeps in file
# with `u`, of whatever class; the same relation for one pair, whose caller counts and states the
# class; a concept whose contract itself fixes the full range of its quantifier; and a caller
# that moves that quantifier across a window.

FILE_LANE = '''def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- One east-bound lane, x in [-50 m, 500 m], y in [-2 m, 2 m]. -/
def theLane : Structure :=
  Build.lane 1 [(m (-50), m (-2)), (m 500, m (-2)), (m 500, m 2), (m (-50), m 2)] Build.east
    (ordinal := some 1) (count := some 1)

/-- A car on the lane centre line, `x0` at the first observation, advancing 20 m per observation. -/
def car (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + 20 * Int.ofNat k), m 0) Build.east
    (Units.metresPerSecond 20) (cm 250, m 1, cm 75) (some (m (20 * Int.ofNat k)))

/-- A bicycle on the lane centre line, advancing as the cars do. -/
def bike (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.user track [.bicycle] (m (x0 + 20 * Int.ofNat k), m 0) Build.east
    (Units.metresPerSecond 20) (cm 100, cm 30, cm 75) (some (m (20 * Int.ofNat k)))

def scene3 (users : Nat → List RoadUser) (regions : List Structure := [theLane]) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => Build.scene t (some 1) (users k) regions [ ]

/-- Five cars in file, 20 m between neighbouring bodies. -/
def fiveCars : Trace := scene3 fun k => [ car 1 0 k, car 2 25 k, car 3 50 k, car 4 75 k, car 5 100 k ]
/-- A car with the nearest other road user 395 m ahead. -/
def lonely : Trace := scene3 fun k => [ car 1 0 k, car 2 400 k ]
/-- A car with two bicycles in file ahead of it, 18 m and 19 m between the bodies. -/
def carAndBikes : Trace := scene3 fun k => [ car 1 0 k, bike 2 22 k, bike 3 43 k ]

/-- The five cars, their extents unobserved and the gap between the bodies measured by the source. -/
def gaugedCar (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.withKin (car track x0 k) fun kin => { kin with extent := none }
def gauged : List (TrackId × Int) := [(2, 20), (3, 45), (4, 70), (5, 95)]
def gaugedRelations : List MeasuredRelation :=
  gauged.flatMap fun (v, g) =>
    [ Build.relation 1 v fun r => { r with surfaceGap := some (m g, m 0), aAheadOfB := some false }
    , Build.relation v 1 fun r => { r with aAheadOfB := some true } ]
def gaugedCars : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ gaugedCar 1 0 k, gaugedCar 2 25 k, gaugedCar 3 50 k, gaugedCar 4 75 k, gaugedCar 5 100 k ] [ theLane ] [ ]
    { s with occupancyObserved := [], occupies := [], relations := gaugedRelations }
'''


def file_witness(cid: str, params: str, grounding: str, scenarios: list[str], extra: str = "") -> str:
    """A concept's witness file over the file-of-road-users scenes."""
    return f'''/- Witnesses over one lane. -/
import {nodeid.concept_module(cid)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.concept_witness_namespace(cid)}

open TrafficSpec

{FILE_LANE}
{extra}
def inst : Concept.Instance :=
  {{ name := "{cid}@w", concept := "{cid}", literals := [], nats := [], params := [{params}], bounds := none }}

def instances : List Concept.Instance := [inst]

def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := inst.name, trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := {grounding}, expected := expected }}

def scenarios : List Scenario :=
  [ {"""
  , """.join(scenarios)} ]

end {nodeid.concept_witness_namespace(cid)}
'''


def file_concept(cid: str, contract: str, args: str, params: str, defs: str) -> str:
    return f'''/- A concept over a file of road users. -/
import TrafficSpec.Core.Language.Concept

namespace {nodeid.concept_namespace(cid)}

def aU : Arg := .var "u"
def aV : Arg := .var "v"
{defs}
def concept : Concept :=
  {{ id := "{cid}"
    contract := "{contract}"
    definition := none
    args := {args}
    params := {params}
    body := .formula body
    residues := []
    narrowings := []
    supersedes := none }}

end {nodeid.concept_namespace(cid)}
'''


IN_FILE_DEFS = '''def pFileReach : Term := .param "file_reach"
def pSameDirectionTolerance : Term := .param "same_direction_tolerance"
def aheadOrBehind : Formula :=
  .or (.atom "rel_ahead_behind_in_lane" [aV, aU] []) (.atom "rel_ahead_behind_in_lane" [aU, aV] [])
def withinReach : Formula := .cmp (.measure "rel_surface_gap" [aU, aV]) .le pFileReach
def inFile : Formula :=
  .and (.atom "rel_same_direction" [aV, aU] [pSameDirectionTolerance]) (.and aheadOrBehind withinReach)
'''
FILE_PARAMS = '("file_reach", .lit (m 50) .metre), ("same_direction_tolerance", .lit (Units.ratio 95 100) .ratio)'
FILE_ELEMENTS = [
    {"span": "heading aligned with u's within the same-direction tolerance", "atoms": ["rel.same_direction"], "concepts": [],
     "justification": "the headings' cosine above the tolerance"},
    {"span": "ahead of or behind u in the same lane", "atoms": ["rel.ahead_behind_in_lane"], "concepts": [],
     "justification": "one road user ahead of the other along the lane they share"},
    {"span": "within the file reach of u, a distance the caller sets measured between the nearest points of the bodies",
     "atoms": ["rel.surface_gap"], "concepts": [], "justification": "the distance between the nearest points of two bodies"}]
REACH_PARAMS = [{"name": "file_reach", "unit": "m", "meaning": "the largest distance between the nearest points of two bodies in one file"},
                {"name": "same_direction_tolerance", "unit": "ratio", "meaning": "the cosine of the largest angle between headings read as one direction"}]
FILE_BLIND = 'witness "blind" gaugedCars (.unknown []) ["rel.surface_gap"]'
FILE_BLIND_SCENARIO = {"name": "blind", "expected": "unknown", "narrative": "the gap between the bodies unobserved", "masked": ["rel.surface_gap"]}

# A file counted inside the concept, over every road user, with no formal for the members' class,
# while its contract leaves that class to the caller.
VEHICLE_FILE = "drv.interaction.vehicle_file"
VEHICLE_FILE_CONTRACT = (
    "Road user u is one of a file of road users travelling one behind another at the observation: counting u itself, at least the minimum "
    "member count of road users have their heading aligned with u's within the same-direction tolerance, lie ahead of or behind u in the "
    "same lane, and are within the file reach of u, a distance the caller sets measured between the nearest points of the bodies. It is a "
    "relation of place, direction and spacing at the observation. It says nothing of why the road users travel together, of a common "
    "destination or origin, of an organizer, or of their speed: a caller that means a moving file states the motion itself. Not a stand-in "
    "for: a chain each of whose consecutive spaces is bounded — the reach is measured from u to each member, so a long file is read through "
    "the membership of each road user in turn — the class of the members, which the caller states, or a towed combination, which is one road "
    "user drawn by another.")
VEHICLE_FILE_SOURCE = file_concept(
    VEHICLE_FILE, VEHICLE_FILE_CONTRACT, '[("u", .track)]',
    '[⟨"min_member_count", .count⟩, ⟨"file_reach", .metre⟩, ⟨"same_direction_tolerance", .ratio⟩]',
    IN_FILE_DEFS + '''def pMinMemberCount : Term := .param "min_member_count"
def body : Formula :=
  .cmp (.aggregate .count "v" (.or (.same aV aU) inFile) (.lit Q.zero .count)) .ge pMinMemberCount
''')
VEHICLE_FILE_RECORD = {
    "concept_id": VEHICLE_FILE, "kind": "formula", "contract": VEHICLE_FILE_CONTRACT, "args": [{"name": "u", "sort": "track"}],
    "params": [{"name": "min_member_count", "unit": "count", "meaning": "the number of road users, u included, read as a file"}] + REACH_PARAMS,
    "elements": FILE_ELEMENTS, "residues": [], "literals": [], "used_by": [],
    "scenarios": [{"name": "holds", "expected": "compliant", "narrative": "five cars in file, 20 m between neighbours"},
                  {"name": "fails", "expected": "violated", "narrative": "one car alone, the nearest other road user 395 m ahead"},
                  FILE_BLIND_SCENARIO]}


def vehicle_file_witness(fails: str) -> str:
    return file_witness(VEHICLE_FILE, '("min_member_count", .lit (Q.ofInt 3) .count), ' + FILE_PARAMS,
                        '[("u", 1)]', ['witness "holds" fiveCars .compliant', f'witness "fails" {fails} .violated', FILE_BLIND])


# The pair relation: the concept states whether `v` keeps in file with `u` at the observation; a
# caller counts the road users `w` of which it holds, of the class its own admitted aggregate states.
FILE_PAIR = "drv.interaction.file_pair"
FILE_PAIR_CONTRACT = (
    "Road user v travels in one file with road user u at the observation: v's heading is aligned with u's within the same-direction "
    "tolerance, v lies ahead of or behind u in the same lane, and v is within the file reach of u, a distance the caller sets measured "
    "between the nearest points of the bodies. It is a relation of place, direction and spacing between the two road users at the "
    "observation; how many road users make a file, and of which class, is stated by a caller that counts the road users v of which it holds.")
FILE_PAIR_SOURCE = file_concept(FILE_PAIR, FILE_PAIR_CONTRACT, '[("u", .track), ("v", .track)]',
                                '[⟨"file_reach", .metre⟩, ⟨"same_direction_tolerance", .ratio⟩]',
                                IN_FILE_DEFS + "def body : Formula := inFile\n")
FILE_PAIR_RECORD = {
    "concept_id": FILE_PAIR, "kind": "formula", "contract": FILE_PAIR_CONTRACT,
    "args": [{"name": "u", "sort": "track"}, {"name": "v", "sort": "track"}], "params": REACH_PARAMS,
    "elements": [dict(e, span=w) for e, w in zip(FILE_ELEMENTS, ("v's heading is aligned with u's within the same-direction tolerance",
                                                                  "v lies ahead of or behind u in the same lane", FILE_ELEMENTS[2]["span"]))], "residues": [], "literals": [],
    "scenarios": [{"name": "holds", "expected": "compliant", "narrative": "car v 20 m behind car u in the lane"},
                  {"name": "fails", "expected": "violated", "narrative": "car v 10 m ahead of car u, in the lane beside it"},
                  FILE_BLIND_SCENARIO]}
FILE_PAIR_EXTRA = '''/-- A second east-bound lane beside the first, y in [2 m, 6 m], and a car on its centre line. -/
def otherLane : Structure :=
  Build.lane 2 [(m (-50), m 2), (m 500, m 2), (m 500, m 6), (m (-50), m 6)] Build.east (ordinal := some 2) (count := some 2)
def carBeside (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + 20 * Int.ofNat k), m 4) Build.east
    (Units.metresPerSecond 20) (cm 250, m 1, cm 75) (some (m (20 * Int.ofNat k)))
def behind : Trace := scene3 (fun k => [ car 1 25 k, car 2 0 k ]) [ theLane, otherLane ]
def beside : Trace := scene3 (fun k => [ car 1 0 k, carBeside 2 10 k ]) [ theLane, otherLane ]
'''
FILE_PAIR_WITNESS = file_witness(FILE_PAIR, FILE_PARAMS, '[("u", 1), ("v", 2)]',
                                 ['witness "holds" behind .compliant', 'witness "fails" beside .violated', FILE_BLIND], FILE_PAIR_EXTRA)
FILE_PAIR_ENTRY = {"reads": ["rel.ahead_behind_in_lane", "rel.same_direction", "rel.surface_gap"], "params": REACH_PARAMS}

# A concept whose contract itself fixes the range of its quantifier: every other road user, of any class.
CLOSE_COMPANY = "drv.interaction.close_company"
CLOSE_COMPANY_CONTRACT = (
    "There is another road user, of any class, whose body is within the company distance of road user u's at the observation, a distance "
    "the caller sets measured between the nearest points of the bodies. Every road user of the scene other than u counts, whatever its "
    "class: the concept selects no class, and a caller that means road users of a class does not call it.")
CLOSE_COMPANY_SOURCE = file_concept(
    CLOSE_COMPANY, CLOSE_COMPANY_CONTRACT, '[("u", .track)]', '[⟨"company_distance", .metre⟩]',
    'def body : Formula :=\n  .existsUser "v" (.and (.not (.same aV aU)) (.cmp (.measure "rel_surface_gap" [aU, aV]) .le (.param "company_distance")))\n')
CLOSE_COMPANY_WITNESS = file_witness(CLOSE_COMPANY, '("company_distance", .lit (m 50) .metre)', '[("u", 1)]',
                                     ['witness "holds" carAndBikes .compliant', 'witness "fails" lonely .violated', FILE_BLIND])
CLOSE_COMPANY_RECORD = {
    "concept_id": CLOSE_COMPANY, "kind": "formula", "contract": CLOSE_COMPANY_CONTRACT, "args": [{"name": "u", "sort": "track"}],
    "params": [{"name": "company_distance", "unit": "m",
                "meaning": "the largest distance between the nearest points of two bodies at which another road user keeps u company"}],
    "elements": [{"span": "whose body is within the company distance of road user u's at the observation", "atoms": ["rel.surface_gap"],
                  "concepts": [], "justification": "the distance between the nearest points of two bodies"}],
    "residues": [], "literals": [],
    "scenarios": [{"name": "holds", "expected": "compliant", "narrative": "a bicycle 18 m ahead of car u"},
                  {"name": "fails", "expected": "violated", "narrative": "the nearest road user 395 m away"}, FILE_BLIND_SCENARIO]}


def interface_concept_gate(cid: str, source: str, witness: str, record: dict) -> tuple[gate.Verdict, dict[str, list[str]]]:
    """A concept through the real concept gate, with no admitted aggregate; returns the verdict and
    the ids its `AGGREGATES` and `HARDAGG` rows name."""
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.concept_path(cid), nodeid.concept_witness_path(cid)]
        for rel, src in zip(files, [source, witness]):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        ran = Ran(files, {f"import {nodeid.concept_module(cid)}", f"import {nodeid.concept_witness_module(cid)}"})
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            v = gate.run_concept_gate(ConceptRecord(copy.deepcopy(record)), Reading(Path(t) / "reading.json"), {}, work, 0, 5, accepted={})
        out = (work / "gate_harness.out").read_text()
    rows = {tag: [x for l in out.splitlines() if l.startswith(tag + "\t") for x in l.split("\t")[1:] if x] for tag in ("AGGREGATES", "HARDAGG")}
    return v, rows


# A caller of the pair relation: the fixture node, its subject a motor vehicle, its obligation read
# where the subject keeps in file with members of `AID`.
CALLER_PARAMS = [{"name": "p.file_min", "value": 3, "unit": "count", "convention": "fixture"},
                 {"name": "p.file_reach", "value": 50, "unit": "m", "convention": "fixture"},
                 {"name": "p.file_cos", "value": 0.95, "unit": "ratio", "convention": "fixture"},
                 {"name": "p.crawl", "value": 3, "unit": "m/s", "convention": "fixture"},
                 {"name": "p.win", "value": 3, "unit": "s", "convention": "fixture"}]
PAIR_CALL = f'.derived "drv_interaction_file_pair" [vV, .var "w"] [.param "p.file_reach", .param "p.file_cos"]'
IS_MEMBER = f'.atom "ru_aggregate" [.var "w", .lit "{AID}"] []'
COUNTED_FILE = (f'.cmp (.aggregate .count "w" (.and ({IS_MEMBER}) (.or (.same (.var "w") vV) ({PAIR_CALL}))) (.lit Q.zero .count)) '
                '.ge (.param "p.file_min")')
CRAWL = '.cmp (.measure "kin_speed" [vV]) .le (.param "p.crawl")'
MOVING = '.cmp (.measure "kin_speed" [vV]) .gt (.lit Q.zero .metrePerSecond)'
# At every observation of the window some member keeps in file with the subject; and the misplaced
# reading, one member keeping in file with it at every observation of the window.
EVERY_MOMENT_SOME = (f'.holdsFor .time (.param "p.win") "v" (.existsUser "w" (.and (.not (.same (.var "w") vV)) '
                     f'(.and ({IS_MEMBER}) ({PAIR_CALL}))))')
ONE_THROUGHOUT = (f'.existsUser "w" (.and (.not (.same (.var "w") vV)) (.and ({IS_MEMBER}) '
                  f'(.holdsFor .time (.param "p.win") "v" ({PAIR_CALL}))))')


def pair_caller(applicability: str, obligation: str) -> str:
    return f'''/- A caller of the pair relation. -/
import TrafficSpec.Core.Language.Rule

namespace {nodeid.rule_namespace(P.NODE_ID)}

def vV : Arg := .var "v"

def rule : Rule :=
  {{ id := "{P.NODE_ID}"
    laws := ["TEST-PRECOND-9"]
    binders := [ {{ name := "v", cls := .atom "ru_motor_vehicle" [vV] [] }} ]
    applicability := {applicability}
    obligation := {obligation} }}

end {nodeid.rule_namespace(P.NODE_ID)}
'''


def caller_witness(defs: str, scenarios: list[str], window: str = "") -> str:
    return f'''/- The caller's witnesses on one lane. -/
import {nodeid.rule_module(P.NODE_ID)}
import TrafficSpec.Core.Evidence.Builders

namespace {nodeid.witness_namespace(P.NODE_ID)}

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def theLane : Structure :=
  Build.lane 1 [(m (-300), m (-2)), (m 500, m (-2)), (m 500, m 2), (m (-300), m 2)] Build.east (ordinal := some 1) (count := some 1)
/-- A car at `x0 + sp·k` at observation k, heading east at `sp`; a bicycle likewise. -/
def car (track : TrackId) (x0 : Int) (sp : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + sp * Int.ofNat k), m 0) Build.east
    (Units.metresPerSecond sp) (cm 250, m 1, cm 75) (some (m (sp * Int.ofNat k)))
def bike (track : TrackId) (x0 : Int) (sp : Int) (k : Nat) : RoadUser :=
  Build.user track [.bicycle] (m (x0 + sp * Int.ofNat k), m 0) Build.east
    (Units.metresPerSecond sp) (cm 100, cm 30, cm 75) (some (m (sp * Int.ofNat k)))
def scene (n : Nat) (users : Nat → List RoadUser) : Trace :=
  Build.trace n 0 (Units.seconds 1) fun k t => Build.scene t (some 1) (users k) [ theLane ] [ ]
{defs}
def witness (name : String) (τ : Trace) (expected : Verdict) (absent : List String := []) : Scenario :=
  {{ name := name, rule := "{P.NODE_ID}", trace := τ, reading := {{}}, manifest := Build.manifest absent,
    grounding := [("v", 1)], expected := expected{window} }}

def scenarios : List Scenario :=
  [ {"""
  , """.join(scenarios)} ]

end {nodeid.witness_namespace(P.NODE_ID)}
'''


def caller_record(segments: tuple[str, str], elements: list[dict], params: list[str], scenarios: list[tuple]) -> dict:
    return {"node_id": P.NODE_ID, "law_refs": ["TEST-PRECOND-9"], "subject": {"binder": "v", "class_elements": ["ru.motor_vehicle"]},
            "binders": [{"name": "v", "class_elements": ["ru.motor_vehicle"]}],
            "segmentation": [{"id": "s1", "role": "subject", "text": "a vehicle"}, {"id": "t1", "role": "trigger", "text": segments[0]},
                             {"id": "o1", "role": "obligation", "text": segments[1]}],
            "elements": [{"span": "s1", "atoms": ["ru.motor_vehicle"]}] + elements,
            "params": params, "applicability": "a", "obligation": "o",
            "scenarios": [dict(zip(("name", "expected", "masked"), s)) for s in scenarios]}


def pair_caller_gate(rule: str, witness: str, record: dict) -> gate.Verdict:
    """The caller and the pair relation, registered beside it, through the real node gate, with the
    reading admitting `AID`."""
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.concept_path(FILE_PAIR), nodeid.rule_path(P.NODE_ID), nodeid.witness_path(P.NODE_ID)]
        for rel, src in zip(files, [FILE_PAIR_SOURCE, rule, witness]):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (work / "registry.json").write_text(json.dumps({"nodes": [], "concepts": [FILE_PAIR]}))
        (Path(t) / "reading.json").write_text(json.dumps({"params": CALLER_PARAMS, "aggregates": AGG_DECLARED}))
        own = {f"import {nodeid.concept_module(FILE_PAIR)}", f"import {nodeid.rule_module(P.NODE_ID)}", f"import {nodeid.witness_module(P.NODE_ID)}"}
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", Ran(files, own)):
            return gate.run_gate(Node(copy.deepcopy(record)), Reading(Path(t) / "reading.json"), {}, work, 0, 5,
                                 accepted_concepts={FILE_PAIR: FILE_PAIR_ENTRY})


COUNT_SCENES = '''def three (sp : Int) : Trace := scene 3 fun k => [ car 1 0 sp k, car 2 25 sp k, car 3 50 sp k ]
/-- The subject with two bicycles in file ahead of it: no file of members of the aggregate. -/
def withBikes : Trace := scene 3 fun k => [ car 1 0 20 k, bike 2 22 20 k, bike 3 43 20 k ]
'''
COUNT_RECORD = caller_record(("in a file of vehicles", "proceed slowly"),
                             [{"span": "t1", "atoms": [f"ru.aggregate={AID}"], "derived": [FILE_PAIR]}, {"span": "o1", "atoms": ["kin.speed"]}],
                             ["p.file_min", "p.file_reach", "p.file_cos", "p.crawl"],
                             [("forbid", "violated"), ("permit", "compliant"), ("idle", "not_applicable"), ("blind", "unknown", ["kin.speed"])])
COUNT_WITNESS = caller_witness(COUNT_SCENES, ['witness "forbid" (three 20) .violated', 'witness "permit" (three 1) .compliant',
                                              'witness "idle" withBikes .notApplicable', 'witness "blind" (three 20) (.unknown []) ["kin.speed"]'])
# Ego (1) at 10 m/s; car 2 starts 30 m ahead at 30 m/s (gaps 25, 45, 65, 85 m: in file at k = 0, 1);
# car 3 starts 100 m behind at 35 m/s (gaps 95, 70, 45, 20 m: in file at k = 2, 3). With a 50 m
# reach some car is in file with ego at every observation, and no one car at all four.
RELAY_SCENES = '''def relay (egoSp : Int) : Trace := scene 4 fun k => [ car 1 0 egoSp k, car 2 30 30 k, car 3 (-100) 35 k ]
def alone : Trace := scene 4 fun k => [ car 1 0 10 k, car 2 300 10 k ]
def escorted : Trace := scene 4 fun k => [ car 1 0 10 k, car 2 25 10 k ]
'''


def relay_case(obligation: str) -> tuple[str, str, dict]:
    """A caller whose obligation keeps a member in file with the moving subject over the window,
    with a relay witness expected compliant."""
    record = caller_record(("while moving", "accompanied at every moment by a vehicle in file"),
                           [{"span": "t1", "atoms": ["kin.speed"]}, {"span": "o1", "atoms": [f"ru.aggregate={AID}"], "derived": [FILE_PAIR]}],
                           ["p.win", "p.file_reach", "p.file_cos"],
                           [("forbid", "violated"), ("permit", "compliant"), ("relay", "compliant"), ("idle", "not_applicable"),
                            ("blind", "unknown", ["kin.speed"])])
    witness = caller_witness(RELAY_SCENES, ['witness "forbid" alone .violated', 'witness "permit" escorted .compliant',
                                            'witness "relay" (relay 10) .compliant', 'witness "idle" (relay 0) .notApplicable',
                                            'witness "blind" escorted (.unknown []) ["kin.speed"]'], ", window := some (3000, 3000)")
    return pair_caller(MOVING, obligation), witness, record


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class ConceptInterfaceValidator(unittest.TestCase):
    """A literal formal admits only the spellings of Core's enumerations: planning refuses a formal
    that admits an aggregate id, so the gate's acceptance of one is no route for a planner."""

    def test_a_literal_formal_admitting_an_aggregate_id_is_refused(self):
        from harness.checks import validate_a
        from harness.model import ontology
        record = copy.deepcopy(CONCEPT_RECORD)
        record["args"] = record["args"] + [{"name": "w", "sort": "literal", "values": [AID]}]
        record["scenarios"] = [{"name": "holds", "expected": "compliant", "narrative": "the road user at rest"},
                               {"name": "fails", "expected": "violated", "narrative": "the road user creeping"}]
        outs = validate_a.validate_concepts([ConceptRecord(record)], [], ontology.load(paths.REPO / "ontology" / "ATOMS_train.md"), {}, [])
        reasons = [r for o in outs for r in o.reasons]
        self.assertIn(f"{CID}: literal formal `w` admits `{AID}`, which spells no enumeration value of Core (the enumerations table lists them)",
                      reasons)

    def test_a_contract_fixing_the_full_range_of_its_quantifier_is_valid(self):
        from harness.checks import validate_a
        from harness.model import ontology
        outs = validate_a.validate_concepts([ConceptRecord(copy.deepcopy(CLOSE_COMPANY_RECORD))], [],
                                            ontology.load(paths.REPO / "ontology" / "ATOMS_train.md"), {}, [])
        self.assertEqual([(o.kind, o.reasons) for o in outs if o.reasons], [])


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class ConceptInterface(unittest.TestCase):
    """What a caller states about what a concept denotes goes through what the concept exposes.
    These cases show the instances they run, never that the principle is enforced."""

    def test_a_known_gap_a_contract_leaving_the_members_class_to_the_caller_passes_the_gate(self):
        """A known gap, recorded rather than wanted: no check of the validator or the gates reads whether a
        contract leaves to the caller a condition on an object the body binds itself. The concept below
        promises that the caller states its members' class, has no formal for it, and passes the gate;
        a scene of mixed classes shows the error once a witness puts it there. This test is updated when
        a check of the interface is added; it is not behaviour to preserve."""
        v, _rows = interface_concept_gate(VEHICLE_FILE, VEHICLE_FILE_SOURCE, vehicle_file_witness("lonely"), VEHICLE_FILE_RECORD)
        self.assertEqual(v.verdict, "OK", v.details)
        v, _rows = interface_concept_gate(VEHICLE_FILE, VEHICLE_FILE_SOURCE, vehicle_file_witness("carAndBikes"), VEHICLE_FILE_RECORD)
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertIn("fails: expected violated, got compliant", v.details)

    def test_the_pair_relation_passes_and_its_caller_states_the_members_class(self):
        v, rows = interface_concept_gate(FILE_PAIR, FILE_PAIR_SOURCE, FILE_PAIR_WITNESS, FILE_PAIR_RECORD)
        self.assertEqual((v.verdict, rows), ("OK", {"AGGREGATES": [], "HARDAGG": []}), v.details)
        # the caller counts members of its own aggregate: a car followed by two bicycles is no file of them
        v = pair_caller_gate(pair_caller(COUNTED_FILE, CRAWL), COUNT_WITNESS, COUNT_RECORD)
        self.assertEqual(v.verdict, "OK", v.details)

    def test_a_contract_fixing_the_full_range_of_its_quantifier_keeps_it(self):
        v, rows = interface_concept_gate(CLOSE_COMPANY, CLOSE_COMPANY_SOURCE, CLOSE_COMPANY_WITNESS, CLOSE_COMPANY_RECORD)
        self.assertEqual((v.verdict, rows), ("OK", {"AGGREGATES": [], "HARDAGG": []}), v.details)

    def test_a_quantifier_moved_to_the_caller_keeps_its_place_relative_to_the_window(self):
        v = pair_caller_gate(*relay_case(EVERY_MOMENT_SOME))
        self.assertEqual(v.verdict, "OK", v.details)
        # the same words with the quantifier moved outside the window: the gate checks only that the
        # formula and its witnesses agree, so the relay witness written for the words fails it
        v = pair_caller_gate(*relay_case(ONE_THROUGHOUT))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertIn("relay: expected compliant, got violated", v.details)


if __name__ == "__main__":
    unittest.main()
