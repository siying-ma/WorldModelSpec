"""Deduplicate identical map boundaries into a sidecar for the evaluation runner.

The runner restores every boundary before passing the trace to the unchanged monitor. Each
scene must have exactly the same region inventory and boundaries; differing geometry is an
error, never silently frozen. No scene, measurement, position or occupancy is recomputed.
The boundary-free intermediate is not a standalone adapter trace for direct evaluation.
"""
import argparse
import json
from pathlib import Path
import shutil
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "lib"))
from prepare_cases import iter_scenes, sha256


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("case", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    if args.case.resolve() == args.out.resolve():
        raise ValueError("projection must not overwrite its input")
    args.out.mkdir(parents=True, exist_ok=True)
    frames = vertices = 0
    boundaries = None
    with (args.out / "trace.json").open("w") as output:
        output.write('{"scenes":[')
        for scene in iter_scenes(args.case / "trace.json"):
            current = {st["id"]: {"id": st["id"], "kind": st["kind"],
                                  **({"boundary": st["boundary"]} if "boundary" in st else {})}
                       for st in scene["structures"]}
            if len(current) != len(scene["structures"]):
                raise ValueError("duplicate structure id")
            if boundaries is None:
                boundaries = current
            elif current != boundaries:
                raise ValueError("region inventory or boundaries changed; cannot deduplicate this trace")
            for st in scene["structures"]:
                boundary = st.pop("boundary", None)
                vertices += len(boundary or [])
            if frames:
                output.write(",")
            output.write(json.dumps(scene, separators=(",", ":"), allow_nan=False))
            frames += 1
        output.write("]}")
    shutil.copyfile(args.case / "manifest.json", args.out / "manifest.json")
    sidecar = {"scenes": [{"t": 0, "structures": list((boundaries or {}).values())}]}
    (args.out / "boundaries.json").write_text(json.dumps(sidecar, separators=(",", ":")))
    record = {"frames": frames, "deduplicated": "structures[*].boundary", "vertices": vertices,
              "restoration": "SharedMapMain restores each original boundary before Monitor.check",
              "input_trace_sha256": sha256(args.case / "trace.json"),
              "output_trace_sha256": sha256(args.out / "trace.json"),
              "boundary_sidecar_sha256": sha256(args.out / "boundaries.json"),
              "manifest_sha256": sha256(args.out / "manifest.json")}
    (args.out / "projection.json").write_text(json.dumps(record, indent=2) + "\n")
    print(f"{args.case.name}: deduplicated {frames} frames, {vertices} boundary vertices preserved in sidecar")


if __name__ == "__main__":
    main()
