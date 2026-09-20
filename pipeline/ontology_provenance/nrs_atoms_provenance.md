# Atom provenance — NRS 484A / 484B / 484D / 486 and Las Vegas Municipal Code Title 11 (NOT agent-readable)

Written 2026-09-18. Companion to `traffic-spec-agent/ontology/ATOMS.md` (second draft). This
file records, for every atom and derived concept in the agent-facing ontology, **which NRS
provisions motivated it**, why the ones flagged `local` are Nevada-specific, and what is known
about grounding it on each planned source. It is kept outside `traffic-spec-agent/` so that no
prompt, gate or agent session can read it.

Direction of the tables matters. They run **atom → sections**: "this atom exists because these
provisions refer to it". They are *not* a table of law → expected atoms, and they must not be
turned into one: the plan agent's own `elements` claims, validated by the harness and read by
the review phase, are the only mapping the pipeline scores. Anything here that looks like "the
right answer for clause X" is a note for the human reviewer of the ontology, not ground truth.

## 1. How the scan was done

- Source: the Legislative Counsel Bureau's NRS pages, 2025 Wayback snapshot
  (`web.archive.org/web/2025id_/https://www.leg.state.nv.us/NRS/NRS-484X.html`). The live
  site and Justia return a bot challenge to non-browser clients.
- Parsed into per-section text (`nrs_tools/nrs_tree.py`): 484A — 115 sections; 484B — 197;
  484D — 124. Every section of 484A and 484B was read in full. Of 484D only the 32 sections
  regulating *use* of equipment or naming devices a rule of the road depends on were read
  (090, 100–130, 145, 160–220, 280, 285, 400–415, 435–440, 490, 515, 545, 850, 860).
- The corpus (`traffic-spec-agent/laws/example/laws.jsonl`, 238 lines) was generated from the
  same trees by `nrs_tools/make_laws.py`; the selection list inside that script is the record
  of what was included and what was not.
- Extension, same day: NRS chapter 486 (motorcycles, mopeds, trimobiles; 50 sections, all read;
  9 operating rules taken) and the Las Vegas Municipal Code Title 11 (Vehicles and Traffic; 40
  chapters, 413 sections retrieved from Municode's content API; every chapter imposing a road-user
  duty read in full; 140 lines taken). The City's Transportation Engineering Fact Sheets (Public
  Works, March 2025, `nrs_tools/sources/clv_transportation_fact_sheets_2025-03.txt`) were read and
  found to be resident-facing explanation that cites LVMC 11.16.060, 11.52.030, 11.52.130,
  11.44.020, 11.52.305 and 11.02.070; they contributed no lines and no atoms, and are kept only as
  a cross-check that the Code sections the City itself points residents to are in the corpus.
- Atoms were enumerated by walking every corpus line and listing each noun phrase that the
  provision uses without defining, each quantity it measures, each device and device state it
  names, and each standard of judgement it invokes; then merging with the first-draft atom set
  (BC MVA Part 3 enumeration, `atoms_provenance.md`) and dropping what no NRS provision needs.

## 2. Changes from the first draft

Dropped (no provision in the corpus refers to them): `dev.transit_yield_device`,
`dev.bus_white_indicator`, `ru.moped_or_motor_assisted_cycle` (split), `ru.child_or_apparently_incapacitated`
(narrowed to `ru.child`; incapacity is not an NRS element), `ru.personal_mobility_or_micro_utility_device`
(split into three local classes), `ru.commercial_or_heavy_vehicle` (split), `sig.beacon` and
`sig.siren_or_horn` (split by colour/mode and by siren/horn because NRS distinguishes them),
`st.sidewalk_or_boulevard` (→ `st.sidewalk`), `st.controlled_access_ramp` (→ `st.controlled_access`
with entrance/exit lanes), `st.bridge_or_tunnel` (→ `st.elevated_structure`), `st.cycle_lane_or_track`
(→ `st.bicycle_lane_or_path`), `ru.cycle` (→ `ru.bicycle`), `ru.emergency_vehicle`'s single class
(now with a kind), `drv.through_highway` (renamed `drv.priority_roadway`, and now also admits
yield-sign entrances, as NRS 484A.275 does).

Added: see the `local` rows and the rows whose "sections" column cites only NRS below.

## 3. Road users (`ru`)

| atom | NRS provisions that refer to it | local? why | grounding notes |
|---|---|---|---|
| `ru.motor_vehicle` | 484A.130 (def.: excludes electric bicycle and electric scooter); 484B.120, .270, .280, .363, .550, .600, .623, .627; 484D.215, .220, .400 | — | CARLA blueprint class; annotated datasets: class label; perception: detector class |
| `ru.motorcycle` | 484A.135; 484B.307(8)(d), (9)(b) ("motorcycle, moped or trimobile"); 484B.323(3)(b) | — (trimobile folded in) | as above |
| `ru.moped` | 484A.125; 484B.307(8)(d), (9)(b) | — | CARLA: no blueprint → absent; perception: estimate |
| `ru.bus` | 484A.030; 484B.323(3)(c), .513, .517, .560(1) | — | class label |
| `ru.transit_bus` | 484B.210(4)(f), (6)(c) ("public transit motor bus", shoulder use); 484B.587(3) | — | livery; absent in CARLA |
| `ru.school_bus` | 484A.230; 484B.353, .360, .560(1) | — | livery + lamps; absent in CARLA |
| `ru.taxicab` | 484A.270; 484B.513, .517 | — | livery / roof sign |
| `ru.truck` | 484A.305; 484B.127(2) | — | class label |
| `ru.commercial_motor_vehicle` | 484B.560(5) (49 C.F.R. § 383.5 definition) | — | estimate from class/size; CARLA: blueprint mass |
| `ru.hazardous_materials_vehicle` | 484B.560(1) | — | placard; perception only |
| `ru.trailer_or_combination` | 484A.050, .235, .295; 484B.127(2); 484D.545 | — | rare in all sources |
| `ru.low_speed_vehicle` | 484B.637 (4-wheeled, 20–25 mph, < 3,000 lb GVWR; may not use highways posted above 35 mph) | **local**: a Nevada class (also federal FMVSS 500, but the operating restriction is NRS) | body type; perception estimate; absent in CARLA |
| `ru.bicycle` | 484A.025; 484B.270, .450(3), .763–.783 | — | CARLA bicycle blueprints; datasets: class |
| `ru.electric_bicycle` | 484B.017 (three classes by assist type and top speed); 484A.081; 484B.270, .307(8)(d), .763–.784 | **local**: the class taxonomy and the "not a vehicle" status are NRS choices | visually indistinguishable from a bicycle at distance; estimate |
| `ru.electric_scooter` | 484A.082, 484B.018; 484B.270, .307, .450(3), .785 (15 mph on roadway) | **local**: NRS defines it and excludes it from "vehicle" | detector class; absent in CARLA |
| `ru.other_conveyance` | 484B.773 ("coaster, roller skates, sled or toy vehicle") | — | perception estimate |
| `ru.pedestrian` | 484A.165 (afoot, wheelchair, EPAMD); 484B.280–.297 | — | CARLA walker; class label |
| `ru.pedestrian_with_white_cane_or_guide_animal` | 484B.290 | — (white-cane laws are US-wide) | perception only; absent in CARLA and in trajectory datasets |
| `ru.child` | 484B.363(3)(a) ("when there are no children present"); 484B.280(1)(c)(3) | — | CARLA walker blueprint age; perception estimate |
| `ru.emergency_vehicle` | 484A.020, .480, .490; 484B.267, .550(1), .607(3)(a), .700, .710; 484D.400(5) | — (kinds general) | CARLA police/fire/ambulance blueprints; livery elsewhere |
| `ru.fire_apparatus` | 484B.710 (500 ft following distance), 484B.913 (fire hose) | — | livery |
| `ru.official_vehicle` | 484B.267 ("official vehicle of a regulatory agency", 484A.205); 484B.607(3)(b)–(h) (tow car, DOT vehicle, contractor, utility, local agency); 484B.210(4)(c),(f) ("traffic incident management vehicle", "coroner vehicle") | kinds `regulatory_agency`, `incident_management` **local**: NRS-defined roles with NRS-specific lamp rights | livery + amber/blue lamps; absent in CARLA |
| `ru.procession_vehicle` | 484A.090; 484B.703 ("pennants or other authorized insignia"), .707 | — | perception only |
| `ru.animal_or_animal_drawn` | 484A.285 (traffic includes ridden or herded animals); 484B.103, .297(5), .703 | — | absent in CARLA |
| `ru.rail_vehicle` | 484A.200, 484B.050 ("railroad train"); 484B.553–.563 ("other on-track equipment", streetcar) | — | absent in CARLA maps |
| `ru.personal_delivery_device` | 484B.044, .045, .787 | **local**: NRS-defined device with pedestrian rights | perception only |
| `ru.mobile_carrying_device` | 484B.029, .790 | **local**: NRS-defined device | perception only |
| `ru.occupant_count` | 484A.460(4), 484B.323(3) (high-occupancy vehicle: more than one person) | — (the HOV *rule* is local; the count is generic) | not observable from outside except by perception through glass; usually `absent` |
| `ru.subject` | every provision addressed to "the driver of a vehicle" | — | ego |

## 4. Kinematics (`kin`)

| atom | NRS provisions | grounding notes |
|---|---|---|
| `kin.time` | every temporal phrase ("until", "continuously", "remain stopped until") | timestamps |
| `kin.position`, `kin.heading`, `kin.velocity`, `kin.speed` | 484B.600–.637 (speed), .603 (decrease speed), .207 ("shall not increase the speed"), .413(3) ("suddenly decrease the speed"), .220 (direction), .253/.283 (approaching) | CARLA exact; datasets exact; perception estimate |
| `kin.accel_longitudinal` | 484B.413(3), .603, .607(1)(a) | derived from velocity where not measured |
| `kin.yaw_rate` | turning provisions (484B.400–.413) as the observable of a turn | derived |
| `kin.extent` | 484B.127(2) ("80 inches or more in overall width"), .270(2)(b) ("any portion of the vehicle"), .560(8) ("trailing end of the vehicle"), .457 ("right-hand wheels … within 18 inches") | CARLA bounding box; datasets box; perception estimate |
| `kin.steer_angle` | 484B.533 ("turning the front wheels to the curb") — the only provision where a steering input is itself the obligation | CARLA control; otherwise absent |
| `kin.path_length` | 484B.413(2) ("last 100 feet traveled"/"300 feet"), .223(3)(b),(c) ("more than 200 feet in a center turn lane", "50 feet"), .210(1)(c)(1) ("200 feet in the section of pavement"), .650(1) ("within the course of 1 mile") | integrated from position; odometer where available |

Not an atom, although NRS refers to it: gear selection (484B.560(2)), engine running and brake
set (484B.530, .533), "knows or reasonably should know" (484B.208 → `jdg.knowledge`).

## 5. Road structure (`st`)

| atom | NRS provisions | local? why | grounding notes |
|---|---|---|---|
| `st.highway` | 484A.095 (entire width incl. sidewalks), 484A.215/.265 (road/street); "upon a highway" in nearly every provision | — | map extent |
| `st.roadway` | 484A.220, .300 ("traveled portion … exclusive of the berm or shoulder"); 484B.440 ("paved or main-traveled part"), .627(2), .763 | — | CARLA driving lanes; HD map |
| `st.lane`, `st.lane_direction`, `st.lane_adjacency`, `st.lane_connectivity` | 484A.110 (laned highway); 484B.208 ("extreme left lane"), .223 ("two or more clearly marked lanes", "three clearly marked lanes", "center lane", "extreme left lane"), .270(2)(a) ("lane to the immediate left"), .400 ("extreme right lane"), .560(3) ("marked for four or more lanes"), .607(1)(d) ("lane that is not adjacent") | — | CARLA waypoints; HD map; perception estimate |
| `st.lane_marking` | 484B.217(2) ("pavement striping designed to mark such zone"), .587(2)(b) ("solid white line that separates an entrance or exit lane"), .213 | — | CARLA lane marking API; HD map |
| `st.centre_line` | 484A.040; 484B.213(1) ("left side of the center"), .400(2)–(4) ("nearest the centerline") | — | HD map |
| `st.road_edge` | 484B.120 ("right hand edge"), .267(1)(b) ("right-hand edge or … curb"), .457 ("right-hand curb"), .627(1)(a) ("extreme right side"), .210(3) ("paved portion") | — | HD map; **paved** attribute from surface type |
| `st.shoulder` | 484B.210(4), .267(1)(b), .587(3) ("paved shoulder … where lawfully placed signage allows"); 484D.165(3), .215 | — | HD map |
| `st.sidewalk` | 484A.240; 484B.117, .297, .450(1)(a), .785(1)(b), .787, .790 | — | HD map; segmentation |
| `st.median_or_divider` | 484A.070 (divided highway); 484B.227 ("dividing space, barrier or section", "opening in the barrier", "crossover"), .353(2), .403(3) | — | HD map |
| `st.one_way_roadway` | 484B.220(1), .307(8)(c), .400(3)–(5), .493, .497 | — | HD map lane directions |
| `st.intersection` | 484A.105 (incl. the 30-ft separate-roadway rule, alley junctions excluded); 484B.113(2), .213(2)(b), .250–.257, .307, .400, .403(3), .450(1)(c), .637(2)(b) | — | CARLA junction; HD map |
| `st.crosswalk` | 484A.065 (marked, or unmarked at intersections); 484A.450; 484B.113(2), .283, .287, .307(8)(a), .310(1), .450(1)(e),(f), .787, .790 | — | CARLA `get_crosswalks` (marked only; unmarked from sidewalk prolongation); HD map |
| `st.stop_line` | 484A.450 ("clearly marked stop line"); 484B.250(4), .257(1), .307(8)(a) ("pavement marking"), .310(1) ("limit line") | — | CARLA stop waypoints; HD map |
| `st.driveway_or_alley_entrance` | 484A.190; 484B.117(1), .210(1)(c)(2), .260, .270(3)(a), .450(1)(b),(n) | — | HD map |
| `st.alley` | 484A.015; 484B.477 | — | HD map |
| `st.curvature`, `st.grade`, `st.sight_distance` | 484B.213(2)(a) ("crest of a grade or upon a curve … view is obstructed"), .407 ("cannot be seen … within 500 feet"), .603 ("curve", "hill crest", "narrow or winding"), .533 ("perceptible grade") | — | map geometry; sight distance from map occlusion |
| `st.railway_crossing` | 484B.047 (railroad sign/signal), .213(2)(b), .450(1)(i), .553–.563 ("nearest rail", "nearest track") | — | HD map; absent in CARLA maps |
| `st.controlled_access` | 484A.060; 484B.208, .263, .587 ("marked entrance or exit lane"), .627(1)(c) | — | HD map road class |
| `st.elevated_structure` | 484B.213(2)(c), .450(1)(m), .633 | — | HD map |
| `st.bicycle_lane_or_path` | 484B.270(3),(4) ("pathway or lane provided for bicycles"), .297(6)(c), .768(2)(a), .777(3), .785(1)(a) | — | HD map |
| `st.reserved_lane` | 484A.460 (HOV: occupancy and hours conditions), 484B.323; 484B.590 (heavy-vehicle lanes) | class `high_occupancy`: **local** (conditions set by NDOT signage) | HD map lane type; signs |
| `st.centre_turn_lane` | 484B.223(3) ("single center lane to be used only for turning by traffic moving in both directions", with 200 ft / 50 ft limits) | **local**: two-way left-turn lane with NRS distance limits | HD map lane type |
| `st.turn_lane` | 484B.223(4) ("single right lane to be used only for turning"), .400(1), .768(2)(a) ("designated turn lane") | — | HD map |
| `st.parking_space` | 484B.457 (parallel), .460 (angle parking), .467/.468 (designated spaces) | — | HD map |
| `st.curb_zone` | 484B.023 (freight curb loading zone), .033 (passenger curb loading zone), .035/.067 (bus stand, taxicab stand), .503–.517 (restricted parking zone) | — | signage; absent in CARLA |
| `st.transit_stop` | 484B.280(1)(c)(2) ("bus stop or bench, shelter or transit stop") | — | map POI |
| `st.safety_zone` | 484B.057; 484B.110, .283(1)(d)(3),(4), .450(1)(h) | — | markings/signs |
| `st.pedestrian_grade_separation` | 484B.287(1)(b) | — | map |
| `st.turnout` | 484B.630(1) ("place designated as a turnout by signs", "sufficient area for a safe turnout") | — | map / signs |
| `st.fire_hydrant`, `st.fire_station_entrance` | 484B.450(1)(d), (j) | — | map POI; perception |
| `st.lane_width` | 484B.777(2)(b) ("lane is too narrow"), .440 ("unobstructed width"), .477(1)(b) ("less than 10 feet of the width of the alley") | — | HD map |
| `st.obstruction` | 484B.450(1)(k) ("highway excavation or obstruction"), .607(3)(i)–(k) ("crash scene", "stalled vehicle", "debris on the roadway"), .913 ("unprotected hose"), .208(2)(b), .297(6) | — | perception; CARLA static props |
| `rel.occupies` | every "upon", "within", "on" phrase | — | footprint–polygon test |

## 6. Control devices (`dev`)

| atom | NRS provisions | local? why | grounding notes |
|---|---|---|---|
| `dev.traffic_signal` | 484A.290; 484B.250(4) ("installed and has its vehicular signals uncovered, but is inoperative"), .307(2)–(9), (11), .310 | state `flashing_yellow_arrow`: **local** (484B.307(7), permissive-turn indication; MUTCD 2009 but the duties are stated by NRS); `dir = u_turn` retained for completeness | CARLA traffic light state (no arrows; **flashing and arrows are absent** in CARLA — manifest must say so); perception: estimate |
| `dev.pedestrian_signal` | 484B.283(1)(d) ("Walk", "Don't Walk", "Wait", walking person, upraised hand, flashing, **countdown timer**) | countdown semantics **local** (484B.283(1)(d)(2): a pedestrian may start during a flashing hand with countdown and must finish by zero) | absent in CARLA; perception |
| `dev.lane_control_signal` | 484B.307(12) ("downward-pointing green arrow", "red 'X' symbol") | **local**: NRS states the duties; used on Las Vegas reversible/managed lanes | absent in CARLA; perception |
| `dev.speed_limit_beacon` | 484B.363(1)(c), (9) ("two or more yellow lights that flash alternately to indicate when the speed limit … is in effect") | **local**: NRS-defined device that switches the school-zone limit | absent in CARLA; perception |
| `dev.stop_sign`, `dev.yield_sign` | 484A.450; 484B.250(4) ("as if a stop sign had been erected"), .257, .557 | — | CARLA stop/yield actors; HD map; perception |
| `dev.speed_limit_sign` | 484B.600(1)(c) ("posted"), .620 ("speed zone"), .623(2) ("minimum speed limit"), .633 ("bridge … maximum speed"), .363 (school zone limits), .637 (posted 35 mph threshold), .208 ("posted speed limit"), .630(3) | — | CARLA speed-limit actors; map; perception |
| `dev.regulatory_sign` | 484B.220(1) ("signposted for one-way"), .300, .327 ("marked, signed or barricaded … closed"), .403(2) ("U-turn is prohibited"), .450(1)(o), .490, .493, .500, .560(4)(b),(d) ("abandoned", "exempt crossing"), .587(1) ("entrances and exits … indicated"), .587(3)/.210(4) ("signage allows that vehicle to use the shoulder"), .593; 484D.515 ("marked or posted … chains") | codes `shoulder_use_permitted`, `exempt_crossing`: **local** | CARLA: only speed/stop/yield exist → most codes absent; HD map signs; perception |
| `dev.zone_sign` | 484B.363(6) (school zone / school crossing zone begin and end signs with hours or "when children present"), 484B.130(3) (work zone begin/end), 484B.135(3) (pedestrian safety zone begin/end), 484B.217 (no-passing zone devices), 484A.460(2) (HOV lane signs with conditions), 484B.590, .620, .490, .500, .453 | kinds `school_crossing`, `pedestrian_safety`, `high_occupancy_lane`: **local** (NRS-created zone types) | absent in CARLA; HD map; perception |
| `dev.railway_signal_or_gate` | 484B.047; 484B.553(1)(a),(b) ("electric or mechanical signal device", "crossing gate is lowered"), (2) ("gate or barrier … closed or is being opened or closed") | — | absent in CARLA; perception |
| `dev.temporary_traffic_control` | 484B.130 (temporary traffic control zone), .327 ("barricaded"), .330, .200(1)(b) ("right half … closed to traffic") | — | CARLA cones/barriers as props; perception |
| `dev.human_direction` | 484B.100 (police officer), .257 ("controlled by a police officer"), .267 ("directed by a law enforcement officer"), .330 (authorized flagger), .350 (school crossing guard), .553(1)(b) (railroad flagger), .703 (funeral escort directing), .560(4)(a), .703 | — | absent in CARLA; perception estimate |
| `dev.school_bus_signal` | 484B.353(1) ("flashing red light signal visible from the front and rear"); stop arm and amber pre-warning are the standard US equipment | — | absent in CARLA; perception |
| `dev.governs`, `dev.position`, `dev.inoperative` | "facing the signal" (484B.307), "at the side of a highway" (484B.450(1)(g)), "signal … at a place other than an intersection" (484B.307(11)), 484B.250(4) | — | CARLA `get_stop_waypoints`/affected lanes; HD map |

## 7. Signals emitted by road users (`sig`)

| atom | NRS provisions | local? why | grounding notes |
|---|---|---|---|
| `sig.turn_indicator` | 484B.223(1)(b), .217(3),(4), .413(2), .417, .210(1)(a) ("signaling to make a left turn"), .768 | — | CARLA light state; perception |
| `sig.brake_lamp` | 484D.125 (equipment); 484B.413(3) as evidence of a stop signal | — | CARLA light state; perception |
| `sig.hazard` | 484D.205(5) (simultaneously flashing warning lamps) | — | CARLA light state |
| `sig.headlamp` | 484D.100, .215 (dim within 500 ft oncoming / 300 ft following), .220(1), .165(4); 484B.707(2). The alternately-flashing state (484A.480(4),(5)) was dropped with the equipment-legality lines | — | CARLA light state (low/high); perception |
| `sig.position_lamp` | 484B.473(2) ("cowl or parking lamps"); 484D.165 | — | CARLA light state |
| `sig.reverse_lamp` | 484D.205(4) ("shall not be lighted when the vehicle is in forward motion") | — | CARLA light state |
| `sig.warning_lamp` | 484A.480(3) (red flashing front; red or blue revolving/flashing/steady), (6),(7) (red-to-front and blue prohibited otherwise); 484B.267 ("flashing lights meeting … 484A.480(3)"); 484D.185, .190, .195, 484B.748, .757 (flashing amber); 484D.200, .475 (**nonflashing blue** rear lamps on DOT/tow vehicles); 484B.550(2) ("flashing red lamp and siren"); 484B.607(3) | amber roles and steady-blue rear lamps: **local** | CARLA: emergency blueprints have special lights (no colour/mode detail) → estimate; perception |
| `sig.siren` | 484D.400(3),(5); 484B.550(2); 484B.700(2) ("audible and visual signals") | — | absent in CARLA (no audio); video: audio track if present |
| `sig.horn` | 484D.400(2); 484B.270(5)(b), .280(1)(b), .413(1) ("clearly audible signal by sounding the horn"); 484B.553(1)(c) (train signal audible) | — | audio only |
| `sig.hand_signal` | 484B.417, .420 (left: horizontal; right: upward; stop: downward; re-enter: horizontal), .769 | — | perception (pose) only |
| `sig.door_open` | 484B.153(2),(3) | — | CARLA door state (0.9.14+); perception |

## 8. Environment (`env`)

| atom | NRS provisions | grounding notes |
|---|---|---|
| `env.darkness` | 484D.100(1)(a) ("one-half hour after sunset to one-half hour before sunrise"), 484B.473, .783 ("at night"), 484D.860 | CARLA sun altitude; video: clock + location |
| `env.precipitation`, `env.wet_road` | 484B.600(1)(a) ("weather"), .603, .413(2) ("regardless of the weather"), .208(2)(b) ("inclement weather") | CARLA weather; perception |
| `env.visibility` | 484D.100(1)(b) ("not clearly discernible at a distance of 1,000 feet"), 484D.165(2),(3) | CARLA fog density; perception estimate |

## 9. Relations (`rel`)

| atom | NRS provisions | notes |
|---|---|---|
| `rel.centre_distance`, `rel.surface_gap` | 484B.270(2)(b) ("not less than 3 feet between any portion of the vehicle and the bicycle"), .710 (500 ft), .127(2) (500 ft), 484D.215 (500 ft / 300 ft), .450(1)(d)–(j) (15/20/30/50/75 ft), .553 (15–50 ft from nearest track), .407 (500 ft) | the bicycle-passing clearance is a *surface* gap by its wording |
| `rel.ahead_behind_in_lane` | 484B.127(1) ("follow another vehicle"), .207, .413(3) ("vehicle immediately to the rear"), .630 ("behind which five or more vehicles are formed in a line") | |
| `rel.longitudinal_overlap` | 484B.267(2)(d) ("not drive abreast of or overtake"), .777(3) ("two abreast") | new in this draft |
| `rel.oncoming`, `rel.same_direction` | 484B.203, .207, .213, .253 ("approaching from the opposite direction"), .270(2) | |
| `rel.bearing` | 484B.250(2) ("vehicle on the right"), .283(1)(a) ("half of the highway upon which the vehicle is traveling"), .400 | |

## 10. Judgement standards — provenance of the operationalization table (ATOMS.md §8)

Since 2026-09-20 there is no `jdg` family: a standard is not an atom and is operationalized per
node as a claim on a derived concept (ATOMS.md §8, termination clause 4). This table keeps the
phrasings each standard takes in the corpus, which is what the operationalization table in
§8 was written from. The first column is the standard's former atom id, kept as a label only.

| standard (former id) | NRS phrasings |
|---|---|
| `jdg.safe` | "can be made with reasonable safety" (484B.113(1), .413(1)), "with safety" (484B.223(1)(b), .410, .403(1)), "safely clear" (484B.207(1), .270(2)(b)), "conditions permitting such movement in safety" (484B.210(2)), "until the driver can do so safely" (484B.553, .560), "reasonably safe" (484B.270(2)(a)) |
| `jdg.reasonable_and_prudent` | "reasonable and prudent" (484B.127(1)), "reasonable or proper" (484B.600(1)(a), .607(1)(a), .267(2)(a)), "as reasonably possible" (484B.120) |
| `jdg.practicable` | "as nearly as practicable" (484B.223(1)(a), .400, .777), "if possible" (484B.607(1)(d), .267(2)(e)), "whenever conditions permit" (484B.127(2)), "when it is practicable" (484B.440) |
| `jdg.immediate_hazard` | "so close thereto as to constitute an immediate hazard" (484B.253, .257, .263), "hazardous proximity" (484B.553(1)(d)), "immediate hazard" (484B.650(1)(c)), "so close that it is impossible for the driver to yield" (484B.283(1)(b)), "approaching so closely … as to be in danger" (484B.283(1)(a)) |
| `jdg.due_care` | "due care" (484B.270(5)(a), .280(1)(a), .557, .603), "proper caution" (484B.280(1)(c)), "with caution"/"cautiously" (484B.250(4), .257(2), .307(7), .310(2), .607(1)(b)), "be prepared to stop" (484B.607(1)(c)) |
| `jdg.necessary` | "when reasonably necessary" (484D.400(2)), "if appropriate and when necessary" (484B.270(5)(b), .280(1)(b)), "except when necessary to avoid conflict" (484B.450(1)), "longer than is necessary" (484B.153(3)), "necessary for safe operation" (484B.623, .627(2)) |
| `jdg.impede` | "impede the normal and reasonable movement of traffic" (484B.623, .627), "interfering with other traffic" (484B.113(1), .153(2)), "no impediment to oncoming or following traffic" (484B.217(3),(4)), "unreasonably interfere" (484B.787, .790) |
| `jdg.clearly_visible` | "clearly visible" (484B.213(1), .223(2)(a), .553), "view is obstructed" (484B.213(2)), "cannot be seen … within 500 feet" (484B.407), "plainly visible" (484B.553(1)(d)), "sufficiently legible to be seen by an ordinarily observant person" (484B.300(2)) |
| `jdg.knowledge` | "knows, or reasonably should know" (484B.208(1)), "has determined that the vehicle being overtaken was not stopped for the purpose of permitting a pedestrian to cross" (484B.283(1)(c)) |
| `jdg.intent` | "intentionally interfere" (484B.270(1), (7)(a)), "willfully fails or refuses" (484B.100, .550) |
| `jdg.reckless_disregard` | "willful or wanton disregard of the safety of persons or property" (484B.653(1)(a)), "due regard for the safety of all persons" (484B.700(4)) |

## 11. Derived concepts (`drv`) — which provisions need each

| drv | provisions | note |
|---|---|---|
| `drv.stopped` | 484A.255 ("complete cessation from movement"); 484A.450, 484B.257, .307(8)(a), .310(1), .350, .353, .553–.560, .627(2) | ε and dwell d are reading parameters; the statute gives none |
| `drv.standing_or_parked` | 484A.155 (park), .250 (stand), .260 (stop when prohibited: "any halting, even momentarily"); 484B.440–.533 | three legal grades of halting; the reading maps them to d |
| `drv.moving_off` | 484B.410, .283(1)(c) | |
| `drv.turning`, `drv.u_turn` | 484B.077 (U-turn def.: "whether accomplished by one continuous movement or not"); 484B.400–.413, .227, .363(3), .403, .407 | |
| `drv.lane_change` | 484B.223(1)(b), .270(2)(a), .607(1)(d), .267(2)(e) | |
| `drv.overtaking`, `drv.passing_side` | 484B.207–.217, .270(2), .283(1)(c), .353, .363(4), .267(2)(d) | |
| `drv.entering_intersection` / `in_intersection` / `approaching` | 484B.250–.257, .307(6)(a) ("must not enter the intersection when the red signal is exhibited"), (13)(b) ("completely entered": all portions past the limit line), .113(2), .223(4)(b) | |
| `drv.crossing_line`, `drv.cleared_line` | 484B.307(8)(a), (13)(b); 484B.560(7),(8) ("trailing end … 15 feet or more past the nearest rail") | `cleared_line d` new in this draft |
| `drv.backing` | 484B.113; 484D.205(4) | |
| `drv.following`, `drv.time_gap` | 484B.127, .710, .707(1) | |
| `drv.meeting` | 484B.203, .353 ("meeting or overtaking, from either direction") | |
| `drv.yields_to`, `drv.arrival_order` | 484A.210 (right-of-way def.); 484B.250 ("approximately the same time"), .253, .257, .260, .263, .267(1)(a), .283 | τ from the reading |
| `drv.wrong_way` | 484B.220(1), .227 | |
| `drv.straddles_marking` | 484B.217(2), .223(1)(a), .587(2)(b) | |
| `drv.responding_emergency` | 484A.480(3), 484B.267(1), .700(2) | lamp colour red or blue per 484A.480(3) |
| `drv.vulnerable_road_user` | 484B.270, .280, .283, .650(1)(c) | |
| `drv.laned_roadway`, `drv.extreme_lane` | 484A.110; 484B.208, .223, .400(1), .627(1)(b) | |
| `drv.priority_roadway` | 484A.275 (through highway: stop **or yield** sign at entrances); 484B.250(3), .257 | renamed from `drv.through_highway` |
| `drv.distance_while` | 484B.413(2), .223(3)(b),(c), .210(1)(c)(1), .650(1) | new: path-length window |
| `drv.within_signed_zone` | 484B.363, .130, .135, .217, .323, .620 | new |
| `drv.queue_behind` | 484B.630(1) ("five or more vehicles are formed in a line") | new |
| `drv.signal_cycles` | 484B.307(8)(d)(1), (9)(b)(2) ("waits for two complete cycles") | new |
| `drv.slower_than_posted` | 484B.208(1), .630(3) | new |

## 12. NRS elements deliberately not made atoms

| element | where it goes |
|---|---|
| business district (484B.010: buildings on 300 ft of frontage within 600 ft), residence district (484B.053), urban area (484A.315), rural area (484A.225), city/town limits (484B.208(2)(e)), unincorporated town (484B.610) | reading assumption per map |
| mountain highway, defile, canyon (484B.120); narrow or winding highway (484B.603) | reading assumption per map (curvature and width atoms give the observable part) |
| premises to which the public has access (484A.185) | reading assumption per map |
| school in session; school hours; "half hour after school is no longer in operation" (484B.363) | reading assumption per trace (calendar); the beacon and sign legend are atoms |
| hours a loading zone or parking restriction is in effect (484B.503–.510) | reading assumption per trace unless the sign states them (then `dev.zone_sign.conditions`) |
| through highway *designation* (484A.275, 484A.450(1)) | `drv.priority_roadway` from the signs at the entrances |
| "stopped to receive or discharge any pupil" (484B.353), "stopped for the purpose of permitting a pedestrian to cross" (484B.283(1)(c)), "expeditious loading or unloading" (484B.477–.517), "engaged in the construction, maintenance or repair of the highway" (484B.208(2)(a)(4)) | purpose — not observable; rules state the evidence they use and carry the residue |
| "lawfully within the intersection", "lawfully riding", "lawfully parked" | rule composition (another rule's verdict) |
| gear, engine, parking brake (484B.530, .533, .560(2)) | interior state — excluded from the corpus except 484B.533's wheel angle |
| "readily identifiable vehicle of any police department" (484B.550) | `ru.emergency_vehicle` kind police with `sig.warning_lamp` red + `sig.siren` (484B.550(2) makes the signal observable) |
| driver-assistive platooning (484B.127(5)), autonomous vehicle driver definition (484A.080) | out of scope for scene evaluation |

## 13. Open review items

1. `dev.traffic_signal` admits several simultaneous states (circular green with a green arrow;
   steady red with a green arrow) — the Core type is a *set* of indications, not one value.
   Reviewer to confirm the arrow directions {left, right, straight, u_turn} are sufficient.
2. `st.curb_zone` and `dev.zone_sign` overlap in the parking area (a restricted parking zone is
   both a signed length of curb and a zone). Convention proposed: the *region* is `st.curb_zone`;
   the sign that establishes it is `dev.zone_sign`/`dev.regulatory_sign`. Rules use the region.
3. `ru.occupant_count` will be `absent` on every planned source; the HOV rule (484B.323) will
   report `unknown` unless the reading supplies an assumption. This is the intended outcome.
4. Whether `ru.electric_bicycle` should carry the three-class attribute at all: no corpus line
   turns on the class. Kept because NRS 484B.017 defines it and local ordinances may.

## 14. Extension for NRS 486 and LVMC Title 11 (2026-09-18)

New or changed atoms, with the provisions that required them. Everything else in the municipal
and motorcycle lines maps onto atoms already listed above.

| atom / change | provisions | local? why | grounding notes |
|---|---|---|---|
| `ru.tour_bus_or_limousine` (new) | LVMC 11.02.090, .150 (tour bus, shuttle bus, limousine); 11.44.080 (tour-bus loading zone); 11.52.030(A)(2); 11.60.030(B) | **local**: LVMC-defined classes with their own curb rights on the Strip/downtown | livery; perception estimate |
| `ru.vending_vehicle` (new) | LVMC 11.22.150 (ice cream truck with safety equipment engaged, 15 mph within 100 ft); NRS 484D.190 (food vendor amber light and warning signs) | **local**: the vending-vehicle rule and its equipment are LVMC/NRS creations | livery + amber lamp + signs; perception |
| `ru.official_vehicle` kinds `armored_car`, `municipal` (added) | LVMC 11.52.030(A)(4), 11.52.130(A)(3) ("ARMORED CARS ONLY"); 11.52.340 (City vehicle spaces) | `armored_car` **local** | livery |
| `ru.rider_posture` (new; **stunt** attribute added 2026-09-20) | NRS 486.191(1), .211 ("at least one hand on a handlebar"), .181; 484B.770(1), .773, .780; LVMC 11.38.010, .040 ("hold to any moving vehicle"), 11.40.090, .150, .160, .185(B) ("ride on handlebars", "wheelies") | — | perception (pose) only |
| `st.roundabout` (replaces the first draft's rotary island) | LVMC 11.02.040 (circulatory roadway), .130 (roundabout incl. approaches and crosswalks); 11.43.010 (counterclockwise, yield on entry, exit lane discipline); NRS 484B.220(2) | — | HD map; CARLA junction geometry |
| `st.curb_zone` **colour** attribute and kinds `fire_lane`, `hotel_loading`, `tour_bus_loading`, `time_limited` (added) | LVMC 11.52.030 (red/yellow/white/gray/blue curb code), 11.52.130(A)(2) (fire lane), 11.44.030 (hotel), .040 (time-limited), .080 (tour bus), 11.52.240–.270 ("curbing … painted red giving notice") | **local**: the colour code is municipal | curb paint colour: perception; absent in CARLA |
| `st.parking_space` **designation** attribute (added) | LVMC 11.02.030 (access aisle), 11.52.030(E), .135, .136 (handicapped spaces, side-lift spaces, access aisles), .340 (municipal); NRS 484B.467, .468 (disabled, charging) | — | markings/signs |
| `st.obstruction` kind `sidewalk_fixture` (added) | LVMC 11.52.130(A)(5) (sidewalk elevator or chute) | — | perception |
| `dev.regulatory_sign` codes `turn_course_marker`, `right_turn_only`, `nonmotorized_prohibited`, `motor_vehicles_prohibited`, `truck_route`, `no_trucks`, `golf_cart_crossing` (added) | LVMC 11.12.020 (markers/buttons indicating turning course); 11.60.090 (taxistand right-turn sign); 11.22.120 (nonmotorized traffic prohibited); 11.27.010 (motorized vehicles prohibited on trails); 11.48.030, .080 (truck routes posted), 11.16.110; 11.41.020 (golf cart crossing) | `truck_route`, `golf_cart_crossing`: **local** | HD map signs; perception |
| `dev.zone_sign` kinds `pedestrian_mall`, `park_grounds`, `trail` (added) | LVMC 11.68.030 (Pedestrian Mall); 11.16.050 (park grounds 15 mph); 11.27.010 (trail posted) | **local** | signs; the region itself is a reading assumption where unsigned |

Municipal elements handled by existing atoms and derived concepts, for the reviewer's
convenience: fifteen-foot intersection setback (`st.intersection` + `rel.surface_gap`);
blind-intersection and rail-crossing 15 mph limits (`st.sight_distance`, `drv.approaching`,
`drv.distance_while`); anti-gridlock (`st.intersection`, `st.crosswalk`, `rel.surface_gap` to the
vehicle ahead beyond the far boundary, `jdg.impede`); stop before the sidewalk when emerging from
an alley in a district (`st.sidewalk`, `st.driveway_or_alley_entrance`, `drv.stopped`, `asm.*`
district); reversible lanes (`dev.lane_control_signal`, `dev.regulatory_sign` lane_use_arrow,
`st.lane_direction` with time-varying value); lane splitting (`rel.longitudinal_overlap` with
two vehicles in adjacent lanes, `rel.occupies` on the marking); moped in the right lane within a
quarter mile of a left turn (`drv.extreme_lane`, `drv.distance_while`, `drv.turning`); taxistand
right turn (`st.curb_zone` taxicab_stand, `dev.regulatory_sign` right_turn_only, `drv.turning`
at the first `st.intersection`).

Municipal elements deliberately not made atoms: "Schedule NN" street lists (reading assumption
per map; the sign is the atom), the Central Traffic District and the Pedestrian Mall boundaries
(reading assumption; `dev.zone_sign` where posted), "unladen weight in excess of eight thousand
pounds" and "overall length of twenty-four feet" (class estimate from `ru.*` and `kin.extent`;
residue), "protective foot covering" (residue), "celebrity home tour", "nonprofit function",
"demonstration ride by a licensed dealer" (purpose; residue), a passenger's age of sixteen
(residue), "engine running", "key removed", "locking the ignition" (interior state; residue).

## 15. Alignment with the pipeline corpus (2026-09-20)

The pipeline corpus is `laws/example/laws.jsonl` = the concrete and judgement tiers (303 lines);
`excluded.jsonl` (11) and `unresolvable.jsonl` (8) are outside it (`nrs_tools/tiers.py`). Every
atom in `ATOMS.md` was checked against the sections that survive in the 303 lines
(`nrs_tools/` alignment scan). Changes:

**Dropped — every provision that needed them is outside the corpus**

| atom or value | needed only by | now in |
|---|---|---|
| `ru.protective_headgear` | NRS 486.231(2), LVMC 11.38.130, 11.40.185(C) | excluded (apparel) |
| `ru.special_mobile_equipment` | NRS 484D.545 | excluded (equipment legality) |
| `ru.golf_cart`; `dev.regulatory_sign` code `golf_cart_crossing` | LVMC 11.41.020 | unresolvable (schedule region) |
| `sig.slow_moving_emblem` | NRS 484D.545 | excluded |
| `sig.headlamp` state `flashing_alternately` | NRS 484A.480(5) | excluded |
| `dev.regulatory_sign` code `chains_required` | NRS 484D.515 | excluded (`env.ice_or_snow` was dropped with it on 2026-09-20 and **restored the same day**: weather and surface conditions are what every speed and care standard is judged against — NRS 484B.600(1)(a) "weather and other highway conditions", .603, .208(2)(b) "inclement weather", .413(2) "regardless of the weather" — and are kept whether or not one clause names them) |
| `dev.zone_sign` kinds `pedestrian_mall`, `park_grounds` | LVMC 11.68.030, 11.16.050 | unresolvable |
| the whole `jdg` family (11 ids) | every judgement line | replaced by ATOMS.md §8 (operationalization) |

**Kept although the scan found no surviving *cited* section** (the citation was a definition or
a dropped duplicate, and the element is used by a surviving line): `st.highway` (the term is in
most lines), `ru.pedestrian_with_white_cane_or_guide_animal` (NRS 484B.290 was superseded by LVMC
11.30.140(B), which survives and adds "being assisted by a person"; contract widened accordingly),
`ru.other_conveyance` (NRS 484B.773 superseded by LVMC 11.40.150; LVMC 11.22.130(A) survives).

**Added**

| atom / derived concept | needed by | note |
|---|---|---|
| `sig.signal_arm` (local) | LVMC 11.22.150 via LVMC 6.47.100(C) (ice-cream-truck signal arm with flashing amber lamps) | the definition retrieved on 2026-09-19 |
| `ru.rider_posture` attribute `stunt` | LVMC 11.40.185(B) ("stunts or wheelies, ride on handlebars") | |
| `drv.time_to_conflict` | every "immediate hazard" / "so close as to be in danger" / "with safety" standard (NRS 484B.253, .257, .263, .283, .553, .650; 484B.207, .223, .270, .413, .768, .777) | the central operationalization; a projection-horizon parameter |
| `drv.lane_change_feasible` | NRS 484B.267(2)(e), .607(1)(d) ("if possible … unless unsafe") | |
| `drv.sight_distance_adequate`, `drv.stopping_distance` | NRS 484B.213, .407, .603; LVMC 11.16.030, .040 | stopping- and passing-distance models as parameters |
| `drv.hard_deceleration` | NRS 484B.413(3) ("suddenly decrease the speed"); surrogate for due-care lines | |
| `drv.speed_below_traffic` | NRS 484B.623, .627 ("so slow as to impede") | with `drv.queue_behind` |
| `drv.forced_halt` | the 17 parking lines' shared exception "except when necessary to avoid conflict with other traffic" (CORPUS_AUDIT §2c) | |
| `drv.officer_directed` | 12 lines' "except when otherwise directed by a law enforcement officer" (CORPUS_AUDIT §2c) | |
| `drv.slower_than_posted` gains a margin parameter | NRS 484B.208(1), .630(3) | |

**Provenance of the operationalization conventions named in ATOMS.md §8** (for the reviewer;
values themselves are proposed per node by the planner and land in the run's reading): time to
conflict / post-encroachment time as used in surrogate-safety analysis; the headway convention of
driver handbooks; stopping-sight and passing-sight distance models of the geometric design
manuals (speed-dependent); gap acceptance at unsignalised intersections. None of these appears in
`ATOMS.md` by name or figure; the file names only the kind of convention a claim has to cite.

**Not aligned yet**: `ru.commercial_motor_vehicle` and `ru.hazardous_materials_vehicle` rest on a
federal definition marked unresolved on NRS 484B.560(1), (5) (observable: placard, size); they stay.

## 16. Completeness audit against the 285-line corpus (2026-09-20)

Method: every content word of the corpus text (1,020 distinct after a stop-list) was checked for
an occurrence in `ATOMS.md`; the 510 that did not occur were reviewed by hand for an element with
no atom. Findings, and what changed:

| element in the corpus | lines | resolution |
|---|---|---|
| "collision", "colliding", "crash", "accident" | NRS 484B.270(5), .280(1), .603(1), .267(2)(a) ("scene of a crash"), LVMC 11.30.130, .40.140 | **added** `rel.contact` — contact is observable and is the only non-judgement content of the due-care lines |
| "engine compression brakes" | NRS 484D.285(1) (tier Q, in corpus) | **added** `sig.compression_brake` (audible; absent without audio) |
| "signal device … giving warning that children are about to cross" | LVMC 11.46.030 | **added** `dev.crossing_warning_signal` |
| "drop box for U.S. mail adjacent to a curb" | LVMC 11.52.030(A)(5) | **added** `st.obstruction` kind `mail_drop_box` |
| "tail lamp … lighted", "lighted lamps and illuminating devices" | LVMC 11.38.120(B) (reinstated), NRS 484D.100(1), .165(3) | `sig.position_lamp` contract now names tail lamps |
| weather: "weather", "inclement weather", "unfavorable atmospheric conditions", "regardless of the weather" | NRS 484B.600, .603, .208, .413(2), 484D.100(1)(b) | `env.precipitation`, `env.wet_road`, `env.ice_or_snow` (restored), `env.visibility` |
| "horse", "animal" | LVMC 11.12.090, NRS 484B.297(5), .703 | `ru.animal_or_animal_drawn` |
| "trimobile" | NRS 484B.307(8)(d), (9)(b), 486.351(2) | `ru.motorcycle` (three-wheeled variants) |
| "flagman", "person stationed", "school crossing guard", "escort" | NRS 484B.330, .350, .553, .703; LVMC 11.46.030 | `dev.human_direction` roles |
| "markers, buttons", "striping", "pavement marking" | LVMC 11.12.020; NRS 484B.217, .307(8)(a) | `dev.regulatory_sign` turn_course_marker; `st.lane_marking`; `st.stop_line` |
| "package, bundle or article" preventing a hand on the bar | NRS 484B.780 | `ru.rider_posture` hands_on_controls |
| "attended or unattended" | NRS 484B.440(1), .533 | `ru.occupant_count` |
| "diagonally" | NRS 484B.287(1)(d) | `kin.heading` against `st.crosswalk` |
| "merging" | NRS 484B.223(3)(c) | `drv.lane_change` |
| "unladen weight", "pounds", "overall length" | LVMC 11.52.305(A), 11.48.050/.060 | `kin.extent` for length; weight is a residue (documented §12) |
| "undercarriage clearance" | NRS 484B.560(7)(a) | residue (vehicle property, not observable) |
| street names (Fremont, Main, Seventh) | LVMC 11.22.130(B), 11.40.180(A) | reading assumption; the posted sign (`dev.regulatory_sign` bicycles_prohibited) is the observable |

Atoms **dropped** because no corpus line needs them after the 31 unresolvable lines left:
`ru.hazardous_materials_vehicle` (only NRS 484B.560(1)); `st.curb_zone` kinds `hotel_loading`
and `time_limited` (LVMC 11.44.030, .040, 11.52.270). Kept although their main line left:
`ru.occupant_count` and `st.reserved_lane` high_occupancy (NRS 484B.208(1) exception (a)(3)
composes HOV compliance), `dev.regulatory_sign` truck_route / no_trucks (LVMC 11.48.050, .060 remain),
`ru.tour_bus_or_limousine` (LVMC 11.52.030(A)(2) remains), `ru.commercial_motor_vehicle` (LVMC
11.52.305(A) remains).

**Reinstatement rule** (generator, 2026-09-20): when the narrower text kept in the overlap
resolution is unresolvable, the resolvable text it superseded returns to the corpus with a
`reinstated_for` field. Five lines returned: NRS 484B.503 (for LVMC 11.44.020), 484B.507(1) (for
11.44.060), 484B.477(1)(a) (for 11.52.180(A)), LVMC 11.22.100 (for NRS 484B.327(2), removed for its
penalty reference), LVMC 11.38.120(B) (for NRS 486.251(1), removed for its equipment reference).

## 17. Time-conditioned rules (2026-09-20)

The completeness audit of §16 missed the clock. The corpus conditions obligations on civil time in
four ways, and only the last was already covered:

| form | lines | observable | added |
|---|---|---|---|
| hours and days printed on a sign ("during the hours specified on the posted signage", "except Sundays and public holidays", HOV hours, school-zone hours) | LVMC 11.52.250, .260 (unresolvable for their schedule, but the form recurs), NRS 484B.323 (unresolvable), .363(1)(d), (2)(d), 484A.460(2) | the sign legend + the calendar time of the recording | `env.civil_time`; structured `conditions` on `dev.zone_sign` / `dev.regulatory_sign`; `drv.condition_in_effect` |
| fixed clock windows in the text ("between the hours of one a.m. and six a.m.", "seven p.m. and six a.m.") | LVMC 11.52.300, 11.48.050 | calendar time of the recording | `env.civil_time` |
| sunset/sunrise offsets ("one-half hour after sunset to one-half hour before sunrise", "nighttime") | NRS 484D.100(1)(a), 484D.165(3), 484B.473(2), LVMC 11.38.120(B) | either the observed light (`env.darkness`) or the calendar time with the date and location | `drv.civil_night` (offsets as parameters; date and location from the reading) — a rule states which of the two it reads |
| durations ("not to exceed three minutes", "thirty minutes within any one-hour period", "remain stopped until") | NRS 484B.503, .507(1); LVMC 11.44.*, 11.52.180(C) | trace time | already `kin.time` and `drv.standing_or_parked` |

Calendar classes that no clock gives — a school day, school hours, a public holiday — stay reading
assumptions (`asm.*`) per trace, as ATOMS.md §9 provides; `drv.condition_in_effect` consults them
when a sign's legend names such a class.

Grounding: civil time comes from the recording's metadata (a dashcam's timestamp, a dataset's
capture time, a simulator scenario's declared time of day and weekday); a source without it
declares `env.civil_time` absent and every hours-conditioned rule reports unknown, which is the
intended behaviour. The sign legend is read by the same perception that reads the sign; in
simulation it is scenario metadata.
