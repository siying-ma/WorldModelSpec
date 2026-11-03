#!/usr/bin/env bash
# Tests of the explain program and its use by the verifier, on a delivered package (default:
# ../../verifier/smoke25).
#
#   tests/run_tests.sh            # Lean checks, then the Python checks
#
# The delivered package is never written: it is copied to $WORK/pkg and built there (seeded with
# $LAKE_CACHE when that holds an earlier build). The Lean checks build `ExplainTest.lean` in
# $WORK/lean: the shipped `Explain.lean` with its `main` renamed and `explain_test_body.lean`
# appended, so they call the shipped functions, with the packaged rules' witness files copied from
# the pipeline run's library snapshot. The Python checks run the copy's own `explain` binary and
# `verify` API on recorded cases ($CASES).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
TOOLS="$(dirname "$HERE")"
EVAL="$(dirname "$TOOLS")"
DELIVERED="${DELIVERED:-$EVAL/verifier/smoke25}"
PIPELINE="${PIPELINE:-$(cd "$EVAL/../traffic-spec-agent" && pwd)}"
RUN="${RUN:-$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['run'])" "$DELIVERED/PROVENANCE.json")}"
WORK="${WORK:-/local-scratch2/sma407/scratch_recorded/explain_test}"
LAKE_CACHE="${LAKE_CACHE:-/local-scratch2/sma407/scratch_recorded/verifier_build_cache/lake}"
export CASES="${CASES:-/local-scratch2/sma407/scratch_recorded/data}"

echo "== copy the delivered package $DELIVERED to $WORK/pkg and build it there"
rm -rf "$WORK"; mkdir -p "$WORK"
cp -a "$DELIVERED" "$WORK/pkg"
[ -d "$LAKE_CACHE" ] && cp -a "$LAKE_CACHE" "$WORK/pkg/lean/.lake"
(cd "$WORK/pkg/lean" && lake build explain monitor 2>&1 | tail -1)
PKG="$WORK/pkg"

echo "== Lean checks in $WORK/lean"
cp -a "$PKG/lean" "$WORK/lean"
SNAP="$PIPELINE/results/$RUN/library_snapshot/TrafficSpecWitness"
for rule in $(python3 -c "import json,sys;print(' '.join(json.load(open(sys.argv[1]))['rules']))" "$PKG/PROVENANCE.json"); do
  src="$(ls "$SNAP"/*/"$rule".lean 2>/dev/null | head -1)"
  [ -n "$src" ] || { echo "no witness file for $rule under $SNAP"; exit 1; }
  dir="$WORK/lean/TrafficSpecWitness/$(basename "$(dirname "$src")")"; mkdir -p "$dir"; cp "$src" "$dir/"
done
{
  grep '^import ' "$PKG/lean/Explain.lean"
  (cd "$WORK/lean" && find TrafficSpecWitness -name '*.lean' | sed 's#/#.#g; s#\.lean$##; s#^#import #')
  grep -v '^import ' "$PKG/lean/Explain.lean" | sed 's/^def main (args : List String)/def explainCli (args : List String)/'
  cat "$HERE/explain_test_body.lean"
} > "$WORK/lean/ExplainTest.lean"
grep -q '^def explainCli' "$WORK/lean/ExplainTest.lean" || { echo "could not rename the shipped main"; exit 1; }
cat >> "$WORK/lean/lakefile.lean" <<'EOF'

lean_lib «TrafficSpecWitness» where
  srcDir := "."
  globs := #[.submodules `TrafficSpecWitness]

lean_exe «explaintest» where
  root := `ExplainTest
EOF
(cd "$WORK/lean" && lake build explaintest 2>&1 | grep -E "error|Build completed" | head -20)
"$WORK/lean/.lake/build/bin/explaintest" "$PKG/data/reading.json"

echo "== Python checks (cases in $CASES)"
[ "${SKIP_PY:-}" ] || PKG="$PKG" DELIVERED="$DELIVERED" python3 -B -m unittest -v "$HERE/test_explain.py"
