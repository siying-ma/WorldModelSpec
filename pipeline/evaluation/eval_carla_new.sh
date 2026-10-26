#!/usr/bin/env bash
# Evaluate a run's accepted rules on carla_new as the dataset ships it (only the retired animal class
# spelling is mapped, so the traces decode). Facts the adapter does not export stay unobserved, and
# the rules report unknown where they need them.
#
#   bash pipeline/evaluation/eval_carla_new.sh
#   RUN=carla_smoke6 bash pipeline/evaluation/eval_carla_new.sh
#
# Settings: PIPELINE, RUN, RULES, CASES, WORK (see lib/common.sh). Writes only under $WORK.
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
WORK="${WORK:-/tmp/eval_carla_new_$RUN}"

build_monitor
echo "== cases as shipped"
for c in $CASES; do python3 "$EVAL_DIR/lib/prepare_cases.py" "$DATA/$c" "$WORK/cases/$c" --mask "$CARLA_NEW_INDICATOR_MASK"; done
run_monitor
