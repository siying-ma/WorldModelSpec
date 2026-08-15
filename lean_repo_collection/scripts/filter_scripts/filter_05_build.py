#!/usr/bin/env python3
"""
filter_05_build.py — Step 5: Clone and lake build. Keep only repos that compile.

For each repo:
  1. Shallow-clone (--depth 1).
  2. Inspect lake-manifest.json for a mathlib dependency.
  3. If mathlib: run `lake exe cache get` (fetches pre-built .olean cache),
     then `lake build`.
     If no mathlib: run `lake build` directly.
  4. Record pass / fail with elapsed time; stream output to a per-repo log file.
  5. Delete the clone immediately to reclaim disk space.

Per-repo log files go to --log-dir (default: pipeline_output/build_logs/).
Checkpoint stores {full_name: {keep, reason, mathlib, elapsed}} so the run
can be interrupted and resumed at any time.

Parallelism model:
  lake build has NO --jobs / -j flag. The two knobs are:
    --workers N        — concurrent lake processes (one per repo).
    --jobs-per-build T — sets LEAN_NUM_THREADS per process (Lean's internal
                         elaboration thread pool).
  Total threads ≈ workers × jobs_per_build. Most Lean repos are small
  (< 20 modules), so Lean's thread pool is rarely the bottleneck — running
  MORE workers with FEWER threads per build saturates CPUs better than
  fewer workers with many threads. Defaults auto-size to cpu_count.

⚠  Notes:
  - Each Lean toolchain version is ~1-3 GB in ~/.elan/toolchains/.
    Periodically run: elan toolchain list / elan toolchain uninstall <version>
  - Default timeout is 30 min per repo; increase for large mathlib-heavy projects.

Requires: git, elan, lake (lake is installed by elan via lean-toolchain)

Usage:
    python filter_05_build.py \\
        --input          pipeline_output/step4_deduped.jsonl \\
        --output         pipeline_output/step5_builds.jsonl \\
        --checkpoint     pipeline_output/checkpoints/build_results.json \\
        --workers        28 \\
        --jobs-per-build 4 \\
        --timeout        1800 \\
        --work-dir       /tmp/lean_builds \\
        --log-dir        pipeline_output/build_logs \\
        --keep-dir       pipeline_output/built_repos
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import threading
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed

MATHLIB_URL  = "https://github.com/leanprover-community/mathlib4.git"

# Thread-safe tracking of which toolchains are actively being used by workers.
# cleanup_toolchains() checks this before uninstalling anything.
_active_toolchain_lock: threading.Lock = threading.Lock()
_active_toolchains: Counter = Counter()


def _register_toolchain(name: str):
    with _active_toolchain_lock:
        _active_toolchains[name] += 1


def _unregister_toolchain(name: str):
    with _active_toolchain_lock:
        _active_toolchains[name] -= 1
        if _active_toolchains[name] <= 0:
            del _active_toolchains[name]


def _toolchain_name_from_file(clone_dir: str):
    """Return the elan internal toolchain name for the repo, or None."""
    tc_file = os.path.join(clone_dir, "lean-toolchain")
    try:
        content = open(tc_file).read().strip().splitlines()[0].strip()
        if content:
            # elan stores toolchains with / → -- and : → ---
            return content.replace("/", "--").replace(":", "---")
    except Exception:
        pass
    return None


MATHLIB_NAME = "mathlib"

DEFAULT_TIMEOUT        = 1800   # seconds
DEFAULT_JOBS_PER_BUILD = 4      # LEAN_NUM_THREADS per lake process
# Auto-size workers: most repos are small so more workers > more threads/build.
# cpu_count // DEFAULT_JOBS_PER_BUILD saturates available CPUs by default.
DEFAULT_WORKERS        = max(1, (os.cpu_count() or 4) // DEFAULT_JOBS_PER_BUILD)
CLONE_TIMEOUT          = 300    # 5 min ceiling for git clone


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def has_mathlib(repo_dir):
    """Return True if lake-manifest.json lists mathlib as a dependency."""
    manifest = os.path.join(repo_dir, "lake-manifest.json")
    if not os.path.exists(manifest):
        return False
    try:
        with open(manifest) as f:
            data = json.load(f)
        for pkg in data.get("packages", []):
            if pkg.get("url") == MATHLIB_URL or pkg.get("name") == MATHLIB_NAME:
                return True
    except Exception:
        pass
    return False


def cleanup_toolchains():
    """
    Remove stale elan state to free disk space:
      - ~/.elan/tmp/*          partial/abandoned downloads
      - toolchains ending in .tmp   incomplete installs
      - non-default fully-installed toolchains (via elan uninstall)
    """
    elan_home = os.environ.get("ELAN_HOME", os.path.expanduser("~/.elan"))

    # 1. Wipe the elan download temp dir (can be several GB of partial tarballs)
    tmp_dir = os.path.join(elan_home, "tmp")
    if os.path.isdir(tmp_dir):
        for entry in os.listdir(tmp_dir):
            path = os.path.join(tmp_dir, entry)
            try:
                if os.path.isdir(path):
                    shutil.rmtree(path)
                else:
                    os.remove(path)
            except Exception as e:
                print(f"  [cleanup] could not remove {path}: {e}", flush=True)
        print(f"  [cleanup] cleared {tmp_dir}", flush=True)

    # 2. Remove incomplete toolchain installs (directories named *.tmp)
    tc_dir = os.path.join(elan_home, "toolchains")
    if os.path.isdir(tc_dir):
        for entry in os.listdir(tc_dir):
            if entry.endswith(".tmp"):
                path = os.path.join(tc_dir, entry)
                try:
                    shutil.rmtree(path)
                    print(f"  [cleanup] removed incomplete toolchain: {entry}", flush=True)
                except Exception as e:
                    print(f"  [cleanup] could not remove {path}: {e}", flush=True)

    # 3. Uninstall non-default fully-installed toolchains, but skip any that
    #    are still being used by an active parallel build worker.
    with _active_toolchain_lock:
        currently_active = set(_active_toolchains.keys())
    try:
        out = subprocess.check_output(["elan", "toolchain", "list"], text=True)
        for line in out.splitlines():
            line = line.strip()
            if line and "(default)" not in line:
                tc = line.split()[0]
                if tc in currently_active:
                    print(f"  [cleanup] skipping active toolchain: {tc}", flush=True)
                    continue
                print(f"  [cleanup] uninstalling toolchain: {tc}", flush=True)
                subprocess.run(["elan", "toolchain", "uninstall", tc],
                               capture_output=True)
    except Exception as e:
        print(f"  [cleanup] toolchain list/uninstall failed: {e}", flush=True)


def run_cmd(cmd, cwd, timeout, log_fh, extra_env=None):
    """
    Run *cmd* in *cwd*, writing stdout+stderr to *log_fh*.
    Returns (success: bool, elapsed: float).
    """
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)
    start = time.time()
    try:
        proc = subprocess.run(
            cmd, cwd=cwd,
            stdout=log_fh, stderr=subprocess.STDOUT,
            timeout=timeout, text=True, env=env,
        )
        return proc.returncode == 0, time.time() - start
    except subprocess.TimeoutExpired:
        log_fh.write(f"\n[TIMEOUT after {timeout}s]\n")
        return False, time.time() - start
    except Exception as exc:
        log_fh.write(f"\n[EXCEPTION] {exc}\n")
        return False, time.time() - start


# ---------------------------------------------------------------------------
# Per-repo build
# ---------------------------------------------------------------------------

def build_repo(repo, work_dir, timeout, log_dir, cached, jobs_per_build=8,
               keep_dir=None, keep_artifacts=False):
    # XDG_CACHE_HOME and ELAN_HOME are set on os.environ in main() so they are
    # inherited by every subprocess via os.environ.copy() in run_cmd().
    # lean_env only needs to carry per-build overrides (thread count here).
    lean_env = {"LEAN_NUM_THREADS": str(jobs_per_build)}
    full_name = repo["full_name"]
    if full_name in cached:
        return full_name, cached[full_name]

    safe_name = full_name.replace("/", "__")
    clone_dir = os.path.join(work_dir, safe_name)
    log_path  = os.path.join(log_dir, safe_name + ".log")

    result = {
        "keep":     False,
        "reason":   "",
        "mathlib":  False,
        "elapsed":  0,
        "saved_to": None,
    }

    build_ok = False
    active_tc = None   # toolchain registered with _active_toolchains for this build
    try:
        with open(log_path, "w") as log:

            # 1. Clone
            ok, _ = run_cmd(
                ["git", "clone", "--depth", "1", repo["clone_url"], clone_dir],
                cwd=work_dir, timeout=CLONE_TIMEOUT, log_fh=log,
            )
            if not ok:
                result["reason"] = "clone_failed"
                return full_name, result

            # Register this repo's toolchain so cleanup_toolchains() won't
            # uninstall it while lake build is still running.
            active_tc = _toolchain_name_from_file(clone_dir)
            if active_tc:
                _register_toolchain(active_tc)

            # 2. Check mathlib dependency
            mathlib = has_mathlib(clone_dir)
            result["mathlib"] = mathlib

            # 3a. Fetch pre-built cache for mathlib projects.
            # cache get can fail due to network issues; its exit code is logged
            # but we always proceed to lake build (fall back to building from source).
            if mathlib:
                cache_ok, _ = run_cmd(
                    ["lake", "exe", "cache", "get"],
                    cwd=clone_dir, timeout=timeout // 2, log_fh=log,
                    extra_env=lean_env,
                )
                if not cache_ok:
                    log.write("\n[WARNING] lake exe cache get failed; proceeding with build from source\n")
                    log.flush()

            # 3b. Build — LEAN_NUM_THREADS (via lean_env) controls Lean's internal
            # thread pool per task. Lake's own job scheduler handles parallel tasks.
            build_ok, elapsed = run_cmd(
                ["lake", "build"],
                cwd=clone_dir, timeout=timeout, log_fh=log,
                extra_env=lean_env,
            )
            result["elapsed"] = round(elapsed)

            if build_ok:
                result["keep"]   = True
                result["reason"] = "build_success"
            else:
                result["reason"] = "build_failed"

    finally:
        # Always release the toolchain slot so cleanup_toolchains() can proceed.
        if active_tc:
            _unregister_toolchain(active_tc)
        if build_ok and keep_dir:
            # Successful build: save the repo for further use.
            dest = os.path.join(keep_dir, safe_name)
            if os.path.exists(dest):
                shutil.rmtree(dest, ignore_errors=True)
            if not keep_artifacts:
                # Strip .lake/ before saving — build artifacts can be many GB
                # for mathlib-heavy projects; source files are what matters.
                lake_cache = os.path.join(clone_dir, ".lake")
                if os.path.exists(lake_cache):
                    shutil.rmtree(lake_cache, ignore_errors=True)
            try:
                shutil.move(clone_dir, dest)
                result["saved_to"] = dest
            except Exception:
                shutil.rmtree(clone_dir, ignore_errors=True)
        else:
            # Failed build or no keep_dir: delete clone to reclaim disk space.
            shutil.rmtree(clone_dir, ignore_errors=True)

    return full_name, result


# ---------------------------------------------------------------------------
# Checkpoint helpers
# ---------------------------------------------------------------------------

def load_checkpoint(path):
    if path and os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return {}


def save_checkpoint(path, data):
    if not path:
        return
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w") as f:
        json.dump(data, f, indent=2)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input",      required=True)
    parser.add_argument("--output",     required=True)
    parser.add_argument(
        "--checkpoint",
        default="pipeline_output/checkpoints/build_results.json",
    )
    parser.add_argument(
        "--workers", type=int, default=DEFAULT_WORKERS,
        help="Parallel build workers (default 2; keep low — lake build is CPU-heavy)",
    )
    parser.add_argument(
        "--timeout", type=int, default=DEFAULT_TIMEOUT,
        help="Per-repo lake build timeout in seconds (default 1800 = 30 min)",
    )
    parser.add_argument(
        "--work-dir", default=None,
        help="Directory for temporary clones (default: system temp dir)",
    )
    parser.add_argument(
        "--log-dir", default="pipeline_output/build_logs",
        help="Directory for per-repo build logs",
    )
    parser.add_argument(
        "--jobs-per-build", type=int, default=DEFAULT_JOBS_PER_BUILD,
        help="Sets LEAN_NUM_THREADS per lake process (Lean's elaboration thread pool). "
             "Total CPU threads ≈ workers × jobs-per-build. "
             "For small repos prefer more --workers with fewer --jobs-per-build.",
    )
    parser.add_argument(
        "--toolchain-cleanup-every", type=int, default=10,
        help="Uninstall non-default elan toolchains every N repos (default 5). "
             "Lower this if you're running out of disk space.",
    )
    parser.add_argument(
        "--keep-dir", default=None,
        help="Directory to save successfully built repo sources for further use. "
             "If omitted, all clones are deleted after each build.",
    )
    parser.add_argument(
        "--keep-artifacts", action="store_true",
        help="Also retain the .lake/ build directory inside --keep-dir. "
             "Off by default because .lake/ can be many GB for mathlib projects.",
    )
    parser.add_argument(
        "--cache-home", default=None,
        help="Sets XDG_CACHE_HOME (mathlib .olean cache) and ELAN_HOME (toolchain "
             "downloads) for every subprocess. Point this at a large filesystem to "
             "avoid filling the home directory. Example: /local-scratch3/$USER/.cache",
    )
    parser.add_argument(
        "--retry-failed", action="store_true",
        help="Drop 'build_failed' entries from the checkpoint before starting so "
             "those repos are retried in this run.",
    )
    args = parser.parse_args()

    # Check tools are available
    for tool in ("git", "lake"):
        if not shutil.which(tool):
            print(f"Error: '{tool}' not found in PATH. Install elan/lake before running step 5.", file=sys.stderr)
            sys.exit(1)

    repos = []
    with open(args.input) as f:
        for line in f:
            line = line.strip()
            if line:
                repos.append(json.loads(line))

    checkpoint = load_checkpoint(args.checkpoint)

    if args.retry_failed:
        failed = [k for k, v in checkpoint.items() if v.get("reason") == "build_failed"]
        for k in failed:
            del checkpoint[k]
        if failed:
            print(f"--retry-failed: dropped {len(failed)} build_failed entries from checkpoint")
            save_checkpoint(args.checkpoint, checkpoint)

    print(f"Repos loaded:   {len(repos)}")
    print(f"Already cached: {len(checkpoint)}")

    work_dir = os.path.abspath(args.work_dir) if args.work_dir else tempfile.mkdtemp(prefix="lean_build_")
    os.makedirs(work_dir, exist_ok=True)
    os.makedirs(os.path.abspath(args.log_dir), exist_ok=True)
    args.log_dir = os.path.abspath(args.log_dir)
    if args.keep_dir:
        args.keep_dir = os.path.abspath(args.keep_dir)
        os.makedirs(args.keep_dir, exist_ok=True)
    # Resolve cache_home: explicit flag > env var already set > None.
    if args.cache_home:
        cache_home = os.path.abspath(args.cache_home)
    elif os.environ.get("XDG_CACHE_HOME"):
        cache_home = os.path.abspath(os.environ["XDG_CACHE_HOME"])
        print(f"Cache home:     {cache_home}  (from $XDG_CACHE_HOME)")
    else:
        cache_home = None
        default_cache = os.path.expanduser("~/.cache")
        print(
            f"[WARNING] --cache-home not set and $XDG_CACHE_HOME is unset.\n"
            f"  mathlib .olean cache and elan toolchains will land in {default_cache}\n"
            f"  which may fill the home filesystem.  Pass --cache-home or set\n"
            f"  XDG_CACHE_HOME to a large filesystem (e.g. /local-scratch3/$USER/.cache).",
            flush=True,
        )

    if cache_home:
        os.makedirs(cache_home, exist_ok=True)
        # Set in the current process so the env is inherited by ALL subprocesses,
        # including any lake invocations not going through run_cmd(extra_env=...).
        os.environ["XDG_CACHE_HOME"] = cache_home
        os.environ["ELAN_HOME"] = os.path.join(cache_home, ".elan")
        print(f"Cache home:     {cache_home}  (XDG_CACHE_HOME + ELAN_HOME)")
        # Ensure the redirected ELAN_HOME has a default toolchain configured.
        # A fresh directory has no default; repos without lean-toolchain would
        # crash with "no default toolchain configured" otherwise.
        new_elan_home = os.environ["ELAN_HOME"]
        elan_cfg = os.path.join(new_elan_home, "elan-config.toml")
        if not os.path.exists(elan_cfg):
            print(f"  Initializing elan default in {new_elan_home} ...", flush=True)
            subprocess.run(
                ["elan", "default", "leanprover/lean4:stable"],
                check=False,
            )

    results = dict(checkpoint)
    pending = [r for r in repos if r["full_name"] not in checkpoint]
    effective_threads = args.workers * args.jobs_per_build
    print(f"To build:       {len(pending)}")
    print(f"Workers:        {args.workers}  ×  LEAN_NUM_THREADS={args.jobs_per_build}"
          f"  →  ~{effective_threads} CPU threads  (available: {os.cpu_count()})")
    print(f"Timeout:        {args.timeout}s per repo")
    print(f"Work dir:       {work_dir}")
    print(f"Logs:           {args.log_dir}")
    print()

    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(
                build_repo, r, work_dir, args.timeout, args.log_dir, checkpoint,
                args.jobs_per_build, args.keep_dir, args.keep_artifacts,
            ): r
            for r in pending
        }
        for fut in as_completed(futures):
            full_name, result = fut.result()
            results[full_name] = result
            done += 1
            icon  = "✓" if result.get("keep") else "✗"
            ml    = " [mathlib]" if result.get("mathlib") else ""
            saved = f" → {result['saved_to']}" if result.get("saved_to") else ""
            print(
                f"  [{done:>4}/{len(pending)}] {icon} {full_name}{ml}"
                f" — {result['reason']} ({result.get('elapsed', 0)}s){saved}",
                flush=True,
            )
            if done % 10 == 0:
                save_checkpoint(args.checkpoint, results)
            if done % args.toolchain_cleanup_every == 0:
                cleanup_toolchains()

    save_checkpoint(args.checkpoint, results)

    kept = 0
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w") as fout:
        for repo in repos:
            r = results.get(repo["full_name"], {})
            if r.get("keep"):
                fout.write(json.dumps(repo) + "\n")
                kept += 1

    dropped = len(repos) - kept
    print(f"\nKept (builds):  {kept}")
    print(f"Dropped:        {dropped}")
    reasons = Counter(v["reason"] for v in results.values() if not v.get("keep"))
    print("Fail reasons:")
    for reason, count in reasons.most_common():
        print(f"  {reason}: {count}")
    print(f"\nFinal output: {args.output}")
    print(f"Build logs:   {args.log_dir}/")
    if args.keep_dir:
        saved = sum(1 for v in results.values() if v.get("saved_to"))
        print(f"Saved repos:  {saved} → {args.keep_dir}/")


if __name__ == "__main__":
    main()
