#!/usr/bin/env bash
# run_pipeline.sh — Run all 5 filter steps in order.
#
# Usage:
#   export GITHUB_TOKEN='ghp_...'
#   bash run_pipeline.sh <input_jsonl> [output_dir]
#
# Example:
#   bash scripts/filter_scripts/run_pipeline.sh projects/lean_repositories.jsonl projects/filter_repo
#
# Each step reads from the previous step's output, so you can re-run any
# individual step independently if needed (just point --input at the right file).

set -euo pipefail

INPUT="${1:?Usage: $0 <input_jsonl> [output_dir] [corpus_dir]}"
OUT="${2:-pipeline_output}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
 
mkdir -p "$OUT/checkpoints"

LOG_FILE="$OUT/pipeline_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "Pipeline log: $LOG_FILE"

echo "========================================"
echo " Lean Repo Filter Pipeline"
echo " Input:      $INPUT"
echo " Output dir: $OUT"
echo "========================================"
echo ""

# ---------------------------------------------------------------------------
echo "--- Step 1: Drop forks / archived / disabled ---"
python3 "$SCRIPTS/filter_01_forks.py" \
    --input  "$INPUT" \
    --output "$OUT/step1_nonforks.jsonl"

echo ""
# ---------------------------------------------------------------------------
echo "--- Step 2: Drop pre-Lean 4 (lean-toolchain fetch) ---"
python3 "$SCRIPTS/filter_02_lean4.py" \
    --input      "$OUT/step1_nonforks.jsonl" \
    --output     "$OUT/step2_lean4.jsonl" \
    --checkpoint "$OUT/checkpoints/lean4_check.json" \
    --workers    8

echo ""
# ---------------------------------------------------------------------------
echo "--- Step 3: Drop noise (metadata only) ---"
python3 "$SCRIPTS/filter_03_noise.py" \
    --input    "$OUT/step2_lean4.jsonl" \
    --output   "$OUT/step3_denoised.jsonl"

echo ""
# ---------------------------------------------------------------------------
# echo "--- Step 4: Deduplicate via lakefile hash ---"
# python3 "$SCRIPTS/filter_04_dedup.py" \
#     --input      "$OUT/step3_denoised.jsonl" \
#     --output     "$OUT/step4_deduped.jsonl" \
#     --checkpoint "$OUT/checkpoints/lakefile_cache.json" \
#     --workers    8

echo "--- Step 5: Clone + structure-fingerprint dedup + save sources ---"
echo "    (Step 4 lakefile-hash dedup has been removed)"
echo "    Workers: 32  (cloning is I/O-bound, high concurrency is fine)"
python3 "$SCRIPTS/filter_05_git.py" \
    --input          "$OUT/step3_denoised.jsonl" \
    --output         "$OUT/step5_corpus.jsonl" \
    --checkpoint     "$OUT/checkpoints/collect_results.json" \
    --corpus-dir     "$OUT/lean_corpus" \
    --workers        32 \
    --min-lean-files 1 \
    --min-lines      10

    
echo ""
echo "========================================"
echo " Pipeline complete!"
echo " Final output: $OUT/step5_corpus.jsonl"
echo ""
echo " Repo counts per step:"
for f in "$OUT"/step*.jsonl; do
    printf "  %-35s %s\n" "$(basename "$f")" "$(wc -l < "$f") repos"
done
echo "========================================"
