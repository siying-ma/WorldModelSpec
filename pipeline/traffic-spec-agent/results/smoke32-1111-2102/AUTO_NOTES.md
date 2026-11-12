# Feedback from iteration 1

selection: 10 aggregate, 22 not an aggregate, 0 gap, of 32 defined term(s)
aggregate `DEF-NRS-484A-020::authorized_emergency_vehicle` admitted: included 0, covered 0, unresolved 14; downgraded to unresolved: ru.emergency_vehicle (underdetermined), ru.motor_vehicle (underdetermined), ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.motorcycle (underdetermined), ru.moped (underdetermined), ru.official_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined), ru.fire_apparatus (cover_target_not_admitted)
aggregate `DEF-NRS-484A-025::bicycle` admitted: included 1, covered 16, unresolved 3; downgraded to unresolved: ru.child (gate_contradiction), ru.pedestrian (gate_contradiction), ru.pedestrian_with_white_cane_or_guide_animal (gate_contradiction)
aggregate `DEF-NRS-484A-125::moped` admitted: included 1, covered 1, unresolved 16; downgraded to unresolved: ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.official_vehicle (underdetermined), ru.rail_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-130::motor_vehicle` admitted: included 7, covered 0, unresolved 9; downgraded to unresolved: ru.electric_bicycle (underdetermined), ru.electric_scooter (underdetermined)
aggregate `DEF-NRS-484A-135::motorcycle` admitted: included 1, covered 0, unresolved 15; downgraded to unresolved: ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.official_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-165::pedestrian` admitted: included 3, covered 1, unresolved 0
aggregate `DEF-NRS-484A-285::traffic` admitted: included 21, covered 0, unresolved 0
aggregate `DEF-NRS-484A-320::vehicle` admitted: included 14, covered 0, unresolved 1; downgraded to unresolved: ru.rail_vehicle (underdetermined)
aggregate `DEF-NRS-484B-017::electric_bicycle` admitted: included 1, covered 0, unresolved 18; downgraded to unresolved: ru.electric_bicycle (underdetermined)
aggregate `DEF-NRS-484B-018::electric_scooter` admitted: included 0, covered 0, unresolved 18; downgraded to unresolved: ru.rail_vehicle (underdetermined), ru.bus (underdetermined), ru.school_bus (underdetermined), ru.transit_bus (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.taxicab (underdetermined), ru.truck (underdetermined), ru.fire_apparatus (underdetermined), ru.trailer_or_combination (underdetermined)
concept `drv.motion.at_rest`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.position.near_region`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.backing`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.backing`: accepted; the review's notes are recorded on it — dismissed: divergence 1 (holds_wrongly) at t=0 ms: The road user points northeast and moves southwest with velocity [-0.7071066, -0.7071066] m/s. Its rearward component along the unit heading is …
concept `drv.motion.stopping_distance`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.position.behind`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.turning_left`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.u_turn`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.left_turn`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.decelerating`: gate OK — 3 witnesses, 2 names, reads 3 atom(s)
concept `drv.motion.heading_change_since_entry`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.heading_change_since_entry`: accepted; the review's notes are recorded on it — Tested continued accumulation after leaving the region: the body returned the contract's 90 deg.; Tested zero at observed entry with the pre-entry yaw rate unobserved: the body returned 0 deg, agreeing with the contract.; Tested accumulation beyond a full revolution: the body returned 450 deg without wrapping, agreeing with the contract.
concept `drv.motion.turning_right`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.interaction.overtakes`: gate OK — 3 witnesses, 2 names, reads 3 atom(s)
concept `drv.interaction.overtakes`: review failed — divergence 1 (holds_wrongly) at t=1000 ms: At the second observation, different but aligned headings and lateral separation make each user wholly behind the other in its own heading projection. Neither … — contract: fails, body: holds; contract: "The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of …" — upheld: In the executed facts, the headings are opposed at t=0 ([1,0] vs [-1,0]), so a is not behind b at any observation before t=1000. The body's SINCE accepts a behind b at the recognition observation itself as the witness, but the contract requires that witness at an earlier observation. The unknown clause does not apply either, because the headings were not aligned since the recording began, so the contract's verdict is fails. — "provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition"
concept `drv.motion.left_turn_from_onset`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.left_turn_from_onset`: accepted; the review's notes are recorded on it — The tested fully observed onset and threshold crossing agreed with the contract: onset at 1000 ms and 10 deg/s thereafter produced recognition at 2000 ms for a 10 degree turn angle.; A proposed challenge involving a long sampling gap before onset could not be evaluated: the harness classified the history as too sparsely sampled. It establishes no divergence.
concept `drv.motion.right_turn_from_onset`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.right_turn_from_onset`: review failed — divergence 1 (fails_wrongly) at t=750 ms: With turn_angle set to zero, a second observed right-turn onset is itself a recognition observation. The body misses it because the heading-change comparison … — contract: holds, body: fails; contract: "The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is …" — upheld: In the executed facts turning_right falls at t=500 and rises again at t=750, so 750 is the new observed beginning. The heading change since it is 0, which reaches −0 first at 750, so the contract holds there. The body fails because its rising edge looks at the heading comparison, which was already true at t=500 when measured from the old onset; that is a wrong onset, not a choice of parameter size. — "The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle."
`LVMC_11_30_030`: held — uses ['drv.interaction.overtakes'], pending (under repair or waiting); no attempt counted
`NRS_484B_250_1`: not coded, composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9a_o1`: not coded — `NRS_484B_307_9a_o1` composes or calls `NRS_484B_307_9b_o1` (missing), `NRS_484B_307_9b_o2` (missing), `NRS_484B_307_9b_o3` (missing), `NRS_484B_307_9b_o4` (missing), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_413_2`: held — uses ['drv.motion.right_turn_from_onset'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9a_o2`: not coded, its law is `returned` after a sibling was returned this iteration
`NRS_484B_113_3` proposed `p.conflict_horizon` = 3.0 s: Time-to-collision horizon of the traffic-conflict technique: a projected approach of the centres within this time counts
`NRS_484B_113_3` proposed `p.conflict_clearance` = 3.0 m: Centre-to-centre distance at the projected closest approach below which the bodies of two passenger vehicles would touch
`NRS_484B_227_1_o3` proposed `p.turn_window` = 15.0 s: Window within which a turn at a junction or across a median, including a U-turn made in several movements, is completed.
`NRS_484B_227_1_o3` proposed `p.left_turn_min_angle` = 60.0 deg: Lower bound of a turn: a leftward heading change below it is a drift or lane change, not a turn onto another way.
`NRS_484B_227_1_o3` proposed `p.left_turn_max_angle` = 150.0 deg: Upper bound of a left turn, above which the direction of travel counts as reversed (a U-turn).
`NRS_484B_227_1_o3` proposed `p.u_turn_min_angle` = 150.0 deg: Heading change at or beyond which the direction of travel counts as reversed.
`NRS_484B_227_1_o3` proposed `p.u_turn_max_angle` = 210.0 deg: Heading change beyond which the road user has turned past the opposite direction (a loop rather than a reversal).
`NRS_484B_227_1_o3` proposed `p.turn_yaw_tolerance` = 5.0 deg/s: Yaw rate below which a change of heading counts as none: above lane-keeping yaw noise, below the yaw rates of turning at
`NRS_484B_250_4_o1` proposed `p.stop_point_tolerance` = 3.0 m: Stop-point tolerance of the ontology's approach convention: the body-to-mark distance within which a halt counts as made
`NRS_484B_253_o1` proposed `p.immediate_hazard_time` = 4.1 s: Critical headway of gap acceptance: an approaching vehicle whose time to reach the intersection is below it is too close
`NRS_484B_257_1_o1` proposed `p.decel_tolerance` = 0.5 m/s^2: Longitudinal deceleration below which a sampled acceleration counts as none: above coasting and sensor noise, below deli
`NRS_484B_257_1_o1` proposed `p.yield_slowing_distance` = 30.0 m: Distance travelled before the stopping zone within which a slowing for a yield sign counts as made for that sign: the br
`NRS_484B_280_1a` proposed `p.pedestrian_conflict_clearance` = 2.5 m: Centre-to-centre distance at the projected closest approach below which the body of a passenger vehicle and a pedestrian
`NRS_484B_600_1a` proposed `p.perception_reaction_time` = 2.5 s: Brake reaction time of the stopping-sight-distance model: the time from the appearance of a hazard to the application of
`NRS_484B_600_1a` proposed `p.stopping_decel_dry` = 4.5 m/s^2: Deceleration a driver attains in a controlled stop on a dry paved surface.
`NRS_484B_600_1a` proposed `p.stopping_decel_wet` = 3.4 m/s^2: Deceleration of the stopping-sight-distance model, which most drivers attain on a wet pavement.
`NRS_484B_600_1a` proposed `p.stopping_decel_ice` = 1.5 m/s^2: Deceleration attainable on an icy or snow-covered surface, from the low friction coefficient of such surfaces.
`NRS_484B_600_1a` proposed `p.curve_lateral_accel` = 2.0 m/s^2: Side-friction limit of horizontal curve design: the lateral acceleration a curve may impose on a vehicle at a comfortabl
`NRS_484B_600_1a` proposed `p.lane_width_speed_time` = 0.16 s: Lane width per unit of speed from the lane-width and design-speed relation of highway design guides (a full-width lane f
`NRS_484B_113_3`: gate OK — 6 witnesses, 5 names, composes nothing
`NRS_484B_227_1_o2`: gate OK — 6 witnesses, 8 names, composes nothing
`NRS_484B_227_1_o1`: gate OK — 7 witnesses, 9 names, composes nothing
`NRS_484B_280_1a`: gate OK — 5 witnesses, 5 names, composes nothing
`NRS_484B_600_1a`: gate OK — 11 witnesses, 14 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_250_4_o1`: gate OK — 10 witnesses, 14 names, composes nothing
`NRS_484B_253_o1`: gate OK — 7 witnesses, 11 names, composes nothing
`NRS_484B_227_1_o3`: gate OK — 13 witnesses, 12 names, composes nothing
`NRS_484B_250_4_o2`: gate OK — 9 witnesses, 17 names, composes nothing
`NRS_484B_257_1_o1`: gate OK — 14 witnesses, 20 names, composes nothing
`NRS_484B_257_1_o2`: gate OK — 16 witnesses, 25 names, composes nothing
`NRS_484B_253_o2`: gate WITNESS_FAIL — forbid: expected violated, got not_applicable; blind: expected unknown, got not_applicable; the manifest masks sig.turn_indicator, sig.hand_signal; branch_3: expected violated, got not_applicable
`NRS_484B_253_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
dependency context changed and rechecked: `drv.motion.at_rest`
dependency context changed and rechecked: `drv.position.near_region`
dependency context changed and rechecked: `drv.motion.backing`
dependency context changed and rechecked: `drv.motion.stopping_distance`
dependency context changed and rechecked: `drv.position.behind`
dependency context changed and rechecked: `drv.motion.turning_left`
dependency context changed and rechecked: `drv.motion.u_turn`
dependency context changed and rechecked: `drv.motion.left_turn`
dependency context changed and rechecked: `drv.motion.decelerating`
dependency context changed and rechecked: `drv.motion.heading_change_since_entry`
dependency context changed and rechecked: `drv.motion.turning_right`
dependency context changed and rechecked: `drv.motion.left_turn_from_onset`
`NRS-484B-117-1`: ['NRS_484B_117_1'] carry gap(s) ['G17', 'G18', 'G19', 'G20', 'G21'], filed; not coded, law blocked
`NRS-484B-297-6`: ['NRS_484B_297_6_o1', 'NRS_484B_297_6_o2', 'NRS_484B_297_6_o3'] carry gap(s) ['G22'], filed; not coded, law blocked
`NRS-484B-307-9b`: ['NRS_484B_307_9b_o1', 'NRS_484B_307_9b_o2', 'NRS_484B_307_9b_o3', 'NRS_484B_307_9b_o4'] carry gap(s) ['G23'], filed; not coded, law blocked
`NRS-484B-440-1`: ['NRS_484B_440_1_o1', 'NRS_484B_440_1_o2', 'NRS_484B_440_1_o3'] carry gap(s) ['G24'], filed; not coded, law blocked

## Laws by state

- blocked: 4
- planned: 10
- returned: 1

## Returned laws and why

- `NRS-484B-307-9a` (attempt 0): `NRS_484B_307_9a_o1` composes or calls `NRS_484B_307_9b_o1` (missing), `NRS_484B_307_9b_o2` (missing), `NRS_484B_307_9b_o3` (missing), `NRS_484B_307_9b_o4` (missing), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted

## Concepts by state

- accepted: 12
- returned: 2

## Returned concepts and why

- `drv.interaction.overtakes` (returned, attempt 1; used by LVMC_11_30_030): review: divergence 1 (holds_wrongly) at t=1000 ms: At the second observation, different but aligned headings and lateral separation make each user wholly behind the other in its own heading projection. Neither … — contract: fails, body: holds; contract: "The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of …" — upheld: In the executed facts, the headings are opposed at t=0 ([1,0] vs [-1,0]), so a is not behind b at any observation before t=1000. The body's SINCE accepts a behind b at the recognition observation itself as the witness, but the contract requires that witness at an earlier observation. The unknown clause does not apply either, because the headings were not aligned since the recording began, so the contract's verdict is fails. — "provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition"
- `drv.motion.right_turn_from_onset` (returned, attempt 1; used by NRS_484B_413_2): review: divergence 1 (fails_wrongly) at t=750 ms: With turn_angle set to zero, a second observed right-turn onset is itself a recognition observation. The body misses it because the heading-change comparison … — contract: holds, body: fails; contract: "The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is …" — upheld: In the executed facts turning_right falls at t=500 and rises again at t=750, so 750 is the new observed beginning. The heading change since it is 0, which reaches −0 first at 750, so the contract holds there. The body fails because its rising edge looks at the heading comparison, which was already true at t=500 when measured from the old onset; that is a wrong onset, not a choice of parameter size. — "The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle."

## Nodes held for a later iteration, and why (no attempt counted)

- `LVMC_11_30_030` waits on `drv.interaction.overtakes`
- `NRS_484B_250_1` held: composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building
- `NRS_484B_413_2` waits on `drv.motion.right_turn_from_onset`

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `NRS_484B_600_1a` u4: The place at which st.sight_distance and st.curvature are read is each lane ego occupies (st.lane, rel.occupies), the regions the width clause selects; no other region of ego's place is read.

## Gaps filed this iteration

- G17 (atom) on `The provisions of subsection 1 do not apply to a vehicle that is powered solely ` — NRS-484B-117-1
- G18 (atom) on `(b) By an officer or other authorized employee of a law enforcement agency,` — NRS-484B-117-1
- G19 (atom) on `in the course of his or her official duties; or` — NRS-484B-117-1
- G20 (atom) on `(c) By a security guard,` — NRS-484B-117-1
- G21 (atom) on `in the course of his or her official duties.` — NRS-484B-117-1
- G22 (atom) on `including, without limitation, a short section of the sidewalk that is missing o` — NRS-484B-297-6
- G23 (atom) on `or trimobile` — NRS-484B-307-9b
- G24 (atom) on `This section shall not apply to the driver of any vehicle which is disabled whil` — NRS-484B-440-1
