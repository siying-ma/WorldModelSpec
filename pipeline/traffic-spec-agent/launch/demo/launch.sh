#!/usr/bin/env bash
# Launch the demo generation run: the 22 demo laws, from this checkout of remote/full-train-generation.
# Run from pipeline/traffic-spec-agent:  bash launch/demo/launch.sh   (RUN_ID may be set; it defaults to demo22-<date>)
# The claude CLI bills the account it is logged in to; ANTHROPIC_API_KEY is cleared so it cannot bill a key.
set -euo pipefail
RUN_ID=${RUN_ID:-demo22-$(date +%m%d-%H%M)}
unset ANTHROPIC_API_KEY
export PYTHONDONTWRITEBYTECODE=1        # a doctor import must not rewrite a tracked cache and dirty the checkout

python -m scripts.subset_laws "$RUN_ID" laws/example/train/laws.jsonl \
  NRS-484A-450-2 NRS-484B-113-2 NRS-484B-127-1 NRS-484B-127-2 NRS-484B-127-3 NRS-484B-220-1 \
  NRS-484B-223-1b NRS-484B-227-1 NRS-484B-250-1 NRS-484B-250-2 NRS-484B-250-4 NRS-484B-253 \
  NRS-484B-257-1 NRS-484B-257-2 NRS-484B-307-6a NRS-484B-400-2a NRS-484B-400-2b NRS-484B-407 \
  NRS-484B-413-2 NRS-484B-600-1a NRS-484B-600-1c NRS-484B-600-1e

# Settings of the demo (2026-11-09): 22 laws, about $220 of Claude and $1 of OpenAI in the first demo.
env RUN_ID="$RUN_ID" LAWS="results/$RUN_ID/laws/laws.jsonl" \
    MODEL='claude-opus-5-5[1m]' REVIEWER_MODEL=gpt-6.1-sol JUDGE_EFFORT=medium \
    ACQUISITION_PROFILE=carla_scene_graph WORKERS=12 \
    CLAUDE_BUDGET=350 OPENAI_BUDGET=25 TOTAL_BUDGET=375 \
  nohup scripts/run-generation.sh new > "launch-$RUN_ID.out" 2>&1 < /dev/null &
echo "launched $RUN_ID (pid $!); log: launch-$RUN_ID.out and .runtime/$RUN_ID/launcher.log"
