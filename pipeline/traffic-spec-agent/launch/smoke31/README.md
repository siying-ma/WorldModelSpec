# smoke31: rehearsal of the full run

smoke31 runs the 29 training laws of smoke30 through the generation stage, on the pipeline fixed after smoke30, exactly as the full run will: the same launcher, settings and checkpoints. It checks that the full run can be launched. It looks for crashes, laws stuck on other laws, cost per law, and whole themes failing. Its acceptance count is a diagnostic, not a result.

Set up the machine first, as the repository's root `README.md` describes. Every command below runs from `pipeline/traffic-spec-agent` of a clean checkout.

## 0. The account

Set the Claude account once, in the shell you launch from, before any command below. The launch and every resume must bill the same account:

```bash
export CLAUDE_CONFIG_DIR=<the config directory of the account to bill>     # leave unset for the default login
```

Both scripts clear `ANTHROPIC_API_KEY`, so no launch can bill an API key. Each script prints the account it uses: check that line.

## 1. Start the smoke (29 laws)

From a clean checkout of `remote/full-train-generation` (a new run starts from the baseline's tip on a new branch):

```bash
bash launch/smoke31/launch.sh                  # RUN_ID may be set first; it defaults to smoke31-<date>
```

| Setting | Value |
|---|---|
| Laws | 9 demo laws, 10 laws in cross-law dependency chains, 10 laws of themes the demo does not cover |
| Claude model | `claude-opus-5-5[1m]` |
| OpenAI model | `gpt-6.1-sol` |
| Workers | 12 |
| Budget for the whole smoke | Claude $400, OpenAI $25, total $425 |
| First invocation | one launch of the loop (`LAUNCHES=1`), so that a resume is rehearsed |

The first invocation usually ends at an iteration-limit checkpoint. A budget pause, an error or an early end may come first, so always read the exit status (section 2) before doing anything else.

## 2. The exit status and the watch

Each script starts the launcher in the background and returns at once. Its own status says only that the launcher started. It prints three file names:

| File | What it holds |
|---|---|
| `launch-<run id>.pid` (or `resume-<run id>-<time>.pid`) | the launcher's process id |
| `launch-<run id>.out` | the launcher's output |
| `launch-<run id>.exit` | **the launcher's exit status, written when it ends.** If the process is gone and this file is missing, the launcher was killed: report it |

Every launch also starts a read-only watcher. Every 10 minutes it appends one line to `.runtime/<run id>/watch.log`:
- the live iteration and its stage, and the laws by state (from `results/<run id>/state.json`);
- the status and stop of the last iteration that ended (from `summary.json`);
- Claude and OpenAI spend against the run's limits, settled apart from reserved (requests in flight, or of unknown cost), with `ALERT` once Claude's or the total's settled plus reserved spend passes 80%: the budget the harness enforces counts both.

When the launcher ends, the watcher logs its exit status, or `ALERT` if the launcher is gone without one. Other ways to watch it:

```bash
tail -f .runtime/<run id>/launcher.log                                        # progress, launch by launch
python -c "import json; s=json.load(open('results/<run id>/summary.json')); print(s.get('status'), s.get('stop'), s.get('stop_reason'))"
git fetch && git log --oneline origin/runs/<run id> -5                       # the pushed checkpoints
```

Do not edit any file under `pipeline/traffic-spec-agent` while the run is going.

## 3. What to do after it ends

Read the exit status in the `.exit` file, then `status` and `stop` in `results/<run id>/summary.json`:

| Exit | `status` / `stop` | What to do |
|---|---|---|
| 0 | `incomplete` / `iteration_limit` | Check the checkpoint is on `runs/<run id>`, then resume (below) |
| 0 | `awaiting_labels` | Generation can go no further here. Report to the requester; do not start any other stage |
| 0 | `complete` | Report to the requester |
| 4 | `paused_budget` | Report `stop_reason`. Resume only with the new limit the requester gives |
| 4 | `awaiting_operator` | Report `stop_reason` and `TO_USER.md`. Resume only after the requester says the decision is made |
| 1 | an error, or a stop without a pushed checkpoint | Keep the checkout as it is. Send `.runtime/<run id>/launcher.log`, `loop.log` and `diagnostics.txt`. Do not resume until the requester says so |
| 2 | refused before spending | Read the message, fix the setup, run the same command again |
| 3 | a checkpoint could not be pushed | Fix the network or credentials, then resume: it pushes the checkpoint first |

To resume, from the same checkout:

```bash
RUN_ID=<run id> bash launch/smoke31/resume.sh
```

A resume keeps every saved setting; only `LAUNCHES` (default 20) is set. To raise a budget, use exactly the limits the requester gives:

```bash
RUN_ID=<run id> CLAUDE_BUDGET=<new limit> TOTAL_BUDGET=<new limit + OpenAI limit> bash launch/smoke31/resume.sh
```

## 4. When it ends: verify the handoff

The launcher exports a handoff with every checkpoint and pushes it to `runs/<run id>`. After the last exit, verify it on a separate, fresh clone of the run branch, as the receiving machine would:

```bash
git clone --branch runs/<run id> <repository url> wms-verify
cd wms-verify/pipeline/traffic-spec-agent
bash setup.sh && (cd library && lake build && lake build monitor explain)
python -m harness handoff verify <run id> > handoff-verify-<run id>.txt 2>&1; echo "exit $?" >> handoff-verify-<run id>.txt
```

## 5. Send back

The results are pushed by the launcher: each checkpoint commit is on `runs/<run id>`. Do not push anything by hand. Send the requester:
- the run id, and every exit status with its `status` / `stop`;
- `.runtime/<run id>/watch.log`;
- `results/<run id>/summary.json` and `results/<run id>/TO_USER.md`;
- `handoff-verify-<run id>.txt`, the output of the handoff verify with its exit status. That the run branch exists is not enough.

More on each exit status is in the operator guide: [`REMOTE_LAUNCH.md`](../../REMOTE_LAUNCH.md).
