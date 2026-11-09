# WorldModelSpec: training-run code baseline

This branch, `remote/full-train-generation`, is the reviewed code baseline for the pipeline's **generation stage**. Each run gets its own branch `runs/<run id>`, created from this branch's tip. The launcher pushes a checkpoint commit there after every iteration. Do not commit development code to this branch or to a run branch.

The generation stage plans, codes and checks traffic laws. It reads no driving recordings. Two model services take part:

| Service | Used for | What the machine needs |
|---|---|---|
| **Claude** (Anthropic) | Planning, coding and repair sessions | The `claude` CLI on `PATH`, logged in (`claude` once, interactively) to the account that should be billed. Leave `ANTHROPIC_API_KEY` unset, or the CLI bills that key instead. |
| **OpenAI** | The concept reviewer and the aggregate verifier (`gpt-6.1-sol`), called through the OpenAI Python SDK | An API key in `~/.config/traffic-spec/openai.env` as `OPENAI_API_KEY=...`, mode 600. No Codex CLI or login is used. |

## Quick start

```bash
git clone --branch remote/full-train-generation <repository url> wms
cd wms/pipeline/traffic-spec-agent
bash setup.sh                                  # Lean toolchain and Python packages (needs Python 3.11+)
export PATH=$HOME/.elan/bin:$PATH              # and `source .venv/bin/activate` if setup.sh created one
python -m harness split                        # must print: train
(cd library && lake build && lake build monitor explain)
python -m harness doctor                       # must exit 0
```

Then start a run with the run id, law list and settings you were given:

```bash
python -m scripts.subset_laws <run id> laws/example/train/laws.jsonl <law id> ...
RUN_ID=<run id> LAWS=results/<run id>/laws/laws.jsonl <settings> \
  nohup scripts/run-generation.sh new > launch-<run id>.out 2>&1 &
```

**The full operator guide** covers the settings, budgets, resuming, exit codes and what to send back: [`pipeline/traffic-spec-agent/REMOTE_LAUNCH.md`](pipeline/traffic-spec-agent/REMOTE_LAUNCH.md).

## Notes

- The launcher checks the checkout, the tools, the Python packages and the key before it spends anything.
- A run keeps its settings: resume with `RUN_ID=<run id> scripts/run-generation.sh resume`, without setting them again.
- Do not edit files under `pipeline/traffic-spec-agent` while a run is going.
- Agent instructions for this repository are in [`CLAUDE.md`](CLAUDE.md).
