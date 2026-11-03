"""Align a trace and its manifest with the packaged ontology before monitoring.

The manifest: an atom id the ontology no longer has is dropped when declared absent (a retired
atom with any other status is an error); an atom id the manifest does not list is declared absent.
The trace: retired road-user classes are removed from `unobserved_classes`; a user positively
classified in a retired class is an error. The trace is streamed scene by scene.
"""
from __future__ import annotations

import json
import re
from pathlib import Path

RETIRED_CLASSES = {"low_speed_vehicle", "mobile_carrying_device", "personal_delivery_device", "procession_vehicle",
                   "vending_vehicle", "animal_drawn_vehicle", "other_conveyance", "ridden_or_herded_animal",
                   "animal_or_animal_drawn"}
RETIRED_ATOMS = {"ru." + c for c in RETIRED_CLASSES} | {"sig.signal_arm", "st.turnout"}


def _scenes(path: Path, chunk: int = 1 << 20):
    dec = json.JSONDecoder()
    with path.open(encoding="utf-8") as f:
        buf = f.read(chunk)
        m = re.match(r'\s*\{\s*"scenes"\s*:\s*\[', buf)
        if not m:
            raise ValueError(f"{path}: expected a scenes-only trace document {{\"scenes\": [...]}}")
        buf, first = buf[m.end():], True
        while True:
            buf = buf.lstrip()
            while not buf:
                more = f.read(chunk)
                if not more:
                    raise ValueError(f"{path}: truncated trace")
                buf = more.lstrip()
            if buf.startswith("]"):
                return
            if not first:
                if not buf.startswith(","):
                    raise ValueError(f"{path}: expected a comma between scenes")
                buf = buf[1:].lstrip()
            while True:
                try:
                    scene, end = dec.raw_decode(buf)
                    break
                except json.JSONDecodeError:
                    more = f.read(chunk)
                    if not more:
                        raise
                    buf += more
            yield scene
            buf, first = buf[end:], False


def prepare(trace: Path, manifest: Path, out: Path, atom_ids_file: Path):
    ids = json.loads(atom_ids_file.read_text())
    m = json.loads(manifest.read_text())
    atoms = m.setdefault("atoms", {})
    notes = []
    for old in sorted(set(atoms) - set(ids)):
        if old in RETIRED_ATOMS and atoms[old] == "absent":
            atoms.pop(old)
        else:
            raise ValueError(f"manifest declares {old} = {atoms[old]}, an atom this ontology does not have")
    added = sorted(set(ids) - set(atoms))
    for a in added:
        atoms[a] = "absent"
    if added:
        notes.append(f"manifest did not list {len(added)} atom(s), declared absent: {', '.join(added)}")
    out_trace, out_manifest = out / "trace.json", out / "manifest.json"
    out_manifest.write_text(json.dumps(m, indent=1))
    n = 0
    with out_trace.open("w", encoding="utf-8") as w:
        w.write('{"scenes":[')
        for s in _scenes(trace):
            for u in s.get("users", []):
                bad = set(u.get("classes") or []) & RETIRED_CLASSES
                if bad:
                    raise ValueError(f"scene t={s.get('t')}: user {u.get('track')} is classified {sorted(bad)}, a retired class")
                if "unobserved_classes" in u:
                    u["unobserved_classes"] = [c for c in u["unobserved_classes"] if c not in RETIRED_CLASSES]
            w.write(("," if n else "") + json.dumps(s, separators=(",", ":"), allow_nan=False))
            n += 1
        w.write("]}")
    return out_trace, out_manifest, notes
