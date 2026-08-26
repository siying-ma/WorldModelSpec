"""CLI entry point.

    python -m scripts.run_spec init
    python -m scripts.run_spec loop    --run-id ca_w32 --laws laws/example/laws.jsonl
    python -m scripts.run_spec verify
    python -m scripts.run_spec doctor
    python -m scripts.run_spec monitor --rsv-dir <capture>/rsv --labels labels/<name>.json
    python -m scripts.run_spec index
    python -m scripts.run_spec cleanup --run-id ca_w32

`loop` is the normal path; the others are slices of it for debugging.

`verify` and `monitor` are the two acceptance checks, and they are not
interchangeable. `verify` runs each rule against the scenarios the plan agent
wrote for it — fast, but self-referential, since the agent that chose the
formalization also chose its tests. `monitor` runs the whole library against a
real CARLA capture and diffs the verdicts against labels a person wrote from the
footage, which is the only signal here that does not come from the agent.

Note: `fire` prints a command's return value rather than using it as the process
exit status, so `$?` is 0 even when `monitor` reports disagreements. Read the
printed value, or wrap `main()` in `sys.exit(...)` if you need this in CI.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path
from typing import Optional

import fire

from . import index_sync
from .diagnostics import capture_eval
from .lean_check import (
    CAPTURE_EVAL_TIMEOUT,
    LeanUnavailable,
    eval_harness,
    first_errors,
    lake_build,
    write_capture_harness,
    write_library_harness,
)
from .loop import Loop, LoopOptions, build_context
from .state import init_state_dir

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_LAWS = "laws/example/laws.jsonl"


def _resolve(path: str | Path) -> Path:
    p = Path(path)
    return p if p.is_absolute() else (REPO_ROOT / p)


class Cli:
    """Autoformalize natural-language traffic law into CARLA-format Lean specs."""

    def init(self, library_root: str = "library", laws: str = DEFAULT_LAWS,
             run_id: str = "default") -> int:
        """Check the toolchain, build the core, and create the state directory."""
        library = _resolve(library_root)
        laws_file = _resolve(laws)

        print("[1/4] Checking `claude`...")
        if shutil.which("claude") is None:
            print("      NOT FOUND — install Claude Code before running the loop.")
        else:
            print("      ok")

        print("[2/4] Checking the Lean toolchain...")
        if shutil.which("lake") is None:
            print("      `lake` NOT FOUND. Run `bash setup.sh` to install elan, then")
            print("      re-run init. The loop cannot verify specifications without it.")
            return 1
        print("      ok")

        print(f"[3/4] Building the library at {library}...")
        try:
            ok, output = lake_build(library)
        except LeanUnavailable as exc:
            print(f"      {exc}")
            return 1
        if not ok:
            print("      BUILD FAILED:")
            print(first_errors(output))
            return 1
        print("      ok")

        print("[4/4] Preparing state...")
        if not laws_file.exists():
            print(f"      law corpus not found: {laws_file}")
            return 1
        init_state_dir(REPO_ROOT / "state" / run_id)
        print(f"      state/{run_id} ready; {sum(1 for _ in open(laws_file)) } law line(s)")
        print("\nReady. Start the loop with:")
        print(f"  python -m scripts.run_spec loop --run-id {run_id} --laws {laws}")
        return 0

    def loop(
        self,
        run_id: str = "default",
        laws: str = DEFAULT_LAWS,
        library_root: str = "library",
        max_iterations: int = 3,
        max_nodes_per_iter: int = 8,
        max_turns: int = 60,
        timeout_minutes: Optional[float] = 45,
        model: Optional[str] = None,
        effort: Optional[str] = None,
        max_budget_usd: Optional[float] = None,
        from_phase: Optional[str] = None,
        force_stage: Optional[str] = None,
        dry_run: bool = False,
    ) -> int:
        """Run the plan → code → integrate loop."""
        laws_file = _resolve(laws)
        if not laws_file.exists():
            print(f"[error] law corpus not found: {laws_file}", file=sys.stderr)
            return 1

        options = LoopOptions(
            max_iterations=max_iterations,
            max_nodes_per_iter=max_nodes_per_iter,
            max_turns=max_turns,
            timeout_minutes=timeout_minutes,
            model=model,
            effort=effort,
            max_budget_usd=max_budget_usd,
            from_phase=from_phase,
            force_stage=force_stage,
            dry_run=dry_run,
        )
        ctx = build_context(REPO_ROOT, laws_file, run_id, options,
                           library_root=_resolve(library_root))
        Loop(ctx).run()
        return 0

    def doctor(self, library_root: str = "library", verbose: bool = False) -> int:
        """Cross-check every agent-facing claim against the artifact it describes.

        The two artifacts that decide spec quality — `carla/schema.json` and
        `prompts/*.txt` — describe things they do not own: the Lean core, the
        adapter, the generator, the gate's verdict set. This compares each
        description with the thing described and names both sources on failure.

        No model, no Lean, no CARLA server. Checks needing the sibling CARLA repo
        are skipped rather than failed, so it runs anywhere:

            python -m scripts.run_spec doctor
            PYTHONPATH=../sg/carla_scene_graphs python -m scripts.run_spec doctor

        Returns 1 if any check fails, so it belongs in CI. Note `fire` prints the
        return value rather than exiting with it.
        """
        from .diagnostics import doctor as doctor_mod
        return doctor_mod.run(REPO_ROOT, _resolve(library_root), verbose)

    def verify(self, library_root: str = "library") -> int:
        """Build the library and re-run every rule's scenarios. No agent involved."""
        library = _resolve(library_root)
        try:
            ok, output = lake_build(library)
            if not ok:
                print("BUILD FAILED:")
                print(first_errors(output))
                return 1
            print("build: ok")

            harness = REPO_ROOT / "results" / "_verify_harness.lean"
            write_library_harness(harness)
            # Whole-library scale, not node scale: every rule against every one
            # of its scenarios, and a rule with several binders grounds many
            # times even on a short trace.
            ok, output = eval_harness(library, harness,
                                      timeout=CAPTURE_EVAL_TIMEOUT)
        except LeanUnavailable as exc:
            print(f"[error] {exc}", file=sys.stderr)
            return 1

        if not ok:
            print("SCENARIO HARNESS FAILED:")
            print(first_errors(output))
            return 1

        rows = [ln for ln in output.splitlines() if ln.startswith("SCEN\t")]
        failures = [r for r in rows if r.rstrip().split("\t")[-1] != "PASS"]
        for row in rows:
            parts = row.split("\t")
            if len(parts) >= 6:
                mark = "ok  " if parts[5] == "PASS" else "FAIL"
                print(f"  {mark} {parts[1]}  expected={parts[2]} actual={parts[3]} "
                      f"groundings={parts[4]}")
        print(f"\n{len(rows) - len(failures)}/{len(rows)} scenarios pass "
              f"across {index_sync.registered_count(library)} rule(s)")
        return 1 if failures else 0

    def monitor(self, rsv_dir: Optional[str] = None, labels: Optional[str] = None,
                ego_log: Optional[str] = None, library_root: str = "library",
                module_name: str = "Captured", max_frames: Optional[int] = None,
                adapter_python: Optional[str] = None,
                skip_convert: bool = False,
                database: Optional[str] = None,
                capture: Optional[str] = None,
                eval_timeout: Optional[float] = None) -> int:
        """Evaluate every registered rule against real CARLA captures and diff the
        verdicts against ground-truth labels.

        `verify` checks a spec against scenarios the plan agent wrote for it;
        this checks it against footage labelled independently of that agent, and
        is the external check to run after the loop.

        **A whole capture set at once** — one directory per capture, each with
        `rsv/`, `ego_logs.json` and its own `labels.json`, as written by
        `../sg/carla_scene_graphs/src/run_capture.py`:

            python -m scripts.run_spec monitor \\
                --database ../sg/carla_scene_graphs/database \\
                --adapter-python $(which python)

        Captures named `<scenario>_compliant` / `<scenario>_violation` are also
        paired, which is the question a single capture cannot answer: does the
        library separate lawful from unlawful? Add `--capture NAME` to restrict
        the run to one directory.

        **A single capture** with an external label file:

            python -m scripts.run_spec monitor \\
                --rsv-dir  .../sceneflow_sample/data/rsv \\
                --ego-log  .../sceneflow_sample/data/ego_logs.json \\
                --labels   labels/sceneflow_sample.json

        Pass `--adapter-python` when the interpreter running this CLI lacks
        `networkx`, which unpickling a capture needs. `--skip-convert` reuses an
        already-converted trace module (single-capture mode only).
        """
        library = _resolve(library_root)
        if database is not None:
            from scripts.diagnostics import capture_bench
            root = Path(database).expanduser()
            if not root.is_absolute():
                root = (REPO_ROOT / root).resolve()
            if not root.is_dir():
                print(f"[error] no such directory: {root}", file=sys.stderr)
                return 2
            return capture_bench.run(
                root, REPO_ROOT, library, adapter_python or sys.executable,
                capture, eval_timeout or capture_bench.CAPTURE_EVAL_TIMEOUT)

        if labels is None:
            print("[error] --labels is required: the point of `monitor` is the "
                  "comparison against human ground truth. Write a label file "
                  "first (see scripts/diagnostics/capture_eval.py for the format).",
                  file=sys.stderr)
            return 2
        labels_file = _resolve(labels)
        if not labels_file.exists():
            print(f"[error] label file not found: {labels_file}", file=sys.stderr)
            return 2

        module = f"TrafficSpec.Carla.{module_name}"
        trace_name = f"TrafficSpec.Carla.{module_name}Trace"
        out_lean = library / "TrafficSpec" / "Carla" / f"{module_name}.lean"

        if not skip_convert:
            if rsv_dir is None:
                print("[error] --rsv-dir is required unless --skip-convert",
                      file=sys.stderr)
                return 2
            cmd = [adapter_python or sys.executable,
                   str(REPO_ROOT / "carla" / "adapter.py"),
                   "--rsv-dir", str(_resolve(rsv_dir)),
                   "--output", str(out_lean),
                   "--module-name", module_name]
            if ego_log:
                cmd += ["--ego-log", str(_resolve(ego_log))]
            if max_frames:
                cmd += ["--max-frames", str(max_frames)]
            print("[1/3] Converting the capture...")
            proc = subprocess.run(cmd, cwd=REPO_ROOT, text=True,
                                  capture_output=True)
            print(proc.stdout.rstrip())
            if proc.returncode != 0:
                print(proc.stderr.rstrip(), file=sys.stderr)
                if "No module named" in proc.stderr:
                    print("[hint] re-run with --adapter-python pointing at an "
                          "interpreter that has networkx installed.",
                          file=sys.stderr)
                return 1
        elif not out_lean.exists():
            print(f"[error] --skip-convert but {out_lean} does not exist",
                  file=sys.stderr)
            return 2

        try:
            print("[2/3] Building the library and the captured trace...")
            ok, output = lake_build(library, target=module)
            if not ok:
                print("BUILD FAILED:")
                print(first_errors(output))
                return 1

            harness = REPO_ROOT / "results" / "_capture_harness.lean"
            write_capture_harness(harness, module, trace_name)
            print("[3/3] Evaluating every rule against the capture...")
            ok, output = eval_harness(
                library, harness,
                timeout=eval_timeout or CAPTURE_EVAL_TIMEOUT)
        except LeanUnavailable as exc:
            print(f"[error] {exc}", file=sys.stderr)
            return 1

        if not ok:
            print("CAPTURE HARNESS FAILED:")
            print(first_errors(output))
            return 1

        frames, rows = capture_eval.parse_capture_report(output)
        if not rows:
            print("[error] the harness reported no rules; is Index.lean empty?",
                  file=sys.stderr)
            return 1
        try:
            capture, annotator, label_map = capture_eval.load_labels(labels_file)
        except ValueError as exc:
            print(f"[error] {exc}", file=sys.stderr)
            return 2

        outcomes = capture_eval.evaluate(label_map, rows, frames)
        missing = capture_eval.unlabelled_rules(label_map, rows)
        print("")
        print(capture_eval.format_report(capture, annotator, frames, outcomes,
                                         missing))
        return 1 if any(o.is_disagreement for o in outcomes) else 0

    def index(self, library_root: str = "library", dry_run: bool = False) -> int:
        """Regenerate Index.lean from the rule files on disk."""
        library = _resolve(library_root)
        changed, problems = index_sync.sync(library, dry_run=dry_run)
        if problems:
            print("Registry sync refused:")
            for p in problems:
                print(f"  - {p}")
            return 1
        print("Index.lean " + ("updated" if changed else "already current")
              + f" ({index_sync.registered_count(library)} rule(s))")
        return 0

    def sample(self, library_root: str = "library") -> int:
        """Regenerate the coverage fixture from Core/Scene.lean."""
        from scripts import sample_sync
        library = _resolve(library_root)
        path, changed = sample_sync.sync(library)
        print(f"{path.name} " + ("regenerated" if changed else "already current"))
        return 0

    def cleanup(self, run_id: str = "default", results: bool = False) -> int:
        """Remove generated harnesses, and optionally a run's results."""
        removed = 0
        for path in REPO_ROOT.rglob("*harness*.lean"):
            path.unlink()
            removed += 1
        print(f"Removed {removed} generated harness file(s)")
        if results:
            target = REPO_ROOT / "results" / run_id
            if target.exists():
                shutil.rmtree(target)
                print(f"Removed {target}")
        return 0

    def status(self, run_id: str = "default", library_root: str = "library") -> int:
        """Show what is in the library and where the run stands."""
        library = _resolve(library_root)
        files = index_sync.discover(library)
        print(f"Rules in library: {len(files)}")
        for f in files:
            print(f"  - {f.rel}   namespace {f.namespace}")
        progress = REPO_ROOT / "state" / run_id / "PROGRESS.md"
        if progress.exists():
            print(f"\n--- {progress} ---")
            print(progress.read_text(encoding="utf-8").strip())
        summary = REPO_ROOT / "results" / run_id / "summary.json"
        if summary.exists():
            print(f"\nSummary: {summary}")
        return 0


def main() -> None:
    fire.Fire(Cli)


if __name__ == "__main__":
    main()
