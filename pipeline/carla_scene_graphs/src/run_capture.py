#!/usr/bin/env python
"""Record compliant/violating CARLA captures for traffic-spec-agent's rules.

A CARLA server must already be running:

    ./sim/CarlaUE4.sh -RenderOffscreen -carla-server -world-port=2000

Then, from the repository root with the `.carlasg` environment active:

    python src/run_capture.py --list
    python src/run_capture.py --scenario red_light --mode violation
    python src/run_capture.py --scenario red_light            # both modes
    python src/run_capture.py --all                           # every scenario

Each capture writes `<database>/<scenario>_<mode>/` containing the scene-graph
frames, the ego log, camera stills, the ground-truth `oracle.jsonl` and the
`labels.json` derived from it. Feed one to the spec repository with:

    python -m scripts.run_spec monitor \\
        --rsv-dir  <capture>/rsv \\
        --ego-log  <capture>/ego_logs.json \\
        --labels   <capture>/labels.json \\
        --module-name Captured \\
        --adapter-python $(which python)

A capture that does not exercise the law its scenario targets is reported as a
failure and retried with a new seed (`--attempts`), because a run that never
reached the situation says nothing about the rule.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from carlaspec import paths                      # noqa: E402
from carlaspec.runner import CaptureRunner       # noqa: E402
from carlaspec.scenario import MODES, REGISTRY   # noqa: E402
from carlaspec.scenario import get as get_scenario  # noqa: E402
import carlaspec.scenarios                       # noqa: E402,F401  (registers them)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--list", action="store_true",
                        help="print the registered scenarios and exit")
    parser.add_argument("--scenario", help="scenario name; omit with --all")
    parser.add_argument("--all", action="store_true",
                        help="run every registered scenario")
    parser.add_argument("--mode", choices=MODES,
                        help="one mode; omit to record both counterparts")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=2000)
    parser.add_argument("--tm-port", type=int, default=8000)
    parser.add_argument("--town", default=None,
                        help="override the scenario's own map")
    parser.add_argument("--fps", type=int, default=20,
                        help="must stay 20: the Lean library reads durations as "
                             "frame counts at 20 Hz")
    parser.add_argument("--duration", type=float, default=None,
                        help="override the scenario's capture length, in seconds")
    parser.add_argument("--destination-folder", default=str(paths.DEFAULT_DATABASE))
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--attempts", type=int, default=3,
                        help="re-runs with seed+1 when the target law is not "
                             "exercised")
    parser.add_argument("--save-viz", action="store_true",
                        help="also render each frame's scene graph (slow)")
    parser.add_argument("--no-camera", action="store_true")
    parser.add_argument("--overwrite", action="store_true",
                        help="reuse the capture folder instead of suffixing it")
    parser.add_argument("--summary", default=None,
                        help="write a JSON summary of every capture here")
    return parser.parse_args()


def print_registry() -> None:
    print(f"{'scenario':<24} {'laws':<22} {'town':<10} description")
    print(f"{'-' * 24} {'-' * 22} {'-' * 10} {'-' * 40}")
    for name in sorted(REGISTRY):
        scenario = REGISTRY[name]
        print(f"{name:<24} {','.join(scenario.target_laws):<22} "
              f"{str(scenario.town):<10} {scenario.description}")


def run_one(scenario, mode: str, args: argparse.Namespace) -> dict:
    last: dict = {}
    for attempt in range(args.attempts):
        seed = args.seed + attempt
        if attempt:
            print(f"\033[93m[retry] {scenario.name} [{mode}] with seed {seed}"
                  f"\033[0m")
        runner = CaptureRunner(
            scenario, mode, host=args.host, port=args.port, tm_port=args.tm_port,
            fps=args.fps, destination=Path(args.destination_folder),
            seed=seed, duration=args.duration, save_viz=args.save_viz,
            no_camera=args.no_camera,
            overwrite=args.overwrite or attempt > 0, town=args.town)
        last = runner.run()
        last["attempt"] = attempt + 1
        if last.get("ok"):
            return last
    return last


def main() -> int:
    args = parse_args()

    if args.list:
        print_registry()
        return 0
    if not args.all and not args.scenario:
        print("[error] pass --scenario NAME, or --all, or --list",
              file=sys.stderr)
        return 2

    names = sorted(REGISTRY) if args.all else [args.scenario]
    modes = [args.mode] if args.mode else list(MODES)

    results = []
    for name in names:
        scenario = get_scenario(name)
        for mode in modes:
            results.append(run_one(scenario, mode, args))

    print("\n" + "=" * 78)
    print(f"{'capture':<32} {'ok':<4} {'targets':<22} note")
    print("-" * 78)
    for result in results:
        ok = "yes" if result.get("ok") else "NO"
        note = result.get("error", "")
        print(f"{result.get('capture', '?'):<32} {ok:<4} "
              f"{','.join(result.get('target_laws', [])):<22} {note[:60]}")

    if args.summary:
        Path(args.summary).write_text(
            json.dumps(results, indent=2, ensure_ascii=False) + "\n",
            encoding="utf-8")
        print(f"\nsummary written to {args.summary}")

    failed = [r for r in results if not r.get("ok")]
    if failed:
        print(f"\n\033[91m{len(failed)} of {len(results)} captures failed"
              f"\033[0m")
    return 1 if failed else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\ninterrupted")
        sys.exit(130)
