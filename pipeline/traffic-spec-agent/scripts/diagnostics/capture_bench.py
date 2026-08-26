"""Evaluate the library against a whole directory of CARLA captures.

`monitor --rsv-dir …` answers "does the library agree with the ground truth on
*this* capture". This module answers the question that decides whether a
specification is any good: **does the library tell the two counterparts apart?**

A rule reporting `compliant` on both the lawful and the unlawful run of the same
scenario agrees with the label half the time and is worthless; one reporting
`violated` on both is worse. Evaluating the pair together turns those into named
outcomes — `BLIND`, `TRIGGER-HAPPY` — instead of two unrelated rows in two
separate reports.

Captures are produced by the sibling CARLA pipeline
(`../sg/carla_scene_graphs/src/run_capture.py`), one directory each, carrying
`rsv/`, `ego_logs.json` and a `labels.json` derived from CARLA-server ground
truth. Pairing is by directory name: `<scenario>_compliant` / `<scenario>_violation`.
"""

from __future__ import annotations

import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from scripts.diagnostics import capture_eval
from scripts.lean_check import (
    CAPTURE_EVAL_TIMEOUT,
    LeanUnavailable,
    eval_harness,
    first_errors,
    lake_build,
    write_capture_harness,
)

# One Lean module reused for every capture: the harness imports it by name and
# captures are evaluated in turn, so there is no reason to accumulate a module
# per capture in the library.
MODULE_NAME = "Bench"

PAIR_MODES = ("compliant", "violation")

# Outcomes of comparing a scenario's two counterpart captures.
DISCRIMINATES = "ok"
BLIND = "BLIND"                    # both runs reported compliant
TRIGGER_HAPPY = "TRIGGER-HAPPY"    # both runs reported violated
INVERTED = "INVERTED"              # the verdicts are the wrong way round
UNGROUNDED = "UNGROUNDED"          # no rule grounds on either run
UNTESTABLE = "UNTESTABLE"          # a capture is shorter than the rule's span
INCOMPLETE = "INCOMPLETE"          # one half of the pair is missing

PAIR_DETAIL = {
    BLIND: "the library reports the unlawful run as compliant too; the rule is "
           "too weak, grounds on the wrong entities, or its antecedent never fires",
    TRIGGER_HAPPY: "the library reports the lawful run as a violation too; the "
                   "rule is too strict or reads the wrong field",
    INVERTED: "the verdicts are the wrong way round — check the relation "
              "direction (Pred.behind v w means v is behind w)",
    UNGROUNDED: "no rule grounds on either run; the binders do not match what "
                "the capture contains",
    UNTESTABLE: "the capture is shorter than the rule's frame span, so its "
                "verdict is an artefact — record a longer capture",
    INCOMPLETE: "only one half of the pair was recorded",
}


@dataclass
class CaptureResult:
    name: str
    path: Path
    frames: int = 0
    outcomes: list = field(default_factory=list)
    missing_labels: list[str] = field(default_factory=list)
    error: Optional[str] = None

    @property
    def ok(self) -> bool:
        return (self.error is None
                and not any(o.is_disagreement for o in self.outcomes))

    def by_law(self) -> dict:
        return {o.law: o for o in self.outcomes}


def discover(database: Path, only: Optional[str] = None) -> list[Path]:
    """Capture directories: those carrying the frames and a label file."""
    found = []
    for child in sorted(database.iterdir()):
        if not child.is_dir() or (only and child.name != only):
            continue
        if (child / "rsv").is_dir() and (child / "labels.json").is_file():
            found.append(child)
    return found


def convert(capture: Path, repo_root: Path, library: Path,
            adapter_python: str) -> None:
    """Convert the **whole** capture — every frame, no window.

    Windowing was a workaround for Lean's code generator and it was unsound: a
    rule's verdict then depended on how many frames happened to be converted,
    because a `.bounded` window overrunning the trace reads as false and so
    reports compliant. `carla/adapter.py` now emits the trace in chunks, which
    removes the limit and the trade-off with it.
    """
    out_lean = library / "TrafficSpec" / "Carla" / f"{MODULE_NAME}.lean"
    cmd = [adapter_python, str(repo_root / "carla" / "adapter.py"),
           "--rsv-dir", str(capture / "rsv"),
           "--output", str(out_lean),
           "--module-name", MODULE_NAME]
    ego_log = capture / "ego_logs.json"
    if ego_log.exists():
        cmd += ["--ego-log", str(ego_log)]
    proc = subprocess.run(cmd, cwd=repo_root, text=True, capture_output=True)
    if proc.returncode != 0:
        hint = ""
        if "No module named" in proc.stderr:
            hint = (" — pass --adapter-python pointing at an interpreter with "
                    "networkx installed")
        tail = (proc.stderr.strip().splitlines() or ["(no output)"])[-1]
        raise RuntimeError(f"adapter failed{hint}: {tail}")


def evaluate(capture: Path, repo_root: Path, library: Path,
             adapter_python: str,
             eval_timeout: float = CAPTURE_EVAL_TIMEOUT) -> CaptureResult:
    result = CaptureResult(name=capture.name, path=capture)
    try:
        convert(capture, repo_root, library, adapter_python)

        module = f"TrafficSpec.Carla.{MODULE_NAME}"
        ok, output = lake_build(library, target=module)
        if not ok:
            hint = ""
            if "maximum recursion depth" in output:
                hint = (" — the trace still overflows Lean's code generator; "
                        "lower CHUNK_FRAMES in carla/adapter.py")
            result.error = f"build failed{hint}: {first_errors(output, 2)}"
            return result

        harness = repo_root / "results" / "_bench_harness.lean"
        write_capture_harness(harness, module, f"{module}Trace")
        ok, output = eval_harness(library, harness, timeout=eval_timeout)
        if not ok:
            hint = (" — evaluation exceeded the budget; a rule with several "
                    "structural binders multiplies the grounding count"
                    if "TIMEOUT" in output else "")
            result.error = f"harness failed{hint}: {first_errors(output, 2)}"
            return result

        frames, rows = capture_eval.parse_capture_report(output)
        if not rows:
            result.error = "the harness reported no rules; is Index.lean empty?"
            return result

        _name, _annotator, labels = capture_eval.load_labels(
            capture / "labels.json")
        result.frames = frames
        result.outcomes = capture_eval.evaluate(labels, rows, frames)
        result.missing_labels = capture_eval.unlabelled_rules(labels, rows)
    except (RuntimeError, ValueError, LeanUnavailable) as exc:
        result.error = str(exc)
    return result


def pair_status(left, right) -> str:
    """Classify a scenario from its two counterpart outcomes for one law."""
    if left is None or right is None:
        return INCOMPLETE
    if left.is_untested or right.is_untested:
        return UNTESTABLE
    if left.groundings == 0 and right.groundings == 0:
        return UNGROUNDED
    lawful, unlawful = left.spec, right.spec
    if lawful == "compliant" and unlawful == "violated":
        return DISCRIMINATES
    if lawful == "violated" and unlawful == "compliant":
        return INVERTED
    if lawful == "violated" and unlawful == "violated":
        return TRIGGER_HAPPY
    if lawful in ("compliant", "not_applicable") and unlawful in (
            "compliant", "not_applicable"):
        return BLIND
    return "MIXED"


def format_capture(result: CaptureResult) -> str:
    if result.error:
        return f"\n{result.name}: \033[91m{result.error}\033[0m"
    lines = [f"\n{result.name}  ({result.frames} frames)",
             f"  {'law':<20} {'ground truth':<16} {'spec':<16} {'grnd':>5}  status",
             f"  {'-' * 20} {'-' * 16} {'-' * 16} {'-' * 5}  {'-' * 20}"]
    for o in result.outcomes:
        lines.append(f"  {o.law:<20} {o.label:<16} {o.spec:<16} "
                     f"{o.groundings:>5}  {o.status}")
        if o.is_untested:
            lines.append(f"  {'':<20} \033[91m^ {o.note}\033[0m")
    if result.missing_labels:
        lines.append(f"  rules exist but the capture has no label for: "
                     f"{', '.join(result.missing_labels)}")
    return "\n".join(lines)


def format_pairs(results: dict[str, CaptureResult]) -> tuple[str, list[str]]:
    scenarios: dict[str, dict[str, CaptureResult]] = {}
    for name, result in results.items():
        for mode in PAIR_MODES:
            suffix = f"_{mode}"
            if name.endswith(suffix):
                scenarios.setdefault(name[: -len(suffix)], {})[mode] = result

    lines = ["", "=" * 78,
             "Counterpart pairs — does the library separate lawful from unlawful?",
             "=" * 78,
             f"{'scenario':<24} {'law':<20} {'lawful':<14} {'unlawful':<14} status",
             f"{'-' * 24} {'-' * 20} {'-' * 14} {'-' * 14} {'-' * 14}"]
    failures: list[str] = []
    skipped = 0

    for scenario in sorted(scenarios):
        pair = scenarios[scenario]
        left_res, right_res = pair.get("compliant"), pair.get("violation")
        laws: list[str] = []
        for res in (left_res, right_res):
            if res:
                laws += [o.law for o in res.outcomes if o.law not in laws]

        for law in laws:
            left = left_res.by_law().get(law) if left_res else None
            right = right_res.by_law().get(law) if right_res else None
            if left is None or right is None:
                lines.append(f"{scenario:<24} {law:<20} {'-':<14} {'-':<14} "
                             f"{INCOMPLETE}")
                failures.append(f"{scenario}/{law}: {INCOMPLETE}")
                continue
            # Discrimination is only testable where the ground truth differs.
            # A law that is the same on both sides tests agreement (shown in the
            # per-capture tables), not separation.
            if left.label == right.label:
                skipped += 1
                continue
            status = pair_status(left, right)
            lines.append(f"{scenario:<24} {law:<20} {left.spec:<14} "
                         f"{right.spec:<14} {status}")
            if status != DISCRIMINATES:
                failures.append(f"{scenario}/{law}: {status}")

    if skipped:
        lines.append(f"\n{skipped} law/pair combination(s) not shown: the ground "
                     f"truth is the same on both runs, so they test agreement "
                     f"but not discrimination.")
    broken = [n for n, r in results.items() if r.error]
    if broken:
        lines.append(f"\n{len(broken)} capture(s) could not be evaluated, so this "
                     f"table is incomplete: {', '.join(broken)}")
    if not failures and not broken:
        lines.append("\nEvery engaged law separates its counterparts.")
    elif failures:
        lines += ["", "Pairs that do not separate — each is a finding:"]
        for failure in failures:
            key = failure.rsplit(": ", 1)[-1]
            lines.append(f"  - {failure} — {PAIR_DETAIL.get(key, '')}")
    return "\n".join(lines), failures


def run(database: Path, repo_root: Path, library: Path, adapter_python: str,
        only: Optional[str] = None,
        eval_timeout: float = CAPTURE_EVAL_TIMEOUT) -> int:
    captures = discover(database, only)
    if not captures:
        print(f"[error] no captures found in {database} — a capture directory "
              f"needs rsv/ and labels.json", file=sys.stderr)
        return 2

    print(f"Evaluating {len(captures)} capture(s) from {database}")
    results: dict[str, CaptureResult] = {}
    for capture in captures:
        print(f"  - {capture.name} ...", flush=True)
        results[capture.name] = evaluate(capture, repo_root, library,
                                         adapter_python, eval_timeout)

    for result in results.values():
        print(format_capture(result))

    pairs, failures = format_pairs(results)
    print(pairs)

    broken = [r for r in results.values() if r.error]
    disagreeing = [r for r in results.values() if not r.error and not r.ok]
    agreeing = len(results) - len(broken) - len(disagreeing)
    print("\n" + "-" * 78)
    print(f"{agreeing}/{len(results)} captures agree with their ground truth "
          f"({len(disagreeing)} disagree, {len(broken)} could not be evaluated).")

    if broken:
        return 2
    return 1 if (failures or disagreeing) else 0
