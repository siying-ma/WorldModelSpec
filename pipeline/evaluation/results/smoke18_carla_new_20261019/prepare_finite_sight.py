"""Make an evaluation view that does not mistake a censored lower bound for a finite horizon.

Reads a deduplicated trace and its original supplementary evidence in timestamp lockstep.
Where a minimizing approach is search-censored, its exported regional scalar is removed, not
replaced by a guessed cutoff. Uncensored estimates and every other observation are retained.
This addresses censoring only, not whether incoming observers measure a driver's forward view.
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
    parser.add_argument("evidence", type=Path)
    parser.add_argument("out", type=Path)
    args = parser.parse_args()
    if args.case.resolve() == args.out.resolve():
        raise ValueError("output must not overwrite its input")
    args.out.mkdir(parents=True, exist_ok=True)
    frames = removed = 0
    with args.evidence.open() as evidence, (args.out / "trace.json").open("w") as output:
        output.write('{"scenes":[')
        for scene, line in zip(iter_scenes(args.case / "trace.json"), evidence, strict=True):
            record = json.loads(line)
            if record["world_scene_t"] != scene["t"]:
                raise ValueError("evidence timestamp does not match trace")
            mapping = record["visibility_mapping"]
            scalar = mapping["value_m"]
            horizons = [a["any_body_sight_horizon"]
                        for a in record["evidence"]["visibility"]["approaches"]]
            censored = scalar is not None and any(
                h.get("bound") == "at_least" and h["distance_m"] <= scalar + 1e-6
                for h in horizons)
            if censored:
                for region in scene["structures"]:
                    if region["id"] in mapping["attached_regions"]:
                        value = region.get("sight_distance")
                        if value is None or abs(value - scalar) > 1e-6:
                            raise ValueError("visibility mapping disagrees with exported value")
                        region.pop("sight_distance")
                removed += 1
            if frames:
                output.write(",")
            output.write(json.dumps(scene, separators=(",", ":"), allow_nan=False))
            frames += 1
        output.write("]}")
    for name in ("manifest.json", "boundaries.json"):
        shutil.copyfile(args.case / name, args.out / name)
    change = {"frames": frames, "censored_frames_made_unknown": removed,
              "assumptions_added": [], "input_trace_sha256": sha256(args.case / "trace.json"),
              "evidence_sha256": sha256(args.evidence), "output_trace_sha256": sha256(args.out / "trace.json")}
    (args.out / "censoring.json").write_text(json.dumps(change, indent=2) + "\n")
    print(f"{args.case.name}: {removed}/{frames} censored frames made unknown")


if __name__ == "__main__":
    main()
