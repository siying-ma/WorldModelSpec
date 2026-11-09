"""A recording projected onto the active split: a training manifest over exactly the split's atom
ids, with a record of what was left out.

Reason: training runs the train variant of Core, which knows only the split's atoms; the held-out
atoms a recording's manifest lists must leave the manifest without changing any observation, and
the change must be traceable.

The projection:
- keeps every listed atom of the split with its state, and declares absent every atom of the
  split the manifest does not list (silence is not a capability);
- drops every listed id outside the split and records it with its original state: a held-out atom
  (an atom of the full split but not of this one) is dropped whatever its state; a retired atom
  (one no split knows) is dropped only when declared absent, and any other state of a retired atom
  is an error, since an observed capability is never discarded silently;
- copies the trace scene by scene, changing nothing but the retired road-user classes listed as
  unobserved (dropped from `unobserved_classes`); a road user positively classified with a retired
  class is an error, since it needs a mapping the source supports;
- records, for a manifest, the split, the excluded ids with their states, the atoms added as absent
  and the sha256 of the input and output manifest; for a trace, its scenes, the retired classes
  dropped and the sha256 of the input and output trace.

A manifest belongs to a source (one scene-graph generator or adapter version), so it is projected
once per source; each trace is projected on its own.
"""
from __future__ import annotations

import codecs
import hashlib
import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import BinaryIO, Iterable, Iterator

#: Road-user classes and atoms retired from the ontology, read under the conventions of the
#: earlier evaluation preparation: an unobserved retired class is dropped, a positive one refused.
RETIRED_CLASSES = {"low_speed_vehicle", "mobile_carrying_device", "personal_delivery_device", "procession_vehicle",
                   "vending_vehicle", "animal_drawn_vehicle", "other_conveyance", "ridden_or_herded_animal",
                   "animal_or_animal_drawn"}
RETIRED_ATOMS = {"ru." + c for c in RETIRED_CLASSES} | {"sig.signal_arm", "st.turnout"}


class ProjectionError(ValueError):
    pass


def atom_ids(ids_lean: Path) -> list[str]:
    """The atom ids a generated `Ids.lean` declares (`def atomIds : List String := [...]`)."""
    source = Path(ids_lean).read_text(encoding="utf-8")
    try:
        section = source.split("def atomIds : List String := [", 1)[1].split("]", 1)[0]
    except IndexError as e:
        raise ProjectionError(f"{ids_lean}: no atomIds list") from e
    return re.findall(r'"([^"]+)"', section)


def split_ids(library: Path, split: str) -> list[str]:
    """The atom ids of one split of a library (`library/splits/<split>/…/Ids.lean`)."""
    return atom_ids(Path(library) / "splits" / split / "TrafficSpec/Core/Vocab/Ontology/Ids.lean")


@dataclass
class ProjectionRecord:
    """A manifest's projection."""
    split: str
    excluded: dict[str, str] = field(default_factory=dict)           # id -> original state
    excluded_kind: dict[str, str] = field(default_factory=dict)      # id -> held_out | retired
    added_absent: list[str] = field(default_factory=list)
    input_sha256: str = ""
    output_sha256: str = ""

    def to_dict(self) -> dict:
        return asdict(self)


@dataclass
class TraceRecord:
    """A trace's projection."""
    scenes: int = 0
    retired_unobserved_classes_dropped: int = 0
    input_sha256: str = ""
    output_sha256: str = ""

    def to_dict(self) -> dict:
        return asdict(self)


def project_manifest(manifest: dict, active: Iterable[str], full: Iterable[str], split: str) -> tuple[dict, ProjectionRecord]:
    """The training manifest over exactly `active`, and the record of the change."""
    active, full = list(active), set(full)
    atoms = dict(manifest.get("atoms") or {})
    rec = ProjectionRecord(split=split)
    for id_ in sorted(set(atoms) - set(active)):
        state = atoms[id_]
        if id_ in full:
            rec.excluded[id_], rec.excluded_kind[id_] = state, "held_out"
        elif id_ in RETIRED_ATOMS and state == "absent":
            rec.excluded[id_], rec.excluded_kind[id_] = state, "retired"
        else:
            raise ProjectionError(f"cannot discard {id_} ({state}): it is no atom of this library, and an observed "
                                  "capability is never dropped silently")
    out_atoms = {}
    for id_ in active:
        if id_ in atoms:
            out_atoms[id_] = atoms[id_]
        else:
            out_atoms[id_] = "absent"
            rec.added_absent.append(id_)
    out = {k: v for k, v in manifest.items() if k != "atoms"}
    out["atoms"] = out_atoms
    return out, rec


def iter_scenes(stream: BinaryIO, chunk_size: int = 1 << 16) -> Iterator[dict]:
    """The scenes of a scenes-only trace document, one at a time (the trace is never held whole)."""
    decoder = json.JSONDecoder()
    text = codecs.getincrementaldecoder("utf-8")()

    def reader() -> str:
        chunk = stream.read(chunk_size)
        return text.decode(chunk, final=not chunk)

    buf = reader()
    while "[" not in buf:                               # the opening may span several chunks
        more = reader()
        if not more:
            break
        buf += more
    m = re.match(r'\s*\{\s*"scenes"\s*:\s*\[', buf)
    if not m:
        raise ProjectionError("expected a scenes-only trace document")
    buf = buf[m.end():]
    first = True
    while True:
        buf = buf.lstrip()
        while not buf:
            more = reader()
            if not more:
                raise ProjectionError("truncated trace")
            buf = more.lstrip()
        if buf.startswith("]"):
            rest = buf[1:]
            while (more := reader()):
                rest += more
            if rest.strip() != "}":
                raise ProjectionError("unexpected content after the scenes")
            return
        if not first:
            if not buf.startswith(","):
                raise ProjectionError("expected a comma between scenes")
            buf = buf[1:].lstrip()
        while True:
            buf = buf.lstrip()
            try:
                scene, end = decoder.raw_decode(buf)
                break
            except json.JSONDecodeError:
                more = reader()
                if not more:
                    raise
                buf += more
        if not isinstance(scene, dict):
            raise ProjectionError("expected a scene object")
        yield scene
        buf = buf[end:]
        first = False


def _migrate(scene: dict) -> int:
    dropped = 0
    for user in scene.get("users", []):
        retired = set(user.get("classes") or []) & RETIRED_CLASSES
        if retired:
            raise ProjectionError(f"a road user is classified {sorted(retired)}, a retired class: it needs a mapping the source supports")
        if "unobserved_classes" in user:
            kept = [c for c in user["unobserved_classes"] if c not in RETIRED_CLASSES]
            dropped += len(user["unobserved_classes"]) - len(kept)
            user["unobserved_classes"] = kept
    return dropped


def _sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write_manifest(manifest_bytes: bytes, out_dir: Path, active: Iterable[str], full: Iterable[str],
                   split: str) -> ProjectionRecord:
    """Write the training `manifest.json` and its `projection.json` for the active split into `out_dir`."""
    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest, rec = project_manifest(json.loads(manifest_bytes), active, full, split)
    mbytes = (json.dumps(manifest, indent=2) + "\n").encode("utf-8")
    (out_dir / "manifest.json").write_bytes(mbytes)
    rec.input_sha256, rec.output_sha256 = _sha(manifest_bytes), _sha(mbytes)
    (out_dir / "projection.json").write_text(json.dumps(rec.to_dict(), indent=2) + "\n", encoding="utf-8")
    return rec


def project_trace(trace: BinaryIO, out_path: Path) -> TraceRecord:
    """Write the projected trace to `out_path`, streaming it scene by scene."""
    out_path = Path(out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    rec = TraceRecord()
    in_hash = hashlib.sha256()
    out_hash = hashlib.sha256()

    class _Tee:
        def read(self, n=-1):
            b = trace.read(n)
            in_hash.update(b)
            return b

    with out_path.open("wb") as out:
        def w(s: str) -> None:
            b = s.encode("utf-8")
            out_hash.update(b)
            out.write(b)
        w('{"scenes":[')
        for scene in iter_scenes(_Tee()):
            rec.retired_unobserved_classes_dropped += _migrate(scene)
            if rec.scenes:
                w(",")
            w(json.dumps(scene, separators=(",", ":"), allow_nan=False))
            rec.scenes += 1
        w("]}")
    rec.input_sha256, rec.output_sha256 = in_hash.hexdigest(), out_hash.hexdigest()
    return rec
