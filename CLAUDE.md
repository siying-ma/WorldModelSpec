# CLAUDE.md

> **Layout changed on 2026-09-15.** `main` now carries only `pipeline/traffic-spec-agent/`,
> which is being re-founded on a law-facing ontology — see `pipeline/CORE_V2_PLAN.md` and
> `pipeline/ALIGNMENT_AUDIT_2026-09-14.md`. The CARLA scene-graph generator
> (`pipeline/carla_scene_graphs/`), the reference Lean prototype (`pipeline/lean_repo/`), the
> label pipeline (`pipeline/evalkit/`) and the Lean repository collector (`lean_repo_collection/`)
> live on the branch `archive/carla-first-2026-09-15` of this repository, with the matching
> library state on the same-named branch of `traffic_agent_library`. Everything below this
> banner describes the archived, CARLA-first design and is to be rewritten with the redraft;
> until then, read paths that point outside `traffic-spec-agent/` as references into the archive.

Guidance for Claude Code when working in this repository.

## Working agreement

**This repository is incomplete by design and is updated continuously.** Only
the artifacts named as frozen below are finished; everywhere else, a missing
piece is work not yet done, not a decision already taken. Do not infer a design
limit from an absence, and do not describe the current contents of the library,
the law corpus, or the readings file as if they were the target.

Before changing anything, in this order:

1. **State the plan first.** Name every file you intend to touch and what the
   change is, before the first edit.
2. **Separate what exists from what does not.** For each item, say whether it is
   already implemented (name the file and line), partially implemented (say what
   is missing), or absent. A "suggestion" that restates something the repo
   already does is noise, and a plan that does not distinguish the three cannot
   be reviewed.
3. **Make the suggestion concrete.** Name the file, the function or the section,
   and every other artifact that has to change with it — a `Core` change drags
   `carla/schema.json`, `carla/adapter.py`, the prompts and `run_spec doctor`
   behind it.
4. **Only then edit**, and afterwards report what actually landed versus what
   the plan said, including anything you skipped and why.

This applies to every directory under `WorldModelSpec/`, not just to
`traffic-spec-agent`.

## Project overview

The pipeline autoformalizes natural-language traffic law into Lean 4
specifications over CARLA scene graphs, and then measures whether those
specifications actually detect violations on recorded driving.

`traffic-spec-agent/scripts/run_spec.py` drives a `plan → validate → code →
integrate` loop: a plan agent turns law clauses into `objectives.jsonl` nodes,
one coding agent per node writes a rule file plus its witness file, and
`tools/check_spec.py` is the gate that decides acceptance. Per-node artifacts and
an aggregate `summary.json` land under `results/<run-id>/`.

## Repository layout

Everything lives under `pipeline/`. The four components are separate on purpose,
and the boundary between them is what keeps a claim checkable.

| path | what it is | how to treat it |
|---|---|---|
| `pipeline/carla_scene_graphs/` | the CARLA scene-graph generator (`carla_sgg`) | **the only ground truth** for what a scene graph contains. Frozen byte-wise: read it, never edit it |
| `pipeline/lean_repo/scene-flow-spec-lean/` | the original Lean prototype that formalized CARLA traffic rules | **reference only** — borrow ideas, copy nothing |
| `pipeline/traffic-spec-agent/` | the autoformalization loop | the working repository; everything below refers to paths inside it |
| `pipeline/evalkit/` | the jurisdiction-neutral evaluation pipeline that derives ground-truth labels | the external measurement; see "Evaluation" |
| `pipeline/datasets/` | capture corpora (`sceneflowlang/`, `sgsm/`) | recorded data; never a source of schema facts |

### `lean_repo` — borrow the idea, not the code

`scene-flow-spec-lean` is the prototype this project grew out of, and it is
useful for exactly one thing: seeing how someone else shaped finite-trace
monitoring in Lean. Nothing in it is an authority here.

- **No definition, constant, threshold, predicate name, adapter mapping table,
  scenario or sample capture from it may be copied into `traffic-spec-agent`,
  and none of it may be cited as evidence for a claim about CARLA.** Its numbers
  were chosen for a prototype and its adapter was written against a different
  Lean model.
- Where a fact appears both there and in `carla_sgg/*.py`, **`carla_sgg` is the
  source, and `carla_sgg` is what the comment cites.** "The reference project
  does it this way" is not a justification for a schema entry, a vocabulary
  predicate or an adapter mapping.
- It is not on the runtime path. A command, a test or a doctor check that reads
  a file out of `lean_repo/` is a defect — the capture corpora are in
  `pipeline/datasets/` and the generator is in `pipeline/carla_scene_graphs/`.

### `carla_scene_graphs` — the generator, and the adapter that must track it

`carla/adapter.py` is the **single translation boundary** between the generator
and Lean: RSV `.pkl` frames plus an ego log become a Lean `Trace` module under
`library/TrafficSpecEval/`. Its tables are the only record of the renames, so
they are also the thing that goes stale first.

- The abstraction must be `carla_sgg.sgg_abstractor.process_to_junction_rsv`.
  It is the only one whose node naming, `special_class` attribute and
  entity → lane → road → junction `isIn` chain match this library;
  `process_to_rsv` names lanes differently and `classify` would bucket every one
  of them as `other`, silently making every lane predicate false for a whole
  capture.
- **The adapter, `carla/schema.json` and `Core/Scene.lean` are one contract in
  three files.** A generator-side label, base class or attribute key that the
  adapter learns to read must land in all three in the same commit, and the
  comment must cite the `carla_sgg` line that emits it.
- The adapter reports every attribute it saw and did not lift, under
  "attributes present but not lifted", because a silent drop there is what makes
  a plan agent believe CARLA cannot express a law. A key on the unlifted side is
  a **vocabulary gap**, not an unsupported law.
- The generator is a sibling checkout and is **not guaranteed to be present**.
  The gate must work without it (`check_spec.py` falls back to the schema's
  in-repo reason patterns); `run_spec doctor` is the place that may require it,
  and is where the two are held to each other.

## The target: all of BC MVA Part 3

The pipeline formalizes **arbitrary traffic rules**, and the target for this
project is *every* obligation in

> Motor Vehicle Act [RSBC 1996] c.318, **Part 3** (ss.119–214)
> <https://www.bclaws.gov.bc.ca/civix/document/id/complete/statreg/96318_00_multi#part3>

not one clause, and not the corpus that happens to be checked in.
`laws/example/laws.jsonl` is **one interchangeable input**, selected by
`--laws <path>`; `pipeline/evalkit/readings/bc_mva_part3.jsonl` currently carries
**10 read obligations out of roughly 96 sections**. Both numbers are the state of
the work, never the design.

What follows from this, and it constrains every suggestion made in this repo:

- **Justify a change for an arbitrary clause, not for the clause in front of
  you.** If a proposal only pays off on the corpus currently checked in, it is
  not a change to the pipeline; say so.
- **Never special-case a law.** No statute id, subject, threshold or unit may be
  written into Core, the schema, the prompts, the gate, the adapter or the
  harness. Those artifacts are frozen before the pipeline sees a law precisely so
  that this cannot happen quietly.
- **Do not tune the vocabulary to the visible corpus.** A predicate is added
  because the generator emits the evidence for it, and it is cited to the
  generator — not because a clause on the current list wants it.
- **Scale is part of the design.** ~96 sections, decomposed, is hundreds of
  nodes. A mechanism that requires a human decision per clause (a hand-written
  label, a bespoke scenario, a per-rule threshold) does not survive the target
  and should be rejected at proposal time.
- **Coverage is measured, not asserted.** The score is `evalkit report` /
  `run_spec monitor` against readings and captures, not the count of accepted
  rules over the example corpus.

## Objectivity of the documentation

Inside `pipeline/traffic-spec-agent/`, **only two kinds of file may name a
particular rule**: the law corpora under `laws/**`, and the formalized specs
themselves (`library/TrafficSpec/Rules/**` and
`library/TrafficSpecWitness/**`, including their header comments, which are
*required* to record the reading and every choice the text did not dictate).

Everywhere else — `README.md`, `INFORMATION_ORIGINS.md`, `library/README.md`,
`gaps/README.md`, `laws/*/README.md` prose about the pipeline, `prompts/*.md`,
`carla/schema.json`, `Core/*.lean` — the content must be **objective and
clause-independent**:

- no instruction, heuristic or worked example written from one statute (it
  teaches the shape of that statute's rules and biases every other clause);
- no statutory text, law id or fabricated citation;
- no figure obtained by running the simulator, and no threshold justified by
  "this is what the current corpus needs";
- a statement about the current library's contents is a *measurement with a
  date*, not guidance — if it will be wrong after the next run, either generate
  it or leave it out.

`run_spec doctor`'s `frozen artifacts law-free` and `prompts law-free` checks
enforce this over `Core/*.lean`, `carla/schema.json` and `prompts/`. Extend those
patterns rather than arguing an exception. The Markdown documents are not yet
covered by a check; hold them to the same rule by hand, and prefer adding a check
to adding a sentence.

Known outstanding violations, to fix rather than to imitate:
`library/README.md` carries a per-law fan-out table and a snapshot rule count,
and `INFORMATION_ORIGINS.md` §6 names `laws/example/laws.jsonl` as though it were
the corpus rather than the default of `--laws`.

## Commands

Run from `pipeline/traffic-spec-agent/`.

```bash
bash setup.sh                                    # elan + Lean toolchain + deps
source .venv/bin/activate

python -m scripts.run_spec init                  # verify toolchain, build Core
python -m scripts.run_spec loop --run-id first --max-iterations 2 --model opus \
    --laws laws/example/laws.jsonl               # the corpus is an argument
python -m scripts.run_spec verify                # rebuild + all scenarios, no agent
python -m scripts.run_spec doctor                # cross-check schema/prompts vs the artifacts
PYTHONPATH=.:../carla_scene_graphs \
  ../carla_scene_graphs/.carlasg/bin/python -m scripts.diagnostics.doctor   # + the generator checks
python -m scripts.run_spec index                 # regenerate Index.lean
python -m scripts.run_spec status --run-id first
python -m scripts.run_spec cleanup --run-id first --results

# evaluate the whole library against real captures and diff against labels
python -m scripts.run_spec monitor \
    --database ../carla_scene_graphs/database \
    --adapter-python $(which python)   # needs networkx to unpickle a capture

# or one capture with an external label file
python -m scripts.run_spec monitor \
    --rsv-dir <capture>/rsv --ego-log <capture>/ego_logs.json \
    --labels  <capture>/labels.json --adapter-python $(which python)
```

Derive the labels rather than writing them, from `pipeline/evalkit/`:

```bash
export PYTHONPATH=../carla_scene_graphs:../carla_scene_graphs/sim/PythonAPI/carla:.
PY=../carla_scene_graphs/.carlasg/bin/python
DS=../datasets/sceneflowlang/study_data

$PY -m evalkit report --corpus $DS --readings readings/bc_mva_part3.jsonl  # what this corpus can test
$PY -m evalkit label  --corpus $DS --readings readings/bc_mva_part3.jsonl  # L3 labels, derived
$PY -m evalkit mutate --corpus $DS --readings readings/bc_mva_part3.jsonl  # scores the dataset
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
   interpolates `prompts/prompt_plan.md` with the law corpus, a library summary,
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
   node, serially. The agent loops: edit the rule and witness files → run
   `check_spec.py` → branch on the verdict.

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

Resume: re-running `loop` with the same `--run-id` keeps node dirs whose
`result.json` has `success: true` and resets every other one. `--from-phase`
skips earlier phases in the first iteration.

### Gaps — what the pipeline cannot express yet

`gaps/ledger.jsonl` (schema and invariants in `scripts/gaps.py`) records each
thing that blocks a formalization, which layer must change to retire it
(`vocab` / `adapter` / `manifest` / `capture` / `core` / `generator` / `absent`),
and whether the question is open. A planning session may only *propose*; the
operator decides. Retiring a gap is the only automatic re-formalization trigger
in the pipeline. This is the mechanism that stops later iterations from quietly
re-deciding earlier verdicts with weaker readings, and it is what makes an
`unsupported` verdict citable and disputable instead of inherited.

### Evaluation — the external check

`verify` asks whether a spec passes the tests the plan agent wrote for it, and
that is self-referential: the same agent chose the reading and the scenarios, so
a misread clause produces scenarios that agree with the misreading and the gate
still prints `OK`. `monitor` is the only check that does not come from the agent.
It converts real captures with `carla/adapter.py`, evaluates every registered
rule, and diffs the verdicts against ground-truth labels.

Ground truth is **derived, not hand-written**, by `pipeline/evalkit/`:

```
L0  trace      rsv/*.pkl + ego_logs.json      what the monitor sees
L1  facts      facts.jsonl, law-neutral       what physically happened
L2  readings   readings/<jurisdiction>.jsonl  what the law demands   <- the only human input
L3  labels     derived                        the ground truth
```

Human effort is O(obligations) once per jurisdiction, not O(rules × captures) —
which is the only reason a target of ~96 sections is labelable at all. A
per-rule hand label would be a *second formalization* of the same statute:
agreeing with the spec would prove nothing and disagreeing would not say which
of the two is wrong. A reading quantifies the clause exactly once, in a place
both the spec and the label cite. Adding a jurisdiction re-uses every capture;
re-reading a clause relabels the whole corpus.

Read the second summary line of a `monitor` report, not the first. A capture in
which a law's situation never arises does not test it, so the report counts how
many laws are *engaged and grounded* — a library of vacuous rules otherwise
scores perfectly against a set of `not_applicable` labels. `evalkit report` says
the same thing about a corpus before any monitor is run, and names the scenarios
that would witness each uncovered obligation, so a coverage hole is a work item
rather than a percentage.

### Key files

- `scripts/run_spec.py` — Fire CLI (`init`, `loop`, `verify`, `doctor`, `monitor`, `index`, `status`, `cleanup`)
- `scripts/loop.py` — orchestrator, iteration summaries, `summary.json`
- `scripts/state.py` — `PROGRESS.md` stage, iteration dirs, `LoopContext`
- `scripts/phases/{plan,code,integrate}.py` — the three phases
- `scripts/plan_validate.py` — deterministic plan checks, `AUTO_NOTES.md`
- `scripts/gaps.py` / `gaps/ledger.jsonl` — the gap ledger, its owners and states
- `scripts/coverage.py` — which clauses of the corpus are formalized, blocked, or open
- `scripts/index_sync.py` — regenerates `Index.lean` from the rule files on disk
- `scripts/lean_check.py` — `lake build`, `lake env lean`, diagnostic parsing, harness generation
- `scripts/preprocessor.py` — per-node scaffolding, resume, snapshot rollback
- `scripts/runner.py` — `claude -p` invocation, usage parsing, signal handling
- `scripts/diagnostics/sgg_surface.py` — derives generator facts from `carla_sgg/*.py` with `ast`
- `scripts/diagnostics/doctor.py` — holds every generated description against the artifact it describes
- `scripts/diagnostics/capture_eval.py` — capture verdicts vs. labels
- `tools/check_spec.py` — **the gate**; also owns `library_manifest`, reused by the preprocessor
- `carla/schema.json` — the CARLA compatibility contract: the key partition, how to read each part of the output, coverage rules, and the caller-supplied preconditions (the grounding budget is sized by `check_spec.CAPTURE_ENTITY_CENSUS`)
- `carla/adapter.py` — RSV `.pkl` frames + ego log → a Lean `Trace`
- `perception/portability.json` — which of the generator's output a camera could
  ever recover, i.e. what survives the move from simulation to real video. Frozen
  on the same terms as the schema, and derived separately from it

### Lean library

`library/TrafficSpec/Core/` is frozen: agents may not edit it, and `check_spec.py`
rejects any change outside a node's own two files. Frozen also means law-free —
no statutory text, no rule named by its subject, no worked value, no reasoning
about how the specification will be scored. `run_spec doctor`'s
`frozen artifacts law-free` check enforces this over `Core/*.lean` and
`carla/schema.json`; extend its patterns rather than arguing an exception.

**A node is two files.**

- `library/TrafficSpec/Rules/<Theme>/<Slug>.lean` — the specification. Imports
  `TrafficSpec.Core` and nothing else, and must declare exactly `schema` and
  `entry` inside `namespace TrafficSpec.Rules.<Theme>.<Slug>`.
- `library/TrafficSpecWitness/<Theme>/<Slug>.lean` — the evidence. Imports the
  rule, and must declare `scenarios : List Scenario` inside
  `namespace TrafficSpecWitness.<Theme>.<Slug>`, containing every witness the
  plan declared with the planned `expected` value.

A witness is evidence *about* a rule, not part of it: nothing that runs the
library in an application reads one. `TrafficSpec.Index` exposes `allRules` and
`checkLibrary`; the witnesses are registered separately in
`TrafficSpecWitness.lean`, which imports the rules and is never imported by them.
Two witnesses are required — `forbid` is the only evidence anywhere that the
formula says something (a rule equivalent to `□ ⊤` grounds and holds on every
capture ever recorded), and `permit` the only evidence that the antecedent is
satisfiable and the obligation reachable.

`library/TrafficSpecEval/` is a third root, holding converted captures. It is
deliberately not under `TrafficSpec/`: the coding agents are sent into
`TrafficSpec/` to read Core and the builders, and a capture within reach of a
shell becomes an argument — "this attribute occurs in the trace, so the predicate
is not dead" is a claim about one recording dressed as a claim about the data
model. `run_spec loop` refuses to start while a converted capture sits under
`TrafficSpec/`.

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
- **`prompts/*.md` are frozen on the same terms as Core and the schema.** A
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

`traffic-spec-agent` is the core autoformalization loop only. Consistency proofs
between rules, defeasibility, proof obligations, a prover phase, review/
faithfulness auditing, retrieval, node deduplication, and parallel worktrees are
out of scope by design.

Out of scope is not the same as not yet built. The target above — every
obligation in BC MVA Part 3, measured against a derived label set — is the work
in progress, and most of it is unfinished.
