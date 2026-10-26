#!/usr/bin/env bash
# Evaluate a run's accepted rules on the demo-thirteen share (58 CARLA cases in 13 cells, each
# labelled for one target law) and score the verdicts against the labels. The cases ship no
# manifest: lib/demo13_manifest.json declares what their exporter observes. Each case is
# prepared, monitored and its prepared trace deleted before the next starts, so the work
# directory never holds a copy of the dataset.
#
#   RUN=smoke20 bash pipeline/evaluation/eval_demo13.sh
#   RUN=smoke20 FILL=1 bash pipeline/evaluation/eval_demo13.sh
#
# Settings: PIPELINE, RUN, RULES, CASES, WORK (see lib/common.sh), and
#   DATASET  the share's root (default ../datasets/demo-thirteen-latest-share-20261010)
#   FILL     1 = the assumption-based sensitivity run: no ice or snow, visibility VISIBILITY_M,
#            LANE_WIDTH_M for a lane with no width, the ego's engine running, and the ego's turn
#            indicator read `off` where the exporter wrote none (it writes the indicator only while
#            lit); these are not recovered measurements. Default 0, the cases as shipped.
#   JOBS     cases monitored at once (default 8; a monitor holds up to ~3 GB)
#   KEEP     1 = keep the prepared traces (default 0)
# Writes only under $WORK: reports/<case>.jsonl, cases/<case>/{manifest,conversion}.json, score.tsv.
EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATASET="${DATASET:-$(cd "$EVAL_DIR/../datasets/demo-thirteen-latest-share-20261010" && pwd)}"
DATA="$DATASET"
CASES="${CASES:-$(python3 -c 'import csv,sys; print(" ".join(r["case_id"] for r in csv.DictReader(open(sys.argv[1]))))' "$DATASET/cases.csv")}"
source "$EVAL_DIR/lib/common.sh"
FILL="${FILL:-0}"
JOBS="${JOBS:-8}"
KEEP="${KEEP:-0}"
VISIBILITY_M="${VISIBILITY_M:-10000}"
LANE_WIDTH_M="${LANE_WIDTH_M:-3.5}"
FILL_ARGS=()
SUFFIX=""
if [ "$FILL" = 1 ]; then
  FILL_ARGS=(--fill --visibility "$VISIBILITY_M" --lane-width "$LANE_WIDTH_M" --engine --indicator-off)
  SUFFIX=_filled
fi
WORK="${WORK:-/tmp/eval_demo13_$RUN$SUFFIX}"

case_dir() {
  python3 -c 'import csv,os,sys; print(next(os.path.dirname(r["lean_trace"]) for r in csv.DictReader(open(sys.argv[1])) if r["case_id"] == sys.argv[2]))' \
      "$DATASET/cases.csv" "$1"
}

# One case: prepare, monitor, drop the prepared trace. A failure is reported and the others go on.
run_case() {
  local c="$1" t0=$SECONDS
  if ! python3 "$EVAL_DIR/lib/prepare_cases.py" "$DATASET/$(case_dir "$c")" "$WORK/cases/$c" \
         --manifest "$EVAL_DIR/lib/demo13_manifest.json" --library "$WORK/lib" "${FILL_ARGS[@]}"; then
    echo "   $c: preparation failed" >&2; return 0
  fi
  monitor_json "$c" || echo "   $c: monitor failed: $(tail -1 "$WORK/reports/$c.err")" >&2
  [ "$KEEP" = 1 ] || rm -f "$WORK/cases/$c/trace.json"
  echo "   $c: monitored in $((SECONDS - t0)) s"
}

build_monitor
rm -rf "$WORK/reports" "$WORK/cases"
echo "== cases $([ "$FILL" = 1 ] && echo 'with weather, lane width, engine state and an unwritten indicator read off' || echo 'as shipped'), $JOBS at a time"
for c in $CASES; do
  while [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; do wait -n || true; done
  run_case "$c" &
done
wait
echo "== verdicts against the labels (also in $WORK/score.tsv)"
python3 "$EVAL_DIR/lib/score_labels.py" "$DATASET/cases.csv" "$WORK/reports" "$WORK/registered.json" | tee "$WORK/score.tsv"
