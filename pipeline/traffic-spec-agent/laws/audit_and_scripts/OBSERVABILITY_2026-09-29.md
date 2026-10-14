# Observability audit — what the two sources can judge, and what left the corpus

Date: 2026-09-29. Scope: all 272 lines of `full_list/laws.jsonl`. Method: join each line's
`required_observations` in `pipeline/evaluation/evaluation_scenario/scenarios.jsonl` against a per-atom capability
table, then refine each hit by the role the scenario's own note says the atom plays in that line.
Reproduced by `python3 audit_and_scripts/observability_nuplan.py`; per-line records in
`audit_and_scripts/observability_nuplan.jsonl`.

**Outcome: 4 lines left the corpus for `unobservable.jsonl`, 3 stay under a required residue, and
nothing is lost to registry or legal designation.** The corpus went 285 → 281 on that count; a further 9 rider-posture lines then went to
`excluded.jsonl` (§5), leaving 272. The test set went 29 → 28.

A sidecar names a data source on purpose. `ontology/ATOMS.md` may not — the doctor's
`named corpus or source` pattern forbids the token there, because the ontology is the termination
rule and must not be decided by what a dataset happens to ship. An atom stays in Core whether or
not a source supplies it: `sig.horn` and `sig.compression_brake` remain in the ontology and are
now zero-support, recorded in `split_atoms.json` under `zero_support_atoms_kept_in_train`.

## 1. The two sources

- **Simulation — CARLA.** Ground truth for every agent: class, kinematics, lamps, occupancy,
  rider posture, steering angle. **A siren is available**, as `carla.VehicleLightState.Special1`
  (`0x1 << 9`) and `Special2` (`0x1 << 10`), which `LibCarla/source/carla/rpc/VehicleLightState.h`
  comments as reserved for sirens. **A horn is not**: `carla.Vehicle` exposes no horn and CARLA
  has no audio API at all.
- **Real video — nuPlan.** The camera and lidar blobs (8 cameras `CAM_F0`, `CAM_B0`,
  `CAM_L0`–`L2`, `CAM_R0`–`R2`, plus merged point clouds) **with our own perception over them**,
  the log's ego state, and an HD map we author into the scene-graph generator. It covers
  **us-nv-las-vegas-strip** — the jurisdiction this corpus is drawn from. It carries no
  microphone.

**What `sig.siren` actually is on both sources.** The atom's contract is "a siren, whistle or bell
**sounding**". Neither source delivers that. CARLA delivers a light flag; video delivers a visible
light bar. For the `drv.responding_emergency` disjunction — `ru.emergency_vehicle ∧
(sig.warning_lamp red or blue ∨ sig.siren)` — the substitution is harmless, because the other
disjunct is the lamp anyway. For one line it is not harmless, and that line is §3. A manifest
should therefore declare `sig.siren` as `estimate`, never `exact`.

Two things follow from choosing perception-over-video rather than nuPlan's released labels:

- **Facts an HD map or a geometric derivation supplies are not gaps.** Lane adjacency and
  direction, widths, grade, curvature, centre lines, sight distance, kerb zones and the legal
  region classes are authoring work. nuPlan's map supplies lanes, lane connectors, roadblocks,
  intersections, crosswalks, stop lines, walkways, car parks, drivable areas, baseline paths and
  a per-lane speed limit; the rest of `st.*` we author.
- **The released labels are not the source.** nuPlan's track taxonomy has seven categories —
  vehicle (all four-or-more-wheeled vehicles and trailers), bicycle (which *includes motorcycles
  and tricycles*), pedestrian, traffic_cone, barrier, czone_sign, generic_object — and its
  `lidar_box`/`track` tables carry no lamp, indicator, siren, horn or occupancy field. On labels
  alone most of the `ru.*` family and all of `sig.*` would be absent.

Traffic light state is the one control device nuPlan gives directly: `traffic_light_status` keys
`green | red | unknown` to a **lane connector**, not to a signal head, so `dev.governs` comes free
and `dev.position` does not.

## 2. Lines removed from the corpus

A line leaves the corpus only when **every** duty it imposes rests on a signal no planned source
observes. The set lives in `nrs_tools/tiers.py` as `UNOBSERVABLE` and is published to
`audit_and_scripts/unobservable.jsonl`. It is deliberately a separate view from `excluded.jsonl`,
whose members are kept out for a reason in the law (apparel, equipment legality, a permission):
these four are kept out for a reason in the **source**, and the decision reverses the day a
microphone is added.

| id | tier | why |
|---|---|---|
| `NRS-484B-270-5b` | S | the whole duty is an audible warning with the horn |
| `NRS-484B-280-1b` | S | the whole duty is an audible warning with the horn |
| `NRS-484D-400-2` | S | both limbs are the horn — sounding it when necessary, and not otherwise |
| `NRS-484D-285-1` | Q | the conduct judged is use of a compression brake, whose statutory test is that it is audible |

Nothing cascaded: no surviving line referenced any of the four, so no new `removed_target` residue
was created. `NRS-484B-270-5a` and `NRS-484B-280-1a` — the other paragraphs of the same two
subsections — stay in the corpus, so the surrounding duties are preserved.

**Cost to the split.** `NRS-484D-285-1` was in the test set precisely because it introduced
`sig.compression_brake`. It was the split's only *new signal atom* cluster, so the test set no
longer measures extending the ontology with a new signal. Test-only atoms fell 14 → 13 and the
test set 29 → 28 (10.0% of 281). Choosing a replacement cluster is a test-design decision and was
not made here.

## 3. Lines kept under a required residue

These impose an audio duty **beside** an observable one. Removing them would discard the
observable duty, so they stay and any rule written for them must carry the residue named here.

| id | tier | atom | the residue it must carry |
|---|---|---|---|
| `NRS-484D-400-5` | C | `sig.siren` | sig.siren is supplied as a special light flag in simulation and as a visible light bar on video, never as sound; this line's obligation is a siren-use prohibition, and its own last sentence permits operating the warning lamps WITHOUT the siren, so the exempt case is indistinguishable from the offence and the verdict may report a violation against it |
| `NRS-484B-413-1` | S | `sig.horn` | the audible warning owed to a pedestrian is not evaluated; the line's other duty, an appropriate signal to affected vehicles, and its precondition that the turn be made with reasonable safety, both are |
| `LVMC-11-40-180-C` | C | `sig.horn` | the audible signal owed before overtaking a pedestrian is not evaluated; the yield duty the same sentence imposes is |

`NRS-484D-400-5` is the sharpest case and the reason `sig.siren` must be declared `estimate`: it
is the one line whose text itself distinguishes the lamp from the siren, so the light-for-sound
substitution reads the expressly exempt case as the offence.

### Audio present, but a visible limb carries the duty — no residue owed

| id | tier | atom | the limb that still carries the duty |
|---|---|---|---|
| `NRS-484B-553-1` | Q | `sig.horn` | limb (c), the train's audible signal, is one of three warnings; limbs (a) a signal device and (b) a lowered gate or a flagger are visible and engage the same duty |
| `NRS-484B-207-2` | C | `sig.horn` | the trigger is disjunctive -- 'upon observing the overtaking vehicle OR hearing a signal' -- and the visual limb engages the duty; only an overtaken driver who could hear but not see is missed |
| `NRS-484B-710` | C | `sig.siren` | the responding state is evidenced by sig.warning_lamp or sig.siren, and NRS 484A.480(3) requires the lamp, so the visible limb carries the trigger |
| `LVMC-11-12-090` | S | `sig.horn` | the horn appears inside the standard ('every reasonable precaution to prevent the frightening'); the duties the line imposes -- reduce speed, do not proceed on request -- are observable |

## 4. Everything else is evaluable

| | lines |
|---|---|
| corpus | 272 |
| kept under a required residue | 3 |
| degraded — evaluable, residue names the failure mode | 103 |
| unaffected | 166 |

| cause | lines | recoverable by |
|---|---|---|
| sign legend (the plate is seen; its text is what the rule turns on) | 67 | OCR and a legend grammar |
| officer's gesture / a dark signal head | 30 | a gesture model; rare in real logs either way |
| rare or novel classes | 6 | more data |
| procession context | 4 | placards, flags, escort |
| residual catch-all class | 4 | nothing; the class has no detector |
| audio, with a visible limb | 4 | — the visible limb suffices |

Resolved on 2026-09-29 and reflected in the capability table — each of these is `note_only`, so no
rule carries a residue for it:

| question | ruling |
|---|---|
| interior (`ru.occupant_count`) | read from the video; **not representable in simulation** — see §5 |
| rider posture (`ru.rider_posture`) | read from the video on an open machine; **not representable in simulation** — see §5 |
| ego-only (`kin.steer_angle`) | exact for every vehicle in CARLA, and for the ego on video; the Core limitation stays open, §8 |
| registry / designation | only a line turning on a vehicle the authority designates **without marking it** counts as affected, and no line in this corpus does |

### Refinement by role

The capability table is per atom; what a line needs of the atom is narrower, and the scenario note
records it. Refinement only ever **relaxes** a verdict — the table is the ceiling. Three rules:

1. **A class named only as an alternative in a joint subject** ("a bicycle or an electric
   bicycle", "a motorcycle or a moped") need not be told from its sibling: the duty falls on the
   union, and the union is observable. 26 of 27 `ru.electric_bicycle` hits and 8 of 10 `ru.moped`
   hits are of this kind.
2. **An audio atom with a visible limb** — where the statute states the trigger or the warning
   disjunctively and the other limb is visible, the duty still engages.
3. **A line that states the fact is irrelevant** to the duty is not exposed by it
   (`LVMC-11-52-130-A2`: "attended or unattended").

### Degraded, by cause

Grouped by cause; a line appears under every cause that touches it.

**sign_legend** (65): `LVMC-11-12-020`, `LVMC-11-18-020`, `LVMC-11-22-100`, `LVMC-11-22-120-B`, `LVMC-11-22-130-B`, `LVMC-11-22-130-C`, `LVMC-11-27-010-A`, `LVMC-11-40-070`, `LVMC-11-40-080`, `LVMC-11-40-180-A`, `LVMC-11-40-180-B`, `LVMC-11-42-030`, `LVMC-11-48-050`, `LVMC-11-48-060`, `LVMC-11-52-030-A`, `LVMC-11-52-030-B`, `LVMC-11-52-070`, `LVMC-11-52-130-A2`, `LVMC-11-52-130-A4`, `LVMC-11-52-130-A7`, `LVMC-11-52-305-A`, `LVMC-11-52-340`, `LVMC-11-60-030-A1`, `LVMC-11-60-030-A5`, `LVMC-11-60-040`, `LVMC-11-60-090`, `NRS-484B-200-1`, `NRS-484B-210-1`, `NRS-484B-217-2`, `NRS-484B-220-1`, `NRS-484B-223-2`, `NRS-484B-267-1b`, `NRS-484B-280-1c`, `NRS-484B-287-1d`, `NRS-484B-287-1e`, `NRS-484B-300-1`, `NRS-484B-307-2a`, `NRS-484B-307-8a`, `NRS-484B-307-8d`, `NRS-484B-307-9b`, `NRS-484B-330-1`, `NRS-484B-363-1`, `NRS-484B-363-2`, `NRS-484B-363-3`, `NRS-484B-363-4`, `NRS-484B-400-2c`, `NRS-484B-403-2`, `NRS-484B-450-1o`, `NRS-484B-457-1`, `NRS-484B-460`, `NRS-484B-490`, `NRS-484B-493`, `NRS-484B-497`, `NRS-484B-500`, `NRS-484B-503`, `NRS-484B-507-1`, `NRS-484B-510`, `NRS-484B-517`, `NRS-484B-560-7b`, `NRS-484B-587-1`, `NRS-484B-587-2a`, `NRS-484B-620-2`, `NRS-484B-630-1`, `NRS-484B-785-1a`, `NRS-484D-100-1`

**rare_gesture** (30): `LVMC-11-16-030`, `LVMC-11-22-100`, `LVMC-11-40-070`, `LVMC-11-46-030`, `NRS-484B-100`, `NRS-484B-208-1`, `NRS-484B-250-4`, `NRS-484B-257-1`, `NRS-484B-257-2`, `NRS-484B-267-1a`, `NRS-484B-267-2a`, `NRS-484B-267-2b`, `NRS-484B-267-2c`, `NRS-484B-267-2d`, `NRS-484B-267-2e`, `NRS-484B-267-2f`, `NRS-484B-270-3`, `NRS-484B-283-1a`, `NRS-484B-300-1`, `NRS-484B-330-1`, `NRS-484B-353-1`, `NRS-484B-450-1c`, `NRS-484B-450-1e`, `NRS-484B-450-1g`, `NRS-484B-450-1h`, `NRS-484B-553-1`, `NRS-484B-560-7b`, `NRS-484B-703-1`, `NRS-484B-913`, `NRS-486-351-4`

**rare_class** (6): `NRS-484B-787-2a`, `NRS-484B-787-2b`, `NRS-484B-787-2c`, `NRS-484B-790-2a`, `NRS-484B-790-2b`, `NRS-484B-790-2c`

**catch_all** (4): `LVMC-11-22-120-B`, `LVMC-11-22-130-A`, `LVMC-11-22-130-B`, `LVMC-11-22-130-C`

**context** (4): `LVMC-11-12-080-A`, `NRS-484B-703-1`, `NRS-484B-707-1`, `NRS-484B-707-2`

## 5. Interior, posture and steering — what each atom means, and where each source fails

Three atoms are easily confused with one another, so the contracts first. Two of them are not
gestures, and the one gesture-like atom in the neighbourhood belongs to somebody else entirely:

| atom | what it is | values |
|---|---|---|
| `ru.rider_posture` | **how a rider sits and holds the machine** — a static body configuration, and explicitly *"not a stand-in for: a manoeuvre"* | `on_seat`, `hands_on_controls` (a **count**), `standing_on_deck`, `holding_another_vehicle`, `stunt`. Core models these as five independent `Option` fields of `Posture`, so a source may supply some and not others |
| `sig.hand_signal` | **the rider's or driver's arm signal** — a deliberate communicative gesture | meaning ∈ {left, right, stop_or_slow, re_enter} |
| `dev.human_direction` | **a third party directing traffic** — not the subject's body at all | role ∈ {police_officer, flagger, school_crossing_guard, railroad_flagger, procession_escort}; indication ∈ {stop, proceed, slow, turn(dir)} |

A posture is a *state of the body*; a hand signal is a *message the rider sends*; a human direction
is *an instruction the subject receives*. This audit previously filed `dev.human_direction` under a
class named "rare_gesture", which invited exactly this confusion; it is now `officer_direction`.

**One defect found and fixed.** `NRS-484B-769` ("shall give all signals by hand and arm … may give a
signal for a right turn by extending his or her right hand and arm") listed `ru.rider_posture` with
the note "which arm is extended and how". An extended arm is `sig.hand_signal`, which that record
already carried; `Posture` has no field for it. The spurious atom was removed from
`pipeline/evaluation/evaluation_scenario/scenarios.jsonl`, taking `ru.rider_posture` from 13 lines to 12.
`NRS-484B-768-1` keeps both atoms correctly: its duty is the hand signal, and posture appears only
in exception (b), where both hands are needed for safe operation.

### Where each source fails — the two fail on opposite halves

| atom | simulation (CARLA) | real video (nuPlan) |
|---|---|---|
| `ru.rider_posture` | **not representable.** The rider is baked into the bike or motorcycle blueprint and no posture attribute is exposed, so no field of `Posture` is a variable | **fine for the gross fields.** `on_seat`, `standing_on_deck`, `holding_another_vehicle`, `stunt` and mounted-vs-dismounted are body configuration in plain view |
| `ru.occupant_count` | **not representable.** CARLA vehicles carry no occupants | **fine except for an absolute count behind glazing** |
| `kin.steer_angle` | **exact, for every vehicle** — `Vehicle.get_wheel_steer_angle()`, with `WheelPhysicsControl.max_steer_angle` | **ego only** — `EgoState.tire_steering_angle`; on a third-party vehicle, visible only while parked with the wheels toward the camera |

This inverts the intuition that simulation is the permissive source. For posture and occupancy the
violating state **cannot be authored in CARLA at all**, so the seven whole-duty posture rules below
would not merely return `unknown` there — they would return *compliant* on every trace, which is a
false pass. That is what `Adequacy.unexercised` is for, and it should report these rules `VACUOUS`
in a simulation run. Real video is the permissive source for these two atoms; simulation is
permissive for steering.

### The weak field in each

- **`hands_on_controls`** is the one posture field that is a *count*, and it was the only field
  carrying whole-duty rules (`NRS-486-211`, `NRS-484B-780`). One hand versus two, from behind or at
  range or at night, is the least reliable thing in this group. Both of those lines are now
  excluded, so the field survives only in one exception clause and is no longer load-bearing.
- **`ru.occupant_count`** splits four ways; see the table below. The decisive point is that ten of
  the fourteen surviving lines need only a *change* in who is aboard, for which `sig.door_open`
  with a kerbside pedestrian track is the proxy — no head count through glazing is required.
- **`kin.steer_angle`** appears on exactly one line, and on that same line so does the most
  favourable `occupant_count` case: `NRS-484B-533` needs both "unattended" and "front wheels turned
  to the kerb", and both concern a stationary vehicle at close range.

### Per line

Nine of the twelve `ru.rider_posture` lines left the corpus for `excluded.jsonl` on 2026-09-29:
the seven whose **whole duty** is the rider's body configuration, and the two where posture served
only as **evidence for an occupant count**. The reason is relevance, not observability — the duty
is how a rider sits on their own machine, which is neither conduct a driving plan performs nor a
fact one turns on — so they join the apparel and equipment-legality lines rather than
`unobservable.jsonl`. None was in the test set, none was referenced by a surviving line, and no
atom was orphaned. The five overlapping municipal twins they supersede (LVMC 11.40.090, 11.38.010,
11.38.020, 11.40.160 and NRS 484B.773) state the same duties in the same words and correctly stay
dropped.

Excluded (9):

| id | tier | posture field | role |
|---|---|---|---|
| `NRS-484B-770-1` | C | `on_seat` | whole duty |
| `NRS-486-191-1` | C | `on_seat` | whole duty |
| `NRS-486-211` | C | `hands_on_controls` (count) | whole duty |
| `NRS-484B-780` | C | `hands_on_controls` (count) | whole duty |
| `LVMC-11-38-040` | C | `holding_another_vehicle` | whole duty |
| `LVMC-11-40-150` | C | `holding_another_vehicle` | whole duty |
| `LVMC-11-40-185-B` | S | `stunt` | whole duty |
| `NRS-484B-770-2` | C | `on_seat` / `standing_on_deck` | evidence for the occupant count |
| `NRS-486-181-1` | C | `on_seat` | evidence for the occupant count |

`ru.rider_posture` now carries **3** lines, in all of which it sits beside observable limbs and
none of which is a posture rule: `LVMC-11-40-180-A` (is the rider mounted, or walking the machine),
`LVMC-11-40-080` (did the rider dismount, the exception to a restricted-turn sign) and
`NRS-484B-768-1` (exception (b), both hands needed for safe operation, beside a hand-signal duty).
With `hands_on_controls` reduced to one exception clause, the weakest posture field is no longer
load-bearing anywhere.

#### `ru.occupant_count` — the 16 lines and what each asks of the count

Four distinct asks, not one. Only case C needs to see inside an enclosed cabin.

| id | tier | case | what the line needs of the count | how it is obtained |
|---|---|---|---|---|
| `NRS-484B-770-2` *(now excluded)* | C | A. absolute count, open machine | more persons than the cycle is designed and equipped for | riders in plain view |
| `NRS-486-181-1` *(now excluded)* | C | A. absolute count, open machine | more than one person on a motorcycle not designed for one | riders in plain view |
| `LVMC-11-52-030-A` | Q | B. change in occupancy | loading or unloading of passengers at a red curb | sig.door_open + a kerbside pedestrian track |
| `LVMC-11-52-030-B` | Q | B. change in occupancy | passengers loaded or unloaded at a yellow curb | sig.door_open + a kerbside pedestrian track |
| `LVMC-11-52-305-A` | Q | B. change in occupancy | passengers picked up or delivered by a commercial or recreational vehicle | sig.door_open + a kerbside pedestrian track |
| `LVMC-11-60-030-A2` | Q | B. change in occupancy | the passengers a bus exchanges away from a designated stop | sig.door_open + a kerbside pedestrian track |
| `LVMC-11-60-040` | Q | B. change in occupancy | the passenger exchange that excuses a taxi stopping outside a stand | sig.door_open + a kerbside pedestrian track |
| `NRS-484B-153-3` | Q | B. change in occupancy | a door open no longer than needed for immediate loading or unloading | sig.door_open + a kerbside pedestrian track |
| `NRS-484B-503` | Q | B. change in occupancy | the passenger exchange a passenger curb loading zone is for | sig.door_open + a kerbside pedestrian track |
| `NRS-484B-507-1` | Q | B. change in occupancy | the passenger exchange the freight-zone exception allows | sig.door_open + a kerbside pedestrian track |
| `NRS-484B-510` | Q | B. change in occupancy | the loading/unloading exception to a restricted parking zone | sig.door_open + a kerbside pedestrian track |
| `NRS-484B-517` | Q | B. change in occupancy | the passenger exchange that excuses stopping in a bus stop or taxi stand | sig.door_open + a kerbside pedestrian track |
| `NRS-484B-270-7b` | S | C. absolute count, enclosed cabin | the occupants a passing cyclist must not endanger | look through the glazing of a moving vehicle |
| `NRS-484B-360-1` | C | C. absolute count, enclosed cabin | whether pupils are aboard a school bus (the 55 mph limit applies only then) | look through high, tinted school-bus glazing -- the weakest case in the corpus |
| `NRS-484B-533` | C | C. absolute count, enclosed cabin | "unattended" -- nobody aboard a vehicle left on a grade | look through the glazing; favourable, the vehicle is stationary and near |
| `LVMC-11-52-130-A2` | Q | D. expressly irrelevant | "attended or unattended" -- the line says the fact does not matter | nothing needed |

`ru.occupant_count` now carries **14** lines: 10 in case B, 3 in case C and 1 in case D. Ten of
the fourteen need only a *change* in who is aboard, which a door event and a kerbside pedestrian
track supply without ever counting heads. `NRS-484B-360-1` is the single hardest line in the
corpus for this atom, and it is hard for a mundane reason: school-bus glazing.

`kin.steer_angle` still carries exactly one line, `NRS-484B-533` — which is also the most
favourable case C, since the vehicle is stationary and near.

## 6. What the ontology now says

The findings above are recorded in the atom contracts themselves, so a future reader meets them
before reaching this audit. `ontology/ATOMS.md` names no data source — the doctor forbids it — so
each note states what *a source* supplies and what it declares absent, in the style
`sig.compression_brake` already used. Five contracts were extended on 2026-09-29; the ontology's
Lean files were regenerated with `python -m scripts.gen_ontology` under the `full` split.

| atom | what was added |
|---|---|
| `sig.horn` | audible; a source without audio declares it absent, **and no visible state stands in for it** |
| `sig.siren` | audible; a source without audio declares it absent, **and does not read a warning lamp as the sound** — the two are separable and a road user may show one without the other |
| `ru.rider_posture` | the five fields are **independent**, each declared on its own; a source that renders a rider as part of the machine, so that no field can vary, declares all of them absent; `hands_on_controls` is a count and is the field a source is least likely to carry; and it is **not a stand-in for an arm signal, which is `sig.hand_signal`** |
| `ru.occupant_count` | a source that observes a **change** in it but not a total declares the count absent — what it observes then is the arrival or the departure, which is not this atom |
| `kin.steer_angle` | a source often carries it for the road user whose conduct is judged and not for the others; **the capability is declared for the atom, not per road user**, so a source that cannot supply it for every road user declares it absent |

The `sig.siren` and `ru.rider_posture` notes are the two that change what a rule may do: the first
forbids the light-for-sound substitution §3 depends on knowing about, and the last clause of the
second is the ontology's answer to the posture/gesture confusion that produced the
`NRS-484B-769` defect in §5.

The `kin.steer_angle` note states the Core limitation of §7 as a contract rather than leaving it
implicit. It is deliberately conservative — it tells a source to declare the atom absent rather
than claim it for road users it cannot see — which is the safe direction, and it is the wording
that would change if `Manifest.entries` ever became per-role.

**One leak caught while writing these.** The first draft of the `ru.occupant_count` note named
`sig.door_open` as the proxy. That atom is test-only, so the note would have carried a test concept
into `ATOMS_train.md`; `atoms_train.py` reported it and the note was rephrased to name no atom.

## 7. Registry and designation — nothing is lost

The rule adopted: a line counts as affected only if it turns on a vehicle **the authority has
designated without marking it** — the private cars of physicians and volunteer firefighters, and
licensed ambulances not in livery. Three findings:

1. **No line in the corpus names that case.** A sweep of every line for `physician`, `volunteer`,
   `livery` and `unmarked` returns only false positives ("de**livery**", "un**marked** crosswalk").
2. **The corpus does not carry the designation list at all.** NRS 484A.480(1)–(2), where the
   authority designates, is not in `laws.jsonl`. What the corpus carries is `DEF-NRS-484A-480-3`,
   the *equipment* subsection: "Every authorized emergency vehicle must be equipped with at least
   one flashing red warning lamp visible from the front and a siren". That is an observable test.
3. **The duties key on the lamp, not the class.** `drv.responding_emergency` is a disjunction, so
   the flashing lamp carries it without the siren. The 12 lines reading it are unaffected.

Rated and licensed classes are read from conspicuous evidence and are `note_only`:
`ru.commercial_motor_vehicle` from size, axle count, hazmat placarding (itself legally required to
be conspicuous) and seating capacity; `ru.low_speed_vehicle` from its form factor;
`ru.official_vehicle` from tow, utility, highway-maintenance, postal and armored-car liveries;
`ru.moped` and `ru.electric_bicycle` because no line turns on telling them from their siblings.

**The failure mode, recorded once.** A vehicle the authority designates but does not mark — an
emergency vehicle, an unmarked municipal or agency car — reads as an ordinary vehicle. Two
directions of error follow, neither detected by the pipeline and neither visible in the per-line
records: on a **priority duty** the verdict comes back *compliant* where the law finds a
violation; on an **exception clause** entitling a designated class, a violation is reported
against a vehicle the law exempts. Any deployment claim from this evaluation set inherits both.

## 8. Ego-only — resolved for the evaluation, open in Core

CARLA supplies `kin.steer_angle` for every vehicle via `Vehicle.get_wheel_steer_angle()`, and
nuPlan's `EgoState.tire_steering_angle` supplies it exactly for the ego, which is the subject a
real-video run judges (§5). `ego_pose` likewise
carries `vx, vy, vz`, `acceleration_x/y/z` and `angular_rate_x/y/z` from the vehicle's own bus.
`NRS-484B-533` is therefore evaluable.

The Core limitation it rests on is unchanged. `Manifest.entries : List (String × Capability)` in
`library/TrafficSpec/Core/**` is keyed by **atom id alone**, and `Mask.user` takes an id and one
`RoadUser` and is mapped over every user in the scene. A capability that differs between the ego
and other agents cannot be declared: `exact` claims the source knows every agent's steering angle,
`absent` blanks it for the ego too. The same split applies to `kin.accel_longitudinal` and
`kin.yaw_rate` (exact for the ego, a derivative of a noisy track for others) and to
`sig.turn_indicator`. Rules quantify over other users with `.forallUser`, so one formula reads the
same atom at both roles. Note also `Mask.user`'s first line, `| "ru.subject" => u`: masking the
subject atom is a deliberate no-op, which assumes the source always knows whose conduct is judged.

**What this costs today:** nothing, while the real-video evaluation judges only the ego.
**Minimal fix**, not applied: key `entries` by `(atomId, role)` with `role ∈ {subject, other,
any}`, resolve `any` as the fallback, and thread the role through `Mask.user`/`Mask.scene` from
the binder that introduced the track. `Manifest.support` changes with it. A Core change, so it
wants a plan of its own.

## 9. What this audit does not cover

- **No manifest exists yet.** `python -m harness doctor` reports `manifests complete — no
  manifests registered yet`, and `Build.manifest` starts from `Manifest.full "witness"`, which
  declares all atoms `exact`. Every rule the pipeline has accepted was accepted against an
  omniscient source. Writing `manifests/carla.json` and `manifests/video.json` from §1 and §4 and
  running `Manifest.support` over the rule set reports which lines are addressable **before** more
  coding tokens are spent. `sig.siren` must be `estimate` in both, for the reason in §1.
- **Vacuity is not measured here.** §5 shows that posture and occupancy are not representable in
  CARLA, so rules over them would pass every simulation trace rather than return `unknown`.
  `Adequacy.unexercised` is the check that should report them `VACUOUS`; it has not been run
  against a simulation manifest, because no manifest exists.
- **Coverage is not observability.** `env.ice_or_snow` (2 lines) and `env.precipitation` (8) are
  observable and will never be exercised in Las Vegas logs. That is a sampling gap.
- **Error classes are named, not measured.** "degraded" means a failure mode has been identified,
  not that its magnitude has been calibrated against the sampling-adequacy bounds Core checks.
