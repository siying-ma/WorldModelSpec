# WorldModelSpec: the 221-law generation run

This branch, `remote/full-train-generation`, launches one job on the server: the pipeline's generation stage over
all 221 training laws. It plans, codes and checks each law with Claude, and uses OpenAI for the concept reviewer
and the aggregate verifier. It reads no driving recordings. The run finds which laws can be formalized, which
gaps block the others, and why; it is not a final result.

## Start the job

```bash
git clone --branch remote/full-train-generation --single-branch \
  git@github.com:siying-ma/WorldModelSpec.git wms
cd wms/pipeline/traffic-spec-agent
bash setup.sh                                                   # Lean and Python packages, once per machine
git config user.name "<name>" && git config user.email "<email>"   # the run commits and pushes checkpoints
export PATH=$HOME/.elan/bin:$PATH
bash launch/full221/launch.sh
```

Before you start: log in to the Claude account to bill (`claude`, then `/login`; set `CLAUDE_CONFIG_DIR` first if
that account uses another config directory, and keep it set for every later command), and put the OpenAI key in
`~/.config/traffic-spec/openai.env` as `OPENAI_API_KEY=...` with mode 600.

`launch.sh` first runs `launch/full221/preflight.sh` (clone at the branch tip and clean, accounts and keys, tools,
disk, the 221 laws, the Lean build, the doctor). If any check fails, nothing starts: send `preflight-<run id>.txt`.

## The configuration (written in `launch/full221/launch.sh`)

| Setting | Value |
|---|---|
| Laws | all 221 laws of the training split (`laws/example/train/laws.jsonl`) |
| Stage | generation only |
| Workers | 12 Claude sessions at once |
| Claude model | `claude-opus-5-5[1m]` (planning and coding effort high, judging medium) |
| OpenAI model | `gpt-6.1-sol` for the concept reviewer and the aggregate verifier (effort high) |
| Budget limits, whole run | Claude $1,500, OpenAI $30, total $1,530; aggregate verifier $20 |
| Per-session limits | $20 per plan or coding session, $8 per repair, $2 per judge answer |

The limits stop the run before a session that would not fit; they are not raised by the operator.

## Progress and resuming

The first `launch.sh` runs one iteration, so that a resume is tried early. Each finished iteration is committed
and pushed to the branch `runs/<run id>`. The launcher runs in the background; a report line is appended every
10 minutes to `.runtime/<run id>/watch.log`, and its exit status is written to `launch-<run id>.exit` (or
`resume-<run id>-<time>.exit`) when it ends.

| Exit | `status` in `results/<run id>/summary.json` | What to do |
|---|---|---|
| 0 | `incomplete` (iteration limit) | `RUN_ID=<run id> bash launch/full221/resume.sh` |
| 0 | `awaiting_labels` or `complete` | Done: send back (below) |
| 4 | `paused_budget` or `awaiting_operator` | Stop and send back; do not resume |
| 1 | an error | Stop and send back; do not resume |
| 2 | refused before spending | Fix what the message says, run the same command again |
| 3 | a checkpoint was not pushed | Fix the network or credentials, then resume |

Report as well if there has been no new checkpoint for 8 hours while the spend in `watch.log` has not moved for
2 hours. The whole run is expected to take about a day.

## Send back

The run id, `git log --oneline origin/runs/<run id> -3`, the last `.exit` file, `results/<run id>/summary.json`,
`results/<run id>/TO_USER.md`, `.runtime/<run id>/watch.log` and `.runtime/<run id>/launcher.log`, and the output
of `bash launch/full221/watch.sh --once <run id>` (the spend). Then, on a second fresh clone of the branch
`runs/<run id>`, after `bash setup.sh`: `python -m harness handoff verify <run id>` and its output.

## Rules

- Start only this job, from a fresh clone; never edit files under `pipeline/traffic-spec-agent` while it runs.
- Never raise a budget, never force-push, never resume after exit 1 or 4 without our word.
- Never run `harness stage`, `gap decide`, `reopen`, or a labels or review stage.
- To stop the run when asked: end only the launcher process (its pid is in `launch-<run id>.pid` or
  `resume-<run id>-<time>.pid`), never the `harness loop` process; the loop finishes its iteration and stops.
