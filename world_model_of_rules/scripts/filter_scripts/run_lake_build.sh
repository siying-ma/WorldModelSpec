#!/usr/bin/env bash
#
# Usage:
#   export GITHUB_TOKEN='ghp_...'
#   bash scripts/filter_scripts/run_lake_build.sh projects/filter_repo
#


set -euo pipefail

OUT="${1:-pipeline_output}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"

mkdir -p "$OUT/build_logs"

# ---------------------------------------------------------------------------
echo "--- Step 5: lake build (slow — CPU intensive) ---"
echo "    Workers:  2  |  Timeout: 1800s per repo"
echo "    Tip: run elan toolchain uninstall <version> periodically to free disk"
python3 "$SCRIPTS/filter_05_build.py" \
    --input          "$OUT/step4_deduped.jsonl" \
    --output         "$OUT/step5_builds.jsonl" \
    --checkpoint     "$OUT/checkpoints/build_results.json" \
    --workers        10 \
    --jobs-per-build 4 \
    --timeout        1800 \
    --log-dir        "$OUT/build_logs" \
    --work-dir       "$OUT/build_work" \
    --keep-dir       "$OUT/built_repos"

echo ""
echo "========================================"
echo " Pipeline complete!"
echo " Final output: $OUT/step5_builds.jsonl"
echo ""
echo " Repo counts per step:"
for f in "$OUT"/step*.jsonl; do
    printf "  %-35s %s\n" "$(basename "$f")" "$(wc -l < "$f") repos"
done
echo "========================================"

