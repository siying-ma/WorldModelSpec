# Plan — batch 01 (iteration 1)

Eight law lines, ten nodes, nine concept records, no law-local aggregates (`aggregates.jsonl` is
empty), no gaps. Every node and concept passes the validator.

## Nodes

**LVMC_11_38_030 (sidewalk riding).** Subject: the admitted motorcycle aggregate together with
`ru.moped` and `ru.electric_scooter` for "motor scooter". No definition applies to "motor scooter",
so I mapped it by contract. A motor-driven scooter is a moped under DEF-NRS-484A-125 ("a
motor-driven scooter, motor-driven cycle or similar vehicle"), or an electric scooter (handlebars
and an electric motor). A larger one is already a motorcycle. "Ridden upon any sidewalk" means the
vehicle is in motion (`drv.motion.moving`) while it occupies a `st.sidewalk`. This is disclosed as
an agency reading, so a parked machine is compliant. "Of the City" is the assumption
`asm.within_city_limits`, following the table's resolution of "city" to DEF-NRS-484A-045 ("any
incorporated city"). *Reverse if:* a reviewer holds that electric scooters are not "motor
scooters" (drop `ru.electric_scooter`), or the operator posts an LVMC definition of "City" or
"motor scooter".

**LVMC_11_43_010_A (roundabout direction).** A vehicle in motion that occupies a `st.roundabout`
must not move clockwise about the roundabout's reference point. This uses a new concept,
`drv.motion.clockwise_about_region`. It is built on the cross product of the vehicle's offset from
the reference point with its velocity, and needs a tangential speed above the resolution. I used
geometry instead of `st.lane_direction` because counterclockwise is a geometric fact about the
island (DEF-LVMC-11-02-040). Radial motion on the right-hand approaches comes out counterclockwise
or zero, so entering and leaving comply. *Reverse if:* roundabout reference points in the maps are
not at the island centre (see operator note); then switch to the designated direction of the
circulatory carriers.

**NRS_484B_113_2 (backing).** The places are conditions and the forbidden act is
`drv.motion.backing` at the same observation. This is logically the same as "shall not back at P"
and keeps a single obligation span. The places:
- "into an intersection": the rise of `rel.occupies` on a `st.intersection`.
- "on or over a crosswalk": occupying a `st.crosswalk`.
- "around a street corner": yawing (`drv.motion.turning`) while occupying an intersection, with
  `asm.within_city_limits` for "street", since DEF-NRS-484A-265 restricts streets to highways
  inside a city.

Backing further inside an intersection already entered is not read as "into" (disclosed as a
narrowing). *Reverse if:* a label counts backing within an intersection as "into". Then
condition (a) becomes plain occupancy.

**NRS_484B_127_3 (caravan spacing).**
- **Applicability:** a moving motor vehicle on a highway, with two assumptions. "Outside of a
  business district" is a legal region class (`asm.outside_business_district`). "In a caravan or
  motorcade" is group membership, which the vocabulary cannot carry (`asm.caravan_or_motorcade`,
  declared per trace).
- **Residue:** "Whether or not towing" adds no restriction, so it is a residue with scope `none`.
- **Standard:** "Sufficient space … without danger" is operationalized as follows. The surface gap
  to every vehicle or combination ahead in the lane must be at least
  `p.caravan_entry_vehicle_length` plus `p.caravan_entry_time_headway` times speed, with the
  headway counted twice: ahead of and behind the entering vehicle. That gives a gap-acceptance
  bound that grows with speed.
- **Surrogate:** not marked. The standard bounds one concrete element (the gap), whose purpose the
  words state.

*Reverse if:* the reviewer rules that the standard is the whole duty (then mark it surrogate), or
the operator supplies a per-road-user caravan fact (then replace the per-trace assumption).

**NRS_484B_210_3 (passing on the right off the pavement).**
- **Condition:** being off the paved portion, meaning the vehicle occupies an unpaved `st.shoulder`
  or straddles a `st.road_edge` whose surface beyond is unpaved.
- **Obligation:** no other vehicle is being passed on the right (`drv.interaction.passing_on_right`:
  same direction, side by side, the other vehicle on the left, the subject gaining).
- **Reading:** "Requires" is read through the conduct actually performed. This is disclosed, as is
  the fact that a vehicle fully beyond an edge with no shoulder region mapped is not read.

*Reverse if:* labels judge a pass that only *would* have needed the shoulder.

**NRS_484B_223_4a (right-turn lane, purpose).** "Only for the purpose of making a right turn" is
rewritten as an exception carried by the declared intention `int.turn_right`. The target is the
intersection the lane enters (`st.lane_enters`). The rewrite is exact: driving in the lane is
allowed only where the vehicle intends a right turn there. "Single right lane" is read through
`st.lane_adjacency`: the rightmost lane, with no right-turn neighbour. *Reverse if:* sources cannot
declare intentions (the rule is then unknown wherever a vehicle is in the lane). The alternative
would be to read the purpose through the following turn, which needs an act search ahead.

**NRS_484B_223_4b (right-turn lane, no through travel).**
- **Act:** a new event-bounded concept, `drv.motion.straight_through_region`. It starts at entry
  into the intersection and is recognized at exit, when the `headingSince` change since entry is
  below `p.straight_through_max_heading_change`. It uses the catalogued step parameter.
- **Lane condition:** the act is forbidden where the vehicle occupied the single right-turn lane at
  some observation since entry, i.e. it came out of that lane.
- **Occasion:** the highway-design condition is read `at_recognition`. It is a static map
  condition, so this narrows nothing.

*Reverse if:* labels treat a vehicle that leaves the lane just before the stop line and goes
straight as violating.

**NRS_484B_227_1_o1 / _o2 / _o3 (divided highway).** Three obligations, in text order. A divided
highway is a `st.highway` with a `st.median_or_divider` on it.
- **o1 (right-hand roadway):** read as never pointing against the designated direction of a
  roadway or lane of that highway that the vehicle occupies (`drv.lane.facing_against_direction`).
  The exception words are `sibling` here, because a turn through an opening never points against
  the crossed roadway.
- **o2 (crossing the divider):** forbids occupying a divider region unless it carries the opening
  attribute or the vehicle is in an intersection.
- **o3 (turns):** forbids `drv.motion.left_turn` and `drv.motion.u_turn`. A "semicircular turn" is
  a heading reversal, so `u_turn` recognizes it. The U-turn concept is born from DEF-NRS-484B-077.
- **o3 occasion:** a window act. The trigger and both exceptions are read `some_moment`, i.e. at
  some turning observation of the recognition window ("through an opening", "at an intersection").
  The occasion scenario pairs are planned.
- **Shared "must not":** it is cut into o2's obligation span, and o3's justification states that
  it governs o3's list too.

*Reverse if:* the reviewer holds that the exception also qualifies o1 (then add the two exception
spans to o1), or labels count long turns that the fixed window misses.

## Concept records

All nine are general: none names a statute's word or a place. They are:
- `drv.motion.moving`, `drv.motion.backing` and `drv.motion.turning`: resolution tolerances only.
- `drv.motion.clockwise_about_region`
- `drv.interaction.passing_on_right`
- `drv.motion.straight_through_region`: event act.
- `drv.lane.facing_against_direction`
- `drv.motion.left_turn` and `drv.motion.u_turn`: window acts with angle bands, so that overshoot
  (a reversal for a left turn, a loop for a U-turn) is excluded.

## For the operator

- **Roundabout reference point.** `drv.motion.clockwise_about_region` treats the `st.region_geometry`
  reference point of a `st.roundabout` as the island centre. Adapters should place it there.
- **Map frame orientation.** The concept also assumes the world frame is the ontology's
  counterclockwise-positive frame (the frame in which `kin.yaw_rate` counts a left turn as
  positive). A left-handed simulator frame must be converted by the adapter, or every verdict flips.
- **Caravan assumption is per trace.** `asm.caravan_or_motorcade` declares that the vehicles
  travelling in line in one lane form a caravan. A trace that mixes caravan and ordinary traffic
  cannot be declared correctly; a per-road-user fact would need an ontology change.
- **Intentions on CARLA.** `int.turn_right` must be supplied by the source for NRS_484B_223_4a.
  Where the `carla_scene_graph` profile carries no planner intentions, that rule reports unknown.
- **Turn recognition window.** `p.turn_recognition_window` is proposed long enough for a three-point
  turn. On long sweeping ramps, a heading change of that size inside the window would be recognized
  as a turn; the values are awaiting review.
- **Capital-C "City".** "City" in LVMC 11.38.030 was resolved by the table to the NRS definition
  ("any incorporated city"). If an LVMC definition of "City" (the City of Las Vegas) is posted,
  the assumption's meaning should narrow.
