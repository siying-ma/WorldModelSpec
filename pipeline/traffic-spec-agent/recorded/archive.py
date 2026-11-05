"""The labelled recording archive, read by recording id without extracting it.

Reason: training reads 189 recordings of about 100 MB each from a zip stored in 4 GB parts; reading
members in place keeps scratch small, and keying every record by (data version, recording id)
keeps two recordings of one case apart (a case id is not unique).

The archive is a zip, either one file or a directory of parts (`part-00`, `part-01`, …) that
concatenate to it. `INDEX.csv` lists every recording with its set (`demo-train` or `demo-test`),
case, law, label fields and member paths; a recording's `label.json` sits beside its trace.
`demo-test` recordings are held out: they are never listed for training and their members are
never read unless the caller asks for the test set explicitly.
"""
from __future__ import annotations

import bisect
import csv
import hashlib
import io
import os
import shutil
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator

TRAIN, TEST = "demo-train", "demo-test"


class ArchiveError(Exception):
    pass


class _Parts(io.RawIOBase):
    """The parts of a split zip, read as one seekable stream."""

    def __init__(self, parts: list[Path]):
        self._files = [open(p, "rb") for p in parts]
        self._offsets = [0]
        for p in parts:
            self._offsets.append(self._offsets[-1] + os.path.getsize(p))
        self._pos = 0

    def readable(self) -> bool:
        return True

    def seekable(self) -> bool:
        return True

    def tell(self) -> int:
        return self._pos

    def seek(self, offset: int, whence: int = 0) -> int:
        self._pos = offset if whence == 0 else self._pos + offset if whence == 1 else self._offsets[-1] + offset
        return self._pos

    def readinto(self, b) -> int:
        want, got, end = len(b), 0, self._offsets[-1]
        while got < want and self._pos < end:
            i = bisect.bisect_right(self._offsets, self._pos) - 1
            f = self._files[i]
            f.seek(self._pos - self._offsets[i])
            chunk = f.read(min(want - got, self._offsets[i + 1] - self._pos))
            b[got:got + len(chunk)] = chunk
            got += len(chunk)
            self._pos += len(chunk)
        return got

    def close(self) -> None:
        for f in self._files:
            f.close()
        super().close()


@dataclass(frozen=True)
class Recording:
    data_version: str
    recording_id: str
    case_id: str
    cell_id: str
    law_id: str
    set: str
    recorded_label: str
    judgment_call: bool
    trace: str          # member path of lean_trace.json
    manifest: str       # member path of manifest.json
    validation: str
    label: str          # member path of label.json

    @property
    def key(self) -> tuple[str, str]:
        return (self.data_version, self.recording_id)


class Archive:
    """The archive at `path` (a zip, or a directory of its parts)."""

    def __init__(self, path: str | Path):
        path = Path(path)
        if path.is_dir():
            parts = sorted(p for p in path.iterdir() if p.is_file() and p.name.startswith("part-"))
            if not parts:
                raise ArchiveError(f"{path}: no part-NN files")
            self._raw = _Parts(parts)
            self._zip = zipfile.ZipFile(io.BufferedReader(self._raw, 1 << 22))
        else:
            self._raw = None
            self._zip = zipfile.ZipFile(path)
        self.path = path
        names = set(self._zip.namelist())
        for need in ("INDEX.csv", "MANIFEST.json"):
            if need not in names:
                raise ArchiveError(f"{path}: no {need}")
        index = self._zip.read("INDEX.csv")
        self.data_version = hashlib.sha256(index + b"\0" + self._zip.read("MANIFEST.json")).hexdigest()
        self._recordings: dict[tuple[str, str], Recording] = {}
        for row in csv.DictReader(io.StringIO(index.decode("utf-8"))):
            trace = row["lean_trace"]
            rec = Recording(self.data_version, row["recording_id"], row["case_id"], row["cell_id"], row["law_id"],
                            row["set"], row["recorded_label"], row["judgment_call"].strip().lower() == "true",
                            trace, row["manifest"], row["validation"], trace.rsplit("/", 1)[0] + "/label.json")
            if rec.key in self._recordings:
                raise ArchiveError(f"recording {rec.recording_id} is listed twice in INDEX.csv")
            if rec.set not in (TRAIN, TEST):
                raise ArchiveError(f"recording {rec.recording_id}: unknown set {rec.set!r}")
            self._recordings[rec.key] = rec

    def close(self) -> None:
        self._zip.close()
        if self._raw is not None:
            self._raw.close()

    def __enter__(self) -> "Archive":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    def recordings(self, set_: str = TRAIN, allow_test: bool = False) -> list[Recording]:
        """The recordings of one set, in INDEX order. Training lists `demo-train` only; listing the
        held-out set, whose rows carry their labels, must be asked for explicitly."""
        if set_ == TEST and not allow_test:
            raise ArchiveError(f"the {TEST} recordings are held out; they are not listed for training")
        return [r for r in self._recordings.values() if r.set == set_]

    def recording(self, recording_id: str, allow_test: bool = False) -> Recording:
        rec = self._recordings.get((self.data_version, recording_id))
        if rec is None:
            raise ArchiveError(f"no recording {recording_id} in this archive version")
        if rec.set == TEST and not allow_test:
            raise ArchiveError(f"recording {recording_id} is held out ({TEST}); it is not read for training")
        return rec

    def _member(self, rec: Recording, member: str, allow_test: bool) -> str:
        self.recording(rec.recording_id, allow_test)            # refuses a held-out recording
        return member

    def read_bytes(self, rec: Recording, which: str, allow_test: bool = False) -> bytes:
        """A small member (`manifest`, `label`, `validation`) as bytes."""
        return self._zip.read(self._member(rec, getattr(rec, which), allow_test))

    def open(self, rec: Recording, which: str, allow_test: bool = False):
        """A member as a binary stream (for the trace, about 100 MB)."""
        return self._zip.open(self._member(rec, getattr(rec, which), allow_test))

    def extract(self, rec: Recording, which: str, dest: Path, allow_test: bool = False) -> Path:
        """Copy one member to `dest` by streaming."""
        dest.parent.mkdir(parents=True, exist_ok=True)
        with self.open(rec, which, allow_test) as src, dest.open("wb") as out:
            shutil.copyfileobj(src, out, 1 << 22)
        return dest

    def iter_train(self) -> Iterator[Recording]:
        yield from self.recordings(TRAIN)
