# Feedback from iteration 1

selection: 10 aggregate, 31 not an aggregate, 0 gap, of 41 defined term(s)
aggregate `DEF-NRS-484A-320::vehicle` admitted: included 14, covered 0, unresolved 3; downgraded to unresolved: ru.electric_bicycle (underdetermined), ru.electric_scooter (underdetermined), ru.rail_vehicle (underdetermined)
aggregate `DEF-NRS-484A-130::motor_vehicle` admitted: included 7, covered 0, unresolved 8; downgraded to unresolved: ru.electric_scooter (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined)
aggregate `DEF-NRS-484A-135::motorcycle` admitted: included 1, covered 0, unresolved 12
aggregate `DEF-NRS-484A-125::moped` admitted: included 1, covered 1, unresolved 15; downgraded to unresolved: ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.electric_bicycle (underdetermined), ru.electric_scooter (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.official_vehicle (underdetermined), ru.rail_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-025::bicycle` admitted: included 1, covered 16, unresolved 0
aggregate `DEF-NRS-484B-017::electric_bicycle` admitted: included 1, covered 0, unresolved 15; downgraded to unresolved: ru.bicycle (underdetermined), ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.motorcycle (underdetermined), ru.official_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484B-018::electric_scooter` admitted: included 0, covered 0, unresolved 15; downgraded to unresolved: ru.bus (underdetermined), ru.fire_apparatus (underdetermined), ru.rail_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-165::pedestrian` admitted: included 3, covered 0, unresolved 18; downgraded to unresolved: ru.bicycle (underdetermined), ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.electric_bicycle (underdetermined), ru.electric_scooter (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.moped (underdetermined), ru.motor_vehicle (underdetermined), ru.motorcycle (underdetermined), ru.official_vehicle (underdetermined), ru.rail_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-285::traffic` admitted: included 21, covered 0, unresolved 0
aggregate `DEF-NRS-484A-050::combination_of_vehicles` admitted: included 1, covered 13, unresolved 1; downgraded to unresolved: ru.rail_vehicle (underdetermined)
concept `drv.motion.halted`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.entering_region`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.road.opposed_directions`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.slowing`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.moving`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.reversing`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.yawing`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.interaction.overtaking_alongside`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.stopping_distance`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.leaving_region`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.leaving_region`: accepted; the review's notes are recorded on it — The tested exit, with observed overlap followed by observed non-overlap, agrees with the contract: the body holds.; The tested consecutive observations outside the region agree with the contract: the body fails at the second observation.
concept `drv.motion.turning_left`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.u_turn`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.interaction.passing_on_right`: gate OK — 3 witnesses, 4 names, reads 4 atom(s)
concept `drv.motion.against_carrier_direction`: gate OK — 3 witnesses, 4 names, reads 3 atom(s)
concept `drv.motion.clockwise_about_region`: gate OK — 3 witnesses, 5 names, reads 4 atom(s)
concept `drv.motion.heading_change_since_entry`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.heading_change_since_entry`: accepted; the review's notes are recorded on it — The body agrees with the contract on the tested exit case: accumulation continues after the road user leaves the region.; The body agrees with the contract when time since entry exceeds step: step bounds consecutive sampling intervals, not the total integration duration.; A test of zero change at entry with a preceding observation more than step earlier was unusable: the harness reported insufficient temporal sampling. No divergence is established for that boundary …
concept `drv.motion.veering_left`: gate OK — 3 witnesses, 4 names, reads 3 atom(s)
concept `drv.motion.veering_right`: gate OK — 3 witnesses, 4 names, reads 3 atom(s)
concept `drv.position.within_clearance_since_entry`: gate OK — 3 witnesses, 2 names, reads 2 atom(s); narrowings declared by the coder: 1
concept `drv.position.within_clearance_since_entry`: accepted; the review's notes are recorded on it — A tested first observation with fully observed distance greater than a positive clearance returned fails, agreeing with the contract; it supplies no divergence.; dismissed: divergence 1 (holds_wrongly) at t=1000 ms: With clearance set to zero metres, x enters r at the judged observation. Its distance is zero, hence at clearance rather than below it; the body …
concept `drv.position.entered_via`: gate WITNESS_FAIL — blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_250_1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_253_o1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_253_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_257_1_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_270_3_o1`: not coded, composes or calls `NRS_484B_297_6_o1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_4`: not coded, composes or calls `NRS_484B_270_3_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9b_o1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9a_o1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9a_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o3`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o4`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484D_215_1_o2`: not coded, composes or calls `NRS_484D_100_1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484D_215_1_o1`: not coded, composes or calls `NRS_484D_100_1` (unpublished), `NRS_484D_215_1_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`LVMC_11_38_030` proposed `p.speed_resolution` = 0.2 m/s: Sensor resolution: the smallest speed the acquisition standard separates from standstill; a speed at or below it counts 
`LVMC_11_43_010_A` proposed `p.circulation_sine_tolerance` = 0.2 ratio: Direction tolerance: the sine of the largest angle off a radial line within which motion about a point counts as neither
`NRS_484B_113_2` proposed `p.yaw_rate_resolution` = 2.0 deg/s: Sensor resolution: the smallest yaw rate the acquisition standard separates from a straight path; a yaw rate at or below
`NRS_484B_127_3` proposed `p.entering_combination_length` = 22.4 m: Design-vehicle length: the overall length of the longest combination of vehicles a highway is designed to carry, standin
`NRS_484B_127_3` proposed `p.entry_time_headway` = 2.0 s: Safe time headway: the time gap kept to the vehicle ahead, applied once ahead of and once behind the entering vehicle at
`NRS_484B_127_3` proposed `p.same_direction_cosine` = 0.9 ratio: Heading alignment tolerance: the cosine of the largest angle between two headings that still counts as travelling the sa
`NRS_484B_210_3` proposed `p.overtaking_speed_margin` = 0.5 m/s: Speed resolution of a speed difference: the smallest excess of the subject's speed over the other's that counts as gaini
`NRS_484B_223_4a` proposed `p.turn_recognition_angle` = 45 deg: Turn recognition: the heading change through an intersection beyond which a passage counts as a turn rather than a strai
`NRS_484B_227_1_o1` proposed `p.opposed_direction_cosine` = 0.5 ratio: Direction tolerance: minus the cosine of the narrowest angle between a velocity and a carrier's designated direction tha
`NRS_484B_250_4_o1` proposed `p.stop_point_tolerance` = 2.0 m: Stop-point tolerance: the largest ground distance between a halted body and the line, crossing or intersection edge at w
`NRS_484B_250_4_o1` proposed `p.intersection_sight_distance` = 100 m: Intersection sight distance: the length of the crossing way, in the smaller of its two directions, that a driver halted 
`NRS_484B_257_1_o1` proposed `p.deceleration_resolution` = 0.3 m/s^2: Sensor resolution: the smallest longitudinal deceleration the acquisition standard separates from steady speed; a decele
`LVMC_11_38_030`: gate OK — 5 witnesses, 6 names, composes nothing
`NRS_484B_263_o2` proposed `p.merge_time_headway` = 2.0 s: Safe merge headway: the time an approaching vehicle on the highway would take, at its own speed, to close the gap to a v
`LVMC_11_43_010_A`: gate OK — 5 witnesses, 4 names, composes nothing
`NRS_484B_297_6_o1` proposed `p.obstruction_encounter_reach` = 2.0 m: Encounter reach: the ground distance from a pedestrian's body to an obstruction within which the pedestrian has come up 
`NRS_484B_263_o1`: gate OK — 6 witnesses, 8 names, composes nothing
`NRS_484B_297_6_o2` proposed `p.pedestrian_detour_offset` = 1.0 m: Pedestrian detour width: the largest distance from the sidewalk at which a pedestrian walking on the adjacent highway co
`NRS_484B_227_1_o1`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_297_6_o3` proposed `p.sidewalk_return_time` = 5.0 s: Return time: the time after a pedestrian has passed an obstruction within which a return to the sidewalk counts as made 
`NRS_484B_210_3`: gate OK — 9 witnesses, 7 names, composes nothing
`NRS_484B_270_3_o2` proposed `p.access_crossing_reach` = 6.0 m: Access reach: the ground distance from a vehicle's body to a driveway or alley entrance within which its presence in a b
`NRS_484B_227_1_o2`: gate OK — 6 witnesses, 9 names, composes nothing
`NRS_484B_270_7b` proposed `p.passing_lateral_clearance` = 0.9 m: Passing clearance: the smallest surface gap between a cycle or scooter and a motor vehicle it passes alongside at which 
`NRS_484B_113_2`: gate OK — 7 witnesses, 6 names, composes nothing
`NRS_484B_363_3` proposed `p.u_turn_window` = 20 s: U-turn recognition window: the longest time over which a reversal of heading, made in one movement or in several forward
`NRS_484B_363_3` proposed `p.u_turn_reversal_tolerance` = 30 deg: Reversal tolerance: the largest difference between the size of the heading change over the window and a half turn within
`NRS_484B_363_3` proposed `p.child_presence_reach` = 5.0 m: Presence reach: the ground distance from a child's body to a travel region of a school zone within which the child count
`NRS_484B_127_3`: gate UNEXPRESSED — c4 (no_atom): 'in a caravan or motorcade' is membership of an organized group of vehicles proceeding together; no atom of the surface denotes it (the record's gap ru.procession_member). The nearest atoms the record; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_127_3`: gate UNEXPRESSED on ['c4'] (the plan proposed the gap and the coding session confirmed it) — gap(s) ['G17'] filed, law blocked
`NRS_484B_400_1_o1` proposed `p.turn_approach_length` = 15.0 m: Turn approach: the distance travelled just before entering an intersection over which a turning vehicle's approach is ju
`NRS_484B_297_6_o3`: gate OK — 4 witnesses, 9 names, composes nothing
`NRS_484B_297_6_o2`: gate OK — 5 witnesses, 9 names, composes nothing
`NRS_484B_413_2` proposed `p.course_departure_sine` = 0.05 ratio: Course-departure tolerance: the sine of the angle between a road user's velocity and its carrier's designated direction 
`NRS_484B_297_6_o1`: gate UNEXPRESSED — s4 (no_atom): 'a short section of the sidewalk that is missing or impassable' is no physical object: st.obstruction ('a physical object on or beside the roadway that is not a road user') covers a section blocked by; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_297_6_o1`: gate UNEXPRESSED on ['s4'] (the plan proposed the gap and the coding session confirmed it) — gap(s) ['G18'] filed, law blocked
`NRS_484B_440_1_o1` proposed `p.offroad_stop_reach` = 5.0 m: Off-road stopping reach: the ground distance from a halted vehicle's body to a shoulder within which moving off the main
`NRS_484B_440_1_o1` proposed `p.stopping_conflict_gap` = 5.0 m: Conflict standoff: the largest surface gap from a halted road user's body to another road user ahead of it at which the 
`NRS_484B_263_o2`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.surface_gap
`NRS_484B_263_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_440_1_o2` proposed `p.free_passage_width` = 3.0 m: Free-passage width: the smallest width of an unoccupied lane beside a standing vehicle that lets another vehicle pass; a
`NRS_484B_440_1_o2` proposed `p.opposite_lane_reach` = 1.0 m: Beside reach: the largest ground distance from a standing vehicle's body to a lane within which the lane counts as oppos
`NRS_484B_270_7b`: gate OK — 5 witnesses, 5 names, composes nothing
`NRS_484B_440_1_o3`: gate OK — 5 witnesses, 8 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_440_1_o1`: gate OK — 9 witnesses, 18 names, composes nothing
`NRS_484B_440_1_o2`: gate OK — 14 witnesses, 12 names, composes nothing
`NRS_484B_600_1a` proposed `p.perception_reaction_time` = 2.5 s: Perception-reaction time: the time a driver keeps its speed before braking begins, in the stopping sight distance model.
`NRS_484B_600_1a` proposed `p.braking_decel_dry` = 4.5 m/s^2: Braking deceleration on a dry surface: a firm, controlled stop most drivers make on dry pavement.
`NRS_484B_600_1a` proposed `p.braking_decel_wet` = 3.4 m/s^2: Design braking deceleration: the deceleration most drivers keep within their lane and control on a wet surface, used by 
`NRS_484B_600_1a` proposed `p.braking_decel_ice` = 1.5 m/s^2: Braking deceleration on an icy or snow-covered surface: the deceleration packed snow or ice allows under controlled brak
`NRS_484B_600_1a` proposed `p.curve_lateral_accel` = 3.0 m/s^2: Curve lateral acceleration: the lateral acceleration (speed squared times curvature) above which a curve is taken faster
`NRS_484B_600_1a` proposed `p.lateral_margin_time` = 0.02 s: Speed-proportional lateral margin: the lateral room beside a vehicle, both sides together, that grows with speed to abso
`NRS_484B_600_1a` proposed `p.traffic_time_headway` = 1.0 s: Minimum time headway in traffic: the time gap to the road user ahead in the lane below which the speed is too high for t
`NRS_484B_223_4b`: gate OK — 7 witnesses, 11 names, composes nothing
`NRS_484B_413_2`: gate OK — 8 witnesses, 8 names, composes nothing
`NRS_484B_270_3_o2`: gate UNEXPRESSED — s12 (no_atom): 'a disabled vehicle': no atom of the surface denotes a vehicle's inability to move under its own power; sig.hazard (both indicators flashing) and kin.engine_running (propulsion available, not a stand-; s17 (no_atom): 'In an emergency': no atom of the surface denotes an emergency situation at the observation; sig.hazard and ru.emergency_vehicle (not a stand-in for a responding emergency vehicle) do not carry the wo; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_270_3_o2`: gate UNEXPRESSED on ['s12', 's17'] (the plan proposed the gap and the coding session confirmed it) — gap(s) ['G19', 'G20'] filed, law blocked
`NRS_484B_560_7a`: gate OK — 7 witnesses, 11 names, composes nothing
`NRS_484B_600_1a`: gate OK — 8 witnesses, 16 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_450_1c`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `e` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_450_1c`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_223_4a`: gate OK — 9 witnesses, 11 names, composes nothing
`NRS_484B_769`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; blind: unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter], not for an atom the manifest masks; the manifest masks sig.hand_signal; branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS_484B_769`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484D_100_1`: gate UNEXPRESSED — s9 (no_atom): “When directed by an official traffic control device” to display lighted lamps: the record maps it to dev.regulatory_sign governing (dev.governs) a travel region (st.travel_region) the vehicle occupie; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484D_100_1`: gate UNEXPRESSED on ['s9'] (the plan proposed the gap and the coding session confirmed it) — gap(s) ['G21'] filed, law blocked
`NRS_484B_400_1_o1`: gate OK — 7 witnesses, 13 names, composes nothing
`NRS_484B_250_4_o1`: gate OK — 11 witnesses, 18 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_250_4_o2` proposed `p.immediate_hazard_gap` = 4.1 s: Critical gap: the time within which another road user's arrival at the conflict area, or its predicted closest approach,
`NRS_484B_250_4_o2` proposed `p.conflict_clearance` = 3.0 m: Conflict radius: the centre distance at predicted closest approach below which two road users' paths count as in conflic
`NRS_484B_363_3`: gate UNUSED_CLAIM — prim_heading_change
`NRS_484B_363_3`: gate UNUSED_CLAIM — sent to a node repair session; no attempt counted
`NRS_484B_400_1_o2`: gate OK — 6 witnesses, 15 names, composes nothing
`NRS_484B_250_4_o2`: gate OK — 7 witnesses, 12 names, composes NRS_484B_250_4_o1
`NRS_484B_257_1_o1`: gate OK — 18 witnesses, 23 names, composes nothing
dependency context changed and rechecked: `drv.motion.halted`
dependency context changed and rechecked: `drv.motion.entering_region`
dependency context changed and rechecked: `drv.road.opposed_directions`
dependency context changed and rechecked: `drv.motion.slowing`
dependency context changed and rechecked: `drv.motion.moving`
dependency context changed and rechecked: `drv.motion.reversing`
dependency context changed and rechecked: `drv.motion.yawing`
dependency context changed and rechecked: `drv.interaction.overtaking_alongside`
dependency context changed and rechecked: `drv.motion.stopping_distance`
dependency context changed and rechecked: `drv.motion.leaving_region`
dependency context changed and rechecked: `drv.motion.turning_left`
dependency context changed and rechecked: `drv.motion.u_turn`
dependency context changed and rechecked: `drv.interaction.passing_on_right`
dependency context changed and rechecked: `drv.motion.against_carrier_direction`
dependency context changed and rechecked: `drv.motion.clockwise_about_region`
dependency context changed and rechecked: `drv.motion.heading_change_since_entry`
dependency context changed and rechecked: `drv.motion.veering_left`
dependency context changed and rechecked: `drv.motion.veering_right`
dependency context changed and rechecked: `drv.position.within_clearance_since_entry`
`NRS-484B-400-1` span e8 borrows from `NRS-484B-223-4a` the words “a single right lane to be used only for turning”
`NRS-484B-400-1` span e8 borrows from `NRS-484B-223-4b` the words “a single right lane to be used only for turning”
`NRS-484B-400-1` span e8 borrows from `NRS-484B-223-4a` the words “a single right lane to be used only for turning”
`NRS-484B-400-1` span e8 borrows from `NRS-484B-223-4b` the words “a single right lane to be used only for turning”
`NRS-484B-250-4` span s9 composes accepted `NRS_484B_250_4_o1` (as: compliance)

## Laws by state

- blocked: 6
- planned: 23

## Concepts by state

- accepted: 19
- returned: 1

## Returned concepts and why

- `drv.position.entered_via` (returned, attempt 1; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_250_1` waits on `drv.position.entered_via`
- `NRS_484B_253_o1` waits on `drv.position.entered_via`
- `NRS_484B_253_o2` waits on `NRS_484B_253_o1`, `drv.position.entered_via`
- `NRS_484B_257_1_o2` waits on `drv.position.entered_via`
- `NRS_484B_270_3_o1` waits on `NRS_484B_297_6_o1`
- `NRS_484B_270_4` waits on `NRS_484B_270_3_o2`
- `NRS_484B_307_9b_o1` waits on `drv.position.entered_via`
- `NRS_484B_307_9a_o1` waits on `NRS_484B_307_9b_o1`, `drv.position.entered_via`
- `NRS_484B_307_9a_o2` waits on `NRS_484B_307_9b_o1`, `drv.position.entered_via`
- `NRS_484B_307_9b_o2` waits on `drv.position.entered_via`
- `NRS_484B_307_9b_o3` waits on `drv.position.entered_via`
- `NRS_484B_307_9b_o4` waits on `drv.position.entered_via`
- `NRS_484D_215_1_o2` waits on `NRS_484D_100_1`
- `NRS_484D_215_1_o1` waits on `NRS_484D_100_1`, `NRS_484D_215_1_o2`

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `drv.position.within_clearance_since_entry` at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance: the distance is read at every observation after the entry up to the judged one, not at the entry itself: there the footprint overlaps r, so by the contract's own words the distance is zero and below clearance, and it does not decide
- `NRS_484B_440_1_o3` g12: The sight distance at x's place is read off the roadway regions x occupies, and is required at each of them where x straddles several.
- `NRS_484B_600_1a` s3: The sight distance and the curvature "at x's place" are read at every lane x's footprint overlaps (rel.occupies over st.lane), the region the lane-width bound reads; where x occupies no lane, these two factors set no bound.
- `NRS_484B_250_4_o1` s4: The history bound's 'previous entry into i' is read at x's exit from i after that entry (the observation at which rel.occupies x i turns false): a halt x makes while its footprint still overlaps i after a previous entry does not count for this entry.

## Gaps filed this iteration

- G17 (atom) on `in a caravan or motorcade` — NRS-484B-127-3
- G18 (atom) on `including, without limitation, a short section of the sidewalk that is missing o` — NRS-484B-297-6
- G19 (atom) on `(b) When operating or parking a disabled vehicle;` — NRS-484B-270-3
- G20 (atom) on `(f) In an emergency.` — NRS-484B-270-3
- G21 (atom) on `and (c) When directed by an official traffic control device.` — NRS-484D-100-1
