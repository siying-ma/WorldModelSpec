#!/usr/bin/env bash
# One stage of a split training run, launched one iteration at a time, each finished iteration
# exported as a handoff checkpoint, committed to the run's branch and pushed before the next launch.
#
#   STAGE=generation (the remote machine, default): plans, codes and gates laws with the concept review
#     and the aggregate verifier; no training recording is read (--label_deferred). It pauses with
#     `awaiting_labels` when nothing runnable is left without a label check.
#   STAGE=labels (the machine with the training recordings): checks every law whose plan is gated on
#     its recordings and repairs it (--label_stage); it plans and codes nothing new.
#
#   RUN_ID=<id> scripts/run-generation.sh new      # a new run on a new branch runs/<id>, from the code baseline's tip
#   RUN_ID=<id> scripts/run-generation.sh resume   # continue the run on its branch, from its persisted progress
#
# Branches. The code baseline is the branch remote/full-train-generation (BASELINE_BRANCH). Each run has its
# own branch runs/<id>, created by `new` from the baseline's tip; the launcher only appends checkpoint commits
# to it, on that baseline, and development code is never merged into an active run: `resume` refuses a run
# branch that does not descend from the run's baseline commit or holds a merge commit after it, and the loop
# refuses any change to the code the run is pinned to. Newer code means a new run.
#
# Exit status: 0 the stage ended at a checkpoint (handed over, complete, or the launch count spent);
# 1 the loop stopped otherwise (diagnostics in .runtime/<id>/); 2 a preflight check refused before any
# model call; 3 a checkpoint could not be pushed (the same commit is pushed first by the next launch);
# 4 the run paused for the operator at a pushed checkpoint, handed to neither stage: `paused_budget` (raise
# the limit its stop_reason names explicitly, then resume) or `awaiting_operator` (a decision is needed: see
# stop_reason in results/<id>/summary.json and TO_USER.md). Neither is ever continued as an iteration limit.
#
# The launcher itself: RUN_ID (required)  BRANCH (runs/$RUN_ID)  REMOTE (origin)  LAUNCHES (iterations this
#   invocation, 20)  BASELINE_BRANCH (remote/full-train-generation)  LABEL_DATASET (STAGE=labels: the dataset folder)  OPENAI_KEY_FILE
#   (~/.config/traffic-spec/openai.env, sourced when it exists; never printed or committed)  PYTHON (python)
#   PUSH_RETRIES (5)  PUSH_WAIT (60 s)  SKIP_BUILD (1: no `lake build` in the preflight)
#
# The run's options (OPTION_TABLE below: variable, loop option, the value a new run takes when unset):
#   LAWS ONTOLOGY READING WORKERS PLAN_BATCH GATE_BUDGET MODEL REVIEWER_MODEL VERIFIER_MODEL (REVIEWER_MODEL)
#   PLAN_EFFORT CODE_EFFORT REVIEW_EFFORT JUDGE_EFFORT VERIFIER_EFFORT
#   SESSION_CAP REPAIR_CAP JUDGE_CAP (USD per Claude session: a plan or coding session, a repair, a judge; each reserved before it starts)
#   VERIFIER_CAP (USD over the whole run for the aggregate verifier, within OPENAI_BUDGET; no per-session reservation)
#   CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET (their sum) (USD over the whole run)
#   LABEL_REPAIR_ATTEMPTS LABEL_REPAIR_BUDGET
# ACQUISITION_PROFILE (a profile of config/acquisition_profiles.json) is passed by `new` only, when set; a
# run keeps its profile (a semantic input), so `resume` refuses it. Unset, the run may read no `heading_since`.
# `new` passes every one, set or defaulted. `resume` passes only those set in this invocation: every
# other option is the run's saved one (the loop keeps a run's options), so a resume never lowers or
# raises a budget, a model or an effort by itself. Raising a budget is explicit: on `resume`, setting
# CLAUDE_BUDGET or OPENAI_BUDGET needs TOTAL_BUDGET set too. The stage, the dataset folder and each
# launch's iteration bound are passed on every launch.
set -euo pipefail

ACTION=${1:-}
case "$ACTION" in new|resume) ;; *) echo "usage: RUN_ID=<id> $0 new|resume" >&2; exit 2;; esac
cd "$(dirname "$0")/.."                                # the agent directory (pipeline/traffic-spec-agent)
# the doctor's corpus and split tools: the run's checkout is the WorldModelSpec layout, which carries them beside this directory
export PYTHONPATH="$(cd .. && pwd)/ontology_provenance${PYTHONPATH:+:$PYTHONPATH}"
RUN_ID=${RUN_ID:?set RUN_ID}
BASELINE_BRANCH=${BASELINE_BRANCH:-remote/full-train-generation}
STAGE=${STAGE:-generation}
BRANCH=${BRANCH:-runs/$RUN_ID}
REMOTE=${REMOTE:-origin}
LAUNCHES=${LAUNCHES:-20}
OPTION_TABLE='
LAWS|--laws|laws/example/train/laws.jsonl
ONTOLOGY|--ontology_file|ontology/ATOMS_train.md
READING|--reading|library/TrafficSpec/Readings/lasvegas.json
WORKERS|--workers|4
PLAN_BATCH|--plan_batch|8
GATE_BUDGET|--gate_budget|6
MODEL|--model|claude-opus-5[1m]
REVIEWER_MODEL|--reviewer_model|gpt-6.1-sol
VERIFIER_MODEL|--aggregate_verifier_model|
PLAN_EFFORT|--plan_effort|high
CODE_EFFORT|--code_effort|high
REVIEW_EFFORT|--review_effort|high
JUDGE_EFFORT|--judge_effort|high
VERIFIER_EFFORT|--aggregate_verifier_effort|high
SESSION_CAP|--session_budget_usd|20
REPAIR_CAP|--repair_budget_usd|8
JUDGE_CAP|--judge_budget_usd|2
VERIFIER_CAP|--aggregate_verifier_budget_usd|5
CLAUDE_BUDGET|--claude_budget_usd|300
OPENAI_BUDGET|--openai_budget_usd|25
TOTAL_BUDGET|--total_budget_usd|
LABEL_REPAIR_ATTEMPTS|--label_repair_attempts|2
LABEL_REPAIR_BUDGET|--label_repair_budget|10
'
OPENAI_KEY_FILE=${OPENAI_KEY_FILE:-$HOME/.config/traffic-spec/openai.env}
PYTHON=${PYTHON:-python}
PUSH_RETRIES=${PUSH_RETRIES:-5}; PUSH_WAIT=${PUSH_WAIT:-60}
RUN_DIR=results/$RUN_ID
LOG_DIR=.runtime/$RUN_ID

die() { echo "[launcher] $*" >&2; exit "${2:-2}"; }
mkdir -p "$LOG_DIR"
EXCLUDE=$(git rev-parse --git-path info/exclude)      # the repository's own, also from a linked worktree
mkdir -p "$(dirname "$EXCLUDE")"
grep -qxF '.runtime/' "$EXCLUDE" 2>/dev/null || echo '.runtime/' >> "$EXCLUDE"   # logs stay local
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG_DIR/launcher.log"; }

# ---------------------------------------------------------------- preflight: nothing below spends model time
case "$STAGE" in generation|labels) ;; *) die "STAGE must be generation or labels";; esac
given() { [ -n "${!1+x}" ]; }                          # set in this invocation's environment
if [ "$ACTION" = resume ] && given ACQUISITION_PROFILE; then
  die "a run keeps the acquisition profile it started with: ACQUISITION_PROFILE is given to \`new\` only"
fi
if [ "$ACTION" = resume ] && { given CLAUDE_BUDGET || given OPENAI_BUDGET; } && ! given TOTAL_BUDGET; then
  die "on resume a budget changes only explicitly: with CLAUDE_BUDGET or OPENAI_BUDGET set, set TOTAL_BUDGET too"
fi
# the options this launch passes: on `new` each one, set or defaulted; on `resume` only those set here
LOOP_OPTS=()
while IFS='|' read -r name flag default; do
  [ -n "$name" ] || continue
  if ! given "$name" && [ "$ACTION" = new ]; then
    case "$name" in
      VERIFIER_MODEL) default=$REVIEWER_MODEL;;
      TOTAL_BUDGET)                                  # money is never Bash arithmetic: summed as decimals
        default=$("$PYTHON" -c 'import sys; from decimal import Decimal as D; print(D(sys.argv[1]) + D(sys.argv[2]))' "$CLAUDE_BUDGET" "$OPENAI_BUDGET" 2>/dev/null) \
          || die "CLAUDE_BUDGET and OPENAI_BUDGET must be amounts in USD";;
    esac
    printf -v "$name" '%s' "$default"
  fi
  if given "$name"; then LOOP_OPTS+=("$flag" "${!name}"); fi
done <<< "$OPTION_TABLE"
for v in WORKERS PLAN_BATCH GATE_BUDGET LAUNCHES PUSH_RETRIES PUSH_WAIT LABEL_REPAIR_ATTEMPTS LABEL_REPAIR_BUDGET; do
  if given "$v"; then [[ ${!v} =~ ^[0-9]+$ ]] || die "$v must be a whole number (given '${!v}')"; fi
done
if given WORKERS; then [ "$WORKERS" -ge 1 ] || die "WORKERS must be at least 1"; fi
for v in SESSION_CAP REPAIR_CAP JUDGE_CAP VERIFIER_CAP CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET; do
  if given "$v"; then
    "$PYTHON" -c 'import sys; from decimal import Decimal as D; x = D(sys.argv[1]); sys.exit(0 if x.is_finite() and x >= 0 else 1)' "${!v}" 2>/dev/null \
      || die "$v must be a non-negative amount in USD (given '${!v}')"
  fi
done
git config user.name >/dev/null && git config user.email >/dev/null || die "set git user.name and user.email"
git diff --cached --quiet || die "the index holds staged changes; this launcher commits only the run's files — unstage them"
[ -z "$(git status --porcelain --untracked-files=no)" ] || die "the checkout has uncommitted changes to tracked files; use a clean, separate checkout"
CURRENT=$(git symbolic-ref --quiet --short HEAD || true)
git fetch -q "$REMOTE" 2>/dev/null || die "cannot fetch from $REMOTE"
REMOTE_HAS=$(git ls-remote --heads "$REMOTE" "refs/heads/$BRANCH" | wc -l)
if [ "$ACTION" = new ]; then
  git show-ref --verify --quiet "refs/heads/$BRANCH" && die "branch $BRANCH exists here: a new run needs a new branch (use resume)"
  [ "$REMOTE_HAS" -eq 0 ] || die "branch $BRANCH exists on $REMOTE: a new run needs a new branch (use resume from a clone of it)"
  [ "$STAGE" = generation ] || die "a new run starts with STAGE=generation"
  BASE_TIP=$(git rev-parse -q --verify "refs/remotes/$REMOTE/$BASELINE_BRANCH^{commit}") \
    || die "no code baseline $REMOTE/$BASELINE_BRANCH: a new run starts from its tip"
  [ "$(git rev-parse HEAD)" = "$BASE_TIP" ] \
    || die "a new run starts from the tip of the code baseline $REMOTE/$BASELINE_BRANCH ($BASE_TIP); this checkout is at $(git rev-parse HEAD)"
else
  [ "$CURRENT" = "$BRANCH" ] || die "resume runs on the checked-out run branch $BRANCH (now: ${CURRENT:-detached})"
  [ -f "$RUN_DIR/state.json" ] || die "$RUN_DIR/state.json is missing: nothing to resume"
  if [ "$REMOTE_HAS" -gt 0 ]; then
    BEHIND=$(git rev-list --count "HEAD..$REMOTE/$BRANCH")
    [ "$BEHIND" -eq 0 ] || die "$REMOTE/$BRANCH has $BEHIND commit(s) this checkout lacks: another machine wrote the run; pull first"
  fi
fi
git push --dry-run -q "$REMOTE" "HEAD:refs/heads/$BRANCH" >/dev/null 2>&1 || die "a dry-run push to $REMOTE $BRANCH failed: check the remote and its credentials"
"$PYTHON" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null || die "$PYTHON is not Python 3.11 or newer"
"$PYTHON" -c 'import harness, fire' 2>/dev/null || die "the Python environment lacks the harness or its dependencies (source .venv/bin/activate)"
"$PYTHON" -c 'from openai import OpenAI, APIError, APITimeoutError, RateLimitError' 2>/dev/null \
  || die "the OpenAI SDK (openai, which the concept review and the aggregate verifier call) does not import in $PYTHON: run setup.sh, or pip install 'openai>=1.66'"
if [ "$ACTION" = new ]; then                            # the harness's own rule: no run directory, or only the run's law subset
  "$PYTHON" -c 'import sys; from pathlib import Path; from harness.store.paths import run_is_new; sys.exit(0 if run_is_new(Path(sys.argv[1])) else 1)' "$RUN_DIR" \
    || die "$RUN_DIR holds more than the run's law subset (laws/laws.jsonl, laws/definitions.jsonl): a new run needs a new run id"
fi
"$PYTHON" -c 'import nrs_tools.atoms_train' 2>/dev/null \
  || die "the doctor's split tools (nrs_tools) are missing: run from a checkout of the whole WorldModelSpec repository, which carries pipeline/ontology_provenance/ beside this directory"
"$PYTHON" -c 'from harness.store.state import Options as O; f = O.__dataclass_fields__; raise SystemExit(0 if {"label_deferred", "label_stage"} <= set(f) else 1)' \
  || die "this checkout's harness has no --label_deferred / --label_stage"
command -v claude >/dev/null || die "the claude CLI is not on PATH"
command -v lake >/dev/null || die "lake (Lean) is not on PATH"
if [ -f "$OPENAI_KEY_FILE" ]; then set +x; set -a; . "$OPENAI_KEY_FILE"; set +a; fi
[ -n "${OPENAI_API_KEY:-}" ] || die "OPENAI_API_KEY is not set (the concept review and the aggregate verifier); see the README"
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then log "claude: ANTHROPIC_API_KEY is set (API billing)"; else log "claude: CLI login (${CLAUDE_CONFIG_DIR:-~/.claude})"; fi
[ "$("$PYTHON" -m harness split 2>/dev/null | grep -o 'train\|full' | head -1)" = train ] || die "the training split is not active (python -m harness split --use train)"
if [ "$STAGE" = labels ]; then [ -n "${LABEL_DATASET:-}" ] && [ -d "$LABEL_DATASET" ] || die "STAGE=labels needs LABEL_DATASET, a dataset folder"; fi
if [ "${SKIP_BUILD:-0}" != 1 ]; then (cd library && lake build >/dev/null) || die "the library does not build"; fi
"$PYTHON" -m harness doctor >"$LOG_DIR/doctor.log" 2>&1 || die "the doctor failed (see $LOG_DIR/doctor.log)"
[ "$ACTION" = new ] && git switch -q -c "$BRANCH"     # a new branch from this HEAD: never a reset of an existing one

# ---------------------------------------------------------------- checkpoints
push_checkpoint() {                                    # push HEAD (the same commit) with retries; 3 when it stays refused
  local i
  for i in $(seq 1 "$PUSH_RETRIES"); do
    if git push -q "$REMOTE" "HEAD:refs/heads/$BRANCH" 2>>"$LOG_DIR/push.log"; then
      git branch -q --set-upstream-to="$REMOTE/$BRANCH" 2>/dev/null || true
      return 0
    fi
    log "push failed (attempt $i of $PUSH_RETRIES); retrying the same commit in $PUSH_WAIT s"
    sleep "$PUSH_WAIT"
  done
  log "the checkpoint $(git rev-parse --short HEAD) is not on $REMOTE; no further model call — rerun to push it first"
  exit 3
}

commit_checkpoint() {                                  # the listed files only, ignored ones included; deletions recorded
  local list="$RUN_DIR/handoff/files.txt"
  cp "$list" "$LOG_DIR/pathspec.txt"                   # paths relative to this directory, as git reads them here
  git add -f --pathspec-from-file="$LOG_DIR/pathspec.txt"
  git ls-files -- "$RUN_DIR" library/TrafficSpec/Rules library/TrafficSpec/Concepts library/TrafficSpecWitness \
      library/TrafficSpec/Gaps | grep -vxF -f "$LOG_DIR/pathspec.txt" \
      | while IFS= read -r gone; do git rm -q --cached -- "$gone"; done || true
  if git diff --cached --quiet; then log "checkpoint: nothing changed"; return 0; fi
  git commit -q -m "$RUN_ID: $STAGE checkpoint, iteration $(state_field iteration) ($1)" \
      -m "handoff $(manifest_field export_id); source baseline $(manifest_field baseline.source_commit); code $(manifest_field baseline.code.digest)"
}

state_field() { "$PYTHON" - "$RUN_DIR" "$1" <<'PY'
import json, sys
d = sys.argv[1]
s = json.load(open(f"{d}/state.json"))
k = sys.argv[2]
print(s.get("iteration", 0) if k == "iteration" else (s.get("prog") or {}).get("stage", ""))
PY
}
manifest_field() { "$PYTHON" - "$RUN_DIR/handoff/manifest.json" "$1" <<'PY'
import json, sys
x = json.load(open(sys.argv[1]))
for k in sys.argv[2].split("."):
    x = (x or {}).get(k)
print(x)
PY
}
summary_field() { "$PYTHON" -c 'import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2]) or "")' "$RUN_DIR/summary.json" "$1" 2>/dev/null || true; }
written() { "$PYTHON" -c 'import os,sys; p=sys.argv[1]; print(os.stat(p).st_mtime_ns if os.path.exists(p) else "none")' "$1"; }   # when the loop last wrote its status

# a run branch holds its baseline and checkpoint commits only: never development code merged in
if [ "$ACTION" = resume ] && [ -f "$RUN_DIR/handoff/manifest.json" ]; then
  RUN_BASE=$(manifest_field baseline.source_commit)
  if [ -n "$RUN_BASE" ] && [ "$RUN_BASE" != None ]; then
    git merge-base --is-ancestor "$RUN_BASE" HEAD 2>/dev/null || die "the run branch does not descend from the run's baseline commit $RUN_BASE"
    [ -z "$(git rev-list --merges "$RUN_BASE..HEAD")" ] \
      || die "the run branch holds a merge commit after its baseline $RUN_BASE: development code is never merged into an active run (start a new run)"
  fi
fi

# a checkpoint committed by an earlier launch and not yet on the remote is pushed before any model call
if [ "$ACTION" = resume ] && { [ "$REMOTE_HAS" -eq 0 ] || [ -n "$(git rev-list "$REMOTE/$BRANCH..HEAD")" ]; }; then
  log "pushing the checkpoint an earlier launch left unpushed"; push_checkpoint
fi

STAGE_FLAGS=(--label_deferred)
[ "$STAGE" = labels ] && STAGE_FLAGS=(--label_stage --label_dataset "$LABEL_DATASET")
[ "$ACTION" = new ] && STAGE_FLAGS=(--feedback labels --label_repair "${STAGE_FLAGS[@]}")   # a resume keeps the run's feedback
[ "$ACTION" = new ] && [ -n "${ACQUISITION_PROFILE:-}" ] && STAGE_FLAGS+=(--acquisition_profile "$ACQUISITION_PROFILE")
log "options passed: ${LOOP_OPTS[*]:-none, the saved options of the run stand}"

for launch in $(seq 1 "$LAUNCHES"); do
  # the iteration bound of this launch, from the persisted progress: an unfinished iteration resumes, else one more
  if [ -f "$RUN_DIR/state.json" ]; then
    it=$(state_field iteration); st=$(state_field stage)
    case "$st" in done|abandoned|"") k=$((it + 1));; *) k=$it;; esac
  else
    k=1
  fi
  before=$(written "$RUN_DIR/summary.json")
  log "launch $launch of $LAUNCHES: $STAGE, iteration bound $k"
  set +e
  "$PYTHON" -m harness loop --run_id "$RUN_ID" "${STAGE_FLAGS[@]}" --max_iterations "$k" ${LOOP_OPTS[@]+"${LOOP_OPTS[@]}"} \
      >>"$LOG_DIR/loop.log" 2>&1
  code=$?
  set -e
  if [ "$(written "$RUN_DIR/summary.json")" = "$before" ]; then
    tail -n 40 "$LOG_DIR/loop.log" > "$LOG_DIR/diagnostics.txt"
    log "the loop exited ($code) without writing its status: stopped (see $LOG_DIR/diagnostics.txt)"; exit 1
  fi
  status=$(summary_field status); stop=$(summary_field stop)
  log "loop exit $code: status $status${stop:+, stop $stop}"
  if ! "$PYTHON" -m harness handoff export "$RUN_ID" --source_baseline "$(git rev-parse HEAD)" >>"$LOG_DIR/launcher.log" 2>&1; then
    cp "$RUN_DIR/summary.json" "$LOG_DIR/diagnostics-summary.json"; tail -n 40 "$LOG_DIR/loop.log" > "$LOG_DIR/diagnostics.txt"
    log "no checkpoint after status $status (see $LOG_DIR/launcher.log and $LOG_DIR/diagnostics.txt): stopped"; exit 1
  fi
  commit_checkpoint "$status${stop:+, $stop}"
  push_checkpoint
  case "$status:$stop" in
    awaiting_labels:*) log "generation paused awaiting label checks: run STAGE=labels on the dataset machine"; exit 0;;
    awaiting_generation:*) log "label checks and repairs done: hand the run back to STAGE=generation"; exit 0;;
    complete:*)        log "the run is complete"; exit 0;;
    paused_budget:*)   log "paused on a budget: $(summary_field stop_reason); raise the named limit explicitly and resume"; exit 4;;
    awaiting_operator:*) log "operator decision needed; see stop_reason and TO_USER.md: $(summary_field stop_reason)"; exit 4;;
    *:iteration_limit) continue;;
    *) cp "$RUN_DIR/summary.json" "$LOG_DIR/diagnostics-summary.json"
       log "status $status is no iteration-limit checkpoint: stopped after pushing it"; exit 1;;
  esac
done
log "$LAUNCHES launch(es) done; resume with: RUN_ID=$RUN_ID STAGE=$STAGE $0 resume"
