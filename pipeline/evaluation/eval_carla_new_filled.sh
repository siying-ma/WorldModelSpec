#!/usr/bin/env bash
# Evaluate a run's accepted rules on carla_new with the facts CARLA knows but the adapter does not
# export filled in: no ice or snow, clear air, a lane width where a lane has none, and (by default)
# the ego's engine running. The filled values are assumptions about the simulation, not measurements.
#
#   bash pipeline/evaluation/eval_carla_new_filled.sh
#   RUN=carla_smoke6 bash pipeline/evaluation/eval_carla_new_filled.sh
#
# Settings: PIPELINE, RUN, RULES, CASES, WORK (see lib/common.sh), and
#   VISIBILITY_M  visibility distance written into every scene (default 10000)
#   LANE_WIDTH_M  width given to a lane that has none (default 3.5); measured widths are kept
#   FILL_ENGINE   1 = report the ego's engine running (default 1); 0 = leave it unobserved
# Writes only under $WORK.
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
WORK="${WORK:-/tmp/eval_carla_new_filled_$RUN}"
VISIBILITY_M="${VISIBILITY_M:-10000}"
LANE_WIDTH_M="${LANE_WIDTH_M:-3.5}"
FILL_ENGINE="${FILL_ENGINE:-1}"

build_monitor
echo "== cases with weather, lane width$([ "$FILL_ENGINE" = 1 ] && echo ' and engine state') filled"
for c in $CASES; do
  python3 "$EVAL_DIR/lib/prepare_cases.py" "$DATA/$c" "$WORK/cases/$c" --fill \
      --visibility "$VISIBILITY_M" --lane-width "$LANE_WIDTH_M" $([ "$FILL_ENGINE" = 1 ] && echo --engine)
done
run_monitor
