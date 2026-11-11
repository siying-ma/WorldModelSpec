#!/usr/bin/env bash
# Resume the smoke31 run from this checkout of its run branch runs/<run id>, only
# when its last exit allows it (see launch/smoke31/README.md).
# Run from pipeline/traffic-spec-agent:  RUN_ID=<run id> bash launch/smoke31/resume.sh
# LAUNCHES (default 20) bounds this invocation's launches of the loop. Every other setting is the run's saved
# one; a budget is raised only with the limits the requester gives (CLAUDE_BUDGET or OPENAI_BUDGET, with
# TOTAL_BUDGET). The account and the exit status: see launch/smoke31/detach.sh.
set -euo pipefail
RUN_ID=${RUN_ID:?set RUN_ID to the run id}
source launch/smoke31/detach.sh
export RUN_ID LAUNCHES=${LAUNCHES:-20}
start_detached resume "resume-$RUN_ID-$(date +%m%d-%H%M)"
