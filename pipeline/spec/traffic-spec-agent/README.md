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
    --labels  labels/sceneflow_sample.json
```

`verify` asks whether a spec passes the tests the plan agent wrote for it.
`monitor` asks whether it agrees with a person who watched the footage — the only
check in the pipeline that is independent of the agent that wrote the spec.

## Layout

```
library/TrafficSpec/         the Lean library — the product
  Core/                        frozen specification language (agents may not edit)
    Scene.lean                   CARLA entities, relations, scenes, traces
    Formula.lean                 SFProp: finite-trace LTL with a bounded operator
    Semantics.lean               eval : Trace → Nat → SFProp → Bool
    Monitor.lean                 verdicts, per-frame monitoring
    Grounding.lean               quantified schemas + the gate's report format
    Decimal.lean                 exact comparison of CARLA's float-string attributes
    Builders.lean                constructors for writing scenario traces
    Vocab.lean                   THE predicate vocabulary — rules use only this
  Carla/Sample.lean            CARLA-shaped smoke trace every rule is checked against
  Rules/<Theme>/<Node>.lean    one formalized rule per file (agent-written)
  Index.lean                   generated registry of all rules
carla/
  schema.json                  the CARLA compatibility contract
  adapter.py                   RSV scene-graph frames → a Lean Trace
laws/example/laws.jsonl        the input corpus, one clause per line
prompts/                       prompt_plan.txt, prompt_code.txt
scripts/                       the harness (never called by an agent)
tools/check_spec.py            the gate (the only thing an agent calls)
state/<run>/                   PROGRESS.md, USER_HINTS.md, AUTO_NOTES.md, iter_NNN/
results/<run>/                 per-node artifacts + summary.json
```

## The loop

```
PLAN  (1 claude -p session)
  reads  laws.jsonl, the existing library, the vocabulary, the CARLA schema,
         AUTO_NOTES.md (harness feedback), USER_HINTS.md (yours)
  writes objectives.jsonl (one node per rule), PLAN.md, PROGRESS.md
  decides: is this law formalizable against CARLA data at all? one rule or several?
           what are the positive and negative acceptance scenarios?
    ↓
VALIDATE  (deterministic — scripts/plan_validate.py)
  schema, node-id shape, law refs resolve, ≥1 positive AND ≥1 negative scenario,
  no collision with an existing rule. A bad plan writes objections to
  AUTO_NOTES.md and skips the code phase entirely.
    ↓
CODE  (1 claude -p session per node, serial)
  edit library/TrafficSpec/Rules/<Theme>/<Node>.lean → run tools/check_spec.py
  → branch on the verdict → repeat until OK
    ↓
INTEGRATE  (deterministic)
  regenerate Index.lean, build the whole library, re-run every rule's scenarios.
  A node that breaks either is reverted to its pre-session snapshot and reported.
```

Nothing stops the loop. Every failure becomes a typed note the next plan phase
consumes — that is what lets a run go unattended.

## The gate

`tools/check_spec.py` is the only path to acceptance. It prints one verdict token
on the first line, which the coding prompt branches on:

| Verdict | Meaning |
|---|---|
| `MISSING_FILE` | the rule file was not created where the plan said |
| `SCOPE_VIOLATION` | a file outside the node's target was modified |
| `STRUCTURE_FAIL` | required declarations, namespace, or a planned scenario missing |
| `VOCAB_VIOLATION` | an ad-hoc scene predicate, or a `Pred.*` that does not exist |
| `CARLA_INCOMPATIBLE` | reads scene-graph data CARLA cannot produce |
| `HYGIENE_FAIL` | `sorry` / `axiom` / `native_decide` / `partial def` |
| `COMPILE_FAIL` | Lean errors |
| `SCENARIO_VACUOUS` | a scenario grounds zero times, so it tests nothing |
| `SCENARIO_FAIL` | the specification disagrees with its acceptance tests |
| `OK` | accepted, pending integration |

Two of these carry most of the quality signal:

- **`SCENARIO_VACUOUS`** catches the dominant failure mode in this domain. A rule
  quantified over two vehicles, tested on a trace containing one, is vacuously
  satisfied — it looks correct and monitors nothing.
- **`CARLA_INCOMPATIBLE`** catches the second. A specification that reads an
  attribute the scene graph never emits can never fire. The correct response is to
  mark the law unsupported, naming the missing field — not to approximate it.

## CARLA compatibility

The vocabulary is derived from the CARLA scene-graph generator's RoadScene2Vec
abstraction (`process_to_rsv`), not from a downstream adapter, and
`carla/schema.json` records the contract. Consequences worth knowing:

- **Proximity band names do not mean what they say.** `safetyHazard` is the
  *closest* band (< 2 m); `near` is 10–16 m, the second *farthest*. Use
  `Pred.withinMetres n`.
- **The five dynamics channels (`speed`, `accel`, `throttle`, `brake`, `steer`)
  exist on the ego vehicle only.** Other actors carry `name`/`sem_class` only.
- **Numeric attributes are float-formatted strings.** `Core/Decimal.lean` parses
  them into milli-units as exact integers, so comparisons stay decidable and no
  `Float` reaches the kernel.
- **`isIn` is overloaded** across entity→lane, lane→road, road→junction. Use the
  structural predicates rather than raw edges.
- **Distance and angular edges relate the ego vehicle to others** in default
  captures, so a rule relating two non-ego actors by proximity may never ground.
- **Relation direction reads "src is ⟨rel⟩ tgt"**: `Pred.behind v w` says *v* is
  behind *w*, so in a following rule *v* is the follower. Getting this backwards
  silently inverts a rule, which is why `Core/Vocab.lean` states the convention
  and the coding prompt calls it out.

To ingest your own capture:

```bash
python3 carla/adapter.py --rsv-dir path/to/rsv --ego-log path/to/ego_logs.json \
  --output library/TrafficSpec/Carla/Captured.lean --module-name Captured
```

The adapter reports any relation label it could not map, rather than dropping it
silently.

## What is deliberately not here

Consistency proofs between rules, defeasibility and rule priorities, proof
obligations, a prover phase, review/faithfulness auditing, retrieval, a node
index with deduplication, and worktree parallelism. The design for those is in
the parent directory's `DESIGN_traffic_spec_agent.md`; this repository is the core
loop only.

Faithfulness to the statute is **not** mechanically checked, and cannot be. The
acceptance scenarios are the proxy: the plan agent derives them from the law text
before any Lean exists, and the coding agent must satisfy them without weakening
them. Each rule file also records the formalization choices the text did not
dictate, so a human can challenge a reading without re-running the pipeline.

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
