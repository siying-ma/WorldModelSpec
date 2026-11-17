# Plan — batch 09 (iteration 001)

There are nine nodes for eight law lines. There are no law-local aggregates, so `aggregates.jsonl` is empty. There are no new concept records. The plan reuses `drv.motion.complete_halt` and `drv.interaction.overtake_pass`, which an earlier batch proposed. The validator accepts every node. Two nodes carry gaps and will not be coded until those gaps are decided: `NRS_484B_117_1` and `NRS_484B_127_3`.

## NRS_484B_117_1 — driving on a sidewalk (carries gaps)

**What the node judges.** The subject is a vehicle (the aggregate `DEF-NRS-484A-320::vehicle`) that overlaps a sidewalk.
- **Violation:** at any observation where the vehicle is moving (not `drv.motion.complete_halt`) on the sidewalk without also overlapping a `st.driveway_or_alley_entrance`.
- **Two reading choices:**
  - "Drive" is read as not being at rest.
  - "Permanent or temporary" excludes nothing, because the entrance kind covers both.
- **Mapping difference:** this differs from LVMC_11_20_060_o1, which maps "driving onto a sidewalk" with `st.region_geometry`. These words name no distance, so occupancy alone carries them.

**Why it is blocked.** The subsection 2 exception cannot be carried by any atom:
- "powered solely by electricity and designed to travel on three wheels" → gap `ru.electric_three_wheeler`.
- The operator's role and duty ("officer … of a law enforcement agency", "security guard", "in the course of … official duties") → gap `ru.operator_role`.
- A role a person holds is never an assumption, and it is not one of the observable-reading categories.
- A vehicle class (`ru.emergency_vehicle`, `ru.official_vehicle`) is not the role of the person driving.

**Other spans.**
- The two "as that term is defined" spans are `definition` references, quoting DEF-NRS-239C-065 and DEF-NRS-648-016.
- The penalty sentence is `boilerplate`: it states a sanction, not conduct.
- "Except as otherwise provided in subsection 2" is a scope-`none` residue: subsection 2 is in this same line and its own spans carry it.

**Reversal signal:** the operator retires either gap with an atom, or rejects it with a reading that permits a class stand-in.

## NRS_484B_127_1 — following too closely (surrogate)

**Why it is a surrogate.** "Reasonable and prudent" is the whole duty, so any bound on it is a policy choice.

**The bound.** The longitudinal body gap to every vehicle ahead in the same lane must be at least:
- the subject's speed × a headway H, **plus**
- (subject speed² − leader speed²) / (2 × a deceleration D).

**How the factors are read.**
- The speeds of both vehicles enter the bound by degree.
- The surface condition picks H and D:
  - ice or snow (`env.ice_or_snow`) → the `_ice` pair;
  - otherwise a wet road or falling rain (`env.wet_road`, `env.precipitation`) → the `_wet` pair;
  - otherwise → the `_dry` pair.
- Narrowing: "the traffic upon the highway" is read only through the followed vehicle. The traffic aggregate is therefore not claimed, and the validator accepts this.

**Party-free case:** a vehicle with no one ahead → compliant.

**Reversal signal:** a labelled case where traffic density, rather than the leader's speed, decides the verdict.

## NRS_484B_127_2 — wide truck following a wide truck: leave 500 ft

**Who it binds and when.**
- The subject is a truck or a combination of vehicles (admitted aggregates) whose full width (`kin.extent`) is at least 80 in.
- It follows such a vehicle immediately ahead in its lane, with no road user between them.
- **Exemption:** if the subject's lane counts two or more lanes in its direction, the rule does not apply.

**What it requires.** One of these must hold, or the node reports a violation:
- the body gap is at least 500 ft; or
- conditions do not permit; or
- an overtaking pass by the subject (`drv.interaction.overtake_pass`) is recognized within the window ahead (`p.overtake_window`).

**How "whenever conditions permit" is read.** Conditions permit the space when, for the whole window `p.truck_space_open_time`:
- the leader has been the subject's immediate leader, and
- neither vehicle has been at rest.

The purpose clause ("so that an overtaking vehicle may enter …") is a disclosed narrowing on the obligation span: the duty is the stated space.

**Reversal signal:** a recording where a queue moving slowly at below the window's duration is labelled a violation.

## NRS_484B_127_3 — caravan spacing (carries a gap, surrogate)

**Why it is blocked.** I kept gap `smoke31-1111-0039:G17` (`ru.procession_member`) on "in a caravan or motorcade", because it is still pending. Following and same-direction relations cannot tell a procession from ordinary traffic.

**Everything else is planned.**
- "Outside of a business district" is the negation of `asm.business_district`.
- "Whether or not towing" is a scope-`none` residue.
- **Sufficient space** is at least: design-combination length + 2 × speed × headway.

**Reversal signal:** the operator decides G17.

## NRS_484B_153_2 — opening a door into traffic

**Who is judged.** The person is read through the vehicle's traffic-side door (`sig.door_open`, side traffic). This is an agency reading, and it is the same subject mapping LVMC_11_22_010 gives "A person". Boarding and alighting are read through that same open door.

**What counts as interference.** Some moving vehicle of the traffic either:
- touches the subject, or
- is alongside it with a lateral body gap within `p.door_swing_reach`.

A vehicle that brakes or swerves earlier to avoid the door is not read (disclosed narrowing).

**Party-free case:** a door open with no traffic → compliant.

## NRS_484B_153_3 — leaving a traffic-side door open

**The bound.** A violation is reported where the traffic-side door has been open at every observation of the window `p.traffic_side_door_max_open`.

**Disclosed narrowing.** Whether loading is going on, and whether it is passengers or cargo, is a purpose that cannot be observed. It is read as this one duration bound.

**Reversal signal:** labelled cargo deliveries longer than the bound that are judged compliant. That would call for a cargo-specific bound, which needs evidence of cargo handling that no atom carries.

## NRS_484B_203_1_o1 / _o2 — vehicles meeting from opposite directions

The line holds two obligations. Each node segments the whole line and marks the other's obligation as `sibling`.

**_o1 — keep to the right.**
- The subject is a moving vehicle.
- Every oncoming vehicle on the same highway that is alongside it must lie on its left (`rel.bearing`).

**_o2 — give half the road on narrow highways.**
- It applies on highways where the subject's lane counts at most one lane in its direction.
- While an oncoming vehicle is meeting the subject (closest approach within `p.meeting_horizon`, or alongside), the subject's body must stay right of the centre line, within `p.lateral_position_tolerance`.
- "As nearly as possible" is read through the room left to the right road edge.
- The paved portion is read as the roadway the centre line divides (narrowing).

**Reversal signal:** unmarked narrow roads, where `st.lane_adjacency` is absent, that are labelled decided. That would call for a lane-free width reading.

## NRS_484B_208_1 — leaving the left lane on controlled-access highways

**Where it applies.**
- The subject is a motor vehicle in the leftmost of two or more lanes on a controlled-access highway.
- It is not an authorized emergency vehicle showing warning lamps or a siren.
- The reading does not place it within a city or town (new assumption `asm.within_city_or_town_limits`). The existing `asm.within_city_limits` means only the one city whose ordinances the reading applies, so it does not fit "a city or town".

**When it is violated.** Call the following state S: the subject is in the leftmost lane, below the posted maximum (`dev.speed_limit_sign` governing where it is), and not excused by exceptions (a)(1)–(4), (b) or (c). A violation is reported when both hold:
- **Continued too long:** for the whole window `p.left_lane_move_over_time`, S has held continuously since a faster motor vehicle was behind the subject in its lane.
- **Still followed:** a motor vehicle is still behind it at the judged observation.

The validator rejected an added closing-horizon reading on "being overtaken", so the trigger is now read as its words say.

**How each exception is read.**
- **(a)(1) overtaking:** an overtake pass (`drv.interaction.overtake_pass`) recognized within the window ahead.
- **(a)(2) left turn:** the declared intention `int.left_turn` at an intersection.
- **(a)(3) high-occupancy lane:** the subject occupies a reserved high-occupancy lane, is a high-occupancy vehicle, and `prim.conditions_hold` for the governing high-occupancy-lane sign.
  - This is the requirement DEF-NRS-484A-460-2 says those signs advise.
  - Outside the posted hours, `prim.conditions_hold` is false, so the exception does not excuse.
- **(a)(4) highway work:** a highway-maintenance official vehicle with its amber warning lamp lit.
- **(b) traffic, weather, obstructions or hazards:** the left lane is necessary where any of these falls below the same stopping distance S_stop used in NRS_484B_127_1:
  - the body gap to a traffic member in the right neighbouring lane;
  - the distance to an obstruction on the subject's right;
  - the visibility distance.
- **(c) devices and officers:** the right neighbouring lane is closed by a lane-control signal, a sign, temporary traffic control, or a police officer's stop direction.

**Readings the validator required.** Purpose words may not be carried by a road-user class alone, so:
- (a)(4) is read through the amber warning lamp;
- (d) "official duties" is read through warning lamps or a siren.

Both are stricter than the words: an on-duty vehicle that shows neither is not excused.

**Reversal signals:**
- the operator accepts NRS-484B-323-1 into the build, which would let (a)(3) compose it as compliance;
- labelled on-duty emergency or maintenance vehicles without lamps that are judged excused.

## For the operator

- **NRS-484B-323-1 is not composable.** NRS-484B-208-1(a)(3) cites it, but it is neither accepted nor planned. I carried the requirement as the qualified fact (high-occupancy membership plus the posted lane conditions), not as a composition. If NRS-484B-323-1 is coded, replanning (a)(3) as a `compliance` composition would follow the bracket exactly.
- **New gap `ru.operator_role`** (on NRS-484B-117-1). Several laws exempt road users by the role of the person driving (an officer, a security guard, on duty). The ontology has no atom for an operator's role or duty status, and a vehicle class is not one.
- **New gap `ru.electric_three_wheeler`** (on NRS-484B-117-1). No class atom states electric-only propulsion together with three wheels.
- **Shared parameters.** Several new parameters are shared across these nodes, each proposed with the same value and convention everywhere:
  - the six `p.following_headway_*` and `p.following_decel_*` parameters (NRS-484B-127-1 and the (b) exception of NRS-484B-208-1);
  - `p.halt_speed_tolerance`, `p.overtake_window` and `p.overtake_same_direction_cos` are proposed again here with their catalogue values.
- **Penalty sentence.** The NRS-484B-117-1 penalty sentence is segmented as `boilerplate`, because a sanction is not conduct a trace can check.
