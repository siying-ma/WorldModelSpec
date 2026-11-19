# WorldModelSpec: the full training-split generation run

This branch, `remote/full-train-generation`, launches one job on the server: the pipeline's generation stage over
all 224 laws of the training split. It plans, codes and checks each law with Claude, and uses OpenAI for the concept reviewer
and the aggregate verifier. It reads no driving recordings. The run finds which laws can be formalized, which
gaps block the others, and why; it is not a final result.

## Start the job

```bash
git clone --branch remote/full-train-generation \
  git@github.com:siying-ma/WorldModelSpec.git
cd WorldModelSpec/pipeline/traffic-spec-agent
bash setup.sh                                                   # Lean and Python packages, once per machine
git config user.name "<name>" && git config user.email "<email>"   # the run commits and pushes checkpoints
export PATH=$HOME/.elan/bin:$PATH
bash launch/full221/launch.sh
```

Before you start: the server needs git, curl and Python 3.11 or newer as `python3` (`setup.sh` checks it). Log in to the Claude account to bill (`claude`, then `/login`; set `CLAUDE_CONFIG_DIR` first if
that account uses another config directory, and keep it set for every later command), and put the OpenAI key in
`~/.config/traffic-spec/openai.env` as `OPENAI_API_KEY=...` with mode 600. Set `TMPDIR` to a directory outside
the clone (for example `export TMPDIR=$HOME/tmp`) and keep it set for every later command: the claude CLI writes
its task output there, and inside the clone the coding gate reads it as a change to the tree.

`launch.sh` first runs `launch/full221/preflight.sh` (clone at the branch tip and clean, accounts and keys, tools,
disk, the 224 laws, TMPDIR outside the clone, the Lean build, the doctor). If any check fails, nothing starts: send `preflight-<run id>.txt`.
Keep the clone's normal all-branch fetch configuration: the launcher needs `origin/runs/<run id>` after each
checkpoint to verify the run branch and to resume after a failed push. Do not clone with `--single-branch`.

## The configuration (written in `launch/full221/launch.sh`)

| Setting | Value |
|---|---|
| Laws | all 224 laws of the training split (`laws/example/train/laws.jsonl`) |
| Stage | generation only; the run records that its laws need a review before any label check, and no reviewer is named here |
| Workers | 16 Claude sessions at once |
| Claude model | `claude-opus-5-5[1m]` (planning and coding effort high, judging medium) |
| OpenAI model | `gpt-6.1-sol` for the concept reviewer and the aggregate verifier (effort high) |
| Budget limits, whole run | Claude $1,500, OpenAI $30, total $1,530; aggregate verifier $20 |
| Per-session limits | $20 per plan or coding session, $8 per repair, $2 per judge answer |

The limits stop the run before a session that would not fit; they are not raised by the operator.

The reviewer and verifier models are the only settings taken from the shell, at launch. To name them through a
gateway, for example:

```bash
REVIEWER_MODEL=openai:openai/openai/gpt-6.1-sol VERIFIER_MODEL=openai:openai/openai/gpt-6.1-sol bash launch/full221/launch.sh
```

Each may be set independently (an unset one stays `gpt-6.1-sol`); a gateway name needs the `openai:` prefix, its
price row in `config/model_prices.json` is keyed by the name without the prefix, and a resume keeps the run's saved
models (`resume.sh` refuses either variable set in the shell).

## Progress and resuming

The job runs by itself until generation has nothing left to do; no step needs you in between. The launcher runs
in the background (closing the terminal does not stop it). Each finished iteration is committed and pushed to the
branch `runs/<run id>`; a report line is appended every 10 minutes to `.runtime/<run id>/watch.log`; when the
launcher ends, its exit status is written to `launch-<run id>.exit` (after a resume, to that resume's
`resume-<run id>-<time>.exit`).

| Exit | `status` in `results/<run id>/summary.json` | What to do |
|---|---|---|
| 0 | `awaiting_review`, `awaiting_labels` or `complete` | Done (the normal end): send back (below). `awaiting_review` is the expected end: the run waits at its checkpoint for the review stage, which is not run here |
| 0 | `incomplete` (the 40-iteration safety bound was used up) | Send back; do not resume without our word |
| 4 | `paused_budget`, `paused_defect`, `awaiting_operator`, or a handover that needs the operator (`.runtime/<run id>/launcher.log`) | Stop and send back; do not resume |
| 5 | `infrastructure_failure`: something the iteration needs did not run; `stop_reason` in `summary.json` (also the last line of `.runtime/<run id>/launcher.log`) says what | Resume yourself only when `stop_reason` reads `<…> session could not be launched: …` followed by `rate limit`, `session refused` (a usage, weekly, daily or session limit, overloaded, credit balance) or `API error`: wait until that has cleared, then `RUN_ID=<run id> bash launch/full221/resume.sh`. Any other reason, `no result line` included (the CLI may have crashed or been killed), or 5 again at once after a resume: stop and send back |
| 1 | an error | Stop and send back; do not resume |
| 143 | the launcher was ended (as below, when we asked) | Resume only when we ask |
| 2 | refused before spending | Fix what the message says, run the same command again |
| 3 | a checkpoint was not pushed | Fix the network or credentials, then `RUN_ID=<run id> bash launch/full221/resume.sh` |
| none | no `.exit` file: the server restarted, or a process was killed | `RUN_ID=<run id> bash launch/full221/resume.sh` from the same clone. It first checks that nothing of the run still runs (its launcher, its `harness loop`, or a Claude session or any process working under `results/<run id>/`); otherwise it refuses with exit 2 and lists them. Wait until they have ended (a loop left alone finishes its iteration) and run it again; if a listed process does not end and you cannot tell why, stop and send back |

A stop inside an iteration leaves that iteration's files changed in the clone: leave them as they are. The
resume continues the iteration from them. It accepts changes only to the files a checkpoint of the run commits
(the run's results and the library's rule, concept, witness and gap records) and refuses a change to any other
file; it cannot tell which run wrote a record, so this clone serves this run only.

Report as well if there has been no new checkpoint for 8 hours while the spend in `watch.log` has not moved for
2 hours. The whole run is expected to take about a day.

## Send back

The run id, `git log --oneline origin/runs/<run id> -3`, the last `.exit` file, `results/<run id>/summary.json`,
`results/<run id>/TO_USER.md`, `.runtime/<run id>/watch.log` and `.runtime/<run id>/launcher.log`, and the output
of `bash launch/full221/watch.sh --once <run id>` (the spend). Then, on a second fresh clone of the branch
`runs/<run id>`, after `bash setup.sh`: `python3 -m harness handoff verify <run id>` and its output.

## Rules

- Start only this job, from a fresh clone; never edit files under `pipeline/traffic-spec-agent` while it runs.
- One operator works this clone, one command at a time: `resume.sh` checks for the run's processes and then
  starts, with no lock between the two, so it does not guard against two resumes typed at the same moment.
- Never raise a budget, never force-push, never resume after exit 1 or 4 without our word.
- Never run `harness stage`, `gap decide`, `reopen`, or a labels or review stage.
- To stop the run when asked: `kill <pid>` with the pid in the newest `launch-<run id>.pid` or
  `resume-<run id>-<time>.pid` (the launcher itself; its `.exit` then reads 143), never the `harness loop`
  process; the loop finishes its iteration and stops, and `resume.sh` continues it when we ask (it waits
  until that loop has ended).
