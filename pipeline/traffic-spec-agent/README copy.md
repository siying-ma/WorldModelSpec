# `Rules/` — the autoformalized library

Every file under this directory was written by a **coding agent**, one file per
session, from a node a **plan agent** had already decided on. Nothing here is
hand-authored, and nothing here was accepted on an agent's own word: acceptance
is `tools/check_spec.py` printing `OK`, re-checked afterwards by
`CodePhase._authorize`.

This document records what the two prompts fix about these files, so a reader can
tell a **contract** (the prompt required it, the gate enforces it) from a
**convention** (the files converged on it) from a **residue** (a reading the law
text did not settle). The prompts are `prompts/prompt_plan.txt` and
`prompts/prompt_code.txt`; the gate is `tools/check_spec.py`; the frozen
vocabulary is `../Core/Vocab.lean`.

Current contents: **21 rules, 8 laws, 96 scenarios**, landed over 10 iterations
of run `EightRulesAfterSchema` (`state/EightRulesAfterSchema/`).

---

## 1. What the plan agent decides, and how it shows up here

The plan agent writes no Lean. It emits `objectives.jsonl`, one JSON object per
rule to write, and `plan_validate.py` rejects the whole plan before any coding
starts if any of it is malformed. Four of its decisions are visible in this
directory.

### 1.1 How many rules a law gets

This is the plan agent's central judgement, and the prompt states the default:
*prefer one clause → one rule; decompose only when you can name what each part
obliges.* In practice the eight-clause corpus produced a **1-to-N fan-out per
law, not per sentence**:

| law | rules | why it fanned out |
|---|---|---|
| `EX-FOLLOW-001` | 5 | Sentence 2 is a bright line (R0003). Sentence 1, "reasonable and prudent", is an open standard with no threshold, so it became **sufficient conditions on different evidence channels**: R0014 reads the lead's `light_brake`, R0015 reads ego `speed`. R0021 and R0024 then restate R0003's and R0014's thresholds through the *angular* edges, because all three earlier rules route through `Pred.followingWithin`, whose `sameLane` conjunct is a shared single point of failure across a lane-node boundary. |
| `EX-LANE-001` | 6 | Sentence 1 (keep right) is R0008 and R0025. Sentence 2 (do not occupy an opposing lane while a vehicle approaches) is R0016, R0017, R0022, R0023 — four rules whose blind spots are deliberate complements: who must be moving (ego vs. witness), and whether the witness carries angular edges at all (a van does not). |
| `EX-SIGNAL-001` | 3 | R0010 covers entry-and-remain. R0018 and R0026 both carry "stop before the line" — R0026 exists because R0018 turned out to be **inert on a real capture**. |
| `EX-STOP-001` | 2 | R0007 and R0019 are the *same duty by two grounding routes*: the stop-sign actor's `controls` edge vs. the map's OpenDRIVE type-`206` landmark via `mayAffect`. Which route survives the abstraction is an empirical question no scenario can answer. |
| `EX-EMERGENCY-001` | 2 | R0012 triggers on a proximity band; CARLA emits no proximity edge for a `van`, so an ambulance is invisible to it. R0020 uses lane membership and restricts itself to `base_class == "van"` so it complements rather than loosens R0012. |
| `EX-SPEED-001` / `EX-SPEED-002` / `EX-JUNCTION-001` | 1 each | Single conditionals. No decomposition. |

Two things about this shape are worth stating plainly, because neither is what
the prompt asks for:

- **Sibling rules, not parent/child.** `objectives.jsonl` carries a `parent`
  field for decomposition, and across all 10 iterations **it was never set** —
  every value is `null`. The plan agent expressed decomposition by planning
  independent siblings against the same `law_refs`, and recorded the relationship
  in prose in `PROGRESS.md` instead. The field is therefore dead in practice, and
  the "which rules cover which limb" relation lives only in the coverage table
  and in each file's header comment.
- **Most fan-out is about *grounding*, not about *obligation*.** R0019, R0021,
  R0023, R0024 and R0026 add no new duty. They restate a duty already in the
  library through a different edge, because the first route might not exist in
  real data. Under `capture_eval.py`'s aggregation — a law counts as violated if
  *any* covering rule fires — a second route can only ever add recall, never
  correct a false positive. That asymmetry is why the library grows this way, and
  why a *narrower* sibling is never worth planning.

### 1.2 Binders, and the grounding budget

`binders` must be non-empty (nothing quantified cannot ground), and the prompt is
emphatic that every binder **multiplies** the grounding count, because
`PropertySchema.bindings` is the cross product. The measured census in
`carla/schema.json` → `capture_reference_census` is 8 vehicles, 35 lanes, 23
roads, 4 junctions, 6 traffic lights, so a second `laneBinder` costs a factor of
~34.

The gate rejects a schema predicted over `GROUNDING_BUDGET = 500` with
`GROUNDING_BUDGET`. **Seven rules in this directory exceed it and would be
rejected if written today:**

| predicted | rule | binders |
|---|---|---|
| 66,640 | `Lane/R0016`, `Lane/R0017`, `Lane/R0022`, `Lane/R0023` | 2 vehicles + 2 lanes |
| 57,120 | `Signal/R0018`, `Signal/R0026` | vehicle + light + 2 lanes |
| 9,520 | `Lane/R0025` | vehicle + 2 lanes |

They are grandfathered: the budget check was added *after* they landed, in
response to exactly this library — `carla/schema.json` → `why_it_bit` records
that 7 lane-binding rules produced 8,775–16,637 groundings per capture and
239–327 s of evaluation against a 300 s ceiling, so two of four captures were
reported unevaluable. The gate never saw it during coding because a scenario
trace holds 3–4 lanes, where the same rule grounds a handful of times in
milliseconds.

Consequence for anyone editing these seven: the two-lane pattern
`inLane v lNow ⋀ ◯ (inLane v lNext) ⋀ laneTravelsTo lNext lNow` is the
directionality idiom the schema's own `recipes` section recommends, and there is
no single-binder predicate that replaces it. Removing the lane binders needs a
**vocabulary extension** in `../Core/Vocab.lean` (an operator action), not a
rewrite here.

The other 14 rules sit at 8–280 predicted groundings, all through
`vehicleBinder` / `proximityVehicleBinder` / `junctionBinder` /
`trafficLightBinder` / `stopSignBinder` / `landmarkBinder` — the structural
quantification pushed inside predicates such as `hasLaneToTheRight`,
`approachingJunction`, `inAnyJunction`, `governs`.

### 1.3 Scenarios

The plan agent writes the acceptance scenarios **before any Lean exists**, from
the law text, and the coding agent must implement every one with exactly the
declared `expected` value and character-identical names. Mechanically required:
at least one `expected: true` and one `expected: false`, since without a negative
a vacuously-true rule passes.

The realised counts are 4–6 per rule (96 across 21 rules). The pattern the files
converged on is one scenario per **load-bearing conjunct**: a scenario that fails
if that conjunct is dropped or inverted. `Following/R0003`'s
`being_tailgated_is_not_a_violation` exists solely to fail if `behind v w` is
inverted; `Lane/R0023` carries one scenario for `¬ₛ (isEgo w)` and one for
`¬ₛ (inReverse v)`.

**What scenarios cannot do** is the reason `run_spec monitor` exists: the same
plan agent wrote the scenarios and chose the reading, so a misread clause
produces scenarios that agree with the misreading and the gate still prints `OK`.
Several headers here say so in as many words ("Not validated against real data").
The gate's one independent signal is the `CARLA` grounding count against
`../Carla/Sample.lean`, and it is a warning, never a failure.

### 1.4 Whether the law is formalizable at all

Four answers, not two — readable today / reachable with a stated residue /
present in the data but not lifted into Lean (a *vocabulary* gap) / genuinely
absent. Only the fourth justifies `unsupported`, and it must name a key from the
schema's *NOT available* list.

**No law in this corpus is `unsupported`.** Every clause is `formalized`, and
`PROGRESS.md` records why that verdict is fragile: iterations 1–3 filed the
signal stop-line limb under `unavailable.stop_line_and_junction_geometry`, and
iteration 4 found it needed only `at_traffic_light` — an attribute that had been
in `attribute_keys` and in `Vocab.lean` the whole time. Nothing downstream
re-examines an `unsupported` verdict, so the cost of getting it wrong is a
permanently unmeasured obligation.

The residues that survive as approximations are written into the file headers,
which is where a reviewer should look: no stop line (so "before entering" is
lane-membership), no junction geometry (so "within" is lane occupancy), no siren
channel (so "responding" is unobservable), no non-ego dynamics (so a lead pulling
away and a stationary lead are indistinguishable), no timestamps (so every
duration is a frame count at an assumed 20 Hz).

---

## 2. What the code agent is required to produce

### 2.1 The path, the module, and the namespace

Derived by `scripts/task.py`, and the agent gets all three in its node spec so it
and the gate never re-derive them differently:

```
node_id    Following/R0003_following_distance      = "<theme>/<slug>"
file       Rules/Following/R0003_following_distance.lean
module     TrafficSpec.Rules.Following.R0003_following_distance
namespace  TrafficSpec.Rules.Following.R0003
```

Note the namespace takes only the **leading identifier of the slug**
(`slug.split("_", 1)[0]`), so declarations read `Rules.Following.R0003.entry`
rather than repeating the descriptive tail. `index_sync.py` finds rules by
scanning for `namespace TrafficSpec.Rules.…`, so a file whose namespace does not
match this rule compiles but is invisible to the library — which the integrate
phase treats as a failure.

### 2.2 The mandatory shape

`STRUCTURE_FAIL` unless the file contains `import TrafficSpec.Core`,
`namespace <the exact expected namespace>`, and **`def schema`, `def entry`,
`def scenarios`** under those exact names. A second `STRUCTURE_FAIL` fires later
if `def scenarios` omits a scenario the plan declared.

```lean
import TrafficSpec.Core                    -- Core only. A rule may import nothing else.

namespace TrafficSpec.Rules.<Theme>.<Rnnnn>

open TrafficSpec TrafficSpec.SFProp TrafficSpec.Pred

def schema : PropertySchema where          -- name, binders, formula
def entry  : RuleEntry     where           -- nodeId, lawRefs, schema
-- entity ids, frame helpers, one `def traceX : Trace` per scenario
def scenarios : List Scenario              -- every declared name, exact `expected`

end TrafficSpec.Rules.<Theme>.<Rnnnn>
```

Everything between `entry` and `scenarios` is unconstrained by the gate. The
convention every file follows is `../Carla/Sample.lean`'s: private id constants,
shared entity and relation lists, a parameterised frame helper, then one
documented `def traceX : Trace` per scenario, so `scenarios` is a flat table of
name → trace and each trace carries a doc comment saying what it depicts and what
breaks if the formula is wrong.

### 2.3 The header comment is part of the contract

The prompt requires a comment block recording the law text and **every
formalization choice the text did not dictate**, so "a reviewer must be able to
challenge your reading without rerunning you." The gate cannot check this, and it
is the single most valuable thing in these files: the headers here run 50–200
lines and cite the generator source for each claim about the data.

The same choices are repeated in machine-readable form in each node's
`node_report.json` → `formalization_choices`.

### 2.4 One file, and the gate is not reconfigurable

A coding agent may write only its own target file. `Core/` is frozen, `Index.lean`
is generated by the harness, and another rule is another node's. The gate hashes
every `.lean`/`.toml` under `library/` before the session (`library_manifest`) and
reports any other change as `SCOPE_VIOLATION`; the harness then re-checks scope
against the manifest **it** captured, and rejects an `OK` as `GATE_BYPASS` if the
gate measured a different `--library-root`, a replaced `baseline.json`, or ran
`--skip-build`.

An honest `blocked` report is explicitly preferred over a rule that passes by
weakening a scenario or dropping a conjunct.

---

## 3. Conventions these files converged on

None of these are required by the prompt or the gate. They are what 21 sessions
independently settled on, and a new rule that departs from them should say why.

**The safety shape.** 8 of 21 rules are exactly
`□ (¬ₛ (SFProp.bounded n forbiddenState))` — "at no position does the forbidden
state hold for `n` consecutive frames." It is the natural reading of a
prohibition plus a persistence window, and it has one property worth knowing:
`loopBounded` reads a window running off the end of the trace as false, so **the
last `n-1` frames of any trace are a blind zone** in which a violation cannot be
reported, and a trace shorter than `n` reports compliant whatever it contains.
Scenario traces are sized for this deliberately, and `frameSpan` is reported per
rule in the capture harness for the same reason.

**The transition-triggered obligation.** `Stop/R0007`, `Stop/R0019`,
`Signal/R0018`, `Signal/R0026` all use

```lean
(trigger ⟹ obligation) ⋀ □ ((¬ₛ trigger ⋀ ◯ trigger) ⟹ ◯ obligation)
```

with `obligation := ¬ₛ ((¬ₛ discharge) 𝒰 deadline)`. The formula language has no
past operator, so a per-frame trigger would demand a *fresh* stop from a driver
who had already made one; asking once per episode — at position 0 if the capture
opens inside one, and at each later frame one begins — is how these rules avoid
that. The strong `𝒰` sits under the negation so a trace that ends on the approach
is compliant rather than convicted for an entry that never happened.

**Thresholds as named top-level `def`s.** `gapMetres`, `persistFrames`,
`dwellFrames`, `graceFrames`, `redHoldFrames`, `speedThresholdKph`,
`overtakeGraceFrames`, `holdFrames` — each with a doc comment stating that the
number is the rule's choice and not the statute's, and often what happens if you
move it in either direction. Durations go through
`TrafficSpec.secondsToFrames` (`secs * captureHz`, `captureHz = 20`) rather than
a bare frame count, so the 20 Hz assumption is visible at every use site.

**Ego gating.** Every rule reading a dynamics channel gates on `Pred.isEgo`,
because `speed`/`accel`/`throttle`/`brake`/`steer` exist on the ego alone and a
dynamics predicate on a non-ego binder is silently false. Several rules gate on
`isEgo` for a second, stronger reason: proximity and angular edges only ever
connect the ego to another actor, so an ungated rule would also read the
*reversed* grounding and convict the vehicle in front.

**Asymmetric evidence in the lane rules.** `Pred.oncoming` is symmetric, so the
bare recipe convicts the victim of a wrong-way driver as readily as the offender.
Every sentence-2 lane rule therefore carries a conjunct that identifies the ego
as the misplaced vehicle — its own motion against `laneTravelsTo`, or the
witness's motion *with* it. The deleted `Lane/R0009` is cited repeatedly as the
counterexample: it read the `lane_id` sign and convicted 50 frames of lawful
driving.

---

## 4. Inventory

Predicted groundings are `predicted_groundings` against the reference census;
`>500` is over today's budget. Scenario counts are the declared ones.

| rule | law | binders | scen. | groundings | shape | key constants |
|---|---|---|---|---|---|---|
| `Speed/R0001_max_speed` | SPEED-001 | v | 5 | 8 | `□(isEgo ⟹ speedLeKph 50)` | 50 km/h literal |
| `Speed/R0002_junction_speed` | SPEED-002 | v, j | 5 | 32 | `□(isEgo ⋀ inJunction ⟹ speedLeKph 30)` | 30 km/h |
| `Following/R0003_following_distance` | FOLLOW-001 | v, w | 4 | 56 | safety | `gapMetres 4`, `persistFrames 4` |
| `Junction/R0006_yield_in_occupied_junction` | JUNCTION-001 | v, w, j | 4 | 224 | entry transition + `◯ bounded` | `persistFrames 4` |
| `Stop/R0007_stop_sign_dwell` | STOP-001 | v, s, j | 5 | 128 | transition + `𝒰` | `dwellFrames = 1 s` |
| `Lane/R0008_keep_right_of_roadway` | LANE-001 | v, l | 5 | 280 | safety | `overtakeGraceFrames = 3 s` |
| `Signal/R0010_red_light_in_junction` | SIGNAL-001 | v, d, j | 4 | 192 | entry transition + `◯ bounded` | `redPersistFrames 4` |
| `Emergency/R0012_pull_right_for_emergency` | EMERGENCY-001 | v, w | 5 | 56 | safety | `graceFrames = 2 s`, 25 m band |
| `Following/R0014_prudent_gap_when_lead_brakes` | FOLLOW-001 | v, w | 5 | 56 | safety | `gapMetres 10`, `persistFrames 6` |
| `Following/R0015_prudent_gap_at_speed` | FOLLOW-001 | v, w | 4 | 56 | safety | `speedThresholdKph 40`, `gapMetres 16`, `persistFrames = 1 s` |
| `Lane/R0016_crossing_into_opposing_lane` | LANE-001 | v, w, lFrom, lOpp | 4 | **66,640** | transition + `◯ bounded` | `persistFrames = 1 s` |
| `Lane/R0017_wrong_way_progress_with_oncoming` | LANE-001 | v, w, lNow, lNext | 4 | **66,640** | single-step `◯` | — |
| `Signal/R0018_stop_at_red_before_entering` | SIGNAL-001 | v, d, lApproach, lControlled | 4 | **57,120** | transition + `𝒰` | `redHoldFrames = 1 s` |
| `Stop/R0019_stop_landmark_dwell` | STOP-001 | v, lm, j | 4 | 192 | transition + `𝒰` | `dwellFrames = 1 s`, landmark type `206` |
| `Emergency/R0020_yield_to_emergency_van_in_lane` | EMERGENCY-001 | v, w | 5 | 56 | safety | `graceFrames = 2 s`, `base_class = van` |
| `Following/R0021_close_gap_across_lane_boundary` | FOLLOW-001 | v, w | 5 | 56 | safety | `gapMetres 4`, `persistFrames 4` |
| `Lane/R0022_occupying_lane_against_observed_flow` | LANE-001 | v, w, lNow, lNext | 5 | **66,640** | single-step `◯` | — |
| `Lane/R0023_wrong_way_with_vehicle_in_lane` | LANE-001 | v, w, lNow, lNext | 4 | **66,640** | single-step `◯` | — |
| `Following/R0024_braking_lead_across_lane_boundary` | FOLLOW-001 | v, w | 5 | 56 | safety | `gapMetres 10`, `persistFrames 6` |
| `Lane/R0025_travel_against_lane_flow` | LANE-001 | v, lNow, lNext | 4 | **9,520** | transition + `◯ bounded` | `holdFrames = 1 s` |
| `Signal/R0026_entry_on_red_without_stopping` | SIGNAL-001 | v, d, lApproach, lControlled | 6 | **57,120** | transition + `𝒰` | *no duration constant* |

---

## 5. Known problems in the current library

These are recorded in `state/EightRulesAfterSchema/PROGRESS.md` as **operator
edits**: none is reachable from the loop, because a coding agent may only write
its own new file and a *narrower* sibling changes no verdict under
`capture_eval.py`'s aggregation.

1. **`Signal/R0018` is inert.** Measured on `red_light_violation`: its antecedent
   holds for 15 frames, and `redHoldFrames = secondsToFrames 1` needs 20, so
   `SFProp.bounded` never closes and the rule reports compliant on the capture
   built to make it fire. Worse, the window is bounded above by the gap between
   entering the trigger volume and reaching the junction, and that gap is
   *shortest for a driver who does not slow down* — so a hold measured in frames
   systematically protects the violator. `R0026` was planned to carry the same
   limb with no duration constant at all. `redHoldFrames` should be cut or the
   rule removed.
2. **Seven rules are over the grounding budget** (§1.2). They are why the budget
   check exists, and they cost 239–327 s per capture.
3. **RSV junction entry is ~0.8 s early**, because `isIn` is bounding-box
   overlap: the ego reads `inAnyJunction` 16–17 frames before the oracle's
   centre-based entry. Both stop rules require the dwell to complete while the
   ego is in no junction, so a driver who stops *at the line* has the stop
   discarded and is convicted for it.
4. **`Junction/R0006` has no distance or conflict conjunct**, so it convicts
   entry into any junction another vehicle already occupies and holds for 0.2 s —
   routine lawful driving at a four-way.
5. **`Lane/R0008`'s "except when overtaking" is a 60-frame persistence proxy**,
   waiting on the one standing vocabulary request,
   `Pred.hasSameDirectionVehicleToTheRight`.
6. **`Emergency/R0012` reads "upon the approach" as a static 25 m band**, so it
   convicts on a *parked* police car. There is no siren channel anywhere in the
   graph, so "responding" is unobservable.
7. **Following a van at any distance is uncovered and unreachable.** The
   generator emits no proximity or angular edge for a van, and the R0012→R0020
   move does not transfer: there the offence was the ego's own lane position,
   here the offence *is* the distance.

---

## 6. Editing a rule by hand

Rule files are agent output, but they are ordinary source. If you edit one:

- Re-run the gate for that node, or `python -m scripts.run_spec verify` for the
  whole library (rebuild + every registered scenario, no agent).
- Do not edit `../Index.lean`; run `python -m scripts.run_spec index`.
- Keep the header honest. If you move a threshold, move the sentence that
  explains it — a reviewer challenging the reading has nothing else to go on.
- Changing a rule's verdict changes its law's verdict on every labelled capture,
  because `capture_eval.py` aggregates a law as violated if any covering rule
  fires. Run `run_spec monitor` before assuming a tightening was free.
