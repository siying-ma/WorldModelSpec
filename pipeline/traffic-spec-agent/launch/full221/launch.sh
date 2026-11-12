#!/usr/bin/env bash
# Start the 221-law run: the generation stage only, over every law of the training split, from a fresh clone of
# remote/full-train-generation at its tip. It first runs launch/full221/preflight.sh (nothing is spent unless every
# check passes), then starts the launcher in the background and returns. The run's settings are written below and
# kept by every resume; none is taken from the shell.
# Run from pipeline/traffic-spec-agent:  bash launch/full221/launch.sh      (RUN_ID may be set; default full221-<MMDD-HHMM>)
set -euo pipefail
export RUN_ID=${RUN_ID:-full221-$(date +%m%d-%H%M)}

# ---------------------------------------------------------------- the run's settings
export LAWS=laws/example/train/laws.jsonl            # all 221 training laws
export ONTOLOGY=ontology/ATOMS_train.md READING=library/TrafficSpec/Readings/lasvegas.json
export ACQUISITION_PROFILE=carla_scene_graph STAGE=generation
export WORKERS=12 PLAN_BATCH=8 GATE_BUDGET=6       # 12 Claude sessions at once
export MODEL='claude-opus-5-5[1m]' PLAN_EFFORT=high CODE_EFFORT=high JUDGE_EFFORT=medium         # planning, coding, judging
export REVIEWER_MODEL=gpt-6.1-sol REVIEW_EFFORT=high                                               # concept reviewer
export VERIFIER_MODEL=gpt-6.1-sol VERIFIER_EFFORT=high                                             # aggregate verifier
export CLAUDE_BUDGET=1500 OPENAI_BUDGET=30 TOTAL_BUDGET=1530 VERIFIER_CAP=20                       # run-wide limits, USD
export SESSION_CAP=20 REPAIR_CAP=8 JUDGE_CAP=2      # per-session Claude limits, USD
export LAUNCHES=1                                    # the first invocation: one iteration, then resume.sh

set +e                                               # a failed preflight is a refusal (exit 2), not an error
bash launch/full221/preflight.sh 2>&1 | tee "preflight-$RUN_ID.txt"; PRE=${PIPESTATUS[0]}
set -e
[ "$PRE" -eq 0 ] || { echo "preflight failed: nothing was started (send preflight-$RUN_ID.txt)" >&2; exit 2; }
source launch/full221/detach.sh
echo "run $RUN_ID at $(git rev-parse --short HEAD): Claude \$$CLAUDE_BUDGET, OpenAI \$$OPENAI_BUDGET, total \$$TOTAL_BUDGET, verifier \$$VERIFIER_CAP, $WORKERS workers"
start_detached new "launch-$RUN_ID"
