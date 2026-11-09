"""The training dataset as a folder, built from one data delivery: every recording projected onto the
active split, each source's manifest projected once, the labels in one index, and a data version
over every input.

Reason: the label check and evaluation read the same recordings many times; a folder built once by
this script replaces reading the delivery on every run and makes the training set inspectable.

A delivery is independent: a dataset is built from exactly one, and its traces, manifests, labels
and validation all come from it; nothing of another delivery is mixed in, and a new delivery gives a
new dataset folder and a new data version. A delivery is a restored directory holding:
- `recordings.csv`: one row per recording (`recording_id`, `case_id`, `cell_id`, `law_id`, and the
  relative paths of its `video`, `trace` and `metadata`);
- `inputs/shared/manifest.json`: the manifest the delivery shares;
- `sets/demo-train/`: `manifest.json`, `scope.json` (the set id and split) and `selection.json`
  (every member with its split and status);
- per recording, beside its `trace.json`: `manifest.json` and `metadata.json` (`recording_id`,
  `case_id`, `law_id`, `expected_label`, `judgment_sweep`, `trace_sha256`, `manifest_sha256`, ...).

The build reads only the demo-train set: a recording whose path lies outside `work/demo-train/`, or
that the selection does not list as an accepted training member, is refused before any of its files
is read. Each trace and each recording's manifest must have the sha256 its metadata states; a
mismatch is refused. Recordings are grouped by the sha256 of their manifest: each group is one
source (a scene-graph generator or adapter version), since what can be observed depends on the
source, not on the recording.

Layout of `<out>/`:
- `sources/<manifest sha256>/`: `manifest.json` (projected onto the active split once per source:
  held-out atoms dropped, split atoms it does not list declared absent; what the monitor reads) and
  `projection.json` (the projection record);
- `recordings/<recording_id>/`: `trace.json` (projected: unchanged but for retired road-user
  classes) and `record.json` (its source, its delivery paths, the sha256 of its metadata, and the
  trace's projection record);
- `INDEX.csv`: one row per recording (id, case, law, source, normalized verdict, recorded label,
  judgment call, scenes, sha256 of the projected trace);
- `DATASET.json`: the layout, the data version, the split, the label contract (`recorded.labels`: a
  label judges the whole recording), the delivery's path and identity, the sources, every excluded
  recording with its reason, and the counts.

The delivery's identity is the sha256 over its shared files (`recordings.csv`, the shared manifest,
the set's manifest, scope and selection) and every included recording's metadata. The data version
is the sha256 over that identity, the split and its atom ids, the label contract, the exclusions,
each source's projected manifest sha256, and each recording's id, source, projected trace sha256 and
label fields, so any change of input gives a new version.

A dataset folder of any other layout is refused when it is read: it is rebuilt from one delivery.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import shutil
import sys
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path

from . import labels, projection

LAYOUT = "one-delivery-v1"
SET = "demo-train"
SET_SPLIT = "training"
INDEX_FIELDS = ["recording_id", "case_id", "law_id", "source", "verdict", "recorded_label", "judgment_call",
                "scenes", "trace_sha256"]
CSV_FIELDS = ["recording_id", "case_id", "cell_id", "law_id", "video", "trace", "metadata"]
SHARED_FILES = ["recordings.csv", "inputs/shared/manifest.json", f"sets/{SET}/manifest.json",
                f"sets/{SET}/scope.json", f"sets/{SET}/selection.json"]
REBUILD = "rebuild the dataset from one delivery (python -m recorded.dataset build <delivery> <out>)"


class DatasetError(ValueError):
    pass


def _sha(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()


def _inside(root: Path, rel: str, what: str) -> Path:
    """`root / rel`, refused when `rel` is absolute or leaves `root`."""
    p = Path(rel)
    if not rel or p.is_absolute() or ".." in p.parts:
        raise DatasetError(f"{what} {rel!r} is not a relative path inside the delivery")
    return root / p


def read_delivery(delivery: Path) -> tuple[list[dict], dict, dict]:
    """The delivery's rows of `recordings.csv`, its shared files (name → bytes) and its demo-train
    selection (recording id → its members). A file missing, a set or split other than demo-train, a row
    listed twice or a row whose paths leave the delivery is refused."""
    missing = [f for f in SHARED_FILES if not (delivery / f).is_file()]
    if missing:
        raise DatasetError(f"{delivery}: not a restored delivery, missing {missing}")
    shared = {f: (delivery / f).read_bytes() for f in SHARED_FILES}
    scope = json.loads(shared[f"sets/{SET}/scope.json"])
    if scope.get("set_id") != SET or scope.get("split", SET_SPLIT) != SET_SPLIT:
        raise DatasetError(f"{delivery}: the set is {scope.get('set_id')!r} ({scope.get('split')!r}); only the {SET} set "
                           f"({SET_SPLIT}) is read")
    members = json.loads(shared[f"sets/{SET}/selection.json"]).get("members") or []
    selection: dict[str, list[dict]] = {}
    for m in members:
        if m.get("recording_id"):
            selection.setdefault(m["recording_id"], []).append(m)
    reader = csv.DictReader(io.StringIO(shared["recordings.csv"].decode("utf-8")))
    if reader.fieldnames != CSV_FIELDS:
        raise DatasetError(f"{delivery}/recordings.csv: columns {reader.fieldnames}, expected {CSV_FIELDS}")
    rows = list(reader)
    ids = [r["recording_id"] for r in rows]
    if len(ids) != len(set(ids)):
        raise DatasetError(f"{delivery}/recordings.csv: a recording is listed twice")
    for r in rows:
        for k in ("trace", "metadata", "video"):
            _inside(delivery, r[k], f"recording {r['recording_id']}: {k}")
    return rows, shared, selection


def held_out(row: dict, selection: dict) -> str | None:
    """Why a row is not a demo-train recording (decided on the index and the selection alone, before
    any of its files is read); None when it is one."""
    rid = row["recording_id"]
    for k in ("trace", "metadata"):
        if Path(row[k]).parts[:2] != ("work", SET):
            return f"its {k} lies outside work/{SET}/"
    ms = selection.get(rid)
    if not ms:
        return f"the {SET} selection does not list it"
    for m in ms:
        if m.get("split") != SET_SPLIT or m.get("set", SET) != SET:
            return f"the selection marks it {m.get('set', m.get('split'))!r}, not {SET}"
    if not any(m.get("status") == "accepted" for m in ms):
        return f"the selection lists it {sorted(str(m.get('status')) for m in ms)}, not accepted"
    return None


def _project_one(args: tuple) -> dict:
    """Project one recording's trace (in a worker process), refused unless its sha256 is the one its
    metadata states."""
    rid, trace_in, out_dir, want_sha = args
    with Path(trace_in).open("rb") as f:
        rec = projection.project_trace(f, Path(out_dir) / "trace.json")
    if rec.input_sha256 != want_sha:
        raise DatasetError(f"recording {rid}: its trace's sha256 {rec.input_sha256} is not the {want_sha} its metadata states")
    return rec.to_dict()


def data_version(identity: str, split: str, active: list[str], exclude: dict[str, str], sources: dict[str, dict],
                 rows: list[dict]) -> str:
    """The sha256 over every input of a dataset (see the module's description)."""
    parts = [["delivery", identity], ["split", split, sorted(active)], ["label_contract", labels.CONTRACT],
             ["excluded", sorted(exclude.items())]]
    parts += [["source", s, sources[s]["manifest_sha256"]] for s in sorted(sources)]
    parts += [["recording", r["recording_id"], r["source"], r["trace_sha256"], r["recorded_label"], r["verdict"],
               r["judgment_call"]] for r in sorted(rows, key=lambda r: r["recording_id"])]
    h = hashlib.sha256()
    for p in parts:
        h.update(json.dumps(p, sort_keys=True).encode("utf-8") + b"\0")
    return h.hexdigest()


def build(delivery: str | Path, out: str | Path, library: str | Path, split: str = "train", jobs: int = 4,
          exclude: dict[str, str] | None = None) -> dict:
    """Write the dataset folder `out` from the restored `delivery`. `exclude` maps a recording id of
    the delivery to the reason it is left out (none of its files is read). Returns `DATASET.json`."""
    delivery, out, exclude = Path(delivery).resolve(), Path(out), dict(exclude or {})
    if out.exists():
        raise DatasetError(f"{out} exists: a dataset is built once, into a new folder")
    active, full = projection.split_ids(Path(library), split), projection.split_ids(Path(library), "full")
    rows_in, shared, selection = read_delivery(delivery)
    unknown = set(exclude) - {r["recording_id"] for r in rows_in}
    if unknown:
        raise DatasetError(f"excluded recordings the delivery does not list: {sorted(unknown)}")
    refused = [f"{r['recording_id']}: {why}" for r in rows_in if (why := held_out(r, selection))]
    if refused:
        raise DatasetError(f"held out or not in the {SET} set, refused: " + "; ".join(refused[:6]))
    chosen = [r for r in rows_in if r["recording_id"] not in exclude]

    # metadata, labels and manifests: small, read first; every check before a trace is projected
    recs, manifests, meta_sha = [], {}, {}
    for r in chosen:
        rid = r["recording_id"]
        trace, mpath = _inside(delivery, r["trace"], "trace"), _inside(delivery, r["metadata"], "metadata")
        if trace.parent != mpath.parent:
            raise DatasetError(f"recording {rid}: its trace and metadata are not in one folder")
        mbytes = mpath.read_bytes() if mpath.is_file() else None
        if mbytes is None or not trace.is_file() or not (trace.parent / "manifest.json").is_file():
            raise DatasetError(f"recording {rid}: its trace, manifest or metadata is missing from the delivery")
        try:
            meta = json.loads(mbytes)
        except ValueError as e:
            raise DatasetError(f"recording {rid}: its metadata is not JSON ({e})") from None
        for k in ("recording_id", "case_id", "law_id"):
            if meta.get(k) != r[k]:
                raise DatasetError(f"recording {rid}: its metadata's {k} {meta.get(k)!r} is not the index's {r[k]!r}")
        try:
            lab = labels.from_metadata(meta, f"recording {rid} metadata")
        except labels.LabelError as e:
            raise DatasetError(str(e)) from None
        man = (trace.parent / "manifest.json").read_bytes()
        man_sha = _sha(man)
        if man_sha != meta.get("manifest_sha256"):
            raise DatasetError(f"recording {rid}: its manifest's sha256 {man_sha} is not the {meta.get('manifest_sha256')} "
                               "its metadata states")
        if not isinstance(meta.get("trace_sha256"), str) or len(meta["trace_sha256"]) != 64:
            raise DatasetError(f"recording {rid}: its metadata states no trace sha256")
        manifests.setdefault(man_sha, man)
        meta_sha[rid] = _sha(mbytes)
        recs.append((r, meta, lab, man_sha, trace))

    tmp = out.with_name(out.name + ".partial")
    if tmp.exists():
        shutil.rmtree(tmp)
    try:
        (tmp / "recordings").mkdir(parents=True)
        shared_sha = _sha(shared["inputs/shared/manifest.json"])
        sources = {}
        for s, man in sorted(manifests.items()):
            try:
                prj = projection.write_manifest(man, tmp / "sources" / s, active, full, split)
            except projection.ProjectionError as e:
                raise DatasetError(f"source {s}: {e}") from None
            doc = json.loads(man)
            sources[s] = {"manifest_sha256": prj.output_sha256, "source": doc.get("source"),
                          "shared_manifest": s == shared_sha, "excluded_atoms": len(prj.excluded),
                          "added_absent": len(prj.added_absent),
                          "recordings": sum(1 for x in recs if x[3] == s)}
        work = [(r["recording_id"], str(trace), str(tmp / "recordings" / r["recording_id"]), meta["trace_sha256"])
                for r, meta, _lab, _s, trace in recs]
        if jobs <= 1 or len(work) <= 1:
            done = [_project_one(w) for w in work]
        else:
            with ProcessPoolExecutor(min(jobs, len(work))) as pool:
                done = list(pool.map(_project_one, work))
        rows = []
        for (r, meta, lab, s, trace), prj in zip(recs, done):
            rid = r["recording_id"]
            record = {"recording_id": rid, "source": s,
                      "delivery": {"trace": r["trace"], "manifest": str(Path(r["trace"]).parent / "manifest.json"),
                                   "metadata": r["metadata"], "metadata_sha256": meta_sha[rid]},
                      "trace_projection": prj}
            (tmp / "recordings" / rid / "record.json").write_text(json.dumps(record, indent=1) + "\n", encoding="utf-8")
            rows.append({"recording_id": rid, "case_id": r["case_id"], "law_id": r["law_id"], "source": s,
                         "verdict": lab.verdict or "", "recorded_label": lab.recorded_label,
                         "judgment_call": lab.judgment_call, "scenes": prj["scenes"], "trace_sha256": prj["output_sha256"]})
        buf = io.StringIO()
        w = csv.DictWriter(buf, INDEX_FIELDS)
        w.writeheader()
        w.writerows(rows)
        (tmp / "INDEX.csv").write_text(buf.getvalue(), encoding="utf-8")
        files_sha = {f: _sha(b) for f, b in shared.items()}
        h = hashlib.sha256()
        for part in [f"{f}:{files_sha[f]}" for f in SHARED_FILES] + [f"metadata:{rid}:{meta_sha[rid]}" for rid in sorted(meta_sha)]:
            h.update(part.encode("utf-8") + b"\0")
        identity = h.hexdigest()
        scope = json.loads(shared[f"sets/{SET}/scope.json"])
        version = data_version(identity, split, active, exclude, sources, rows)
        meta = {"layout": LAYOUT, "data_version": version, "split": split, "split_atoms": len(active),
                "label_contract": labels.CONTRACT,
                "delivery": {"path": str(delivery), "identity": identity, "files": files_sha, "set": SET,
                             "scope_source_version": scope.get("source_version"),
                             "law_split_version": scope.get("law_split_version")},
                "sources": sources, "excluded": exclude,
                "held_out": f"only the {SET} set is read; a recording outside it is refused before any of its files is read",
                "counts": {"recordings": len(rows), "sources": len(sources),
                           "labelled": sum(bool(r["verdict"]) for r in rows),
                           "labelled_plain": sum(bool(r["verdict"]) and not r["judgment_call"] for r in rows),
                           "labelled_judgment_call": sum(bool(r["verdict"]) and r["judgment_call"] for r in rows),
                           "unlabelled": sum(not r["verdict"] for r in rows),
                           "scenes": sum(r["scenes"] for r in rows)}}
        (tmp / "DATASET.json").write_text(json.dumps(meta, indent=1) + "\n", encoding="utf-8")
        tmp.rename(out)
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise
    return meta


class Dataset:
    """A built dataset folder, read only. A folder of another layout is refused, never half-read."""

    def __init__(self, path: str | Path):
        self.path = Path(path)
        f = self.path / "DATASET.json"
        if not f.is_file():
            raise DatasetError(f"{self.path}: no DATASET.json, not a dataset folder")
        self.meta = json.loads(f.read_text(encoding="utf-8"))
        with (self.path / "INDEX.csv").open(encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            self.rows = list(reader)
        if self.meta.get("layout") != LAYOUT or reader.fieldnames != INDEX_FIELDS or not (self.path / "sources").is_dir():
            raise DatasetError(f"{self.path}: not a dataset of the current layout (one delivery, one manifest per source, "
                               f"the labels in the index): {REBUILD}")
        try:
            labels.require_v1(self.meta, f"{self.path}/DATASET.json")
        except ValueError as e:
            raise DatasetError(str(e)) from None
        self.sources: dict[str, dict] = dict(self.meta.get("sources") or {})
        self._row = {r["recording_id"]: r for r in self.rows}
        if len(self._row) != len(self.rows):
            raise DatasetError(f"{self.path}: a recording is listed twice")
        bad = sorted(r["recording_id"] for r in self.rows if r["source"] not in self.sources)
        if bad:
            raise DatasetError(f"{self.path}: recordings name a source DATASET.json does not list: {bad[:6]}")

    @property
    def data_version(self) -> str:
        return self.meta["data_version"]

    def keys(self) -> list[tuple[str, str]]:
        """Every (data version, recording id): the fixed set a run scores."""
        return [(self.data_version, r["recording_id"]) for r in self.rows]

    def row(self, recording_id: str) -> dict:
        return self._row[recording_id]

    def files(self, recording_id: str) -> dict[str, Path]:
        """The recording's projected trace, its source's projected manifest, and its record."""
        d = self.path / "recordings" / recording_id
        return {"trace": d / "trace.json", "manifest": self.path / "sources" / self.row(recording_id)["source"] / "manifest.json",
                "record": d / "record.json"}

    def expected_sha256(self, recording_id: str) -> dict[str, str]:
        """The sha256 the dataset states for the recording's trace and its source's manifest."""
        r = self.row(recording_id)
        return {"trace": r["trace_sha256"], "manifest": self.sources[r["source"]]["manifest_sha256"]}

    def label(self, recording_id: str) -> labels.Label:
        """The recording's label from the index, read again under the label contract; an index row whose
        verdict or judgment call is not what its recorded label gives is refused."""
        r = self.row(recording_id)
        where = f"{self.path}/INDEX.csv {recording_id}"
        if r["judgment_call"] not in ("True", "False"):
            raise DatasetError(f"{where}: judgment_call {r['judgment_call']!r} is not True or False")
        try:
            verdict = labels.verdict_of(r["recorded_label"])
        except ValueError as e:
            raise DatasetError(f"{where}: {e}") from None
        if (verdict or "") != r["verdict"]:
            raise DatasetError(f"{where}: verdict {r['verdict']!r} is not the {verdict!r} its recorded label gives")
        return labels.Label(law_id=r["law_id"], verdict=verdict, recorded_label=r["recorded_label"],
                            judgment_call=r["judgment_call"] == "True")


def main(argv: list[str]) -> int:
    """python -m recorded.dataset build <delivery_dir> <out_dir> [--split train] [--jobs N] [--exclude FILE] [--library DIR]"""
    p = argparse.ArgumentParser(prog="python -m recorded.dataset", description=main.__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build", help="build a dataset folder from one restored delivery")
    b.add_argument("delivery")
    b.add_argument("out")
    b.add_argument("--split", default="train")
    b.add_argument("--jobs", type=int, default=4)
    b.add_argument("--exclude", default="", help="a JSON file mapping a recording id to the reason it is left out")
    b.add_argument("--library", default=str(Path(__file__).resolve().parents[1] / "library"))
    a = p.parse_args(argv)
    exclude = json.loads(Path(a.exclude).read_text(encoding="utf-8")) if a.exclude else {}
    try:
        meta = build(a.delivery, a.out, a.library, a.split, a.jobs, exclude)
    except (DatasetError, projection.ProjectionError) as e:
        print(f"refused: {e}", file=sys.stderr)
        return 2
    print(json.dumps({k: meta[k] for k in ("data_version", "split", "counts")} | {"sources": sorted(meta["sources"])}, indent=1))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
