#!/usr/bin/env bash
# Resume the smoke32 run from this checkout of its run branch runs/<run id>, only
# when its last exit allows it (see launch/smoke32/README.md).
# Run from pipeline/traffic-spec-agent:  RUN_ID=<run id> bash launch/smoke32/resume.sh
# LAUNCHES (default 20) bounds this invocation's launches of the loop. Every other setting is the run's saved
# one; the budget limits of this smoke are hard and never raised. The account and the exit status: see
# launch/smoke32/detach.sh.
set -euo pipefail
RUN_ID=${RUN_ID:?set RUN_ID to the run id}
source launch/smoke32/detach.sh
export RUN_ID LAUNCHES=${LAUNCHES:-20}
start_detached resume "resume-$RUN_ID-$(date +%m%d-%H%M)"
