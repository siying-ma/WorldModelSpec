# full221: the 221-law gap-discovery run

This is the runbook for the remote operator. It assumes you know shell and git, not this pipeline. Follow it in order and copy the commands as they are. When something here does not match what you see, stop and ask the requester: do not improvise.

## 1. What the run is, and what it is not

**It is** the pipeline's **generation stage only** (the run's first stage, `G0`) over all 221 laws of the training split (`laws/example/train/laws.jsonl`). Claude sessions plan, code and gate-check each law; two OpenAI checks (the concept review and the aggregate verifier) run beside them. It is a **discovery run**: it records which laws generate, which gaps are filed, which laws a gap blocks or a dependency holds, and where sessions fail.

**It ends normally at `awaiting_labels`**: nothing more can be generated without a later stage. That is the expected end, not an error. Many laws will be blocked or held at that point; that is what the run is meant to show.

**It is not** a training result, and it reads no driving recordings. You never start a labels or review stage, and you never decide anything for the pipeline (section 8).

Every checkpoint is committed and pushed by the launcher to the branch `runs/<run id>`. You push nothing by hand.

## 2. What the requester gives you

| Item | Example form | Used in |
|---|---|---|
| The repository url | `git@github.com:...` | setup |
| `EXPECTED_BASELINE`: the commit of `remote/full-train-generation` to run | 40 hex characters | preflight, launch |
| The Claude account: the value of `CLAUDE_CONFIG_DIR` | `~/.claude-acct2` | everything |
| `CLAUDE_BUDGET`, `OPENAI_BUDGET`, `TOTAL_BUDGET`, `VERIFIER_CAP` (USD) | four amounts | launch |

If any of these is missing, ask before going further. **There is no default run budget**: `launch.sh` refuses without all four amounts.

## 3. Setup, then preflight

### 3.1 Setup (once)

Do the setup in the repository's root `README.md` first ("Setup (once per machine)"), on a **new, separate clone** used for this run only. Then, in that clone, make the account and tools visible in **the shell you will launch from**. Use the same shell (or the same exports) for every command below:

```bash
cd wms/pipeline/traffic-spec-agent
export PATH=$HOME/.elan/bin:$PATH                      # and: source .venv/bin/activate   (if setup.sh created .venv)
export CLAUDE_CONFIG_DIR=<the value the requester gave>
unset ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_BASE_URL ANTHROPIC_VERTEX_BASE_URL ANTHROPIC_BEDROCK_BASE_URL
unset CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
export RUN_ID=full221-$(date +%m%d-%H%M)               # once; write it down: it names the run everywhere
export EXPECTED_BASELINE=<the commit the requester gave>
```

If the account is not logged in yet: run `claude` once in this shell, use `/login`, then `/exit`.

### 3.2 Preflight (must pass before any launch)

```bash
set -o pipefail
bash launch/full221/preflight.sh 2>&1 | tee preflight-$RUN_ID.txt
```

It calls no model and changes no tracked file. Each line says `PASS` or `FAIL` (`INFO` lines are for the record). It checks: the clone is at `EXPECTED_BASELINE` and so is `origin/remote/full-train-generation`; nothing tracked is changed; `runs/$RUN_ID` and `results/$RUN_ID` do not exist yet and a dry-run push is accepted; your git identity; `CLAUDE_CONFIG_DIR` and **the account it bills (check the printed e-mail and plan with the requester)**; `ANTHROPIC_API_KEY` unset; the OpenAI key file (never printed); `claude`, Python, Lean; that this launcher runs staged runs; that no other `harness loop` runs under your user; free disk (20 GB here, 5 GB for `CLAUDE_CONFIG_DIR`); the training split and its 221 laws; `lake build` (a few minutes on a fresh clone; the time is printed); the doctor; and that the checkout is still clean afterwards.

It ends with `preflight: all checks passed` and exit status 0, or with the number of failures. Fix a setup failure (PATH, identity, key file, login) and run it again. **Any failure about the commit, the remote, the stage support or the law count: stop and send `preflight-$RUN_ID.txt` to the requester.**

## 4. Start the run

In the same shell, with the four amounts the requester gave:

```bash
CLAUDE_BUDGET=<usd> OPENAI_BUDGET=<usd> TOTAL_BUDGET=<usd> VERIFIER_CAP=<usd> bash launch/full221/launch.sh
```

It returns at once: the launcher runs in the background, in its own session, so closing the terminal or the ssh connection does not stop it. Check the printed `claude account` line and the limits.

| Setting | Value |
|---|---|
| Laws | the training split, 221 laws (no subset) |
| Stage | generation (`G0`), opened by the launcher on the first launch |
| Claude model | `claude-opus-5-5[1m]` |
| OpenAI model | `gpt-6.1-sol` (concept review and aggregate verifier) |
| Workers | 12 parallel sessions initially |
| Pipeline admission limits for the whole run | `CLAUDE_BUDGET`, `OPENAI_BUDGET`, `TOTAL_BUDGET` as given; **never raised by you**. A Claude session can exceed its reserved cap by one turn, so these are not absolute billing ceilings |
| Per-session caps | the launcher's defaults (Claude $20 per plan or coding session, $8 per repair, $2 per judge), unless the requester gives `SESSION_CAP`, `REPAIR_CAP` or `JUDGE_CAP` for the launch |
| Aggregate verifier cap | `VERIFIER_CAP` as given; it is part of the OpenAI and total limits |
| First invocation | one launch of the loop (`LAUNCHES=1`), to rehearse a resume |
| Expected duration | about 1 to 1.3 days in all (an estimate) |
| Checkpoints | one after every iteration of the loop, pushed to `runs/$RUN_ID`. The first iteration is the longest (it plans all 221 laws); expect a checkpoint every few hours after that |

**First invocation.** It ends after the first iteration, normally with exit 0 and `incomplete` / `iteration_limit`. Check that the checkpoint is pushed (section 5), then resume with more launches (section 7):

```bash
LAUNCHES=30 bash launch/full221/resume.sh
```

Each later invocation runs up to `LAUNCHES` iterations, pushing a checkpoint after each, and usually ends at `awaiting_labels`.

## 5. Watching it

The launch prints three files, named `launch-$RUN_ID.*` (or `resume-$RUN_ID-<time>.*` for a resume), in `pipeline/traffic-spec-agent`:

| File | What it holds |
|---|---|
| `.pid` | the process id of this launch (a small wrapper around the launcher) |
| `.out` | the launcher's output |
| `.exit` | **the launcher's exit status, written when it ends.** If the process is gone and this file is missing, the launcher was killed: report it |

A watcher appends one line every 10 minutes to `.runtime/$RUN_ID/watch.log`: the run's stage (must read `G0`), the iteration and its step, the laws by state, how the last iteration ended, and the spend against the limits (settled apart from reserved: reserved is money held for requests still running). Useful commands:

```bash
tail -n 3 .runtime/$RUN_ID/watch.log                     # the latest reports
tail -f .runtime/$RUN_ID/launcher.log                    # progress, launch by launch (Ctrl-C stops only tail)
bash launch/full221/watch.sh --once $RUN_ID              # one report now
git fetch -q origin && git log --oneline origin/runs/$RUN_ID -5   # the pushed checkpoints
```

What an `ALERT` in `watch.log` means, and what to do:

| `ALERT` | Meaning | What to do |
|---|---|---|
| `ALERT claude ...`, `ALERT openai ...`, `ALERT total ...` | Settled plus reserved spend passed 80% of that limit; the run will pause at the limit | Tell the requester now. Do nothing to the run |
| `ALERT verifier ...` | The aggregate verifier's run-wide cap is 80% used | Tell the requester now. Do nothing to the run |
| `ALERT launcher <pid> is gone and wrote no exit status` | The launcher was killed (a reboot, the OOM killer, someone's `kill`) | Do not resume. Send the files of section 10 with this line |

Also report, without touching the run: a `run stage` other than `G0` (or `unreadable`); no new checkpoint on `origin/runs/$RUN_ID` for 8 hours while the spend in `watch.log` has not moved for 2 hours.

## 6. After it ends: the exit status

Read the `.exit` file of the launch, then `status` and `stop`:

```bash
cat launch-$RUN_ID.exit resume-$RUN_ID-*.exit 2>/dev/null   # the last one is the latest
python -c "import json; s=json.load(open('results/$RUN_ID/summary.json')); print(s.get('status'), s.get('stop'), s.get('stop_reason'))"
```

| Exit | `status` / `stop` | Meaning | What to do |
|---|---|---|---|
| 0 | `incomplete` / `iteration_limit` | The launch count ran out with work left | Check the checkpoint is on `origin/runs/$RUN_ID`, then resume (section 7) |
| 0 | `awaiting_labels` | **Done.** Generation can go no further in this stage | Verify the handoff (section 9), send back (section 10). Do not start any other stage |
| 0 | `complete` | Every law reached a final state (not expected here) | Same as `awaiting_labels` |
| 4 | `paused_budget` | A limit was reached | **Stop and report** `stop_reason` and `TO_USER.md`. Do not resume, do not raise a limit, do not change any law |
| 4 | `awaiting_operator` | The pipeline needs a decision | Report `stop_reason` and `TO_USER.md`. Resume only after the requester says the decision is made |
| 1 | an error, or a stop without a pushed checkpoint | Something failed | Keep the checkout exactly as it is. Send `.runtime/$RUN_ID/launcher.log`, `loop.log`, `diagnostics.txt` (and `diagnostics-summary.json` if present). **Never resume without the requester** |
| 2 | refused before spending | A check failed before any model call | Read the message. A setup problem (PATH, key, identity, login): fix it and run the same command again. Anything about the run, its branch or its stage: report it |
| 3 | a checkpoint could not be pushed | Network or credentials | Fix them, then resume: it pushes the same checkpoint first |
| 143 | stopped by a signal | The launcher was stopped (section 11) | Report; do not resume unless told |

## 7. Resuming: when, and when not

Resume **only** after exit 0 with `iteration_limit`, after exit 3 once the push works again, or when the requester tells you to. From the same checkout and shell (the launcher left it on the branch `runs/$RUN_ID`):

```bash
LAUNCHES=30 bash launch/full221/resume.sh
```

A resume keeps every saved setting of the run. `resume.sh` refuses if a budget, model, law, stage or cap variable is set in your shell: unset it, never change it. `WORKERS=<n>` may be set on a resume only when the requester asks for fewer workers (for example after rate-limit errors).

Do **not** resume after exit 1, exit 4 `paused_budget`, a killed launcher, a stop you made (143), or `awaiting_labels`.

## 8. Never

- Never start a labels or review stage (`STAGE=labels`, `STAGE=review`), never run `scripts/run-generation.sh stage-enter` or `python -m harness stage ...`.
- Never decide a gap (`python -m harness gap decide`), never `python -m harness reopen`, never run `init`.
- Never raise or set a budget after the launch; never resume after `paused_budget`.
- Never resume after exit 1 without the requester.
- Never edit, add or delete files under `pipeline/traffic-spec-agent` while the run is going (the logs the scripts write are fine); never `git checkout`, `git reset`, `git clean`, `git stash`, `git pull` or `git gc` in this clone while it runs.
- Never push by hand, never force-push, never delete or rewrite `runs/$RUN_ID`.
- Never run the same run from two checkouts, and never start a second run on this account while this one runs.
- Never kill the `harness loop` or `claude` processes (section 11 is the only stop).

## 9. When it ends: verify the handoff on a second, fresh clone

After the last exit (`awaiting_labels` or as the requester says), verify what was pushed, as the receiving machine will:

```bash
cd ~                                                     # outside the run's clone
git clone --branch runs/$RUN_ID <repository url> wms-verify-$RUN_ID
cd wms-verify-$RUN_ID/pipeline/traffic-spec-agent
bash setup.sh && export PATH=$HOME/.elan/bin:$PATH        # and: source .venv/bin/activate   (if created)
export PYTHONDONTWRITEBYTECODE=1 PYTHONPATH=$(cd .. && pwd)/ontology_provenance
(cd library && lake build && lake build monitor explain)
{ git log -1 --format='verified commit %H'; python -m harness handoff verify $RUN_ID; echo "exit $?"; } > handoff-verify-$RUN_ID.txt 2>&1
cat handoff-verify-$RUN_ID.txt                           # must show a line starting "verified", then "exit 0"
```

The commit printed must be the last checkpoint (`git rev-parse origin/runs/$RUN_ID` in the run's clone). Copy `handoff-verify-$RUN_ID.txt` into the folder of section 10. The verify clone can be deleted after the requester confirms receipt.

## 10. What to send back

From `pipeline/traffic-spec-agent` of the run's clone, in the run's shell:

```bash
B=sendback-$RUN_ID; mkdir -p $B
cp results/$RUN_ID/summary.json results/$RUN_ID/TO_USER.md $B/
cp .runtime/$RUN_ID/watch.log .runtime/$RUN_ID/launcher.log $B/
cp launch-$RUN_ID.* resume-$RUN_ID-*.* preflight-$RUN_ID.txt $B/ 2>/dev/null
cp .runtime/$RUN_ID/loop.log .runtime/$RUN_ID/diagnostics*.* $B/ 2>/dev/null       # after exit 1 only; harmless otherwise
bash launch/full221/watch.sh --once $RUN_ID > $B/usage-totals.txt                  # spend from usage.jsonl, settled and reserved
git fetch -q origin
{ echo "run id      $RUN_ID"; echo "local HEAD  $(git rev-parse HEAD)"; echo "pushed tip  $(git rev-parse origin/runs/$RUN_ID)";
  git log --format='%h %ad %s' --date=iso origin/runs/$RUN_ID -40; } > $B/checkpoints.txt
cp ~/wms-verify-$RUN_ID/pipeline/traffic-spec-agent/handoff-verify-$RUN_ID.txt $B/ 2>/dev/null
tar czf $B.tar.gz $B && ls -l $B.tar.gz
```

Send `sendback-$RUN_ID.tar.gz` and, in the message:
- the run id;
- the last pushed checkpoint commit (`pushed tip` in `checkpoints.txt`), and whether `local HEAD` equals it;
- every exit status with its `status` / `stop` (in order);
- confirmation that `git log origin/runs/$RUN_ID` shows the checkpoints (one per iteration);
- the handoff verify result (`verified`, exit 0, or the refusals);
- anything you did that this runbook does not describe.

The tarball holds `summary.json`, `TO_USER.md`, `watch.log`, `launcher.log`, the `.exit`, `.out` and `.pid` files, the preflight output, the `usage.jsonl` totals, the checkpoint list and the handoff verify output. Everything else the requester needs is on `runs/$RUN_ID`.

## 11. Stopping safely, only if the requester asks

The only safe stop ends **the launcher's bash process** while the loop is in the middle of an iteration, after the last checkpoint is on the remote. The loop then finishes its current iteration and exits by itself; that iteration's results stay local and unpushed; no new launch starts. Never kill the `harness loop` or a `claude` process, and never stop while the launcher is exporting, committing or pushing.

```bash
P=$(cat "$(ls -t launch-$RUN_ID.pid resume-$RUN_ID-*.pid 2>/dev/null | head -n 1)")   # the latest launch
L=$(pgrep -P "$P" -f run-generation.sh); echo "launcher: $L"           # must print one pid
pgrep -P "$L" -af '[h]arness loop'                                       # must print one line: the loop is mid-iteration
git fetch -q origin && git rev-parse HEAD origin/runs/$RUN_ID          # the two ids must be equal: the last checkpoint is pushed
```

If any of the three does not hold (no loop line: the launcher is between iterations), wait a few minutes and check again. When all three hold:

```bash
kill -TERM "$L"                                                        # the launcher's bash only
while pgrep -u "$(id -u)" -f "[h]arness loop --run_id $RUN_ID" >/dev/null; do sleep 60; done; echo "loop ended"
```

The launch's `.exit` file then reads `143`. Wait for `loop ended` (it can take hours), then send section 10's files, saying that you stopped it and when. Do not resume.

## 12. Disk and process hygiene

- Check free space now and then: `df -h . "$CLAUDE_CONFIG_DIR"`. Report when either falls under 10 GB; do not delete anything to make room.
- Never delete `results/`, `.runtime/`, `library/.lake`, the `.pid`/`.out`/`.exit` files or `CLAUDE_CONFIG_DIR`'s session files while the run lives, nor after it until the requester confirms receipt.
- Do not run other heavy jobs on the machine during the run; the run uses 16 parallel sessions and Lean builds.
- See what runs: `pgrep -af '[r]un-generation.sh|[h]arness loop|[w]atch.sh'`. One launcher, one loop and one watcher at a time is normal; anything more, report.
- After the requester confirms receipt, they will tell you what to keep; the run's clone stays until then.

More on the launcher's exit statuses: [`REMOTE_LAUNCH.md`](../../REMOTE_LAUNCH.md). Where this page and that one differ, this page governs for this run.
