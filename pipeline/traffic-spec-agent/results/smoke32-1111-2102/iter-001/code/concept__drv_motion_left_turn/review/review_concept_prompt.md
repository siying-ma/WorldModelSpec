# Concept reviewer — does the body compute what the contract says?

## Role

You review one derived concept after it has passed the gate. The contract is the concept's
meaning: a notion of road users or of the scene, stated in words, with parameters a caller sets.
The body is the formula that computes it. You ask in what situation the body decides differently
from the contract: it holds where the contract's words say the notion does not, it fails where
they say the notion does, or it returns no value where every atom it reads is observed and the
contract decides. For every such situation you write a trace and an instance, and the harness runs
the body on it. A difference you can show on a trace is a defect; one you can only describe is an
advisory. You do not edit the concept and you do not propose another.

## Inputs (injected below)

- **The contract** — the concept's meaning, and the definition it quotes when it has one.
- **The record** — the formals (`track`, `region`, `literal` with its admissible spellings, `nat`), the
  parameters with their units and meanings, which words of the contract map to which atoms, and
  the readings the coder chose (`narrowings_by_the_coder`).
- **The rendering** — the body as prose, generated mechanically from the code. This, and not any
  narrative, is what the body computes.
- **The atoms the concept reads** — every atom the body reads, with where a trace writes it.
- **The contracts** — what every atom, primitive and concept the body names denotes.
- **The trace format** — how a situation is written as a trace the harness can run.
- **Challenges to carry over** (when there are any) — challenges upheld against an earlier body of
  this concept that cannot be run on this one as recorded, each with its record and what does not
  correspond.

### Contract

`drv.motion.left_turn`: Road user a makes a left turn: within the window behind the observation its heading turns to the left by an angle within the turn band, from the lower bound, below which a heading change counts as no turn, up to the upper bound, above which the road user's direction counts as reversed. Measured as the signed heading change over the window (prim.heading_change, degrees, left positive) at or above the lower bound and at or below the upper bound. The act is recognized at the observation at which the heading change over the window first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the heading change over the window lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for the turn indicator or for a declared intention to turn.


### Record

```json
{
 "concept_id": "drv.motion.left_turn",
 "kind": "formula",
 "contract": "Road user a makes a left turn: within the window behind the observation its heading turns to the left by an angle within the turn band, from the lower bound, below which a heading change counts as no turn, up to the upper bound, above which the road user's direction counts as reversed. Measured as the signed heading change over the window (prim.heading_change, degrees, left positive) at or above the lower bound and at or below the upper bound. The act is recognized at the observation at which the heading change over the window first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the heading change over the window lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for the turn indicator or for a declared intention to turn.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "window",
   "unit": "s",
   "meaning": "the window behind the observation within which the turn is completed"
  },
  {
   "name": "min_angle",
   "unit": "deg",
   "meaning": "the leftward heading change below which a change counts as no turn"
  },
  {
   "name": "max_angle",
   "unit": "deg",
   "meaning": "the leftward heading change above which the direction counts as reversed"
  }
 ],
 "act": {
  "boundary": "window",
  "window": "window",
  "onset": "Its observed beginning lies within the window behind that observation.",
  "recognition": "The act is recognized at the observation at which the heading change over the window first reaches the lower bound.",
  "extent": "The concept holds at every observation at which the heading change over the window lies within the band, and ends where it leaves the band.",
  "history": "It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing."
 },
 "elements": [
  {
   "span": "the signed heading change over the window (prim.heading_change, degrees, left positive)",
   "atoms": [
    "prim.heading_change"
   ],
   "concepts": [],
   "justification": "prim.heading_change: 'the signed heading change (degrees, left positive) of a road user over the window behind the observation'; it reads the body's heading, not the turn indicator."
  }
 ],
 "residues": [],
 "literals": [],
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `a` (a track).
Parameters (bounds the caller sets): `window` in s, `min_angle` in deg, `max_angle` in deg.
It holds at an observation exactly when:
(
  the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is at least `min_angle` (a parameter the caller sets)
  AND
  the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is at most `max_angle` (a parameter the caller sets)
)


### The atoms this concept reads

Every atom the concept reads, including those its concepts and primitives read, and where a trace writes it. A trace that leaves one out where the concept reads it leaves the concept unknown there.

- `kin_yaw_rate` — in the trace: `users[].kin.yaw_rate`


| id | contract |
|---|---|
| `drv.motion.at_rest` | A road user is at rest at an observation: the observable form of a stop where one is required, "complete cessation from movement". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations. |
| `drv.motion.backing` | A road user is backing at an observation: it moves in the direction opposite to the one its body points. Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none. Not a stand-in for the gear selected: a vehicle in reverse gear that stands still or rolls forward is not backing, and one in a forward gear that rolls backwards is. |
| `drv.motion.stopping_distance` | The distance road user a would travel before coming to rest if it began to brake after a reaction time, at the observation: its speed (kin.speed, m/s) times the reaction time, plus the square of its speed divided by twice the deceleration (m). Computed from the current speed only, under a constant deceleration on a level road. Not a stand-in for a sight distance or a gap to another road user, which a caller compares it with, nor for a braking manoeuvre actually made. |
| `drv.motion.turning_left` | Road user a is turning to the left at an observation: it moves and its heading turns to the left. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or above the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the left. Not a stand-in for the turn indicator or for a declared intention to turn. |
| `drv.position.behind` | Road user a is behind road user b at an observation: their headings are aligned and b's body lies wholly ahead of a's along a's heading. Measured as headings aligned (rel.same_direction with the alignment tolerance, the cosine of the largest angle between the headings counted as aligned), the bearing of b from a (rel.bearing) pointing forward in a's frame, and the two footprints' projections on a's heading sharing no length (rel.longitudinal_overlap below zero). Either road user may be at rest. Not a stand-in for following in the same lane: b may travel in another lane. |
| `drv.position.near_region` | Road user a is at region r at an observation: r lies within the reach of a's body, the distance within which a region counts as the place the road user is at. Measured as the ground distance from a's body outline to r (st.region_geometry, m; zero when they overlap) at or below the reach. Not a stand-in for occupancy: a body within the reach may lie wholly outside the region. |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |
| `prim.heading_change` | the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing |


### Trace format

The keys below are generated from the decoder the harness runs your traces through, so every atom
can be written. They are the only keys a trace holds: Core never reads any other, so a trace that
holds one is refused, the key named. A trace is `{"scenes": [scene, ...]}` with `t` strictly increasing (milliseconds).
Every key is optional unless marked required, and a key left out is unobserved (an atom that reads
it is unknown), never false: write every key the rule and your case read. Numbers are in Core
units: metres, seconds, m/s, m/s², degrees and degrees per second.

Frame. Every position, heading, velocity, lane direction and boundary is in one world frame, +x
east and +y north, angles counter-clockwise. Left of a heading is its counter-clockwise side: a
lateral offset, a bearing's lateral component and a side are positive to the left. A yaw rate is
positive when the heading turns to the left (counter-clockwise). A lane's ordinal 1 is its leftmost
lane, looking along the lane's direction.

Occupancy is decided only for the tracks `occupancy_observed` lists (`true` lists every user): for
them a pair in `occupies` is occupied and any other pair is not; for any other track every
occupancy is unknown, whatever `occupies` says. For an observed track you do not write `occupies`:
the harness derives it from the track's footprint and the structures' boundaries, as the check below
states, and replaces whatever the trace lists for it. Core computes the relations between users
from their kinematics: a relation it computes from the scene is never supplied in `relations`, and a
trace that supplies one fails the check; supply only one it cannot compute (`visible`, or a pair
whose geometry the scene leaves out). A look-back of length d needs scenes
reaching d before the observation judged, no two consecutive scenes more than d/2 apart; otherwise
the look-back is unknown.

The harness checks every trace you write before it runs anything on it, exactly and with no
tolerance; a trace that fails is returned to you with the messages. The check, as Core states it:

The admission check of a trace written by hand (a reviewer's counterexample), before any rule is
run on it. It reads the trace and, for the witness check, a grounding, a case's entities and one
timestamp: no law, rule, formula, contract or reading parameter. Every check is exact, in
rational arithmetic, with no tolerance: a written trace has no measurement noise, and its author
is shown these rules. Traces a source records are never held to it.

`checkTrace` requires:
- identity: track, region and device ids unique within a scene; at most one measured relation
  per ordered pair of tracks within a scene; every reference a scene makes (`Scene.references`)
  names an entity of that kind present in the same scene, a sight-along-way entry names a
  highway, and an `entrance_of` entry names a lane, a roadway, a shoulder or a bicycle lane or
  path, or a kind refining one (`StructureKind.entranceCarriers`); every track a link names
  appears in some scene;
- a static map: the same structures in every scene, each identical at every appearance; every
  device that does not move (`Device.mobile`) in every scene; a device identical at every
  appearance outside its state (`Device.staticPart`);
- one representation of direction and control: a designated direction (`lane.direction`) is
  carried only by a structure a vehicle travels in (`directionKinds`: a lane, reserved lane,
  turn lane, bicycle lane or path, roadway, one-way roadway or shoulder; a centre turn lane
  carries none), and is not the zero vector; each carrier stands on its own, and carriers that
  overlap or cross may carry different directions. A device whose control is observed governs
  only the travel regions whose traffic it controls, or an intersection, read as control of the
  junction itself (`governedKinds`); never a highway, a controlled-access region or a region no
  vehicle travels in. Only a lane, a roadway, a shoulder or a bicycle lane or path, or a kind
  refining one, carries the intersection it is an approach to (`lane.enters_intersection`); a
  roadway, one-way roadway, shoulder or bicycle lane or path that carries one is a directed
  approach segment entering that one intersection, which the check cannot see, and a whole
  two-way roadway or bicycle path carries none. Only a stop line or a crosswalk
  lists the carriers whose entrance it marks (`entrance_of`). A place no carrier covers has no
  designated direction, a device whose `governs` is not written has no observed control, and a
  line whose `entrance_of` is not written has no observed entrances; none is filled in;
- valid geometry: a boundary has at least three vertices, all distinct (the first is not
  repeated at the end), a non-zero area and no self-intersection; an extent's half-length and
  half-width are positive; a path length is not negative; a heading is not the zero vector; a
  supplied relation's `surface_gap` has no negative component (each is a distance between the
  bodies' nearest points, zero on contact or overlap);
- geometric occupancy: a track whose occupancy is observed has a position, a heading and an
  extent, and in a scene with such a track every structure has a valid boundary, because a
  pair absent from `occupies` is read as not occupied. The pairs of such a track are not
  written by hand: `completeOccupancy` derives them, the pair (track, structure) exactly when
  the track's footprint (`footprint`) and the structure's boundary overlap as closed sets
  (`Geom.polygonsOverlap`), so touching counts and a body on the line between two lanes
  occupies both;
- path length: between consecutive observations of a track's path length it never decreases,
  and its increase is at least the straight-line distance between the two positions;
- heading against yaw rate: where a track's heading is the same direction at two consecutive
  scenes (parallel and not opposed, whatever the vectors' lengths), the yaw rate integrated
  between them, ω (t₁ − t₀) with the later sample's rate held over the interval before it, is a
  whole number of turns (a multiple of 360°).
`checkReferences` is the identity part alone. A witness trace is held to the whole check, after
`completeOccupancy`, as a reviewer's trace is.
`checkWitness` requires that `at` is the timestamp of a scene, and that every grounded track and
every entity of the case, with its declared kind, is present in that scene.

Each message names the scene by its timestamp, the entity and the field.

- kin (user.kin): `position` [x, y], `heading` [x, y], `velocity` [x, y], `speed` number, `accel_longitudinal` number, `yaw_rate` number, `extent` [half_length, half_width, half_height], `steer_angle` number, `engine_running` bool, `parking_brake` bool, `gear` int, `throttle` number, `service_brake` number, `path_length` number.
- posture (user.posture): `on_seat` bool, `hands_on_controls` nat, `standing_on_deck` bool, `holding_another_vehicle` bool, `stunt` bool.
- warning lamp (sig.warning_lamps[]): `colour` a LampColour spelling (required), `mode` a LampMode spelling (required), `facing` a Facing spelling (required).
- sig (user.sig): `turn_indicator` a TurnIndicatorState spelling, `brake_lamp` bool, `hazard` bool, `headlamp` a HeadlampState spelling, `position_lamp` bool, `warning_lamps` [warning lamp, ...], `siren` bool, `horn` bool, `hand_signal` a HandSignal spelling, `doors_open` [a DoorSide spelling, ...], `compression_brake` bool.
- user (scene.users[]): `track` nat (required), `classes` [a RoadUserClass spelling, ...], `unobserved_classes` [a RoadUserClass spelling, ...], `emergency_kind` a EmergencyKind spelling, `official_kind` a OfficialKind spelling, `e_bike_class` nat, `occupants` nat, `posture` posture, `kin` kin, `sig` sig, `sight_along_way` [[nat, number], ...].
- lane (structure.lane): `direction` [x, y], `left` nat, `right` nat, `ordinal` nat, `count` nat, `leads_to` [nat, ...], `enters_intersection` nat, `marking_left` [marking type, marking colour], `marking_right` [marking type, marking colour], `width` number.
- structure (scene.structures[]): `id` nat (required), `kind` a StructureKind spelling other than an abstract kind (travel_region) (required), `unobserved_kinds` [a StructureKind spelling other than an abstract kind (travel_region), ...], `position` [x, y], `boundary` [[x, y], ...], `lane` lane, `paved` bool, `opening` bool, `marked` bool, `curvature` number, `grade` number, `sight_distance` number, `ways` [nat, ...], `entrance_of` [nat, ...], `reserved_class` a ReservedClass spelling, `turn_side` a TurnSide spelling, `parking_angle` number, `designation` a ParkingDesignation spelling, `curb_kind` a CurbZoneKind spelling, `curb_colour` a CurbColour spelling, `obstruction_kind` a ObstructionKind spelling.
- time window (conditions.windows[]): `weekdays` [nat, ...], `calendar_class` string, `start_minute` nat, `end_minute` nat.
- conditions (device.conditions): `windows` [time window, ...], `min_occupancy` nat, `duration_limit` number, `vehicle_class` a RoadUserClass spelling, `when_children_present` bool.
- device (scene.devices[]): `id` nat (required), `kind` a DeviceKind spelling (required), `unobserved_kinds` [a DeviceKind spelling, ...], `position` [x, y], `governs` [nat, ...], `indications` [a SignalIndication spelling, ...], `uncovered` bool, `inoperative` bool, `ped_state` a PedSignalState spelling, `countdown` bool, `lane_control` a LaneControlState spelling, `flashing` bool, `active` bool, `speed_value` number, `speed_kind` a SpeedSignKind spelling, `code` a SignCode spelling, `zone_kind` a ZoneKind spelling, `is_end` bool, `conditions` conditions, `rail_lights` a RailLights spelling, `gate` a GateState spelling, `bell` bool, `human_role` a HumanRole spelling, `human_indication` a HumanIndication spelling.
- civil time (env.civil_time): `year` nat (required), `month` nat (required), `day` nat (required), `weekday` nat (required), `minute_of_day` nat (required).
- env (scene.env): `darkness` bool, `precipitation` bool, `wet_road` bool, `ice_or_snow` bool, `visibility` number, `civil_time` civil time.
- relation (scene.relations[]): `a` nat (required), `b` nat (required), `centre_distance` number, `surface_gap` [number, number], `a_ahead_of_b` bool, `longitudinal_overlap` number, `oncoming` bool, `same_direction` bool, `bearing` [x, y], `contact` bool, `visible` bool.
- intent (scene.intents[]): `source` string (required), `vehicle` nat (required), `target` nat (required), `values` [[int.<name>, bool], ...] (required).
- scene: `users` [user, ...], `t` int (required), `subject` nat, `structures` [structure, ...], `devices` [device, ...], `occupies` [[nat, nat], ...], `relations` [relation, ...], `env` env, `assumptions` [[string, bool], ...], `intents` [intent, ...], `links` [[nat, nat], ...], `occupancy_observed` true | [track, ...].

Enumeration spellings (the values the decoder accepts):
- ArrowDir: left, right, straight, u_turn
- CurbColour: blue, gray, none, red, white, yellow
- CurbZoneKind: bus_stop, fire_lane, freight_loading, no_parking, no_stopping, passenger_loading, restricted_parking, taxicab_stand, tour_bus_loading
- DeviceKind: crossing_warning_signal, human_direction, lane_control_signal, pedestrian_signal, railway_signal_or_gate, regulatory_sign, speed_limit_beacon, speed_limit_sign, stop_sign, temporary_traffic_control, traffic_signal, yield_sign, zone_sign
- DoorSide: curb, traffic
- EmergencyKind: ambulance, fire, other, police
- Facing: front, rear, side
- GateState: down, lowering, none, raising, up
- HandSignal: left, no_signal, re_enter, right, stop_or_slow
- HeadlampState: high_beam, low_beam, off
- HumanIndication: proceed, slow, stop, turn(<ArrowDir>)
- HumanRole: flagger, police_officer, railroad_flagger, school_crossing_guard
- LampColour: amber, blue, red, white
- LampMode: flashing, rotating, steady
- LaneControlState: dark, green_down_arrow, red_x, yellow_arrow(<ArrowDir>), yellow_x
- MarkingColour: other, white, yellow
- MarkingType: broken, curb, dotted, double_solid, none, solid, solid_broken
- ObstructionKind: barrier, debris, excavation, hose, mail_drop_box, other, sidewalk_fixture, stalled_vehicle_wreckage
- OfficialKind: armored_car, coroner, highway_maintenance, incident_management, municipal, other, regulatory_agency, tow, utility
- ParkingDesignation: access_aisle, charging, disabled, disabled_side_lift, general, municipal
- PedSignalState: dark, dont_walk_flashing, dont_walk_steady, walk
- RailLights: dark, flashing
- ReservedClass: bus, heavy_vehicle, high_occupancy, other
- RoadUserClass: bicycle, bus, child, commercial_motor_vehicle, electric_bicycle, electric_scooter, emergency_vehicle, fire_apparatus, moped, motor_vehicle, motorcycle, official_vehicle, pedestrian, pedestrian_with_white_cane_or_guide_animal, rail_vehicle, school_bus, taxicab, tour_bus_or_limousine, trailer_or_combination, transit_bus, truck
- SignCode: abandoned_crossing, angle_parking, bicycles_prohibited, closed_to_traffic, do_not_enter, entrance, exempt_crossing, exit, keep_right, motor_vehicles_prohibited, no_left_turn, no_parking, no_right_turn, no_standing, no_stopping, no_straight, no_trucks, no_u_turn, nonmotorized_prohibited, one_way, pedestrians_prohibited, right_turn_only, shoulder_use_permitted, truck_route, wrong_way
- SignalIndication: circular_green, circular_red, circular_yellow, dark, flashing_red, flashing_yellow, flashing_yellow_arrow(<ArrowDir>), green_arrow(<ArrowDir>), red_arrow(<ArrowDir>), unknown, yellow_arrow(<ArrowDir>)
- SpeedSignKind: maximum, minimum, structure_maximum, zone
- StructureKind: alley, bicycle_lane_or_path, centre_line, centre_turn_lane, controlled_access, crest, crosswalk, curb_zone, driveway_or_alley_entrance, elevated_structure, fire_hydrant, fire_station_entrance, highway, intersection, lane, median_or_divider, obstruction, one_way_roadway, parking_space, pedestrian_grade_separation, railway_crossing, reserved_lane, road_edge, roadway, roundabout, safety_zone, shoulder, sidewalk, stop_line, transit_stop, travel_region, turn_lane
- TurnIndicatorState: left, off, right
- TurnSide: left, right
- ZoneKind: hazardous_place, heavy_vehicle_lane, high_occupancy_lane, narrow_highway, no_passing, parking_restricted, pedestrian_safety, school, school_crossing, speed_zone, temporary_traffic_control, trail




## Questions

1. **Holds too widely.** A situation in which the body holds but the contract's words exclude it:
   an entity the body accepts from anywhere in the scene where the contract names one related to
   the road user; a condition the contract states that the body drops; a value the body reaches
   only because something is absent or unobserved. The contract's verdict is `fails`.
2. **Holds too narrowly.** A situation the contract's words cover in which the body fails. The
   contract's verdict is `holds`.
3. **No value where the contract decides.** A situation in which every atom the body reads is
   observed, the contract decides, and the body is unknown.
4. **Off its domain.** What does the contract say where the thing it is about is absent — no region
   of the kind it reads, no other road user? If the body decides there where the contract does
   not, or decides the other way, that is a situation under question 1 or 2.

A concept of kind `quantity` returns a value, not a verdict. For it, a divergence is a situation in
which the contract's words put the value in an interval and the body's value falls outside it
(`value_wrongly`), or the body has no value where the contract gives one (`undecided`). It states
that interval as `contract_value`, `lo` and `hi`, each a value with its unit (equal for an exact
value), at the observation `at`, in place of `contract_verdict`.
5. Each trace is minimal and complete: the fewest road users, regions and observations that
   realize the situation, with every atom the body reads written in every scene. Name in `at` the
   timestamp of the scene at which the contract decides: the body is read at that observation, and
   the scenes before it are its history. Give the instance — a spelling for each literal formal, a
   natural number for each nat formal, a value with its unit for each parameter — and the track of
   each track formal, the contract's verdict at `at` (`holds` or `fails`), and the words of the
   contract that decide it, verbatim. A constant the record declares under `literals` is part
   of the body, never an input of the instance.
6. **Open magnitudes.** A situation whose verdict turns only on how large a parameter should be is
   an advisory: the caller sets it. So is one in which a parameter takes a value outside the domain
   its meaning states (a negative magnitude, a zero divisor): there the contract gives no value or
   verdict, so nothing diverges from it.
7. **Readings.** A reading the coder disclosed that chooses among meanings the contract's words
   allow is an advisory. A reading that changes what the contract denotes — narrows it to what the
   formula language could write, or widens it — is a divergence: show it on a trace.
8. **Generality.** If the contract or the body names a figure, a place, a class list, a device or a
   side that the notion does not need, so that it fits one use and no other, list it under
   `not_general` with the words, verbatim. No trace is needed.
9. Use the contracts for what an atom asserts. Do not use knowledge of any law or jurisdiction.
10. `accept` when you find no situation under questions 1 to 4 and nothing under question 8;
    `return` otherwise. Before you answer, run each divergence through `run_instance`, at most
    8 calls in all: it checks the trace and runs the body, as the instance names it,
    on it. A trace on which the body's verdict differs from the contract's confirms the divergence;
    one on which they agree is recorded as your advisory and returns nothing. Revise a divergence
    until it is `confirmed`, or drop it.
11. **Carried-over challenges.** For each challenge to carry over, submit a divergence with
    `extends` naming it that continues it: its trace keeps every scene and every field the recorded
    trace states (you may add scenes and fill fields it left unobserved); each recorded formal keeps
    its value, under its name or the one formal it became; the instant, the contract's words and the
    claimed verdict or interval are the recorded ones. A divergence that does not continue it is
    refused, and a challenge left without one keeps the review open.

## Output

The answer is the argument of `submit_review`, in this schema and nothing more:

```
{"verdict": "accept | return",
 "divergences": [{"kind": "holds_wrongly | fails_wrongly | undecided",
                  "situation": "<one or two sentences>",
                  "contract_words": "<verbatim words of the contract that decide it>",
                  "contract_verdict": "holds | fails",
                  "instance": {"literals": {"<literal formal>": "<spelling>"},
                               "nats": {"<nat formal>": <natural number>},
                               "params": {"<parameter>": [<value>, "<unit>"]}},
                  "grounding": {"<track formal>": <track id>},
                  "regions": {"<region formal>": <region id>},
                  "trace": {"scenes": [ ... ]},
                  "at": <timestamp of a scene, ms>,
                  "extends": "<the id of a challenge to carry over, only for such a divergence>"}],
 "not_general": [{"words": "<verbatim words of the contract or the rendering>", "why": "<one sentence>"}],
 "advisories": ["<observations that return nothing>"]}
```

For a concept of kind `quantity`, a divergence has the same keys, except that `kind` is
`value_wrongly | undecided` and `contract_verdict` is replaced by
`"contract_value": {"lo": [<value>, "<unit>"], "hi": [<value>, "<unit>"]}`.

## Finish

Submit with `submit_review`. The harness runs every divergence of the answer the same way: an
answer with a schema defect or a divergence that cannot be evaluated comes back with the messages,
at most 3 submissions in all, and the last one stands. Finish when a submission
is accepted.
