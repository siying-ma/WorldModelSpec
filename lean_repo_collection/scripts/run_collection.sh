#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Github token: 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
if [[ -z "${GITHUB_TOKEN:-${GH_TOKEN:-}}" ]]; then
  echo "Set GITHUB_TOKEN or GH_TOKEN before running this script." >&2
  exit 2
fi

# Incremental update: fetch repos created after 2026-06-26 using --load-existing-jsonl
# pre-seeds the repo table so the final output contains all repos combined.
python3 scripts/collect_lean_repos.py \
  --projects-dir projects \
  --start-date 2026-05-27 \
  --initial-window-days 365 \
  --request-delay 2.1 \
  --load-existing-jsonl projects/lean_repositories.jsonl

python3 scripts/summarize_lean_repos.py projects/lean_repositories.jsonl
