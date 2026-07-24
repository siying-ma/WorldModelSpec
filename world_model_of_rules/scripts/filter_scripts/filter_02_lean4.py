#!/usr/bin/env python3
"""
filter_02_lean4.py — Step 2: Drop pre-Lean 4 repos (multi-phase check).

CHANGES vs. the original:
  * Issue 1 (recall): the fast-path date drop now uses `pushed_at` (last push),
    NOT `created_at`. A repo created as a Lean 3 project in 2020/2021 and later
    migrated to Lean 4 keeps its old `created_at` but has a recent `pushed_at`,
    so it is now checked instead of silently dropped.
  * Issue 2 (recall): when the root `lean-toolchain` is missing (404), we no
    longer drop immediately. We list the repo git tree and look for a
    `lean-toolchain` in a subdirectory (monorepo / package-in-subdir) or a
    Lake build file (`lakefile.lean`/`lakefile.toml`, which are Lean 4 only;
    `leanpkg.toml` is the Lean 3 marker). Only if none of these Lean 4 signals
    exist do we fall back to the topic heuristic / drop.

Phase 1 — lean-toolchain:
  - Repos whose LAST PUSH predates 2022-01-01 → drop without fetching
    (overwhelmingly Lean 3 and inactive since).
  - Fetch <branch>/lean-toolchain.
      "lean4" found        → confirmed Lean 4 → keep.
      not lean4            → drop.
      404                  → Phase 1b (tree search) before deciding.
      fetch error          → drop.

Phase 1b — git-tree search (only when root lean-toolchain is 404):
  - List the tree recursively via the GitHub API.
      subdir lean-toolchain containing "lean4"  → keep.
      lakefile.lean / lakefile.toml present      → Lean 4 build → keep.
      only leanpkg.toml present                   → Lean 3 → drop.
      tree unavailable / inconclusive             → topic heuristic:
          "lean4" in topics → uncertain → Phase 2.
          else              → drop.

Phase 2 — leanpkg.toml check (only for the "uncertain" cohort):
  - Fetch <branch>/leanpkg.toml.
      Found (200)     → Lean 3 confirmed → drop.
      Not found (404) → keep.
      Fetch error     → keep (benefit of the doubt).

Single checkpoint file stores every phase per repo so the run can be
interrupted and resumed at any point without re-fetching completed work.

Checkpoint entry schema:
  {
    "toolchain_reason": str,   # set after phase 1 / 1b
    "leanpkg_checked":  bool,  # set after phase 2 (only for uncertain repos)
    "leanpkg_found":    bool,
    "keep":             bool,
    "final_reason":     str
  }

Requires: pip install requests

Usage:
    export GITHUB_TOKEN='ghp_...'
    python filter_02_lean4.py \\
        --input      pipeline_output/step1_nonforks.jsonl \\
        --output     pipeline_output/step2_lean4.jsonl \\
        --checkpoint pipeline_output/checkpoints/lean4_check.json \\
        --workers    8
"""

import argparse
import json
import os
import sys
import time
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone

import requests

# Repos with no activity since this date cannot be Lean 4 (and are not
# migrations worth checking). Compared against `pushed_at`, not `created_at`.
LEAN4_ACTIVITY_CUTOFF = datetime(2022, 1, 1, tzinfo=timezone.utc)

RAW_URL  = "https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{filename}"
TREE_URL = "https://api.github.com/repos/{owner}/{repo}/git/trees/{branch}?recursive=1"

TOKEN = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN", "")
HEADERS = {"Authorization": f"token {TOKEN}"} if TOKEN else {}

# Lean 4 build files (Lake). leanpkg.toml is intentionally NOT here — it is the
# Lean 3 package marker.
LAKE_FILES = ("lakefile.lean", "lakefile.toml")


# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------

def fetch_raw(owner, repo, branch, filename):
    """
    Fetch a single raw file. Returns (content_or_None, http_status).
    Handles rate-limit back-off and retries.
    """
    url = RAW_URL.format(owner=owner, repo=repo, branch=branch, filename=filename)
    for attempt in range(3):
        try:
            r = requests.get(url, headers=HEADERS, timeout=10)
            if r.status_code == 200:
                return r.text.strip(), 200
            if r.status_code == 404:
                return None, 404
            if r.status_code in (403, 429):
                reset = int(r.headers.get("X-RateLimit-Reset", time.time() + 60))
                wait = max(reset - time.time(), 5)
                print(f"  Rate-limited, sleeping {wait:.0f}s …", flush=True)
                time.sleep(wait)
                continue
            if attempt == 2:
                return None, r.status_code
            time.sleep(2 ** attempt)
        except requests.RequestException:
            if attempt == 2:
                return None, -1
            time.sleep(2 ** attempt)
    return None, -1


def fetch_tree(owner, repo, branch):
    """
    List every blob path in the repo tree (recursive) via the GitHub API.
    Returns a list[str] of paths, or None on error/unavailable.
    Note: for very large repos the API may set "truncated": true; in that case
    we still return whatever paths we got (lean-toolchain/lakefile live near the
    root, so they are virtually always present in the first page).
    """
    url = TREE_URL.format(owner=owner, repo=repo, branch=branch)
    for attempt in range(3):
        try:
            r = requests.get(url, headers=HEADERS, timeout=15)
            if r.status_code == 200:
                data = r.json()
                return [
                    item["path"]
                    for item in data.get("tree", [])
                    if item.get("type") == "blob"
                ]
            if r.status_code == 404:
                return None
            if r.status_code in (403, 429):
                reset = int(r.headers.get("X-RateLimit-Reset", time.time() + 60))
                wait = max(reset - time.time(), 5)
                print(f"  Rate-limited (tree), sleeping {wait:.0f}s …", flush=True)
                time.sleep(wait)
                continue
            if attempt == 2:
                return None
            time.sleep(2 ** attempt)
        except requests.RequestException:
            if attempt == 2:
                return None
            time.sleep(2 ** attempt)
    return None


# ---------------------------------------------------------------------------
# Phase 1 (+ 1b): lean-toolchain / tree search
# ---------------------------------------------------------------------------

def _basename(path):
    return path.rsplit("/", 1)[-1]


def phase1_worker(repo, cached):
    """
    Returns (full_name, entry) where entry is a complete checkpoint record
    if the decision is final, or a partial one if phase 2 is still needed.
    A cached entry is returned as-is if phase 1 is already done.
    """
    full_name = repo["full_name"]
    entry = cached.get(full_name, {})

    # Already has a toolchain_reason → phase 1 done, skip
    if "toolchain_reason" in entry:
        return full_name, entry

    owner  = repo["owner_login"]
    name   = repo["name"]
    branch = repo["default_branch"]

    # ---- Fast path: no activity since the Lean 4 era → cannot be Lean 4. ----
    # Use pushed_at (last push) so repos created as Lean 3 and later migrated to
    # Lean 4 (recent pushes) are NOT dropped here. Fall back to created_at only
    # if pushed_at is missing.
    pushed = repo.get("pushed_at") or repo.get("created_at")
    if pushed:
        pushed_dt = datetime.fromisoformat(pushed.replace("Z", "+00:00"))
        if pushed_dt < LEAN4_ACTIVITY_CUTOFF:
            return full_name, {
                "toolchain_reason": "inactive_before_2022",
                "keep": False,
                "final_reason": "inactive_before_2022",
            }

    # ---- Root lean-toolchain ----
    content, status = fetch_raw(owner, name, branch, "lean-toolchain")

    if status == 200 and content:
        if "lean4" in content.lower():
            return full_name, {
                "toolchain_reason": "toolchain_lean4",
                "keep": True,
                "final_reason": "toolchain_lean4",
            }
        return full_name, {
            "toolchain_reason": "toolchain_not_lean4",
            "keep": False,
            "final_reason": f"toolchain_not_lean4:{content[:60].strip()}",
        }

    if status == 404:
        # ---- Phase 1b: the toolchain may live in a subdirectory. ----
        tree = fetch_tree(owner, name, branch)
        if tree is not None:
            sub_toolchains = [p for p in tree if _basename(p) == "lean-toolchain"]
            has_lake     = any(_basename(p) in LAKE_FILES for p in tree)
            has_leanpkg  = any(_basename(p) == "leanpkg.toml" for p in tree)

            # A subdir lean-toolchain that names lean4 is definitive.
            for tc_path in sub_toolchains:
                c, s = fetch_raw(owner, name, branch, tc_path)
                if s == 200 and c and "lean4" in c.lower():
                    return full_name, {
                        "toolchain_reason": "toolchain_lean4_subdir",
                        "keep": True,
                        "final_reason": f"toolchain_lean4_subdir:{tc_path}",
                    }

            # A Lake build file is a Lean 4 signal (leanpkg.toml would be Lean 3).
            if has_lake:
                return full_name, {
                    "toolchain_reason": "lakefile_lean4",
                    "keep": True,
                    "final_reason": "lakefile_lean4",
                }

            # Only a Lean 3 package marker present → drop.
            if has_leanpkg:
                return full_name, {
                    "toolchain_reason": "leanpkg_toml_in_tree",
                    "keep": False,
                    "final_reason": "leanpkg_toml_in_tree",
                }
            # else: tree had no Lean 4/3 markers → fall through to topic heuristic.

        # Tree unavailable or inconclusive → topic heuristic.
        if "lean4" in (repo.get("topics") or []):
            # Uncertain — needs phase 2
            return full_name, {
                "toolchain_reason": "no_toolchain_lean4_topic",
                # keep / final_reason set after phase 2
            }
        return full_name, {
            "toolchain_reason": "no_toolchain_no_lean4_topic",
            "keep": False,
            "final_reason": "no_toolchain_no_lean4_topic",
        }

    # Fetch error
    return full_name, {
        "toolchain_reason": f"fetch_error:{status}",
        "keep": False,
        "final_reason": f"fetch_error:{status}",
    }


# ---------------------------------------------------------------------------
# Phase 2: leanpkg.toml (only for "no_toolchain_lean4_topic" repos)
# ---------------------------------------------------------------------------

def phase2_worker(repo, entry):
    """
    Mutates and returns entry with leanpkg check results.
    """
    full_name = repo["full_name"]

    # Already checked
    if entry.get("leanpkg_checked"):
        return full_name, entry

    _, status = fetch_raw(
        repo["owner_login"], repo["name"], repo["default_branch"], "leanpkg.toml"
    )

    found = (status == 200)
    entry["leanpkg_checked"] = True
    entry["leanpkg_found"] = found

    if found:
        entry["keep"] = False
        entry["final_reason"] = "leanpkg_toml_found"
    else:
        entry["keep"] = True
        entry["final_reason"] = "no_toolchain_lean4_topic_no_leanpkg"

    return full_name, entry


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
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--checkpoint",
        default="pipeline_output/checkpoints/lean4_check.json",
    )
    parser.add_argument(
        "--workers", type=int, default=8,
        help="Parallel HTTP workers (default 8; keep ≤ 16 to stay within rate limits)",
    )
    args = parser.parse_args()

    if not TOKEN:
        print(
            "Warning: GITHUB_TOKEN / GH_TOKEN not set. The git-tree fallback "
            "uses the GitHub API (60 req/hr unauthenticated) — set a token.",
            file=sys.stderr,
        )

    repos = []
    with open(args.input) as f:
        for line in f:
            line = line.strip()
            if line:
                repos.append(json.loads(line))

    checkpoint = load_checkpoint(args.checkpoint)
    results = dict(checkpoint)
    print(f"Repos loaded:    {len(repos)}")
    print(f"Already cached:  {len(checkpoint)}")

    # -----------------------------------------------------------------------
    # Phase 1: lean-toolchain (+ 1b tree search)
    # -----------------------------------------------------------------------
    p1_pending = [r for r in repos if "toolchain_reason" not in results.get(r["full_name"], {})]
    print(f"\n[Phase 1] lean-toolchain — to fetch: {len(p1_pending)}")

    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(phase1_worker, r, results): r for r in p1_pending}
        for fut in as_completed(futures):
            full_name, entry = fut.result()
            results[full_name] = entry
            done += 1
            if done % 200 == 0:
                print(f"  {done}/{len(p1_pending)} checked …", flush=True)
                save_checkpoint(args.checkpoint, results)

    save_checkpoint(args.checkpoint, results)

    # -----------------------------------------------------------------------
    # Phase 2: leanpkg.toml for uncertain repos
    # -----------------------------------------------------------------------
    p2_pending = [
        r for r in repos
        if results.get(r["full_name"], {}).get("toolchain_reason") == "no_toolchain_lean4_topic"
        and not results.get(r["full_name"], {}).get("leanpkg_checked")
    ]
    print(f"\n[Phase 2] leanpkg.toml check — uncertain repos to fetch: {len(p2_pending)}")

    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {
            pool.submit(phase2_worker, r, results[r["full_name"]]): r
            for r in p2_pending
        }
        for fut in as_completed(futures):
            full_name, entry = fut.result()
            results[full_name] = entry
            done += 1
            if done % 100 == 0:
                print(f"  {done}/{len(p2_pending)} checked …", flush=True)
                save_checkpoint(args.checkpoint, results)

    save_checkpoint(args.checkpoint, results)

    # -----------------------------------------------------------------------
    # Write output
    # -----------------------------------------------------------------------
    kept = 0
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w") as fout:
        for repo in repos:
            entry = results.get(repo["full_name"], {})
            if entry.get("keep"):
                fout.write(json.dumps(repo) + "\n")
                kept += 1

    dropped = len(repos) - kept
    print(f"\nKept:    {kept}")
    print(f"Dropped: {dropped}")

    reasons = Counter(
        entry.get("final_reason", "unknown").split(":")[0]
        for entry in results.values()
        if not entry.get("keep")
    )
    print("Drop reasons:")
    for reason, count in reasons.most_common():
        print(f"  {reason}: {count}")


if __name__ == "__main__":
    main()