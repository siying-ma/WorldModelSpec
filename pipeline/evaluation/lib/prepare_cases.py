"""Copy one case (its trace.json, and its manifest.json or the source's) into a work directory,
ready for the monitor.

    python3 prepare_cases.py <case dir> <out dir> [--manifest M] [--mask ATOM=REASON ...]
                             [--fill] [--visibility M] [--lane-width M] [--engine] [--indicator-off]

Retired unobserved classes and absent capabilities are removed; a positively observed retired
class requires an explicit source-supported mapping and is rejected. Newly introduced atoms are
declared absent, never inferred. A conversion record hashes the inputs and outputs. --manifest
names the source's manifest for a case that ships none. --mask declares an atom absent, with the
reason recorded: an atom the source reports wrongly is not judged on until the adapter is fixed.

With --fill, assumptions are added, and the manifest declares them observed: no ice or snow,
the visibility distance given, and a lane width
for every lane that has none (lanes with a measured width keep it). With --engine as well, the ego's
engine is reported running. With --indicator-off, the ego's turn indicator is read `off` in every
scene whose signals are reported without it, for a source that wrote the indicator only while lit.
The dataset itself is only read.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re

RETIRED_CLASSES = {"low_speed_vehicle", "mobile_carrying_device", "personal_delivery_device", "procession_vehicle",
                   "vending_vehicle", "animal_drawn_vehicle", "other_conveyance", "ridden_or_herded_animal",
                   "animal_or_animal_drawn"}
RETIRED_ATOMS = {"ru." + c for c in RETIRED_CLASSES} | {"sig.signal_arm", "st.turnout"}


def iter_scenes(path: Path, chunk_size: int = 65536):
    """Read the scenes-only trace document without retaining its repeated map geometry."""
    decoder = json.JSONDecoder()
    with path.open(encoding="utf-8") as stream:
        buf = stream.read(chunk_size)
        prefix = re.match(r'\s*\{\s*"scenes"\s*:\s*\[', buf)
        if not prefix:
            raise ValueError("expected a scenes-only trace document")
        buf = buf[prefix.end():]
        first = True
        while True:
            buf = buf.lstrip()
            while not buf:
                buf = stream.read(chunk_size).lstrip()
                if not buf:
                    raise ValueError("truncated trace")
            if buf.startswith("]"):
                if (buf[1:] + stream.read()).strip() != "}":
                    raise ValueError("unexpected content after scenes")
                return
            if not first:
                if not buf.startswith(","):
                    raise ValueError("expected a comma between scenes")
                buf = buf[1:].lstrip()
            while True:
                try:
                    scene, end = decoder.raw_decode(buf)
                    break
                except json.JSONDecodeError:
                    chunk = stream.read(chunk_size)
                    if not chunk:
                        raise
                    buf += chunk
                    buf = buf.lstrip()
            if not isinstance(scene, dict):
                raise ValueError("expected a scene object")
            yield scene
            buf = buf[end:]
            first = False


def atom_ids(library: Path) -> list[str]:
    """Read the generated full ontology's atom list, not its separate primitive list."""
    source = (library / "splits/full/TrafficSpec/Core/Vocab/Ontology/Ids.lean").read_text()
    section = source.split("def atomIds : List String := [", 1)[1].split("]", 1)[0]
    return re.findall(r'"([^"]+)"', section)


def migrate_scene(scene):
    for user in scene.get("users", []):
        retired = set(user.get("classes") or []) & RETIRED_CLASSES
        if retired:
            raise ValueError(f"positive retired classification needs a source-supported mapping: {sorted(retired)}")
        if "unobserved_classes" in user:
            user["unobserved_classes"] = [c for c in user["unobserved_classes"] if c not in RETIRED_CLASSES]
    return scene


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("case"); ap.add_argument("out")
    ap.add_argument("--fill", action="store_true")
    ap.add_argument("--visibility", type=float, default=10000.0)
    ap.add_argument("--lane-width", type=float, default=3.5)
    ap.add_argument("--engine", action="store_true")
    ap.add_argument("--indicator-off", action="store_true")
    ap.add_argument("--manifest", type=Path)
    ap.add_argument("--mask", action="append", default=[], metavar="ATOM=REASON")
    ap.add_argument("--library", type=Path, default=Path(os.environ.get(
        "PIPELINE", str(Path(__file__).resolve().parents[2] / "traffic-spec-agent"))) / "library")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    source = Path(a.case)
    target = Path(a.out)
    if source.resolve() == target.resolve():
        raise ValueError("output must not overwrite the source case")
    manifest_path = a.manifest or source / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    masks = dict(m.split("=", 1) for m in a.mask)
    atoms = manifest["atoms"]
    ids = atom_ids(a.library)
    retired = sorted(set(atoms) - set(ids))
    for old in retired:
        if old not in RETIRED_ATOMS or atoms[old] != "absent":
            raise ValueError(f"cannot silently discard unsupported capability {old}: {atoms[old]}")
        atoms.pop(old)
    added = sorted(set(ids) - set(atoms))
    for missing in added:
        atoms[missing] = "absent"
    unknown = sorted(set(masks) - set(ids))
    if unknown:
        raise ValueError(f"not atom ids: {unknown}")
    for atom in masks:
        atoms[atom] = "absent"

    widths = indicators = 0
    scenes = 0
    with (target / "trace.json").open("w") as output:
        output.write('{"scenes":[')
        for s in iter_scenes(source / "trace.json"):
            migrate_scene(s)
            if a.fill:
                env = s.setdefault("env", {})
                env["ice_or_snow"] = False
                env["visibility"] = a.visibility
                for st in s.get("structures", []):
                    if st.get("kind") == "lane":
                        lane = st.setdefault("lane", {})
                        if lane.get("width") is None:
                            lane["width"] = a.lane_width; widths += 1
                if a.engine:
                    for u in s.get("users", []):
                        if u.get("track") == s.get("subject"):
                            u.setdefault("kin", {})["engine_running"] = True
            if a.indicator_off:
                for u in s.get("users", []):
                    if u.get("track") == s.get("subject") and u.get("sig") and u["sig"].get("turn_indicator") is None:
                        u["sig"]["turn_indicator"] = "off"; indicators += 1
            if scenes:
                output.write(",")
            output.write(json.dumps(s, separators=(",", ":"), allow_nan=False))
            scenes += 1
        output.write("]}")
    if a.fill:
        atoms["env.ice_or_snow"] = atoms["env.visibility"] = atoms["st.lane_width"] = "exact"
        if a.engine:
            atoms["kin.engine_running"] = "subject"

    (target / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    assumptions = ({"ice_or_snow": False, "visibility_m": a.visibility,
                    "missing_lane_width_m": a.lane_width, "engine_running": a.engine} if a.fill else {})
    if a.indicator_off:
        assumptions["unwritten_turn_indicator"] = "off"
    conversion = {"source": str(source.resolve()), "manifest": str(manifest_path.resolve()), "scenes": scenes,
                  "retired_absent_atoms_removed": retired, "new_atoms_declared_absent": added,
                  "masked_atoms": masks, "assumptions": assumptions,
                  "source_sha256": {"trace.json": sha256(source / "trace.json"), "manifest.json": sha256(manifest_path)},
                  "output_sha256": {n: sha256(target / n) for n in ("trace.json", "manifest.json")}}
    (target / "conversion.json").write_text(json.dumps(conversion, indent=2) + "\n")
    note = f", weather filled, {widths} lane entries given {a.lane_width} m" + (", engine running" if a.engine else "") if a.fill else ""
    note += f", indicator read off in {indicators} scenes" if a.indicator_off else ""
    print(f"   {os.path.basename(a.case)}: {scenes} scenes{note}; {len(added)} new atoms absent")


if __name__ == "__main__":
    main()
