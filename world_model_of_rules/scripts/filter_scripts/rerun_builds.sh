#!/usr/bin/env bash
# rerun_builds.sh — Free disk space, then retry failed and unbuilt repos.
#
# Problems this script fixes:
#   1. ~/.elan/tmp/ accumulates stale partial toolchain downloads (can be GBs).
#   2. ~/.elan/toolchains/*.tmp are incomplete installs from previous crashes.
#   3. ~/.cache/mathlib/ (30 GB) lives on the small home filesystem.
#      → mathlib .olean cache and elan toolchains are redirected to --cache-home
#        (a large filesystem like /local-scratch3) via XDG_CACHE_HOME + ELAN_HOME.
#   4. Repos with build_failed in the checkpoint are retried (--retry-failed).
#
# Example:
#  bash scripts/filter_scripts/rerun_builds.sh projects/filter_repo /local-scratch3/sma407/.cache
#
# The script preserves all previous build_success entries in the checkpoint.

set -euo pipefail

OUT="${1:-pipeline_output}"
SCRIPTS="$(cd "$(dirname "$0")" && pwd)"
CACHE_HOME="${2:-/local-scratch3/$(whoami)/.cache}"
ELAN_HOME="${ELAN_HOME:-$HOME/.elan}"

echo "========================================"
echo " Lean Build Rerun"
echo " Output dir:  $OUT"
echo " Cache home:  $CACHE_HOME"
echo " ELAN_HOME:   $ELAN_HOME"
echo "========================================"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Free disk space on the home filesystem
# ---------------------------------------------------------------------------
echo "--- Freeing disk space ---"

# 1a. Remove stale partial elan downloads (these can be several GB)
ELAN_TMP="$ELAN_HOME/tmp"
if [ -d "$ELAN_TMP" ]; then
    SIZE=$(du -sh "$ELAN_TMP" 2>/dev/null | cut -f1)
    echo "  Clearing $ELAN_TMP  ($SIZE)"
    rm -rf "${ELAN_TMP:?}"/*
fi

# 1b. Remove incomplete toolchain installs (*.tmp directories)
ELAN_TC="$ELAN_HOME/toolchains"
if [ -d "$ELAN_TC" ]; then
    for d in "$ELAN_TC"/*.tmp; do
        [ -d "$d" ] || continue
        echo "  Removing incomplete toolchain: $(basename "$d")"
        rm -rf "$d"
    done
fi

# 1c. Move the mathlib .olean cache to the large filesystem (if still on home)
MATHLIB_CACHE_HOME="$HOME/.cache/mathlib"
MATHLIB_CACHE_SCRATCH="$CACHE_HOME/mathlib"
if [ -d "$MATHLIB_CACHE_HOME" ] && [ ! -L "$MATHLIB_CACHE_HOME" ]; then
    SIZE=$(du -sh "$MATHLIB_CACHE_HOME" 2>/dev/null | cut -f1)
    echo "  Moving mathlib cache ($SIZE) from $MATHLIB_CACHE_HOME → $MATHLIB_CACHE_SCRATCH"
    mkdir -p "$(dirname "$MATHLIB_CACHE_SCRATCH")"
    mv "$MATHLIB_CACHE_HOME" "$MATHLIB_CACHE_SCRATCH"
    ln -s "$MATHLIB_CACHE_SCRATCH" "$MATHLIB_CACHE_HOME"
    echo "  Symlinked $MATHLIB_CACHE_HOME → $MATHLIB_CACHE_SCRATCH"
elif [ -L "$MATHLIB_CACHE_HOME" ]; then
    echo "  Mathlib cache already symlinked: $MATHLIB_CACHE_HOME → $(readlink "$MATHLIB_CACHE_HOME")"
else
    echo "  Mathlib cache not found at $MATHLIB_CACHE_HOME (will be created at $MATHLIB_CACHE_SCRATCH)"
fi

df -h "$HOME" "$CACHE_HOME" 2>/dev/null | awk 'NR==1 || NR>1' || true
echo ""

# ---------------------------------------------------------------------------
# Step 1d: Initialize elan default in the new ELAN_HOME.
#
# When ELAN_HOME is redirected to a fresh directory the default toolchain is
# not yet configured there.  Repos without a lean-toolchain file rely on this
# fallback.  Without it elan crashes with "no default toolchain configured."
# ---------------------------------------------------------------------------
NEW_ELAN_HOME="$CACHE_HOME/.elan"
export XDG_CACHE_HOME="$CACHE_HOME"
export ELAN_HOME="$NEW_ELAN_HOME"
mkdir -p "$NEW_ELAN_HOME"
if [ ! -f "$NEW_ELAN_HOME/elan-config.toml" ]; then
    echo "--- Initializing elan default in $NEW_ELAN_HOME ---"
    elan default leanprover/lean4:stable
    echo ""
else
    echo "--- elan default already configured in $NEW_ELAN_HOME ---"
    echo ""
fi

# ---------------------------------------------------------------------------
# Step 2: Run filter_05_build.py with --retry-failed
# ---------------------------------------------------------------------------
mkdir -p "$OUT/checkpoints" "$OUT/build_logs"

# Log file: all output tee'd here for later inspection.
LOG_FILE="$OUT/rerun_builds_$(date +%Y%m%d_%H%M%S).log"
echo "--- Saving build log to $LOG_FILE ---"
echo ""


python3 "$SCRIPTS/filter_05_build.py" \
    --input              "$OUT/step4_deduped.jsonl" \
    --output             "$OUT/step5_builds.jsonl" \
    --checkpoint         "$OUT/checkpoints/build_results.json" \
    --workers            10 \
    --jobs-per-build     4 \
    --timeout            1800 \
    --log-dir            "$OUT/build_logs" \
    --keep-dir           "$OUT/built_repos" \
    --cache-home         "$CACHE_HOME" \
    --retry-failed \
    --toolchain-cleanup-every 10 \
    2>&1 | tee -a "$LOG_FILE"

echo ""
echo "========================================"
echo " Done!"
echo " Output:      $OUT/step5_builds.jsonl"
echo " Built repos: $OUT/built_repos/"
NBUILT=$(wc -l < "$OUT/step5_builds.jsonl" 2>/dev/null || echo "?")
echo " Kept (builds): $NBUILT"
echo " Run log:     $LOG_FILE"
echo "========================================"
