# Traffic-law ontology — atoms

Status: **draft for review, 2026-09-15**. Frozen after review; changed afterwards only by an
explicit ontology change (new atom, new value, new grounding), never by a rule.

## How to read this file

An **atom** is an element traffic law refers to without defining it further: a class of road user,
a quantity of motion, a piece of road structure, a control device and its state, a signal a road
user emits, a condition of the environment, or a relation between two of these. Each atom has a
**semantic contract** — what it denotes physically, its unit and reference frame — and that
contract is independent of any data source. A source (CARLA, an annotated driving dataset, a
perception stack over video) either supplies the atom, supplies an estimate of it with a stated
error class, or declares it **absent**; it never redefines it.

Every atom is **three-valued** when observed: true, false, or *not observed on this source*. A rule
built on an unobserved atom reports `unknown`, never compliance.

Enumerated from BC Motor Vehicle Act Part 3 (ss.119–214): every noun and verb that appears inside
a driving obligation. Cross-checked against the Vienna Convention on Road Traffic (1968) Art. 1
definitions and Chapter II, and against the US Uniform Vehicle Code / MUTCD for North-American
device semantics, so that the set is jurisdiction-neutral. Column **X-check**: `V` counterpart in
Vienna, `U` in UVC/MUTCD, `—` none found (candidate for a jurisdiction extension rather than Core).
The Vienna and UVC references were made from working knowledge of those texts and must be verified
against the originals before the freeze; that verification is the one open review item.

Column **Grounding**: `C` CARLA (the API call or the RSV field that supplies it; `collector` means
a capture-time collector we write), `A` annotated driving dataset (nuPlan / Waymo Open Motion class
of annotation), `P` monocular perception (the task that estimates it). `absent` means no form of it
exists on that source. Grounding is what the per-source **capability manifest** must declare, atom
by atom.

Companion file: `concepts.jsonl` — the statutory elements (as the law phrases them) and, for each,
the atoms allowed to express it and the proxies forbidden. That file is the termination rule; this
file is what it terminates in.

Identifier scheme: `family.name`. Families: `ru` road user, `kin` kinematics, `st` road structure,
`dev` control device, `sig` emitted signal, `env` environment, `rel` relation between road users,
`jdg` judgement standard. Derived concepts (Core-defined, not atoms) use `drv`.

---

## 1. Road users (`ru`) — class atoms on an entity

| id | contract | Part 3 | X-check | Grounding |
|---|---|---|---|---|
| `ru.motor_vehicle` | a self-propelled vehicle other than a rail vehicle or a device moved by human power | 119, 144–148, 152–153 | V "power-driven vehicle" / "motor vehicle" | C exact (blueprint) · A exact (class) · P estimate (detector class) |
| `ru.motorcycle` | motor vehicle on two or three wheels ridden astride | 194 | V "motor cycle" | C exact · A exact · P estimate |
| `ru.moped_or_motor_assisted_cycle` | low-power two-wheeler as the jurisdiction defines it | 182.1 | V "moped" | C absent (no blueprint) · A rare · P estimate |
| `ru.bus` | motor vehicle designed to carry many passengers | 129(2), 169.1, 185(4) | V (Art.1 "public transport") · U | C exact · A exact · P estimate |
| `ru.school_bus` | bus designated for carrying school children, with the jurisdiction's markings | 149, 185(4) | U only | C absent · A absent · P estimate (livery) — **extension: CA/US** |
| `ru.commercial_or_heavy_vehicle` | vehicle over the jurisdiction's mass class or licensed commercially | 146.1, 162(2), 207 | V "permissible maximum mass" | C estimate (blueprint mass) · A exact (class) · P estimate |
| `ru.trailer_or_combination` | vehicle drawn by another, or the combination | 119, 162(2) | V "trailer", "combination of vehicles" | C absent · A rare · P estimate |
| `ru.cycle` | human-powered wheeled vehicle ridden by a person | 119, 157.1, 183, 184 | V "cycle" | C exact (bicycle blueprints) · A exact · P estimate |
| `ru.pedestrian` | a person on foot, or on a device the jurisdiction treats as on foot | 119, 127–133, 179–182 | V "pedestrian" (Art.1) | C exact (walker) · A exact · P estimate |
| `ru.child_or_apparently_incapacitated` | pedestrian who is a child or visibly impaired | 181(c) | — | C estimate (walker blueprint `age`) · A absent · P estimate |
| `ru.emergency_vehicle` | vehicle of a class the jurisdiction designates as emergency | 122, 177, 198 | V Art.34 (priority vehicles) | C exact (blueprint) · A rare · P estimate (livery) |
| `ru.animal_or_animal_drawn` | ridden or herded animal, or an animal-drawn vehicle | 120(c) | V Art.1 | C absent · A absent · P estimate |
| `ru.rail_vehicle` | train or tram on rails | 185 | V "rail-borne vehicle", Art.18–19 | C absent (no rail in shipped maps) · A absent · P estimate |
| `ru.personal_mobility_or_micro_utility_device` | powered devices the jurisdiction prescribes | 182.01, 182.02 | — | C absent · A rare · P estimate — **extension** |
| `ru.official_vehicle` | vehicle prescribed by regulation (e.g. works, police at scene) | 150(2)(c), 151.1(3)(d) | — | C absent · A absent · P estimate — **extension: CA-BC** |
| `ru.subject` | the road user whose conduct a rule judges (the ego) | all | — | C exact · A exact (ego track) · P exact (camera vehicle) |

"Vehicle" as a legal aggregate (BC: excludes human-powered devices; other codes include cycles) is
a **concept**, not an atom — see `concepts.jsonl` `vehicle`, which maps per jurisdiction onto these
classes. A responding emergency vehicle is derived (`drv.responding_emergency`).

## 2. Kinematics (`kin`) — measurements on any road user

| id | contract | unit / frame | Part 3 | X-check | Grounding |
|---|---|---|---|---|---|
| `kin.time` | instant of observation of a scene | ms, monotone within a trace | every duration | — | C exact (tick × Δt from manifest) · A exact (timestamp) · P exact-ish (PTS; may be irregular) |
| `kin.position` | position of the body's reference point | m, world frame (map or local) | throughout | — | C exact · A exact · P estimate (depth error grows with range) |
| `kin.heading` | direction the body points | unit vector, world frame | 154, 168, 174 | — | C exact · A exact · P estimate (orientation) |
| `kin.velocity` | velocity vector | m/s, world frame | 145–148, 157(2), 162 | V Art.13 | C exact via API on every actor (**collector**; RSV has ego only) · A exact · P estimate |
| `kin.speed` | magnitude of velocity | m/s | 145–148 | V Art.13 | as velocity |
| `kin.accel_longitudinal` | acceleration along heading, signed | m/s² | 170(3) (sudden decrease), 157(2)(b) | — | C exact (**collector**) · A derived · P estimate |
| `kin.yaw_rate` | rate of change of heading | deg/s | 165–168 | — | C exact (ego; collector for others) · A derived · P estimate |
| `kin.extent` | body half-length, half-width, half-height about the reference point, along the body axes | m | 154, 157.1, 190 | — | C exact (bounding box) · A exact (3-D box) · P estimate (3-D box) |
| `kin.steer_angle` | front-wheel steering angle | deg | 191(2)(b) | — | C exact (ego) · A absent · P absent |

## 3. Road structure (`st`) — map-level atoms

| id | contract | Part 3 | X-check | Grounding |
|---|---|---|---|---|
| `st.roadway` | the part of a highway improved for vehicular traffic, excluding shoulder; separate roadways of a divided highway are separate | 119, 150, 154, 187 | V "carriageway" | C exact (OpenDRIVE driving lanes) · A exact (map) · P estimate (drivable area) |
| `st.lane` | a longitudinal strip of roadway for one line of vehicles | 119, 134, 151–153 | V "lane" | C exact · A exact · P estimate (lane detection) |
| `st.lane_direction` | direction of travel a lane is designated for | 150, 151(f), 154, 163 | V Art.10 | C exact (OpenDRIVE) · A exact · P estimate (from markings + traffic) |
| `st.lane_adjacency` | left / right neighbouring lane of the same direction; lane ordinal within the carriageway | 151(d),(e), 151.1, 165(3) | V Art.10 | C exact (**collector**: `get_left_lane`/`get_right_lane`; RSV has adjacency edges only) · A exact · P estimate |
| `st.lane_connectivity` | which lane a lane leads into | 165, 175 | — | C exact · A exact · P absent without map |
| `st.lane_marking` | per side of a lane: type (none / broken / solid / double solid / solid+broken / botts / curb), colour | 151(a),(b), 155, 165(2) | V Annex 2 | C exact (**collector**: waypoint markings; folded away by the RSV) · A exact (map) · P estimate (line detection) |
| `st.centre_line` | the marking, or the geometric centre, dividing the two directions of a two-way roadway | 155, 165(2), 166 | V Art.10, Annex 2 | C exact (collector) · A exact · P estimate |
| `st.road_edge` | curb or edge of the roadway | 150(2), 165(1), 167, 177, 190 | V Art.10 "edge of the carriageway" | C exact (lane width + last lane) · A exact · P estimate |
| `st.shoulder` | the part of the highway beside the roadway not intended for vehicular traffic | 119, 182(2), 187 | V "verge"/"shoulder" | C exact (collector: lane type Shoulder) · A exact · P estimate |
| `st.sidewalk_or_boulevard` | area for pedestrians between roadway and property line; verge | 119, 176, 182, 189(1)(a), 200 | V "pavement/footpath" | C exact (collector: Sidewalk lane type) · A exact · P estimate |
| `st.median_or_divider` | physical barrier or dividing section between roadways | 163 | V Art.1 "divided" (Art.10) | C exact (collector: Median lane type / static meshes) · A exact · P estimate |
| `st.one_way_roadway` | roadway on which traffic is restricted to one direction | 150(1)(c), 158(1)(c), 160, 165(3) | V Art.10 | C exact (lane directions) · A exact · P estimate (signs) |
| `st.intersection` | the region where two roadways meet, bounded by the prolongation of their edges | 119, 125.1–131, 165, 173–175, 189(1)(c), 193 | V "intersection" (Art.1) | C exact (OpenDRIVE junction; entry boundary via collector) · A exact · P estimate |
| `st.crosswalk` | marked crossing, or the unmarked prolongation of sidewalks at an intersection | 119, 127–133, 179, 186, 189(1)(e),(f), 193 | V "pedestrian crossing" (Art.1, Art.21) | C exact (**collector**: `Map.get_crosswalks`) · A exact (map) · P estimate (marking detection; unmarked needs sidewalk lines) |
| `st.stop_line` | the transverse line at which a device requires a halt | 128–131, 186 | V Annex 2 | C exact (**collector**: `get_stop_waypoints`) · A exact (map) · P estimate |
| `st.driveway_or_alley_entrance` | private road, alley or driveway meeting the highway | 150(2)(b), 151.1(3)(c), 156, 166–167, 176, 189(1)(b) | V Art.18 | C partial (map-dependent) · A partial · P estimate |
| `st.curvature` | horizontal curvature of the roadway at a point | 168(b)(i), 196 | V Art.13 | C exact (collector: OpenDRIVE geometry) · A exact · P estimate |
| `st.grade` | longitudinal slope of the roadway | 168(b)(ii), 191(2)(b), 197 | — | C exact (collector: elevation) · A exact (z) · P estimate |
| `st.sight_distance` | distance along the road within which another vehicle would be visible from a point | 160, 168(b)(ii), 196 | V Art.11 | C exact (collector: ray cast over map geometry) · A partial · P estimate |
| `st.railway_crossing` | level crossing of a railway with the roadway, and its nearest rail | 185, 189(1)(i) | V "level-crossing" (Art.1, Art.19) | C absent in shipped maps · A rare · P estimate |
| `st.controlled_access_ramp` | on/off ramp of a highway with access only at designated points | 164 | V "motorway" (Art.1, Art.25) | C exact (collector: OnRamp/OffRamp lane type) · A exact · P estimate |
| `st.bridge_or_tunnel` | elevated structure or tunnel carrying the roadway | 189(1)(m) | V Art.23 | C exact (level objects) · A exact · P estimate |
| `st.cycle_lane_or_track` | lane or separate track reserved for cycles | 151, 183 | V "cycle lane", "cycle track" (Art.1) | C exact (collector: Biking lane type) · A exact · P estimate |
| `st.reserved_lane` | lane reserved for a class of vehicles (bus, HOV, designated use), with its class code | 152, 153, 153.2, 161(c),(d) | V Art.10 (reserved lanes) · U | C absent in shipped maps (Restricted/Special lane types exist) · A rare · P estimate (signs/markings) |
| `st.parking_space` | marked bay for standing or parking | 124(f), 187–190 | V Art.23 | C exact (collector: Parking lane type) · A exact · P estimate |
| `st.roundabout_island` | central island of a rotary intersection | 150(3) | V Art.10 (roundabouts, Annex 1) | C exact (map geometry) · A exact · P estimate |
| `st.lane_width` | width of a lane at a point | 146(8), 154(2) | — | C exact (collector) · A exact · P estimate |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line) | throughout | — | C exact · A exact · P estimate |

"Highway" (the legal right of way), "through highway", "laned roadway", "divided highway",
"business / residence district", "municipality" are concepts or derived concepts, not atoms; see §9.

## 4. Control devices (`dev`) — a device is an entity with class, state, position and governance

| id | contract | Part 3 | X-check | Grounding |
|---|---|---|---|---|
| `dev.traffic_signal` | a signal head; **state** is an open enumeration: `red`, `yellow`, `green`, `red_arrow(dir)`, `yellow_arrow(dir)`, `green_arrow(dir)`, `flashing_red`, `flashing_yellow`, `flashing_green`, `off`, `unknown` | 125.1–131 | V Art.23, Annex 1 · U (arrows, flashing yellow arrow) | C exact for red/yellow/green/off (API); arrow and flashing states **absent** on CARLA · A exact (per-lane signal state) · P estimate (classifier) |
| `dev.pedestrian_signal` | walk / don't-walk / flashing don't-walk head | 127(1)(b), 129(4)(a), 132–133 | V Annex 1 · U | C absent · A absent · P estimate |
| `dev.lane_control_signal` | overhead per-lane red / green (/ yellow arrow) | 134 | V Annex 1 · U | C absent · A absent · P estimate |
| `dev.stop_sign` | regulatory sign requiring a full halt | 119 "through highway", 175, 185(3), 186, 189(1)(g) | V Annex 1 B,2 · U | C exact (`traffic.stop`) · A exact (map) · P estimate |
| `dev.yield_sign` | regulatory sign requiring yielding without a mandatory halt | 173(2) | V Annex 1 B,1 "give way" · U | C exact via API (`traffic.yield` — **dropped by the current generator**; collector) · A exact · P estimate |
| `dev.speed_limit_sign` | sign stating a maximum speed, with value and unit | 140, 146(3)–(7), 147, 151.1, 169.1(2) | V Annex 1 C,14 · U | C exact (blueprint value; landmark 274) · A exact (map) · P estimate (sign reading) |
| `dev.regulatory_sign` | any other regulatory or mandatory sign, by catalogue **code** and legend: no left/right turn, no U-turn, one-way, mandatory direction, no stopping / no parking, lane designation, school / playground zone, no cycles, no entry, keep right | 124(1), 129(3),(4)(b), 147, 151(g), 152–153.2, 161, 168(b)(iii), 183(2)(h), 189(1)(n) | V Annex 1 C/D · U | C exact where the map authors the landmark (OpenDRIVE type/subtype) · A exact (map) · P estimate |
| `dev.railway_signal_or_gate` | flashing signal or crossing gate at a level crossing | 185 | V Art.19, Annex 1 | C absent · A rare · P estimate |
| `dev.temporary_traffic_control` | cones, barriers, temporary signs and flashers marking works or an obstruction | 138–142, 150(1)(b), 155(2), 207(3) | V Art.32, Annex 1 | C absent from the graph (level objects exist: **collector** or scenario) · A partial · P estimate |
| `dev.human_direction` | a peace officer, flagger, traffic control person or crossing guard directing traffic, and the direction given | 123, 125, 141, 141.1, 179(4), 185(1)(b) | V Art.6 | C **absent** · A absent · P estimate (pose) — audible/gestural content absent everywhere |
| `dev.school_bus_signal` | the school bus's alternating lamps / stop arm | 149 | U only | C absent · A absent · P estimate — **extension: CA/US** |
| `dev.transit_yield_device` | the "yield to bus" sign or lamp on a transit bus | 169.1 | — | C absent · A absent · P estimate — **extension: CA-BC** |
| `dev.bus_white_indicator` | the white rectangular indicator permitting a bus to proceed on red | 129(2) | — | C absent · A absent · P estimate — **extension: CA-BC** |
| `dev.governs` | relation: the device applies to a lane or approach (which traffic it faces) | all device rules | V Art.23 | C exact (API: affected waypoints, trigger volume, landmark orientation + validities) · A exact (map association) · P estimate (geometry) |
| `dev.position` | location of the device head / sign face | 128–131 "before reaching the signal", 189(1)(g) | — | C exact · A exact · P estimate |
| `dev.inoperative` | a signal head showing no valid indication | 125.1 | U | C exact (`off`) · A partial · P estimate |

## 5. Signals emitted by road users (`sig`)

| id | contract | Part 3 | X-check | Grounding |
|---|---|---|---|---|
| `sig.turn_indicator` | left / right indicator lit | 151(c), 158(1)(a), 169–172, 174 | V Art.14 | C exact for non-ego (RSV); **ego via collector** · A rare · P estimate (portable) |
| `sig.brake_lamp` | brake lamps lit | 170(3), 179(3) | V Art.14 (slowing signal) | as turn indicator |
| `sig.hazard` | both indicators lit | 207 | V Art.32 | as turn indicator |
| `sig.headlamp` | low / high beam lit | 183(6), 207 | V Art.32 | as turn indicator |
| `sig.position_lamp` | position / parking lamps lit | 183(6), 207 | V Art.32 | as turn indicator |
| `sig.reverse_lamp` | reversing lamps lit | 193 | — | as turn indicator |
| `sig.beacon` | emergency warning lamps lit (visual) | 177, 198 | V Art.34 | C exact (Special1/2, non-ego; ego via collector) · A rare · P estimate |
| `sig.siren_or_horn` | audible warning sounding | 157(2)(a), 177, 181(b), 196 | V Art.28, Art.34 | C **absent** · A absent · P estimate only with audio |
| `sig.hand_signal` | driver's or cyclist's arm signal | 151(c), 169–172, 183(17) | V Art.14 | C absent · A absent · P estimate (pose) |
| `sig.door_open` | a door open on the traffic side | 203 | V Art.24 | C exact (door state API, ≥0.9.13) · A absent · P estimate |

## 6. Environment (`env`) — per trace or per frame, from a manifest or a sensor

| id | contract | Part 3 | X-check | Grounding |
|---|---|---|---|---|
| `env.darkness` | insufficient natural light (the jurisdiction fixes the period relative to sunset/sunrise) | 183(6), 207(1) | V Art.32 | C exact (sun altitude) · A exact (timestamp + location) · P estimate |
| `env.precipitation` | rain or snow falling | 144(1)(c) | V Art.13 | C exact (weather parameters) · A exact (tags) · P estimate |
| `env.wet_road` | road surface wet, standing water | 144(1)(c) | V Art.13 | C exact · A partial · P estimate |
| `env.visibility` | visibility distance (fog, dust) | 144(1)(c), 207(1) | V Art.13, Art.32 | C exact (fog parameters) · A partial · P estimate |

## 7. Relations between road users (`rel`)

| id | contract | Part 3 | X-check | Grounding |
|---|---|---|---|---|
| `rel.centre_distance` | Euclidean ground-plane distance between reference points | 157, 162, 198 | V Art.13 | from `kin.position` |
| `rel.surface_gap` | distance between the nearest points of two bodies; longitudinal and lateral components in the subject's frame | 154(2), 157(1), 157.1 (1 m) | V Art.11 | from `kin.position` + `kin.extent` |
| `rel.ahead_behind_in_lane` | a is ahead of / behind b in the same lane, along the lane direction | 157, 162, 179(3) | V Art.11 | from `rel.occupies`, `kin.position`, `st.lane_direction` |
| `rel.oncoming` | headings opposed and closing | 154, 174 | V Art.12 "meeting" | from `kin.heading`, `kin.velocity` |
| `rel.same_direction` | headings aligned within a tolerance | 150(1)(a), 157 | V Art.11 | from `kin.heading` |
| `rel.bearing` | direction of b from a in a's frame (for "on the right of") | 125.1(2), 173(1) | V Art.18 | from `kin.position`, `kin.heading` |

These are computed from kinematics; they are listed because the law names them directly and a
source may supply them measured rather than derived.

## 8. Judgement standards (`jdg`) — atoms a reading must quantify

| id | contract | Part 3 |
|---|---|---|
| `jdg.safe` / `jdg.can_be_made_in_safety` | the manoeuvre would not force another road user to act | 128(1)(a), 151(a), 156, 158(2), 159, 166(c), 168(a), 169, 185, 193, 203 |
| `jdg.reasonable_and_prudent` | as a careful driver would, given speed, traffic and road | 121, 122(4), 144, 162(1) |
| `jdg.practicable` | feasible in the circumstances | 150(1),(2), 165(1),(2), 167, 187 |
| `jdg.immediate_hazard` | so close that yielding is required | 174, 175, 176(2), 185(1)(c) |
| `jdg.due_care` | attention and consideration | 144(1)(a),(b), 181 |
| `jdg.necessary` / `jdg.impede` | as needed; blocking normal movement | 145, 181(b), 187(2), 189(1) |

A judgement atom is never read from a scene. A reading turns it into a bound over kinematic or
relational atoms (e.g. `jdg.immediate_hazard` → time gap below *g* seconds), and the same reading
drives the derived label. Rules take the bound as a parameter.

## 9. Not atoms

**Legal region classes** — categories the law defines administratively, invisible on the road:
municipality, treaty lands, rural area, business district, residence district, school day and its
hours, controlled-access designation (as a legal status; the ramp geometry is `st.controlled_access_ramp`),
"highway" as a public right of way. These enter a formalization only as **reading assumptions**
declared per map or per trace, never as atoms a rule reads from a scene.

**Derived concepts** (`drv`) — defined once in Core from atoms, with parameters exposed; rules may
use them and may not redefine them:

| id | definition sketch | parameters |
|---|---|---|
| `drv.stopped` | speed ≤ ε for ≥ d seconds | ε, d |
| `drv.standing_or_parked` | stopped, not in a queue of moving traffic, for ≥ d | d |
| `drv.moving_off` | stopped then speed > ε | ε |
| `drv.turning` | heading change of ≥ θ within w seconds, left or right | θ, w |
| `drv.u_turn` | heading reversal (≈180°) within w seconds while on the roadway | w, tolerance |
| `drv.lane_change` | `rel.occupies` moves from one lane to an adjacent same-direction lane | — |
| `drv.overtaking` | same direction, a moves from behind b to ahead of b | — |
| `drv.passing_side` | which side the overtaken vehicle was on | — |
| `drv.entering_intersection` / `drv.in_intersection` / `drv.approaching` | footprint crosses the region boundary; is inside; is within distance d along the lane of the boundary | d |
| `drv.crossing_line` | footprint crosses a stop line / crosswalk boundary | — |
| `drv.backing` | velocity opposed to heading | — |
| `drv.following` | same lane, behind, within gap g | g |
| `drv.meeting` | oncoming vehicles whose paths overlap within t | t |
| `drv.yields_to` | a slows or stops so that b passes first (a's arrival order after b) | — |
| `drv.arrival_order` | which of two approaching users reaches the intersection boundary first, with a simultaneity tolerance τ | τ |
| `drv.wrong_way` | heading opposed to `st.lane_direction` of the lane occupied | tolerance |
| `drv.straddles_marking` | footprint on both sides of a marking | — |
| `drv.responding_emergency` | `ru.emergency_vehicle` ∧ (`sig.beacon` ∨ `sig.siren_or_horn`) | — |
| `drv.vulnerable_road_user` | `ru.pedestrian` ∨ (person on `ru.cycle`) ∨ prescribed | — |
| `drv.laned_roadway` | roadway with ≥ 2 marked lanes in one direction | — |
| `drv.through_highway` | roadway whose entrances carry `dev.stop_sign` | — |
| `drv.time_gap` | `rel.centre_distance` (or surface gap) ÷ follower's speed | — |

**Dataset fields** — `controls` edge, `mayAffect`, trigger volume, render distance, proximity band
labels, `laneChange` edge, RSV node names. These are how CARLA grounds an atom; they belong in the
adapter and its manifest, never in a rule.

## 10. Cross-check notes (to verify against the texts before the freeze)

- Present in Vienna, absent from Part 3, **kept** because the ontology is universal: cycle track,
  reserved lane semantics (Art.10), tram (Art.18), built-up-area sign zone (Art.1 — a *signed*
  zone, hence a device-defined region, unlike BC's administrative municipality), motorway.
- Present in Part 3, no Vienna or UVC counterpart, **filed as extensions** rather than Core:
  flashing green (Canada-specific meaning), bus white rectangular indicator, transit yield device,
  personal mobility / micro-utility device classes, official vehicle. School bus signals are UVC/US
  and Canadian, not Vienna: extension `CA/US`.
- Device states: Vienna Annex 1 has no flashing yellow arrow and no per-lane flashing red; UVC/MUTCD
  do. The signal-state value space is the union, kept open, and each source's manifest says which
  values it can observe (CARLA: three colours and off only).
- Vienna defines "standing" and "parking" by duration and purpose (Art.1), BC by purpose; both are
  readings over `drv.standing_or_parked`, not new atoms.
