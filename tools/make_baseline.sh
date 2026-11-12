#!/usr/bin/env bash
# Build the next commit of the code baseline branch remote/full-train-generation, in a new clone, from
# fixed commits only, and check it. It pushes nothing: it prints the push command for the requester.
#
#   MAIN_SHA=<main commit> CANDIDATE_SHA=<accepted candidate commit> LAYER_SHA=<remote layer commit> \
#   BASE_TIP=<the baseline branch's current tip> OUT=<new directory> bash tools/make_baseline.sh
#
# Inputs (every commit a full 40-character id, never a branch name):
#   MAIN_SHA       the main commit that carries the accepted pipeline (MAIN_REPO, default the WorldModelSpec checkout)
#   CANDIDATE_SHA  the accepted candidate, whose root is the pipeline directory (CANDIDATE_REPO, default the scratch repo)
#   LAYER_SHA      the commit that holds the remote layer as reviewed (LAYER_REPO, default this repository)
#   BASE_TIP       the tip of remote/full-train-generation the new commit follows (fetched from BASE_REPO, the
#                  repository url; it must still be that tip, or the build stops)
#   OUT            the build clone, a new directory outside the scratch areas
#
# Steps:
#   1. MAIN_SHA's pipeline directory must be the candidate's tree exactly (git tree ids compared);
#   2. a new clone of MAIN_REPO at OUT, with no remote; BASE_TIP fetched from BASE_REPO and LAYER_SHA from
#      LAYER_REPO, each checked against the id given;
#   3. the new tree is MAIN_SHA's tree with the layer's files taken from LAYER_SHA, and only these:
#      README.md, pipeline/traffic-spec-agent/launch/,
#      tools/make_baseline.sh; it is committed with BASE_TIP as its only parent, so the push is a fast-forward
#      (the commit copies main's tree: main's commit is not thereby in the branch's history);
#   4. checks on the new commit: it differs from MAIN_SHA only in the layer's files, and its pipeline
#      directory differs from the candidate only in launch/; then in OUT the active
#      split is train, the library builds, the doctor exits 0 and the checkout stays clean;
#   5. a record (OUT.record.txt): the four input commits, the new commit, the handoff code digest and the
#      checks' results; then the push command, printed with BASE_REPO as the address: it checks that the
#      remote tip is still BASE_TIP before an ordinary push, and Git refuses a push that is not a
#      fast-forward (the check and the push are two steps, not one atomic test).
set -euo pipefail
die() { echo "make_baseline: $*" >&2; exit 2; }
MAIN_REPO=${MAIN_REPO:-/local-scratch2/sma407/WorldModelSpec}
CANDIDATE_REPO=${CANDIDATE_REPO:-/local-scratch2/sma407/scratch_core/s2/traffic-spec-agent}
LAYER_REPO=${LAYER_REPO:-$(git -C "$(dirname "$0")" rev-parse --show-toplevel)}
BASE_REPO=${BASE_REPO:?set BASE_REPO to the repository url that holds remote/full-train-generation}
BR=remote/full-train-generation
LAYER_PATHS=(README.md pipeline/traffic-spec-agent/launch tools/make_baseline.sh)
for v in MAIN_SHA CANDIDATE_SHA LAYER_SHA BASE_TIP; do
  val=${!v:-}; [[ "$val" =~ ^[0-9a-f]{40}$ ]] || die "$v must be a full 40-character commit id"
done
OUT=${OUT:?set OUT to a new directory}
case "$OUT" in */scratch_core/*|/tmp/*) die "OUT must lie outside the scratch areas";; esac
[ ! -e "$OUT" ] || die "$OUT exists: look at it, then remove it by hand"
RECORD="$OUT.record.txt"
[ ! -e "$RECORD" ] || die "$RECORD exists"
GIT_NAME=$(git -C "$MAIN_REPO" config user.name || true); GIT_NAME=${GIT_NAME:-sma407}
GIT_EMAIL=$(git -C "$MAIN_REPO" config user.email || true); GIT_EMAIL=${GIT_EMAIL:-sma407@sfu.ca}

# 1. the accepted pipeline is main's
git -C "$MAIN_REPO" cat-file -e "$MAIN_SHA^{commit}" || die "MAIN_SHA is not in $MAIN_REPO"
git -C "$CANDIDATE_REPO" cat-file -e "$CANDIDATE_SHA^{commit}" || die "CANDIDATE_SHA is not in $CANDIDATE_REPO"
MAIN_PIPE=$(git -C "$MAIN_REPO" rev-parse "$MAIN_SHA:pipeline/traffic-spec-agent")
CAND_TREE=$(git -C "$CANDIDATE_REPO" rev-parse "$CANDIDATE_SHA^{tree}")
[ "$MAIN_PIPE" = "$CAND_TREE" ] || die "main's pipeline tree ($MAIN_PIPE) is not the candidate's ($CAND_TREE)"

# 2. the clone and the fixed inputs
git clone -q --no-hardlinks --no-checkout "$MAIN_REPO" "$OUT"
cd "$OUT"
git remote remove origin
git fetch -q "$BASE_REPO" "refs/heads/$BR"
[ "$(git rev-parse FETCH_HEAD)" = "$BASE_TIP" ] || die "the remote tip of $BR is $(git rev-parse FETCH_HEAD), not BASE_TIP"
git fetch -q "$LAYER_REPO" "$LAYER_SHA" 2>/dev/null || git fetch -q "$LAYER_REPO" "+refs/heads/*:refs/layer/*"
git cat-file -e "$LAYER_SHA^{commit}" || die "LAYER_SHA is not in $LAYER_REPO"
for p in "${LAYER_PATHS[@]}"; do
  [ -n "$(git ls-tree "$LAYER_SHA" -- "$p")" ] || die "the layer commit has no $p"
done

# 3. main's tree with the layer's files, one commit on BASE_TIP
export GIT_INDEX_FILE="$OUT/.git/baseline-index"
git read-tree "$MAIN_SHA"
for p in "${LAYER_PATHS[@]}"; do
  git rm -r -q --cached --ignore-unmatch -- "$p"
  git ls-tree -r "$LAYER_SHA" -- "$p" | git update-index --index-info
done
TREE=$(git write-tree)
unset GIT_INDEX_FILE
rm -f "$OUT/.git/baseline-index"
MSG="Code baseline: main ${MAIN_SHA:0:12} (accepted candidate ${CANDIDATE_SHA:0:12}) with the remote layer ${LAYER_SHA:0:12}

The tree is main $MAIN_SHA,
whose pipeline directory is the accepted candidate $CANDIDATE_SHA,
with the layer files of $LAYER_SHA:
${LAYER_PATHS[*]}.
It follows the previous baseline tip $BASE_TIP."
NEW=$(GIT_AUTHOR_NAME="$GIT_NAME" GIT_AUTHOR_EMAIL="$GIT_EMAIL" GIT_COMMITTER_NAME="$GIT_NAME" GIT_COMMITTER_EMAIL="$GIT_EMAIL" \
      git commit-tree "$TREE" -p "$BASE_TIP" -m "$MSG")
git switch -q -c "$BR" "$NEW"

# 4. checks
allowed() { local f=$1 p; for p in "${LAYER_PATHS[@]}"; do [[ "$f" == "$p" || "$f" == "$p"/* ]] && return 0; done; return 1; }
while IFS= read -r f; do allowed "$f" || die "the new commit differs from main in $f, outside the layer"; done \
  < <(git diff --name-only "$MAIN_SHA" "$NEW")
git fetch -q "$CANDIDATE_REPO" "$CANDIDATE_SHA" 2>/dev/null || git fetch -q "$CANDIDATE_REPO" "+refs/heads/*:refs/candidate/*"
while IFS= read -r f; do
  case "$f" in launch/*) ;; *) die "the pipeline differs from the candidate in $f";; esac
done < <(git diff --name-only "$CANDIDATE_SHA" "$NEW:pipeline/traffic-spec-agent")
cd pipeline/traffic-spec-agent
export PYTHONDONTWRITEBYTECODE=1 PYTHONPATH="$OUT/pipeline/ontology_provenance${PYTHONPATH:+:$PYTHONPATH}"
SPLIT=$(python -m harness split 2>&1 | grep -xE 'train|full' | head -n 1 || true)
[ "$SPLIT" = train ] || die "the active split is '$SPLIT', not train"
(cd library && lake build && lake build monitor explain) > "$OUT.build.log" 2>&1 || die "the library does not build (see $OUT.build.log)"
python -m harness doctor > "$OUT.doctor.log" 2>&1 || die "the doctor fails (see $OUT.doctor.log)"
[ -z "$(git status --porcelain)" ] || die "the checkout is not clean after the build and the doctor: $(git status --porcelain | head -n 5 | tr '\n' ' ')"
CODE=$(python -c "from harness.tools.handoff import code_digest; print(code_digest()['digest'])")

# 5. the record and the push command
cat > "$RECORD" <<EOF
built      $(date -u +%FT%TZ) in $OUT
main       $MAIN_SHA
candidate  $CANDIDATE_SHA (pipeline tree $CAND_TREE)
layer      $LAYER_SHA
base tip   $BASE_TIP (fetched from $BASE_REPO)
new commit $NEW (tree $TREE), branch $BR in $OUT
code       $CODE (the handoff code digest)
split      $SPLIT
build      ok ($OUT.build.log)
doctor     exit 0, $(grep -E "checks pass" "$OUT.doctor.log" | tail -n 1) ($OUT.doctor.log)
checkout   clean
EOF
cat "$RECORD"
# the push command, printed only: the expected-tip check and the push use the same address (BASE_REPO)
Q_REPO=$(printf '%q' "$BASE_REPO"); Q_OUT=$(printf '%q' "$OUT")
echo
echo "To publish, after review: the check refuses when the remote tip is no longer BASE_TIP; the push itself is"
echo "an ordinary one, so Git refuses any update that is not a fast-forward (the check and the push are not atomic)."
echo "  [ \"\$(git ls-remote $Q_REPO refs/heads/$BR | cut -f1)\" = $BASE_TIP ] && \\"
echo "    git -C $Q_OUT push $Q_REPO $NEW:refs/heads/$BR"
