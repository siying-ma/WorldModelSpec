# Scenario captures for traffic-spec-agent

Records **compliant/violating counterpart captures** in CARLA for each traffic law
formalized in `../../traffic-spec-agent/library/TrafficSpec/Rules/`, together
with ground truth read from the CARLA server, so the Lean specifications can be
checked against footage instead of only against the acceptance scenarios the plan
agent wrote for them.

The point of running the two counterparts together is that a single capture
cannot tell you much. A rule that reports `compliant` on lawful footage may be
right, or may be incapable of reporting anything else. Only the pair separates
those, and `run_spec monitor --database` on the spec side scores exactly that.

## Layout

```
src/
├── run_capture.py            CLI: record one scenario, or all of them
├── relabel.py                re-derive labels from an existing oracle.jsonl
└── carlaspec/
    ├── runner.py             the capture loop — sync mode, SGG, camera, cleanup
    ├── scenario.py           the Scenario interface and registry
    ├── oracle.py             per-tick ground truth from the CARLA server API
    ├── labeler.py            oracle.jsonl -> labels.json, one verdict per law
    ├── geometry.py           map and actor queries the oracle needs
    ├── driving.py            shared manoeuvres (approach selection, signal pinning,
    │                         a pure-pursuit driver for wrong-way runs)
    ├── compat.py             NumPy 2 shim for carla_sgg
    └── scenarios/            one module per law
```

Adding a scenario means adding a module under `scenarios/` and importing it in
`scenarios/__init__.py`. Nothing else changes: the CARLA connection, synchronous
mode, spawning, the SGG loop, the camera queue, the oracle, the label file and
teardown are written once in `runner.py`.

## Scenarios

| scenario | law | rules exercised | how the modes differ |
|---|---|---|---|
| `max_speed` | EX-SPEED-001 | R0001 | `set_desired_speed` 35 vs 80 km/h |
| `junction_speed` | EX-SPEED-002 | R0002 | 18 vs 55 km/h through a green-pinned junction |
| `following` | EX-FOLLOW-001 | R0003, R0010 | `distance_to_leading_vehicle` 12 m vs 0.3 m |
| `red_light` | EX-SIGNAL-001 | R0004 | `ignore_lights_percentage` 0 vs 100 |
| `stop_sign` | EX-STOP-001 | R0005 | scripted 1.5 s halt vs `ignore_signs_percentage` 100 |
| `junction_yield` | EX-JUNCTION-001 | R0006 | `ignore_vehicles_percentage` 0 vs 100 |
| `keep_right` | EX-LANE-001 | R0011 | starts in the kerbside vs an inner lane |
| `oncoming` | EX-LANE-001 | R0008 | own lane vs driven up the opposing one |
| `emergency_pull_right` | EX-EMERGENCY-001 | R0012 | kerbside vs inner lane as a police car closes |
| `emergency_junction` | EX-EMERGENCY-001 | R0013 | drives through vs stalls inside the junction |

`red_light`, `max_speed`, `emergency_junction` and `junction_yield` have been run
end to end, both counterparts each, and are in `database/`. The remaining six are
written but unrecorded — expect the first run of each to need a seed or town
adjustment, and watch the two `[FAIL]` lines, which are there to catch exactly
that.

Every scenario is 12 s (240 frames at 20 Hz), which is the ceiling
`max_capture_frames` imposes. It is not a stylistic choice: nine of the ten used
to declare 22-30 s and silently receive 12, so their approaches and closing
vehicles were choreographed against a length that never existed. The runner now
**refuses** a scenario whose declared `duration` exceeds the ceiling instead of
truncating it.

## Usage

Start a server (the vendored build is under `../sim/`):

```bash
./sim/CarlaUE4.sh -RenderOffscreen -nosound -carla-server -world-port=2000
```

Then, with the `.carlasg` environment:

```bash
python src/run_capture.py --list
python src/run_capture.py --scenario red_light            # both counterparts
python src/run_capture.py --scenario red_light --mode violation
python src/run_capture.py --all --summary /tmp/captures.json
```

Each capture writes `database/<scenario>_<mode>/`:

```
rsv/{0..N}.pkl     process_to_junction_rsv frames, what the Lean rules see
ego_logs.json      per-frame ego control/state, 1:1 with rsv/
camera/*.png       RGB stills, for spot-checking the labels by eye
oracle.jsonl       per-frame CARLA-server ground truth
labels.json        one verdict per law, derived from oracle.jsonl
simulation.json    what was configured and what actually happened
```

Score them against the library:

```bash
cd ../../traffic-spec-agent
python -m scripts.run_spec monitor \
    --database ../sg/carla_scene_graphs/database \
    --adapter-python ../sg/carla_scene_graphs/.carlasg/bin/python
```

One command evaluates every capture in the directory, and additionally pairs
`<scenario>_compliant` with `<scenario>_violation` to report whether the library
separates lawful from unlawful — the question a single capture cannot answer.

## Where the labels come from

`labels.json` is derived mechanically from `oracle.jsonl`, which is recorded from
the CARLA server: actor transforms and bounding boxes, OpenDRIVE waypoints, and
each junction's traffic lights. It does not pass through `carla_sgg`'s
abstraction or through Lean, so a disagreement between a label and a `monitor`
verdict is a real finding about the specification, the abstraction, or the
adapter.

`labeler.py` tags every threshold with its provenance:

* **statute** — stated in the law text (50 km/h, 30 km/h, four metres, one second)
* **reading** — the statute is qualitative and the module quantifies it, e.g.
  "shall not *remain* within four metres" as 0.2 s
* **rule** — the statute gives no figure at all and the number is borrowed from
  the Lean rule. Only EX-EMERGENCY-001 is in this category, and its label
  therefore cannot falsify R0012/R0013's constants, only whether they fire on
  the right situation.

Three safeguards keep a capture from proving nothing:

* Each scenario declares `target_laws`, and the runner **fails** the capture when
  a target law comes out `not_applicable`. A red-light run that never reached a
  red signal is reported as a failure and retried with a new seed, rather than
  silently scoring as agreement.
* The runner also **fails** the capture when a target law was engaged but came
  out the wrong way round for the mode — a `compliant` run whose ground truth
  reads `violated` is not a lawful counterpart. Without this,
  `emergency_junction_compliant` scored `ok: true` while its own label said
  `violated`, and `capture_bench` then reported the pair `TRIGGER-HAPPY` and
  billed it to the Lean rule instead of to the capture.
* Signals are pinned with `TrafficLight.freeze` before the first captured frame,
  so the situation under test does not depend on catching the phase by luck.

A fourth check only warns: if a capture violates a law it does not target, the
runner says so. A counterpart pair is attributable only when its two runs differ
in one respect, and several scenarios still set `ignore_lights_percentage(ego,
100)` to keep the ego moving, which buys an incidental EX-SIGNAL-001 violation.
`emergency_junction` and `junction_yield` no longer do: they pin the approach
green and obey it.

## Things that bit, and are now handled

**`agents` is not installed.** `carla_sgg.sgg.init_to_world` imports
`agents.navigation.global_route_planner`, which ships as loose source under
`sim/PythonAPI/carla/` and is not part of the `carla` wheel. `paths.py` puts it on
`sys.path`; without that, building an `SGG` fails immediately.

**NumPy 2.** `carla_sgg/sgg.py:334` calls `np.nan_to_num(x, 0)`, whose second
positional parameter is `copy`, not `nan`. NumPy 2 raises on it and map indexing
dies. `compat.py` drops the stray argument, which gives `nan=0.0` — both the
default and what the call was written to mean. `carla_sgg/` itself is left
byte-identical to upstream, because `traffic-spec-agent/carla/schema.json` cites
its line numbers.

**Vehicle lights are off unless something drives them.** A non-ego vehicle's
light booleans are the only dynamic evidence the abstraction keeps about it, and
R0010's antecedent reads the lead's brake light. The runner enables
`TrafficManager.update_vehicle_lights` for every vehicle it spawns; without it
that rule grounds and is trivially satisfied on every capture.

**The ambulance is invisible to distance rules.** `carla_sgg` emits proximity
edges only for the base classes in `DEFAULT_PROXIMITY_RELATIONS`, and
`vehicle.ford.ambulance` is a `van`, which is not one of them. The emergency
scenarios use `vehicle.dodge.charger_police` (base class `car`), and the oracle
records `proximity_edge_possible` per actor so a future change back to a van
shows up in the label file instead of quietly reading as compliance.

**Junction complexes.** Choosing a start by scanning spawn points for "a junction
ahead" put the ego inside Town03's junction 861 — tens of metres across — from
the third second, so it never had an outside-the-intersection approach.
`driving.approach_to_traffic_light` works backwards from a light's own
`get_stop_waypoints()` instead, and guarantees a clean approach with the junction
beginning just past the stop line.


**Which light is nearest is not which light governs you.** `pin_light` reds a
light's whole group before greening the one it was handed, so pinning the wrong
head green sets the ego's own head *red*. At a junction every approach's head
sits a few metres from every other, and picking by Euclidean distance
(`nearest_light_ahead`) reliably gets a sibling: the first attempt at holding
`emergency_junction`'s approach green left the ego stopped at a red for all 240
frames with `0 in a junction`. `driving.light_governing_lane` indexes lights by
`get_stop_waypoints()` and matches on the ego's own lane, the same way
`oracle.py::_index_lights` does and for the same reason.

**A CARLA red phase outlasts a whole capture.** `junction_yield`'s compliant ego
obeyed its signal, met a red, stopped 27.9 m short at frame 55 and never moved
again — `frames_in_junction: 0`, target law `not_applicable`, capture failed. No
`--seed` can fix that: the seed drives the Traffic Manager and the background
spawns, not the signal phase, so all three attempts failed identically. A
scenario that is not *about* the signal must pin it rather than leave it to
chance; ignoring it instead buys a second, untargeted offence.

**Interrupts used to leave a half-written capture.** `except Exception` does not
catch `KeyboardInterrupt`, so Ctrl-C skipped `_finalize` and left a directory
holding `rsv/` and `camera/` with no `oracle.jsonl`, `labels.json` or
`simulation.json` — which `capture_bench.discover` then reports as an
`INCOMPLETE` pair, and which a re-run without `--overwrite` sidesteps into
`<name>_2` rather than replacing. The runner now finalizes what it has and
re-raises, so the batch still stops.

**Timing two vehicles into one junction is a race you lose.** `junction_yield`
used to spawn its cross vehicle 22 m back and release it immediately, which its
own docstring called "timed". Measured on the Town03 approach the scenario picks,
the ego reaches the junction 31 frames before a cross vehicle released at the
same moment — it cannot win that race by tuning. The cross vehicle now drives in
and *stops* inside the box for 2 s, which makes the antecedent R0006 needs a
certainty rather than a coincidence.

**The Traffic Manager will not yield across a junction.**
`ignore_vehicles_percentage(ego, 0)` looks along the ego's own lane, and a
vehicle stopped across a 25 m junction on a different approach is not in it — so
the compliant ego drove into the occupied junction exactly like the violating
one. The compliant half is now scripted, as `stop_sign`'s dwell already was, and
the label is still read back out of `oracle.jsonl`.


`Scenario.max_capture_frames` (240 = 12 s) bounds capture length and is now
enforced rather than applied silently; keep it comfortably above the longest rule
window (80 frames = 4 s).
