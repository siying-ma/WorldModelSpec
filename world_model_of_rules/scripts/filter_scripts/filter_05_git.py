#!/usr/bin/env python3
"""
filter_05_git.py — Step 5: Clone, deduplicate by structure fingerprint, save sources.

Replaces the old lake-build step. No Lean/elan required — just git.

Per repo:
  Phase A (parallel)
    1. Shallow-clone (--depth 1).
    2. Structure fingerprint: SHA-256 of sorted (rel_path, file_size) pairs for
       every .lean file (no contents read; .lake/.git skipped).
    3. Content check: at least --min-lean-files .lean files, each with at least
       --min-lines non-empty lines.
    4. Resolve commit SHA, then copy .lean + docs + license + config to
       --corpus-dir/<owner>/<repo>/ and write metadata.json. Mark "candidate".
    5. Delete the clone.
  Phase B (serial, deterministic)
    6. Group candidates by fingerprint; keep the highest-priority repo per
       group, prune duplicate folders.



Usage:
    python filter_05_git.py \\
        --input      pipeline_output/step3_denoised.jsonl \\
        --output     pipeline_output/step5_corpus.jsonl \\
        --checkpoint pipeline_output/checkpoints/collect_results.json \\
        --corpus-dir /path/to/lean_corpus \\
        --work-dir   /tmp/lean_collect \\
        --workers    32 \\
        --min-lean-files 1 \\
        --min-lines      10
"""

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

CLONE_TIMEOUT = 300   # 5 min per clone
DEFAULT_WORKERS = min(32, (os.cpu_count() or 4) * 2)  # cloning is I/O-bound
SKIP_DIRS = {".lake", ".git"}

# Lake config / toolchain files always kept.
CONFIG_FILES = {"lakefile.lean", "lakefile.toml", "lean-toolchain", "lake-manifest.json"}

# Text extensions worth keeping for reference context (docs, blueprints, code).
KEEP_EXTS = (".lean", ".md", ".rst", ".tex")


# ---------------------------------------------------------------------------
# File selection for saving
# ---------------------------------------------------------------------------

def should_save(fname):
    """
    True if this file should be copied into the corpus. Keeps Lean sources,
    docs/blueprints, config, README and LICENSE variants. All are small text.
    """
    low = fname.lower()
    if fname.endswith(KEEP_EXTS):
        return True
    if fname in CONFIG_FILES:
        return True
    if low.startswith(("readme", "license", "licence", "copying")):
        return True
    return False


# ---------------------------------------------------------------------------
# Structure fingerprint (unchanged — identity is the .lean layout)
# ---------------------------------------------------------------------------

def structure_fingerprint(clone_dir):
    """
    SHA-256 of sorted (relative_path, file_size) for every .lean file.
    No file contents are read — pure filesystem stat calls. Very fast.
    Returns (fingerprint: str, lean_file_count: int).
    """
    entries = []
    for root, dirs, files in os.walk(clone_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if not fname.endswith(".lean"):
                continue
            path = os.path.join(root, fname)
            rel  = os.path.relpath(path, clone_dir)
            size = os.path.getsize(path)
            entries.append(f"{rel}:{size}")
    entries.sort()
    digest = hashlib.sha256("\n".join(entries).encode()).hexdigest()
    return digest, len(entries)


# ---------------------------------------------------------------------------
# Content quality check
# ---------------------------------------------------------------------------

def count_nonempty_lines(path):
    try:
        with open(path, errors="replace") as f:
            return sum(1 for l in f if l.strip())
    except Exception:
        return 0


def has_enough_content(clone_dir, min_lean_files, min_lines):
    """
    Returns (ok: bool, lean_file_count: int).
    Passes if at least min_lean_files .lean files each have >= min_lines
    non-empty lines.
    """
    qualifying = 0
    total_lean = 0
    for root, dirs, files in os.walk(clone_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fname in files:
            if not fname.endswith(".lean"):
                continue
            total_lean += 1
            path = os.path.join(root, fname)
            if count_nonempty_lines(path) >= min_lines:
                qualifying += 1
            if qualifying >= min_lean_files:
                return True, total_lean
    return False, total_lean


# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------

def git_head(clone_dir):
    """Resolved commit SHA of the shallow clone (or None)."""
    try:
        out = subprocess.run(
            ["git", "-C", clone_dir, "rev-parse", "HEAD"],
            capture_output=True, text=True, timeout=30,
        )
        if out.returncode == 0:
            return out.stdout.strip()
    except Exception:
        pass
    return None


# ---------------------------------------------------------------------------
# Source saving + metadata
# ---------------------------------------------------------------------------

def save_sources(repo, clone_dir, corpus_dir, fingerprint, commit_sha, lean_count):
    """
    Copy .lean + docs + license + config from clone_dir to
    corpus_dir/<owner_login>/<repo_name>/ and write a metadata.json.
    Skips .lake/ and .git/. Returns the destination path.
    """
    dest = os.path.join(corpus_dir, repo["owner_login"], repo["name"])
    os.makedirs(dest, exist_ok=True)

    for root, dirs, files in os.walk(clone_dir):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        rel_root = os.path.relpath(root, clone_dir)
        for fname in files:
            if not should_save(fname):
                continue
            src = os.path.join(root, fname)
            dst = os.path.join(dest, rel_root, fname)
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(src, dst)

    _write_metadata(repo, dest, fingerprint, commit_sha, lean_count)
    return dest


def _write_metadata(repo, dest, fingerprint, commit_sha, lean_count):
    meta = {
        "full_name":      repo.get("full_name"),
        "repo_url":       repo.get("html_url") or repo.get("clone_url"),
        "clone_url":      repo.get("clone_url"),
        "commit_sha":     commit_sha,
        "default_branch": repo.get("default_branch"),
        "stars":          repo.get("stargazers_count", repo.get("stars", 0)),
        "description":    repo.get("description"),
        "topics":         repo.get("topics", []),
        "created_at":     repo.get("created_at"),
        "pushed_at":      repo.get("pushed_at"),
        "archived":       bool(repo.get("archived") or repo.get("archived_flag")),
        "license":        repo.get("license"),
        "fingerprint":    fingerprint,
        "lean_files":     lean_count,
    }
    with open(os.path.join(dest, "metadata.json"), "w") as f:
        json.dump(meta, f, indent=2)


# ---------------------------------------------------------------------------
# Deterministic winner selection
# ---------------------------------------------------------------------------

def priority_key(repo):
    """
    Total order for choosing the canonical repo among structural duplicates:
    most-starred first, then earliest-created (the likely original), then
    full_name alphabetically as a final stable tiebreaker.
    """
    stars = repo.get("stargazers_count", repo.get("stars", 0)) or 0
    created = repo.get("created_at") or "9999"
    return (-stars, created, repo.get("full_name", ""))


# ---------------------------------------------------------------------------
# Phase A worker: clone + fingerprint + content check + save candidate
# ---------------------------------------------------------------------------

def collect_repo(repo, work_dir, log_dir, cached,
                 corpus_dir, min_lean_files, min_lines):
    """
    Returns (full_name, result_dict). No dedup here — Phase B decides winners.
    """
    full_name = repo["full_name"]
    if full_name in cached:
        return full_name, cached[full_name]

    safe_name = full_name.replace("/", "__")
    clone_dir = os.path.join(work_dir, safe_name)
    log_path  = os.path.join(log_dir, safe_name + ".log")

    result = {
        "keep":        False,
        "reason":      "",
        "fingerprint": None,
        "lean_files":  0,
        "commit_sha":  None,
        "saved_to":    None,
    }

    start = time.time()
    try:
        # 1. Clone
        with open(log_path, "w") as log:
            proc = subprocess.run(
                ["git", "clone", "--depth", "1", repo["clone_url"], clone_dir],
                stdout=log, stderr=subprocess.STDOUT,
                timeout=CLONE_TIMEOUT, text=True,
            )
        if proc.returncode != 0:
            result["reason"] = "clone_failed"
            return full_name, result

        # 2. Structure fingerprint
        fp, lean_count = structure_fingerprint(clone_dir)
        result["fingerprint"] = fp
        result["lean_files"]  = lean_count

        if lean_count == 0:
            result["reason"] = "no_lean_files"
            return full_name, result

        # 3. Content quality check
        ok, _ = has_enough_content(clone_dir, min_lean_files, min_lines)
        if not ok:
            result["reason"] = "below_min_content"
            return full_name, result

        # 4. Resolve commit, save sources + metadata (candidate — dedup pending)
        commit = git_head(clone_dir)
        result["commit_sha"] = commit
        dest = save_sources(repo, clone_dir, corpus_dir, fp, commit, lean_count)
        result["saved_to"] = dest
        result["reason"]   = "candidate"

    except subprocess.TimeoutExpired:
        result["reason"] = "clone_timeout"
    except Exception as exc:
        result["reason"] = f"error:{exc}"
    finally:
        shutil.rmtree(clone_dir, ignore_errors=True)

    result["elapsed"] = round(time.time() - start)
    return full_name, result


# ---------------------------------------------------------------------------
# Phase B: deterministic dedup over all saved candidates
# ---------------------------------------------------------------------------

def deduplicate(results, repos_by_name):
    """
    Group everything currently occupying a corpus slot (candidate/saved) by
    fingerprint, keep the highest-priority repo per group, prune the rest.
    Idempotent: safe to re-run on resume.
    Returns (winners, dropped_dupes).
    """
    groups = defaultdict(list)
    for full_name, r in results.items():
        if r.get("reason") in ("candidate", "saved") and r.get("fingerprint"):
            groups[r["fingerprint"]].append(full_name)

    winners = dropped = 0
    for _fp, members in groups.items():
        members.sort(key=lambda fn: priority_key(repos_by_name.get(fn, {"full_name": fn})))
        winner = members[0]
        results[winner]["keep"] = True
        results[winner]["reason"] = "saved"
        winners += 1
        for loser in members[1:]:
            path = results[loser].get("saved_to")
            if path and os.path.isdir(path):
                shutil.rmtree(path, ignore_errors=True)
            results[loser]["keep"] = False
            results[loser]["reason"] = f"duplicate:{winner}"
            results[loser]["saved_to"] = None
            dropped += 1
    return winners, dropped


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
        default="pipeline_output/checkpoints/collect_results.json",
    )
    parser.add_argument(
        "--corpus-dir", default="lean_corpus",
        help="Where to save sources. Structure: <corpus-dir>/<owner>/<repo>/",
    )
    parser.add_argument(
        "--work-dir", default=None,
        help="Temp directory for clones (default: system temp). "
             "Point at a large disk — clones are deleted after each repo.",
    )
    parser.add_argument(
        "--workers", type=int, default=DEFAULT_WORKERS,
        help=f"Parallel clone workers (default {DEFAULT_WORKERS}). "
             "Cloning is I/O-bound so high counts (32–64) are fine.",
    )
    parser.add_argument(
        "--min-lean-files", type=int, default=1,
        help="Minimum number of .lean files with enough content (default 1).",
    )
    parser.add_argument(
        "--min-lines", type=int, default=10,
        help="Minimum non-empty lines per qualifying .lean file (default 10).",
    )
    args = parser.parse_args()

    if not shutil.which("git"):
        print("Error: 'git' not found in PATH.", file=sys.stderr)
        sys.exit(1)

    repos = []
    with open(args.input) as f:
        for line in f:
            line = line.strip()
            if line:
                repos.append(json.loads(line))

    repos_by_name = {r["full_name"]: r for r in repos}

    checkpoint = load_checkpoint(args.checkpoint)
    print(f"Repos loaded:    {len(repos)}")
    print(f"Already cached:  {len(checkpoint)}")

    work_dir = os.path.abspath(args.work_dir) if args.work_dir \
               else tempfile.mkdtemp(prefix="lean_collect_")
    log_dir  = os.path.join(os.path.dirname(os.path.abspath(args.checkpoint)),
                            "..", "collect_logs")
    os.makedirs(work_dir, exist_ok=True)
    os.makedirs(log_dir,  exist_ok=True)
    os.makedirs(args.corpus_dir, exist_ok=True)

    results = dict(checkpoint)
    pending = [r for r in repos if r["full_name"] not in checkpoint]
    print(f"To process:      {len(pending)}")
    print(f"Workers:         {args.workers}")
    print(f"Corpus dir:      {args.corpus_dir}")
    print(f"Min lean files:  {args.min_lean_files}  ×  min lines: {args.min_lines}")
    print()

    # -----------------------------------------------------------------------
    # Phase A: clone + fingerprint + content check + save candidate
    # -----------------------------------------------------------------------
    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(
                collect_repo, r, work_dir, log_dir, checkpoint,
                args.corpus_dir, args.min_lean_files, args.min_lines,
            ): r
            for r in pending
        }
        for fut in as_completed(futures):
            full_name, result = fut.result()
            results[full_name] = result
            done += 1
            icon = "•" if result.get("reason") == "candidate" else "✗"
            print(
                f"  [{done:>4}/{len(pending)}] {icon} {full_name}"
                f" — {result['reason']}"
                f" ({result.get('lean_files', 0)} .lean files,"
                f" {result.get('elapsed', 0)}s)",
                flush=True,
            )
            if done % 20 == 0:
                save_checkpoint(args.checkpoint, results)

    save_checkpoint(args.checkpoint, results)

    # -----------------------------------------------------------------------
    # Phase B: deterministic dedup
    # -----------------------------------------------------------------------
    print("\n[Phase B] deterministic dedup by fingerprint …")
    winners, dropped_dupes = deduplicate(results, repos_by_name)
    print(f"  Unique kept:      {winners}")
    print(f"  Duplicates pruned:{dropped_dupes}")
    save_checkpoint(args.checkpoint, results)

    # -----------------------------------------------------------------------
    # Write output
    # -----------------------------------------------------------------------
    kept = 0
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w") as fout:
        for repo in repos:
            r = results.get(repo["full_name"], {})
            if r.get("keep"):
                out = dict(repo)
                out["commit_sha"] = r.get("commit_sha")
                out["fingerprint"] = r.get("fingerprint")
                out["saved_to"] = r.get("saved_to")
                fout.write(json.dumps(out) + "\n")
                kept += 1

    dropped = len(repos) - kept
    print(f"\nKept:    {kept}")
    print(f"Dropped: {dropped}")
    reasons = Counter(
        v["reason"].split(":")[0] for v in results.values() if not v.get("keep")
    )
    print("Drop reasons:")
    for reason, count in reasons.most_common():
        print(f"  {reason}: {count}")
    print(f"\nFinal output: {args.output}")
    print(f"Corpus:       {args.corpus_dir}/")


if __name__ == "__main__":
    main()