#!/usr/bin/env python3
"""
filter_04_dedup.py — Step 4: Deduplicate and drop skeleton repos via lakefile hash.

For each repo:
  - Fetch lakefile.lean (tried first) or lakefile.toml from raw.githubusercontent.com.
  - Drop "skeleton" lakefiles: missing, too short, or containing only import/open/option
    lines with no real declarations.
  - Hash remaining lakefiles (SHA-256). Repos sharing an identical hash are duplicates;
    keep the one with the most stars (ties broken by earlier created_at).
  - Checkpoint is a JSON dict {full_name: {filename, hash, skeleton, reason, line_count}}
    so interrupted runs resume without re-fetching.

Requires: pip install requests

Usage:
    export GITHUB_TOKEN='ghp_...'
    python filter_04_dedup.py \\
        --input  pipeline_output/step3_denoised.jsonl \\
        --output pipeline_output/step4_deduped.jsonl \\
        --checkpoint pipeline_output/checkpoints/lakefile_cache.json \\
        --workers 8
"""

import argparse
import hashlib
import json
import os
import time
from collections import Counter, defaultdict
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests

RAW_URL = "https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{filename}"
LAKEFILE_NAMES = ["lakefile.lean", "lakefile.toml"]

TOKEN = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN", "")
HEADERS = {"Authorization": f"token {TOKEN}"} if TOKEN else {}

# Skeleton: lines that provide no real content.
_CONTENT_FREE_PREFIXES = ("import ", "open ", "set_option ", "--", "/-", "-/")


# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------

def fetch_lakefile(owner, repo, branch):
    """Try lakefile.lean then lakefile.toml. Returns (filename, content) or (None, None)."""
    for filename in LAKEFILE_NAMES:
        url = RAW_URL.format(owner=owner, repo=repo, branch=branch, filename=filename)
        for attempt in range(3):
            try:
                r = requests.get(url, headers=HEADERS, timeout=10)
                if r.status_code == 200:
                    return filename, r.text
                if r.status_code == 404:
                    break  # try next filename
                if r.status_code in (403, 429):
                    reset = int(r.headers.get("X-RateLimit-Reset", time.time() + 60))
                    wait = max(reset - time.time(), 5)
                    time.sleep(wait)
                    continue
                if attempt == 2:
                    break
                time.sleep(2 ** attempt)
            except requests.RequestException:
                if attempt == 2:
                    break
                time.sleep(2 ** attempt)
    return None, None


# ---------------------------------------------------------------------------
# Skeleton detection
# ---------------------------------------------------------------------------

def classify_lakefile(content):
    """
    Returns (is_skeleton: bool, reason: str).
    """
    if content is None:
        return True, "no_lakefile"

    stripped = content.strip()
    if not stripped:
        return True, "empty_lakefile"

    lines = [l.strip() for l in stripped.splitlines()]
    non_empty = [l for l in lines if l]

    if len(non_empty) < 3:
        return True, f"too_short ({len(non_empty)} lines)"

    # If every non-empty line starts with a content-free prefix, there are no
    # real declarations — it's a skeleton.
    def content_free(line):
        return any(line.startswith(p) for p in _CONTENT_FREE_PREFIXES)

    if all(content_free(l) for l in non_empty):
        return True, "imports_only"

    return False, ""


def sha256(text):
    return hashlib.sha256(text.encode()).hexdigest()


# ---------------------------------------------------------------------------
# Per-repo worker
# ---------------------------------------------------------------------------

def process_repo(repo, cached):
    full_name = repo["full_name"]
    if full_name in cached:
        return full_name, cached[full_name]

    filename, content = fetch_lakefile(
        repo["owner_login"], repo["name"], repo["default_branch"]
    )
    skeleton, reason = classify_lakefile(content)
    result = {
        "filename": filename,
        "hash": sha256(content) if content else None,
        "skeleton": skeleton,
        "reason": reason,
        "line_count": len(content.splitlines()) if content else 0,
    }
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
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--checkpoint",
        default="pipeline_output/checkpoints/lakefile_cache.json",
    )
    parser.add_argument("--workers", type=int, default=8)
    args = parser.parse_args()

    repos = []
    with open(args.input) as f:
        for line in f:
            line = line.strip()
            if line:
                repos.append(json.loads(line))

    checkpoint = load_checkpoint(args.checkpoint)
    print(f"Repos loaded:   {len(repos)}")
    print(f"Already cached: {len(checkpoint)}")

    results = dict(checkpoint)
    pending = [r for r in repos if r["full_name"] not in checkpoint]
    print(f"To fetch:       {len(pending)}")

    done = 0
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(process_repo, r, checkpoint): r for r in pending}
        for fut in as_completed(futures):
            full_name, result = fut.result()
            results[full_name] = result
            done += 1
            if done % 200 == 0:
                print(f"  {done}/{len(pending)} fetched …", flush=True)
                save_checkpoint(args.checkpoint, results)

    save_checkpoint(args.checkpoint, results)

    # --- Drop skeletons ---
    after_skeleton = []
    dropped_skeleton = Counter()
    for repo in repos:
        r = results.get(repo["full_name"], {})
        if r.get("skeleton"):
            dropped_skeleton[r.get("reason", "unknown")] += 1
        else:
            after_skeleton.append(repo)

    # --- Deduplicate by hash ---
    hash_groups = defaultdict(list)
    no_hash = []
    for repo in after_skeleton:
        h = results.get(repo["full_name"], {}).get("hash")
        if h:
            hash_groups[h].append(repo)
        else:
            no_hash.append(repo)

    kept = []
    dropped_dup = 0
    for h, group in hash_groups.items():
        # Keep the repo with most stars; break ties by earliest created_at (the original).
        # min() with (-stars, created_at) picks the highest star count and, on a tie,
        # the lexicographically smallest ISO date (i.e. the oldest repo).
        best = min(
            group,
            key=lambda r: (-r.get("stargazers_count", 0), r.get("created_at", ""))
        )
        kept.append(best)
        dropped_dup += len(group) - 1
    kept.extend(no_hash)

    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w") as fout:
        for repo in kept:
            fout.write(json.dumps(repo) + "\n")

    total_dropped = len(repos) - len(kept)
    print(f"\nInput:              {len(repos)}")
    print(f"Dropped (skeleton): {sum(dropped_skeleton.values())}")
    for reason, count in dropped_skeleton.most_common():
        print(f"  {reason}: {count}")
    print(f"Dropped (dup):      {dropped_dup}")
    print(f"Kept:               {len(kept)}")


if __name__ == "__main__":
    main()
