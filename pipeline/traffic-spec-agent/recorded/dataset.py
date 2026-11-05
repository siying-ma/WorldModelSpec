"""The training dataset as a folder: every training recording projected onto the active split, with
its label, its projection record and where it came from, and one index over all of them.

Reason: the label check and evaluation read the same recordings many times; a folder built once by
this script, with a data version over every input, replaces streaming the archive on every run and
makes the training set inspectable. The archive and the revision packages are only read.

Layout of `<out>/`:
- `recordings/<recording_id>/`: `trace.json` and `manifest.json` (projected, what the monitor
  reads), `label.json` (the archive's, unchanged), `projection.json` (the projection record),
  `source.json` (the archive member or revision the trace and manifest came from, with their
  sha256 before projection);
- `INDEX.csv`: one row per recording (id, case, law, verdict, judgment call, revision, scenes, and
  the sha256 of the projected trace and manifest);
- `DATASET.json`: the data version, the split, the label contract the labels follow (v1, the whole
  recording, unless the build names v2, a scoring interval per label: `recorded.labels`), the
  sources, every excluded recording with its reason, and the counts.

A revision replaces a recording's trace and manifest as a pair, only when its receipt names the
archive's own trace and manifest as its source and the revised trace and manifest have the sha256
the receipt states; the label stays the archive's. The data version is the sha256 over the archive's version,
the split's atom ids, the label contract, and every recording's id with its projected trace and
manifest sha256, so any change of input gives a new version.
"""
from __future__ import annotations

import csv
import hashlib
import io
import json
import shutil
import zipfile
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path

from . import archive as archive_mod
from . import labels, projection

INDEX_FIELDS = ["recording_id", "case_id", "law_id", "verdict", "recorded_label", "judgment_call", "revision",
                "scenes", "trace_sha256", "manifest_sha256"]


class DatasetError(ValueError):
    pass


def _sha_stream(f) -> str:
    h = hashlib.sha256()
    for chunk in iter(lambda: f.read(1 << 22), b""):
        h.update(chunk)
    return h.hexdigest()


@dataclass(frozen=True)
class Revision:
    """One revised recording of a revision package (a zip with `index.csv` and per-case folders)."""
    package: str
    revision: str
    recording_id: str
    trace_member: str
    manifest_member: str
    trace_sha256: str
    manifest_sha256: str
    source_trace_sha256: str
    source_manifest_sha256: str


def read_revisions(package: str | Path) -> list[Revision]:
    """The revisions a package declares: per row of `index.csv`, its folder's `lean-trace.json`,
    `manifest.json` and `receipt.json`."""
    out = []
    with zipfile.ZipFile(package) as z:
        for row in csv.DictReader(io.StringIO(z.read("index.csv").decode("utf-8"))):
            folder = row["folder"].rstrip("/") + "/"
            receipt = json.loads(z.read(folder + "receipt.json"))
            if receipt.get("recording_id") != row["recording_id"]:
                raise DatasetError(f"{package}: {folder} receipt names another recording")
            if receipt.get("derived_trace_sha256") != row["lean_trace_sha256"]:
                raise DatasetError(f"{package}: {folder} receipt and index disagree on the trace")
            out.append(Revision(str(package), receipt.get("revision", ""), row["recording_id"], folder + "lean-trace.json",
                                folder + "manifest.json", row["lean_trace_sha256"], receipt["derived_manifest_sha256"],
                                receipt["source_trace_sha256"],
                                receipt["source_manifest_sha256"]))
    ids = [r.recording_id for r in out]
    if len(ids) != len(set(ids)):
        raise DatasetError(f"{package}: a recording is revised twice")
    return out


def build(archive_path: str | Path, out: str | Path, library: str | Path, split: str = "train",
          revisions: list[str | Path] = (), exclude: dict[str, str] | None = None, jobs: int = 6,
          pending: dict[str, str] | None = None, label_contract: str = "v1") -> dict:
    """Write the dataset folder. `exclude` maps a recording id to the reason it is left out;
    `pending` maps an included recording to a revision it awaits (it is used as the archive holds it);
    `label_contract` is the contract the archive's labels follow, stated by whoever builds it."""
    out, exclude = Path(out), dict(exclude or {})
    contract = labels.CONTRACTS[label_contract]
    if out.exists():
        raise DatasetError(f"{out} exists: a dataset is built once, into a new folder")
    active, full = projection.split_ids(library, split), projection.split_ids(library, "full")
    revs: dict[str, Revision] = {}
    for p in revisions:
        for r in read_revisions(p):
            if r.recording_id in revs:
                raise DatasetError(f"recording {r.recording_id} is revised by two packages")
            revs[r.recording_id] = r
    with archive_mod.Archive(archive_path) as a:
        recs = a.recordings()
        version = a.data_version
    train_ids = {r.recording_id for r in recs}
    pending = dict(pending or {})
    if set(pending) & (set(revs) | set(exclude)):
        raise DatasetError("a pending recording is also revised or excluded")
    unknown = (set(revs) | set(exclude) | set(pending)) - train_ids
    if unknown:
        raise DatasetError(f"not training recordings of the archive: {sorted(unknown)}")
    chosen = [r for r in recs if r.recording_id not in exclude]
    tmp = out.with_name(out.name + ".partial")
    if tmp.exists():
        shutil.rmtree(tmp)
    (tmp / "recordings").mkdir(parents=True)

    def one(rec: archive_mod.Recording) -> dict:
        d = tmp / "recordings" / rec.recording_id
        with archive_mod.Archive(archive_path) as a:                       # one reader per worker
            rec = a.recording(rec.recording_id)
            label_bytes = a.read_bytes(rec, "label")
            source = {"archive": str(archive_path), "archive_version": version, "trace_member": rec.trace,
                      "manifest_member": rec.manifest}
            rv = revs.get(rec.recording_id)
            if rv is None:
                mbytes = a.read_bytes(rec, "manifest")
                with a.open(rec, "trace") as tr:
                    prj = projection.project(tr, mbytes, d, active, full, split)
            else:
                with a.open(rec, "trace") as tr:
                    orig_trace = _sha_stream(tr)
                orig_manifest = hashlib.sha256(a.read_bytes(rec, "manifest")).hexdigest()
                if (orig_trace, orig_manifest) != (rv.source_trace_sha256, rv.source_manifest_sha256):
                    raise DatasetError(f"{rec.recording_id}: the revision's source is not this archive's trace and manifest")
                with zipfile.ZipFile(rv.package) as z:
                    mbytes = z.read(rv.manifest_member)
                    if hashlib.sha256(mbytes).hexdigest() != rv.manifest_sha256:
                        raise DatasetError(f"{rec.recording_id}: the revised manifest is not the one the receipt states")
                    with z.open(rv.trace_member) as tr:
                        prj = projection.project(tr, mbytes, d, active, full, split)
                if prj.input_sha256["trace.json"] != rv.trace_sha256:
                    raise DatasetError(f"{rec.recording_id}: the revised trace is not the one the package states")
                source.update({"revision": rv.revision, "revision_package": rv.package, "trace_member": rv.trace_member,
                               "manifest_member": rv.manifest_member, "replaces": {"trace_sha256": orig_trace,
                                                                                    "manifest_sha256": orig_manifest}})
        source["input_sha256"] = prj.input_sha256
        (d / "label.json").write_bytes(label_bytes)
        (d / "source.json").write_text(json.dumps(source, indent=1) + "\n", encoding="utf-8")
        lab = labels.parse(label_bytes, label_contract)
        return {"recording_id": rec.recording_id, "case_id": rec.case_id, "law_id": rec.law_id,
                "verdict": lab.verdict or "", "recorded_label": rec.recorded_label, "judgment_call": rec.judgment_call,
                "revision": source.get("revision", ""), "scenes": prj.scenes,
                "trace_sha256": prj.output_sha256["trace.json"], "manifest_sha256": prj.output_sha256["manifest.json"]}

    with ThreadPoolExecutor(jobs) as pool:
        rows = list(pool.map(one, chosen))
    buf = io.StringIO()
    w = csv.DictWriter(buf, INDEX_FIELDS)
    w.writeheader()
    w.writerows(rows)
    (tmp / "INDEX.csv").write_text(buf.getvalue(), encoding="utf-8")
    h = hashlib.sha256()
    for part in [version, split, json.dumps(sorted(active)), json.dumps(contract, sort_keys=True)] + \
            [f"{r['recording_id']}:{r['trace_sha256']}:{r['manifest_sha256']}" for r in sorted(rows, key=lambda r: r["recording_id"])]:
        h.update(part.encode("utf-8") + b"\0")
    meta = {"data_version": h.hexdigest(), "archive": str(archive_path), "archive_version": version, "split": split,
            "label_contract": contract, "revisions": sorted({str(p) for p in revisions}),
            "excluded": exclude, "pending_revision": pending, "held_out": f"the archive's {archive_mod.TEST} recordings are never read",
            "counts": {"recordings": len(rows), "revised": sum(bool(r["revision"]) for r in rows),
                       "labelled": sum(bool(r["verdict"]) for r in rows),
                       "labelled_plain": sum(bool(r["verdict"]) and not r["judgment_call"] for r in rows),
                       "labelled_judgment_call": sum(bool(r["verdict"]) and r["judgment_call"] for r in rows),
                       "scenes": sum(r["scenes"] for r in rows)}}
    (tmp / "DATASET.json").write_text(json.dumps(meta, indent=1) + "\n", encoding="utf-8")
    tmp.rename(out)
    return meta


class Dataset:
    """A built dataset folder, read only."""

    def __init__(self, path: str | Path):
        self.path = Path(path)
        self.meta = json.loads((self.path / "DATASET.json").read_text(encoding="utf-8"))
        with (self.path / "INDEX.csv").open(encoding="utf-8") as f:
            self.rows = list(csv.DictReader(f))
        ids = [r["recording_id"] for r in self.rows]
        if len(ids) != len(set(ids)):
            raise DatasetError(f"{self.path}: a recording is listed twice")

    @property
    def contract(self) -> str:
        """The label contract the dataset's labels follow (v1 when it states none)."""
        return labels.contract_of(self.meta.get("label_contract"))

    @property
    def data_version(self) -> str:
        return self.meta["data_version"]

    def keys(self) -> list[tuple[str, str]]:
        """Every (data version, recording id): the fixed set a run scores."""
        return [(self.data_version, r["recording_id"]) for r in self.rows]

    def files(self, recording_id: str) -> dict[str, Path]:
        d = self.path / "recordings" / recording_id
        return {k: d / f"{k}.json" for k in ("trace", "manifest", "label", "projection", "source")}

    def label(self, recording_id: str) -> labels.Label:
        return labels.parse(self.files(recording_id)["label"].read_bytes(), self.contract)
