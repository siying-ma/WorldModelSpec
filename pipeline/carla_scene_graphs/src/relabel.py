#!/usr/bin/env python
"""Regenerate `labels.json` from an existing `oracle.jsonl`, without re-simulating.

The ground truth is the oracle log; the label file is a reading of it. When that
reading changes — a threshold restated, a clause quantified differently — every
capture already on disk can be relabelled in seconds instead of re-recording
hours of simulation.

    python src/relabel.py --database database
    python src/relabel.py --capture database/red_light_violation

Requires no CARLA server.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from carlaspec import paths                                   # noqa: E402
from carlaspec.labeler import build_label_file, write_label_file  # noqa: E402
from carlaspec.oracle import load_oracle                      # noqa: E402


def relabel(capture: Path, fps: int) -> dict:
    oracle_path = capture / "oracle.jsonl"
    if not oracle_path.exists():
        raise FileNotFoundError(f"{capture.name}: no oracle.jsonl")
    records = load_oracle(oracle_path)
    if not records:
        raise ValueError(f"{capture.name}: oracle.jsonl is empty")

    meta = {}
    simulation = capture / "simulation.json"
    if simulation.exists():
        data = json.loads(simulation.read_text(encoding="utf-8"))
        meta = {"scenario": data.get("scenario"), "mode": data.get("mode"),
                "seed": data.get("seed"), "town": data.get("town"),
                "notes": data.get("scenario_notes", {})}
        fps = int(data.get("fps", fps))

    label_file = build_label_file(records, capture.name, fps, meta=meta)
    write_label_file(label_file, capture / "labels.json")
    return label_file


def main() -> int:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--database", default=str(paths.DEFAULT_DATABASE))
    parser.add_argument("--capture", default=None,
                        help="relabel just this capture directory")
    parser.add_argument("--fps", type=int, default=20,
                        help="fallback when simulation.json is absent")
    args = parser.parse_args()

    if args.capture:
        captures = [Path(args.capture)]
    else:
        root = Path(args.database)
        captures = sorted(child for child in root.iterdir()
                          if (child / "oracle.jsonl").exists())
    if not captures:
        print("[error] no captures with an oracle.jsonl found", file=sys.stderr)
        return 2

    failures = 0
    for capture in captures:
        try:
            label_file = relabel(capture, args.fps)
        except (FileNotFoundError, ValueError) as exc:
            print(f"  {capture.name}: \033[91m{exc}\033[0m")
            failures += 1
            continue
        verdicts = " ".join(
            f"{entry['law'].replace('EX-', '')}={entry['verdict'][:4]}"
            for entry in label_file["labels"])
        print(f"  {capture.name}: {verdicts}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
