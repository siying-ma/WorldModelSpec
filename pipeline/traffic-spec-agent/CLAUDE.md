# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project overview

traffic-spec-agent autoformalizes natural-language traffic law into Lean 4
specifications over CARLA scene graphs. `scripts/run_spec.py` drives a
`plan → validate → code → integrate` loop: a plan agent turns law clauses into
`objectives.jsonl` nodes, one coding agent per node writes
`library/TrafficSpec/Rules/<Theme>/<Node>.lean`, and `tools/check_spec.py` is the
gate that decides acceptance. Per-node artifacts and an aggregate `summary.json`
land under `results/<run-id>/`.

## Commands

```bash
bash setup.sh                                    # elan + Lean toolchain + deps
source .venv/bin/activate

python -m scripts.run_spec init                  # verify toolchain, build Core
python -m scripts.run_spec loop --run-id first --max-iterations 2 --model opus
python -m scripts.run_spec verify                # rebuild + all scenarios, no agent
python -m scripts.run_spec doctor                # cross-check schema/prompts vs the artifacts
PYTHONPATH=.:../sg/carla_scene_graphs \
  ../sg/carla_scene_graphs/.carlasg/bin/python -m scripts.diagnostics.doctor   # + the generator checks
python -m scripts.run_spec index                 # regenerate Index.lean
python -m scripts.run_spec status --run-id first
python -m scripts.run_spec cleanup --run-id first --results

# evaluate the whole library against a real capture and diff against human labels
python -m scripts.run_spec monitor \
    --rsv-dir ../lean_repo/scene-flow-spec-lean/sceneflow_sample/data/rsv \
    --ego-log ../lean_repo/scene-flow-spec-lean/sceneflow_sample/data/ego_logs.json \
    --labels  labels/sceneflow_sample.json \
    --adapter-python $(which python)   # needs networkx to unpickle a capture
```

Run `lake` only from inside `library/`, where `lean-toolchain` pins v4.28.0. From
the repo root, elan tries to fetch its own default toolchain.

There is no Python test suite. The Lean library self-tests at build time:
`TrafficSpec/Tests/CoreArith.lean` carries the `#guard` assertions for every
Core definition that decides by arithmetic rather than by a graph lookup, and it
is a second `@[default_target]`, so `lake build` fails if any of them regresses.
They live outside `Core/` deliberately — Core is frozen before any law or
capture and carries no concrete values, but the arithmetic still has to be
pinned down somewhere that is checked.

## Architecture

### Execution flow

1. **Plan** — `phases/plan.py` captures `AUTO_NOTES.md` and `USER_HINTS.md`,
   interpolates `prompts/prompt_plan.txt` with the law corpus, a library summary,
   the predicate vocabulary and the CARLA schema, runs one `claude -p` session,
   then clears the captured feedback (only on success, so a crash preserves it).
   The agent writes `objectives.jsonl`, `PLAN.md`, and updates `PROGRESS.md`.
2. **Validate** — `plan_validate.py`, deterministic. Rejects on schema violations,
   `node_id` not equal to `<theme>/<slug>`, non-identifier theme/slug, unresolvable
   law refs, empty binders, a missing positive *or* negative scenario, or collision
   with an existing rule. On rejection it writes objections to `AUTO_NOTES.md` and
   the code phase does not run.
3. **Code** — `phases/code.py` prepares a task dir per node (node spec,
   target-file snapshot, progress log), then runs one `claude -p` session per
   node, serially. The agent loops: edit the rule file → run `check_spec.py` →
   branch on the verdict.

   Two things are deliberate here. The scope **baseline is captured at the start
   of each node's own session**, not when the iteration is prepared: sessions are
   serial, so an up-front baseline goes stale as earlier nodes land their files
   and every node after the first gets a false `SCOPE_VIOLATION` naming a
   sibling's rule. And a rejected node is **rolled back immediately**, so its file
   is not part of the library the next node is measured against.

   Acceptance is decided by `CodePhase._authorize`, not by the verdict the
   session's own gate call wrote. Both of the gate's inputs are caller-controlled
   — `--library-root` and `baseline.json` — so the harness re-checks scope against
   the manifest it captured itself and rejects an `OK` as `GATE_BYPASS` when the
   gate measured a different library, a replaced baseline, or used `--skip-build`.
4. **Integrate** — `phases/integrate.py`, deterministic. Rolls back nodes that
   never passed their gate, regenerates `Index.lean` via `index_sync.py`, builds
   the whole library, and re-runs every registered rule's scenarios. On failure it
   reverts candidates newest-first until the library verifies, and reports each
   reverted node.
5. **Feedback** — outcomes and uncovered law ids are written to `AUTO_NOTES.md`
   for the next plan phase. `summary.json` is rewritten each iteration.

### External validation (outside the loop)

`monitor` closes the loop the four phases cannot: a rule's `scenarios` are
written by the same plan agent that chose the formalization, so a misread clause
produces scenarios that agree with the misreading and the gate still prints `OK`.
`monitor` converts a real CARLA capture with `carla/adapter.py`, evaluates every
registered rule on it, and diffs the verdicts against a per-capture label file
written by a person from the footage (`labels/<capture>.json`, one verdict per
law — `compliant` / `violated` / `not_applicable`; see `scripts/diagnostics/capture_eval.py`).

Read the second summary line, not the first. A capture in which a law's situation
never arises does not test it: the report counts how many laws are *engaged and
grounded*, because a library of vacuous rules otherwise scores perfectly against
a set of `not_applicable` labels.

Resume: re-running `loop` with the same `--run-id` keeps node dirs whose
`result.json` has `success: true` and resets every other one. `--from-phase`
skips earlier phases in the first iteration.

### Key files

- `scripts/run_spec.py` — Fire CLI (`init`, `loop`, `verify`, `index`, `status`, `cleanup`)
- `scripts/loop.py` — orchestrator, iteration summaries, `summary.json`
- `scripts/state.py` — `PROGRESS.md` stage, iteration dirs, `LoopContext`
- `scripts/phases/{plan,code,integrate}.py` — the three phases
- `scripts/plan_validate.py` — deterministic plan checks, `AUTO_NOTES.md`
- `scripts/index_sync.py` — regenerates `Index.lean` from the rule files on disk
- `scripts/lean_check.py` — `lake build`, `lake env lean`, diagnostic parsing, harness generation
- `scripts/preprocessor.py` — per-node scaffolding, resume, snapshot rollback
- `scripts/runner.py` — `claude -p` invocation, usage parsing, signal handling
- `tools/check_spec.py` — **the gate**; also owns `library_manifest`, reused by the preprocessor
- `carla/schema.json` — the CARLA compatibility contract: the key partition, how to read each part of the output, coverage rules, and the caller-supplied preconditions (the grounding budget is sized by `check_spec.CAPTURE_ENTITY_CENSUS`)
- `carla/adapter.py` — RSV `.pkl` frames + ego log → a Lean `Trace`

### Lean library

`library/TrafficSpec/Core/` is frozen: agents may not edit it, and `check_spec.py`
rejects any change outside a node's own target file. Frozen also means law-free —
no statutory text, no rule named by its subject, no worked value, no reasoning
about how the specification will be scored. `run_spec doctor`'s
`frozen artifacts law-free` check enforces this over `Core/*.lean` and
`carla/schema.json`; extend its patterns rather than arguing an exception. Rule files import
`TrafficSpec.Core` and nothing else, and must declare exactly `schema`, `entry`,
and `scenarios` inside `namespace TrafficSpec.Rules.<Theme>.<Slug>`.

`Core/Grounding.lean` defines the tab-separated report (`SPAN` / `SCEN` / `GROUND` /
`FRAMES` / `CARLA` / `RESULT` lines) that `check_spec.py` parses. Changing that
format means changing `NodeReport` in `tools/check_spec.py` in the same commit.

## Conventions & constraints

- **Relation direction reads "src is ⟨rel⟩ tgt".** `Pred.behind v w` means *v* is
  behind *w*. Inverting this silently inverts a rule; it is stated in
  `Core/Vocab.lean` §5 and in the coding prompt.
- **Proximity bands are not English.** `safetyHazard` < 2 m is the *closest*;
  `near` is 10–16 m. Always use `Pred.withinMetres`.
- **`speed`/`accel`/`throttle`/`brake`/`steer`/`yaw_rate`/`hand_brake`/`reverse`/
  `at_traffic_light` exist on the ego vehicle only** — the generator calls
  `copy_carla_actor_state` and `copy_carla_control` for the ego node alone. A
  dynamics predicate on a non-ego binder is always false. Another vehicle's
  **light states** (`light_brake`, the blinkers, …) *are* available and are the
  only dynamic evidence about it.
- **Proximity and angular edges only ever connect the ego to another actor**, and
  only for the base classes `person`/`bicycle`/`car`/`motorcycle`/`bus`/`truck` —
  never two non-ego actors, never a van, never a sign or signal. Associate a
  signal or sign with a lane through `controls` / `mayAffect`. See
  `carla/schema.json` → `relation_coverage`.
- **Numeric attributes are decimal strings**, compared via `Core/Decimal.lean` in
  milli-units. Never `attrEq` a number. No `Float` anywhere. Booleans are the
  strings `"true"`/`"false"`; an absent boolean reads false.
- **Frames carry no timestamp.** A duration is a frame count at the reference
  20 Hz capture rate — `TrafficSpec.secondsToFrames`.
- Predicates live in `Core/Vocab.lean` only. A rule file that builds its own
  `Scene → Bool` test is rejected — the vocabulary is the CARLA compatibility
  boundary.
- The 18 entity types and 18 relation labels in `Core/Scene.lean` are exactly what
  the generator emits, transcribed from `carla_sgg/sgg.py`,
  `carla_sgg/sgg_abstractor.py::process_to_junction_rsv` and
  `carla_sgg/actors.py`. Do not extend `EntityType` or `RelLabel` without
  updating `carla/schema.json` and `carla/adapter.py` in the same commit, and
  cite the generator line that emits the thing you are adding.
- **`carla/schema.json` is FROZEN before the pipeline sees any law and before any
  capture exists.** It therefore carries no worked example, no reference to a
  particular rule or statute, and no figure obtained by running the simulator.
  Guidance about writing a good rule, and about what the gate rejects, belongs in
  `prompts/`, not here — a `pitfalls` section that mixed the two was removed
  because seven of its eight entries restated another section or the coding
  prompt. Everything in the file is derived from the generator source, the Lean
  Core, or the CARLA API, and cites where it comes from.
- **`carla/schema.json` partitions the generator's attribute surface into exactly
  two sides**, and nothing else: `attribute_keys` (lifted into Lean, readable
  from a rule) and `available_not_exposed` (in the data, not lifted). Disjoint
  and complete over the surface `scripts/diagnostics/sgg_surface.py` derives from
  `carla_sgg/*.py`; `run_spec doctor` fails if a key is on both sides or on
  neither. There is deliberately NO tier of absent things — such a tier can only
  be written by imagining the laws that would want them, and the schema is frozen
  before the pipeline sees any law. Absence is derived instead, via
  `deciding_unsupported`: the two sides enumerate everything that exists, so
  anything on neither does not exist. A key on the unlifted side is a
  **vocabulary gap** — extend the adapter and `Vocab.lean`; never mark the law
  unsupported.
- **`prompts/*.txt` are frozen on the same terms as Core and the schema.** A
  template is fixed before the pipeline sees a law or records a capture, so it
  carries no statutory text, no rule named by its subject, no fabricated law id,
  and no figure obtained by running the simulator — an example written from one
  statute teaches the shape of that statute's rules, and a quoted capture figure
  goes on asserting itself after a re-measurement. `run_spec doctor`'s
  `prompts law-free` check enforces this; extend its patterns rather than arguing
  an exception. Everything law- or capture-specific reaches the agent by
  interpolation instead: the corpus, the library summary, the generated
  vocabulary/binder/schema tables, and the worked-example block, which says so
  plainly when the library carries no rule yet — the state every run starts in.
- **The grounding budget is rendered into the prompts, never written into them.**
  `summarize_binders` imports `CAPTURE_ENTITY_CENSUS`, `BINDER_CENSUS_KEY` and
  `GROUNDING_BUDGET` from `tools/check_spec.py` and computes the over-budget
  binder combinations with the gate's own `predicted_groundings`, so the
  arithmetic the agent is shown and the arithmetic the gate applies cannot
  disagree. The census is a measurement of one capture: it belongs to the gate,
  and re-measuring it must not require editing a prompt.
- **The schema must never be derived from a capture.** It was once, by loading
  recorded scene graphs and collecting the keys that appeared: circular, because
  the captures come from this project's own scripts, and incomplete — it missed
  the four keys written only inside `sgg.py`'s `get_light_boxes` branch, which
  the schema then reported as absent. Derive from `carla_sgg/*.py` and the CARLA
  API, never from the recorded captures or the capture scripts beside them.
- **The gate is the sole authority, and the authority is the harness's gate call.**
  A coding agent's claim of success is worth nothing, and so is an `OK` it obtained
  by choosing what the gate measures. Never add a path by which a session can
  influence its own scope comparison, and never read acceptance straight out of
  `verdict.json` without re-checking it.
- `Index.lean` is generated. Edit rule files, then run `run_spec index`.
- **Every agent-facing list is generated from the artifact it describes, and cites it.** Entity types and relation labels come from `Core/Scene.lean`, predicates from `Core/Vocab.lean`, the formula language from `Core/Formula.lean`, binder helpers from `Core/Grounding.lean`, and the worked-example path is resolved from `Rules/**` rather than hard-coded. `carla/schema.json` keeps what only it knows — the key partition, data limits, coverage rules, preconditions — not enumerations that something else owns. `run_spec doctor` fails when a description and the thing described disagree; add a check there rather than a sentence here.
- Compilation is checked with `lake build`; the whole-library gate additionally
  runs `lake env lean` on a generated harness.
- Always pass `ensure_ascii=False` to `json.dump`/`json.dumps` — Lean sources and
  law text contain Unicode.
- `results/`, `state/`, `library/.lake/`, and generated `*harness*.lean` are run
  artifacts, not source.

## Scope

This repository is the core autoformalization loop only. Consistency proofs
between rules, defeasibility, proof obligations, a prover phase, review/
faithfulness auditing, retrieval, node deduplication, and parallel worktrees are
out of scope by design.
