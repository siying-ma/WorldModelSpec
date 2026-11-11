"""A concept bound to a posted definition is written as based on it: its skeleton never claims the
contract is the definition's text, and shows the posted text apart from the contract, on a coding
task's first write and on its relaunch."""
from __future__ import annotations
import shutil
import subprocess
import tempfile
import json
import unittest
from contextlib import contextmanager
from pathlib import Path
from unittest import mock

from harness.lean import skeleton
from harness.model import nodeid
from harness.model.blueprint import ConceptRecord
from harness.phases import code as code_phase
from harness.store import paths as _paths

REAL_LIBRARY = _paths.LIBRARY          # the built library: a world's library holds Core's sources only

DEF_ID = "DEF-STA-900A-010"
DEF_TEXT = "“Turn lane” means a lane marked for turning movements only."


class ConceptSkeletonHeader(unittest.TestCase):
    RAW = {"concept_id": "drv.motion.halt_probe", "kind": "formula", "definition": DEF_ID,
           "contract": "A road user is halted: its speed at or below `tol`.", "args": [{"name": "x", "sort": "track"}],
           "params": [{"name": "tol", "unit": "m/s"}], "elements": [{"span": "its speed", "atoms": ["kin.speed"], "concepts": []}],
           "residues": [], "literals": []}

    def header(self, text: str) -> str:
        return text.split("-/\n", 1)[0]

    def test_based_on_the_definition_never_its_text(self):
        for given in (None, DEF_TEXT):
            s = skeleton.concept_skeleton(ConceptRecord(self.RAW), given)
            self.assertNotIn("verbatim.", self.header(s))
            self.assertNotIn("The contract is the definition", s)
            self.assertIn(f"Based on the posted definition `{DEF_ID}`: the contract above is this record's reading", self.header(s))
            self.assertIn(f'definition := some "{DEF_ID}"', s)
        self.assertNotIn(DEF_TEXT, skeleton.concept_skeleton(ConceptRecord(self.RAW)))

    def test_the_posted_text_stands_apart_from_the_contract(self):
        s = skeleton.concept_skeleton(ConceptRecord(self.RAW), DEF_TEXT)
        lines = self.header(s).splitlines()
        i = lines.index("  The posted text (the definition's words; the concept denotes its contract):")
        self.assertEqual(lines[i + 1].strip(), DEF_TEXT)
        contract = next(l for l in s.splitlines() if l.strip().startswith("contract :="))
        self.assertNotIn(DEF_TEXT, contract)

    def test_a_concept_bound_to_no_definition_says_nothing_of_one(self):
        raw = {k: v for k, v in self.RAW.items() if k != "definition"}
        self.assertNotIn("posted definition", skeleton.concept_skeleton(ConceptRecord(raw), DEF_TEXT))

    def test_the_skeleton_with_the_posted_text_builds(self):
        from harness.store import paths
        if not shutil.which("lake"):
            self.skipTest("the Lean toolchain is not installed")
        tricky = DEF_TEXT + " A comment mark -/ or /- in posted words is no delimiter."
        s = skeleton.concept_skeleton(ConceptRecord(self.RAW), tricky)
        self.assertEqual(self.header(s).count("-/"), 0)
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "probe.lean"
            f.write_text(s, encoding="utf-8")
            out = subprocess.run(["lake", "env", "lean", str(f)], cwd=paths.LIBRARY, capture_output=True, text=True, timeout=600)
        self.assertEqual(out.returncode, 0, out.stdout[-2000:] + out.stderr[-2000:])


class Stop(Exception):
    pass


class CodingTaskWritesThePostedText(unittest.TestCase):
    """A concept coding task writes the concept's skeleton with the posted text of the definition it
    is bound to, on its first write and on a relaunch; a concept bound to no definition is written
    as before. A definition the run's corpus lacks is returned by the validator before coding; should
    one reach a task, the task goes on and the skeleton marks the missing text abnormal."""

    @contextmanager
    def task(self, raw: dict):
        from harness.model.reading import Reading
        from harness.store import paths
        from scripts.tests.test_candidate import world
        with world({}, {}) as (run, _lib):
            Path(run.opts.laws).with_name("definitions.jsonl").write_text(
                json.dumps({"id": DEF_ID, "title": "Turn lane defined", "text": DEF_TEXT, "source": "STA 900A.010"}) + "\n", encoding="utf-8")
            rec = ConceptRecord(raw)
            yield run, rec, Reading(run.reading_file), paths.LIBRARY / nodeid.concept_path(rec.id)

    def check(self, text: str, posted: bool) -> None:
        header = text.split("-/\n", 1)[0]
        contract = next(l for l in text.splitlines() if l.strip().startswith("contract :="))
        self.assertNotIn(DEF_TEXT, contract)
        self.assertEqual(DEF_TEXT in header, posted)

    def session_sees(self, raw: dict, relaunched: bool = False) -> str:
        """The concept file as the coding session finds it on starting, or after its relaunch."""
        with self.task(raw) as (run, rec, reading, path):
            seen = {}

            def session_run(prompt, relaunch=None, **_k):
                if relaunched:
                    path.write_text("-- the session's half-written file\n", encoding="utf-8")
                    relaunch()
                seen["text"] = path.read_text(encoding="utf-8")
                raise Stop
            with mock.patch.object(code_phase.session, "run", session_run), \
                    mock.patch.object(code_phase.lean, "lake_build", lambda *_a, **_k: (0, "")), \
                    mock.patch.object(code_phase.index_sync, "write_index", lambda *_a, **_k: None):
                with self.assertRaises(Stop):
                    code_phase.run_code_concept(run, rec, reading)
        return seen["text"]

    def test_the_first_write_carries_the_posted_text(self):
        text = self.session_sees(ConceptSkeletonHeader.RAW)
        self.check(text, True)
        self.assertNotIn("ABNORMAL", text)
        self.assertEqual(text, skeleton.concept_skeleton(ConceptRecord(ConceptSkeletonHeader.RAW), DEF_TEXT))
        self.builds(text)

    def test_the_relaunch_carries_the_posted_text(self):
        text = self.session_sees(ConceptSkeletonHeader.RAW, relaunched=True)
        self.check(text, True)
        self.assertEqual(text, skeleton.concept_skeleton(ConceptRecord(ConceptSkeletonHeader.RAW), DEF_TEXT))

    def test_a_concept_bound_to_no_definition_is_written_as_before(self):
        raw = {k: v for k, v in ConceptSkeletonHeader.RAW.items() if k != "definition"}
        text = self.session_sees(raw)
        self.assertEqual(text, skeleton.concept_skeleton(ConceptRecord(raw)))
        self.assertNotIn("posted", text.split("-/\n", 1)[0])

    def test_the_task_prompt_shows_the_written_skeleton(self):
        def stop(*_a, **_k):
            raise Stop
        with self.task(ConceptSkeletonHeader.RAW) as (run, rec, reading, path):
            with mock.patch.object(code_phase.session, "run", stop), \
                    mock.patch.object(code_phase.lean, "lake_build", lambda *_a, **_k: (0, "")), \
                    mock.patch.object(code_phase.index_sync, "write_index", lambda *_a, **_k: None):
                with self.assertRaises(Stop):
                    code_phase.run_code_concept(run, rec, reading)
            written = path.read_text(encoding="utf-8")
            prompt = (code_phase.concept_dir(run, rec.id) / "prompt.md").read_text(encoding="utf-8")
        self.check(written, True)
        self.assertIn(written, prompt)

    def test_an_unresolved_definition_never_reaches_coding(self):
        """A record bound to a definition the run's corpus lacks is returned by the validator, so the
        skeleton's fallback for a missing text is never reached in a valid run."""
        from harness.checks import validate_a
        from scripts.tests.test_review_routing import ONTO
        raw = {**ConceptSkeletonHeader.RAW, "definition": "DEF-STA-900A-099",
               "scenarios": [{"name": "holds", "expected": "compliant", "narrative": "x's speed is 0.05 m/s with tol 0.2 m/s."},
                             {"name": "fails", "expected": "violated", "narrative": "x's speed is 2 m/s."},
                             {"name": "blind", "expected": "unknown", "narrative": "x's speed is not observed.", "masked": ["kin.speed"]}]}
        reasons = validate_a.validate_concepts([ConceptRecord(raw)], [{"id": DEF_ID, "text": DEF_TEXT}], ONTO, {}, [])[0].reasons
        self.assertTrue(any("definition `DEF-STA-900A-099` is not among the definitions given" in r for r in reasons), reasons)

    def test_the_abnormal_fallback_is_marked_and_does_not_fail_the_task(self):
        text = self.session_sees({**ConceptSkeletonHeader.RAW, "definition": "DEF-STA-900A-099"})
        self.check(text, False)
        self.assertIn("ABNORMAL: the posted text of this definition was not available", text)

    def builds(self, text: str) -> None:
        if not shutil.which("lake"):
            self.skipTest("the Lean toolchain is not installed")
        with tempfile.TemporaryDirectory() as t:
            f = Path(t) / "probe.lean"
            f.write_text(text, encoding="utf-8")
            out = subprocess.run(["lake", "env", "lean", str(f)], cwd=REAL_LIBRARY, capture_output=True, text=True, timeout=600)
        self.assertEqual(out.returncode, 0, out.stdout[-2000:] + out.stderr[-2000:])


if __name__ == "__main__":
    unittest.main()
