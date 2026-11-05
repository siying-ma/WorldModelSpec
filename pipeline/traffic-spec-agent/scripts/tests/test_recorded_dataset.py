"""The training dataset folder, on a synthetic archive and revision package: held-out and excluded
recordings never enter it, a revision replaces a recording's trace and manifest as a pair only when
its receipt names the archive's own inputs, the label stays the archive's, and the data version
changes with any input."""
import csv
import hashlib
import io
import json
import tempfile
import unittest
import zipfile
from pathlib import Path

from recorded import dataset
from scripts.tests import test_recorded_archive as fixtures
from scripts.tests.test_recorded_archive import row

IDS = '"kin.speed", "st.lane"'


def fake_library(root: Path) -> Path:
    for split, ids in (("train", IDS), ("full", IDS + ', "sig.reverse_lamp"')):
        p = root / "splits" / split / "TrafficSpec/Core/Vocab/Ontology/Ids.lean"
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(f"def atomIds : List String := [{ids}]\n")
    return root


def make_archive(path: Path, rows: list[dict]) -> None:
    """The archive fixture with scenes-only traces, as the pipeline's traces are."""
    fixtures.make_archive(path, rows)
    with zipfile.ZipFile(path) as z:
        members = {n: z.read(n) for n in z.namelist()}
    for n, b in members.items():
        if n.endswith("lean_trace.json"):
            members[n] = json.dumps({"scenes": json.loads(b)["scenes"]}).encode()
    with zipfile.ZipFile(path, "w") as z:
        for n, b in members.items():
            z.writestr(n, b)


def trace_bytes(rid: str, archive_zip: Path) -> tuple[bytes, bytes]:
    with zipfile.ZipFile(archive_zip) as z:
        base = next(n for n in z.namelist() if rid in n and n.endswith("lean_trace.json")).rsplit("/", 1)[0]
        return z.read(base + "/lean_trace.json"), z.read(base + "/manifest.json")


def make_revision(path: Path, archive_zip: Path, rid: str, source_trace: bytes | None = None,
                  tamper_manifest: bool = False) -> bytes:
    orig_t, orig_m = trace_bytes(rid, archive_zip)
    new_t = json.dumps({"scenes": [{"t": 0, "users": [], "revised": True}]}).encode()
    new_m = json.dumps({"source": "rev", "atoms": {"kin.speed": "exact", "st.lane": "estimate:join"}}).encode()
    folder = f"cases/X--{rid[:6]}/"
    receipt = {"recording_id": rid, "revision": "rev-1",
               "source_trace_sha256": hashlib.sha256(source_trace or orig_t).hexdigest(),
               "source_manifest_sha256": hashlib.sha256(orig_m).hexdigest(),
               "derived_trace_sha256": hashlib.sha256(new_t).hexdigest(),
               "derived_manifest_sha256": hashlib.sha256(new_m).hexdigest()}
    buf = io.StringIO()
    w = csv.DictWriter(buf, ["case_id", "law_id", "recording_id", "lean_trace_sha256", "folder"])
    w.writeheader()
    w.writerow({"case_id": "X", "law_id": "NRS-1", "recording_id": rid, "lean_trace_sha256": receipt["derived_trace_sha256"],
                "folder": folder})
    with zipfile.ZipFile(path, "w") as z:
        z.writestr("index.csv", buf.getvalue())
        z.writestr(folder + "lean-trace.json", new_t)
        z.writestr(folder + "manifest.json", new_m.replace(b"estimate:join", b"exact") if tamper_manifest else new_m)
        z.writestr(folder + "receipt.json", json.dumps(receipt))
    return new_t


ROWS = [row("demo-train", "C1-a", "aaa111", label="violation", jc="True"), row("demo-train", "C1-a", "bbb222"),
        row("demo-train", "C2-b", "ccc333", label="Unresolved (no label assigned)"), row("demo-train", "C3-c", "ddd444"),
        row("demo-test", "C9-z", "zzz999")]


class DatasetTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.zip = self.root / "a.zip"
        make_archive(self.zip, ROWS)
        self.lib = fake_library(self.root / "lib")

    def tearDown(self):
        self.tmp.cleanup()

    def test_held_out_and_excluded_recordings_never_enter(self):
        meta = dataset.build(self.zip, self.root / "ds", self.lib, exclude={"ddd444": "operator: manifest pending"}, jobs=2)
        ds = dataset.Dataset(self.root / "ds")
        ids = {r["recording_id"] for r in ds.rows}
        self.assertEqual(ids, {"aaa111", "bbb222", "ccc333"})
        self.assertFalse((self.root / "ds/recordings/zzz999").exists())
        self.assertEqual(meta["excluded"], {"ddd444": "operator: manifest pending"})
        self.assertEqual((meta["counts"]["labelled_plain"], meta["counts"]["labelled_judgment_call"]), (1, 1))
        # projected onto the split: the active atoms and nothing else
        m = json.loads(ds.files("bbb222")["manifest"].read_text())
        self.assertEqual(set(m["atoms"]), {"kin.speed", "st.lane"})
        self.assertEqual(ds.label("aaa111").verdict, "violated")

    def test_a_revision_replaces_trace_and_manifest_and_keeps_the_label(self):
        rev = self.root / "rev.zip"
        make_revision(rev, self.zip, "bbb222")
        meta = dataset.build(self.zip, self.root / "ds", self.lib, revisions=[rev], jobs=2)
        ds = dataset.Dataset(self.root / "ds")
        f = ds.files("bbb222")
        self.assertIn('"revised":true', f["trace"].read_text())
        self.assertEqual(json.loads(f["manifest"].read_text())["atoms"]["st.lane"], "estimate:join")
        self.assertEqual(json.loads(f["source"].read_text())["revision"], "rev-1")
        self.assertEqual(ds.label("bbb222").verdict, "compliant")
        self.assertEqual(meta["counts"]["revised"], 1)
        plain = dataset.build(self.zip, self.root / "ds2", self.lib, jobs=2)
        self.assertNotEqual(meta["data_version"], plain["data_version"])

    def test_a_revision_of_another_trace_is_refused(self):
        rev = self.root / "rev.zip"
        make_revision(rev, self.zip, "bbb222", source_trace=b"some other trace")
        with self.assertRaises(dataset.DatasetError):
            dataset.build(self.zip, self.root / "ds", self.lib, revisions=[rev], jobs=1)
        self.assertFalse((self.root / "ds").exists())

    def test_a_revised_manifest_the_receipt_does_not_state_is_refused(self):
        rev = self.root / "rev.zip"
        make_revision(rev, self.zip, "bbb222", tamper_manifest=True)
        with self.assertRaises(dataset.DatasetError):
            dataset.build(self.zip, self.root / "ds", self.lib, revisions=[rev], jobs=1)

    def test_a_revision_or_exclusion_outside_the_training_set_is_refused(self):
        with self.assertRaises(dataset.DatasetError):
            dataset.build(self.zip, self.root / "ds", self.lib, exclude={"zzz999": "x"})

    def test_a_dataset_is_built_once(self):
        dataset.build(self.zip, self.root / "ds", self.lib, jobs=1)
        with self.assertRaises(dataset.DatasetError):
            dataset.build(self.zip, self.root / "ds", self.lib, jobs=1)


if __name__ == "__main__":
    unittest.main()
