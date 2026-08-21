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
python -m scripts.run_spec index                 # regenerate Index.lean
python -m scripts.run_spec status --run-id first
python -m scripts.run_spec cleanup --run-id first --results

# evaluate the whole library against a real capture and diff against human labels
python -m scripts.run_spec monitor \
    --rsv-dir ../../lean_repo/scene-flow-spec-lean/sceneflow_sample/data/rsv \
    --ego-log ../../lean_repo/scene-flow-spec-lean/sceneflow_sample/data/ego_logs.json \
    --labels  labels/sceneflow_sample.json \
    --adapter-python $(which python)   # needs networkx to unpickle a capture
```

Run `lake` only from inside `library/`, where `lean-toolchain` pins v4.28.0. From
the repo root, elan tries to fetch its own default toolchain.

There is no Python test suite. The Lean library self-tests at build time:
`Core/Decimal.lean` carries `#guard` assertions, so `lake build` fails if the
decimal parser regresses.

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
law — `compliant` / `violated` / `not_applicable`; see `scripts/capture_eval.py`).

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
- `carla/schema.json` — the CARLA compatibility contract (tier A = producible, tier B = in the sample)
- `carla/adapter.py` — RSV `.pkl` frames + ego log → a Lean `Trace`

### Lean library

`library/TrafficSpec/Core/` is frozen: agents may not edit it, and `check_spec.py`
rejects any change outside a node's own target file. Rule files import
`TrafficSpec.Core` and nothing else, and must declare exactly `schema`, `entry`,
and `scenarios` inside `namespace TrafficSpec.Rules.<Theme>.<Slug>`.

`Core/Grounding.lean` defines the tab-separated report (`SCEN` / `GROUND` /
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
- `carla/schema.json` sorts data into four availability tiers, and the difference
  between them is a decision the plan agent makes: readable now, reachable with a
  stated residue, present-but-not-lifted (a **vocabulary gap** — extend the
  adapter and `Vocab.lean`, do not mark the law unsupported), and genuinely
  absent (the only tier that justifies `unsupported`).
- **The gate is the sole authority, and the authority is the harness's gate call.**
  A coding agent's claim of success is worth nothing, and so is an `OK` it obtained
  by choosing what the gate measures. Never add a path by which a session can
  influence its own scope comparison, and never read acceptance straight out of
  `verdict.json` without re-checking it.
- `Index.lean` is generated. Edit rule files, then run `run_spec index`.
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
out of scope by design — see `../DESIGN_traffic_spec_agent.md` for how they would
attach.
