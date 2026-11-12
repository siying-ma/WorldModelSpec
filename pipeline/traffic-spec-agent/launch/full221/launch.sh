#!/usr/bin/env bash
# Launch the 221-law gap-discovery run: the generation stage only (the run's first stage, G0, which the launcher
# opens itself), over every law of the training split, from this clean checkout of remote/full-train-generation
# at the commit the requester named. It records which laws generate, which gaps are filed, which laws a gap
# blocks or a dependency holds, and the failure paths. It ends normally at `awaiting_labels`.
# Run from pipeline/traffic-spec-agent, after launch/full221/preflight.sh passed:
#   RUN_ID=<run id> EXPECTED_BASELINE=<commit> CLAUDE_BUDGET=<usd> OPENAI_BUDGET=<usd> TOTAL_BUDGET=<usd> VERIFIER_CAP=<usd> \
#     bash launch/full221/launch.sh
# There is no default run budget: the four limits are the requester's, given explicitly. A limit reached
# is reported, never raised by the operator. A Claude session may exceed its reserved cap by one turn.
# The first invocation allows one launch of the loop (LAUNCHES=1),
# so that a resume is rehearsed; what to do after each exit is in launch/full221/README.md.
# The account and the exit status: see launch/full221/detach.sh.
set -euo pipefail
die() { echo "refusing: $*" >&2; exit 2; }
RUN_ID=${RUN_ID:?set RUN_ID to the run id (full221-<MMDD-HHMM>, the same one preflight.sh checked)}
EXPECTED_BASELINE=${EXPECTED_BASELINE:?set EXPECTED_BASELINE to the baseline commit the requester named}
for v in CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET VERIFIER_CAP; do
  [ -n "${!v:-}" ] || die "$v is not set: the requester gives CLAUDE_BUDGET, OPENAI_BUDGET, TOTAL_BUDGET and VERIFIER_CAP (USD); there is no default"
  [[ ${!v} =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "$v must be an amount in USD (given '${!v}')"
done
[ "$(git rev-parse HEAD)" = "$EXPECTED_BASELINE" ] || die "this checkout is at $(git rev-parse HEAD), not EXPECTED_BASELINE $EXPECTED_BASELINE"
source launch/full221/detach.sh

# No law subset: the whole training split. Settings fixed for the run; a resume keeps them.
# Start at smoke32's tested concurrency. More laws lengthen the queue, not the safe per-account rate.
export RUN_ID LAWS=laws/example/train/laws.jsonl STAGE=generation MODEL='claude-opus-5-5[1m]' REVIEWER_MODEL=gpt-6.1-sol \
       JUDGE_EFFORT=medium ACQUISITION_PROFILE=carla_scene_graph WORKERS=12 LAUNCHES=1 \
       CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET VERIFIER_CAP
echo "run $RUN_ID on $EXPECTED_BASELINE; admission limits: Claude \$$CLAUDE_BUDGET, OpenAI \$$OPENAI_BUDGET, total \$$TOTAL_BUDGET, verifier \$$VERIFIER_CAP"
echo "per-session caps: ${SESSION_CAP:-launcher default} / ${REPAIR_CAP:-launcher default} / ${JUDGE_CAP:-launcher default}"
start_detached new "launch-$RUN_ID"
