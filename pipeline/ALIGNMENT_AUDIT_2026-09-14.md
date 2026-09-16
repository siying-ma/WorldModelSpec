# Alignment audit: `carla_sgg` → `carla/adapter.py` → `carla/schema.json` → `Core/*.lean`

Date: 2026-09-14. Sources read in full: `carla_scene_graphs/carla_sgg/{sgg,sgg_abstractor,actors,utils}.py`,
`traffic-spec-agent/carla/adapter.py`, `traffic-spec-agent/carla/schema.json`,
`traffic-spec-agent/library/TrafficSpec/Core/*.lean` (all eight files),
`traffic-spec-agent/perception/portability.json`, `scripts/diagnostics/{doctor,sgg_surface}.py`,
the capture scripts `carla_scene_graphs/src/carlaspec/runner.py` and `capture_sensor_data.py`,
the CARLA PythonAPI reference shipped in `carla_scene_graphs/sim/PythonAPI/python_api.md`,
and BC Motor Vehicle Act [RSBC 1996] c.318 Part 3, ss.119–214 (downloaded from bclaws.gov.bc.ca).

Every fact about what a scene graph contains is cited to `carla_sgg/*.py` line numbers.
Recorded frames under `datasets/sceneflowlang/study_data` were opened for exactly two purposes,
both stated where used: to confirm how a CARLA enum survives pickling, and to measure how often
an RSV node name changes the physical actor it denotes. Neither is used as a source of schema facts.

---

## 1. Severity-ranked findings

Severity: **S1** silently changes verdicts on real captures; **S2** makes a formalizable clause look
unsupported or misleads the formalizing agent; **S3** documentation drift with no verdict effect.

### 1A. Core states or assumes what the generator does not deliver (user's item 1)

| # | Sev | Where in Core | What Core says or assumes | What the generator does | Landed |
|---|---|---|---|---|---|
| A1 | **S1** | `Core/Scene.lean::EntityId`, `Core/Grounding.lean` (binds one `EntityId` for the whole trace) | one id = one physical entity for the trace | `process_to_junction_rsv` names every actor `{base_class}_{n}` with `n` a **per-frame counter** (`sgg_abstractor.py:234-235`); the adapter keyed `EntityId` on that name, so `car_0` at frame *t* and `car_0` at *t+1* are different cars whenever a car ahead in iteration order enters or leaves the render box. Measured on frames only to size it: 17 of 938 frame transitions rename an actor on `HazardAtSideLaneTwoWays`, 101 of 1048 on `lav/run1/RouteScenario_18`. Every temporal formula over a non-ego binder compared one vehicle's frame with another's. | **Fixed in the adapter** (`entity_key`): identity from `carla_id` (`sgg.py:681`, `:607`, `:623`), the ego's `entity_id` (`:837`), `landmark_id` (`:717`), negative `entity_id` for scenery (`:462`), position for other static nodes. Core doc updated. |
| A2 | **S1** | `Core/Vocab.lean` §4b `hasHeading` / `headingAlignedWith` / `headingOpposedTo` read `fwd_*` as a unit heading on every actor-like node | `fwd_*` is a direction | In the traffic-light branch that iterates `get_light_boxes()`, `forward = bbox.location + unit_vector` (`sgg.py:595-600`) — a **point**, not a direction. Any heading predicate on a `.trafficLight` compared a map coordinate with a unit vector. The fallback branch (`:618`) is correct; the captures on disk took the fallback (no `carla_parent_id` on their light nodes), but the CARLA build in `.carlasg` has `get_light_boxes`, so new captures take the buggy branch. | **Repaired in the adapter** (`heading_vector`: subtract `vertex` when the raw value cannot be a unit vector). Core doc updated. Generator fix listed in §4b. |
| A3 | **S2** | `Core/Builders.lean::mkEgo (ty := .car)`, `adapter.classify` returns `car` for `ego` | the ego is a `.car`; `Pred.isVehicle ego`, `hasType ego .car` are data | The ego node is written with `sem_class = "ego"` (`sgg.py:560`) and the `carla_type_id` write is inside the non-ego actor loop (`:681-682`) the ego is excluded from (`:543-544`, `:575`). The ego's blueprint is **not in any capture**. A motorcycle, bus or truck ego is typed `.car`. | Documented on `mkEgo`. Cannot be repaired below the generator: listed in §4b. |
| A4 | **S2** | `Core/Vocab.lean` §7 header: light state recorded "for **every** `carla.Vehicle`, not just the ego" | ego lamps readable | The ego is never in the actor loop (`sgg.py:543-544`, `:575`); every §7 predicate is identically false on the ego. The schema had this right; Core had it wrong. | **Fixed** (§7 header rewritten). |
| A5 | **S2** | `Core/Vocab.lean` §5 `oncoming` doc and schema `angular_edges_and_lane_connectivity.available`: sector "computed from the **source** actor's forward vector" | frame of the edge's source | Bearing is taken from actor₁'s `forward` and the edge added is `actor₂ → actor₁` (`sgg_abstractor.py:272-282`, `:303-310`): the sector is judged in the **target's** frame. The predicate reading ("a is ahead of b") was right; the stated mechanism was inverted, which matters to anyone reasoning about `inDFrontOf` asymmetry. | **Fixed** in Core §5 and in the schema. |
| A6 | **S2** | `Pred.offRoadway` doc: "off the roadway" | Off Road = not on a driving lane | Off Road collects every actor with no edge to a **kept** driving node, and kept nodes are gradient-filtered against the ego's height (`sgg_abstractor.py:131-132`, `:247-248`, `utils.py::valid_gradient`). A vehicle on an overpass/underpass, a sign overlapping no lane, and every landmark read as off the roadway. | Documented in the schema (`isIn_edges.off_road_is_also_out_of_reach`, `off_road_node.data_limit`). Predicate name kept; semantics now stated. |
| A7 | **S3** | `Pred.canLaneChangeTo` doc: "a lane change is legal from l₁ to l₂" | per-position permission | The route planner's lane-change edge is extended to every node of the lane once any segment permits the change (`sgg.py:175-176`, `:259-305`), so `laneChange` is a per-lane permission; the marking at a point is base-graph only. | Documented in the schema. |
| A8 | **S3** | `Pred.sepSqMilli` drops z; docs say band and exact distance agree | same metric | Band edges are cut on the 3-D separation (`sgg_abstractor.py:265`); on a gradient the two differ by up to one band. | Documented in the schema. |
| A9 | **S3** | `mkLane` writes `sem_class = "Driving"` | an attribute the trace carries | RSV lane nodes carry **no** attributes (`sgg_abstractor.py:152`, `:19-23`); the value is a builder constant. Harmless, but a rule reading it reads Core, not data. | Documented in the schema `sem_class.on`. |

Not a finding, checked and consistent: `distanceBands` metres and order (`sgg_abstractor.py:116`, band = smallest threshold ≥ 3-D distance, `:287-291`); `proximityTypes` vs `DEFAULT_PROXIMITY_RELATIONS` ∩ `base_type_map`; the four angular arcs; `opposes` only between adjacent lane ids of one road (`:161-166`); `controls` from `get_affected_lane_waypoints` (`:628-631`) and stop-sign `trigger_volume` (`:675-679`); `light_state = str(actor.state)` (`:639`); `special_class` from `actors.py::special_type_map`; `at_traffic_light` (`:561`); every attribute key `Vocab.lean` reads is on the lifted side.

### 1B. Generator emits it, adapter dropped it (user's item 2) — all implemented

| # | Sev | Key (generator) | Emitted at | What it carries | Landed as |
|---|---|---|---|---|---|
| B1 | **S1** | `carla_id`, `entity_id`, `landmark_id` **as identity** | `sgg.py:681`, `:837`, `:462`, `:717` | the only stable cross-frame identity; was lifted as an attribute but the adapter still keyed entities by the counter name (finding A1) | `entity_key` in the adapter; `landmark_id` lifted; run report prints "N physical entities behind M node names" |
| B2 | **S2** | `landmark_orientation` | `sgg.py:710` | `carla.LandmarkOrientation`: **which direction of travel the sign faces**. Positive = lanes with negative OpenDRIVE ids, Negative = positive lanes, Both (CARLA PythonAPI reference, `carla.LandmarkOrientation`). The schema filed it under "physical geometry ... nothing can relate it to lanes", which is wrong: paired with the lane node's `lane_id` — the one use of that sign that is sound — it narrows `mayAffect` to the carriageway the sign faces. Pickled as a Boost enum → `OpaqueValue(args=(int,))`; decoded by member order, verified against `carla.LandmarkOrientation.names` in the `.carlasg` environment. | attribute `landmark_orientation` ∈ {Positive, Negative, Both}; `Pred.landmarkOrientation`, `landmarkFacesLane`, `landmarkOrientedFor`, `landmarkOfTypeOrientedFor` |
| B3 | **S2** | `threedbbox` (+ `right`, `up` to project it) | `sgg.py:837`, `:798`, `:462` | body extents; every separation in the library was centre-to-centre (open gap G16) | derived `half_length` / `half_width` / `half_height` (metres); `Pred.hasExtent`, `surfaceGapAtLeastCentimetres` (circumradius bound, sound lower bound on the surface gap), `surfaceGapAtMostCentimetres` (inradius bound, sound upper bound). Absent on the captures on disk, which predate the field. |
| B4 | **S2** | `entity_id < 0` / `sem_class ∈ CityObjectLabel names` | `sgg.py:462`, `:456`, `:415-426` | marks level scenery (parked props) that otherwise is a `.car` with full proximity edges | boolean `map_scenery`; `Pred.isMapScenery` |
| B5 | **S3** | `landmark_is_dynamic` | `sgg.py:720` | signal head vs static sign | attribute + `Pred.landmarkIsDynamic` |
| B6 | — | `ego_control_*` | `sgg.py:565-570` | the caller's commanded control, beside the applied control already lifted (`:562`) | **not lifted**, now documented as its own reason group (`available_not_exposed.commanded_control`); the schema previously claimed these replaced the control channels, which is false |

Deliberately still unlifted, each with a reason that holds for any law: `vertex_point`, `carla_type_id`,
`vehicle_light_state`, `light_All/NONE`, `landmark_{h_offset,height,width,pitch,roll,z_offset,name}`,
`carla_{parent_id,semantic_tags,actor_state,attr}`. `run_spec doctor` partitions 65 emitted keys into
49 lifted + 16 unlifted, every unlifted key matched by exactly one reason group.

### 1C. `carla/schema.json` disagreed with the generator (user's item 3) — all corrected

| # | Entry | Was | Is (cited) |
|---|---|---|---|
| C1 | `partially_available.angular_edges_and_lane_connectivity.mechanism` | cites `sgg_abstractor.py:185-195` (the **lane** left/right block) and "SOURCE actor's forward" | `:257-310` actor block, target's frame |
| C2 | `attribute_keys.kinds.carla_id.on` | "all actors" | non-ego actors and traffic lights only; not the ego (`:560-563`), not landmarks, not scenery |
| C3 | `kinds.accel.source` | "ego_logs ... the graph carries only components" | adapter computes the magnitude from `carla_acc_*` first; the log is the fallback |
| C4 | `static_background_vehicles` | cites `:607-608` for the actor-loop id writes | `:681-682`; `:607` is the light-box branch; also notes older generators passed no `entity_id` |
| C5 | `capture_preconditions.{capture_rate,proximity_band_metres,proximity_pair_table}.note` | `value_lives_at: time_base.capture_hz`, `relation_labels.proximity_bands_closest_first`, `...covered_base_classes` — sections that no longer exist (the doctor's cross-reference check scans Core and prompts, not the schema's own prose) | `Core/Scene.lean::captureHz`, `::distanceBands`, `::proximityTypes` |
| C6 | `available_not_exposed.conditional_on_the_carla_version.why` | "the branch runs and these keys are emitted" | both branches described; which one a capture took is readable (`carla_parent_id` absent on the fallback); the `forward` defect named |
| C7 | `capture_preconditions.ego_control_source.note` | "throttle, brake and steer arrive ABSENT" when a dict is passed | the applied control is always written (`:562`); `ego_control_*` is an additional copy |
| C8 | `junction_membership_and_controls.mechanism` | "junction membership is bounding-box containment" | lane nodes hang under a junction by the waypoint's OpenDRIVE `junction_id` (`sgg_abstractor.py:137`, `:143-150`); an actor's membership is bbox overlap with such a lane (`sgg.py:793`) |
| C9 | `governance_edges.landmarks`, `landmark_nodes_and_mayAffect.mechanism` | "within render distance of a lane" | `Waypoint.get_landmarks(render_dist)` returns landmarks **ahead along the lane** (`:695-698`), kept only inside the ego render box (`:699`); directional along the road, blind to carriageway |
| C10 | `governance_edges.traffic_light_targets` | omitted the fallback | `get_affected_lane_waypoints` matched in 3-D (`plane_projection=False`, `:630`); on builds lacking it the trigger volume is used (`:632-635`) — the stop-sign construction |
| C11 | `vehicle_light_booleans.available` | lists 3 of 11 lifted lamps | all 11 |
| C12 | `landmark_physical_geometry.why` | orientation is "shape and pose" | orientation, validities, is_dynamic, id are governance/identity and are lifted; the group is the residue |
| C13 | `off_road_node.data_limit`, `isIn_edges` | sidewalk collapse only | gradient filter consequence (A6) |
| C14 | `excluded_and_why` | — | `junction_boundary` added (not in the proximity table) |
| C15 | `kinds.name.source` | name is the entity identity, `carla_id` "the repair" | identity resolution as now implemented |

`perception/portability.json`: the four new sim-only keys and the three extents classed; the
`identity_across_frames` statement, which asserted a stability the adapter did not deliver, corrected.

---

## 2. What changed, against the plan

| File | Planned | Landed |
|---|---|---|
| `traffic-spec-agent/carla/adapter.py` | identity keying; lift orientation / is_dynamic / id / scenery / extents; heading repair | all of it, plus: ints render as plain integer strings (so `attrEq` on an id matches what a scenario writes); run report prints identity statistics; same-frame identity collisions are kept apart and counted |
| `traffic-spec-agent/carla/schema.json` | entries for every new key; corrections C1–C15 | all; `not_a_usable_value` no longer claims `entity_id`; `volume` no longer claims `threedbbox`/`right`/`up`; new group `commanded_control` |
| `library/TrafficSpec/Core/Vocab.lean` | new predicates; §5 and §7 doc fixes | `isMapScenery`; `extentsMilli`, `hasExtent`, `surfaceGapAtLeastCentimetres`, `surfaceGapAtMostCentimetres`; `landmarkIsDynamic`, `landmarkOrientation`, `landmarkFacesLane`, `landmarkOrientedFor`, `landmarkOfTypeOrientedFor`; doc fixes in §4b, §5, §7. No existing predicate's semantics changed. |
| `library/TrafficSpec/Core/Builders.lean`, `Scene.lean` | docs only | `mkEgo` type caveat, `mkLandmark` note on the three `withAttr` fields, `EntityId` identity note |
| `library/TrafficSpec/Tests/CoreArith.lean` | kernel guards | 30 `#guard`s: orientation vs lane-id sign (both signs, unset), oriented governance narrows the plain form, scenery flag, surface-gap bounds bracket a known gap and are false without extents |
| `traffic-spec-agent/perception/portability.json` | classes for new keys | done |
| `gaps/ledger.jsonl` | — | **not edited**: retiring a gap is the operator's decision. G16 (body geometry, owner `adapter`) is now retirable; G3/G20/G23 unchanged. |
| `library/TrafficSpecEval/{Captured,Bench}.lean` | — | **not regenerated**: they carry the old name-keyed identity and no new attributes. Re-run `carla/adapter.py` (or `run_spec monitor`) before the next evaluation. |

Verification: `lake build` succeeds (Core, rules, witnesses, `Tests/CoreArith`); `run_spec doctor`
28/28 (60 attribute keys, each with one portability class; 65 generator keys partitioned 49 + 16;
schema delivery 140 entries all rendered); a 464-frame capture converted with the new adapter
type-checks under `lake env lean` in 24 s; `run_spec verify` result is reported in the session summary.

Observed while testing, not changed: `lav/run1/RouteScenario_18` displaces the ego ~9.8× faster per
frame than the declared rate implies — that capture is not sampled at the library's rate, and the
adapter's contradiction report already says so. The `library/` directory is a git submodule; the Lean
edits live in its working tree.

---

## 3. Mapping tables

Status vocabulary (same as `perception/portability.json::origins` and the gap ledger's `owner`):
**lifted** (a rule can read it today) · **vocab** (data lifted, predicate missing) ·
**in_rsv_not_lifted** · **in_base_not_rsv** (waypoint attribute the abstraction folds away) ·
**in_api_not_graph** (CARLA has it, `carla_sgg` never records it) · **absent** (the simulator has
no form of it) · **judgement** (a standard such as "reasonable and prudent" that no data model
decides; needs a reading-level quantification, not a data change).

### 3a. BC MVA Part 3 (ss.119–214): what each driving obligation needs, and where it stops

Pipeline warning list. A section is **not formalizable in CARLA at all** only where the decisive
element is `absent`; a `judgement` element needs a reading (like the readings file already does for
"in a municipality"); everything else is a gap with an owner. Sections that impose no driving
conduct (119 definitions, 120, 124/124.2 municipal powers, 135–139, 142, 146.1/146.2, 148–148.2,
184, 188, 191(1), 192, 194(1)–(9), 195, 201, 204, 206, 207(2), 208–214) are omitted.

| s. | Obligation (driver's) | Decisive elements → status | Formalizable in CARLA? |
|---|---|---|---|
| 121 | due regard for safety (works vehicles) | judgement; works site: absent | no (judgement) |
| 122 | emergency-vehicle privileges | ego is an emergency vehicle: ego blueprint **in_api_not_graph** (A3); ego beacon lit: **in_api_not_graph** (ego `light_*`, G23) | only with generator update |
| 123 | obey peace officer | officer / hand direction: **absent** | **no** |
| 125 | obey applicable traffic control device | lights, stop signs, speed signs, landmarks: lifted; painted lines: in_base_not_rsv | partly |
| 125.1 | inoperative signal: stop before entering; yield to vehicle on right / already entering | `light_state ∈ {Off, Unknown}`: lifted; stop position: in_api_not_graph (`get_stop_waypoints`, G2); other vehicle stopped: in_api_not_graph (non-ego velocity, G3); "on the right": lifted (`toRightOf`, ego frame) / vocab (G21) | with residues |
| 127 | green: yield to pedestrians in intersection/adjacent crosswalk and to vehicles lawfully in intersection | signal + governance: lifted; pedestrians in junction: lifted; crosswalk region: in_api_not_graph (`Map.get_crosswalks`, G1); "lawfully": judgement | partly |
| 128 | yellow: stop before crosswalk / intersection unless unsafe | `Yellow`: lifted; crosswalk and stop line: in_api_not_graph (G1, G2); "cannot stop in safety": judgement over ego dynamics (lifted) | with residues |
| 129(1),(5) | red: stop before crosswalk / intersection / signal; do not proceed until permitted | as 128; signal position: lifted (`pos_*` of the head) | with residues |
| 129(2) | bus may proceed on red with white indicator | indicator: **absent** | **no** |
| 129(3),(4)(b) | right / left turn on red after stopping, yielding | stopped: lifted (ego); turn made: vocab/core (G12 heading over time; `yaw_rate`); one-way street: vocab (G18, `opposes`); "closely as practicable to crosswalk": in_api_not_graph | with residues |
| 130 | green / yellow **arrow** | arrow states: **absent** (`TrafficLightState` has only Red/Yellow/Green/Off/Unknown) | **no** |
| 131 | flashing red / yellow / green | flashing mode: **absent** (no flashing state; a light that alternates per frame would read as state changes) | **no** |
| 132–133 | pedestrian signals | pedestrian signal heads: **absent** | **no** (pedestrian duties anyway) |
| 134 | lane direction control signals | per-lane overhead signals: **absent** | **no** |
| 140 | obey speed / manner signs at works | works signage semantics: absent; a posted limit landmark: lifted | speed part only |
| 141, 141.1 | obey flagger / traffic control person | human signals: **absent** | **no** |
| 143 | newly painted lines | absent | **no** |
| 144(1)(c), 144.1 | speed excessive for conditions; precautions for vulnerable users | conditions: weather in_api_not_graph (manifest carries it, G6); visibility: in_api_not_graph (`fog_*`); rest: judgement | judgement |
| 145 | not so slow as to impede traffic | ego speed: lifted; "normal movement of traffic": in_api_not_graph (non-ego speeds, G3) | with G3 |
| 146(1) | 50 km/h in municipality, 80 outside | municipal boundary: **absent** (read as assumption, as `bc_mva_part3.jsonl` does); ego speed: lifted | yes, with a reading |
| 146(3),(5),(7) | obey posted limit | landmark 274 / `posted_limit_kph`: lifted; which carriageway: lifted (**new** `landmark_orientation`) | **yes** |
| 146(8),(11) | 20 km/h on a lane ≤ 8 m wide | lane width: in_base_not_rsv; "lane" (alley) class: absent | no |
| 147 | 30 km/h school / playground zones, by time | zone signs: lifted if the map authors the code; time of day: in_api_not_graph (`sun_altitude_angle`); school day: **absent** | partly |
| 148(1) | more than 40 over the limit | as 146 | yes where 146 is |
| 149 | stop for school bus with signals | school bus, alternating lamps: **absent** | **no** |
| 150(1) | keep to right half of roadway | lane side of own travel direction: lifted (`inRightmostLane`, `laneBesideSameDirection`); roadway width / centre line: in_base_not_rsv; one-way exception: vocab (G18) | with residues |
| 150(2) | slow vehicle keeps right lane | as above + "less than normal speed of traffic": in_api_not_graph (G3) | with G3 |
| 150(3) | keep right of rotary island | island geometry: absent as a graph concept | no |
| 151(a),(b) | change lanes only across broken line / never across solid | markings: in_base_not_rsv; coarse permission: lifted (`laneChange`, A7) | coarse only |
| 151(c) | signal before lane change | ego blinker: in_api_not_graph (G23); non-ego: lifted | ego no |
| 151(d),(e) | approach in correct lane for the turn | lane position: lifted; turn intent: G23 / G12 | with residues |
| 151(f) | do not pass into opposing lane | `opposes`, `opposingLanes`: lifted | yes |
| 151(g) | slow-traffic lane sign | absent | no |
| 151.1 | leave leftmost lane on approach of another vehicle (≥80 km/h roads) | posted limit: lifted; lane ordinal: vocab (G17, rejected as cost); vehicle behind in same lane: lifted (`following`, ego as one end); "actual speed of traffic ≥ 50": in_api_not_graph (G3) | with residues |
| 152–153.2 | HOV / bus / designated-use lanes | lane designation: **absent** in shipped maps (and lane type is in_base_not_rsv anyway) | **no** |
| 154 | keep right when meeting; leave half the travelled portion on a narrow road | oncoming: lifted; lateral offset within lane / road width: in_base_not_rsv | partly |
| 155 | solid / double line rules | markings: in_base_not_rsv | no (abstraction) |
| 156 | entering/leaving highway suspends 151, 155 | driveways: map dependent; judgement | — |
| 157(1) | pass on left at safe distance; return only when clear | positions and extents: lifted (**new** surface gap); "safe": judgement | yes with a quantified reading |
| 157(2) | overtaken driver: give way on audible signal, do not accelerate | horn: **absent**; other's speed: G3; ego as the overtaken: lifted | horn part no |
| 157.1 | pass pedestrian / cyclist with ≥ 1 m | pedestrian, bicycle positions: lifted; **surface** clearance: lifted where the capture carries `threedbbox` (**new**), else centre-to-centre residue | **yes** on new captures |
| 158 | passing on right only where permitted | one-way: vocab (G18); unobstructed lane: lifted; overtaken vehicle signalling left: lifted (non-ego blinker); off roadway: lifted | with residues |
| 159, 160 | pass on left only when safe / clear view | sight distance: in_api_not_graph (`World.cast_ray`); oncoming within range: lifted (render 50 m) | judgement |
| 161 | obey direction / prohibited-movement signs | landmark code: lifted if authored; movement made: G12 | partly |
| 162(1) | following too closely (reasonable and prudent) | gap: lifted; time gap: vocab (G19); judgement | with reading |
| 162(2) | commercial vehicles 60 m apart outside business district | truck class: lifted; commercial: blueprint (partial); business district: **absent**; 60 m exceeds the 50 m render distance (capture setting) | no as written |
| 163 | divided highway: no crossing median, no left roadway | median / barrier: in_base_not_rsv (`LaneType.Median`) or in_api_not_graph (`GuardRail`, `Static` boxes); G15/G18 | no today |
| 164 | controlled-access entry/exit only at signed points | designation: **absent**; ramps: in_base_not_rsv (`OnRamp`/`OffRamp`) | no |
| 165 | turning position at intersections | lane position: lifted; centre line: in_base_not_rsv; turn: G12; curb offset: in_base_not_rsv | with residues |
| 166, 167 | turns other than at intersections | as 165; driveway as a place: map dependent | with residues |
| 168 | U-turn restrictions | interference with traffic: lifted; on a curve: in_base_not_rsv (G4); crest / 150 m sight: `pos_z` lifted for actors, lane z in_base_not_rsv, sight in_api_not_graph; U-turn sign: landmark if authored; signalised intersection: lifted; business district: absent | partly |
| 169 | signal before moving off | ego signal: in_api_not_graph (G23); non-ego: lifted | ego no |
| 169.1 | yield to transit bus signalling out | bus blinker: lifted; yield-to-bus device: **absent**; limit ≤ 60: lifted | partly |
| 170 | signal turns continuously; signal before stopping / slowing | ego blinkers and brake lamp: in_api_not_graph (G23); non-ego: lifted | ego no |
| 171, 172 | hand-and-arm signals | **absent** | no (lamps: as 170) |
| 173(1) | uncontrolled intersection: yield to vehicle on right arriving at same time | arrival: `junctionBoundary` (capture setting, G22) or position; "on the right": lifted (ego frame) / vocab (G21) | with residues |
| 173(2) | facing a yield sign: yield to all | **yield sign actors are dropped by the generator** (`actors.py::get_base_type` has no `traffic.yield` → `None` → node skipped); OpenDRIVE landmark type 205 survives if the map authors it | generator update (§3b) |
| 174 | left turn: yield to oncoming in / near intersection | `oncoming`, `opposingLanes`, junction membership: lifted; left-turn intent: G23/G12 | with residues |
| 175 | after stopping at a through-highway stop sign, yield to immediate hazards | stop sign governance and ego stop: lifted; "immediate hazard": other's speed G3, distance lifted | with G3 residue |
| 176 | emerging from alley / driveway: stop before sidewalk, yield | sidewalk region: in_api_not_graph (`Map.get_waypoint(lane_type=Sidewalk)`), G15; business district: absent | no today |
| 177 | on approach of emergency vehicle with siren and flashing red: pull to nearest edge, clear of intersection, stop | beacon: lifted (`beaconOn`); emergency class: lifted; **siren: absent** (G11); clear of intersection: lifted; stopped: lifted (ego); "as close as possible to the edge": lateral offset in_base_not_rsv, rightmost lane lifted | yes, siren residue |
| 179(1) | yield to pedestrian in a crosswalk | crosswalk: in_api_not_graph (G1); pedestrian: lifted; "half of the highway": `opposes` lifted | no without G1 |
| 179(3) | do not overtake a vehicle stopped for a pedestrian | other vehicle stopped: in_api_not_graph (G3); brake lamp proxy: lifted; crosswalk: G1 | no today |
| 181 | due care; horn when necessary; child / confused person | horn: **absent**; child: in_api_not_graph (`walker` blueprint `age` attribute); rest: judgement | judgement |
| 183(2)(c),(d) | cyclist keeps right; not abreast | bicycle positions: lifted, exact separation between two non-ego actors: lifted (`pos_*`) | yes (cyclist as subject: non-ego, no dynamics) |
| 183(6) | cycle lights at night | night: in_api_not_graph (`sun_altitude_angle`); bicycle lamps: lifted booleans (rarely actuated) | partly |
| 183(17) | cyclist hand signals | **absent** | no |
| 185 | railway crossings | crossings, gates, trains: **absent** from shipped maps | **no** |
| 186 | stop at stop line / before crosswalk / before entering intersection | stop sign governance and stop: lifted; stop line and crosswalk: in_api_not_graph (G2, G1); junction entry position: G22 | with residues |
| 187 | no stopping on roadway outside business district when off-roadway practicable | ego stopped: lifted; off-roadway practicability: in_base_not_rsv (`Shoulder`); business district: absent | no today |
| 189(1)(a),(e),(f) | no stopping on sidewalk / crosswalk / within 6 m of crosswalk | surface type: G15; crosswalk: G1 | no today |
| 189(1)(c) | no stopping in an intersection | `inAnyJunction ∧ stopped`: lifted | **yes** |
| 189(1)(d),(i),(m) | hydrant 5 m; railway 15 m; bridge / tunnel | hydrant / bridge boxes: in_api_not_graph (`CityObjectLabel.Static`/`Bridge`); railway: absent | no |
| 189(1)(g) | no stopping within 6 m on the approach to a stop sign / signal | sign head position and ego position and heading: lifted (`withinMetresExact`, `fwd_*`) | **yes** |
| 189(1)(l) | no double parking | the other vehicle's standing: parked scenery lifted (**new** `map_scenery`); a stopped actor: G3 | partly |
| 189(1)(n) | parking prohibited by sign | landmark code: lifted if authored | partly |
| 190 | park on the right, parallel, within 30 cm of curb | curb line / lane width: in_base_not_rsv; heading vs lane: G20 | no today |
| 191(2)(b) | wheels to curb on a grade | grade: `pos_z` over time (G12) or in_base_not_rsv; wheel angle: `steer` lifted | partly |
| 193 | no backing into intersection / over crosswalk; back only when safe | `inReverseGear`, `movingBackward`, junction: lifted; crosswalk: G1 | yes except crosswalk |
| 194(10) | no more than two motorcycles abreast | motorcycle positions and `sameLane`: lifted | **yes** |
| 196 | canyons: keep right, horn on blind curves | horn: absent; canyon: absent; curve: G4 | no |
| 197 | no coasting in neutral down grade | `gear` = 0: lifted (ego); grade: `pos_z` over time (G12) | with G12 |
| 198 | not within 150 m of fire apparatus | firetruck: lifted (`truck` + `emergency`); 150 m exceeds render distance 50 m (capture setting) | no with default capture settings |
| 199 | fire hose | absent | no |
| 200 | no driving on sidewalk / boulevard | coarse `offRoadway`: lifted; sidewalk specifically: G15 | coarse only |
| 203 | door opening into traffic | door state: in_api_not_graph (`Vehicle.open_door`, door state in CARLA ≥ 0.9.13); who opens: absent | no today |
| 207(3) | warning devices when disabled | placement semantics: absent | no |

Summary for the warning: clauses whose decisive element is **absent from CARLA in any form** —
123, 129(2), 130, 131, 132–134, 141, 141.1, 143, 149, 152–153.2, 157(2) horn part, 164, 171–172,
183(17), 185, 189(1)(i), 196 horn, 199, 207(3), and every "business/residence district", "municipality"
and "school day" predicate — cannot be formalized by this pipeline and must be recorded `unsupported`
(or carried as a stated reading assumption where the readings file already does so). Everything
else in the table is a gap with an owner.

### 3b. CARLA exposes it, `carla_sgg` never records it — generator update list

Ordered by how many rows of §3a it unblocks. None of these is recoverable from captures on disk;
each needs a collector at capture time (or a generator change, which is frozen here).

| CARLA API | Generator today | Unblocks | Note |
|---|---|---|---|
| `Actor.get_velocity()` / `get_acceleration()` on **every** actor | `copy_carla_actor_state` for the ego only (`sgg.py:563`) | 125.1, 145, 150(2), 151.1, 157(2), 175, 179(3), 189(1)(l) — every "other vehicle is stopped / faster / approaching" (gap G3) | largest single win |
| `Vehicle.get_light_state()` on the **ego** | ego appended to `exclude_ids` unconditionally (`:543-544`), so never in the lamp loop (`:683-689`) | 151(c), 169, 170, 122 — every signalled manoeuvre by the subject vehicle (G23) | also the most portable channel to video |
| `Actor.type_id` / `attributes` for the ego | ego node has `sem_class = "ego"` and no `carla_type_id` (`:560`) | 122, 162(2), 185(4), 194 — any clause conditioned on the subject's vehicle class (A3) | one attribute |
| `TrafficLight.get_stop_waypoints()` | never called; `controls` uses `get_affected_lane_waypoints` (`:628`) | 128, 129, 186 stop-line position (G2) | as its own edge or a positioned node |
| `Map.get_crosswalks()` | never called | 127–129, 179, 186, 189(1)(e),(f), 193 (G1) | polygons; needs a region node an actor can be `isIn` |
| `traffic.yield` sign actors | `actors.py::get_base_type` returns `None` for the blueprint → dropped with a printed warning (`:41-45`); CARLA's reference lists yields among the implemented `TrafficSign`s | 173(2) | one `base_type_map` entry plus a `yield_sign` base class; Core `EntityType` would follow |
| Waypoint `lane_type` beyond Driving, `lane_width`, both `lane_marking_*`, `angle`/`curve` | on the base graph (`sgg.py:203-218`, `:314-344`), folded away by `process_to_junction_rsv` | 150, 151(a),(b), 154, 155, 163, 165–168, 176, 187, 189(1)(a), 190, 200 (G4, G15, G20) | needs a different abstraction or a side collector; the generator is byte-frozen |
| `World.get_weather()` (`precipitation`, `wetness`, `fog_*`, `sun_altitude_angle`) | not recorded; the capture scripts write it into `simulation.json` | 144(1)(c), 147, 183(6), 207 darkness (G6) | a manifest read, not a re-record, for captures made by those scripts |
| `Vehicle.get_speed_limit()` | not recorded | 146(3) cross-check: CARLA's own view of the limit governing the ego | cheap sanity channel |
| `World.get_traffic_light_from_opendrive_id`, `TrafficLight.get_opendrive_id`, `get_group_traffic_lights`, `get_elapsed_time` | not recorded | pairs a `trafficLight` actor with its landmark (`landmark_is_dynamic`); signal grouping; time in state (yellow-duration readings) | — |
| `World.get_environment_objects(TrafficSigns / Poles / RoadLines / Static / Dynamic)` | the ingestion loop exists with every entry commented out (`sgg.py:472-497`) | 140, 189(1)(d),(m), 207(3); painted lines as geometry for 151/155 | enabling it changes the census |
| `Walker` blueprint `age` attribute; `Walker.get_velocity()` | not recorded (only traffic lights get `carla_attr`, `:612`) | 181(c), 179 (pedestrian moving / crossing) | — |
| `Vehicle.open_door` / door state | not recorded | 203 | CARLA ≥ 0.9.13 |
| **Generator defect, not an omission:** `forward` on light-box traffic-light nodes is `location + unit` (`:595-600`) | — | repaired in the adapter (A2); fix at source when the generator is next edited | — |

### 3c. CARLA / the graph has it, real ego video cannot — flag before a rerun on video

From `perception/portability.json` (now covering all 60 lifted keys) plus this audit. These are the
elements a CARLA-validated rule may lean on that a monocular ego camera does not provide.

| Element | Class | Why it will not survive | Rules most exposed |
|---|---|---|---|
| Stable identity (`carla_id`, `landmark_id`, `entity_id`, `map_scenery`) | sim_only | a tracker drops and re-acquires ids under occlusion and swaps them between neighbours; the pipeline's whole binder architecture rests on one id per trace | every rule with a non-ego binder; now correct in simulation (A1), which makes the transfer gap sharper, not smaller |
| Occlusion (`check_occlusion=False`) | inversion | the graph contains actors behind buildings; video contains only what is visible — a rule validated in CARLA may fire on a hidden vehicle and be silent on video while both look right | 157, 162, 173–175, 177, 179 |
| Field of view (`render_dist` in all directions; rear sectors) | sim_only | `atDRearOf`, `atSRearOf`, following-vehicle antecedents need rear coverage | 151.1, 157(2), 179(3) |
| Governance edges `controls`, `mayAffect`; `landmark_orientation`, `landmark_lane_validities` | needs a map / estimator | "this signal governs this lane" is a map fact; video must estimate it | 125–129, 146(3), 186 |
| OpenDRIVE identities `road_id`, `lane_id`, `junction_id`; `isIn`, `opposes`, `travelsTo`, `laneChange` | sim_only | lane detection recovers geometry, never identity or connectivity | every lane and junction predicate |
| Control channels `throttle`, `brake`, `steer`, `gear`, `hand_brake`, `reverse`, `at_traffic_light`, `special_class` | sim_only | inputs and blueprint metadata; video sees only effects (brake lamp, livery) | 129(3), 193, 197, 122 |
| Metric position, heading, velocity, acceleration; body extents (`half_*`) | both_with_error | monocular depth and 3-D box error grow with range; a threshold near a metre is at the noise floor; the surface-gap bounds inherit the box error twice | 157.1, 162, 189(1)(g), 198 |
| Classification `base_class`, `sem_class` | both_with_error | detector confusion and recall; a rule over cyclists inherits cyclist recall | 157.1, 183 |
| Time base (fixed rate, no timestamps) | both_with_error | video frames carry variable presentation timestamps; a frame count is a different duration on each source | every `secondsToFrames` window |
| `light_state`, vehicle lamp booleans | portable | designed to be seen; failure is a miss, not a wrong value | 127–129 antecedent, 158, 169.1, 177 |

---

## 4. Operator decisions this audit leaves open

1. **Regenerate** `library/TrafficSpecEval/Captured.lean` and `Bench.lean`, and any labels derived on
   the old identity, before the next `run_spec monitor`; verdicts over non-ego binders on the old
   files are over spliced entities.
2. **Gap ledger**: G16 (body geometry, owner `adapter`) is retirable against `half_*` and the two
   `surfaceGap*` predicates; consider filing the yield-sign drop (§3b) at owner `generator`.
3. **Census**: `check_spec.CAPTURE_ENTITY_CENSUS` was sized on name-keyed entities; physical-entity
   counts are higher (266 vs 207 on one route window). The budget is reported, not enforced, so
   nothing breaks, but re-measure before tightening it.
4. **Capture rate** of `lav/run1/*` disagrees with the declared rate by a factor near ten; decide
   whether those routes are usable at all under the frozen `captureHz`.
5. **Generator update list** (§3b) is the request to make of `carla_sgg`'s owners; the two cheapest
   and highest-yield items are non-ego velocity and the ego's own lamp state.
