# Feedback from iteration 1

selection: 10 aggregate, 31 not an aggregate, 0 gap, of 41 defined term(s)
aggregate `DEF-NRS-484A-320::vehicle` admitted: included 14, covered 0, unresolved 2; downgraded to unresolved: ru.rail_vehicle (underdetermined)
aggregate `DEF-NRS-484A-130::motor_vehicle` admitted: included 7, covered 0, unresolved 9; downgraded to unresolved: ru.commercial_motor_vehicle (underdetermined), ru.electric_bicycle (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.official_vehicle (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined)
aggregate `DEF-NRS-484A-025::bicycle` admitted: included 1, covered 16, unresolved 0
aggregate `DEF-NRS-484B-017::electric_bicycle` admitted: included 1, covered 1, unresolved 14; downgraded to unresolved: ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.motorcycle (underdetermined), ru.official_vehicle (underdetermined), ru.rail_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484B-018::electric_scooter` admitted: included 0, covered 0, unresolved 15; downgraded to unresolved: ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.electric_scooter (gate_contradiction), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.motorcycle (underdetermined), ru.official_vehicle (underdetermined), ru.rail_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-125::moped` admitted: included 1, covered 1, unresolved 13; downgraded to unresolved: ru.motor_vehicle (underdetermined), ru.emergency_vehicle (underdetermined), ru.official_vehicle (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.taxicab (underdetermined), ru.rail_vehicle (underdetermined), ru.trailer_or_combination (underdetermined), ru.bus (underdetermined), ru.school_bus (underdetermined), ru.transit_bus (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.truck (underdetermined), ru.fire_apparatus (underdetermined)
aggregate `DEF-NRS-484A-135::motorcycle` admitted: included 1, covered 0, unresolved 13; downgraded to unresolved: ru.bus (underdetermined), ru.commercial_motor_vehicle (underdetermined), ru.emergency_vehicle (underdetermined), ru.fire_apparatus (underdetermined), ru.motor_vehicle (underdetermined), ru.official_vehicle (underdetermined), ru.school_bus (underdetermined), ru.taxicab (underdetermined), ru.tour_bus_or_limousine (underdetermined), ru.trailer_or_combination (underdetermined), ru.transit_bus (underdetermined), ru.truck (underdetermined)
aggregate `DEF-NRS-484A-050::combination_of_vehicles` admitted: included 1, covered 13, unresolved 1; downgraded to unresolved: ru.rail_vehicle (gate_contradiction)
aggregate `DEF-NRS-484A-165::pedestrian` admitted: included 3, covered 0, unresolved 1; downgraded to unresolved: ru.electric_scooter (underdetermined)
aggregate `DEF-NRS-484A-285::traffic` admitted: included 19, covered 2, unresolved 0
concept `drv.motion.moving`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.stopped`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.turning`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.clockwise_about_region`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.turning_left`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.lane.heading_offset_from_direction`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.lane.facing_against_direction`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.lane.facing_against_direction`: accepted; the review's notes are recorded on it — dismissed: divergence 1 (holds_wrongly) at t=0 ms: The heading is [-7,-1] and the carrier direction is [1,1], so their exact cosine is -8/sqrt(50·2) = -0.8. With cos_tol = 0.8 the strict comparison mu
concept `drv.motion.left_turn`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.interaction.overtaking`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.stopping_distance`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.interaction.passing_on_right`: gate OK — 3 witnesses, 4 names, reads 4 atom(s)
concept `drv.motion.u_turn`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.backing`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.backing`: accepted; the review's notes are recorded on it — dismissed: divergence 1 (holds_wrongly) at t=0 ms: The road user points along [5,12] and has velocity [-0.2,-1] m/s, giving an exact backward component of 1 m/s, equal to tol. Truncating the scaled he
concept `drv.motion.straight_through_region`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.straight_through_region`: accepted; the review's notes are recorded on it — A fully observed crossing with zero heading change was recognized at exit, agreeing with the contract.; A 90-degree heading change before the observed entry did not affect recognition of a straight crossing; the body agreed with the contract.
concept `drv.motion.right_turn_through_region`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.left_turn_through_region`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
`NRS_484B_250_1`: not coded, composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_3_o1`: not coded, composes or calls `NRS_484B_297_6_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_4`: not coded, composes or calls `NRS_484B_270_3_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9a_o1`: not coded, composes or calls `NRS_484B_307_9b_o1` (unpublished), `NRS_484B_307_9b_o2` (unpublished), `NRS_484B_307_9b_o3` (unpublished), `NRS_484B_307_9b_o4` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9a_o2`: not coded, composes or calls `NRS_484B_307_9b_o1` (unpublished), `NRS_484B_307_9b_o2` (unpublished), `NRS_484B_307_9b_o3` (unpublished), `NRS_484B_307_9b_o4` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484D_215_1_o2`: not coded, composes or calls `NRS_484D_100_1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484D_215_1_o1`: not coded, composes or calls `NRS_484D_100_1` (unpublished), `NRS_484D_215_1_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`LVMC_11_38_030` proposed `p.motion_speed_tolerance` = 0.2 m/s: Speed resolution: the noise floor of a source's speed estimate, below which a road user is read as standing still.
`NRS_484B_113_2` proposed `p.yaw_rate_tolerance` = 2.0 deg/s: Yaw-rate resolution: the noise floor of a source's yaw-rate estimate, below which a heading is read as not changing.
`NRS_484B_127_3` proposed `p.caravan_entry_vehicle_length` = 22.4 m: Overall length of the longest design combination a highway is designed for (an interstate semitrailer combination), so t
`NRS_484B_127_3` proposed `p.caravan_entry_time_headway` = 1.0 s: Minimum accepted lead and lag time gap of a merging or lane-changing vehicle, applied once ahead of and once behind the 
`NRS_484B_210_3` proposed `p.same_direction_cos_tolerance` = 0.9 ratio: Heading alignment: cosine of the largest angle between two headings still read as the same way of travel (about a quarte
`NRS_484B_223_4b` proposed `p.straight_through_max_heading_change` = 30.0 deg: Turning-movement classification at a junction: a crossing whose net heading change stays below this bound is a through m
`NRS_484B_227_1_o1` proposed `p.against_direction_cos_tolerance` = 0.7 ratio: Cosine of the largest angle off exactly opposed at which a heading still points against a carrier's designated direction
`NRS_484B_227_1_o3` proposed `p.turn_recognition_window` = 15.0 s: The time within which a turn or a reversal, a reversal made in several moves included, is completed: the window over whi
`NRS_484B_227_1_o3` proposed `p.left_turn_min_angle` = 60.0 deg: The heading change to the left beyond which a manoeuvre is a turn rather than a lane change or a bend's drift.
`NRS_484B_227_1_o3` proposed `p.reversal_min_angle` = 150.0 deg: The heading change magnitude from which the heading has come round to the opposite direction (a reversal); also the uppe
`NRS_484B_227_1_o3` proposed `p.reversal_max_angle` = 210.0 deg: The heading change magnitude beyond which the heading has come round past the opposite direction (a loop rather than a r
`NRS_484B_250_4_o1` proposed `p.stop_point_tolerance` = 2.0 m: Stop-point tolerance of the approach convention: the distance between a road user's body and the governing mark (stop li
`NRS_484B_250_4_o1` proposed `p.approach_view_sight_distance` = 61.0 m: Sight distance along a crossing way that gives a view of approaching traffic: the stopping sight distance at a 30 mph de
`NRS_484B_250_4_o2` proposed `p.conflict_time_horizon` = 3.0 s: Time-to-collision horizon of the traffic-conflict technique: a predicted closest approach within this time counts as an 
`NRS_484B_250_4_o2` proposed `p.conflict_centre_clearance` = 4.0 m: Centre-to-centre distance at the predicted closest approach below which two road users' bodies come into conflict: about
`LVMC_11_43_010_A`: gate OK — 6 witnesses, 5 names, composes nothing
`NRS_484B_253_o1` proposed `p.immediate_hazard_time_gap` = 4.0 s: Critical gap of gap acceptance: an approaching vehicle whose time to reach the conflict (its distance over its speed) is
`LVMC_11_38_030`: gate OK — 8 witnesses, 6 names, composes nothing
`NRS_484B_257_1_o1` proposed `p.yield_sign_check_speed` = 6.7 m/s: Speed to which a vehicle at a yield-controlled approach slows so that it can still halt before the conflict (about 15 mp
`NRS_484B_227_1_o2`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_227_1_o1`: gate OK — 6 witnesses, 8 names, composes nothing
`NRS_484B_127_3`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_223_4a`: gate OK — 7 witnesses, 11 names, composes nothing
`NRS_484B_297_6_o1` proposed `p.obstruction_encounter_reach` = 2.0 m: Distance between a pedestrian's body and an obstruction within which the pedestrian is at the obstruction (encountering 
`NRS_484B_297_6_o1` proposed `p.pedestrian_detour_side_distance` = 1.0 m: Largest distance between a detouring pedestrian's body and the sidewalk that is still as far to the side near the sidewa
`NRS_484B_113_2`: gate OK — 9 witnesses, 6 names, composes nothing
`NRS_484B_297_6_o2` proposed `p.sidewalk_return_time` = 5.0 s: Time within which a pedestrian who has cleared an obstruction steps back onto the sidewalk: the walking time to cover a 
`NRS_484B_210_3`: gate OK — 10 witnesses, 7 names, composes nothing
`NRS_484B_227_1_o3`: gate OK — 11 witnesses, 11 names, composes nothing
`NRS_484B_270_7b` proposed `p.overtaking_lateral_clearance` = 1.0 m: Lateral clearance of the bicycle operating envelope: the shy distance between a bicyclist's body and a motor vehicle bes
`NRS_484B_223_4b`: gate OK — 7 witnesses, 10 names, composes nothing
`NRS_484B_307_9b_o1` proposed `p.right_turn_min_angle` = 60.0 deg: The heading change to the right beyond which a manoeuvre is a turn rather than a lane change or a bend's drift; the righ
`NRS_484B_297_6_o1`: gate OK — 9 witnesses, 9 names, composes nothing
`NRS_484B_297_6_o2`: gate OK — 7 witnesses, 9 names, composes nothing
`NRS_484B_263_o1`: gate WITNESS_FAIL — blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest masks; the manifest masks rel.surface_gap
`NRS_484B_263_o1`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_270_7b`: gate OK — 5 witnesses, 5 names, composes nothing
`NRS_484B_253_o1`: gate OK — 12 witnesses, 11 names, composes nothing
`NRS_484B_263_o2`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.surface_gap
`NRS_484B_263_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_270_3_o2`: gate OK — 11 witnesses, 11 names, composes nothing
`NRS_484B_257_1_o2`: gate OK — 13 witnesses, 21 names, composes nothing
`NRS_484B_413_2` proposed `p.course_change_sin_tolerance` = 0.05 ratio: Lane-change kinematics: the heading of a vehicle changing lanes or turning departs from the lane direction by about thre
`NRS_484B_250_4_o2`: gate OK — 10 witnesses, 22 names, composes nothing
`NRS_484B_440_1_o1` proposed `p.queue_standstill_gap` = 4.0 m: Standstill gap of queued vehicles: the clearance between a vehicle halted in a queue and the one ahead of it; car-follow
`NRS_484B_440_1_o1` proposed `p.off_roadway_reach` = 3.7 m: One standard lane width (12 ft): a shoulder separated from the vehicle's body by no more than one lane is reachable by o
`NRS_484B_413_2`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_440_1_o2` proposed `p.free_passage_width` = 3.0 m: Width a passing design vehicle needs: the 8.5 ft (2.6 m) design vehicle width plus a shy margin of about 0.4 m.
`NRS_484B_400_1_o2`: gate OK — 6 witnesses, 11 names, composes nothing
`NRS_484B_307_9b_o2`: gate BARE_LITERAL — formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
`NRS_484B_307_9b_o2`: gate BARE_LITERAL — sent to a node repair session; no attempt counted
`NRS_484B_257_1_o1`: gate OK — 19 witnesses, 23 names, composes nothing
`NRS_484B_363_3`: gate OK — 16 witnesses, 16 names, composes nothing
`NRS_484B_600_1a` proposed `p.perception_reaction_time` = 2.5 s: Brake reaction time of the stopping-sight-distance model: the time from sighting a need to halt to applying the brakes, 
`NRS_484B_600_1a` proposed `p.surface_friction_accel_dry` = 3.4 m/s^2: Deceleration of the stopping-sight-distance model, which most drivers achieve and most paved surfaces sustain when dry; 
`NRS_484B_600_1a` proposed `p.surface_friction_accel_wet` = 2.5 m/s^2: Deceleration a wet paved surface sustains: a wet-pavement friction coefficient of about a quarter at highway speeds, tim
`NRS_484B_600_1a` proposed `p.surface_friction_accel_ice_or_snow` = 1.0 m/s^2: Deceleration an icy or snow-covered surface sustains: a friction coefficient of about a tenth, times gravity; also the a
`NRS_484B_600_1a` proposed `p.following_min_time_headway` = 1.0 s: Car-following: the smallest time gap to the road user ahead at which a following driver can still react to its braking; 
`NRS_484B_600_1a` proposed `p.lane_keeping_margin_per_speed` = 0.0175 s: Time-to-line-crossing convention: drifting at a heading error of about one degree, a vehicle keeps at least one second b
`NRS_484B_400_1_o1`: gate OK — 10 witnesses, 10 names, composes nothing
`NRS_484B_440_1_o3`: gate OK — 7 witnesses, 7 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_440_1_o2`: gate OK — 11 witnesses, 9 names, composes nothing
`NRS_484B_769`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS_484B_769`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_450_1c`: gate OK — 11 witnesses, 17 names, composes nothing
`NRS_484D_100_1`: gate SCOPE_NARROWED — narrowing on f7 (condition): 'When directed by an official traffic control device' to display lighted lamps: no atom of the surface denotes such a direction. dev.regulatory_sign carries no ; a span that decides when the rule applies is carried as the node maps it, or the node is wrong: report it in the result note
`NRS_484D_100_1`: gate SCOPE_NARROWED — sent to a node repair session; no attempt counted
`NRS_484B_250_4_o1`: gate OK — 12 witnesses, 18 names, composes nothing; narrowings declared by the coder: 2
`NRS_484B_440_1_o1`: gate OK — 12 witnesses, 22 names, composes nothing
`NRS_484B_600_1a`: gate OK — 10 witnesses, 16 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_307_9b_o3`: gate OK — 9 witnesses, 15 names, composes nothing
`NRS_484B_560_7a`: gate OK — 9 witnesses, 14 names, composes nothing
`NRS_484B_253_o2`: gate OK — 7 witnesses, 12 names, composes NRS_484B_253_o1
`NRS_484B_307_9b_o4`: gate OK — 7 witnesses, 17 names, composes nothing
`NRS_484B_307_9b_o1`: gate OK — 12 witnesses, 18 names, composes nothing; narrowings declared by the coder: 2
dependency context changed and rechecked: `drv.motion.moving`
dependency context changed and rechecked: `drv.motion.stopped`
dependency context changed and rechecked: `drv.motion.turning`
dependency context changed and rechecked: `drv.motion.clockwise_about_region`
dependency context changed and rechecked: `drv.motion.turning_left`
dependency context changed and rechecked: `drv.lane.heading_offset_from_direction`
dependency context changed and rechecked: `drv.lane.facing_against_direction`
dependency context changed and rechecked: `drv.motion.left_turn`
dependency context changed and rechecked: `drv.interaction.overtaking`
dependency context changed and rechecked: `drv.motion.stopping_distance`
dependency context changed and rechecked: `drv.interaction.passing_on_right`
dependency context changed and rechecked: `drv.motion.u_turn`
dependency context changed and rechecked: `drv.motion.backing`
dependency context changed and rechecked: `drv.motion.straight_through_region`
dependency context changed and rechecked: `drv.motion.right_turn_through_region`
dependency context changed and rechecked: `drv.motion.left_turn_through_region`
`NRS-484B-400-1` span r7 borrows from `NRS-484B-223-4a` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-400-1` span r7 borrows from `NRS-484B-223-4b` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-400-1` span r7 borrows from `NRS-484B-223-4a` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-400-1` span r7 borrows from `NRS-484B-223-4b` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-253` span s6 composes accepted `NRS_484B_253_o1` (as: compliance)

## Laws by state

- planned: 29

## Concepts by state

- accepted: 16

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_250_1` held: composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building
- `NRS_484B_270_3_o1` held: composes or calls `NRS_484B_297_6_o2` (unpublished), not usable for building
- `NRS_484B_270_4` held: composes or calls `NRS_484B_270_3_o2` (unpublished), not usable for building
- `NRS_484B_307_9a_o1` waits on `NRS_484B_307_9b_o2`
- `NRS_484B_307_9a_o2` waits on `NRS_484B_307_9b_o2`
- `NRS_484D_215_1_o2` waits on `NRS_484D_100_1`
- `NRS_484D_215_1_o1` waits on `NRS_484D_100_1`, `NRS_484D_215_1_o2`

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `NRS_484B_440_1_o3` e10: x's place is read as each roadway x occupies on the highway it occupies (the e1/e6 selection repeated): the sight distance the source records for that roadway region must be at least 200 ft, for every such roadway.
- `NRS_484B_250_4_o1` s6: The search's end at x's previous entry into the intersection is read as any earlier observation at which x occupies the intersection, whichever place that visit came through.
- `NRS_484B_250_4_o1` s6: Where several stop lines (or several crosswalks) are recorded as marking the approach carrier, a halt at any one of them meets the duty.
- `NRS_484B_600_1a` b3: 'the sight distance at x's place' and 'the curvature at x's place' are read on each lane x occupies (st.lane, rel.occupies), the regions the width bound reads; where x occupies no mapped lane, sight distance and curvature set no bound.
- `NRS_484B_307_9b_o1` b7: Where x occupied several approach carriers into the intersection at the observation before its entry, the halt is required at the place of each carrier, rather than leaving the verdict unknown where the carriers' places give different verdicts.
- `NRS_484B_307_9b_o1` b7: The approach start that ends the search for a halt is read on the approach carrier itself (the carrier the mark is recorded as marking for this approach), not on another carrier the same mark is recorded as marking.
