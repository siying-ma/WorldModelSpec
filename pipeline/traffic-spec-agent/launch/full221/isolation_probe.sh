#!/usr/bin/env bash
# The isolation gate before a new run: can a Claude session, under exactly the coding session's permissions, read
# a file no session may read (the held-out laws, the full corpus and ontology, the full Core variant, the driving
# data, another run)? launch.sh runs it after the preflight and starts nothing unless it passes; it also runs alone.
# It never writes into this clone: it makes a throwaway sparse clone of this checkout's HEAD outside it, with every
# such path left out, has launch/full221/isolation_probe.py put a synthetic sentinel at each one and run two
# sessions there, keeps the raw streams, the rules, the sentinels and the verdict in PROBE_OUT, and removes the
# throwaway clone. It spends at most $3 (two sessions of at most $1 each, PROBE_MODEL), billed to the claude CLI's
# account.
# Run from pipeline/traffic-spec-agent:  bash launch/full221/isolation_probe.sh <run id>
# Optional: PROBE_OUT (~/wms-isolation-probe/<run id>), PROBE_TMP (TMPDIR or /tmp), PROBE_MODEL (claude-haiku-5-5),
# PYTHON (python3). Exit: 0 PASS; 1 FAIL (a session reached such a file, or the probe did not run as given: the
# verdict says which); 2 refused before any session.
set -uo pipefail
RUN_ID=${1:?run id}
PYTHON=${PYTHON:-python3}
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL
[ -d harness ] && [ -f launch/full221/isolation_probe.py ] || { echo "refusing: run from pipeline/traffic-spec-agent"; exit 2; }
HERE=$(pwd -P); TOP=$(git rev-parse --show-toplevel); PREFIX=$(git rev-parse --show-prefix)
OUT=${PROBE_OUT:-$HOME/wms-isolation-probe/$RUN_ID}
case "$(realpath -m "$OUT")/" in "$TOP"/*) echo "refusing: PROBE_OUT ($OUT) is inside this clone"; exit 2;; esac
[ ! -e "$OUT" ] || { echo "refusing: $OUT exists (a probe of this run id was made before; set PROBE_OUT)"; exit 2; }
[ -z "$(git status --porcelain --untracked-files=no)" ] || { echo "refusing: this checkout has changes to tracked files"; exit 2; }
command -v claude >/dev/null || { echo "refusing: claude is not on PATH"; exit 2; }
VERSION=$(claude --version 2>/dev/null | head -n 1)
[ -n "$VERSION" ] || { echo "refusing: claude --version printed nothing"; exit 2; }
# the paths no session may read, from this checkout's harness, as sparse-checkout exclusions
EXCL=$(PYTHONDONTWRITEBYTECODE=1 "$PYTHON" -c '
import sys
from harness.agents.session import UNREADABLE, UNREADABLE_REPO
print("\n".join(["!/" + sys.argv[1] + u for u in UNREADABLE] + ["!/" + r for r in UNREADABLE_REPO]))' "$PREFIX") \
  || { echo "refusing: the harness's unreadable paths could not be read"; exit 2; }
BEFORE=$(git status --porcelain --ignored)

TMP=$(mktemp -d "${PROBE_TMP:-${TMPDIR:-/tmp}}/wms-probe.XXXXXX") || { echo "refusing: no temporary directory"; exit 2; }
trap 'rm -rf "${TMP:?}"' EXIT
case "$(realpath "$TMP")/" in "$TOP"/*) echo "refusing: PROBE_TMP is inside this clone"; exit 2;; esac
HEAD=$(git rev-parse HEAD)
git clone -q --no-checkout "$TOP" "$TMP/clone" && git -C "$TMP/clone" sparse-checkout set --no-cone '/*' $EXCL \
  && git -C "$TMP/clone" checkout -q --detach "$HEAD" || { echo "refusing: the throwaway clone could not be made"; exit 2; }
mkdir -p "$OUT"
{ echo "run id: $RUN_ID"; echo "commit: $HEAD"; echo "claude --version: $VERSION"; echo "account: ${CLAUDE_CONFIG_DIR:-the default login}"
  echo "excluded:"; echo "$EXCL"; } > "$OUT/context.txt"
(cd "$TMP/clone/$PREFIX" && PYTHONPATH="$PWD" PYTHONDONTWRITEBYTECODE=1 "$PYTHON" "$HERE/launch/full221/isolation_probe.py" \
  "$OUT" "$VERSION" "${PROBE_MODEL:-claude-haiku-5-5}" 1.00 3.00) 2>&1 | tee "$OUT/probe.txt"
RC=${PIPESTATUS[0]}
if [ "$(git status --porcelain --ignored)" != "$BEFORE" ]; then
  echo "FAIL: this clone changed while the probe ran" | tee -a "$OUT/probe.txt"; RC=1
fi
echo "isolation probe: $([ "$RC" -eq 0 ] && echo PASS || echo FAIL) (exit $RC); kept in $OUT"
exit "$RC"
