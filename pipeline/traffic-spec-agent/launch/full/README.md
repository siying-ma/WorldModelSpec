# Full training generation run

The full run generates all 221 laws of the training split. Set up the machine first, as the repository's root `README.md` describes.

> **Do not launch this run on the current baseline.** This branch will be rebuilt on newer pipeline code before the full run. The requester will tell you when it is ready.

## Launch

From `pipeline/traffic-spec-agent`:

```bash
bash launch/full/launch.sh                     # RUN_ID may be set first; it defaults to fulltrain-<date>
```

The script starts the launcher in the background over the whole training split, with these settings:

| Setting | Value |
|---|---|
| Laws | the training split, 221 laws (`laws/example/train/laws.jsonl`) |
| Claude model | `claude-opus-5[1m]` |
| OpenAI model | `gpt-6.1-sol` |
| Workers | 12 |
| Launches per invocation | 40 |
| Budget for the whole run | Claude $2,500, OpenAI $40, total $2,540 |

## Budget

The whole split is estimated at $2,000–2,500 of Claude and about $10 of OpenAI; the limits above are the whole run's.

If a limit is reached, the run stops at a pushed checkpoint with **exit status 4** (`paused_budget`). Do not raise the limit yourself: the requester tells you the new limit, and you resume with it:

```bash
RUN_ID=<run id> CLAUDE_BUDGET=<new limit> TOTAL_BUDGET=<new limit + 40> \
  nohup scripts/run-generation.sh resume > resume-<run id>.out 2>&1 &
```

**What to do after any exit, how to resume and what to send back** is in the operator guide: [`REMOTE_LAUNCH.md`](../../REMOTE_LAUNCH.md).
