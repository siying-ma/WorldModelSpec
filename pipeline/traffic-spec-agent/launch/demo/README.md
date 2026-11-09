# Demo generation run

The demo run generates the 22 demo laws. Set up the machine first, as the repository's root `README.md` describes.

## Launch

From `pipeline/traffic-spec-agent`:

```bash
bash launch/demo/launch.sh                     # RUN_ID may be set first; it defaults to demo22-<date>
```

The script writes the 22-law list and starts the launcher in the background with these settings:

| Setting | Value |
|---|---|
| Laws | the 22 demo laws |
| Claude model | `claude-opus-5[1m]` |
| OpenAI model | `gpt-6.1-sol` |
| Workers | 12 |
| Budget | Claude $350, OpenAI $25, total $375 |

The first demo took about 4 hours and spent about $220 of Claude and $1 of OpenAI. It ended at `awaiting_labels`, with 19 laws generated and 3 waiting for the laws they reference.

**What to do after it exits, how to resume and what to send back** is in the operator guide: [`REMOTE_LAUNCH.md`](../../REMOTE_LAUNCH.md).
