# Feedback from iteration 2

concept `drv.motion.left_turn_through_region`: re-proposed by a repair session
concept `drv.motion.circulating_clockwise_about`: re-proposed by a repair session
concept `drv.motion.right_turn_through_region`: re-proposed by a repair session
concept `drv.motion.right_turn`: re-proposed by a repair session
concept `drv.lane.entering_adjacent_lane`: re-proposed by a repair session
concept `drv.interaction.overtake_pass`: re-proposed by a repair session
concept `drv.motion.left_turn`: re-proposed by a repair session
concept `drv.lane.heading_left_of_carrier`: coded again, it was held
concept `drv.motion.complete_halt`: coded again, it was held
concept `drv.motion.parked`: coded again, it was held
concept `drv.interaction.overtake_pass_on_right`: coded again, it was held
concept `drv.motion.right_turn`: no node of this plan uses it; not coded
concept `drv.lane.heading_left_of_carrier` returned by the validator — drv.lane.heading_left_of_carrier: same argument sorts and the same atoms as accepted `drv.lane.heading_right_of_carrier`; reuse it, or state `differs_from: {concept, why}`
`NRS-484B-413-2`: a held node no longer validates beside the current plan; returned to the planner, no attempt counted
concept `drv.motion.complete_halt`: gate OK — 3 witnesses, 1 names, reads 1 atom(s)
concept `drv.motion.circulating_clockwise_about`: gate OK — 3 witnesses, 4 names, reads 4 atom(s)
concept `drv.motion.right_turn_through_region`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.lane.entering_adjacent_lane`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.left_turn_through_region`: gate OK — 3 witnesses, 3 names, reads 3 atom(s)
concept `drv.motion.left_turn_through_region`: accepted; the review's notes are recorded on it — The body agreed with the contract on both tested passages: a fully observed 90-degree left turn and the same entry-to-exit change preceded by a right turn before entry. Neither test established a …
concept `drv.motion.parked`: gate OK — 3 witnesses, 2 names, reads 2 atom(s)
concept `drv.motion.parked`: accepted; the review's notes are recorded on it — The harness requires consecutive observations in a look-back window to be at most half the window's length apart. The contract states no sampling-gap limit, but the harness rejected the sparse-window …; The boundary test agreed with the contract: a speed above tolerance exactly min_duration before the current observation makes the body fail.
concept `drv.motion.left_turn`: gate OK — 3 witnesses, 2 names, reads 1 atom(s)
concept `drv.motion.left_turn`: accepted; the review's notes are recorded on it — dismissed: divergence 1 (holds_wrongly) at t=6000 ms: A continuous leftward turn is already under way at t=0 and is still under way at t=4000 ms; the first stopped observation is t=6000 ms. The act …
concept `drv.interaction.overtake_pass`: gate OK — 3 witnesses, 5 names, reads 5 atom(s)
concept `drv.interaction.overtake_pass`: accepted; the review's notes are recorded on it — Tested a pass recognized one second after the recording begins, within a two-second window. The observed aligned-ahead and first-behind observations suffice: the body holds, agreeing with the contract …
concept `drv.interaction.overtake_pass_on_right`: gate UNEXPRESSED — `with their headings aligned within same_dir_cos` (no_atom): The onset of the act (the last observation of the window behind at which b was ahead of a with their headings aligned), from which the side-by-side observations the recognition reads are counted, need; the vocabulary or the language cannot state these words: the repair session retypes a formal the body cannot honour, or withdraws the concept naming what is missing
`NRS_484B_210_2`: held — uses ['drv.interaction.overtake_pass_on_right'], pending (under repair or waiting); no attempt counted
`NRS_484B_210_3`: held — uses ['drv.interaction.overtake_pass_on_right'], pending (under repair or waiting); no attempt counted
`NRS_484B_250_1`: not coded, composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_250_2`: not coded, composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_257_2_o1`: not coded, composes or calls `NRS_484B_257_1_o1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_267_2a`: not coded, composes or calls `NRS_484B_600_1a` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_2b_o1`: not coded, composes or calls `NRS_484B_213_1` (unpublished), `NRS_484B_213_2a` (unpublished), `NRS_484B_213_2b` (unpublished), `NRS_484B_213_2c` (unpublished), `NRS_484B_217_2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_2b_o2`: not coded, composes or calls `NRS_484B_213_1` (unpublished), `NRS_484B_213_2a` (unpublished), `NRS_484B_213_2b` (unpublished), `NRS_484B_213_2c` (unpublished), `NRS_484B_217_2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_2b_o3`: not coded, composes or calls `NRS_484B_213_1` (unpublished), `NRS_484B_213_2a` (unpublished), `NRS_484B_213_2b` (unpublished), `NRS_484B_213_2c` (unpublished), `NRS_484B_217_2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_287_1c`: not coded, composes or calls `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_287_1d`: not coded, composes or calls `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_287_1e`: not coded, composes or calls `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1a`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1b`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d1`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d2`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d3_o1`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d3_o2`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d4_o1`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d4_o2`: not coded, composes or calls `LVMC_11_30_060_A` (unpublished), `LVMC_11_30_060_B` (unpublished), `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), `LVMC_11_46_030_o1` (unpublished), `LVMC_11_46_030_o2` (unpublished), `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1d` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_2b`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o1` (unpublished), `NRS_484B_283_1d3_o2` (unpublished), `NRS_484B_283_1d4_o1` (unpublished), `NRS_484B_283_1d4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_4b`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o2` (unpublished), `NRS_484B_283_1d4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_8b`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o2` (unpublished), `NRS_484B_283_1d4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_8a_o2`: not coded, composes or calls `NRS_484B_307_8d` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9a_o1`: not coded, composes or calls `NRS_484B_307_9b` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9a_o2`: not coded, composes or calls `NRS_484B_307_9b` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9c`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o1` (unpublished), `NRS_484B_283_1d4_o1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_777_1_o1`: not coded, composes or calls `NRS_484B_785_1a` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_267_2f_o1`: not coded, composes or calls `NRS_484B_267_1a` (unpublished), `NRS_484B_267_1b_o1` (unpublished), `NRS_484B_267_1b_o2` (unpublished), `NRS_484B_267_1c` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`LVMC_11_12_070_B` proposed `p.conflict_horizon` = 3.0 s: time-to-collision threshold of the traffic-conflict technique: a closest approach later than this is not a present dange
`LVMC_11_12_070_B` proposed `p.conflict_centre_clearance` = 3.0 m: centre-to-centre distance at the closest approach below which the bodies of a passenger car and another road user are ta
`LVMC_11_12_070_B` proposed `p.halt_speed_tolerance` = 0.1 m/s: the speed at or below which a sampled speed counts as no movement: the source's speed resolution
`LVMC_11_20_060_o1` proposed `p.stop_point_tolerance` = 2.0 m: the body-to-mark gap within which a halt counts as at the mark: a stop line's set-back before a crossing plus a placemen
`LVMC_11_30_030` proposed `p.overtake_window` = 10.0 s: the longest duration of an overtaking manoeuvre on an urban street, from having the overtaken vehicle ahead to having it
`LVMC_11_30_030` proposed `p.overtake_same_direction_cos` = 0.9 ratio: cosine of the largest heading difference (about 25 degrees) at which two vehicles count as travelling in the same direct
`LVMC_11_30_140_B_o1` proposed `p.blind_person_approach_reach` = 30.0 m: the centre distance within which a moving road user has approached a pedestrian carrying a white cane or led by another 
`LVMC_11_30_140_B_o1` proposed `p.immediate_stop_window` = 4.0 s: the longest time from the moment a stop is due until the road user is at rest for the stop to be immediate: a 1 s percep
`LVMC_11_40_120` proposed `p.rider_crossing_motion_cos` = 0.94 ratio: largest absolute cosine between a rider's velocity and a carrier's designated direction at which the rider counts as mov
`LVMC_11_40_120` proposed `p.usable_path_width_min` = 1.2 m: the narrowest width of a bicycle path at which one bicycle or scooter rider can operate on it: the essential operating s
`LVMC_11_43_010_A` proposed `p.roundabout_clockwise_sin_tol` = 0.26 ratio: the share of a vehicle's speed across the line to the roundabout's centre at or below which its motion counts as towards
`LVMC_11_38_030`: gate OK — 6 witnesses, 5 names, composes nothing
`LVMC_11_40_180_A`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter]
`LVMC_11_40_180_A`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`LVMC_11_48_060` proposed `p.delivery_halt_min_duration` = 60.0 s: the shortest halt counted as a pick-up or delivery stop en route rather than a halt in traffic: the short end of a goods
`LVMC_11_43_010_A`: gate WITNESS_FAIL — branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-320::vehicle]
`LVMC_11_43_010_A`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`LVMC_11_52_030_A` proposed `p.queue_halt_gap` = 5.0 m: the gap between bodies to a road user ahead in the same lane within which a halt is a halt behind other traffic: the spa
`LVMC_11_52_030_A` proposed `p.mail_drop_box_reach` = 3.0 m: the ground distance from a halted vehicle's body to a mail drop box within which a driver can post mail from the vehicle
`LVMC_11_52_030_A` proposed `p.mail_deposit_max_halt` = 60.0 s: the longest halt counted as expeditious deposit of mail into a drop box: pull up, post, pull away
`LVMC_11_30_090`: gate OK — 7 witnesses, 9 names, composes nothing; narrowings declared by the coder: 1
`LVMC_11_20_060_o1`: gate OK — 7 witnesses, 7 names, composes nothing
`LVMC_11_52_040_A` proposed `p.standing_min_duration` = 60.0 s: the longest halt counted as receiving or discharging passengers or loading rather than standing: a passenger pick-up dwe
`LVMC_11_52_040_A` proposed `p.parked_heading_cos` = 0.97 ratio: cosine of the largest angle (about fourteen degrees) between a standing vehicle's heading and its carrier's designated d
`LVMC_11_40_180_C_o1`: gate WITNESS_FAIL — branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter]
`LVMC_11_40_180_C_o1`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`LVMC_11_52_060` proposed `p.parking_min_duration` = 180.0 s: the longest halt counted as temporary, as for loading or unloading: a common time limit of a passenger loading zone
`LVMC_11_30_140_B_o1`: gate OK — 7 witnesses, 6 names, composes nothing
`LVMC_11_52_070` proposed `p.parking_space_angle_resolution` = 5.0 deg: the bay angle at or below which a mapped parking bay counts as parallel to the curb rather than angled: the source's ang
`LVMC_11_40_120`: gate OK — 14 witnesses, 14 names, composes nothing
`LVMC_11_52_030_B`: gate WITNESS_FAIL — branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-070::commercial_vehicle, aggregate_unresolved:DEF-LVMC-11-02-140::taxicab]; branch_2: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-070::commercial_vehicle, aggregate_unresolved:DEF-LVMC-11-02-140::taxicab]
`LVMC_11_52_030_B`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`LVMC_11_52_040_A`: gate OK — 6 witnesses, 10 names, composes nothing
`LVMC_11_52_136`: gate OK — 5 witnesses, 5 names, composes nothing
`LVMC_11_60_030_A4` proposed `p.curb_parallel_cos` = 0.97 ratio: cosine of the largest angle (about fourteen degrees) between a stopped bus's heading and its carrier's designated direct
`LVMC_11_46_030_o2`: gate OK — 8 witnesses, 14 names, composes nothing
`LVMC_11_52_060`: gate OK — 5 witnesses, 11 names, composes nothing
`LVMC_11_40_180_C_o2`: gate OK — 10 witnesses, 11 names, composes nothing
`LVMC_11_52_070`: gate OK — 8 witnesses, 11 names, composes nothing
`LVMC_11_52_340`: gate OK — 6 witnesses, 7 names, composes nothing
`LVMC_11_43_010_C2`: gate OK — 5 witnesses, 7 names, composes nothing
`LVMC_11_60_040`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-140::taxicab]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-140::taxicab]; blind: unknown for [aggregate_unresolved:DEF-LVMC-11-02-140::taxicab], not for an atom the manifest masks; the manifest masks kin.speed; branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-140::taxicab]
`LVMC_11_60_040`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_127_2` proposed `p.truck_space_open_time` = 30.0 s: the time a following heavy vehicle needs to open a space behind a leader that has come ahead of it, easing off by a few 
`LVMC_11_52_030_A`: gate WITNESS_FAIL — branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus, aggregate_unresolved:DEF-LVMC-11-02-150::shuttle_bus, aggregate_unresolved:DEF-LVMC-11-02-090::limo]; branch_5: expected not_applicable, got compliant
`LVMC_11_52_030_A`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_153_2` proposed `p.door_swing_reach` = 1.0 m: lateral reach of an open passenger-car side door beyond the vehicle body (a front door opens about 0.9 to 1.1 m)
`NRS_484B_110`: gate OK — 4 witnesses, 4 names, composes nothing
`NRS_484B_203_1_o1` proposed `p.oncoming_heading_cos` = 0.9 ratio: cosine of the largest angle off exactly opposed headings (about 25 degrees) at which two vehicles count as proceeding in
`LVMC_11_60_030_A4`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus], not for an atom the manifest masks; the manifest masks st.region_geometry; branch_1: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-LVMC-11-02-150::tour_bus]
`LVMC_11_60_030_A4`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_203_1_o2` proposed `p.meeting_horizon` = 5.0 s: the time ahead within which two vehicles closing head-on on a narrow two-way road count as meeting, so that each keeps t
`NRS_484B_203_1_o2` proposed `p.lateral_position_tolerance` = 0.3 m: the lateral margin within which a vehicle body counts as at a line or an edge: lane-keeping variability of a driven vehi
`LVMC_11_46_030_o1`: gate OK — 9 witnesses, 14 names, composes nothing
`NRS_484B_208_1` proposed `p.left_lane_move_over_time` = 10.0 s: the time a driver needs, once a faster vehicle closes from behind, to check the mirrors, signal and move one lane to the
`LVMC_11_40_140_o1`: gate OK — 13 witnesses, 8 names, composes nothing
`NRS_484B_213_1` proposed `p.passing_sight_time` = 11.0 s: the MUTCD minimum passing sight distance (Table 3B-1, the warrant for a no-passing zone) divided by the prevailing speed
`LVMC_11_52_300`: gate BARE_LITERAL — formula literals [('60', 'second'), ('1800', 'second'), ('3600', 'second'), ('21600', 'second')] ≠ the node's declared literals [('1800', 'second'), ('3600', 'second'), ('21600', 'second')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
`LVMC_11_52_300`: gate BARE_LITERAL — sent to a node repair session; no attempt counted
`LVMC_11_48_060`: gate OK — 6 witnesses, 9 names, composes nothing
`LVMC_11_43_010_C1`: gate BARE_LITERAL — formula literals [('1', 'count')] ≠ the node's declared literals []; a figure the law states is declared on its span, any other magnitude belongs in the reading
`LVMC_11_43_010_C1`: gate BARE_LITERAL — sent to a node repair session; no attempt counted
`NRS_484B_220_2`: gate OK — 4 witnesses, 4 names, composes nothing
`NRS_484B_153_2`: gate OK — 9 witnesses, 6 names, composes nothing
`LVMC_11_30_030`: gate OK — 12 witnesses, 13 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_113_3`: gate OK — 8 witnesses, 8 names, composes nothing
`NRS_484B_203_1_o1`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.bearing
`NRS_484B_203_1_o1`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`LVMC_11_30_140_B_o2`: gate OK — 7 witnesses, 7 names, composes nothing
`NRS_484B_257_1_o1` proposed `p.yield_line_speed_max` = 4.2 m/s: the speed at or below which a vehicle at the place of a yield sign counts as having slowed: the speed from which a passe
`NRS_484B_203_1_o2`: gate OK — 13 witnesses, 15 names, composes nothing
`NRS_484B_223_1b`: gate OK — 9 witnesses, 10 names, composes nothing
`LVMC_11_60_090`: gate OK — 5 witnesses, 11 names, composes nothing
`NRS_484B_600_1a` proposed `p.driver_reaction_time` = 1.5 s: perception-reaction time of an alert driver to an expected hazard in the stopping-distance model
`NRS_484B_600_1a` proposed `p.curve_lateral_accel_max` = 3.0 m/s^2: the lateral acceleration a passenger vehicle sustains on a curve within comfortable side friction on a dry or wet paved 
`NRS_484B_600_1a` proposed `p.lane_keeping_heading_error` = 0.03 ratio: the sine of the heading error (about 1.7 degrees) that a driver's lane keeping leaves uncorrected, so that the vehicle d
`NRS_484B_600_1a` proposed `p.lane_departure_time_min` = 1.0 s: the shortest time to line crossing a driver tolerates before correcting its lateral drift: the warning threshold of lane
`NRS_484B_600_1a` proposed `p.low_beam_sight_reach` = 50.0 m: the distance ahead a passenger-car low beam lights the road in darkness enough to see an obstacle
`NRS_484B_223_3a`: gate OK — 7 witnesses, 9 names, composes nothing
`NRS_484B_127_2`: gate OK — 12 witnesses, 10 names, composes nothing
`NRS_484B_270_2a_o1` proposed `p.rider_evasive_decel` = 2.0 m/s^2: the longitudinal deceleration of a bicycle or scooter rider beyond which its braking counts as an evasive reaction to an
`NRS_484B_223_3b`: gate OK — 4 witnesses, 6 names, composes nothing
`NRS_484B_223_3c`: gate OK — 4 witnesses, 8 names, composes nothing
`NRS_484B_213_2a` proposed `p.curvature_resolution` = 0.0005 1/m: the horizontal curvature at or below which a mapped roadway reads as straight: the curvature resolution of map centrelin
`NRS_484A_450_2`: gate OK — 10 witnesses, 13 names, composes nothing
`NRS_484B_223_4b`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_213_2a`: gate OK — 10 witnesses, 15 names, composes nothing
`NRS_484A_450_3`: gate OK — 12 witnesses, 16 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_280_1c` proposed `p.pedestrian_near_reach` = 3.0 m: the ground distance from a pedestrian's body to a place, a region or a vehicle within which the pedestrian is near it: a
`NRS_484B_267_1b_o2`: gate UNEXPRESSED — u4 (no_atom): 'visible from the front' (borrowed from DEF-NRS-484A-480-3 via u5; the record's 'facing front'): the formula surface reads a warning lamp only by colour and mode (sig_warning_lamp [x, colour, mode]); ; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_267_1b_o2`: gate UNEXPRESSED — sent to a node repair session; no attempt counted
`NRS_484B_600_1a`: gate OK — 9 witnesses, 15 names, composes nothing; narrowings declared by the coder: 2
`NRS_484B_270_2a_o1`: gate OK — 5 witnesses, 8 names, composes nothing
`NRS_484B_293` proposed `p.pedestrian_lateral_tolerance` = 0.3 m: the lateral margin within which a pedestrian's reference point counts as on a line that divides a region or a way: half 
`NRS_484B_227_1_o3`: gate OK — 10 witnesses, 11 names, composes nothing
`NRS_484B_213_2c`: gate OK — 5 witnesses, 14 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_213_2b`: gate OK — 7 witnesses, 13 names, composes nothing
`NRS_484B_270_2a_o2`: gate OK — 13 witnesses, 17 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_293`: gate OK — 9 witnesses, 13 names, composes nothing
`NRS_484B_250_4_o1`: gate OK — 13 witnesses, 15 names, composes nothing
`LVMC_11_30_060_B`: gate OK — 8 witnesses, 14 names, composes nothing
`NRS_484B_307_12b`: gate OK — 7 witnesses, 12 names, composes nothing
`NRS_484B_270_7b`: gate UNCLAIMED_ATOM — kin_heading; kin_position; rel_longitudinal_overlap; rel_same_direction
`NRS_484B_270_7b`: gate UNCLAIMED_ATOM — sent to a node repair session; no attempt counted
`NRS_484B_208_1`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `turnAtS` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked); in the formula, the quantified variable `turnAtR` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_208_1`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`LVMC_11_30_060_A`: gate VACUOUS — obligation leaf 7: cmp TrafficSpec.Term.measure "kin_speed" [TrafficSpec.Arg.var "subject"] TrafficSpec.Term.param "p.halt_speed_tolerance"
`LVMC_11_30_060_A`: gate VACUOUS — sent to a node repair session; no attempt counted
`NRS_484B_267_1c`: gate UNEXPRESSED — u4 (no_atom): the record reads u4 (with the borrowed u5 words 'at least one flashing red warning lamp visible from the front') as sig.warning_lamp of colour red, mode flashing, facing front; the formula forms of si; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_267_1c`: gate UNEXPRESSED — sent to a node repair session; no attempt counted
`NRS_484B_307_12a`: gate OK — 10 witnesses, 12 names, composes nothing
`NRS_484B_257_1_o1`: gate OK — 14 witnesses, 19 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_307_5a_o1`: gate OK — 9 witnesses, 11 names, composes nothing
`NRS_484B_280_1c`: gate OK — 14 witnesses, 20 names, composes nothing
`NRS_484B_213_1`: gate OK — 15 witnesses, 21 names, composes nothing
`LVMC_11_12_070_B`: gate OK — 20 witnesses, 16 names, composes nothing
`NRS_484B_307_4a_o1`: gate OK — 9 witnesses, 11 names, composes nothing
`NRS_484B_413_3` proposed `p.sudden_decel_min` = 3.4 m/s^2: the longitudinal deceleration beyond which a decrease of speed counts as sudden: the comfortable deceleration most drive
`NRS_484B_413_3` proposed `p.rear_signal_reach` = 30.0 m: the gap between bodies within which a following vehicle in the same lane is immediately to the rear of a vehicle: two se
`NRS_484B_413_3` proposed `p.stop_signal_lead_window` = 3.0 s: the time behind the onset of a halt or a sudden deceleration within which a stop or slow signal shown counts as given fi
`NRS_484B_267_2d`: gate UNEXPRESSED — s3 (no_atom): The borrowed words of s4 ('at least one flashing red warning lamp visible from the front'), which the record reads as a lit sig.warning_lamp red, flashing, facing front: no formula can read a lamp's f; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_267_2d`: gate UNEXPRESSED — sent to a node repair session; no attempt counted
`NRS_484B_307_8e`: gate OK — 7 witnesses, 11 names, composes nothing
`NRS_484B_307_8a_o1`: gate OK — 10 witnesses, 14 names, composes nothing
`NRS_484B_410_o1`: gate OK — 10 witnesses, 14 names, composes nothing
`NRS_484B_450_1k` proposed `p.free_passage_width` = 3.0 m: the free lateral width one passing vehicle needs beside a standing vehicle: the width of a design passenger or single-un
`NRS_484B_410_o2`: gate OK — 8 witnesses, 14 names, composes nothing
`NRS_484B_450_1l` proposed `p.edge_standing_gap` = 0.6 m: the gap between a standing vehicle's body and the curb or roadway edge within which the vehicle counts as standing at th
`NRS_484B_310_1`: gate OK — 10 witnesses, 14 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_413_3`: gate OK — 13 witnesses, 21 names, composes nothing
`NRS_484B_307_7a_o1`: gate OK — 11 witnesses, 14 names, composes nothing
`NRS_484B_450_1g`: gate OK — 14 witnesses, 26 names, composes nothing
`NRS_484B_450_1h`: gate OK — 12 witnesses, 23 names, composes nothing
`NRS_484B_450_1m`: gate OK — 18 witnesses, 18 names, composes nothing
`NRS_484B_250_4_o2`: gate OK — 9 witnesses, 14 names, composes NRS_484B_250_4_o1
`NRS_484B_450_1j`: gate OK — 13 witnesses, 23 names, composes nothing
`NRS_484B_450_1k`: gate OK — 12 witnesses, 23 names, composes nothing
`NRS_484B_450_1l`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.bearing
`NRS_484B_450_1l`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_477_1a`: gate OK — 12 witnesses, 14 names, composes nothing
`NRS_484B_507_1` proposed `p.commercial_loading_max_halt` = 1800.0 s: the longest halt of a commercial vehicle counted as expeditious loading or unloading of goods or passengers: the thirty-
`NRS_484B_507_1` proposed `p.zone_entry_wait_reach` = 10.0 m: the ground distance from a halted vehicle's body to a curb zone within which the vehicle counts as waiting to enter the 
`NRS_484B_400_2b`: gate OK — 9 witnesses, 13 names, composes nothing
`NRS_484B_490`: gate OK — 7 witnesses, 8 names, composes nothing
`NRS_484B_450_1o`: gate OK — 16 witnesses, 23 names, composes nothing
`NRS_484B_533` proposed `p.grade_resolution` = 0.005 ratio: the longitudinal slope at or below which a roadway reads as level: the grade resolution of map elevation profiles
`NRS_484B_533` proposed `p.steer_angle_resolution` = 2.0 deg: the front-wheel steering angle at or below which a parked vehicle's wheels read as straight: the steering-angle sensor r
`NRS_484B_457_1`: gate OK — 13 witnesses, 27 names, composes nothing
`NRS_484B_497`: gate OK — 8 witnesses, 19 names, composes nothing
`NRS_484B_493`: gate OK — 8 witnesses, 18 names, composes nothing
`NRS_484B_500`: gate OK — 20 witnesses, 23 names, composes nothing
`NRS_484B_477_1b`: gate OK — 17 witnesses, 19 names, composes nothing
`NRS_484B_560_7a`: gate OK — 5 witnesses, 5 names, composes nothing
`NRS_484B_533`: gate OK — 8 witnesses, 12 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_363_4`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.bearing
`NRS_484B_363_4`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_785_1a`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; blind: unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter], not for an atom the manifest masks; the manifest masks kin.speed; branch_1: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS_484B_785_1a`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_257_1_o2`: gate OK — 22 witnesses, 18 names, composes NRS_484B_257_1_o1
`NRS_484B_777_3` proposed `p.abreast_gap_max` = 1.5 m: the gap between the bodies of two riders side by side within which they ride abreast in one row: the handlebar-to-handle
`NRS_484B_557_o1`: gate OK — 6 witnesses, 10 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_517`: gate WITNESS_FAIL — branch_1: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-030::bus, aggregate_unresolved:DEF-NRS-484A-270::taxicab]; branch_2: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-270::taxicab]
`NRS_484B_517`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_503`: gate OK — 13 witnesses, 24 names, composes nothing; narrowings declared by the coder: 2
`NRS_484B_307_8c`: gate OK — 12 witnesses, 27 names, composes nothing
`NRS_484D_165_3`: gate OK — 5 witnesses, 10 names, composes nothing
`NRS_484B_510`: gate OK — 13 witnesses, 27 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_587_2a`: gate WITNESS_FAIL — branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle, aggregate_unresolved:DEF-NRS-484A-280::tow_car, aggregate_unresolved:DEF-NRS-484A-030::bus]
`NRS_484B_587_2a`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484D_165_4`: gate OK — 6 witnesses, 3 names, composes nothing
`LVMC_11_16_060`: gate OK — 6 witnesses, 8 names, composes nothing
`NRS_484B_560_7b`: gate OK — 13 witnesses, 20 names, composes nothing
`LVMC_11_40_130`: gate OK — 8 witnesses, 7 names, composes nothing
`NRS_484B_627_2`: gate OK — 16 witnesses, 21 names, composes nothing
`NRS_484B_507_1`: gate OK — 18 witnesses, 27 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_557_o2`: gate OK — 7 witnesses, 14 names, composes nothing
`LVMC_11_30_050`: gate OK — 7 witnesses, 6 names, composes nothing
`LVMC_11_30_070_B`: gate OK — 8 witnesses, 6 names, composes nothing
`LVMC_11_22_010`: gate OK — 5 witnesses, 6 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_127_1` proposed `p.following_headway_dry` = 2.0 s: time headway a following driver keeps on a dry surface: the two-second rule of driver manuals
`NRS_484B_127_1` proposed `p.following_headway_wet` = 3.0 s: time headway a following driver keeps on a wet surface or in rain: the two-second rule lengthened by a second
`NRS_484B_127_1` proposed `p.following_headway_ice` = 6.0 s: time headway a following driver keeps on an icy or snow-covered surface: the tripled following time driver manuals advis
`NRS_484B_127_1` proposed `p.following_decel_dry` = 6.0 m/s^2: braking deceleration of a passenger vehicle on a dry paved surface (coefficient of friction about 0.6)
`NRS_484B_127_1` proposed `p.following_decel_wet` = 4.0 m/s^2: braking deceleration of a passenger vehicle on a wet paved surface (coefficient of friction about 0.4)
`NRS_484B_127_1` proposed `p.following_decel_ice` = 1.0 m/s^2: braking deceleration of a passenger vehicle on an icy or snow-covered surface (coefficient of friction about 0.1)
`LVMC_11_43_010_B_o2`: gate OK — 6 witnesses, 5 names, composes nothing
`NRS_484B_153_3` proposed `p.traffic_side_door_max_open` = 60.0 s: the longest time a traffic-side door stays open for immediate loading or unloading: a passenger pick-up or drop-off dwel
`LVMC_11_22_020`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_307_8a_o3`: gate OK — 9 witnesses, 27 names, composes nothing
`NRS_484B_777_3`: gate OK — 10 witnesses, 8 names, composes nothing
`LVMC_11_20_060_o2`: gate OK — 13 witnesses, 9 names, composes nothing
`NRS_484B_220_1`: gate OK — 4 witnesses, 4 names, composes nothing
`NRS_484B_153_3`: gate OK — 4 witnesses, 3 names, composes nothing
`LVMC_11_43_010_B_o1`: gate UNUSED_CLAIM — kin_speed
`LVMC_11_43_010_B_o1`: gate UNUSED_CLAIM — sent to a node repair session; no attempt counted
`LVMC_11_20_060_o3`: gate OK — 9 witnesses, 9 names, composes nothing
`NRS_484B_223_4a`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `r` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_223_4a`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_263_o2` proposed `p.merge_window` = 10.0 s: the time an entering or exiting vehicle takes, after coming onto or leaving the controlled-access highway, to complete i
`NRS_484B_587_2b`: gate VACUOUS — applicability leaf 8: atom ru_aggregate [TrafficSpec.Arg.var "subject", TrafficSpec.Arg.lit "DEF-NRS-484A-020::authorized_emergency_vehicle"] (one of 3 literal variants of this atom; none exercised); applicability leaf 14: atom ru_transit_bus [TrafficSpec.Arg.var "subject"]
`NRS_484B_587_2b`: gate VACUOUS — sent to a node repair session; no attempt counted
`NRS_484B_267_1a` proposed `p.emergency_immediate_approach_reach` = 100.0 m: centre distance within which an emergency or enforcement vehicle closing on a road user with its warning lamps flashing 
`NRS_484B_777_1_o2`: gate OK — 9 witnesses, 10 names, composes nothing
`NRS_484B_267_1b_o1` proposed `p.emergency_pullover_window` = 10.0 s: the longest time from the onset of an emergency vehicle's immediate approach until a driver has moved to the right-hand 
`NRS_484B_267_1b_o1` proposed `p.pullover_edge_gap` = 1.0 m: the gap between a vehicle body and the right-hand curb or roadway edge within which a vehicle pulled over to clear the w
`NRS_484B_127_1`: gate OK — 11 witnesses, 7 names, composes nothing
`NRS_484B_267_2b` proposed `p.emergency_pass_clearance` = 1.5 m: the gap between bodies a driver keeps while passing alongside an emergency or enforcement vehicle: a lateral passing cle
`NRS_484B_227_1_o1`: gate OK — 8 witnesses, 9 names, composes nothing
`NRS_484B_113_2`: gate OK — 7 witnesses, 7 names, composes nothing
`NRS_484B_267_2e` proposed `p.emergency_lane_change_window` = 6.0 s: the time from the onset of an approach to an emergency or enforcement vehicle until a driver has moved one lane over: a 
`LVMC_11_18_020`: gate OK — 10 witnesses, 20 names, composes nothing
`NRS_484B_227_1_o2`: gate OK — 7 witnesses, 7 names, composes nothing
`NRS_484B_270_7a` proposed `p.vehicle_evasive_decel` = 4.0 m/s^2: the longitudinal deceleration of a motor vehicle at or beyond which its braking counts as an evasive reaction to another
`NRS_484B_307_8d`: gate WITNESS_FAIL — branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS_484B_307_8d`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_263_o1`: gate WITNESS_FAIL — blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest masks; the manifest masks rel.bearing
`NRS_484B_263_o1`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_270_7a`: gate OK — 5 witnesses, 6 names, composes nothing
`NRS_484B_260`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.bearing
`NRS_484B_260`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_263_o2`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.bearing
`NRS_484B_263_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`LVMC_11_16_040`: gate OK — 15 witnesses, 18 names, composes nothing
`NRS_484B_253_o1`: gate OK — 7 witnesses, 10 names, composes nothing
`NRS_484B_270_5a`: gate OK — 10 witnesses, 5 names, composes nothing
`LVMC_11_40_140_o2`: gate OK — 11 witnesses, 11 names, composes nothing
`NRS_484B_267_2c`: gate UNEXPRESSED — s3 (no_atom): the borrowed words of DEF-NRS-484A-480-3 'visible from the front', which the record writes as a lit sig.warning_lamp facing front, cannot be stated: no atom form of the surface reads a warning lamp's ; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_267_2c`: gate UNEXPRESSED — sent to a node repair session; no attempt counted
`NRS_484B_267_1a`: gate UNEXPRESSED — u4 (no_atom): the words borrowed from u5 (DEF-NRS-484A-480-3) require the flashing red warning lamp to be 'visible from the front' (the record: facing front); the formula language's sig_warning_lamp atom reads colo; the vocabulary or the language cannot state these words: the repair session withdraws the span as a gap or re-maps it
`NRS_484B_267_1a`: gate UNEXPRESSED — sent to a node repair session; no attempt counted
`NRS_484B_267_2b`: gate OK — 16 witnesses, 20 names, composes nothing
`NRS_484B_257_2_o2`: gate OK — 13 witnesses, 16 names, composes nothing
`NRS_484B_280_1a`: gate OK — 9 witnesses, 5 names, composes nothing
`NRS_484B_400_1_o1` proposed `p.approach_lane_same_direction_cos` = 0.9 ratio: cosine of the largest angle (about twenty-five degrees) between the designated directions of two mapped lanes entering o
`NRS_484B_307_9b`: gate BARE_LITERAL — formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
`NRS_484B_307_9b`: gate BARE_LITERAL — sent to a node repair session; no attempt counted
`NRS_484B_307_2a`: gate OK — 7 witnesses, 14 names, composes nothing
`NRS_484B_363_1`: gate OK — 14 witnesses, 12 names, composes nothing
`NRS_484B_363_2`: gate OK — 13 witnesses, 12 names, composes nothing
`NRS_484B_267_1b_o1`: gate OK — 16 witnesses, 26 names, composes nothing
`NRS_484B_407` proposed `p.crest_near_reach` = 150.0 m: the ground distance from a road user's body to a crest within which the road user is on the approach to or near the cres
`NRS_484B_307_7a_o3`: gate OK — 6 witnesses, 12 names, composes nothing
`NRS_484B_560_3_o1` proposed `p.railroad_crossing_approach_reach` = 15.2 m: the ground distance from a vehicle's body to a railroad grade crossing within which the vehicle is at the crossing, on t
`NRS_484B_307_3a`: gate OK — 7 witnesses, 14 names, composes nothing
`NRS_484B_560_3_o2` proposed `p.side_by_side_same_direction_cos` = 0.9 ratio: cosine of the largest heading difference (about 25 degrees) at which two road users standing or moving side by side coun
`NRS_484B_330_1`: gate OK — 8 witnesses, 19 names, composes nothing
`NRS_484B_307_7a_o2`: gate OK — 8 witnesses, 14 names, composes nothing
`NRS_484B_307_4a_o2`: gate OK — 8 witnesses, 14 names, composes nothing
`NRS_484B_267_2e`: gate OK — 20 witnesses, 28 names, composes nothing
`NRS_484B_603_1_o1` proposed `p.curve_approach_reach` = 150.0 m: the distance a road user travels ahead within which a bend it reaches counts as one it is approaching: about the stoppin
`NRS_484B_603_1_o1` proposed `p.narrow_lane_width` = 3.0 m: the lane width at or below which a highway's lane counts as narrow: below the 3.3 to 3.6 m design lane width at which a 
`NRS_484B_560_3_o1`: gate OK — 9 witnesses, 19 names, composes nothing
`NRS_484B_307_6a`: gate OK — 12 witnesses, 8 names, composes nothing
`NRS_484B_307_5a_o2`: gate OK — 9 witnesses, 14 names, composes nothing
`NRS_484B_627_1a` proposed `p.impeding_speed_margin` = 4.5 m/s: the amount by which a vehicle's speed below the posted maximum of its way holds back the traffic immediately behind it: 
`NRS_484B_600_1e`: gate OK — 4 witnesses, 2 names, composes nothing
`NRS_484B_253_o2`: gate OK — 7 witnesses, 12 names, composes NRS_484B_253_o1
`NRS_484B_400_1_o2`: gate OK — 10 witnesses, 10 names, composes nothing
`NRS_484B_600_1c`: gate OK — 5 witnesses, 8 names, composes nothing
`NRS_484B_587_1`: gate OK — 7 witnesses, 7 names, composes nothing
`NRS_484B_400_1_o1`: gate OK — 9 witnesses, 8 names, composes nothing
`NRS_484B_403_2`: gate OK — 9 witnesses, 13 names, composes nothing
`NRS_484B_633_2`: gate OK — 6 witnesses, 11 names, composes nothing
`NRS_484B_620_2`: gate OK — 13 witnesses, 13 names, composes nothing
`NRS_484B_403_3`: gate OK — 10 witnesses, 10 names, composes nothing
`NRS_484D_400_5`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle]; idle: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-020::authorized_emergency_vehicle], not for an atom the manifest masks; the manifest masks sig.siren
`NRS_484D_400_5`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_653_1a`: gate OK — 6 witnesses, 7 names, composes nothing
`NRS_484B_560_3_o2`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.longitudinal_overlap
`NRS_484B_560_3_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_407`: gate OK — 10 witnesses, 10 names, composes nothing
`NRS_484B_363_3`: gate OK — 19 witnesses, 16 names, composes nothing
`NRS_484B_400_2a`: gate OK — 12 witnesses, 11 names, composes nothing
`NRS_486_341`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.longitudinal_overlap
`NRS_486_341`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_627_1b`: gate OK — 9 witnesses, 18 names, composes nothing
`NRS_484B_267_2f_o2`: gate WITNESS_FAIL — forbid: expected violated, got compliant
`NRS_484B_267_2f_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_486_351_1`: gate OK — 10 witnesses, 9 names, composes nothing
`NRS_484B_627_1a`: gate OK — 8 witnesses, 20 names, composes nothing
`NRS_484B_603_1_o2`: gate OK — 14 witnesses, 12 names, composes nothing
`NRS_486_351_2`: gate WITNESS_FAIL — blind: expected unknown, got violated; the manifest masks rel.longitudinal_overlap
`NRS_486_351_2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_603_1_o1`: gate OK — 12 witnesses, 29 names, composes nothing; narrowings declared by the coder: 2
dependency context changed and rechecked: `drv.motion.complete_halt`
dependency context changed and rechecked: `drv.motion.circulating_clockwise_about`
dependency context changed and rechecked: `drv.motion.right_turn_through_region`
dependency context changed and rechecked: `drv.lane.entering_adjacent_lane`
dependency context changed and rechecked: `drv.motion.left_turn_through_region`
dependency context changed and rechecked: `drv.motion.parked`
dependency context changed and rechecked: `drv.motion.left_turn`
dependency context changed and rechecked: `drv.interaction.overtake_pass`
`NRS-484B-250-4` span p1 composes accepted `NRS_484B_250_4_o1` (as: compliance)
`NRS-484B-257-1` span j composes accepted `NRS_484B_257_1_o1` (as: compliance)
`NRS-484B-307-8c` span s3 borrows from `NRS-484B-307-8a` the words “must stop before entering the crosswalk on the nearest side of the intersection where the sign or pavement marking indicates where the stop must be made, or in the absence of any such crosswalk, sign or marking, then before entering the intersection”
`NRS-484D-165-3` span t5 borrows from `NRS-484D-100-1` the words “(a) At any time from one-half hour after sunset to one-half hour before sunrise; (b) At any other time when, because of insufficient light or unfavorable atmospheric conditions, persons and vehicles on the highway are not clearly discernible at a distance of 1,000 feet ahead;”
`NRS-484D-165-3` span t8 borrows from `NRS-484D-165-3` the words “one or more lamps which, when lighted, shall display a white or amber light visible from a distance of 500 feet to the front of the vehicle, and one or more lamps which, when lighted, shall display a red light visible from a distance of 500 feet to the rear of the vehicle”
`NRS-484B-267-2b` span t7 borrows from `DEF-NRS-484A-480-3` the words “at least one flashing red warning lamp visible from the front”
`NRS-484B-267-1b` span u5 borrows from `DEF-NRS-484A-480-3` the words “at least one flashing red warning lamp visible from the front”
`NRS-484B-267-2e` span s4 borrows from `DEF-NRS-484A-480-3` the words “at least one flashing red warning lamp visible from the front”
`NRS-484B-253` span i composes accepted `NRS_484B_253_o1` (as: compliance)
`NRS-484B-400-1` span s7 borrows from `NRS-484B-223-4a` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-400-1` span s7 borrows from `NRS-484B-223-4b` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-400-1` span s7 borrows from `NRS-484B-223-4a` the words “If a highway has been designed to provide a single right lane to be used only for turning”
`NRS-484B-400-1` span s7 borrows from `NRS-484B-223-4b` the words “If a highway has been designed to provide a single right lane to be used only for turning”

## Laws by state

- blocked: 45
- planned: 175
- returned: 1

## Returned laws and why

- `NRS-484B-413-2` (attempt 0): NRS_484B_413_2: concept `drv.lane.heading_left_of_carrier` is neither accepted nor proposed in this plan (a concept record for span s6)

## Concepts by state

- accepted: 14
- returned: 3

## Returned concepts and why

- `drv.motion.right_turn` (returned, attempt 1; used by LVMC_11_40_080_o1, LVMC_11_40_080_o2): gate WITNESS_FAIL; holds (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); fails (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); blind (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it)
- `drv.interaction.overtake_pass_on_right` (returned, attempt 1; used by NRS_484B_210_1, NRS_484B_210_2, NRS_484B_210_3): gate UNEXPRESSED; `with their headings aligned within same_dir_cos` (no_atom): The onset of the act (the last observation of the window behind at which b was ahead of a with their headings aligned), from which the side-by-side observations the recognition reads are counted, need; the vocabulary or the language cannot state these words: the repair session retypes a formal the body cannot honour, or withdraws the concept naming what is missing
- `drv.lane.heading_left_of_carrier` (returned, attempt 0; used by NRS_484B_413_2): drv.lane.heading_left_of_carrier: same argument sorts and the same atoms as accepted `drv.lane.heading_right_of_carrier`; reuse it, or state `differs_from: {concept, why}`

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_210_2` waits on `drv.interaction.overtake_pass_on_right`
- `NRS_484B_210_3` waits on `drv.interaction.overtake_pass_on_right`
- `NRS_484B_217_2` waits on `NRS_484B_413_2`
- `NRS_484B_250_1` held: composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building
- `NRS_484B_250_2` held: composes or calls `NRS_484B_250_4_o1` (unpublished), `NRS_484B_250_4_o2` (unpublished), not usable for building
- `NRS_484B_257_2_o1` held: composes or calls `NRS_484B_257_1_o1` (unpublished), not usable for building
- `NRS_484B_267_2a` held: composes or calls `NRS_484B_600_1a` (unpublished), not usable for building
- `NRS_484B_270_2b_o1` waits on `NRS_484B_217_2`
- `NRS_484B_270_2b_o2` waits on `NRS_484B_217_2`
- `NRS_484B_270_2b_o3` waits on `NRS_484B_217_2`
- `NRS_484B_287_1c` held: composes or calls `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), not usable for building
- `NRS_484B_287_1d` held: composes or calls `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), not usable for building
- `NRS_484B_287_1e` held: composes or calls `LVMC_11_30_140_B_o1` (unpublished), `LVMC_11_30_140_B_o2` (unpublished), not usable for building
- `NRS_484B_283_1a` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1b` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1d1` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1d2` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1d3_o1` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1d3_o2` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1d4_o1` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_283_1d4_o2` waits on `LVMC_11_30_060_A`, `NRS_484B_287_1c`, `NRS_484B_287_1d`, `NRS_484B_287_1e`
- `NRS_484B_307_2b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o1`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_4b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_8b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_8a_o2` waits on `NRS_484B_307_8d`
- `NRS_484B_307_9a_o1` waits on `NRS_484B_307_9b`
- `NRS_484B_307_9a_o2` waits on `NRS_484B_307_9b`
- `NRS_484B_307_9c` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d4_o1`
- `NRS_484B_777_1_o1` waits on `NRS_484B_785_1a`
- `NRS_484B_267_2f_o1` waits on `NRS_484B_267_1a`, `NRS_484B_267_1b_o2`, `NRS_484B_267_1c`

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `LVMC_11_30_090` s3: The carriers of r (r itself, or an occupied st.lane on the same highway) are read existentially for compliance: moving across any one of them (drv.motion.moving_across_carrier) is crossing, not walking along; a moving pedestrian violates only where its motion is along every such carrier.
- `LVMC_11_30_030` d3: The pass's observations are read from the one after the last observation at which b was ahead of the subject with headings aligned, up to the recognition: the language has no next-observation operator to single out that last aligned-ahead observation from the earlier ones of its run, so the act's first observation, at which b is still ahead of the subject with a gap between them, is not read for the trigger.
- `NRS_484A_450_3` s4: The approach start that ends the search into the past is read with the subject on the approach carrier c itself (one of the carriers the governing mark is recorded as marking): an exit from the stopping zone upstream observed while the subject is on another carrier the same mark marks does not end the search, which then runs further back (to an approach start on c, an observation in r, or the recording's start, where it is unknown).
- `NRS_484B_600_1a` p4: 'at the subject's place' (st.sight_distance and st.curvature) is read at every lane the subject's footprint overlaps (rel.occupies), each of them bounding the speed
- `NRS_484B_600_1a` p4: the surface gap to the road user ahead in the lane is read as the distance between the nearest points of the two bodies, not one of its components
- `NRS_484B_213_2c` s3: st.sight_distance 'at the subject's point' is read off the highway region the subject occupies (rel.occupies); the view is obstructed where it is below the subject's kin.speed times p.passing_sight_time for some such highway.
- `NRS_484B_270_2a_o2` a8: 'the lane' to the rider's lane's immediate left is read beside some lane the rider occupies at the pass's start: the left lane is missing, unavailable or unsafe where it is so beside some lane the rider occupies
- `NRS_484B_257_1_o1` e: The history bound 'the subject's previous entry into X' is written as the subject's observed exit from X following that entry (rises of not rel_occupies(subject, X)): a single since cannot tell the judged entry from an earlier one at the same intersection, so the search stops at the first observation off X after the earlier entry, and an act performed while the footprint still overlaps X after an earlier entry does not count toward the next entry.
- `NRS_484B_310_1` s5: The record states the approach start that ends the search back only for marks; for the 'if none' alternative it is read the same way against the intersection's edge: the subject on a carrier entering the intersection, not overlapping it, short of it along the approach carrier's direction and farther from it than the stop-point tolerance.
- `NRS_484B_533` s5: Where two road edges lying on the highway are equally nearest the vehicle, front wheels turned beyond the resolution toward the side of either comply.
- `NRS_484B_557_o1` s5: The search's end at the subject's previous exit from the crossing is read as including the exit observation itself (the first observation at which it no longer overlaps the crossing): a halt there in the zone counts, and the search does not pass it.
- `NRS_484B_503` s1: A railway gate 'not up' is read as a gate observed lowering, down or raising; a crossing without a gate (gate state none) excuses a halt only through flashing lights.
- `NRS_484B_503` s1: A traffic signal's 'red or yellow indication' is read as circular red or yellow and red or yellow arrows of any direction (with flashing red); flashing yellow and flashing yellow arrows, which permit proceeding, are not included.
- `NRS_484B_510` s1: 'A traffic signal displaying a red or yellow indication or flashing_red' is read as a steady red or yellow indication (circular_red, circular_yellow, red_arrow, yellow_arrow) or flashing_red; flashing_yellow and flashing_yellow_arrow, cautionary indications that require no halt, are not read as a device's direction to halt.
- `NRS_484B_507_1` s1: 'A traffic signal displaying a red or yellow indication or flashing_red' is read as the circular indications circular_red and circular_yellow and flashing_red; a red or yellow arrow, which controls only the movement it points to, is not read as requiring the halt.
- `LVMC_11_22_010` h4: contact is read against every other road user only: Core's rel.contact relates two tracks, so the record's 'no structure' limb is not read
- `NRS_484B_603_1_o1` s9: The pedestrian whose presence on a roadway is a hazard that may exist is read on the roadway the subject occupies, the region that ties the pedestrian to the subject.
- `NRS_484B_603_1_o1` s4: The sight distance at the subject's place is read from every roadway the subject occupies; the stopping distance must be within each.
