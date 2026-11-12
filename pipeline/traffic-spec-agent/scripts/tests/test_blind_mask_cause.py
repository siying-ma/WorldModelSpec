"""A `blind` witness of a concept that reads its only atom inside operators looking into the past.
Masking that atom leaves `since` and `rises` unsettled back to the trace start, so Core reports a
window truncated there beside the masked atom, and `Scenario.run` refuses a blind witness for that
truncation. The gate and the library's verification hold every witness through `witnessRun`: such
a blind witness is admitted where the mask is the cause, that is where it is unknown only for
masked atoms and truncations at the trace start, and the same trace with nothing masked is decided.
A truncation the mask does not explain (the trace starts in the middle of the overlap) stays
refused, masked or not.

The record, body and witnesses are those of `drv.position.entered_via` as a coding session wrote
them (fixtures under `fixtures/r6_entered_via/`). The Lean-backed tests are skipped, and so not
verified, where the toolchain or the built Core is absent."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from harness.checks import gate
from harness.lean import index_sync, lean
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord
from harness.model.reading import Reading
from harness.store import paths
from scripts.tests import test_precondition_continuity as P
from scripts.tests.test_gate_phases import Ran, _library, REAL_LIBRARY

FIX = Path(__file__).parent / "fixtures" / "r6_entered_via"
CID = "drv.position.entered_via"
RECORD = json.loads((FIX / "concept.json").read_text())
BODY = (FIX / "concept.lean").read_text()
WITNESS = (FIX / "witness.lean").read_text()

#: The blind witness's trace as written (the holds scenes) and one that starts with the overlap of r
#: already under way, on the same footprints (x at 10 m, 14 m, 14 m), so its beginning is unobserved.
AS_WRITTEN = '''def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX k 4 ]
      structures
      [ ]
      (occupies := some (occ k 101))'''
MID_OVERLAP = '''def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ userX (k + 1) 4 ]
      structures
      [ ]
      (occupies := some (occ (k + 1) 101))'''
MASKED = '["rel.occupies"] ]'
assert AS_WRITTEN in WITNESS and WITNESS.count(MASKED) == 1


def witness(trace: str = AS_WRITTEN, masked: str = MASKED) -> str:
    return WITNESS.replace(AS_WRITTEN, trace).replace(MASKED, masked)


def concept_gate(witness_src: str) -> gate.Verdict:
    """The real concept gate on the fixture's record and body and the given witnesses."""
    with tempfile.TemporaryDirectory() as t:
        lib, work, dirs = _library(t)
        files = [nodeid.concept_path(CID), nodeid.concept_witness_path(CID)]
        for rel, src in zip(files, (BODY, witness_src)):
            (lib / rel).parent.mkdir(parents=True, exist_ok=True)
            (lib / rel).write_text(src, encoding="utf-8")
        (Path(t) / "reading.json").write_text(json.dumps({"params": [], "aggregates": []}))
        ran = Ran(files, {f"import {nodeid.concept_module(CID)}", f"import {nodeid.concept_witness_module(CID)}"})
        with mock.patch.multiple(paths, **dirs), mock.patch.object(gate, "repo_digest", lambda *a, **k: {}), \
                mock.patch.object(gate, "_toolchain", ran):
            return gate.run_concept_gate(ConceptRecord(json.loads(json.dumps(RECORD))), Reading(Path(t) / "reading.json"),
                                         {}, work, 0, 5, accepted={})


PROBE = '''open TrafficSpec
def showV : Except String Verdict → String
  | .ok v => s!"ok {v.tag} {(match v with | .unknown w => w.map UnknownReason.tag | _ => [])}"
  | .error e => s!"error {e}"
def main : IO Unit := do
  let cs := [TrafficSpec.Concepts.position.entered_via.concept]
  let rules := TrafficSpecWitness.Concepts.position.entered_via.instances.filterMap (Concept.asRule cs)
  let scs := TrafficSpecWitness.Concepts.position.entered_via.scenarios
  let full : Manifest := Build.manifest []
  let mid := { (scs.find? (·.name == "blind")).get! with trace := midTrace }
  for sc in scs do
    IO.println s!"CORE\\t{sc.name}\\t{showV (sc.run rules cs)}"
    IO.println s!"HELD\\t{sc.name}\\t{showV (witnessRun rules sc cs)}"
  let blind := (scs.find? (·.name == "blind")).get!
  IO.println s!"FULL\\tblind\\t{showV (({ blind with manifest := full, expected := .compliant } : Scenario).run rules cs)}"
  IO.println s!"MID_FULL\\t{showV (({ mid with manifest := full, boundary := "the start" } : Scenario).run rules cs)}"
  IO.println s!"MID_HELD\\t{showV (witnessRun rules mid cs)}"
  IO.println s!"MID_BARE\\t{showV (witnessRun rules { mid with manifest := full } cs)}"
'''


def probe() -> dict[str, str]:
    """The fixture's witnesses run through Core and through `witnessRun`, one line per question."""
    imports, bodies = [], []
    mid = MID_OVERLAP.replace("def blindTrace", "def midTrace")
    for src in (BODY, WITNESS.replace("end TrafficSpecWitness.Concepts.position.entered_via",
                                      mid + "\nend TrafficSpecWitness.Concepts.position.entered_via")):
        imp, body = P._split(src)
        imports += [i for i in imp if "Concepts.position" not in i]
        bodies.append(body)
    program = (index_sync.WITNESS_RUN_DEFS + PROBE).replace("midTrace", "TrafficSpecWitness.Concepts.position.entered_via.midTrace")
    with tempfile.TemporaryDirectory() as t:
        f = Path(t) / "probe.lean"
        f.write_text("\n".join(dict.fromkeys(imports)) + "\n" + "\n".join(bodies) + "\n" + program, encoding="utf-8")
        code, out = lean.lean_run(REAL_LIBRARY, f, timeout=600)
    rows = {}
    for l in out.splitlines():
        parts = l.split("\t")
        if parts[0] in ("CORE", "HELD", "FULL"):
            rows[f"{parts[0]} {parts[1]}"] = parts[2]
        elif parts[0] in ("MID_FULL", "MID_HELD", "MID_BARE"):
            rows[parts[0]] = parts[1]
    if code != 0 or not rows:
        raise AssertionError(f"the probe did not run ({code}): {out[-2000:]}")
    return rows


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class Regression(unittest.TestCase):
    """The three cases on the concept's own record, body and witnesses."""

    @classmethod
    def setUpClass(cls):
        cls.rows = probe()

    def test_a_the_masked_observation_is_unknown(self):
        # Core alone refuses the blind witness for the truncations beside the masked atom ...
        self.assertIn("window_truncated:since", self.rows["CORE blind"])
        self.assertTrue(self.rows["CORE blind"].startswith("error"), self.rows["CORE blind"])
        # ... and the witness is held: unknown, for the masked atom and the truncations alone
        self.assertTrue(self.rows["HELD blind"].startswith("ok unknown"), self.rows["HELD blind"])
        self.assertIn("absent_atom:rel_occupies", self.rows["HELD blind"])

    def test_b_the_complete_observation_is_decided(self):
        self.assertEqual(self.rows["FULL blind"], "ok compliant []")
        self.assertEqual(self.rows["HELD holds"], "ok compliant []")
        self.assertEqual(self.rows["HELD fails"], "ok violated []")

    def test_c_a_shortfall_the_mask_does_not_explain_is_refused(self):
        # the trace starts in the overlap: unknown with nothing masked, for the truncations alone
        self.assertTrue(self.rows["MID_FULL"].startswith("ok unknown"), self.rows["MID_FULL"])
        self.assertNotIn("absent_atom", self.rows["MID_FULL"])
        self.assertIn("window_truncated:rises", self.rows["MID_FULL"])
        # masked, it is refused, naming why; with nothing masked, Core's own refusal stands
        self.assertTrue(self.rows["MID_HELD"].startswith("error"), self.rows["MID_HELD"])
        self.assertIn("with nothing masked the same trace is unknown too", self.rows["MID_HELD"])
        self.assertTrue(self.rows["MID_BARE"].startswith("error"), self.rows["MID_BARE"])
        self.assertIn("not for an atom the manifest masks", self.rows["MID_BARE"])
        self.assertNotIn("with nothing masked", self.rows["MID_BARE"])


@unittest.skipUnless(P.TOOLCHAIN, P.SKIP)
class ConceptGate(unittest.TestCase):
    """The real concept gate on the concept as the session wrote it."""

    def test_the_witnesses_as_written_pass(self):
        v = concept_gate(witness())
        self.assertNotEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertFalse(any(d.startswith("blind") for d in v.details), v.details)

    def test_a_blind_trace_starting_in_the_overlap_is_refused(self):
        v = concept_gate(witness(MID_OVERLAP))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any(d.startswith("blind:") and "with nothing masked the same trace is unknown too" in d
                            for d in v.details), v.details)

    def test_a_blind_witness_masking_nothing_is_refused(self):
        v = concept_gate(witness(MID_OVERLAP, "[] ]"))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertTrue(any(d.startswith("blind:") and "not for an atom the manifest masks" in d for d in v.details), v.details)

    def test_a_declared_boundary_is_still_the_plans(self):
        # the witness may not widen what the plan lets stay unknown: the mask needs no declaration
        v = concept_gate(witness(masked='["rel.occupies"] (boundary := "the beginning of the overlap") ]'))
        self.assertEqual(v.verdict, "WITNESS_FAIL", v.details)
        self.assertIn("blind: the witness declares a history boundary the plan does not", v.details)


class Sources(unittest.TestCase):
    """Every place that holds a witness holds it through the one definition."""

    def test_the_gate_harnesses_and_the_library_verification_use_witnessRun(self):
        reg = ("import TrafficSpec.Core\n", "")
        sources = {"node": gate._harness_source("L_1", Path("r.json"), reg),
                   "concept": gate._concept_harness_source(CID, Path("r.json"), reg)}
        for kind, src in sources.items():
            self.assertIn(index_sync.WITNESS_RUN_DEFS, src, kind)
            self.assertIn("match witnessRun rules sc ", src, kind)
            self.assertEqual(src.count("sc.run rules"), index_sync.WITNESS_RUN_DEFS.count("sc.run rules"), kind)
        with tempfile.TemporaryDirectory() as t:
            root = Path(t) / "TrafficSpecWitness.lean"
            with mock.patch.multiple(paths, LIBRARY=Path(t), INDEX_FILE=Path(t) / "Index.lean", WITNESS_ROOT_FILE=root,
                                     RULES_DIR=Path(t) / "R", CONCEPTS_DIR=Path(t) / "C", WITNESS_DIR=Path(t) / "W",
                                     CONCEPT_WITNESS_DIR=Path(t) / "W" / "Concepts"):
                index_sync.write_index()
            text = root.read_text()
        self.assertIn(index_sync.WITNESS_RUN_DEFS, text)
        self.assertIn("match witnessRun witnessRules", text)

    def test_the_tracked_witness_registry_is_the_generated_one(self):
        with tempfile.TemporaryDirectory() as t:
            root = Path(t) / "TrafficSpecWitness.lean"
            with mock.patch.multiple(paths, LIBRARY=Path(t), INDEX_FILE=Path(t) / "Index.lean", WITNESS_ROOT_FILE=root,
                                     RULES_DIR=Path(t) / "R", CONCEPTS_DIR=Path(t) / "C", WITNESS_DIR=Path(t) / "W",
                                     CONCEPT_WITNESS_DIR=Path(t) / "W" / "Concepts"):
                index_sync.write_index()
            self.assertEqual(root.read_text(), (REAL_LIBRARY / "TrafficSpecWitness.lean").read_text())


if __name__ == "__main__":
    unittest.main()
