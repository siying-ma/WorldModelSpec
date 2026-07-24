#!/usr/bin/env python3
"""
filter_03_noise.py — Step 3: Drop empty repos (metadata only).

All checks are metadata-only (no network calls, no cloning). Fast and instant.

Drop conditions:
  1. size == 0  (GitHub reports 0 KB — repo is truly empty)
  2. size < --size-min KB  (default 0, i.e. disabled)

Noise/coursework filters and low-signal (0 stars + 0 forks + small size) have
been intentionally removed. This corpus is used as VLM reference context for
auto-formalization, where coursework repos (exercises, homework, tutorials) are
valuable formalization examples, and small single-file proofs are legitimate
content. Step 5 (clone + content check) handles quality filtering on actual
Lean file content.

Usage:
    python filter_03_noise.py \\
        --input  pipeline_output/step2_lean4.jsonl \\
        --output pipeline_output/step3_denoised.jsonl
"""

import argparse
import json
import os
from collections import Counter

# ---------------------------------------------------------------------------
# Decision
# ---------------------------------------------------------------------------

def drop_reason(repo, size_min_kb):
    """
    Returns (drop: bool, reason: str). reason is '' if kept.
    """
    size = repo.get("size", 0)   # GitHub size field is in KB

    # 1. Truly empty (GitHub reports 0 KB)
    if size == 0:
        return True, "size_zero"

    # 2. Below explicit minimum (disabled by default; pass --size-min to enable)
    if size_min_kb > 0 and size < size_min_kb:
        return True, f"size_too_small ({size} KB)"

    return False, ""


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--size-min", type=int, default=0,
        help=(
            "Drop repos below this size in KB (default 0 = disabled). "
            "Prefer leaving at 0 and letting step 5 handle content quality."
        ),
    )
    args = parser.parse_args()

    total = kept = 0
    bucket = Counter()   # coarse reason buckets for the summary

    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.input) as fin, open(args.output, "w") as fout:
        for line in fin:
            line = line.strip()
            if not line:
                continue
            total += 1
            repo = json.loads(line)

            drop, reason = drop_reason(repo, args.size_min)
            if drop:
                # Coarse bucket key
                coarse = reason.split(" ")[0].split("_")[0]
                bucket[coarse] += 1
            else:
                kept += 1
                fout.write(json.dumps(repo) + "\n")

    print(f"Total:   {total}")
    print(f"Kept:    {kept}")
    print(f"Dropped: {total - kept}")
    print("Drop reasons:")
    for reason, count in bucket.most_common():
        print(f"  {reason}: {count}")


if __name__ == "__main__":
    main()