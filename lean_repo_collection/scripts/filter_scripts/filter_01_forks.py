#!/usr/bin/env python3
"""
filter_01_forks.py — Step 1: Drop forks, and disabled repos.

No network calls or checkpointing needed — instant metadata pass.

Input:  lean_repositories.jsonl (raw collection)
Output: step1_nonforks.jsonl

Usage:
    python filter_01_forks.py \\
        --input lean_repositories.jsonl \\
        --output pipeline_output/step1_nonforks.jsonl
"""

import argparse
import json
from collections import Counter


def main():
    parser = argparse.ArgumentParser(description="Drop forks and disabled repos (archived kept).")
    parser.add_argument("--input", required=True, help="Input JSONL file")
    parser.add_argument("--output", required=True, help="Output JSONL file")
    args = parser.parse_args()
 
    total = kept = archived_kept = 0
    drop_reasons = Counter()
 
    with open(args.input) as fin, open(args.output, "w") as fout:
        for line in fin:
            line = line.strip()
            if not line:
                continue
            total += 1
            repo = json.loads(line)
 
            if repo.get("fork"):
                drop_reasons["fork"] += 1
                continue
            if repo.get("disabled"):
                drop_reasons["disabled"] += 1
                continue
 
            # archived repos are KEPT — annotate rather than drop.
            if repo.get("archived"):
                archived_kept += 1
            repo["archived_flag"] = bool(repo.get("archived"))
 
            kept += 1
            fout.write(json.dumps(repo) + "\n")
 
    print(f"Total:          {total}")
    print(f"Kept:           {kept}  (of which archived: {archived_kept})")
    print(f"Dropped:        {total - kept}")
    for reason, count in drop_reasons.most_common():
        print(f"  {reason}: {count}")
 
 
if __name__ == "__main__":
    main()