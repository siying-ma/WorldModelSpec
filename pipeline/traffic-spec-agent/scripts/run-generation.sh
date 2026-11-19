#!/usr/bin/env bash
# One stage of a split training run, launched one iteration at a time, each finished iteration
# exported as a handoff checkpoint, committed to the run's branch and pushed before the next launch.
#
#   STAGE=generation (the remote machine, default): plans, codes and gates laws with the concept review
#     and the aggregate verifier; no training recording is read (--label_deferred). It pauses with
#     `awaiting_labels` when nothing runnable is left without a label check.
#   STAGE=labels (the machine with the training recordings): checks every law whose plan is gated on
#     its recordings and repairs it (--label_stage); it plans and codes nothing new.
#   STAGE=review (a run with a stage record, in a review stage): writes and checks each generated law's behaviour
#     properties with the reviewer the run fixed (--review_stage); it plans, codes and label-checks nothing. Which
#     stage may follow which, and whether a review stage may be entered at all (the run's policy `review: required`
#     and a reviewer: the run's first review entry fixes the registered one BEHAVIOUR_REVIEWER names, a later entry
#     keeps it, registered as fixed), is the harness's `stage enter` rule.
#
# Handover. A staged run whose launch ends `awaiting_review` (generation or labels) or `awaiting_labels` (review)
# enters that stage itself, on the same code, when `python -m harness stage handover` finds every condition
# holds (the last iteration committed and exported, no session active, no request unsettled, no review call
# unreconciled and no stop open, the scope fixed, the code unchanged, this machine able to run that stage: the
# reviewer the run fixed registered as fixed, or before its first review entry the one BEHAVIOUR_REVIEWER names
# registered, with the review budgets set; or LABEL_DATASET the run's dataset; and the switch no round
# trip without progress): it runs `stage-enter` with NEW_BASE at this checkpoint, KIND the new stage,
# TRANSITION auto-<stage left>-<kind>, and goes on launching in the new stage. Otherwise the run waits at its
# checkpoint (exit 0) with the reasons logged, for a machine that can run the stage or for the operator; an
# active stop of the run (any kind summary.json's `stops` lists) or a round trip without progress is the
# operator's (exit 4). It never chooses a scope, raises a limit or acknowledges a stop. A run without a stage record is handed over by hand, as before.
#
#   RUN_ID=<id> scripts/run-generation.sh new      # a new run on a new branch runs/<id>, from the code baseline's tip
#   RUN_ID=<id> scripts/run-generation.sh resume   # continue the run on its branch, from its persisted progress
#   RUN_ID=<id> NEW_BASE=<commit> KIND=<kind> FROM=<stage> TRANSITION=<id> [SCOPE=<file>] [PROMPTS_APPROVED=<digest>] \
#     [BEHAVIOUR_REVIEWER=<name>] scripts/run-generation.sh stage-enter   # the run enters a new stage on the code of NEW_BASE
#
# Branches. The code baseline is the branch remote/full-train-generation (BASELINE_BRANCH). Each run has its
# own branch runs/<id>, created by `new` from the baseline's tip; the launcher only appends checkpoint commits
# to it, on that baseline, and development code is never merged into an active run: `resume` refuses a run
# branch that does not descend from the run's baseline commit or holds a merge commit after it, and the loop
# refuses any change to the code the run is pinned to. Newer code means a new run, or, for a run with a stage
# record (results/<id>/stages.jsonl), a new stage:
#
# Stages. `stage-enter` runs on the checked-out run branch at its last pushed checkpoint, clean. It replaces
# exactly the code files (those the code patterns of the harness's handoff module match, as of NEW_BASE and of
# the checkpoint, with the doctor's split tool; additions and deletions included; never a run artifact) by
# NEW_BASE's, runs `python -m harness stage enter` on that code, commits all of it as one non-merge commit
# `stage <new id>: baseline <NEW_BASE>` (with a `Stage-Transition: <id>` line), pushes it, runs `python -m
# harness stage confirm --transition <id> --commit <it>`, and commits and pushes the transition's `done` state. Run again after
# a stop anywhere, it continues. For a staged run `resume` requires instead: no transition short of `done`,
# STAGE a launch kind of the active stage, the branch descending from the stage's transition commit (the one
# `stage confirm` recorded; a first stage without one keeps the baseline rule above) with no merge after it,
# and the code here equal to the stage's code baseline.
#
# Exit status: 0 the stage ended at a checkpoint (handed over or waiting for the next stage, complete, or the
# launch count spent);
# 1 the loop stopped otherwise (diagnostics in .runtime/<id>/); 2 a preflight check refused before any
# model call; 3 a checkpoint could not be pushed (the same commit is pushed first by the next launch);
# 4 the run paused for the operator, handed to neither stage: a handover that finds a stop of the run active or
# would be a round trip without progress, `paused_budget` (raise the limit its
# stop_reason names explicitly, then resume), `paused_defect` (one gate failure repeated across laws: find its
# cause before resuming, see stop_reason) or `awaiting_operator` (a decision is needed: see stop_reason in
# results/<id>/summary.json and TO_USER.md); 5 `infrastructure_failure`, uncharged: something the iteration
# needs did not run, and its stop_reason says what (a session the account or the API refused, the toolchain,
# the check of accepted records before integration, the integration, or the validator itself); whether a
# resume is due depends on that reason. None of 1, 4, 5 is ever continued as an iteration
# limit. A stop inside an iteration leaves no checkpoint: the iteration's work stays in the files a checkpoint
# commits (those `handoff export` lists: the run's directory, every file under the library's record
# directories, the registries and the reading; and deletions under those directories), and `resume` accepts a
# checkout whose only tracked changes are there, the loop taking the iteration up. That is no proof that each
# such file was written by this run: it holds because the checkout serves one run only. `new`, and any change
# to another tracked file, still need a clean checkout.
# `stage-enter`: 0 the stage is entered, confirmed and pushed (also when it already was); 1 the harness's
# transition or confirmation stopped after it began (run the same stage-enter again); 2 refused before
# anything changed (a refusal of the harness included: the checkpoint's code is put back); 3 a commit could
# not be pushed (the same stage-enter pushes it first).
#
# The launcher itself: RUN_ID (required)  BRANCH (runs/$RUN_ID)  REMOTE (origin)  LAUNCHES (iterations this
#   invocation, 20)  BASELINE_BRANCH (remote/full-train-generation)  LABEL_DATASET (STAGE=labels: the dataset folder)  OPENAI_KEY_FILE
#   (~/.config/traffic-spec/openai.env, sourced when it exists; never printed or committed)  PYTHON (python3)
#   PUSH_RETRIES (5)  PUSH_WAIT (60 s)  SKIP_BUILD (1: no `lake build` in the preflight)
#
# The run's options (OPTION_TABLE below: variable, loop option, the value a new run takes when unset):
#   LAWS ONTOLOGY READING WORKERS PLAN_BATCH GATE_BUDGET MODEL REVIEWER_MODEL VERIFIER_MODEL (REVIEWER_MODEL)
#   PLAN_EFFORT CODE_EFFORT REVIEW_EFFORT JUDGE_EFFORT VERIFIER_EFFORT
#   SESSION_CAP REPAIR_CAP JUDGE_CAP (USD per Claude session: a plan or coding session, a repair, a judge; each reserved before it starts)
#   VERIFIER_CAP (USD over the whole run for the aggregate verifier, within OPENAI_BUDGET; no per-session reservation)
#   CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET (their sum) (USD over the whole run)
#   LABEL_REPAIR_ATTEMPTS LABEL_REPAIR_BUDGET
#   REVIEW_COVERAGE (strict or bounded, fixed by a new run) REVIEW_BUDGET (USD over the run for the reviewer's calls; a review launch needs it; no default)
#   REVIEW_REPAIR_ATTEMPTS REVIEW_PROPERTY_ATTEMPTS REVIEW_INFRA_ATTEMPTS (per law; a resume may raise, never lower them)
# An option whose value is empty is not passed.
# ACQUISITION_PROFILE (a profile of config/acquisition_profiles.json) is passed by `new` only, when set; a
# run keeps its profile (a semantic input), so `resume` refuses it. Unset, the run may read no `heading_since`.
# `new` passes every one, set or defaulted. `resume` passes only those set in this invocation: every
# other option is the run's saved one (the loop keeps a run's options), so a resume never lowers or
# raises a budget, a model or an effort by itself. Raising a budget or a repair count is explicit: on `resume`,
# setting CLAUDE_BUDGET or OPENAI_BUDGET needs TOTAL_BUDGET set too; the loop records each change of a limit in
# results/<id>/limit_changes.jsonl. The coverage is fixed for the run's life. BEHAVIOUR_REVIEWER (a registered reviewer)
# is no loop option: it is passed to `stage handover --to review` and `stage enter --kind review` only, and the run's first
# review entry fixes it for the run's life; no launch passes it. The stage, the dataset folder and each launch's iteration
# bound are passed on every launch.
set -euo pipefail

ACTION=${1:-}
case "$ACTION" in new|resume|stage-enter) ;; *) echo "usage: RUN_ID=<id> $0 new|resume|stage-enter" >&2; exit 2;; esac
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
MODEL|--model|claude-opus-5-5[1m]
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
REVIEW_COVERAGE|--review_coverage|strict
REVIEW_BUDGET|--behaviour_review_budget_usd|
REVIEW_REPAIR_ATTEMPTS|--review_repair_attempts|2
REVIEW_PROPERTY_ATTEMPTS|--review_property_attempts|2
REVIEW_INFRA_ATTEMPTS|--review_infra_attempts|3
'
OPENAI_KEY_FILE=${OPENAI_KEY_FILE:-$HOME/.config/traffic-spec/openai.env}
PYTHON=${PYTHON:-python3}
PUSH_RETRIES=${PUSH_RETRIES:-5}; PUSH_WAIT=${PUSH_WAIT:-60}
RUN_DIR=results/$RUN_ID
LOG_DIR=.runtime/$RUN_ID
RUN_ROOTS=(library/TrafficSpec/Rules library/TrafficSpec/Concepts library/TrafficSpecWitness library/TrafficSpec/Gaps)   # the run's library records

die() { echo "[launcher] $*" >&2; exit "${2:-2}"; }
mkdir -p "$LOG_DIR"
EXCLUDE=$(git rev-parse --git-path info/exclude)      # the repository's own, also from a linked worktree
mkdir -p "$(dirname "$EXCLUDE")"
grep -qxF '.runtime/' "$EXCLUDE" 2>/dev/null || echo '.runtime/' >> "$EXCLUDE"   # logs stay local
log() { echo "[$(date -u +%FT%TZ)] $*" | tee -a "$LOG_DIR/launcher.log"; }

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

stage_run_files() {                                    # the listed files only, ignored ones included; deletions recorded
  local list="$RUN_DIR/handoff/files.txt"
  cp "$list" "$LOG_DIR/pathspec.txt"                   # paths relative to this directory, as git reads them here
  stage_record_files >> "$LOG_DIR/pathspec.txt"
  git add -f --pathspec-from-file="$LOG_DIR/pathspec.txt"
  git ls-files -- "$RUN_DIR" "${RUN_ROOTS[@]}" | grep -vxF -f "$LOG_DIR/pathspec.txt" \
      | while IFS= read -r gone; do git rm -q --cached -- "$gone"; done || true
}

commit_checkpoint() {
  stage_run_files
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
changes_outside_run() {                               # tracked changes, staged or not, to files a checkpoint of the run does not commit
  [ -n "$(git diff --name-only HEAD)" ] || return 0
  git diff --name-only -z HEAD | "$PYTHON" -c '
import sys
from harness.tools.handoff import artifact_files
prefix, run_id, roots = sys.argv[1], sys.argv[2], sys.argv[3:]
own = set(artifact_files(run_id))
for top in sys.stdin.read().split("\0"):
    rel = top[len(prefix):] if top.startswith(prefix) else None
    if top and (rel is None or not (rel in own or any(rel.startswith(r + "/") for r in roots))):
        print(top)' "$(git rev-parse --show-prefix)" "$RUN_ID" "$RUN_DIR" "${RUN_ROOTS[@]}"
}
stop_status() {                                        # the launcher's exit status for a loop status that ends the launches
  case "$1" in
    paused_budget|paused_defect|awaiting_operator) echo 4;;
    infrastructure_failure) echo 5;;
    *) echo 1;;
  esac
}
written() { "$PYTHON" -c 'import os,sys; p=sys.argv[1]; print(os.stat(p).st_mtime_ns if os.path.exists(p) else "none")' "$1"; }   # when the loop last wrote its status

# ---------------------------------------------------------------- stages
stage_record_files() {                                 # a staged run's stage record, snapshots and last transition state, with its checkpoint
  local f
  for f in stages.jsonl stage_transition.json; do [ ! -f "$RUN_DIR/$f" ] || echo "$RUN_DIR/$f"; done
  [ ! -d "$RUN_DIR/stages" ] || find "$RUN_DIR/stages" -type f
}
transition_field() { "$PYTHON" - "$RUN_DIR/stage_transition.json" "$1" <<'PY'
import json, sys
from pathlib import Path
f = Path(sys.argv[1])
print((json.loads(f.read_text()) if f.is_file() else {}).get(sys.argv[2]) or "")
PY
}
stage_commit() {                                       # the stage commit of a transition on this branch, by its `Stage-Transition:` line
  local c
  for c in $(git log --format=%H -F --grep="Stage-Transition: $1" HEAD); do
    if grep -qxF "Stage-Transition: $1" <<< "$(git log -1 --format=%B "$c")"; then echo "$c"; return 0; fi
  done
}

# The checks of a staged run, by this checkout's harness (the stage's own code). `resume <launch kind>`: no
# transition is short of `done`; the active stage allows the launch; the code equals the stage's code
# baseline; prints the commit the run branch must descend from with no merge after it: the transition
# commit `stage confirm` recorded, or nothing for a first stage (adopted, with no transition commit), which
# keeps the manifest's baseline commit. `enter <transition>`: the active stage was opened by that transition
# and its code baseline equals the code here; prints the stage id. A refusal is printed, with status 1.
stage_check() { "$PYTHON" - "$RUN_DIR" "$1" "$2" <<'PY'
import sys
from pathlib import Path
try:
    from harness.store import jsonl, stages
    from harness.tools.handoff import code_digest
except ImportError as e:
    print(f"the run has a stage record and this checkout's harness cannot read it ({e})"); sys.exit(1)
rd, mode, arg = Path(sys.argv[1]), sys.argv[2], sys.argv[3]


def refuse(msg):
    print(msg); sys.exit(1)


try:
    stage = stages.active_stage(rd)
except jsonl.DataIntegrityError as e:
    refuse(f"the run's stage record does not read: {e}")
if stage is None:
    refuse(f"{rd / stages.STAGES_FILE} opens no stage")
sid = stage["stage_id"]
if mode == "resume":
    why = stages.transition_refusal(rd)
    if why:
        refuse(why)
    kinds = list(stage.get("launch_kinds") or ())
    if arg not in kinds:
        refuse(f"the run's stage `{sid}` allows {' and '.join(kinds) or 'no'} launches, not STAGE={arg}: "
               "a stage of another kind is entered with stage-enter")
elif stage.get("transition_id") != arg:
    refuse(f"the run's active stage `{sid}` was not opened by the transition {arg}")
base = stage.get("code_baseline") or {}
want, have = (base.get("code") or {}).get("files") or {}, code_digest()["files"]
diff = sorted(k for k in set(want) | set(have) if want.get(k) != have.get(k))
if diff:
    more = f" and {len(diff) - 10} more" if len(diff) > 10 else ""
    refuse(f"the checkout's code differs from the code baseline of the run's stage `{sid}` ({base.get('source_commit')}): "
           f"{', '.join(diff[:10])}{more}; a stage runs only on its own code (its transition commit)")
if mode == "enter":
    print(sid)
else:
    tr = stages.transition_state(rd) or {}
    if tr.get("transition_id") == stage.get("transition_id") and tr.get("commit"):
        print(tr["commit"])
    elif stage.get("previous_stage_id") is not None:
        refuse(f"the run's stage `{sid}` has no confirmed transition commit: finish its transition with stage-enter")
PY
}

# The code files a transition to NEW_BASE replaces: every file that the new baseline's own `CODE_PATTERNS` or
# the current one's match, in NEW_BASE or at HEAD, and the doctor's split tool (`DOCTOR_TOOL`, outside the
# agent directory). The patterns are read from each commit's handoff module as literals (parsed, never
# imported: the other commit's code is not this interpreter's) and matched as `Path.glob` does against the
# commits' trees, so neither the working tree nor this checkout's patterns decide the set. A run artifact
# (the run's results, rules, concepts, witnesses, gaps) is never in it. Writes NUL-separated
# repository-relative lists: `replace` (in NEW_BASE), `delete` (not in NEW_BASE), `restore` (at HEAD) and
# `drop` (not at HEAD), the last two to undo the replacement when the harness refuses the transition.
code_plan() { "$PYTHON" - "$TOP" "$PREFIX" "$1" "$2" <<'PY'
import ast, os, posixpath, subprocess, sys
from fnmatch import fnmatchcase
top, prefix, new, out = sys.argv[1:5]
ARTIFACTS = ("results/", "library/TrafficSpec/Rules/", "library/TrafficSpec/Concepts/", "library/TrafficSpecWitness/",
             "library/TrafficSpec/Gaps/")


def git(*a):
    return subprocess.run(["git", "-C", top, *a], capture_output=True, check=True).stdout


def constants(rev):
    try:
        src = git("show", f"{rev}:{prefix}harness/tools/handoff.py")
    except subprocess.CalledProcessError:
        return {}
    found = {}
    for node in ast.parse(src).body:
        targets = node.targets if isinstance(node, ast.Assign) else [node.target] if isinstance(node, ast.AnnAssign) and node.value else []
        for t in targets:
            if isinstance(t, ast.Name) and t.id in ("CODE_PATTERNS", "DOCTOR_TOOL"):
                found[t.id] = ast.literal_eval(node.value)
    return found


def blobs(rev):
    out = set()
    for e in git("ls-tree", "-r", "-z", "--full-tree", rev).split(b"\0"):
        if e:
            meta, path = e.split(b"\t", 1)
            if meta.split()[1] == b"blob":
                out.add(os.fsdecode(path))
    return out


def matches(pat, rel):                                 # `**` is zero or more directories, any other part one name
    ps, xs = pat.split("/"), rel.split("/")

    def m(i, j):
        if i == len(ps):
            return j == len(xs)
        if ps[i] == "**":
            return any(m(i + 1, k) for k in range(j, len(xs) + 1))
        return j < len(xs) and fnmatchcase(xs[j], ps[i]) and m(i + 1, j + 1)
    return m(0, 0)


nc, hc = constants(new), constants("HEAD")
if not nc.get("CODE_PATTERNS"):
    print(f"NEW_BASE {new} has no CODE_PATTERNS in {prefix}harness/tools/handoff.py"); sys.exit(1)
patterns = set(nc["CODE_PATTERNS"]) | set(hc.get("CODE_PATTERNS") or ())
tools = {posixpath.normpath(prefix + c["DOCTOR_TOOL"]) for c in (nc, hc) if c.get("DOCTOR_TOOL")}
nb, hb = blobs(new), blobs("HEAD")


def code(path):
    if path in tools:
        return True
    rel = path[len(prefix):] if path.startswith(prefix) else None
    return rel is not None and "__pycache__" not in rel.split("/") and any(matches(p, rel) for p in patterns)


paths = sorted(p for p in nb | hb if code(p))
bad = [p for p in paths if p.startswith(prefix) and p[len(prefix):].startswith(ARTIFACTS)]
if bad:
    print(f"the code patterns match run artifacts: {', '.join(bad[:5])}"); sys.exit(1)
for name, keep in (("replace", lambda p: p in nb), ("delete", lambda p: p not in nb),
                   ("restore", lambda p: p in hb), ("drop", lambda p: p not in hb)):
    with open(os.path.join(out, name), "wb") as f:
        f.write(b"".join(os.fsencode(p) + b"\0" for p in paths if keep(p)))
PY
}
git_paths() {                                          # git <args> over a NUL-separated list of repository-relative paths, when it has any
  local list=$1; shift
  [ ! -s "$list" ] || git --literal-pathspecs -C "$TOP" "$@" --pathspec-from-file="$list" --pathspec-file-nul
}

# `stage-enter`: the run enters a new stage on the code of NEW_BASE (see the head of this file). Every step
# can be run again after a stop: the harness's transition resumes from its recorded state, the stage commit
# is found by its `Stage-Transition:` line, and a code replacement begun here on a clean checkpoint is
# recorded in the launcher's local directory, so a rerun continues it instead of refusing the changed tree.
stage_enter() {
  local new kind=${KIND:-} from=${FROM:-} trn=${TRANSITION:-} plan="$PWD/$LOG_DIR/stage-enter" c sid status tid rc
  local -a extra=()
  { [ -n "${NEW_BASE:-}" ] && [ -n "$kind" ] && [ -n "$from" ] && [ -n "$trn" ]; } || die "stage-enter needs NEW_BASE, KIND, FROM and TRANSITION"
  case "$kind" in generation|labels|review) ;; *) die "KIND must be generation, labels or review";; esac
  if [ -n "${SCOPE:-}" ]; then [ -f "$SCOPE" ] || die "SCOPE must be a file (given '$SCOPE')"; extra+=(--scope "$SCOPE"); fi
  [ -z "${PROMPTS_APPROVED:-}" ] || extra+=(--prompts_approved "$PROMPTS_APPROVED")
  [ "$kind" != review ] || [ -z "${BEHAVIOUR_REVIEWER:-}" ] || extra+=(--behaviour_reviewer "$BEHAVIOUR_REVIEWER")   # a review entry only
  "$PYTHON" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 11) else 1)' 2>/dev/null || die "$PYTHON is not Python 3.11 or newer"
  git config user.name >/dev/null && git config user.email >/dev/null || die "set git user.name and user.email"
  CURRENT=$(git symbolic-ref --quiet --short HEAD || true)
  [ "$CURRENT" = "$BRANCH" ] || die "stage-enter runs on the checked-out run branch $BRANCH (now: ${CURRENT:-detached})"
  [ -f "$RUN_DIR/state.json" ] || die "$RUN_DIR/state.json is missing: no run to move to a new stage"
  git fetch -q "$REMOTE" 2>/dev/null || die "cannot fetch from $REMOTE"
  new=$(git rev-parse -q --verify "$NEW_BASE^{commit}") || die "NEW_BASE $NEW_BASE is not a commit in this checkout (fetch it first)"
  [ "$(git ls-remote --heads "$REMOTE" "refs/heads/$BRANCH" | wc -l)" -gt 0 ] \
    || die "$BRANCH is not on $REMOTE: the run's last checkpoint is pushed before a stage transition"
  BEHIND=$(git rev-list --count "HEAD..$REMOTE/$BRANCH")
  [ "$BEHIND" -eq 0 ] || die "$REMOTE/$BRANCH has $BEHIND commit(s) this checkout lacks: another machine wrote the run; pull first"
  TOP=$(git rev-parse --show-toplevel); PREFIX=$(git rev-parse --show-prefix)
  mkdir -p "$plan"
  status=$(transition_field status) && tid=$(transition_field transition_id) || die "$RUN_DIR/stage_transition.json does not read"
  c=$(stage_commit "$trn")
  if [ -z "$c" ]; then
    [ -z "$(git rev-list "$REMOTE/$BRANCH..HEAD")" ] \
      || die "the checkpoint $(git rev-parse --short HEAD) is not on $REMOTE: push the run's last checkpoint before a stage transition"
    [ "$tid:$status" != "$trn:done" ] || die "the transition $trn is done, but its stage commit is not on this branch"
    if [ "$tid" != "$trn" ] && [ "$(cat "$plan/begun" 2>/dev/null)" != "$trn $new $(git rev-parse HEAD)" ]; then
      git diff --cached --quiet || die "the index holds staged changes; a stage transition starts from a clean checkpoint — unstage them"
      [ -z "$(git status --porcelain --untracked-files=no)" ] \
        || die "the checkout has uncommitted changes to tracked files; a stage transition starts from a clean checkpoint"
      echo "$trn $new $(git rev-parse HEAD)" > "$plan/begun"
    fi
    code_plan "$new" "$plan" > "$plan/refusal" || die "$(cat "$plan/refusal")"
    git_paths "$plan/replace" checkout -q "$new"
    git_paths "$plan/delete" rm -q -f --ignore-unmatch
    log "stage-enter $trn: the code of $new is in place ($(tr -cd '\0' < "$plan/replace" | wc -c) file(s), $(tr -cd '\0' < "$plan/delete" | wc -c) deleted)"
    if [ "$tid:$status" != "$trn:exported" ]; then
      log "stage-enter $trn: harness stage enter $RUN_ID --kind $kind --from $from"
      set +e
      "$PYTHON" -m harness stage enter "$RUN_ID" --kind "$kind" --from "$from" --transition "$trn" --source_commit "$new" \
        ${extra[@]+"${extra[@]}"} >>"$LOG_DIR/stage.log" 2>&1      # the new stage's baseline is NEW_BASE, whose clean checkout restores it
      rc=$?
      set -e
      status=$(transition_field status); tid=$(transition_field transition_id)
      if [ "$rc" -ne 0 ] && [ "$tid" = "$trn" ]; then
        log "the transition $trn stopped at \`$status\` (exit $rc; see $LOG_DIR/stage.log): run the same stage-enter again"; exit 1
      elif [ "$rc" -ne 0 ]; then                       # refused before it began: the checkpoint's code comes back
        git_paths "$plan/restore" checkout -q HEAD
        git_paths "$plan/drop" rm -q -f --ignore-unmatch
        rm -f "$plan/begun"
        die "the harness refused the transition $trn (exit $rc); the checkpoint's code is restored. $(tail -n 5 "$LOG_DIR/stage.log")"
      fi
    fi
    if [ "$tid:$status" != "$trn:exported" ]; then
      log "the transition $trn is at \`$status\` (last transition: ${tid:-none}), not \`exported\`: run the same stage-enter again"; exit 1
    fi
    sid=$(stage_check enter "$trn") || { log "$sid"; exit 1; }
    stage_run_files
    git commit -q -m "stage $sid: baseline $new" -m "$RUN_ID: $from to $sid ($kind)" -m "Stage-Transition: $trn"
    rm -f "$plan/begun"
    c=$(git rev-parse HEAD)
  else
    sid=$(git log -1 --format=%s "$c")
    case "$sid" in "stage "*": baseline $new") sid=${sid#stage }; sid=${sid%%:*};;
      *) die "the transition $trn was committed as $c on another baseline than $new ($sid)";; esac
    [ "$(git rev-list --parents -n 1 "$c" | wc -w)" -eq 2 ] && [ -z "$(git rev-list --merges "$c..HEAD")" ] \
      || die "the run branch holds a merge commit at or after the stage commit $c: development code is never merged into an active run"
    [ -z "$(git status --porcelain --untracked-files=no -- ":(top)" ":(exclude)$RUN_DIR")" ] \
      || die "the checkout has uncommitted changes to tracked files outside $RUN_DIR"
    [ "$tid" = "$trn" ] || die "the stage commit $c of the transition $trn is on this branch, but the run's last transition is ${tid:-none}"
    if [ "$status" = done ] && [ "$(transition_field commit)" != "$c" ]; then
      die "the transition $trn was confirmed at $(transition_field commit), not at its stage commit $c"
    fi
  fi
  if [ -n "$(git rev-list "$REMOTE/$BRANCH..HEAD")" ]; then log "stage-enter $trn: pushing $(git rev-parse --short HEAD)"; push_checkpoint; fi
  if [ "$status" != done ]; then
    log "stage-enter $trn: harness stage confirm $RUN_ID --transition $trn --commit $c"
    set +e
    "$PYTHON" -m harness stage confirm "$RUN_ID" --transition "$trn" --commit "$c" --remote "$REMOTE" --branch "$BRANCH" >>"$LOG_DIR/stage.log" 2>&1
    rc=$?
    set -e
    if [ "$rc" -ne 0 ] || [ "$(transition_field status):$(transition_field commit)" != "done:$c" ]; then
      log "the confirmation of $trn at $c did not finish (exit $rc; see $LOG_DIR/stage.log): run the same stage-enter again"; exit 1
    fi
  fi
  stage_run_files
  if ! git diff --cached --quiet; then git commit -q -m "$RUN_ID: stage $sid confirmed" -m "Stage-Transition-Done: $trn at $c"; fi
  if [ -n "$(git rev-list "$REMOTE/$BRANCH..HEAD")" ]; then push_checkpoint; fi
  log "stage $sid entered on $new by the transition $trn (stage commit $c): resume with RUN_ID=$RUN_ID STAGE=<a launch kind of $sid> $0 resume"
}
if [ "$ACTION" = stage-enter ]; then stage_enter; exit 0; fi   # one line: parsed whole before the code it replaces, this file included

# ---------------------------------------------------------------- preflight: nothing below spends model time
case "$STAGE" in
  generation|labels|review) ;;
  *) die "STAGE must be generation, labels or review";;
esac
if [ "$STAGE" = review ] && [ ! -f "$RUN_DIR/stages.jsonl" ]; then
  die "STAGE=review runs only in a review stage of a run with a stage record ($RUN_DIR/stages.jsonl), entered with stage-enter"
fi
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
  if given "$name" && [ -n "${!name}" ]; then LOOP_OPTS+=("$flag" "${!name}"); fi
done <<< "$OPTION_TABLE"
for v in WORKERS PLAN_BATCH GATE_BUDGET LAUNCHES PUSH_RETRIES PUSH_WAIT LABEL_REPAIR_ATTEMPTS LABEL_REPAIR_BUDGET \
         REVIEW_REPAIR_ATTEMPTS REVIEW_PROPERTY_ATTEMPTS REVIEW_INFRA_ATTEMPTS; do
  if given "$v"; then [[ ${!v} =~ ^[0-9]+$ ]] || die "$v must be a whole number (given '${!v}')"; fi
done
if given WORKERS; then [ "$WORKERS" -ge 1 ] || die "WORKERS must be at least 1"; fi
for v in SESSION_CAP REPAIR_CAP JUDGE_CAP VERIFIER_CAP CLAUDE_BUDGET OPENAI_BUDGET TOTAL_BUDGET REVIEW_BUDGET; do
  if given "$v" && { [ "$v" != REVIEW_BUDGET ] || [ -n "$REVIEW_BUDGET" ]; }; then
    "$PYTHON" -c 'import sys; from decimal import Decimal as D; x = D(sys.argv[1]); sys.exit(0 if x.is_finite() and x >= 0 else 1)' "${!v}" 2>/dev/null \
      || die "$v must be a non-negative amount in USD (given '${!v}')"
  fi
done
git config user.name >/dev/null && git config user.email >/dev/null || die "set git user.name and user.email"
if [ "$ACTION" = resume ]; then                       # a stop inside an iteration leaves the checkpoint files changed: the loop takes them up
  others=$(changes_outside_run) || die "the run's checkpoint files could not be listed (python -c \"from harness.tools.handoff import artifact_files\" failed)"
  [ -z "$others" ] || die "the checkout has uncommitted changes to tracked files outside the run's checkpoint files; use a clean, separate checkout: $(echo $others)"
else
  git diff --cached --quiet || die "the index holds staged changes; this launcher commits only the run's files — unstage them"
  [ -z "$(git status --porcelain --untracked-files=no)" ] || die "the checkout has uncommitted changes to tracked files; use a clean, separate checkout"
fi
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
"$PYTHON" -c 'import sys; from harness.store.state import Options as O; raise SystemExit(0 if set(sys.argv[1:]) <= set(O.__dataclass_fields__) else 1)' \
    label_deferred label_stage $([ "$STAGE" != review ] || echo review_stage) \
  || die "this checkout's harness lacks the stage options of STAGE=$STAGE (--label_deferred, --label_stage, --review_stage)"
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

# a run branch holds its baseline and checkpoint commits only: never development code merged in. A staged run's
# code is its active stage's baseline, put on the branch by that stage's transition commit (a first stage with
# no transition commit keeps the run's baseline commit)
ANCHOR=
if [ "$ACTION" = resume ] && [ -f "$RUN_DIR/stages.jsonl" ]; then
  ANCHOR=$(stage_check resume "$STAGE") || die "$ANCHOR"
fi
if [ -n "$ANCHOR" ]; then
  git merge-base --is-ancestor "$ANCHOR" HEAD 2>/dev/null || die "the run branch does not descend from its stage's transition commit $ANCHOR"
  [ -z "$(git rev-list --merges "$ANCHOR..HEAD")" ] \
    || die "the run branch holds a merge commit after its stage's transition commit $ANCHOR: development code is never merged into an active run (new code enters by stage-enter)"
elif [ "$ACTION" = resume ] && [ -f "$RUN_DIR/handoff/manifest.json" ]; then
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

stage_flags() {                                        # the loop's stage options for STAGE, set into STAGE_FLAGS
  case "$STAGE" in
    labels) STAGE_FLAGS=(--label_stage --label_dataset "$LABEL_DATASET");;
    review) STAGE_FLAGS=(--review_stage);;
    *) STAGE_FLAGS=(--label_deferred);;
  esac
  if [ "$ACTION" = new ]; then                         # a resume keeps the run's acceptance policy and profile
    STAGE_FLAGS=(--label_repair "${STAGE_FLAGS[@]}")
    [ -z "${ACQUISITION_PROFILE:-}" ] || STAGE_FLAGS+=(--acquisition_profile "$ACQUISITION_PROFILE")
  fi
  return 0
}
stage_flags

# A staged run at a checkpoint whose status hands it to another stage (`awaiting_review`, `awaiting_labels`)
# enters that stage here when the harness's `stage handover` finds every condition holds, and the launches go
# on in it; otherwise it waits at its checkpoint (0), or, on an active stop of the run or a round trip without
# progress, for the operator (4).
handover() {
  local to rc out
  case "$1" in awaiting_review) to=review;; *) to=labels;; esac
  if [ ! -f "$RUN_DIR/stages.jsonl" ]; then
    case "$to" in
      labels) log "generation paused awaiting label checks: run STAGE=labels on the dataset machine";;
      review) log "paused awaiting its review: run STAGE=review";;
    esac
    exit 0
  fi
  set +e
  local -a named=()
  [ "$to" != review ] || [ -z "${BEHAVIOUR_REVIEWER:-}" ] || named=(--behaviour_reviewer "$BEHAVIOUR_REVIEWER")
  out=$("$PYTHON" -m harness stage handover "$RUN_ID" --to "$to" ${LABEL_DATASET:+--dataset "$LABEL_DATASET"} \
        ${named[@]+"${named[@]}"} 2>&1)
  rc=$?
  set -e
  echo "$out" >> "$LOG_DIR/handover.log"
  case "$rc" in
    0) ;;
    1) log "status $1: the run waits at its checkpoint for the $to stage, not entered here: ${out//$'\n'/ }"; exit 0;;
    4) log "status $1: operator decision needed, the run is handed to neither stage: ${out//$'\n'/ }"; exit 4;;
    *) log "status $1: the handover check did not run (exit $rc; see $LOG_DIR/handover.log): stopped"; exit 1;;
  esac
  FROM=$("$PYTHON" -c 'import sys; from pathlib import Path; from harness.store import stages; print(stages.active_stage(Path(sys.argv[1]))["stage_id"])' "$RUN_DIR")
  KIND=$to; NEW_BASE=$(git rev-parse HEAD); TRANSITION="auto-$FROM-$to"; SCOPE=; PROMPTS_APPROVED=
  log "status $1: entering the $to stage (RUN_ID=$RUN_ID NEW_BASE=$NEW_BASE KIND=$KIND FROM=$FROM TRANSITION=$TRANSITION $0 stage-enter; run it again if this stops)"
  stage_enter                                          # its own exit status on any stop (1, 2, 3), as `stage-enter`'s
  STAGE=$to; ACTION=resume; stage_flags
}
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
  generation=$("$PYTHON" -c 'import json,sys; g=json.load(open(sys.argv[1])).get("generation") or {}; print(g.get("complete"), g.get("reason_if_null") or "")' "$RUN_DIR/summary.json" 2>/dev/null || true)
  log "loop exit $code: status $status${stop:+, stop $stop}; generation complete: ${generation:-unknown}"
  if ! "$PYTHON" -m harness handoff export "$RUN_ID" --source_baseline "$(git rev-parse HEAD)" >>"$LOG_DIR/launcher.log" 2>&1; then
    cp "$RUN_DIR/summary.json" "$LOG_DIR/diagnostics-summary.json"; tail -n 40 "$LOG_DIR/loop.log" > "$LOG_DIR/diagnostics.txt"
    rc=$(stop_status "$status")
    case "$rc" in
      4) log "no checkpoint after status $status: $(summary_field stop_reason); the iteration's work is kept for a resume";;
      5) log "no checkpoint after status $status: $(summary_field stop_reason); the iteration's work is kept for a resume";;
      *) log "no checkpoint after status $status (see $LOG_DIR/launcher.log and $LOG_DIR/diagnostics.txt): stopped";;
    esac
    exit "$rc"
  fi
  commit_checkpoint "$status${stop:+, $stop}"
  push_checkpoint
  case "$status:$stop" in
    awaiting_review:*|awaiting_labels:*) handover "$status"; continue;;
    awaiting_generation:*) log "label checks and repairs done: hand the run back to STAGE=generation"; exit 0;;
    complete:*)        log "the run is complete"; exit 0;;
    paused_budget:*)   log "paused on a budget: $(summary_field stop_reason); raise the named limit explicitly and resume"; exit 4;;
    paused_defect:*)   log "paused on a gate failure repeated across laws; find its cause before resuming: $(summary_field stop_reason)"; exit 4;;
    awaiting_operator:*) log "operator decision needed; see stop_reason and TO_USER.md: $(summary_field stop_reason)"; exit 4;;
    *:iteration_limit) continue;;
    *) cp "$RUN_DIR/summary.json" "$LOG_DIR/diagnostics-summary.json"
       log "status $status is no iteration-limit checkpoint: stopped after pushing it"; exit "$(stop_status "$status")";;
  esac
done
log "$LAUNCHES launch(es) done; resume with: RUN_ID=$RUN_ID STAGE=$STAGE $0 resume"
