# Evaluation dataset — handoff

**Date:** 2026-09-10 · **Scope:** how the traffic-rule monitor gets evaluated, and what the dataset it is evaluated on has to be.

---

## TL;DR

1. **The target is a rulebook, not a route.** BC MVA Part 3 is ss.119–214, ~96 sections, 250–400 atomic obligations, with other jurisdictions to follow. CARLA's Driving Score measures a *driver*; a monitor is a *detector*. Different object, different metric.
2. **Ground truth must be derived, not annotated.** A hand-written per-rule label is a *second formalization* of the same statute — when it agrees with the spec you learn nothing, when it disagrees you cannot say which is wrong. Fix: annotate the **world** once in a jurisdiction-neutral fact schema, and derive labels as a pure function of (facts, reading).
3. **Working implementation exists:** [`pipeline/evalkit/`](evalkit/), 33 passing tests, no CARLA required, runs on the real 33-capture SceneFlowLang corpus.
4. **Two data faults were found, root-caused and fixed in the adapter.** Both were silent: they produced plausible wrong verdicts rather than errors, and together they corrupted dynamics channels read by **20 of 24 rule files**.
5. **Biggest remaining risk is not labelling — it is situation coverage.** The corpus witnesses 3 of Bench2Drive's 44 scenarios and gives 3 of 10 obligations a two-sided witness.

---

## 1 · How a monitor should be scored

**Not** `DrivingScore = RouteCompletion × Π penalties`. That scores how well the car drove. A monitor can be excellent while watching a terrible driver; its multiplicative form also gives a monitor that never fires the same score as one that is always right. The Leaderboard's infraction set is ~7 hard-coded detectors and has nowhere to put obligation #300.

Four axes, reported separately:

| Axis | What | Why it is not in any driving score |
|---|---|---|
| **Detection** | Per-rule precision/recall over **episodes** (intervals), matched by overlap + onset tolerance | Frame accuracy is dominated by long compliant stretches; reads ~99% for a monitor that never fires |
| **Latency** | Frames from true onset to alarm | A red-light entry reported 2 s late is correct and useless. This is what an intervention depends on |
| **Coverage** | Fraction of the rulebook formalized / **witnessed** / witnessed **two-sided** | Measures the *dataset*. Report this first while the dataset is what you are building |
| **Cost** | Wall-clock per frame | A monitor that can't keep pace is an offline tool |

When one number is required:

```
MonitorScore = TwoSidedCoverage × mean(F1ᵣ × LatencyFactorᵣ)
LatencyFactorᵣ = clamp(1 − latencyᵣ / (2·budget), 0, 1)      budget = 1.0 s
```

The product is deliberate: covering 3 of 96 obligations caps the score at 0.031 however good the monitor is. Rules that are not two-sided are excluded from the quality mean and counted against coverage, so they can never inflate it.

> **Free ground truth.** CARLA's own `RunningRedLightTest`, `RunningStopTest`, `CollisionTest`, `OutsideRouteLanesTest`, `ActorBlockedTest` are independent, widely-replicated implementations of rules we also cover. Run them beside our labels on the same captures to validate the labelling machinery on the overlap at **zero human cost**.

**A bug this metric design caught in our own code:** an `F1` of *undefined* for a rule where the monitor was maximally wrong (0 TP, 5 FP, 5 FN) dropped that rule out of the aggregate mean and **raised** the score. Undefined must mean "nothing to score"; fired-and-entirely-wrong scores 0.0. Fixing it moved the demo MonitorScore 0.017 → 0.006.

---

## 2 · The labelling architecture

### The problem, concretely

The clause *"at least two seconds of space"* was quantified **20 m centre-to-centre** in `Rules/Following/two_second_gap.lean` and **4 m bumper-to-bumper** in `carlaspec/labeler.py`, where it was tagged `[statute]` — the statute says neither. An audit found the same failure in **4 of 8** labelled laws: a junction speed limit attributed to a section about rural highways; a one-second stop dwell attributed to a section naming no duration; an emergency rule checking "pull right" (a different subsection) while never checking the "stop" the cited subsection requires.

### The fix: four layers, human effort in exactly one

```
L0  trace      rsv/*.pkl + ego_logs.json          what the monitor sees
L1  facts      ~70 jurisdiction-neutral fields    what physically happened   ← machine
L2  readings   readings/<jurisdiction>.jsonl      what the law demands       ← HUMAN, only here
L3  labels     derived, never hand-written        the ground truth           ← machine
```

Because L1 is jurisdiction-neutral, adding a jurisdiction adds readings and reuses every capture. **Demonstrated:** the same 23 captures, the same fact tracks, a second readings file → different labels, **zero re-annotation, zero re-simulation**.

| Readings | Obligations | compliant | violated | n/a | untestable |
|---|---|---|---|---|---|
| `bc_mva_part3.jsonl` | 10 | 93 | 8 | 83 | 46 |
| `demo_eu_urban.jsonl` | 2 | 39 | 5 | 2 | 0 |

### Three semantic rules the whole thing rests on

1. **UNKNOWN is not False.** Missing facts propagate through Kleene three-valued logic, so a rule can never be satisfied by a gap in the data.
2. **UNTESTABLE is not NOT_APPLICABLE.** The first is a claim about the *recording*, the second about the *world*. Conflating them lets a corpus with a missing field report full coverage.
3. **Physics in L1, thresholds in L2.** `headway_s` is computed in the fact layer, so the expression language needs no arithmetic and stays reviewable at a glance — which is the only property that makes L2 worth having, and is exactly what stops "two seconds" becoming two different distances in two places.

### Human budget

| Task | Who | Volume | Cost | Recurs |
|---|---|---|---|---|
| Draft readings from statute | LLM | ~300 | machine | per jurisdiction |
| **Review each reading's quantifications** | **human / legal** | ~300 | **~50 h** | per jurisdiction, once |
| Adjudicate spec↔label disagreements | human | 1–5% of cells | small | per release |
| Audit a random sample of agreements | human | 1–2% of cells | small | per release |
| Label a capture | — | **0** | **0** | never |

The audit line cannot be automated away. Differential formalization defends against *independent* errors, not *correlated* ones. Publish the audit sample size and its disagreement rate as part of the benchmark.

**Where AI belongs:** drafting L2 readings; an adversarial ensemble over L2 that routes disagreement to a human; a VLM as a *third channel on perceptual predicates only* (cross-checked against privileged state — a disagreement detector, never an oracle); scenario synthesis from the coverage report. **Never the legal verdict** — it cannot be audited and re-introduces the un-attributable second formalization.

---

## 3 · Building the corpus without setting parameters by hand

> **The label function is the search's fitness function.** `label_one(reading, track)` is a cheap pure function of a trace, so it goes *inside* the generation loop. You do not need a person to say whether a run came out compliant or violating — run it, derive the label, keep it if it landed where you wanted. The labelling pipeline and the generation pipeline are the same loop.

Three authored-once ingredients, then a search:

1. **Map index** (offline, per town) — every site where a situation class can occur: signalized approaches, stop-sign approaches, uncontrolled junctions, multi-lane straights, curves, crosswalks, one-ways, merges. From `map.get_topology()`, `map.get_all_landmarks()`, `junction.get_waypoints()`, `map.get_crosswalks()`, `TrafficLight.get_stop_waypoints()`. Turns "where does the scenario go" from a choice into a query.
2. **Parameterized manoeuvre templates** (5–8 cover most of Part 3): approach-a-control / longitudinal / lateral / static-state / special-actor. Each with a typed parameter vector and a **scripted controller**.
3. **Search** — implemented in [`evalkit/search.py`](evalkit/evalkit/search.py).

**Boundary bisection**, measured (mock simulator, `BC-MVA-162-1`, threshold 2.0 s, never given to the search):

```
run 1  0.500 → violated      run 7   2.047 → compliant
run 2  6.000 → compliant     run 8   1.961 → violated
run 3  3.250 → compliant     run 9   2.004 → compliant
run 4  1.875 → violated      run 10  1.982 → violated
run 5  2.562 → compliant     run 11  1.993 → violated
run 6  2.219 → compliant
→ 11 runs, empirical flip at 1.9985 s; pair kept straddles by 0.011 s
```

A corpus of unambiguous cases **cannot falsify a threshold** — the project's own Lean rule says so: *"both readings agree on all four scenarios … nothing in this session distinguishes them."* The near-boundary pair is what discriminates. The empirical flip point is also a result: compare it to the statutory value and you have measured whether the formalization put its threshold where the law puts it, with no annotation.

Four **refusal** paths are tested, because each would otherwise look like convergence: unbracketed range (returns an endpoint), antecedent never engages, field ABSENT (→ UNTESTABLE, a recording problem not a parameter problem), non-monotone bracket.

**Stop using Traffic Manager to drive the vehicle under test.** TM is a black box that will not reliably produce a specific violation; the existing scenario code documents the fight (*"the cross vehicle crossed and left while the ego was still 28 m away"*). Drive a fixed route with a scripted controller whose speed profile and lateral offset are scenario **parameters** — then "violation" is `lateral_offset = +2.0 m`, exact and seed-independent, and the compliant/violating pair differs in exactly one parameter, which is what makes a disagreement attributable. TM for background traffic only.

**Label-free signals to run first** (no monitor, no labels):
- **Mutation testing** — perturb a constant, re-derive, see if any capture notices. Overall score on the current corpus **0.442**; `BC-MVA-157-1` and `-162-1` score 1.00, `BC-MVA-186-1` scores **0.00** (no capture near the stop threshold). A surviving mutant is a *request for a capture*, not a defect in the reading.
- **Invariance** — same manoeuvre, different town/weather/seed; the verdict must not change.

### Bench2Drive's 44 scenarios

Verified from the paper's Table 2: the union of the five skill lists is **exactly 44**. Encoded in [`evalkit/corpus.py`](evalkit/evalkit/corpus.py).

| Skill | Scenarios | Present in our corpus |
|---|---|---|
| Merging | 16 | 0 |
| TrafficSign | 18 | 2 |
| EmergencyBrake | 12 | 2 |
| Overtaking | 9 | 1 |
| GiveWay | 2 | 0 |

**Blocking version conflict:** Bench2Drive's 220 routes live on **Town12/Town13**, requiring CARLA 0.9.15+. This install is **0.9.14** with Town01–05 + Town10HD, and the client wheels are cp27/cp37 only. A 0.9.14 client cannot replay a 0.9.15 recorder log. Recommended split: Tier A/C on the existing 0.9.14 stack (those towns have signals, stop signs, speed signs, multi-lane roads and junctions — enough for most of BC MVA); Tier B on a separate 0.9.15 install, fed in as recorder logs.

### Python API setup for scale

- **Determinism is a precondition of bisection, not a nicety.** Sync mode + fixed `fixed_delta_seconds` + `tm.set_random_device_seed` + `world.set_pedestrians_seed` + fixed spawn order + scripted ego. `verify_determinism()` measures it rather than assuming.
- **SGG reuse — the throughput finding.** `SGG.__new__` **deletes and rebuilds** the singleton whenever args are passed, so `SGG(client, ego_id)` pays the full `init_to_world()` map index every time. `SGG()` returns the cache, and `ego_id`'s setter is the **only** one that does not call `_check_init()` (`segment_length`, `angular_precision`, `closeness_inflation` all do); the base graph depends on the map alone. ⇒ **one SGG per (worker process, town), reused across unlimited runs via `sgg.ego_id = new_ego.id`.**
  [`runner.py`](carla_scene_graphs/src/carlaspec/runner.py) currently calls `SGG(client, ctx.ego.id)` inside `run()`, so `--all` re-indexes the whole map for every capture. Free speedup.
- Headless: `./CarlaUE4.sh -RenderOffscreen -nosound -quality-level=Low -carla-rpc-port=$((2000+2*W))`, one TM port per server.
- Python **must** be 3.7 (0.9.14 wheels). Use the existing `.carlasg` env.
- **Campaign size:** ~300 obligations × 3 sites × 12 runs ≈ **10,800 simulations**. Per-run cost must be measured.

> **There is no 12-second / 240-frame ceiling.** Retracted after checking: the adapter already chunks (`CHUNK_FRAMES = 8`) and `--max-frames` defaults to no cap; a 962-frame capture converts to 122 chunks / 1.6 MB. The constant survives only in `src/carlaspec/scenario.py`, describing an adapter that no longer exists. **Delete it.**

---

## 4 · Verified facts about the data

All measured against 44,455 frames of real `carla_sgg` output, not read off documentation.

| Finding | Evidence |
|---|---|
| **Recorder replay zeroes all ego dynamics.** A CARLA property, **not** a `carla_sgg` bug — live rollouts are fine | `carla_speed` 0.000 on all 3 replayed captures; 6.667 / 5.172 on tcp / interfuser rollouts. 882 of 882 moving frames report stationary |
| **Control *survives* replay.** The loss is exactly velocity, acceleration, angular velocity | `carla_throttle` 0.8 and `carla_brake` 0.3/0.097/0.071 across the same frames where speed is 0 |
| **The scene-graph and ego-log frame indices have different origins: +10.** A real bug in `capture_sensor_data.py:437` — it ticks 10 times to warm 5 sensors up *after* `replay_file()` has started, then takes `start_frame`, while `add_agent_delay()` has already re-based the log to tick 0 | Verified by position, recorded independently in both files: mean error **3.452 m at 0, 0.039 m at +10**, on **3 of 3** logged captures. The first 10 log records carry an identical transform and zero velocity — the `add_agent_delay` signature |
| The same offset also corrupts the **IMU CSV** attached to every sensor frame | `imu_data = imu_logs[FPS*start + frame_diff]`, `frame_diff = sg_frame` |
| **No non-ego actor ever carries a velocity** | `copy_carla_actor_state` runs at `sgg.py:563` for the ego and nowhere else. 1,487 non-ego nodes inspected, **zero** carry any dynamics key |
| **RSV lane/road/junction nodes carry zero attributes** | `{Lane: 0, Road: 0, Junction: 0, Off Road: 0}` on a real frame. Lane heading, width, markings, `curve`, `waypoint_s` all destroyed; only `(road_id, lane_id)` survives, inside the node *name* |
| `ego -isIn-> Lane` is **one-to-many** (5 lane nodes in one frame) | "Same lane" is a set intersection; written as equality the rule never fires |
| **Posted controls are monitorable** | Lights reach lanes by `controlsTrafficOf` with `light_state`; landmarks by `mayAffect` with `landmark_type` (206 stop, 274 speed limit, 1000001 signal) and `landmark_value`. `landmark_OpenDRIVE_274_30` → `30.0` |
| `landmark_unit` reads `'mph'` while CARLA authors its towns in km/h | Believing it scales every posted limit by 1.61 |
| **`threedbbox` survives the abstraction** — it is an *adapter non-lift*, not a generator loss | Fixture: a base graph carrying an 8×3 bbox comes out of `process_to_junction_rsv` with it intact on ego and car. Absent from the SceneFlowLang corpus (0/6062) only because that corpus predates the field |
| 10 of 33 captures will not load under shapely 1.8 | pickled with shapely 2 |

### What this did to the Lean trace

| Channel | Source | Replay | Live |
|---|---|---|---|
| `speed` | graph | **0.0 — wrong** | ok |
| `accel` | log only, no graph fallback | value ok, **+10 off** | **0.0 — no log** |
| `throttle` / `brake` / `steer` | graph | ok | ok |
| `yaw_rate` | graph | **0.0 — wrong** | ok |
| `vel_*` / `acc_*` attrs | graph | **0.0 — wrong** | ok |

**20 of 24 rule files** read a channel this corrupts. `Pred.stopped` (12 files) is `speedLe e restTolerance`, so a fabricated 0.0 makes it **true on every frame**. `Speed/urban_default_limit` is `□(situation ⟹ ¬ₛ .bounded n (¬ₛ speedLeKph ego 50))` — with speed 0 it reports **compliant on a capture where the ego did 90 km/h**. There is a false-positive direction too: `Parking/off_roadway_dwell` reads a moving ego as parked off the roadway.

Note the asymmetry, which matters for how rules are written:

| | attribute | `speedLe X` | `speedGe X` |
|---|---|---|---|
| ego, replay | present, `0.0` | **TRUE** ← fabricated evidence | false |
| any non-ego, always | **absent** | false | false ← honest "no evidence" |

---

## 5 · Changes made

### Fixed — `carla_scene_graphs/src/` (Python API blockers)

| Bug | Fix |
|---|---|
| PEP 584 dict union (3.9+) on a 3.7 env — killed **every** capture in `_finalize` after the whole simulation had run | `dict.update` / `{**a, **b}` at `runner.py`×2, `labeler.py`×1 |
| `keep_slow_lane_rule_percentage` is the 0.9.15 name; 0.9.14 has `keep_right_rule_percentage` | `compat.keep_right_rule_percentage()` dual-name shim; **raises** rather than degrading to a no-op, since that switch is the only difference between the two counterparts. 3 call sites (`emergency.py`, `lane.py`, `speed.py`) |

### Fixed — `traffic-spec-agent/carla/adapter.py` (accuracy into Core)

**Principle: never fabricate a number the capture did not supply.**

`Core/Decimal.parseMilli` returns `none` for an unparseable value and every comparison documents that it then reads **false** — identical to an absent attribute. So `UNMEASURED = "unmeasured"` expresses "no evidence" with **zero Core changes**. Verified in Lean:

```
parseMilli "unmeasured" = none      leMilli "unmeasured" 13888 = false
parseMilli "0.0" = some 0           leMilli "0.0"        13888 = TRUE   ← the corruption
```

| Change | Effect |
|---|---|
| `UNMEASURED` sentinel | `speed` / `accel` / `yaw_rate` emitted honestly when not measured |
| `EGO_REPLAY_INVALID_VECTORS` | `vel_*` / `acc_*` / `roll_rate` / `pitch_rate` suppressed **by key** (three zeros are a well-formed vector of magnitude zero; absence is not) |
| `RecordingPolicy` + `detect_replay_zeroing()` | `capture_mode` / `dynamics_valid` / `ego_log_frame_offset`. Priority: **declaration > manifest > detection** |
| `ego_accel()` | accel now prefers the graph's own `carla_acc_*` magnitude — same frame by construction, and it fixes the live-capture bug |
| `log_index += ego_log_frame_offset` | the +10 correction |
| `--declare-capture-mode`, `--declare-ego-log-offset` | matching the existing `--declare-*` style |
| `simulation.template.json` → `recording` block | with `$fields` notes explaining each |

**Verified — predicate level** (`zeroed` vs `unmeasured`):

```
Pred.stopped                   (true,  false)   ← 12 of 24 rule files
Pred.speedLeKph 50             (true,  false)   ← urban_default_limit's consequent
Pred.notTurning 5000           (true,  false)
Pred.accelMagnitudeAtMost 500  (true,  false)
Pred.speedGeKph 36             (false, false)   ← removes false evidence,
Pred.turningAtLeast 5000       (false, false)      cannot manufacture missing evidence
```

**Verified — live capture:** `accel` went from **0/400** frames to **114/400** (peak 12.25 m/s²).
**Regression:** the no-manifest refusal still fires; explicit declaration overrides detection; evalkit's 33 tests still pass.

### Built — [`pipeline/evalkit/`](evalkit/)

```
facts.py      L1 schema, ~70 fields, per-field provenance (SIM/SG/DERIVED/ABSENT)
reading.py    L2 expression language, three-valued; quantification provenance
              (statute / reading / borrowed)
evaluate.py   L3 derivation → intervals, not verdicts
metrics.py    episode P/R/F1, latency, coverage, MonitorScore
mutation.py   label-free dataset discrimination
search.py     bisection, witness search, determinism check, campaign planner
extract_sg.py L1 from real rsv/*.pkl — the monitor's view
corpus.py     discovery, Bench2Drive's 44, coverage reporting
readings/     bc_mva_part3.jsonl (10), demo_eu_urban.jsonl (2)
tests/        33 tests, no CARLA required
```

`evalkit report` needs no monitor and no labels — run it first on any corpus:

```
captures found 33, usable 23, frames 9200, 4.3 min
Bench2Drive coverage: 3 of 44
witnessed 8/10 · two-sided 3/10 · untestable everywhere 2
  ego.lane.wrong_way            blocks BC-MVA-150-1   (5 of 44 scenarios are TwoWays overtakes)
  ego.posted.crosswalk_ahead_m  blocks BC-MVA-179-1   (4 of 44 are pedestrian crossings)
```

Every uncovered obligation prints the Bench2Drive scenarios that would witness it — a coverage hole is a work item, not a percentage.

### Written — [`carla_scene_graphs/SCENE_GRAPH_LIMITS.md`](carla_scene_graphs/SCENE_GRAPH_LIMITS.md)

Four categories by **where the datum stops being available**, because that decides whether it is fixable: **A** never collected · **B** on the base graph, destroyed by `process_to_junction_rsv` (`carla_sgg/` is byte-frozen) · **C** in the RSV, not lifted by the adapter (**fixable here**) · **D** present but not a measurement.

### Deleted — `traffic-spec-agent/gaps/ledger.jsonl`

11 entries. **Was not git-tracked**, so backed up to `scratchpad/ledger.jsonl.deleted-2026-09-10` first. After deletion `gaps.load()` returns `(0, 0)`, `render_for_agent()` has a graceful empty state, `next_id()` → `G1`, all four consumer modules import.

**Why the logic was wrong, with evidence.** The prompt's Phase A files a gap for `blocked_on_gap` and `unsupported` but **not** for `formalized_with_residue` — which the same prompt calls *"the normal outcome for real law over an abstraction"*. Consequences, all verified:

1. `coverage.py:58` lists `formalized_with_residue` in `TERMINAL`.
2. `prompt_plan.txt:40` — a terminal row may not be re-planned.
3. `loop.py:104` — **retiring a gap is the only thing that reopens a row.**
4. `plan_validate.py:298` ties gaps to `blocked_on_gap` only; no gap requirement on `formalized_with_residue`.

⇒ **A clause that ends in residue is sealed permanently.** Even if the exact capability that would close it later lands, there is no gap to retire and nothing reopens it; the residue lives only as free text in a `notes` column, with no `owner`, no cross-iteration dedup, and no way to dispute it. The 11 deleted entries confirm it — all `vocab/core/generator/adapter/manifest`, none from a residue, and `G11` was hand-entered by an operator after the fact.

---

## 6 · Open items

### Now — no simulator needed

| # | Item | Why |
|---|---|---|
| 1 | **Rewire the gap ledger** (4 edits): require a gap on `formalized_with_residue` (`prompt_plan.txt` Phase A, `plan_validate.py`); make that status terminal-*until-its-gap-retires* (`coverage.py`); add `residue_direction` to `Gap` (the prompt already demands a direction and the ledger has nowhere to put it) | Otherwise the most common outcome is permanently sealed |
| 2 | **Lift `threedbbox` as `half_length` / `half_width`** in the adapter | Unlocks body-to-body gaps. Every "within N m of the vehicle in front" is currently ~4.7 m looser than the statute; the 1.0/1.5 m vulnerable-user clearance is not computable at all. Derive two scalars, not 24 raw numbers |
| 3 | **Write `simulation.json` for the 3 replay captures** (`capture_mode: replay`, `ego_log_frame_offset: 10`, `dynamics_valid: false`) | Stop depending on auto-detection; lets the adapter's CONTRADICTION report converge |
| 4 | **Delete `max_capture_frames = 240`** from `src/carlaspec/scenario.py` | Stale; blocks longer captures for no reason |
| 5 | **Fix `labeler.py`'s misattributed `[statute]` constants**, or retire it in favour of `readings/` | 4 of 8 laws currently mis-cite the statute |
| 6 | **Repair the shapely-2 reader** | Unlocks 10 of 33 existing captures |

### Next — needs CARLA

| # | Item |
|---|---|
| 7 | `evalkit/extract_sim.py` — the privileged-state extractor. Schema and provenance contract are in place |
| 8 | `evalkit/sites.py` — the offline map indexer, one run per town. The missing piece between `search.py` and a real map |
| 9 | Extend L1 **once** to the full ~70 fields: full OpenDRIVE landmark extraction, crosswalk polygons, lane heading, lane counts, body half-widths, junction control status. **The only step requiring a full re-record, so settle the schema first** |
| 10 | Fix `capture_sensor_data.py`: it cannot avoid losing the first 10 ticks (the hero does not exist before `replay_file()`), so either slice the ego log by the same offset, or record scenarios with ~1 s of idle lead-in |
| 11 | Scripted controller + parameterized templates; then the bisection campaign |

### Decisions that are yours, not mine

- **`--derive-speed-from-motion`** is deliberately **not** implemented. Differencing `vertex` recovers replay speed to 0.039 m/s, but that is a *derived* value, not a measurement. Whether it may enter Core is a judgement about what "accurate" means here.
- **CARLA 0.9.14 vs 0.9.15** — Bench2Drive's routes need Town12/13. Two stacks, or drop Tier B.
- **Core unfreeze policy.** 21 laws produced 11 gaps (~0.5/law), of which ~18% were `core`-owned. Extrapolated to ~300 obligations that is ~27 explicit unfreeze requests. Without a defined process, that fraction of Part 3 becomes formalizable only as deliberately weakened rules — which show up in evaluation as systematic missed violations and look like a bad monitor when they are a language limit.

---

## 7 · Reproducing any of this

```bash
PY37=pipeline/carla_scene_graphs/.carlasg/bin/python        # CARLA client env, 3.7.10
DS=pipeline/datasets/sceneflowlang/study_data               # 33 captures, 44,455 frames

# the corpus report — no monitor, no labels, no CARLA
cd pipeline/evalkit
export PYTHONPATH=../carla_scene_graphs:../carla_scene_graphs/sim/PythonAPI/carla:.
$PY37 -m evalkit report  --corpus $DS --readings readings/bc_mva_part3.jsonl
$PY37 -m evalkit mutate  --corpus $DS --readings readings/bc_mva_part3.jsonl
$PY37 -m evalkit label   --corpus $DS --readings readings/demo_eu_urban.jsonl
$PY37 tests/test_pipeline.py && $PY37 tests/test_search.py     # 24 + 9

# conversion, with the recording policy applied
cd ../traffic-spec-agent
python3 carla/adapter.py --rsv-dir $DS/scenarios/HazardAtSideLaneTwoWays/rsv \
    --ego-log $DS/scenarios/HazardAtSideLaneTwoWays/ego_logs.json \
    --declare-capture-hz 20 --declare-generator-defaults \
    --declare-capture-mode replay --declare-ego-log-offset 10 \
    --output /tmp/X.lean --module-name X

# the Decimal contract the whole "never fabricate" fix rests on
cd library && lake env lean <<'LEAN'
import TrafficSpec.Core
open TrafficSpec
#eval Decimal.parseMilli "unmeasured"        -- none
#eval Decimal.leMilli "unmeasured" 13888     -- false
#eval Decimal.leMilli "0.0" 13888            -- true   ← what was corrupting 12 rule files
LEAN
```

**Full design write-up:** <https://claude.ai/code/artifact/b5ce4dfc-0cf3-4dff-b3ab-61dc6d05f65b>

---

## Standing rule

Every claim in this document names the call site or the measurement that establishes it. Several things in here started as a plausible reading of a docstring and turned out to be false — the 240-frame ceiling, "control is lost under replay", `threedbbox` being dropped by the abstraction. **Do not trust a docstring over a measurement**, including the docstrings in `src/carlaspec/`, which were machine-written and are not authority.
