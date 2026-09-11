# traffic-spec-agent

Autoformalize natural-language traffic law into Lean 4 specifications over CARLA
scene graphs, using a Claude Code wrapper with a two-agent `plan → code →
integrate` loop.

Given a corpus of traffic-law clauses in English, a **plan agent** decides what to
formalize and how to decompose it, a **coding agent** writes one Lean rule per
planned node, and a deterministic **integrate** step lands the rules or reverts
them. Every specification is checked against the real CARLA scene-graph schema and
against acceptance scenarios derived from the law text before it is accepted.

## Quick start

```bash
bash setup.sh                       # elan + Lean toolchain + python deps
source .venv/bin/activate
python -m scripts.run_spec init
python -m scripts.run_spec loop --run-id first --max-iterations 2 --model opus
```

Inspect the result:

```bash
python -m scripts.run_spec status --run-id first
python -m scripts.run_spec verify          # rebuild + re-run all scenarios, no agent
```

Validate against a real capture, rather than against the agent's own scenarios:

```bash
python -m scripts.run_spec monitor \
    --rsv-dir <capture>/rsv --ego-log <capture>/ego_logs.json \
    --labels  <capture>/labels.json
```

`verify` asks whether a spec passes the tests the plan agent wrote for it.
`monitor` asks whether it agrees with a person who watched the footage — the only
check in the pipeline that is independent of the agent that wrote the spec.

## Commands

| Command | Purpose |
|---|---|
| `run_spec init` | check toolchain, build the core, create state |
| `run_spec loop` | the plan → code → integrate loop |
| `run_spec verify` | rebuild and re-run all scenarios, no agent |
| `run_spec index` | regenerate `Index.lean` from the rule files |
| `run_spec status` | what is in the library, and where the run stands |
| `run_spec cleanup` | remove generated harnesses (and optionally a run's results) |

Useful flags on `loop`: `--max-iterations`, `--max-nodes-per-iter`, `--model`
(`opus`/`sonnet`/`haiku`/`fable` or a full id), `--effort`, `--max-turns`,
`--timeout-minutes`, `--max-budget-usd`, `--from-phase {plan,code,integrate}`,
`--dry-run`.

Re-running `loop` with the same `--run-id` resumes: nodes whose `result.json`
says `success: true` are kept, everything else is reset and re-prepared.
