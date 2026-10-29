"""The guards that keep held-out laws out of development records: the doctor lists a gap row that
names a held-out law under the training split, and a training run refuses to start on one, while a
test round's own rows let it resume."""
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

from harness import loop
from harness.store import paths
from scripts.diagnostics.doctor import OK, REVIEW, SKIP, Doctor


def write_jsonl(path: Path, rows: list[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("".join(json.dumps(r) + "\n" for r in rows), encoding="utf-8")


class GapLedgerNamesNoHeldOutLaw(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self.tmp.name) / "repo"
        self.lib = self.repo / "library"
        write_jsonl(self.repo / "laws" / "example" / "test" / "laws.jsonl", [{"id": "L-held"}])
        (self.lib / "splits").mkdir(parents=True)
        (self.lib / "splits" / "ACTIVE").write_text("train\n")

    def tearDown(self):
        self.tmp.cleanup()

    def check(self, rows):
        write_jsonl(self.lib / "TrafficSpec" / "Gaps" / "proposals.jsonl", rows)
        return Doctor(self.repo, self.lib).held_out_laws_out_of_gap_ledger()

    def test_a_row_on_a_held_out_law_is_listed_for_review(self):
        r = self.check([{"id": "G7", "law_refs": ["L-train", "L-held"]}])
        self.assertEqual(r.status, REVIEW)
        self.assertIn("G7: L-held", r.detail)

    def test_rows_on_training_laws_pass(self):
        self.assertEqual(self.check([{"id": "G1", "law_refs": ["L-train"]}]).status, OK)

    def test_the_check_is_skipped_under_the_full_split(self):
        (self.lib / "splits" / "ACTIVE").write_text("full\n")
        self.assertEqual(self.check([{"id": "G7", "law_refs": ["L-held"]}]).status, SKIP)

    def gate(self, mode: str, new: bool):
        gaps, results = self.lib / "TrafficSpec" / "Gaps", Path(self.tmp.name) / "results"
        write_jsonl(gaps / "proposals.jsonl", [{"id": "G7", "law_refs": ["L-held"], "proposed_in": "t/iter-001"}])
        (results / "t").mkdir(parents=True, exist_ok=True)
        state = results / "t" / "state.json"
        if not new:
            state.write_text("{}")
        run = SimpleNamespace(state_file=state)
        with patch.object(paths, "GAPS_DIR", gaps), patch.object(paths, "RESULTS", results), patch.object(paths, "REPO", self.repo):
            return loop.gap_gate(run, SimpleNamespace(mode=mode))

    def test_a_test_round_resumes_on_its_own_held_out_gap(self):
        self.assertEqual(self.gate("test", new=False), [])

    def test_a_training_run_refuses_a_held_out_gap(self):
        with self.assertRaises(SystemExit) as e:
            self.gate("train", new=False)
        self.assertIn("G7", str(e.exception))

    def test_a_new_round_refuses_while_the_test_gap_is_open(self):
        with self.assertRaises(SystemExit):
            self.gate("test", new=True)


if __name__ == "__main__":
    unittest.main()
