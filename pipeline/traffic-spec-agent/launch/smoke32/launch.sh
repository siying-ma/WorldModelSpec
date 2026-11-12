#!/usr/bin/env bash
# Launch smoke32: 15 training laws, from this checkout of remote/full-train-generation. It checks the
# pipeline fixed after smoke31 before the full gap-discovery run: a node carrying a planned gap is filed and
# blocks its law (440-1, 297-6, 307-9b); a concept read only through past-time operators can pass its blind
# witness (250-1 with its provider 250-4, 253, 257-1, 307-9a); the definitions a corpus text cites from other chapters reach the
# aggregates (280-1a, 113-3, LVMC 11.30.030, 117-1); and three laws that were sound stay sound (600-1a, 413-2,
# 227-1). Its acceptance count is a diagnostic, not a result.
# Run from pipeline/traffic-spec-agent:  bash launch/smoke32/launch.sh   (RUN_ID may be set; it defaults to smoke32-<date>)
# The first invocation allows one launch of the loop (LAUNCHES=1), so that a resume is rehearsed. It usually
# ends at an iteration-limit checkpoint, but a budget pause, an error or an early end may come first: what to
# do after each exit is in launch/smoke32/README.md.
# The account and the exit status: see launch/smoke32/detach.sh.
set -euo pipefail
RUN_ID=${RUN_ID:-smoke32-$(date +%m%d-%H%M)}
source launch/smoke32/detach.sh

python -m scripts.subset_laws "$RUN_ID" laws/example/train/laws.jsonl \
  NRS-484B-440-1 NRS-484B-297-6 NRS-484B-307-9b \
  NRS-484B-250-1 NRS-484B-250-4 NRS-484B-253 NRS-484B-257-1 NRS-484B-307-9a \
  NRS-484B-280-1a NRS-484B-113-3 LVMC-11-30-030 NRS-484B-117-1 \
  NRS-484B-600-1a NRS-484B-413-2 NRS-484B-227-1

# Hard limits for the whole smoke: Claude $150, OpenAI $10, total $160. A limit reached is reported with what is
# unfinished; it is never raised to finish, and no law is swapped in.
export RUN_ID="$RUN_ID" LAWS="results/$RUN_ID/laws/laws.jsonl" MODEL='claude-opus-5-5[1m]' REVIEWER_MODEL=gpt-6.1-sol \
       JUDGE_EFFORT=medium ACQUISITION_PROFILE=carla_scene_graph WORKERS=12 LAUNCHES=1 \
       CLAUDE_BUDGET=150 OPENAI_BUDGET=10 TOTAL_BUDGET=160
start_detached new "launch-$RUN_ID"
