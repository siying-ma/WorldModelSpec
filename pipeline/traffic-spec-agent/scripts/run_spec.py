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
from .lean_check import (
    CAPTURE_EVAL_TIMEOUT,
    EVAL_LIB_ROOT,
    LeanUnavailable,
    captures_under,
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

        # No capture inside the tree the formalization agents read.
        #
        # The prompts send both agents into `library/TrafficSpec/` — Core, the
        # vocabulary, the builders — and an agent with a shell reads the rest of
        # that directory. A converted capture there is not a file it is told to
        # read; it is a file it can find, and one run shows what that costs: a
        # plan agent counted an attribute's occurrences in a converted capture
        # and used the count to argue that a predicate was not dead. That is a
        # claim about one recording standing in for a claim about the data
        # model, and it inverts the pipeline, because a capture is what a rule
        # is TESTED against.
        #
        # This is not a rule against captures in the library: the evaluation
        # set is Lean traces and belongs there. It is a rule about where they
        # sit — `library/TrafficSpecEval/`, its own library root, which no
        # prompt names. Refusing to start is deliberate: a warning here would be
        # read after the run, and by then the reasoning is already in the rule
        # comments and in PROGRESS.md, where the next iteration inherits it.
        library = _resolve(library_root)
        stray = captures_under(library / "TrafficSpec")
        if stray:
            print("[error] converted capture(s) inside the tree the agents read:",
                  file=sys.stderr)
            for path in stray:
                print(f"          {path.relative_to(library)}", file=sys.stderr)
            print(f"        Move them under {EVAL_LIB_ROOT}/ (their own library "
                  f"root) and re-run. A capture is evidence for `monitor`, not "
                  f"for formalization.", file=sys.stderr)
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
                           library_root=library)
        Loop(ctx).run()
        return 0

    def doctor(self, library_root: str = "library", verbose: bool = False) -> int:
        """Cross-check every agent-facing claim against the artifact it describes.

        The artifacts that decide spec quality — the prompt templates, the
        frozen ontology, the Core docstrings — describe things they do not own:
        the Lean core, the gate's verdict set, the witness roles. This compares
        each description with the thing described and names both sources on
        failure. No model, no Lean, no simulator:

            python -m scripts.run_spec doctor

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

    def monitor(self, *args, **kwargs) -> int:
        """Evaluate the library against recorded driving and diff against derived labels.

        Rebuilt with adapter v2: the previous implementation converted CARLA
        scene-graph captures through the archived `carla/adapter.py` and scored
        them with `scripts/diagnostics/capture_eval.py`, both of which belong to
        the CARLA-first design now on `archive/carla-first-2026-09-15`. The
        replacement reads a source's capability manifest, evaluates every rule
        with four-valued verdicts (violated / compliant / not_applicable /
        unknown) and reports accuracy with `unknown` separated.
        """
        print("[error] `monitor` is being rebuilt on Core v2 and the source "
              "adapters; the CARLA-first version is on the archive branch.",
              file=sys.stderr)
        return 2

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
