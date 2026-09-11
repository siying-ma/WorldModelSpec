# What the scene graph cannot tell you

An inventory of what `carla_sgg` does not deliver to a Lean specification, and —
the part that decides what to do about each one — **where** it stops being
available.

Four places, and they are not interchangeable:

| # | Category | Fixable without editing `carla_sgg/`? |
|---|---|---|
| **A** | The generator never asks CARLA for it | ✗ needs a collector of our own |
| **B** | On the base graph; `process_to_junction_rsv` destroys it | ✗ `carla_sgg/` is byte-frozen |
| **C** | Survives into the RSV; `carla/adapter.py` does not lift it | **✓ adapter change only** |
| **D** | Present and well-formed, but not a measurement | ✓ already handled in the adapter |

Getting a datum into the wrong category is expensive in both directions: a
category-C item written off as a generator limitation is a capability thrown
away for nothing, and a category-B item planned as an adapter change is work
that cannot land.

## How this was established

Measured, not read off the source. Two instruments:

1. **Corpus scan** — every attribute key on every node of 299 sampled frames
   across the SceneFlowLang study corpus (33 captures; 130 frame-loads failed on
   a shapely-2 pickle and were skipped). 6,062 attributed nodes.
2. **Abstraction fixture** — a hand-built base graph in the shape `sgg.py`
   produces, pushed through `process_to_junction_rsv`, to separate "the
   abstraction drops it" from "this corpus never had it".

The fixture matters. A key missing from the corpus proves only that *this*
corpus lacks it; it does not prove the abstraction destroys it. `threedbbox` is
exactly that case, and the two instruments disagree — see §C.

---

## A. Never collected

The generator does not call the CARLA API at all. Nothing downstream can
recover these; they need a collector beside the SGG.

| Datum | Evidence | Blocks |
|---|---|---|
| **Crosswalk geometry** | `carla.Map.get_crosswalks()` — **0 hits** anywhere in `carla_sgg/` | Every pedestrian-crossing clause. 4 of Bench2Drive's 44 scenarios are crossing scenarios |
| **Adjacent-lane enumeration** | `get_left_lane()` / `get_right_lane()` — **0 hits** | "travel in a right-hand lane" on a road with more than two lanes: the RSV has `toLeftOf` / `toRightOf` edges between lane nodes but no lane count or index |
| **Stop-line waypoints** | `TrafficLight.get_stop_waypoints()` — **0 hits**. A signal reaches lanes through `controlsTrafficOf`, which is an affected-lane test, not a line | "stop *before the marked stop line*". The junction boundary is the only available stand-in, and it lies past the line |
| **Non-ego dynamics** | `copy_carla_actor_state` is called at `sgg.py:563` for the ego node **and nowhere else**. Measured: 1,487 non-ego nodes across 3 live captures, **zero** carry `carla_speed`, `carla_vel_*`, `carla_acc_*` or `carla_ang_vel_*` | Any rule whose binder reads another vehicle's motion. `Pred.stopped` on a non-ego actor is false whatever that actor is doing — not "stopped", **false in both directions** |

> The non-ego row is the one that most changes how rules must be written. It is
> not a zero and not a wrong number: `getAttr` returns `none`, so
> `Pred.attrMilli*` is `false` for `≤` and `≥` alike. A binder over two vehicles
> that gates on the other's speed can never engage, and the rule is vacuous
> rather than wrong. `Core/Builders.lean` states this on `mkActor`: *"Non-ego
> actors carry no dynamics channels — that is a property of the data source."*

## B. On the base graph, destroyed by the abstraction

`sgg.py:203` builds each driving node with a rich waypoint record. **RSV lane,
road and junction nodes carry zero attributes.** Measured on a real frame:

```
(node kind, attribute count) -> {('Lane', 0): 29, ('Road', 0): 17,
                                 ('Junction', 0): 2, ('Off Road', 0): 1}
base_class on a lane node: None
```

Everything the base graph knew about a lane is gone except its identity, and
that survives only as text inside the node *name* — `Lane 584_-1` — which the
adapter parses back out.

| Destroyed | On the base graph as | Blocks |
|---|---|---|
| **Lane heading** | `forward` / `right` / `up` on every driving node | Every wrong-way and keep-right clause. Nothing in the RSV says which way a lane runs, so "the ego is facing against the flow" is not expressible at all |
| **Lane width** | `lane_width` (read at `sgg.py`, 1 hit) | Lateral-clearance clauses that are stated relative to the lane |
| **Lane markings** | `left_/right_lane_marking_{color,type,width,lane_change}` | Every no-passing / solid-line clause |
| **`waypoint_s`, `is_junction`, `curve`, `angle`, `section_id`, `lane_change`** | all present at `sgg.py:203-215` | Curvature-dependent clauses (a U-turn "on a curve"); junction membership survives only through the `Road → Junction` `isIn` edge |

`carla_sgg/` is frozen byte-wise, so none of this is an adapter change. The
resolution has to re-route to a collector of our own, or to "absent".

## C. In the RSV, but not lifted by the adapter — **fixable here**

These reach `rsv/*.pkl` intact and stop at `carla/adapter.py`. They are the
cheap wins, and they do not touch `carla_sgg/`.

| Key | Status | What it would unlock |
|---|---|---|
| **`threedbbox`** | **Preserved by the abstraction — verified.** `__add_actor_to_graph` (`sgg.py:835-837`) passes `parse3dbb(actor, transform)`, `__add_to_graph` writes it at `sgg.py:798`, and `process_to_junction_rsv:241` passes the whole base-graph attribute dict through by reference. A fixture carrying an 8×3 bbox comes out the far side with `threedbbox` intact on both the ego and a car node. | **Body-to-body distances.** The 8 world-space box vertices give each actor's true extent, hence a **bumper gap** and a **lateral clearance**. Every "within N metres of the vehicle in front" is currently centre-to-centre, which for two 4.7 m cars is about 4.7 m looser than the statute means; and the 1.0 m / 1.5 m passing clearance for a cyclist is not computable at all without a half-width |
| `landmark_*` geometry | emitted, not lifted (`schema.json → available_not_exposed.landmark_physical_geometry`) | Sign pose and applicability detail |
| `right`, `up`, `vertex_point` | emitted, not lifted (`schema.json → available_not_exposed.volume`) | Actor orientation beyond `forward` |

> **`threedbbox` is absent from the SceneFlowLang corpus (0 of 6,062 nodes)
> while `vertex_point`, `right`, `up` and `entity_id` — set in the same
> `graph.add_node` call — are on all 6,062.** That corpus was produced by an
> upstream generator version predating the field; it is not evidence about the
> abstraction. The fixture is. Any capture recorded with the vendored generator
> will carry it.
>
> Lifting the raw array would add 24 numbers per actor per frame, which is why
> `schema.json` files it under `volume`. The useful form is two derived scalars
> — half-length and half-width — computed in the adapter from the box, in the
> frame the box came from.

## D. Present, well-formed, and not a measurement

A CARLA **recorder replay** teleports actors instead of integrating physics, so
`get_velocity()`, `get_acceleration()` and `get_angular_velocity()` return zero
while `get_control()` still returns the real inputs. This is a property of
CARLA, not a defect in `carla_sgg`: the same generator produces correct
dynamics live.

| | replay capture | live capture |
|---|---|---|
| `carla_speed`, `carla_vel_x` max | **0.000** | 6.667 |
| `\|carla_acc\|` max | 0.011 | **12.690** |
| `\|carla_ang_vel_z\|` max | **0.000** | **16.354** |
| `carla_throttle` / `carla_brake` | **0.8 / 0.3 — intact** | intact |

Handled in `carla/adapter.py`: `speed`, `accel` and `yaw_rate` are emitted as
`unmeasured`, and `vel_*` / `acc_*` / `roll_rate` / `pitch_rate` are suppressed
by key. `Core/Decimal.parseMilli` returns `none` for an unparseable value and
every comparison documents that it then reads **false**, so those channels carry
no evidence in either direction — which is what "we did not measure it" means.

The fabricated `0.0` this replaced was not neutral. Verified in Lean:

```
Pred.stopped                   zeroed=true   unmeasured=false   ← 12 of 24 rule files
Pred.speedLeKph 50             zeroed=true   unmeasured=false   ← urban_default_limit
Pred.notTurning 5000           zeroed=true   unmeasured=false
Pred.accelMagnitudeAtMost 500  zeroed=true   unmeasured=false
```

A second, independent defect lives beside it: **the scene-graph frame index and
the ego-log record index have different origins.** `capture_sensor_data.py:437`
ticks the world ten times to warm five sensors up *after* `replay_file()` has
started, and takes `start_frame` after those ticks, while `add_agent_delay()`
has already re-based `ego_logs.json` to tick 0. So `rsv/i.pkl` is replay tick
*i*+10. Verified by position, which both files record independently: mean error
**3.452 m at offset 0, 0.039 m at +10**, on all three logged captures. Declare
`recording.ego_log_frame_offset` in the capture manifest.

---

## Re-verifying this document

```bash
PY=.carlasg/bin/python
export PYTHONPATH=.:sim/PythonAPI/carla

# A — the generator's CARLA API surface
grep -c get_crosswalks carla_sgg/sgg.py        # 0
grep -c get_left_lane  carla_sgg/sgg.py        # 0
grep -n copy_carla_actor_state carla_sgg/sgg.py # one call site, the ego

# B — what a real RSV lane node carries
$PY -c "import pickle; g=pickle.load(open('<capture>/rsv/274.pkl','rb'));
print([(str(n), len(getattr(n,'attr',{}) or {})) for n in g.nodes][:5])"

# C — does the abstraction drop threedbbox? Build a fixture, push it through
#     process_to_junction_rsv, inspect the far side. It does not.
```

Nothing here should be taken from this file alone. Each row names the call site
or the measurement that establishes it; a claim that cannot be re-derived that
way has no business in an inventory whose whole purpose is deciding what work is
possible.
