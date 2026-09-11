#!/usr/bin/env python
"""Build a stand-in monitor's alarm file, to exercise `evalkit score`.

There is no Lean monitor wired in here, so this synthesizes one in the way that
makes the metrics meaningful rather than trivial: it takes the SAME readings and
perturbs them, producing a monitor that is *plausibly* wrong in the way a real
formalization is wrong -- a threshold read off by a factor, a persistence window
invented, a clause that fires late.

That is the point of the exercise. A monitor that agrees with the labels
perfectly proves nothing about the metrics; one that is wrong in a known way
lets you check that the metrics say so, and say WHICH way.

    python demo/make_alarms.py --corpus DIR --readings F.jsonl \
        --scale 0.8 --delay 0.4 --out alarms.json
"""

from __future__ import annotations

import argparse
import copy
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from evalkit import corpus as corpus_mod
from evalkit import evaluate, extract_sg
from evalkit.mutation import _set_at, _walk_numbers
from evalkit.reading import load_readings


def perturb(reading, scale):
    """Scale every constant in the consequent, leaving the antecedent alone.

    Only the consequent, because scaling the antecedent changes WHEN the rule is
    engaged, which is a different failure mode from getting the threshold wrong
    and would muddle what the score is measuring.
    """
    mutated = copy.deepcopy(reading)
    for path, value in list(_walk_numbers(mutated.violated_when)):
        if value:
            _set_at(mutated.violated_when, path, value * scale)
    return mutated


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--corpus", required=True)
    ap.add_argument("--readings", required=True)
    ap.add_argument("--scale", type=float, default=0.8,
                    help="factor applied to the monitor's own thresholds")
    ap.add_argument("--delay", type=float, default=0.0,
                    help="seconds of alarm latency to inject")
    ap.add_argument("--limit-frames", type=int, default=None)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    readings = load_readings(args.readings)
    monitor = [perturb(r, args.scale) for r in readings]

    alarms = {}
    for capture in corpus_mod.discover(args.corpus):
        try:
            track = extract_sg.extract(capture.rsv_dir, capture=capture.name,
                                       limit=args.limit_frames)
        except Exception:                              # noqa: BLE001
            continue
        if capture.ego_log:
            try:
                extract_sg.fuse_ego_log(track, capture.ego_log)
            except Exception:                          # noqa: BLE001
                pass
        shift = int(round(args.delay * track.fps))
        rows = {}
        for rule_id, label in evaluate.label_capture(monitor, track).items():
            if label.violations:
                rows[rule_id] = [[a + shift, b + shift]
                                 for a, b in label.violations]
        alarms[track.capture] = rows

    with open(args.out, "w") as fd:
        json.dump(alarms, fd, indent=2, sort_keys=True)
    fired = sum(len(v) for v in alarms.values())
    print("wrote %s: %d captures, %d rules firing (scale=%.2f, delay=%.2fs)"
          % (args.out, len(alarms), fired, args.scale, args.delay))


if __name__ == "__main__":
    main()
