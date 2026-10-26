# Shared steps of the evaluation scripts; sourced, not run.
#
# Settings (environment variables, all optional):
#   PIPELINE  the traffic-spec-agent tree whose run is evaluated (default: the one beside this folder;
#             point it at a worktree to evaluate a branch's run)
#   RUN       the run under $PIPELINE/results whose accepted rules and reading are used (default carla_smoke7,
#             the run the library holds); a run archived by `init --fresh --snapshot` is read from its
#             library_snapshot
#   RULES     comma-separated node ids to evaluate (default: every rule the run accepted)
#   DATA      the dataset's case directory (default: carla_new's)
#   CASES     space-separated case ids (default: every case of $DATA)
#   WORK      scratch directory (default /tmp/eval_<script>_<RUN>)
set -euo pipefail
EVAL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIPELINE="${PIPELINE:-$(cd "$EVAL_DIR/../traffic-spec-agent" && pwd)}"
DATA="${DATA:-$(cd "$EVAL_DIR/../datasets/carla_new/cases" && pwd)}"
RUN="${RUN:-carla_smoke7}"
RULES="${RULES:-}"
CASES="${CASES:-$(ls "$DATA")}"
RUN_DIR="$PIPELINE/results/$RUN"
READING="$RUN_DIR/reading.json"
[ -f "$READING" ] || { echo "no run $RUN under $PIPELINE/results (no reading.json)" >&2; exit 1; }

# carla_new's adapter writes `left` in every scene of every case, whatever the light state.
CARLA_NEW_INDICATOR_MASK="sig.turn_indicator=legacy exporter emits constant left"

# A copy of the library with the full split active and only the run's accepted rules registered:
# the monitor needs the full Core, and a rule still being coded must not enter the build.
build_monitor() {
  echo "== monitor for run $RUN ($PIPELINE), in $WORK/lib"
  rm -rf "$WORK/lib" && mkdir -p "$WORK" && cp -a "$PIPELINE/library" "$WORK/lib"
  cp -a "$WORK/lib/splits/full/TrafficSpec/." "$WORK/lib/TrafficSpec/" && echo full > "$WORK/lib/splits/ACTIVE"
  if [ -d "$RUN_DIR/library_snapshot" ]; then          # an archived run: its own rule and concept files
    cp -a "$RUN_DIR/library_snapshot/." "$WORK/lib/"
  fi
  python3 "$EVAL_DIR/lib/register_accepted.py" "$WORK/lib" "$RUN_DIR" "$PIPELINE"
  (cd "$WORK/lib" && lake build monitor 2>&1 | tail -1)
}

# The monitor on every prepared case; the verdict lines only (times in ms from the trace's start).
run_monitor() {
  echo "== verdicts (GROUND: the case; TL: a stretch of time with one verdict; UNK: what was missing)"
  for c in $CASES; do
    echo "-- $c"
    "$WORK/lib/.lake/build/bin/monitor" ${RULES:+--rules "$RULES"} \
        --manifest "$WORK/cases/$c/manifest.json" --reading "$READING" \
        "$WORK/cases/$c/trace.json" 2>&1 | grep -E '^(GROUND|TL|UNK)' || echo "   (no verdict lines: run the monitor by hand to see why)"
  done
}

# The monitor on one prepared case, as JSON lines in $WORK/reports/<case>.jsonl (stderr beside it);
# fails on a decode error.
monitor_json() {
  local c="$1"
  mkdir -p "$WORK/reports"
  "$WORK/lib/.lake/build/bin/monitor" ${RULES:+--rules "$RULES"} --json \
      --manifest "$WORK/cases/$c/manifest.json" --reading "$READING" \
      "$WORK/cases/$c/trace.json" > "$WORK/reports/$c.jsonl" 2> "$WORK/reports/$c.err"
}
