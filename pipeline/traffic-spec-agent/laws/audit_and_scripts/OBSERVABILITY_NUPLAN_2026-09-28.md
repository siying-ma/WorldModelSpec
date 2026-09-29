# Observability audit — which corpus lines a nuPlan-sourced evaluation can judge

Date: 2026-09-28. Scope: all 285 lines of `full_list/laws.jsonl`. Method: join each line's
`required_observations` in `evaluation_scenario/scenarios.jsonl` against a per-atom capability
table for the nuPlan source, then refine each hit by the role the scenario's own note says the
atom plays in that line. Reproduced by `python3 audit_and_scripts/observability_nuplan.py`;
the per-line records are `audit_and_scripts/observability_nuplan.jsonl`.

This file is a sidecar and names a data source on purpose. `ontology/ATOMS.md` may not: the
doctor's `named corpus or source` pattern forbids the token there, because the ontology is the
termination rule and must not be decided by what one dataset happens to ship. An atom stays in
Core whether or not nuPlan supplies it; what a source supplies is a **capability manifest**, and
this audit is the evidence for writing one.

## 1. Source profile assumed

`nuPlan` = the camera and lidar blobs (8 cameras `CAM_F0`, `CAM_B0`, `CAM_L0`–`L2`, `CAM_R0`–`R2`,
plus merged point clouds) **with our own perception over them**, the log's ego state, and an HD
map we author into the scene-graph generator. Two consequences of that choice:

- **Facts an HD map or a geometric derivation can supply are not counted as gaps here.** Lane
  adjacency, lane direction, widths, grade, curvature, centre lines, sight distance, kerb zones
  and the legal region classes are authoring work, not observability limits. nuPlan's own map
  supplies lanes, lane connectors, roadblocks, intersections, crosswalks, stop lines, walkways,
  car parks, drivable areas, baseline paths and a per-lane speed limit; everything else in the
  `st.*` family we author.
- **nuPlan's released annotations are not the source.** Its track taxonomy has seven categories —
  vehicle (all four-or-more-wheeled vehicles and trailers), bicycle (which *includes motorcycles
  and tricycles*), pedestrian, traffic_cone, barrier, czone_sign, generic_object — and its
  `lidar_box`/`track` tables carry no lamp, indicator, siren, horn or occupancy field. Judged
  against the released labels alone, most of the 32-atom `ru.*` family and all of `sig.*` would be
  absent. Perception over the video is what makes this corpus addressable at all.

Traffic light state is the one control device nuPlan gives directly: `traffic_light_status` keys
`green | red | unknown` to a **lane connector**, not to a signal head, so `dev.governs` comes free
and `dev.position` does not.

## 2. Verdicts

Three buckets, assigned per atom and then refined per line:

- **blocked** — no path on this source at any effort. The line cannot be judged; it belongs
  outside the evaluation set, not in it with an optimistic manifest.
- **degraded** — obtainable as an estimate with a failure mode that a rule reading it must carry
  as a residue.
- **note_only** — obtainable. The failure mode is recorded here once and no rule carries a residue.

### Refinement by role

The capability table is per atom; what a line needs of the atom is narrower, and the scenario
note records it. Three rules, which between them moved 98 hits out of `blocked`:

1. **A class atom named only as an alternative in a joint subject** ("a bicycle or an electric
   bicycle", "a motorcycle or a moped") does not have to be told from its sibling: the duty falls
   on the union, and the union is observable. This alone accounts for 26 of 27 `ru.electric_bicycle`
   hits and 8 of 10 `ru.moped` hits — the registry gap for these two classes is almost entirely
   an artefact of reading the enumeration literally.
2. **`ru.occupant_count` usually wants a change, not a count.** Twelve of sixteen lines ask
   whether passengers were loaded, unloaded or exchanged; `sig.door_open` with a kerbside
   pedestrian track is the proxy, and it fails only for an exchange through a door the cameras do
   not see. Where the line needs an absolute count it is on an open machine, where the riders are
   in plain view.
3. **A line that states the fact is irrelevant** to the duty is not exposed by it
   (`LVMC-11-52-130-A2`: "attended or unattended").

## 3. Result

| | lines |
|---|---|
| corpus | 285 |
| **blocked** | **30** |
| **degraded** | **98** |
| unaffected | 157 |

Blocked by tier: C 12, Q 11, S 7. Blocked by theme: stopping/standing/parking 8,
cycles_and_devices 4, vulnerable_road_users 3, lamps_and_warnings 3, emergency_and_incident 2,
overtaking 2.

Cause of every blocked or degraded hit:

| cause | hits | recoverable by |
|---|---|---|
| sign legend (the plate is seen; its text is what the rule turns on) | 67 | OCR and a legend grammar |
| officer's gesture / a dark signal head | 30 | a gesture model; rare in the logs either way |
| interior of a cabin | 15 | nothing; 11 of them fall back to a door-and-kerb proxy |
| rider posture on an open machine | 13 | a pose model; fails at range and at night |
| audio | 11 | **a microphone** — the cheapest item on this list, and nuPlan has none |
| designation (`ru.official_vehicle` kinds) | 8 | a register |
| registry / rated facts | 8 | a register |
| rare or novel classes | 6 | more data |
| procession context | 4 | placards, flags, escort |
| residual catch-all class | 4 | nothing; the class has no detector |
| livery (recorded, no residue) | 3 | — |
| **ego-only** (`kin.steer_angle`) | 1 | see §6 |

## 4. Blocked and degraded lines

### blocked

Only the blocked atoms are shown per line; several of these lines also carry
degraded hits, which the JSONL records in full.

| id | tier | title | atom | what the line needs of it |
|---|---|---|---|---|
| `LVMC-11-22-100` | C | New pavement or closed street | `ru.official_vehicle` | the excepted paving employees' vehicles |
| `LVMC-11-22-120-B` | C | Nonmotorized-traffic street closures (B) | `ru.moped` | motor-driven cycles |
| `LVMC-11-27-010-A` | C | Motorized vehicles prohibited—Exceptions (A) | `ru.official_vehicle` | exception (2): maintenance of the right-of-way |
| `LVMC-11-52-030-A` | Q | Curb marking color code (A) | `ru.official_vehicle` | (4) armored cars |
| `LVMC-11-52-340` | C | Municipal vehicles | `ru.official_vehicle` | kind municipal — the entitled class |
| `LVMC-11-52-030-B` | Q | Curb marking color code (B) | `ru.commercial_motor_vehicle`, `ru.occupant_count` | (1) the commercial vehicles entitled; passengers loaded or unloaded |
| `NRS-484B-507-1` | Q | Stopping, standing or parking in zone for lo | `ru.commercial_motor_vehicle` | the class the zone serves |
| `LVMC-11-52-130-A7` | Q | Posted places (A)(7) | `ru.official_vehicle` | the postal vehicle the exception names |
| `NRS-484B-533` | C | Unattended motor vehicle | `ru.occupant_count`, `kin.steer_angle` | 'unattended' — no one aboard; the front wheels turned to the curb or side |
| `LVMC-11-52-305-A` | Q | Commercial vehicles, recreational vehicles a | `ru.commercial_motor_vehicle` | the commercial vehicle |
| `NRS-484B-280-1b` | S | Duties of driver of motor vehicle to pedestr | `sig.horn` | the audible warning |
| `NRS-484B-360-1` | C | Maximum speed of school bus (1) | `ru.occupant_count` | whether pupils are being carried |
| `NRS-484B-553-1` | Q | Obedience to signal indicating approach of r | `sig.horn` | (c) its audible signal within about 1,500 feet |
| `NRS-484B-587-2a` | C | Obedience to signs relating to controlled-ac | `ru.official_vehicle` | tow, coroner, incident-management |
| `NRS-486-351-4` | Q | Unlawful passing (4) | `ru.moped` | the machine |
| `LVMC-11-40-185-B` | S | Electric bicycles and electric scooters (B) | `ru.electric_bicycle` | the machine |
| `NRS-484B-267-1b` | Q | Operation of vehicle on approach of authoriz | `ru.official_vehicle` | tow, coroner, incident-management vehicles |
| `NRS-484D-285-1` | Q | Conditions for use of compression brakes (1) | `sig.compression_brake` | the device in use — audible |
| `NRS-484D-400-2` | S | Horns and other warning devices (2) | `sig.horn` | the horn sounded |
| `NRS-484B-270-5b` | S | Vehicles, bicycles, electric bicycles, elect | `sig.horn` | the audible warning |
| `NRS-484B-270-7b` | S | Vehicles, bicycles, electric bicycles, elect | `ru.occupant_count` | the occupants said to be endangered |
| `NRS-484B-207-2` | C | Overtaking vehicle on left side (2) | `sig.horn` | 'hearing a signal' |
| `NRS-484B-477-1a` | Q | Stopping, standing or parking in alley (1)(a | `ru.commercial_motor_vehicle` | the class typically loading there |
| `NRS-484B-637-2b` | C | “Low-speed vehicle” defined (2)(b) | `ru.low_speed_vehicle` | the subject's class |
| `NRS-484D-400-5` | C | Horns and other warning devices (5) | `sig.siren` | the siren, whistle or bell sounding |
| `NRS-484B-210-1` | Q | When overtaking on right side allowed (1) | `ru.official_vehicle` | tow, coroner, incident-management vehicles |
| `NRS-484B-413-1` | S | Requirements for turning on highway (1) | `sig.horn` | the clearly audible warning owed to that pedestrian |
| `NRS-484B-710` | C | Following fire apparatus prohibited | `sig.siren` | the same |
| `LVMC-11-40-180-C` | C | Sidewalk riding (C) | `sig.horn` | the audible signal — a bell or voice |
| `LVMC-11-12-090` | S | Passing animals | `sig.horn` | a sound that would frighten the animal |

### degraded

Grouped by cause; a line appears under every cause that touches it. These counts
are lower than §3's because a line whose worst hit is `blocked` is listed above, not here.

**sign_legend** (54): `LVMC-11-12-020`, `LVMC-11-18-020`, `LVMC-11-22-130-B`, `LVMC-11-22-130-C`, `LVMC-11-40-070`, `LVMC-11-40-080`, `LVMC-11-40-180-A`, `LVMC-11-40-180-B`, `LVMC-11-42-030`, `LVMC-11-48-050`, `LVMC-11-48-060`, `LVMC-11-52-070`, `LVMC-11-52-130-A2`, `LVMC-11-52-130-A4`, `LVMC-11-60-030-A1`, `LVMC-11-60-030-A5`, `LVMC-11-60-040`, `LVMC-11-60-090`, `NRS-484B-200-1`, `NRS-484B-217-2`, `NRS-484B-220-1`, `NRS-484B-223-2`, `NRS-484B-280-1c`, `NRS-484B-287-1d`, `NRS-484B-287-1e`, `NRS-484B-300-1`, `NRS-484B-307-2a`, `NRS-484B-307-8a`, `NRS-484B-307-8d`, `NRS-484B-307-9b`, `NRS-484B-330-1`, `NRS-484B-363-1`, `NRS-484B-363-2`, `NRS-484B-363-3`, `NRS-484B-363-4`, `NRS-484B-400-2c`, `NRS-484B-403-2`, `NRS-484B-450-1o`, `NRS-484B-457-1`, `NRS-484B-460`, `NRS-484B-490`, `NRS-484B-493`, `NRS-484B-497`, `NRS-484B-500`, `NRS-484B-503`, `NRS-484B-510`, `NRS-484B-517`, `NRS-484B-560-7b`, `NRS-484B-587-1`, `NRS-484B-620-2`, `NRS-484B-630-1`, `NRS-484B-785-1a`, `NRS-484D-100-1`

**rare_gesture** (27): `LVMC-11-16-030`, `LVMC-11-40-070`, `LVMC-11-46-030`, `NRS-484B-100`, `NRS-484B-208-1`, `NRS-484B-250-4`, `NRS-484B-257-1`, `NRS-484B-257-2`, `NRS-484B-267-1a`, `NRS-484B-267-2a`, `NRS-484B-267-2b`, `NRS-484B-267-2c`, `NRS-484B-267-2d`, `NRS-484B-267-2e`, `NRS-484B-267-2f`, `NRS-484B-270-3`, `NRS-484B-283-1a`, `NRS-484B-300-1`, `NRS-484B-330-1`, `NRS-484B-353-1`, `NRS-484B-450-1c`, `NRS-484B-450-1e`, `NRS-484B-450-1g`, `NRS-484B-450-1h`, `NRS-484B-560-7b`, `NRS-484B-703-1`, `NRS-484B-913`

**posture** (12): `LVMC-11-38-040`, `LVMC-11-40-080`, `LVMC-11-40-150`, `LVMC-11-40-180-A`, `NRS-484B-768-1`, `NRS-484B-769`, `NRS-484B-770-1`, `NRS-484B-770-2`, `NRS-484B-780`, `NRS-486-181-1`, `NRS-486-191-1`, `NRS-486-211`

**interior** (8): `LVMC-11-60-030-A2`, `LVMC-11-60-040`, `NRS-484B-153-3`, `NRS-484B-503`, `NRS-484B-510`, `NRS-484B-517`, `NRS-484B-770-2`, `NRS-486-181-1`

**rare_class** (6): `NRS-484B-787-2a`, `NRS-484B-787-2b`, `NRS-484B-787-2c`, `NRS-484B-790-2a`, `NRS-484B-790-2b`, `NRS-484B-790-2c`

**context** (4): `LVMC-11-12-080-A`, `NRS-484B-703-1`, `NRS-484B-707-1`, `NRS-484B-707-2`

**catch_all** (3): `LVMC-11-22-130-A`, `LVMC-11-22-130-B`, `LVMC-11-22-130-C`

**livery** (2): `LVMC-11-60-030-A1`, `LVMC-11-60-030-A2`


## 5. Emergency, fire and school-bus classes — observable, recorded here, no residue

`ru.emergency_vehicle`, `ru.fire_apparatus` and `ru.school_bus` are marked **note_only**: the
marked class is a livery-and-silhouette detection and a detector does it. Two findings support
treating the remainder as a note rather than a per-rule residue:

1. **The corpus does not carry the designation list.** NRS 484A.480(1)–(2), which is where the
   authority designates vehicles — including private cars of physicians, volunteer firefighters
   and licensed ambulances not in livery — is not in `laws.jsonl`. What the corpus carries is
   `DEF-NRS-484A-480-3`, the *equipment* subsection: "Every authorized emergency vehicle must be
   equipped with at least one flashing red warning lamp visible from the front and a siren".
   That is an observable test, not a register lookup. A sweep of all 285 lines for `physician`,
   `volunteer`, `livery` and `unmarked` returns only false positives ("de**livery**", "un**marked**
   crosswalk"): **no line in this corpus turns on the unmarked designated vehicle.**
2. **The duty is keyed on the lamp, not the class.** `drv.responding_emergency` is
   `ru.emergency_vehicle ∧ (sig.warning_lamp red or blue ∨ sig.siren)` — a disjunction, so the
   visible flashing lamp carries it without the siren. The 12 lines that read
   `drv.responding_emergency` are therefore unaffected.

**The failure mode, recorded once:** a vehicle the authority has designated but not marked is
read as an ordinary vehicle. The verdict then comes back *compliant* on a line where the law
would find a violation — a false negative on a priority-vehicle duty. It is not detected by the
pipeline and it is not visible in the per-line records above. Any deployment claim made from
this evaluation set inherits it.

`ru.official_vehicle` is **not** covered by this ruling and stays blocked on 8 lines: its kinds
`regulatory_agency`, `coroner`, `municipal`, `incident_management` and `armored_car` are
designations with no livery, unlike `tow`, `utility` and `highway_maintenance`, which are
livery-visible. The lines are exception clauses that entitle those classes to do what the rule
otherwise forbids, so the failure direction is the opposite one: a violation reported against a
vehicle the law exempts.

## 6. Ego-only, and why Core cannot express it

nuPlan makes this concrete rather than hypothetical. `EgoState` carries `tire_steering_angle`
for the ego and the `ego_pose` table carries `vx, vy, vz`, `acceleration_x/y/z` and
`angular_rate_x/y/z` — all from the vehicle's own bus, all exact. No equivalent exists for any
other agent: another vehicle's velocity is a finite difference of a tracked box, its yaw rate a
second difference, its steering angle nothing at all.

Core cannot state that difference. `Manifest.entries : List (String × Capability)` in
`library/TrafficSpec/Core/Runtime/Manifest.lean` is keyed by **atom id alone**, and `Mask.user` takes an
id and one `RoadUser` and is mapped over every user in the scene. So for `kin.steer_angle` there
are two available declarations and both are wrong:

- `exact` — the rule then evaluates as though the source knew every agent's steering angle, and
  `NRS-484B-533` reports a verdict about a parked third-party vehicle on evidence that does not
  exist.
- `absent` — `Mask.user` blanks the field for everyone **including the ego**, so the one case the
  log answers exactly becomes `unknown`.

The same split applies to `kin.accel_longitudinal` and `kin.yaw_rate` (exact for the ego, a
derivative of a noisy track for others) and to `sig.turn_indicator` and `ru.occupant_count`
(introspection for the ego, perception for others). It is not a corner case: rules quantify over
other users — `.forallUser "o"` — so a single formula reads the same atom at both roles.

Note also `Mask.user`'s first line, `| "ru.subject" => u`: masking the subject atom is a
deliberate no-op, which assumes the source always knows whose conduct is judged. True when the
ego is the subject; false the moment a third-party vehicle is.

**Minimal fix**, not applied: key `entries` by `(atomId, role)` with `role ∈ {subject, other,
any}`, resolve `any` as the fallback, and thread the role through `Mask.user`/`Mask.scene` from
the binder that introduced the track. `Manifest.support` changes with it. This is a Core change
and drags the generated tables and the doctor, so it wants a plan of its own.

## 7. What this audit does not cover

- **No manifest exists yet.** There is no source manifest anywhere in the tree;
  `Build.manifest` starts from `Manifest.full "witness"`, which declares all atoms `exact`.
  Every rule the pipeline has accepted was accepted against an omniscient source, and
  `Manifest.support` has never been run on anything else. Writing `manifests/nuplan.json` from
  the table in §3 and running `support` over the rule set is the next step; it reports which
  lines are addressable **before** any more coding tokens are spent.
- **Coverage is not observability.** `env.ice_or_snow` (2 lines) and `env.precipitation` (8) are
  observable and will simply never be exercised in Las Vegas logs. That is a sampling gap, and it
  belongs in a separate count.
- **Error classes are named, not measured.** "estimate" here means a failure mode has been
  identified, not that its magnitude has been calibrated against the sampling-adequacy bounds
  Core checks.
