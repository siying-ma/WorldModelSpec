# Launching a generation run

This page is for whoever starts the pipeline's generation stage on a remote machine. It covers setup, the launch command, resuming, and reading the outcome.

The generation stage plans, codes and gate-checks traffic laws with Claude. It also runs two OpenAI checks, the concept review and the aggregate verifier. It reads no driving recordings, and it does not include a semantic review of each rule: that stage is not part of this pipeline yet.

## 1. Prerequisites (once per machine)

- `git` with push access to the repository, and `git config user.name` / `user.email` set.
- Python 3.11 or newer.
- The `claude` CLI on `PATH`, logged in to the account the run should bill.
  - Do not set `ANTHROPIC_API_KEY` in the launch environment: if it is set, the CLI bills that API key instead of the logged-in account.
- An OpenAI API key in `~/.config/traffic-spec/openai.env` as `OPENAI_API_KEY=...`, readable only by you. The launcher loads it and never prints or commits it.
- About 20 GB of free disk space.

```bash
git clone --branch remote/full-train-generation <repository url> wms
cd wms/pipeline/traffic-spec-agent
bash setup.sh                     # the Lean toolchain (elan) and the Python packages; safe to re-run
```

`setup.sh` runs in its own shell, so make its results visible in yours:
- add `~/.elan/bin` to `PATH`;
- if it created `.venv`, run `source .venv/bin/activate`.

Then:

```bash
python -m harness split                                  # must print: train
(cd library && lake build && lake build monitor explain)
python -m harness doctor                                 # must end with exit status 0
```

The launcher also checks the tools, the Python packages, the key and the checkout before it spends anything.

## 2. Start a run

You are given a run id, the list of law ids, and the settings. If the run covers only some laws, write its law list first:

```bash
python -m scripts.subset_laws <run id> laws/example/train/laws.jsonl <law id> <law id> ...
```

Then launch it with the given settings. Use `nohup` or `tmux`, because a run takes hours. For example:

```bash
RUN_ID=<run id> LAWS=results/<run id>/laws/laws.jsonl \
MODEL='claude-opus-5-5[1m]' REVIEWER_MODEL=gpt-6.1-sol JUDGE_EFFORT=medium WORKERS=12 \
CLAUDE_BUDGET=300 OPENAI_BUDGET=25 TOTAL_BUDGET=325 ACQUISITION_PROFILE=carla_scene_graph \
nohup scripts/run-generation.sh new > launch-<run id>.out 2>&1 &
```

After each finished iteration, the launcher commits a checkpoint to the branch `runs/<run id>` and pushes it.

**Budgets.** `CLAUDE_BUDGET`, `OPENAI_BUDGET` and `TOTAL_BUDGET` are run-wide totals. `SESSION_CAP`, `REPAIR_CAP` and `JUDGE_CAP` are per-session caps for Claude: each plan or coding session, each repair session and each judge answer reserves its cap before it starts, and the run stops before a session that would not fit. `VERIFIER_CAP` is a run-wide total for the aggregate verifier, within `OPENAI_BUDGET`. These limits let a session start only when it fits; they do not guarantee that a law is finished within them. They are not an absolute billing ceiling either: a session is checked after each of its turns, so it can exceed its cap by up to one turn, and OpenAI input is reserved from an estimate.

## 3. If it stops

Resume with the same run id from the same checkout:

```bash
RUN_ID=<run id> nohup scripts/run-generation.sh resume > resume-<run id>.out 2>&1 &
```

A resume keeps every saved setting; do not set `LAWS`, models or budgets again. Never edit files under `pipeline/traffic-spec-agent` while a run is going.

## 4. After it exits: read the status, not only the exit code

| Code | Meaning | What to do |
|---|---|---|
| 0 | A checkpoint was pushed. Not necessarily the end | Read `status` and `stop` in `results/<run id>/summary.json` (next table); `stop_reason` explains them |
| 1 | Stopped on an error, or paused without a pushed checkpoint | Keep the run directory; send `.runtime/<run id>/launcher.log` and `loop.log` |
| 2 | Refused before spending (setup or check failed) | Read the message, fix the setup, run again |
| 3 | A checkpoint could not be pushed | Check network and credentials, then `resume`; it pushes first |
| 4 | Paused for a decision at a pushed checkpoint (budget or operator) | Send `summary.json` and `TO_USER.md`; do not raise budgets yourself |

After exit 0:

| `status` / `stop` | Meaning | What to do |
|---|---|---|
| `incomplete` / `iteration_limit` | The launch count ran out with work left | `resume` |
| `awaiting_labels` | Nothing more can be generated here now. This does **not** mean every law was generated or accepted: some laws wait for others to be accepted later | Tell the requester; do not start any other stage yourself |
| `complete` | Every law reached a final state | Tell the requester |

## 5. Where to look

- Progress: `.runtime/<run id>/launcher.log`.
- The current state: `status`, `stop` and `stop_reason` in `results/<run id>/summary.json`.
- Messages for the requester: `results/<run id>/TO_USER.md`.
- Everything the requester needs arrives through the pushed `runs/<run id>` branch. Logs under `.runtime/` stay local.
