# WorldModelSpec: training-run code baseline

This branch, `remote/full-train-generation`, is the reviewed code baseline for the pipeline's **generation stage**. Each run gets its own branch `runs/<run id>`, created from this branch's tip. The launcher pushes a checkpoint commit there after every iteration. Do not commit development code to this branch or to a run branch.

The generation stage plans, codes and checks traffic laws. It reads no driving recordings. Two model services take part:

| Service | Used for | What the machine needs |
|---|---|---|
| **Claude** (Anthropic) | Planning, coding and repair sessions | The `claude` CLI on `PATH`, logged in (`claude` once, interactively) to the account that should be billed. Leave `ANTHROPIC_API_KEY` unset, or the CLI bills that key instead. |
| **OpenAI** | The concept reviewer and the aggregate verifier (`gpt-6.1-sol`), called through the OpenAI Python SDK | An API key in `~/.config/traffic-spec/openai.env` as `OPENAI_API_KEY=...`, mode 600. No Codex CLI or login is used. |

## Setup (once per machine)

```bash
git clone --branch remote/full-train-generation <repository url> wms
cd wms/pipeline/traffic-spec-agent
bash setup.sh                                  # Lean toolchain and Python packages (needs Python 3.11+)
export PATH=$HOME/.elan/bin:$PATH              # and `source .venv/bin/activate` if setup.sh created one
python -m harness split                        # must print: train
(cd library && lake build && lake build monitor explain)
python -m harness doctor                       # must exit 0
```

## The runs

Each run has its own folder under `pipeline/traffic-spec-agent/launch/`, with its settings, its budget and a script that starts it:

| Run | Laws | Guide |
|---|---|---|
| **Demo** | the 22 demo laws | [`launch/demo/README.md`](pipeline/traffic-spec-agent/launch/demo/README.md) |
| **Full training** | all 221 training laws; spans more than a week; not to be started on the current baseline | [`launch/full/README.md`](pipeline/traffic-spec-agent/launch/full/README.md) |

Start only the run you were asked for. **What to do after any exit, how to resume and what to send back** is in the operator guide: [`pipeline/traffic-spec-agent/REMOTE_LAUNCH.md`](pipeline/traffic-spec-agent/REMOTE_LAUNCH.md).

## Notes

- The launcher checks the checkout, the tools, the Python packages and the key before it spends anything.
- A run keeps its settings: on resume, set nothing but the values you are told to change.
- Do not edit files under `pipeline/traffic-spec-agent` while a run is going.
- Agent instructions for this repository are in [`CLAUDE.md`](CLAUDE.md).
