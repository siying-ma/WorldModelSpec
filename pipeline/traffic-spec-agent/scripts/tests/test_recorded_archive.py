"""The recorded archive and its labels, on a synthetic archive: recordings are keyed by data version
and recording id (two recordings of one case stay apart), a split archive reads like one zip, a
held-out recording is never listed for training nor read, and a label's verdict and contract are
read as stated, a judgment call keeping its verdict (it is scored apart, not dropped)."""
import csv
import io
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from recorded import archive, labels

FIELDS = ["set", "cell_id", "law_id", "case_id", "recording_id", "recorded_label", "raw_saved_label", "judgment_call",
          "in_current_comparison", "video", "lean_trace", "manifest", "validation"]


def row(set_, case, rid, law="NRS-1", label="compliant", jc="False"):
    base = f"cases/{case}/{case}--{rid[:6]}"
    return {"set": set_, "cell_id": case[:4], "law_id": law, "case_id": case, "recording_id": rid, "recorded_label": label,
            "raw_saved_label": "", "judgment_call": jc, "in_current_comparison": "True", "video": f"{base}/video.webm",
            "lean_trace": f"{base}/lean_trace.json", "manifest": f"{base}/manifest.json", "validation": f"{base}/validation.json"}


def make_archive(path: Path, rows: list[dict]) -> None:
    buf = io.StringIO()
    w = csv.DictWriter(buf, FIELDS)
    w.writeheader()
    w.writerows(rows)
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("INDEX.csv", buf.getvalue())
        z.writestr("MANIFEST.json", json.dumps({"version": 1}))
        for r in rows:
            base = r["lean_trace"].rsplit("/", 1)[0]
            z.writestr(r["lean_trace"], json.dumps({"scenes": [{"t": 0, "users": []}], "id": r["recording_id"]}))
            z.writestr(r["manifest"], json.dumps({"source": "s", "atoms": {"kin.speed": "exact"}}))
            z.writestr(r["validation"], "{}")
            z.writestr(base + "/label.json", json.dumps({"law_id": r["law_id"], "recorded_label": r["recorded_label"],
                                                         "judgment_call": r["judgment_call"] == "True"}))


ROWS = [row("demo-train", "C1-a", "aaa111"), row("demo-train", "C1-a", "bbb222", label="violation", jc="True"),
        row("demo-train", "C2-b", "ccc333", label="Unresolved (no label assigned)", jc="True"),
        row("demo-test", "C9-z", "zzz999")]


class ArchiveTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.zip = Path(self.tmp.name) / "a.zip"
        make_archive(self.zip, ROWS)

    def tearDown(self):
        self.tmp.cleanup()

    def test_two_recordings_of_one_case_stay_apart(self):
        with archive.Archive(self.zip) as a:
            train = a.recordings()
            self.assertEqual([r.recording_id for r in train], ["aaa111", "bbb222", "ccc333"])
            self.assertEqual(len({r.key for r in train}), 3)
            self.assertEqual({r.case_id for r in train if r.case_id == "C1-a"}, {"C1-a"})
            self.assertEqual(json.loads(a.read_bytes(a.recording("bbb222"), "manifest"))["atoms"], {"kin.speed": "exact"})
            with a.open(a.recording("bbb222"), "trace") as f:
                self.assertEqual(json.loads(f.read())["id"], "bbb222")

    def test_a_duplicate_recording_id_is_refused(self):
        make_archive(self.zip, ROWS + [row("demo-train", "C3-c", "aaa111")])
        with self.assertRaises(archive.ArchiveError):
            archive.Archive(self.zip)

    def test_a_held_out_recording_is_neither_listed_nor_read(self):
        with archive.Archive(self.zip) as a:
            self.assertNotIn("zzz999", [r.recording_id for r in a.recordings()])
            with self.assertRaises(archive.ArchiveError):
                a.recordings(archive.TEST)                          # the held-out rows carry labels
            self.assertEqual([r.recording_id for r in a.recordings(archive.TEST, allow_test=True)], ["zzz999"])
            with self.assertRaises(archive.ArchiveError):
                a.recording("zzz999")
            test = a.recording("zzz999", allow_test=True)
            with self.assertRaises(archive.ArchiveError):
                a.read_bytes(test, "manifest")                      # refused without allow_test
            self.assertTrue(a.read_bytes(test, "manifest", allow_test=True))

    def test_a_split_archive_reads_like_the_zip(self):
        parts = Path(self.tmp.name) / "parts"
        parts.mkdir()
        data = self.zip.read_bytes()
        for i in range(0, len(data), 97):                          # parts smaller than a member
            (parts / f"part-{i // 97:03d}").write_bytes(data[i:i + 97])
        with archive.Archive(self.zip) as a, archive.Archive(parts) as b:
            self.assertEqual(a.data_version, b.data_version)
            self.assertEqual([r.key for r in a.recordings()], [r.key for r in b.recordings()])
            out = b.extract(b.recording("ccc333"), "trace", Path(self.tmp.name) / "x" / "trace.json")
            self.assertEqual(json.loads(out.read_text())["id"], "ccc333")

    def test_the_data_version_follows_index_and_manifest(self):
        with archive.Archive(self.zip) as a:
            v1 = a.data_version
        make_archive(self.zip, ROWS[:2])
        with archive.Archive(self.zip) as a:
            self.assertNotEqual(v1, a.data_version)


class LabelTests(unittest.TestCase):
    def test_verdicts(self):
        self.assertEqual(labels.verdict_of("violation"), "violated")
        self.assertEqual(labels.verdict_of("compliant"), "compliant")
        self.assertEqual(labels.verdict_of("not applicable"), "not_applicable")
        self.assertIsNone(labels.verdict_of("Unresolved (no label assigned)"))
        self.assertIsNone(labels.verdict_of("Unresolved (judgment call)"))

    def test_a_judgment_call_keeps_its_verdict(self):
        lab = labels.parse({"law_id": "NRS-1", "recorded_label": "violation", "judgment_call": True})
        self.assertEqual(lab.verdict, "violated")
        self.assertTrue(lab.judgment_call)

    def test_the_contract_is_ego_over_the_whole_recording(self):
        lab = labels.parse('{"law_id": "NRS-1", "recorded_label": "compliant", "judgment_call": "False"}')
        self.assertEqual((lab.subject, lab.scope, lab.provisional), ("ego", "whole recording", False))
        self.assertFalse(lab.judgment_call)


if __name__ == "__main__":
    unittest.main()
