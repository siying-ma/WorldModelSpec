"""Copy one carla_new case (trace.json, manifest.json) into a work directory, ready for the monitor.

    python3 prepare_cases.py <case dir> <out dir> [--fill] [--visibility M] [--lane-width M] [--engine]

Always: the retired road-user class `animal_or_animal_drawn` is written as the two classes it was
split into, so traces made before the split decode.

With --fill, the facts CARLA knows but the adapter does not export are added, and the manifest
declares them observed: no ice or snow, the visibility distance given (clear air), and a lane width
for every lane that has none (lanes with a measured width keep it). With --engine as well, the ego's
engine is reported running. The dataset itself is only read.
"""
from __future__ import annotations

import argparse
import json
import os

NEW_ANIMAL_CLASSES = ["ridden_or_herded_animal", "animal_drawn_vehicle"]


def respell(x):
    if isinstance(x, list):
        return [y for v in x for y in (NEW_ANIMAL_CLASSES if v == "animal_or_animal_drawn" else [respell(v)])]
    return {k: respell(v) for k, v in x.items()} if isinstance(x, dict) else x


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("case"); ap.add_argument("out")
    ap.add_argument("--fill", action="store_true")
    ap.add_argument("--visibility", type=float, default=10000.0)
    ap.add_argument("--lane-width", type=float, default=3.5)
    ap.add_argument("--engine", action="store_true")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    trace = respell(json.load(open(os.path.join(a.case, "trace.json"))))
    manifest = json.load(open(os.path.join(a.case, "manifest.json")))
    atoms = manifest["atoms"]
    if "ru.animal_or_animal_drawn" in atoms:
        v = atoms.pop("ru.animal_or_animal_drawn")
        atoms["ru.ridden_or_herded_animal"] = atoms["ru.animal_drawn_vehicle"] = v

    widths = 0
    if a.fill:
        for s in trace["scenes"]:
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
        atoms["env.ice_or_snow"] = atoms["env.visibility"] = atoms["st.lane_width"] = "exact"
        if a.engine:
            atoms["kin.engine_running"] = "subject"

    json.dump(trace, open(os.path.join(a.out, "trace.json"), "w"))
    json.dump(manifest, open(os.path.join(a.out, "manifest.json"), "w"))
    note = f", weather filled, {widths} lane entries given {a.lane_width} m" + (", engine running" if a.engine else "") if a.fill else ""
    print(f"   {os.path.basename(a.case)}: {len(trace['scenes'])} scenes{note}")


if __name__ == "__main__":
    main()
