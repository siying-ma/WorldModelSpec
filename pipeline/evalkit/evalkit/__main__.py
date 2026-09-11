"""evalkit CLI.

    python -m evalkit facts   --corpus DIR [--out DIR]
    python -m evalkit label   --corpus DIR --readings F.jsonl [--out DIR]
    python -m evalkit report  --corpus DIR --readings F.jsonl
    python -m evalkit mutate  --corpus DIR --readings F.jsonl
    python -m evalkit score   --corpus DIR --readings F.jsonl --alarms A.json

`report` is the one to run first on a new corpus: it needs no monitor and no
labels of its own, and it says what the corpus can and cannot be used to test.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time

from . import corpus as corpus_mod
from . import evaluate, extract_sg, metrics, mutation
from .facts import ABSENT, FIELDS
from .reading import load_readings, validate


def _tracks(root, limit_frames=None, quiet=False):
    captures = corpus_mod.discover(root)
    tracks = []
    for capture in captures:
        try:
            track = extract_sg.extract(capture.rsv_dir, capture=capture.name,
                                       limit=limit_frames)
        except Exception as exc:                       # noqa: BLE001
            if not quiet:
                print("  [skip] %-34s %s: %s"
                      % (capture.name, type(exc).__name__, str(exc)[:60]))
            continue
        if capture.ego_log:
            try:
                extract_sg.fuse_ego_log(track, capture.ego_log)
            except Exception as exc:                   # noqa: BLE001
                if not quiet:
                    print("  [warn] %s: ego log not fused: %s"
                          % (capture.name, exc))
        tracks.append(track)
    return captures, tracks


def cmd_facts(args):
    captures, tracks = _tracks(args.corpus, args.limit_frames)
    print("captures discovered: %d, extracted: %d" % (len(captures), len(tracks)))
    if args.out:
        if not os.path.isdir(args.out):
            os.makedirs(args.out)
    for track in tracks:
        replay = track.meta.get("replay_detected")
        lag = track.meta.get("ego_log_lag_frames")
        print("  %-34s %5d frames %6.1fs  replay=%-5s  speed=%s%s"
              % (track.capture, len(track), track.duration_s(), replay,
                 track.meta.get("speed_source"),
                 "" if lag is None else "  lag=%+d" % lag))
        if args.out:
            track.write(os.path.join(args.out, track.capture + ".facts.jsonl"))
    return 0


def cmd_label(args):
    readings = load_readings(args.readings)
    problems = validate(readings, set(FIELDS))
    if problems:
        for p in problems:
            print("[error] " + p, file=sys.stderr)
        return 2
    _, tracks = _tracks(args.corpus, args.limit_frames)
    if args.out and not os.path.isdir(args.out):
        os.makedirs(args.out)
    tally = {}
    for track in tracks:
        labels = evaluate.label_capture(readings, track)
        for label in labels.values():
            tally[label.verdict] = tally.get(label.verdict, 0) + 1
        if args.out:
            evaluate.write_labels(
                labels, os.path.join(args.out, track.capture + ".labels.json"),
                meta={"capture": track.capture, "fps": track.fps,
                      "view": track.meta.get("view"),
                      "readings": os.path.basename(args.readings)})
    print("derived %d labels over %d captures x %d obligations"
          % (sum(tally.values()), len(tracks), len(readings)))
    for verdict in sorted(tally):
        print("  %-16s %d" % (verdict, tally[verdict]))
    return 0


def cmd_report(args):
    readings = load_readings(args.readings)
    problems = validate(readings, set(FIELDS))
    if problems:
        for p in problems:
            print("[error] " + p, file=sys.stderr)
        return 2

    started = time.time()
    captures, tracks = _tracks(args.corpus, args.limit_frames)
    labels_by_capture = {}
    durations = {}
    for track in tracks:
        labels_by_capture[track.capture] = evaluate.label_capture(readings, track)
        durations[track.capture] = track.duration_s()

    fps = tracks[0].fps if tracks else 20
    # No monitor supplied: score the CORPUS, not a monitor. Every rule gets an
    # empty alarm list, so tp/fp are meaningless here and are not printed.
    scores = metrics.score_corpus(labels_by_capture, {}, durations, fps)

    print("=" * 78)
    print("CORPUS REPORT   %s" % args.corpus)
    print("=" * 78)
    total_frames = sum(len(t) for t in tracks)
    print("captures found %d, usable %d, frames %d, %.1f min of driving"
          % (len(captures), len(tracks), total_frames,
             sum(durations.values()) / 60.0))
    replayed = sum(1 for t in tracks if t.meta.get("replay_detected"))
    print("replay-derived captures: %d of %d (ego dynamics recovered by "
          "differencing)" % (replayed, len(tracks)))

    print("\n-- Bench2Drive scenario coverage --")
    scov = corpus_mod.scenario_coverage(captures)
    print("  %d of %d scenarios present" % (scov["present"],
                                            scov["bench2drive_total"]))
    for skill in sorted(scov["by_skill"]):
        row = scov["by_skill"][skill]
        print("    %-16s %2d/%2d" % (skill, row["have"], row["of"]))
    if scov["present_names"]:
        print("  present: %s" % ", ".join(scov["present_names"]))

    print("\n-- obligation coverage --")
    ocov = corpus_mod.obligation_coverage(scores, readings)
    print("  %-26s %-9s %-9s %-10s %s"
          % ("obligation", "witnessed", "2-sided", "applic/viol", "record next"))
    for row in ocov["rows"]:
        nxt = ",".join(row["record_next"][:2])
        print("  %-26s %-9s %-9s %2d/%-7d %s"
              % (row["obligation"],
                 "yes" if row["witnessed"] else
                 ("UNTESTABLE" if row["untestable_everywhere"] else "no"),
                 "yes" if row["two_sided"] else "no",
                 row["captures_applicable"], row["captures_violating"],
                 nxt[:34]))
    print("  witnessed %d/%d, two-sided %d/%d, untestable everywhere %d"
          % (ocov["witnessed"], ocov["obligations"],
             ocov["two_sided"], ocov["obligations"],
             ocov["untestable_everywhere"]))

    print("\n-- fields this view cannot supply --")
    absent = sorted(set(k for t in tracks for k, v in t.provenance.items()
                        if v == ABSENT))
    for field in absent:
        blocked = [r.id for r in readings if field in r.paths()]
        print("  %-32s blocks: %s" % (field, ", ".join(blocked) or "-"))

    print("\nreport built in %.1fs" % (time.time() - started))
    if args.json:
        with open(args.json, "w") as fd:
            json.dump({"scenario_coverage": scov, "obligation_coverage": ocov,
                       "absent_fields": absent,
                       "captures": [t.capture for t in tracks]},
                      fd, indent=2, sort_keys=True)
        print("json written to %s" % args.json)
    return 0


def cmd_mutate(args):
    readings = load_readings(args.readings)
    _, tracks = _tracks(args.corpus, args.limit_frames, quiet=True)
    report = mutation.corpus_mutation_report(readings, tracks)
    print("=" * 78)
    print("MUTATION REPORT  %d captures x %d readings"
          % (report["captures"], report["readings"]))
    print("=" * 78)
    print("  %-26s %8s %8s %8s   %s"
          % ("obligation", "mutants", "killed", "score", "surviving (sample)"))
    for row in report["per_reading"]:
        score = row["mutation_score"]
        print("  %-26s %8d %8d %8s   %s"
              % (row["reading"], row["mutants"], row["killed"],
                 "-" if score is None else "%.2f" % score,
                 ", ".join(row["surviving_mutants"][:2])[:36]))
    overall = report["overall_mutation_score"]
    print("\n  overall mutation score: %s"
          % ("-" if overall is None else "%.3f" % overall))
    print("  " + report["interpretation"])
    if args.json:
        with open(args.json, "w") as fd:
            json.dump(report, fd, indent=2, sort_keys=True)
        print("  json written to %s" % args.json)
    return 0


def cmd_score(args):
    readings = load_readings(args.readings)
    _, tracks = _tracks(args.corpus, args.limit_frames, quiet=True)
    with open(args.alarms) as fd:
        alarms_raw = json.load(fd)
    alarms = dict((cap, dict((rule, [tuple(iv) for iv in ivs])
                             for rule, ivs in rules.items()))
                  for cap, rules in alarms_raw.items())

    labels_by_capture = {}
    durations = {}
    for track in tracks:
        labels_by_capture[track.capture] = evaluate.label_capture(readings, track)
        durations[track.capture] = track.duration_s()
    fps = tracks[0].fps if tracks else 20
    scores = metrics.score_corpus(labels_by_capture, alarms, durations, fps,
                                  onset_tolerance_s=args.onset_tolerance)

    print("  %-26s %4s %4s %4s %6s %6s %6s %8s"
          % ("obligation", "tp", "fp", "fn", "prec", "rec", "f1", "lat(s)"))
    for rule_id in sorted(scores):
        s = scores[rule_id]
        fmt = lambda v: "-" if v is None else "%.2f" % v
        print("  %-26s %4d %4d %4d %6s %6s %6s %8s"
              % (rule_id, s.tp, s.fp, s.fn, fmt(s.precision), fmt(s.recall),
                 fmt(s.f1), fmt(s.mean_latency_s)))
    summary = metrics.monitor_score(scores, args.rulebook_size)
    print("\n  MonitorScore %.3f = two-sided coverage %.3f x mean quality %.3f"
          % (summary["monitor_score"], summary["two_sided_coverage"],
             summary["mean_quality"]))
    print("  (%d of %d rulebook obligations scored)"
          % (summary["scored_rules"], args.rulebook_size))
    return 0


def main(argv=None):
    parser = argparse.ArgumentParser(prog="evalkit", description=__doc__)
    sub = parser.add_subparsers(dest="command")

    def common(p):
        p.add_argument("--corpus", required=True)
        p.add_argument("--limit-frames", type=int, default=None,
                       help="only the first N frames of each capture (dev aid)")

    p = sub.add_parser("facts"); common(p); p.add_argument("--out")
    p.set_defaults(func=cmd_facts)

    p = sub.add_parser("label"); common(p)
    p.add_argument("--readings", required=True); p.add_argument("--out")
    p.set_defaults(func=cmd_label)

    p = sub.add_parser("report"); common(p)
    p.add_argument("--readings", required=True); p.add_argument("--json")
    p.set_defaults(func=cmd_report)

    p = sub.add_parser("mutate"); common(p)
    p.add_argument("--readings", required=True); p.add_argument("--json")
    p.set_defaults(func=cmd_mutate)

    p = sub.add_parser("score"); common(p)
    p.add_argument("--readings", required=True)
    p.add_argument("--alarms", required=True)
    p.add_argument("--onset-tolerance", type=float, default=1.0)
    p.add_argument("--rulebook-size", type=int, default=96,
                   help="obligations in the statute; BC MVA Part 3 is ss.119-214")
    p.set_defaults(func=cmd_score)

    args = parser.parse_args(argv)
    if not getattr(args, "func", None):
        parser.print_help()
        return 2
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
