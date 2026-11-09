"""The training dataset folder, built from one synthetic delivery: recordings grouped into sources by
their manifest, each source's manifest projected once, the labels normalized into the index, a trace
or manifest whose sha256 is not the one its metadata states refused, a held-out recording refused
before its files are read, a dataset of the old layout refused when read, and a data version that
changes with any input."""
import contextlib
import csv
import hashlib
import io
import json
import shutil
import tempfile
import unittest
from pathlib import Path

from recorded import dataset, labels

IDS = '"kin.speed", "st.lane"'
M1 = {"source": "gen-a", "reid_gap": 0, "atoms": {"kin.speed": "exact", "sig.reverse_lamp": "absent"}}
M2 = {"source": "gen-b", "reid_gap": 0, "atoms": {"kin.speed": "estimate:x", "st.lane": "exact"}}


def fake_library(root: Path, ids: str = IDS) -> Path:
    """A library with only the split atom lists (`full` adds one held-out atom)."""
    for split, xs in (("train", ids), ("full", ", ".join(x for x in (ids, '"sig.reverse_lamp"') if x))):
        p = root / "splits" / split / "TrafficSpec/Core/Vocab/Ontology/Ids.lean"
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(f"def atomIds : List String := [{xs}]\n")
    return root


def scenes_doc(times=(0, 50)) -> bytes:
    return json.dumps({"scenes": [{"t": t, "users": []} for t in times]}).encode()


def make_delivery(root: Path, recs: list[dict], shared: dict = M1, split_of: dict | None = None) -> Path:
    """A restored delivery. Each rec: `rid`, `law`, `label` (str or None), `jc`, and optionally
    `manifest` (dict, default `shared`), `trace` (bytes), `meta` (fields overriding the metadata)."""
    rows = []
    members = []
    for r in recs:
        rid, law = r["rid"], r["law"]
        d = root / "work" / dataset.SET / f"C1--{law}" / f"case-{rid}--{rid[:12]}"
        d.mkdir(parents=True)
        trace = r.get("trace", scenes_doc())
        man = (json.dumps(r.get("manifest", shared), indent=2) + "\n").encode()
        (d / "trace.json").write_bytes(trace)
        (d / "manifest.json").write_bytes(man)
        meta = {"recording_id": rid, "case_id": f"case-{rid}", "law_id": law, "expected_label": r["label"],
                "judgment_sweep": r["jc"], "manifest_sha256": hashlib.sha256(man).hexdigest(),
                "trace_sha256": hashlib.sha256(trace).hexdigest(), "status": "accepted", "schema": "final-review-recording-v1",
                **r.get("meta", {})}
        (d / "metadata.json").write_text(json.dumps(meta, indent=2))
        rel = d.relative_to(root)
        rows.append({"recording_id": rid, "case_id": f"case-{rid}", "cell_id": "C1", "law_id": law,
                     "video": str(rel / "video.webm"), "trace": str(rel / "trace.json"), "metadata": str(rel / "metadata.json")})
        members.append({"recording_id": rid, "case_id": f"case-{rid}", "law_id": law, "status": "accepted",
                        "split": (split_of or {}).get(rid, "training")})
    with (root / "recordings.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, dataset.CSV_FIELDS)
        w.writeheader()
        w.writerows(rows)
    (root / "inputs/shared").mkdir(parents=True)
    (root / "inputs/shared/manifest.json").write_text(json.dumps(shared, indent=2) + "\n")
    (root / "inputs/shared/reading.json").write_text("{}")
    s = root / "sets" / dataset.SET
    s.mkdir(parents=True)
    (s / "manifest.json").write_text(json.dumps(shared, indent=2) + "\n")
    (s / "scope.json").write_text(json.dumps({"set_id": dataset.SET, "split": "training", "source_version": "sv"}))
    (s / "selection.json").write_text(json.dumps({"members": members}))
    return root


RECS = [{"rid": "aaa111", "law": "NRS-1", "label": "violation", "jc": True},
        {"rid": "bbb222", "law": "NRS-1", "label": "compliant", "jc": False},
        {"rid": "ccc333", "law": "NRS-2", "label": None, "jc": True, "manifest": M2},
        {"rid": "ddd444", "law": "NRS-2", "label": "non_compliant", "jc": False, "manifest": M2}]


class _Fixture(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.lib = fake_library(self.root / "lib")

    def tearDown(self):
        self.tmp.cleanup()

    def delivery(self, recs=RECS, name="dl", **kw) -> Path:
        return make_delivery(self.root / name, recs, **kw)

    def build(self, dl: Path, name="ds", **kw) -> dict:
        return dataset.build(dl, self.root / name, self.lib, jobs=kw.pop("jobs", 1), **kw)


class Build(_Fixture):

    def test_two_sources_each_manifest_projected_once(self):
        meta = self.build(self.delivery(), jobs=2)
        ds = dataset.Dataset(self.root / "ds")
        s1, s2 = (hashlib.sha256((json.dumps(m, indent=2) + "\n").encode()).hexdigest() for m in (M1, M2))
        self.assertEqual(set(ds.sources), {s1, s2})
        self.assertEqual(sorted(p.name for p in (self.root / "ds/sources").iterdir()), sorted([s1, s2]))
        self.assertEqual({r["recording_id"]: r["source"] for r in ds.rows},
                         {"aaa111": s1, "bbb222": s1, "ccc333": s2, "ddd444": s2})
        self.assertEqual((ds.sources[s1]["recordings"], ds.sources[s1]["shared_manifest"], ds.sources[s2]["shared_manifest"]),
                         (2, True, False))
        # the source's manifest is the one every recording of it reads, projected onto the split
        self.assertEqual(ds.files("aaa111")["manifest"], ds.files("bbb222")["manifest"])
        m = json.loads(ds.files("aaa111")["manifest"].read_text())
        self.assertEqual(m["atoms"], {"kin.speed": "exact", "st.lane": "absent"})
        self.assertEqual(m["source"], "gen-a")
        prj = json.loads((self.root / "ds/sources" / s1 / "projection.json").read_text())
        self.assertEqual((prj["excluded_kind"], prj["added_absent"], prj["input_sha256"]),
                         ({"sig.reverse_lamp": "held_out"}, ["st.lane"], s1))
        self.assertEqual(ds.expected_sha256("aaa111")["manifest"], hashlib.sha256(ds.files("aaa111")["manifest"].read_bytes()).hexdigest())
        # no manifest per recording; a small record per recording
        self.assertEqual(sorted(p.name for p in (self.root / "ds/recordings/aaa111").iterdir()), ["record.json", "trace.json"])
        rec = json.loads(ds.files("aaa111")["record"].read_text())
        self.assertEqual((rec["source"], rec["trace_projection"]["scenes"]), (s1, 2))
        self.assertEqual(rec["trace_projection"]["output_sha256"], ds.row("aaa111")["trace_sha256"])
        self.assertEqual(meta["counts"], {"recordings": 4, "sources": 2, "labelled": 3, "labelled_plain": 2,
                                          "labelled_judgment_call": 1, "unlabelled": 1, "scenes": 8})
        self.assertEqual(meta["layout"], dataset.LAYOUT)
        self.assertEqual(meta["label_contract"], labels.CONTRACT)
        self.assertEqual(meta["delivery"]["path"], str((self.root / "dl").resolve()))
        self.assertEqual(len(meta["delivery"]["identity"]), 64)

    def test_labels_are_normalized_into_the_index(self):
        self.build(self.delivery())
        ds = dataset.Dataset(self.root / "ds")
        got = {r["recording_id"]: (r["verdict"], r["recorded_label"], r["judgment_call"]) for r in ds.rows}
        self.assertEqual(got, {"aaa111": ("violated", "violation", "True"), "bbb222": ("compliant", "compliant", "False"),
                               "ccc333": ("", "", "True"), "ddd444": ("violated", "non_compliant", "False")})
        self.assertEqual((ds.label("aaa111").verdict, ds.label("aaa111").judgment_call), ("violated", True))
        self.assertIsNone(ds.label("ccc333").verdict)

    def test_an_unknown_label_string_is_refused(self):
        dl = self.delivery([{**RECS[0], "label": "probably fine"}])
        with self.assertRaisesRegex(dataset.DatasetError, "unrecognized label 'probably fine'"):
            self.build(dl)
        self.assertFalse((self.root / "ds").exists())
        self.assertFalse((self.root / "ds.partial").exists())

    def test_a_label_without_a_judgment_flag_or_under_another_contract_is_refused(self):
        for meta, why in (({"judgment_sweep": None}, "judgment_sweep"), ({"label_contract": "v2"}, "label contract 'v2' is refused")):
            with self.subTest(why=why):
                shutil.rmtree(self.root / "dl", ignore_errors=True)
                with self.assertRaisesRegex(dataset.DatasetError, why):
                    self.build(self.delivery([{**RECS[1], "meta": meta}]))

    def test_a_trace_or_manifest_sha_mismatch_is_refused(self):
        for which in ("trace", "manifest"):
            with self.subTest(which=which):
                shutil.rmtree(self.root / "dl", ignore_errors=True)
                dl = self.delivery()
                f = next((dl / "work").rglob(f"*bbb222/{which}.json"))
                f.write_bytes(f.read_bytes().replace(b"0", b"1", 1))
                with self.assertRaisesRegex(dataset.DatasetError, f"bbb222: its {which}'s sha256 .* its metadata states"):
                    self.build(dl, jobs=2)
                self.assertFalse((self.root / "ds").exists())
                self.assertFalse((self.root / "ds.partial").exists())

    def test_a_demo_test_recording_is_refused_and_never_read(self):
        dl = self.delivery(split_of={"ddd444": "testing"})
        held = next((dl / "work").rglob("*ddd444"))
        for f in held.iterdir():
            f.write_text("held out: must not be read")
        with self.assertRaisesRegex(dataset.DatasetError, "ddd444: the selection marks it 'testing'"):
            self.build(dl)
        # a recording filed under another set's folder is refused on its path alone
        shutil.rmtree(dl)
        dl = self.delivery()
        moved = dl / "work/demo-test"
        (dl / "work" / dataset.SET).rename(moved)
        text = (dl / "recordings.csv").read_text().replace("work/demo-train/", "work/demo-test/")
        (dl / "recordings.csv").write_text(text)
        with self.assertRaisesRegex(dataset.DatasetError, "outside work/demo-train/"):
            self.build(dl)
        # a recording the selection does not list is refused too
        shutil.rmtree(dl)
        dl = self.delivery()
        sel = dl / "sets" / dataset.SET / "selection.json"
        sel.write_text(json.dumps({"members": json.loads(sel.read_text())["members"][1:]}))
        with self.assertRaisesRegex(dataset.DatasetError, "aaa111: the demo-train selection does not list it"):
            self.build(dl)

    def test_another_set_is_refused(self):
        dl = self.delivery()
        (dl / "sets" / dataset.SET / "scope.json").write_text(json.dumps({"set_id": "demo-test", "split": "testing"}))
        with self.assertRaisesRegex(dataset.DatasetError, "only the demo-train set"):
            self.build(dl)

    def test_exclusions_are_kept_with_their_reasons_and_not_read(self):
        dl = self.delivery()
        next((dl / "work").rglob("*ddd444/trace.json")).write_text("broken")
        meta = self.build(dl, exclude={"ddd444": "operator: trace pending"})
        self.assertEqual(meta["excluded"], {"ddd444": "operator: trace pending"})
        self.assertEqual({r["recording_id"] for r in dataset.Dataset(self.root / "ds").rows}, {"aaa111", "bbb222", "ccc333"})
        with self.assertRaisesRegex(dataset.DatasetError, "does not list"):
            self.build(dl, name="ds2", exclude={"zzz": "x"})

    def test_a_dataset_is_built_once(self):
        dl = self.delivery()
        self.build(dl)
        with self.assertRaisesRegex(dataset.DatasetError, "exists"):
            self.build(dl)

    def test_the_command_line_builds_and_refuses_an_existing_folder(self):
        dl = self.delivery()
        argv = ["build", str(dl), str(self.root / "ds"), "--library", str(self.lib), "--jobs", "1"]
        with contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(dataset.main(argv), 0)
        self.assertEqual(json.loads(out.getvalue())["counts"]["recordings"], 4)
        with contextlib.redirect_stderr(io.StringIO()) as err:
            self.assertEqual(dataset.main(argv), 2)
        self.assertIn("exists", err.getvalue())


class DataVersion(_Fixture):

    def version(self, recs, name, **kw) -> str:
        return self.build(self.delivery(recs, name=name + ".dl", **kw), name=name)["data_version"]

    def test_the_same_inputs_give_the_same_version(self):
        self.assertEqual(self.version(RECS, "a"), self.version(RECS, "b"))

    def test_a_changed_label_or_judgment_flag_changes_the_version(self):
        base = self.version(RECS, "a")
        self.assertNotEqual(base, self.version([{**RECS[0], "label": "compliant"}] + RECS[1:], "b"))
        self.assertNotEqual(base, self.version([{**RECS[0], "jc": False}] + RECS[1:], "c"))
        self.assertNotEqual(base, self.version([{**RECS[0], "label": "violated"}] + RECS[1:], "d"))   # the raw label too

    def test_a_changed_manifest_or_trace_changes_the_version(self):
        base = self.version(RECS, "a")
        m3 = {**M2, "atoms": {**M2["atoms"], "st.lane": "estimate:y"}}
        self.assertNotEqual(base, self.version(RECS[:2] + [{**r, "manifest": m3} for r in RECS[2:]], "b"))
        self.assertNotEqual(base, self.version([{**RECS[0], "trace": scenes_doc((0, 50, 100))}] + RECS[1:], "c"))

    def test_another_split_changes_the_version(self):
        dl = self.delivery()
        a = self.build(dl, name="a")["data_version"]
        fake_library(self.lib, IDS + ', "kin.yaw_rate"')
        self.assertNotEqual(a, self.build(dl, name="b")["data_version"])


class Reader(_Fixture):

    def test_the_old_layout_is_refused(self):
        old = self.root / "old"
        (old / "recordings" / "r1").mkdir(parents=True)
        for f in ("trace.json", "manifest.json", "label.json", "projection.json", "source.json"):
            (old / "recordings" / "r1" / f).write_text("{}")
        with (old / "INDEX.csv").open("w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["recording_id", "case_id", "law_id", "verdict", "recorded_label", "judgment_call", "revision",
                        "scenes", "trace_sha256", "manifest_sha256"])
            w.writerow(["r1", "c", "NRS-1", "compliant", "compliant", "False", "", "1", "", ""])
        (old / "DATASET.json").write_text(json.dumps({"data_version": "x", "archive": "a.zip", "revisions": []}))
        with self.assertRaisesRegex(dataset.DatasetError, "rebuild the dataset from one delivery"):
            dataset.Dataset(old)

    def test_an_index_row_whose_verdict_its_label_does_not_give_is_refused(self):
        self.build(self.delivery())
        idx = self.root / "ds/INDEX.csv"
        idx.write_text(idx.read_text().replace("violated,violation", "compliant,violation"))
        with self.assertRaisesRegex(dataset.DatasetError, "is not the 'violated' its recorded label gives"):
            dataset.Dataset(self.root / "ds").label("aaa111")

    def test_a_dataset_stating_another_contract_is_refused(self):
        self.build(self.delivery())
        f = self.root / "ds/DATASET.json"
        meta = json.loads(f.read_text())
        for ok in ("v1", labels.CONTRACT):
            f.write_text(json.dumps({**meta, "label_contract": ok}))
            dataset.Dataset(self.root / "ds")
        for bad in ("v2", {"version": "v2", "subject": "ego", "scope": "scoring interval"}):
            f.write_text(json.dumps({**meta, "label_contract": bad}))
            with self.subTest(bad=bad), self.assertRaisesRegex(dataset.DatasetError, "is refused"):
                dataset.Dataset(self.root / "ds")


class Labels(unittest.TestCase):

    def test_the_normalization_table(self):
        table = {"violation": "violated", "violated": "violated", "non_compliant": "violated", "Non_Compliant ": "violated",
                 "compliant": "compliant", "not applicable": "not_applicable", "not_applicable": "not_applicable",
                 None: None, "": None, "unknown": None, "inconclusive": None, "Unresolved (no label assigned)": None,
                 "Unresolved (judgment call)": None}
        for raw, want in table.items():
            with self.subTest(raw=raw):
                self.assertEqual(labels.verdict_of(raw), want)
        for bad in ("noncompliant", "maybe", "violation?"):
            with self.subTest(bad=bad), self.assertRaisesRegex(labels.LabelError, "unrecognized label"):
                labels.verdict_of(bad)

    def test_a_judgment_call_keeps_its_verdict(self):
        lab = labels.from_metadata({"law_id": "NRS-1", "expected_label": "violation", "judgment_sweep": True})
        self.assertEqual((lab.verdict, lab.judgment_call, lab.recorded_label), ("violated", True, "violation"))
        lab = labels.from_metadata({"law_id": "NRS-1", "expected_label": None, "judgment_sweep": True})
        self.assertEqual((lab.verdict, lab.judgment_call, lab.recorded_label), (None, True, ""))

    def test_a_label_stating_another_contract_is_refused(self):
        base = {"law_id": "L", "expected_label": "compliant", "judgment_sweep": False}
        for ok in (base, {**base, "label_contract": "v1"}, {**base, "label_contract": labels.CONTRACT}):
            self.assertEqual(labels.from_metadata(ok).verdict, "compliant")
        for bad in ("v2", None, "", {"scope": "the part we like"}, {**labels.CONTRACT, "scope": "scoring interval"}):
            with self.subTest(bad=bad), self.assertRaisesRegex(ValueError, "label contract .* is refused"):
                labels.from_metadata({**base, "label_contract": bad, "scoring_interval": {"start_ms": 0, "end_ms": 1}})


if __name__ == "__main__":
    unittest.main()
