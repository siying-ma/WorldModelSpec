#!/usr/bin/env bash
# Launch smoke31: the 29 training laws of smoke30, from this checkout of remote/full-train-generation, on the
# pipeline fixed after smoke30. It is the rehearsal of the full run: the same launcher, settings and checkpoints, on 9 demo laws, 10 laws in cross-law
# dependency chains and 10 laws of themes the demo does not cover.
# Run from pipeline/traffic-spec-agent:  bash launch/smoke31/launch.sh   (RUN_ID may be set; it defaults to smoke31-<date>)
# The first invocation allows one launch of the loop (LAUNCHES=1), so that a resume is rehearsed. It usually
# ends at an iteration-limit checkpoint, but a budget pause, an error or an early end may come first: what to
# do after each exit is in launch/smoke31/README.md.
# The account and the exit status: see launch/smoke31/detach.sh.
set -euo pipefail
RUN_ID=${RUN_ID:-smoke31-$(date +%m%d-%H%M)}
source launch/smoke31/detach.sh

python -m scripts.subset_laws "$RUN_ID" laws/example/train/laws.jsonl \
  NRS-484B-413-2 NRS-484B-113-2 NRS-484B-127-3 NRS-484B-253 NRS-484B-227-1 NRS-484B-257-1 \
  NRS-484B-250-1 NRS-484B-250-4 NRS-484B-600-1a \
  NRS-484B-270-4 NRS-484B-270-3 NRS-484B-297-6 NRS-484B-307-9a NRS-484B-307-9b \
  NRS-484D-215-1 NRS-484D-100-1 NRS-484B-400-1 NRS-484B-223-4a NRS-484B-223-4b \
  NRS-484B-440-1 NRS-484B-450-1c NRS-484B-769 NRS-484B-270-7b NRS-484B-363-3 \
  NRS-484B-560-7a LVMC-11-43-010-A NRS-484B-210-3 LVMC-11-38-030 NRS-484B-263

# Budget for the whole smoke: Claude $400, OpenAI $25, total $425.
export RUN_ID="$RUN_ID" LAWS="results/$RUN_ID/laws/laws.jsonl" MODEL='claude-opus-5-5[1m]' REVIEWER_MODEL=gpt-6.1-sol \
       JUDGE_EFFORT=medium ACQUISITION_PROFILE=carla_scene_graph WORKERS=12 LAUNCHES=1 \
       CLAUDE_BUDGET=400 OPENAI_BUDGET=25 TOTAL_BUDGET=425
start_detached new "launch-$RUN_ID"
