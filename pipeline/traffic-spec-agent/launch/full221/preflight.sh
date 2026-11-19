#!/usr/bin/env bash
# Check the machine and the checkout before the full221 run spends anything. It calls no model and changes no
# file of the checkout: it only builds the library (lake writes library/.lake, which git ignores) and writes its
# logs under .runtime/preflight-<run id>/. Every check prints PASS or FAIL (INFO lines are printed only for the
# record); the exit status is the number of FAILs, capped at 1 (0: all passed).
# Run from pipeline/traffic-spec-agent of the clone the run will use:
#   RUN_ID=<run id> bash launch/full221/preflight.sh          (launch.sh runs it first, with the run's id)
# Optional: MIN_FREE_GB (20, on the checkout's disk), MIN_CONFIG_FREE_GB (5, on the Claude config directory's disk),
# OPENAI_KEY_FILE (~/.config/traffic-spec/openai.env), PYTHON (python3), REMOTE (origin).
set -uo pipefail
export PYTHONDONTWRITEBYTECODE=1
RUN_ID=${RUN_ID:-}
CONFIG=${CLAUDE_CONFIG_DIR:-$HOME/.claude}                 # the claude CLI's config directory (its default when unset)
ACCOUNT_FILE=${CLAUDE_CONFIG_DIR:+$CLAUDE_CONFIG_DIR/.claude.json}; ACCOUNT_FILE=${ACCOUNT_FILE:-$HOME/.claude.json}
MIN_FREE_GB=${MIN_FREE_GB:-20}; MIN_CONFIG_FREE_GB=${MIN_CONFIG_FREE_GB:-5}
OPENAI_KEY_FILE=${OPENAI_KEY_FILE:-$HOME/.config/traffic-spec/openai.env}
PYTHON=${PYTHON:-python3}; REMOTE=${REMOTE:-origin}
BASELINE_BRANCH=remote/full-train-generation; LAWS=laws/example/train/laws.jsonl; N_LAWS=224
FAILS=0
pass() { echo "PASS  $*"; }
fail() { echo "FAIL  $*"; FAILS=$((FAILS + 1)); }
info() { echo "INFO  $*"; }
free_gb() { df -Pk "$1" 2>/dev/null | awk 'NR == 2 { print int($4 / 1048576) }'; }

# ---------------------------------------------------------------- the inputs and the place
[ -n "$RUN_ID" ] && pass "RUN_ID is $RUN_ID" || fail "RUN_ID is not set (export RUN_ID=full221-\$(date +%m%d-%H%M), once)"
if [ -d harness ] && [ -f scripts/run-generation.sh ] && [ "$(git rev-parse --show-prefix 2>/dev/null)" = pipeline/traffic-spec-agent/ ]; then
  pass "running in pipeline/traffic-spec-agent of a WorldModelSpec clone ($(pwd))"
else
  echo "FAIL  run this from pipeline/traffic-spec-agent of the clone (now: $(pwd))"; exit 1
fi
export PYTHONPATH="$(cd .. && pwd)/ontology_provenance${PYTHONPATH:+:$PYTHONPATH}"   # the doctor's corpus and split tools, as the launcher sets it
LOGS=.runtime/preflight-${RUN_ID:-unnamed}; mkdir -p "$LOGS"

# ---------------------------------------------------------------- the checkout
HEAD=$(git rev-parse HEAD)
TIP=$(git ls-remote "$REMOTE" "refs/heads/$BASELINE_BRANCH" 2>/dev/null | cut -f1)
if [ -z "$TIP" ]; then fail "$REMOTE has no branch $BASELINE_BRANCH (or cannot be reached): clone the repository with --branch $BASELINE_BRANCH"
elif [ "$TIP" = "$HEAD" ]; then pass "HEAD is the tip of $REMOTE/$BASELINE_BRANCH ($HEAD)"
else fail "HEAD is $HEAD, but $REMOTE/$BASELINE_BRANCH is at $TIP: make a fresh clone of the branch"; fi
git diff --cached --quiet && [ -z "$(git status --porcelain --untracked-files=no)" ] \
  && pass "no tracked file is changed or staged" || fail "the checkout has changed or staged tracked files: use a fresh clone ($(git status --porcelain --untracked-files=no | head -n 3 | tr '\n' ' '))"
if [ -n "$RUN_ID" ]; then
  git show-ref --verify --quiet "refs/heads/runs/$RUN_ID" && fail "a local branch runs/$RUN_ID exists: choose a new RUN_ID" \
    || pass "no local branch runs/$RUN_ID"
  [ -z "$(git ls-remote --heads "$REMOTE" "refs/heads/runs/$RUN_ID" 2>/dev/null)" ] && pass "no branch runs/$RUN_ID on $REMOTE" \
    || fail "runs/$RUN_ID exists on $REMOTE: choose a new RUN_ID"
  [ ! -e "results/$RUN_ID" ] && pass "results/$RUN_ID does not exist" || fail "results/$RUN_ID exists: choose a new RUN_ID"
  git push --dry-run -q "$REMOTE" "HEAD:refs/heads/runs/$RUN_ID" >/dev/null 2>&1 \
    && pass "a dry-run push to $REMOTE runs/$RUN_ID is accepted" || fail "a dry-run push to $REMOTE runs/$RUN_ID failed: check push access and credentials"
fi
TOP=$(cd "$(git rev-parse --show-toplevel)" && pwd -P); TMP=$(realpath -m "${TMPDIR:-/tmp}")
case "$TMP/" in
  "$TOP"/*) fail "TMPDIR ($TMPDIR) lies inside the checkout ($TOP): the claude CLI writes its task output there, and the coding gate reads it as a change to the tree; export TMPDIR=<a directory outside the checkout>" ;;
  *) pass "TMPDIR (${TMPDIR:-unset: /tmp}) lies outside the checkout" ;;
esac
[ -n "$(git config user.name)" ] && [ -n "$(git config user.email)" ] \
  && pass "git identity: $(git config user.name) <$(git config user.email)>" || fail "git user.name / user.email not set (git config user.name ...; git config user.email ...)"

# ---------------------------------------------------------------- accounts and keys
if true; then
  ACCOUNT=$("$PYTHON" - "$ACCOUNT_FILE" <<'PY' 2>/dev/null
import json, sys
a = json.load(open(sys.argv[1])).get("oauthAccount") or {}
if not a.get("emailAddress"):
    sys.exit(1)
print(f"{a.get('emailAddress')}, organization {a.get('organizationName') or '-'}, plan {a.get('planDisplayName') or a.get('billingType') or '-'}")
PY
)
  [ -n "$ACCOUNT" ] && pass "the claude CLI (config ${CLAUDE_CONFIG_DIR:-default}) bills: $ACCOUNT" \
    || fail "the claude CLI (config ${CLAUDE_CONFIG_DIR:-default}) has no logged-in account: run claude once and /login"
fi
[ -z "${ANTHROPIC_API_KEY:-}" ] && [ -z "${ANTHROPIC_AUTH_TOKEN:-}" ] && pass "ANTHROPIC_API_KEY and ANTHROPIC_AUTH_TOKEN are unset" \
  || fail "ANTHROPIC_API_KEY or ANTHROPIC_AUTH_TOKEN is set: unset it (the CLI would bill it instead of the account)"
if [ ! -f "$OPENAI_KEY_FILE" ]; then fail "the OpenAI key file $OPENAI_KEY_FILE is missing"
elif [ "$(stat -c %a "$OPENAI_KEY_FILE")" != 600 ]; then fail "$OPENAI_KEY_FILE has mode $(stat -c %a "$OPENAI_KEY_FILE"): chmod 600 it"
elif grep -qE '^(export )?OPENAI_API_KEY=.+' "$OPENAI_KEY_FILE"; then pass "the OpenAI key file is present, mode 600, with OPENAI_API_KEY (not printed)"
else fail "$OPENAI_KEY_FILE has no OPENAI_API_KEY=... line"; fi

# ---------------------------------------------------------------- tools
if command -v claude >/dev/null; then
  pass "claude resolves to $(command -v claude)"
  info "claude --version: $(timeout 30 claude --version 2>&1 | head -n 1)"
else
  fail "claude is not on PATH"
fi
if "$PYTHON" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null; then
  pass "$("$PYTHON" --version 2>&1) ($(command -v "$PYTHON"))"
else
  fail "$PYTHON is missing or older than 3.11 ($("$PYTHON" --version 2>&1))"
fi
"$PYTHON" -c 'import harness, fire; from openai import OpenAI' 2>/dev/null && pass "harness, fire and openai import" \
  || fail "harness, fire or openai does not import: run setup.sh, or source .venv/bin/activate"
"$PYTHON" -c 'import nrs_tools.atoms_train' 2>/dev/null \
  && pass "the doctor's split tools (nrs_tools) import" || fail "nrs_tools does not import: the clone must be the whole repository"
if command -v lake >/dev/null; then
  pass "lake: $(cd library && lake --version 2>&1 | head -n 1)"
  info "lean: $(cd library && lean --version 2>&1 | head -n 1); library/lean-toolchain: $(cat library/lean-toolchain)"
else
  fail "lake is not on PATH (export PATH=\$HOME/.elan/bin:\$PATH)"
fi
grep -q 'stage-enter' scripts/run-generation.sh && "$PYTHON" -c 'import harness.store.stages' 2>/dev/null \
  && pass "the launcher and harness run staged runs (a new run opens stage G0)" \
  || fail "this checkout's launcher or harness has no stages: it is not the baseline for this run"
pgrep -u "$(id -u)" -f 'python[0-9.]* -m harness loop' >/dev/null \
  && fail "a harness loop already runs under this user: ask the requester before starting another run" \
  || pass "no other harness loop runs under this user"

# ---------------------------------------------------------------- disk and corpus
G=$(free_gb .); [ -n "$G" ] && [ "$G" -ge "$MIN_FREE_GB" ] && pass "free disk here: ${G} GB (at least $MIN_FREE_GB)" \
  || fail "free disk here: ${G:-unknown} GB, less than $MIN_FREE_GB"
if [ -d "$CONFIG" ]; then
  G=$(free_gb "$CONFIG"); [ -n "$G" ] && [ "$G" -ge "$MIN_CONFIG_FREE_GB" ] \
    && pass "free disk for the Claude config directory $CONFIG (session transcripts): ${G} GB (at least $MIN_CONFIG_FREE_GB)" \
    || fail "free disk for the Claude config directory $CONFIG: ${G:-unknown} GB, less than $MIN_CONFIG_FREE_GB"
fi
SPLIT=$("$PYTHON" -m harness split 2>/dev/null | grep -o 'train\|full' | head -n 1)
[ "$SPLIT" = train ] && pass "the active split is train" || fail "the active split is '${SPLIT:-unknown}', not train"
COUNT=$("$PYTHON" - "$LAWS" <<'PY' 2>&1
import json, sys
ids = [json.loads(l)["id"] for l in open(sys.argv[1]) if l.strip()]
print(len(ids) if len(ids) == len(set(ids)) else f"{len(ids)} lines with duplicate ids")
PY
)
[ "$COUNT" = "$N_LAWS" ] && pass "$LAWS has $N_LAWS laws" || fail "$LAWS: $COUNT, not $N_LAWS laws"

# ---------------------------------------------------------------- build and doctor (slow)
T0=$(date +%s)
if (cd library && lake build) > "$LOGS/lake-build.log" 2>&1; then
  pass "lake build succeeded in $(( $(date +%s) - T0 )) s"
else
  fail "lake build failed after $(( $(date +%s) - T0 )) s: see $LOGS/lake-build.log"; tail -n 15 "$LOGS/lake-build.log" | sed 's/^/      /'
fi
T0=$(date +%s)
if "$PYTHON" -m harness doctor > "$LOGS/doctor.log" 2>&1; then
  pass "doctor exit 0 in $(( $(date +%s) - T0 )) s: $(grep -E 'checks pass' "$LOGS/doctor.log" | tail -n 1)"
else
  fail "doctor failed after $(( $(date +%s) - T0 )) s: see $LOGS/doctor.log"; tail -n 15 "$LOGS/doctor.log" | sed 's/^/      /'
fi
git diff --cached --quiet && [ -z "$(git status --porcelain --untracked-files=no)" ] \
  && pass "the checkout is still clean after the build and the doctor" || fail "the build or the doctor changed tracked files: $(git status --porcelain --untracked-files=no | head -n 3 | tr '\n' ' ')"

echo
if [ "$FAILS" -eq 0 ]; then echo "preflight: all checks passed"; exit 0; fi
echo "preflight: $FAILS check(s) failed; do not launch"; exit 1
