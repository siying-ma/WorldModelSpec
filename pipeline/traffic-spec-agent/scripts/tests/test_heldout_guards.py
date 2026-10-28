"""The two guards that keep held-out laws out of development records: the doctor fails while a gap
row names a held-out law under the training split, and a fresh init copies the whole gap ledger
before pruning it."""
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from harness import __main__ as cli
from harness.store import paths
from scripts.diagnostics.doctor import FAIL, OK, SKIP, Doctor


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

    def test_a_row_on_a_held_out_law_fails(self):
        r = self.check([{"id": "G7", "law_refs": ["L-train", "L-held"]}])
        self.assertEqual(r.status, FAIL)
        self.assertIn("G7: L-held", r.detail)

    def test_rows_on_training_laws_pass(self):
        self.assertEqual(self.check([{"id": "G1", "law_refs": ["L-train"]}]).status, OK)

    def test_the_check_is_skipped_under_the_full_split(self):
        (self.lib / "splits" / "ACTIVE").write_text("full\n")
        self.assertEqual(self.check([{"id": "G7", "law_refs": ["L-held"]}]).status, SKIP)


class FreshInitCopiesTheLedger(unittest.TestCase):
    def test_every_ledger_file_is_copied_and_left_in_place(self):
        with tempfile.TemporaryDirectory() as t:
            gaps, results = Path(t) / "Gaps", Path(t) / "results"
            write_jsonl(gaps / "proposals.jsonl", [{"id": "G1"}])
            write_jsonl(gaps / "decisions.jsonl", [{"id": "G1", "state": "retired"}])
            (gaps / "counter.txt").write_text("2\n")
            with patch.object(paths, "GAPS_DIR", gaps), patch.object(paths, "RESULTS", results):
                copied = cli.snapshot_gaps("smoke24")
            self.assertEqual(copied, ["counter.txt", "decisions.jsonl", "proposals.jsonl"])
            for name in copied:
                self.assertEqual((results / "smoke24" / "gaps_snapshot" / name).read_text(), (gaps / name).read_text())
                self.assertTrue((gaps / name).exists())


if __name__ == "__main__":
    unittest.main()
