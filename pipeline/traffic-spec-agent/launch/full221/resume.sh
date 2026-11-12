#!/usr/bin/env bash
# Resume the full221 run from the checkout that started it (on its run branch runs/<run id>), only when its last
# exit allows it (see the repository's README).
# Run from pipeline/traffic-spec-agent:  RUN_ID=<run id> LAUNCHES=<n> bash launch/full221/resume.sh
# LAUNCHES (default 30) bounds this invocation's launches of the loop. Every other setting is the run's saved one:
# a budget, a model, the stage or the laws given here is refused, since the run's limits are hard and its stage
# is generation. WORKERS may be lowered, only on the requester's word. The account and the exit status: see
# launch/full221/detach.sh.
set -euo pipefail
RUN_ID=${RUN_ID:?set RUN_ID to the run id}
if [ -n "${WORKERS+x}" ]; then
  PYTHON=${PYTHON:-python}
  "$PYTHON" - "$RUN_ID" "$WORKERS" <<'PY' || { echo "refusing: WORKERS may only be lowered from the saved value" >&2; exit 2; }
import json, sys
from pathlib import Path
try:
    saved = int(json.loads((Path('results') / sys.argv[1] / 'options.json').read_text())['workers'])
    requested = int(sys.argv[2])
except (OSError, ValueError, KeyError, TypeError):
    raise SystemExit(1)
if requested < 1 or requested > saved:
    raise SystemExit(1)
PY
fi
for v in CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET SESSION_CAP REPAIR_CAP JUDGE_CAP VERIFIER_CAP LAWS ONTOLOGY READING \
         MODEL REVIEWER_MODEL VERIFIER_MODEL PLAN_EFFORT CODE_EFFORT REVIEW_EFFORT JUDGE_EFFORT VERIFIER_EFFORT \
         ACQUISITION_PROFILE LABEL_DATASET LABEL_REPAIR_ATTEMPTS LABEL_REPAIR_BUDGET NEW_BASE KIND FROM TRANSITION; do
  [ -z "${!v+x}" ] || { echo "refusing: $v is set in this shell; a resume of this run keeps its saved settings (unset $v)" >&2; exit 2; }
done
[ "${STAGE:-generation}" = generation ] || { echo "refusing: this run is a generation-stage run; STAGE=$STAGE is never launched by the operator" >&2; exit 2; }
source launch/full221/detach.sh
export RUN_ID STAGE=generation LAUNCHES=${LAUNCHES:-30}
start_detached resume "resume-$RUN_ID-$(date +%m%d-%H%M)"
