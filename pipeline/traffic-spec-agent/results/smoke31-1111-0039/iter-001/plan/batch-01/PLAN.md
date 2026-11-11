# Plan — batch 01 (iteration 001)

Eight law lines, nine nodes, seven concept records, one atom gap. No law-local aggregates
(`aggregates.jsonl` is empty): none of these clauses defines, adds or excludes members of a class.

## Nodes

**LVMC_11_38_030 — sidewalk riding.** The subject is `ru.aggregate=DEF-NRS-484A-135::motorcycle`
plus "motor scooter". No definition or aggregate applies to "motor scooter", so it is carried by
`ru.moped` and `ru.electric_scooter`, the classes whose contracts denote a scooter driven by a motor.
A scooter above the moped class already belongs to the motorcycle aggregate. "be ridden upon any
sidewalk" is read as `drv.motion.moving` while the vehicle occupies an `st.sidewalk`, disclosed as
an agency reading; a parked machine is not ridden. "of the City" is the legal region class
`asm.within_city_limits`. Reversal signal: if the operator reads "motor scooter" as excluding
stand-up electric scooters, drop `ru.electric_scooter` from the subject.

**LVMC_11_43_010_A — roundabout direction.** The subject is a vehicle (the admitted aggregate) that
occupies an `st.roundabout`. The obligation is that the vehicle is not moving clockwise about the
roundabout's reference point (`drv.motion.clockwise_about_region`). Clockwise is tested by the
sign of the cross product of the radius vector and the velocity, beyond a sine tolerance. Entering
or leaving radially, and standing still, are neither sense, so they comply. The reading that the
region's reference point is the centre of the circulatory roadway is disclosed. Reversal signal:
a source whose roundabout reference point is not near the island centre (see below).

**NRS_484B_113_2 — backing.** One obligation span covers three alternatives:
- `drv.motion.reversing` at the rise of occupancy of an `st.intersection` ("into");
- reversing while occupying an `st.crosswalk` ("on or over");
- reversing and `drv.motion.yawing` while occupying an intersection ("around a … corner").

"street" (DEF-NRS-484A-265, inside city limits) limits only the third alternative. It is carried by
`asm.within_city_limits` on its own span, and the coder joins it to that alternative alone.
"corner" is a condition span read as the intersection region. Backing is read from velocity against
heading, never from `kin.gear`. Reversal signal: a labelled scene that backs around a corner outside
any mapped intersection region.

**NRS_484B_127_3 — caravan spacing.**
- The subject is the admitted motor-vehicle aggregate on an `st.highway`.
- "outside of a business district" is `asm.outside_business_district`.
- "whether or not towing" is a scope-none residue: the duty is the same either way.
- The obligation is a longitudinal `rel.surface_gap` to the vehicle or combination (both admitted
  aggregates) ahead in the lane.
- The standard "so as to enable … to enter and occupy such space without danger" is bounded by
  `p.entering_combination_length` plus `p.entry_time_headway` × speed, once ahead of and once behind
  the entering vehicle (a gap-acceptance convention). It is not a surrogate: the standard qualifies
  a concrete spacing duty.

"in a caravan or motorcade" has no observable counterpart. Group membership is neither a
purpose that conduct reads nor a legal region class, and ordinary following looks the same. It is
mapped to the nearest atoms (`rel.ahead_behind_in_lane`, `rel.same_direction`) and filed as atom
gap `ru.procession_member`. Reversal signal: the operator accepting a following-based reading, or
admitting the atom.

**NRS_484B_210_3 — passing on the right off the pavement.** The condition "requires driving off
the paved portion" is read by the movement as made: the vehicle occupies an `st.shoulder`, or an
`st.road_edge`, whose paved attribute is false. The obligation is that the vehicle passes no vehicle
on its right (`drv.interaction.passing_on_right`: aligned headings, side by side, the other on the
subject's left, the subject faster). The pass is judged at its side-by-side phase, disclosed as a
narrowing. The other vehicle is quantified, not bound, so a vehicle alone on the shoulder is decided
compliant. Reversal signal: a labelled pass made off the pavement that never comes alongside.

**NRS_484B_223_4a — right turn lane used only to turn right.**
- The singled-out lane L is an `st.turn_lane` of side right on an `st.highway`.
- "single" means no adjacent lane (`st.lane_adjacency`) is also a right turn lane.
- "only for the purpose of making a right turn" is a purpose reading, judged by how the vehicle
  leaves L. It violates by leaving L for the adjacent lane on its left short of the intersection
  L enters (`st.lane_enters`).
- It also violates by leaving that intersection, having entered it from L, with a heading change
  since entry (`drv.motion.heading_change_since_entry`) short of minus `p.turn_recognition_angle`.

Reversal signal: a labelled lane exit to the left that the words treat as permitted.

**NRS_484B_223_4b — no travel through from the right turn lane.** It uses the same lane selection
as 4a. "travel through an intersection" is read as entering the intersection L enters while
occupying L, then leaving it without a right-turn heading change. Straight and left passages alike
violate. A through passage from the turn lane violates both 4a and 4b, as both lines say.

**NRS_484B_227_1_o1 and NRS_484B_227_1_o2 — divided highway.** The line has two "must" clauses, so
it has two nodes. A divided highway is an `st.highway` on which an `st.median_or_divider` lies.

- **o1 (right-hand roadway):** the vehicle does not move against the designated direction of a
  roadway of that highway it occupies (`drv.motion.against_carrier_direction`). This reads "the
  right-hand roadway" under right-hand traffic. Crossing a roadway at a wide angle is not against it.
- **o2 (dividing section and turns):** the vehicle neither occupies a median region nor moves
  against a roadway's direction. Both are excepted where it occupies a median region with the
  opening attribute (opening, crossover) or an `st.intersection`. "established by a public
  authority" is a status reading of the feature's presence.

The turns in o2 are read through their outcome: crossing the dividing section, or "so as to proceed
in the opposite direction" (DEF-NRS-484B-077). This is disclosed as a narrowing. A wrong-way
vehicle that never turned is judged by o2 too. Reversal signal: a labelled wrong-way entry from a
ramp that is expected not to violate o2. Then o2 would need a turn act concept (occasion
machinery) instead of the outcome reading.

## Concept records

All are states or quantities at an observation, so none declares an act and no node needs an
`occasion`.
- `drv.motion.moving`: speed above resolution.
- `drv.motion.reversing`: velocity component along heading below minus resolution, never gear.
- `drv.motion.yawing`: absolute yaw rate above resolution.
- `drv.motion.clockwise_about_region`: sense of motion about a region's reference point.
- `drv.motion.against_carrier_direction`: velocity against `st.lane_direction`.
- `drv.interaction.passing_on_right`: the side-by-side phase of an overtaking on the other's right.
- `drv.motion.heading_change_since_entry`: a quantity, the heading change since the footprint
  entered a region.

## Parameters proposed

`p.speed_resolution`, `p.yaw_rate_resolution`, `p.circulation_sine_tolerance`,
`p.opposed_direction_cosine`, `p.same_direction_cosine`, `p.overtaking_speed_margin`,
`p.turn_recognition_angle`, `p.entering_combination_length`, `p.entry_time_headway`. Each proposal
states its convention and source. The `headingSince` step bound is the catalogue's
`p.heading_since_step_carla_scene_graph`.

## For the operator

- **Gap `ru.procession_member` (NRS-484B-127-3, span "in a caravan or motorcade"):** nothing in the
  ontology tells a member of an organized motorcade from ordinary following traffic. The law stays
  blocked until the atom is admitted, or until a following-based reading is approved.
- **Roundabout centre:** LVMC-11-43-010-A relies on the `st.roundabout` reference point
  (`st.region_geometry`) lying at the centre of the circulatory roadway. The adapter's manifest
  should confirm this for `carla_scene_graph`; otherwise the clockwise test is taken about the wrong
  point.
- **"motor scooter":** LVMC 11.38.030 uses an undefined term. The plan includes mopeds and electric
  scooters. Please confirm or narrow this reading.
- **Attribute-valued kinds:** several nodes read attribute values: `st.turn_lane` side right,
  `st.median_or_divider` opening, and the paved attribute of `st.shoulder` / `st.road_edge`. The
  plan names the atoms and states the values in the justifications. The coder reads them through
  the atoms' attributes.
