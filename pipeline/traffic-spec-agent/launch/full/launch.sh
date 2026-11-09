#!/usr/bin/env bash
# Launch the full generation run: every law of the training split (221 laws), from this checkout of
# remote/full-train-generation.
# Run from pipeline/traffic-spec-agent:  bash launch/full/launch.sh   (RUN_ID may be set; it defaults to fulltrain-<date>)
# The claude CLI bills the account it is logged in to; ANTHROPIC_API_KEY is cleared so it cannot bill a key.
#
# Budget. The first demo spent about $10 of Claude per law over its generation, so the whole split is
# estimated at $2,000-2,500 of Claude and about $10 of OpenAI. That is more than one Claude seat's weekly
# allowance (about $1.4-1.5k of API-equivalent use), so the Claude limit below is set for one week. When
# it is reached the run stops at a pushed checkpoint with exit status 4 (`paused_budget`). Next week the
# requester raises the limit explicitly and the run resumes:
#   RUN_ID=<run id> CLAUDE_BUDGET=<new limit> TOTAL_BUDGET=<new limit + OPENAI_BUDGET> scripts/run-generation.sh resume
set -euo pipefail
RUN_ID=${RUN_ID:-fulltrain-$(date +%m%d-%H%M)}
unset ANTHROPIC_API_KEY
export PYTHONDONTWRITEBYTECODE=1        # a doctor import must not rewrite a tracked cache and dirty the checkout

# No law subset: LAWS defaults to the training split, laws/example/train/laws.jsonl.
env RUN_ID="$RUN_ID" \
    MODEL='claude-opus-5[1m]' REVIEWER_MODEL=gpt-6.1-sol JUDGE_EFFORT=medium \
    ACQUISITION_PROFILE=carla_scene_graph WORKERS=12 LAUNCHES=40 \
    CLAUDE_BUDGET=1300 OPENAI_BUDGET=40 TOTAL_BUDGET=1340 \
  nohup scripts/run-generation.sh new > "launch-$RUN_ID.out" 2>&1 < /dev/null &
echo "launched $RUN_ID (pid $!); log: launch-$RUN_ID.out and .runtime/$RUN_ID/launcher.log"
