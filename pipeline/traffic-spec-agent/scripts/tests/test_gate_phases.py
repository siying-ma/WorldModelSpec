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
# formal `w`, which the caller fills (the only form a shared concept may read an aggregate in);
# `HARD_BODY` writes the id into the body itself, which the concept gate refuses.
AID = "DEF-TST-1::wagon"
AGG_ARGS = f'[("u", .track), ("w", .literal ["{AID}"])]'
AGG_BODY = ('.cmp (.cond (.atom "ru_aggregate" [aU, .var "w"] []) (.measure "kin_speed" [aU]) '
            '(.measure "kin_speed" [aU])) .le (.param "tol")')
HARD_BODY = (f'.cmp (.cond (.atom "ru_aggregate" [aU, .lit "{AID}"] []) (.measure "kin_speed" [aU]) '
             '(.measure "kin_speed" [aU])) .le (.param "tol")')
AGG_DECLARED = [{"id": AID, "included": ["ru.motor_vehicle"]}]
HARD_CODED = (f"{CID}: the body names the definition-scoped aggregate `{AID}` itself (here or in a concept it calls with that id); "
              "a shared concept reads an aggregate only through a literal formal its caller fills, so that each calling law's "
              "own gate checks the id against its definitions, its reading and its claims")


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


if __name__ == "__main__":
    unittest.main()
