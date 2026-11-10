# Plan — batch 02 (iteration 001)

Eight law lines, fourteen nodes, two new concept records (`drv.motion.stopped`, `drv.motion.turning_left`), no law-local aggregates, no gaps. The validator accepts every node and concept.

## Conventions shared by the yield nodes

These nodes all apply the right-of-way definition (DEF-NRS-484A-210, "danger of a crash"): NRS_484B_250_1, 253_o1/o2, 257_1_o2, 263_o1/o2 and 270_3_o1, plus the "cautiously" standard of 250_4_o2.

- **The standard.** The words "the right-of-way" are a separate `standard` span. They are operationalized as a predicted conflict: `prim.closest_approach_within` and `prim.closest_approach_distance` with `p.conflict_time_horizon` and `p.conflict_centre_clearance` (traffic-conflict technique).
- **The duty.** "Shall yield" is the single obligation span. It is read as: the subject does not move (`drv.motion.moving`) where the yield is owed (into or within the intersection, at the entry to or exit from the controlled-access highway, on the bicycle lane) while it is in predicted conflict with a party owed precedence.
- **The parties.** The validator requires exactly one obligation span per node, so the words naming whom the subject yields to are `condition` spans. That party is quantified in the applicability and bound again, with its whole selection, in the obligation. As a result, a scene with no such party is `not_applicable`, not `compliant`.
- **"Immediate hazard".** Read by gap acceptance: distance (to the intersection, or the body gap) is at most speed × `p.immediate_hazard_time_gap`. A ratio would need a measured divisor, so the comparison is written as a product.
- **Approach direction.** "From the opposite direction" is read through the approach carriers' `st.lane_direction`, as `rel.oncoming`'s contract requires, with `p.opposed_approach_cos_tolerance`.
- **What would reverse this:** a label set that treats a stationary subject in a conflict as failing to yield, or that requires the yield to be shown upstream before entry. Either would call for a slowing or deceleration bound on the approach.

## Nodes

**NRS_484B_250_4_o1 — stop at an inoperative signal (rule 4c).**
- **Event and place.** The event is the entry into an intersection whose controlling signal heads are installed, uncovered and `dev.inoperative` at that entry. The place follows the words' order: the stop line, then the near-side crosswalk, then the carrier's entrance end where `st.sight_along_way` along the through highway meets `p.approach_view_sight_distance`.
- **Segmentation.** The place words and "proceed as if a stop sign…" make up one obligation span. The view clause, together with "on the through highway", is the `standard` span.
- **Readings and scenario.** The through highway is read as any way through the intersection that the approach carrier does not lie on, since every entrance is treated as stop-controlled (a status reading). The obligation states the history bound in full, and a `history_boundary` scenario is planned.
- **Reversal:** an operator decision that "nearest point with a view" means a point upstream of the edge rather than the edge itself.

**NRS_484B_250_4_o2 — proceed cautiously, yielding.**
- **Referring condition.** "After making such a stop" (s7) refers to the stop defined by the sibling words (s6). It keeps that stop's full qualification: a halt at the governing place (stop line / crosswalk / entrance end with the view bound), within `p.stop_point_tolerance` upstream, on the approach since that approach began.
- **Why not composed.** It is not written as compliance with o1. The words require the act itself, and o1 is judged only at the entry observation, so it would not be engaged at the later observations this node judges.
- **Caution.** "Cautiously," is a standard read only through the yield the words attach to it (disclosed as a narrowing).
- **Previously completed a stop.** This is the order of the two halts' onsets.
- **Reversal:** a reviewer who reads "cautiously" as a separate manner-of-driving standard. That would make it a care standard and the node a surrogate.

**NRS_484B_250_1 — yield to a vehicle that has entered from a different highway.**
- **"Has entered from".** Read as: the other vehicle has occupied the intersection continuously since it was on a carrier entering it, on a highway the subject's carrier does not lie on.
- **Device exception.** Devices "controlling" an intersection are limited to signals, stop signs and yield signs that govern it or an approach to it. The definition of official traffic-control device is quoted, and markings and warning signs are named as left out.
- **"Except as otherwise provided in subsection 4".** This is an `unless` composition with NRS_484B_250_4_o1 and _o2 that suspends only the device exception (s8). At an inoperative-signal intersection the yield therefore applies.
- **Left-turn exception.** The opposite-direction / left-turn exception applies per vehicle. "Is intending to" is carried by `int.turn_left`; "is making a left turn" by the new `drv.motion.turning_left` inside the intersection.
- **Reversal:** a reading that subsection 4 also overrides the left-turn exception. That would add a second `unless` scoping s9–s11.

**NRS_484B_253_o1 — the left-turner yields.**
- **Applicability.** The subject is within the intersection and has a declared `int.turn_left` there.
- **Who is yielded to.** Opposite-direction vehicles within the intersection, or close enough to be an immediate hazard.

**NRS_484B_253_o2 — oncoming drivers yield to the turner.**
- **Composed condition.** "Having so yielded" is compliance with NRS_484B_253_o1, with its x mapped to the turner y, at every observation since y entered the intersection. That is what the words require (y's compliance), not just o1 applying.
- **Signal.** "Having given a signal when and as required" is carried as a left `sig.turn_indicator` or `sig.hand_signal` on the turner's approach. "When and as required" refers to signalling rules outside this corpus and is read inside that element.
- **Permission.** "May make such left turn" is a scope-none residue, because "the vehicle making the left turn" already requires the turn to be under way.
- **Reversal:** the signalling statute entering the corpus, which would turn the signal element into a composition.

**NRS_484B_257_1_o1 — stop or yield at a sign (rule 4c).**
- **Act.** The place and history bound are as in 250_4_o1. Under a stop sign the act is a halt; under a yield sign only, it is a halt or a slowing to at most `p.yield_sign_check_speed`. This follows the next sentence's own words, "slowed or stopped", disclosed on the obligation span.
- **Exceptions.** A police officer directing, or a traffic signal that is neither inoperative nor dark, governing the approach or the intersection.
- **Traffic aggregate.** "Traffic" in the exception is claimed as the admitted traffic aggregate, with x as a member of that traffic.

**NRS_484B_257_1_o2 — yield to through-highway traffic after the stop.**
- **"After having stopped".** The words name a stop but no place. It is carried as a halt on the approach outside the intersection; under a yield sign, "slowed" is a standard bounded by the same check speed.
- **Through-highway vehicles.** Those that entered from the through highway, or are approaching on it as an immediate hazard.
- **Timing.** The duty is judged while the subject moves across or within the intersection, which is what the words "during the time" say.

**NRS_484B_263_o1 / _o2 — entering or exiting a controlled-access highway.**
- **"About to enter or exit".** An imminent movement, read by the movement it leads to: the entry into or exit from the `st.controlled_access` region (an `observable_reading` of category `intention`).
- **"The highway".** Read as the highway being entered (disclosed).
- **o1.** Covers vehicles whose proximity is an immediate hazard at that event.
- **o2.** The second "shall", "continue to yield … until … reasonable safety", is its own node. "That traffic" keeps its referent's qualifications: the vehicles that were an immediate hazard during the run before the event. "Reasonable safety" is read as no predicted conflict.
- **Reversal:** a reading that exit means moving from the through lanes onto the exit lane. The ontology cannot tell a ramp from the mainline, so that reading would need an atom gap.

**NRS_484B_297_6_o1 / _o2 — the pedestrian detour.**
- **Obligations.** Only (a) and (d) are duties; (b) and (c) and the opening "may proceed" are permissions.
- **Trigger.** An obstruction is a `st.obstruction` within `p.obstruction_encounter_reach` while the pedestrian is on the sidewalk. A missing or impassable sidewalk section has no atom, and a trigger span cannot be a residue, so it is the assumption `asm.sidewalk_section_missing_or_impassable`. "With due care" (both nodes) and permission (b) (in o1) are scope-none residues: the duty is the same whether or not they hold.
- **o1.** The pedestrian stays within `p.pedestrian_detour_side_distance` of the sidewalk. Exception (c) is the bicycle lane together with `asm.area_beside_bicycle_lane_impassable`.
- **o2.** Being off the sidewalk and clear of every obstruction for the whole `p.sidewalk_return_time` window is not "as soon as practicable".
- **Reversal:** an ontology atom for a missing or impassable sidewalk section, which would replace the assumption.

**NRS_484B_270_3_o1 — motor vehicles yield on the bicycle lane.**
- **Parties.** Bicycles, electric bicycles and electric scooters (each its admitted aggregate), and pedestrians "as provided in subsection 6".
- **Pedestrian composition.** The pedestrian part is a `condition` composition with NRS_484B_297_6_o2 (x mapped to y). It deliberately does not use _o1: exception (c) of _o1 is exactly the pedestrian in the bicycle lane, so `ruleApplies` of _o1 would be false for the very pedestrian the words protect. _o2's applicability is the detour itself.
- **No aggregate for the lane words.** "Provided for bicycles, …" names the lane's purpose, so no aggregate is claimed for those words.

**NRS_484B_270_3_o2 — stay out of the bicycle lane, with exceptions (a)–(f).**
- **The prohibition.** "Enter, stop, stand, park or drive within" jointly cover every observation at which the footprint overlaps the lane, so the prohibition is read as occupancy (disclosed).
- **Observable exceptions.** (a) a driveway or alley entrance during the stay; (c) a predicted conflict with other traffic when the stay began (a `purpose` reading); (e) a police officer's direction governing the region.
- **Assumed exceptions.** (b) disabled vehicle, (d) official duties and (f) emergency are not observable and are not among the five reading categories. They are therefore the assumptions `asm.vehicle_disabled`, `asm.performing_official_duties` and `asm.emergency`.
- **Structure.** The exceptions sit in the applicability and are read only where the vehicle is in the lane. A vehicle outside every lane is therefore decided as compliant whatever the assumptions say.

**NRS_484B_270_4 — no entering an intersection from the bicycle lane.**
- **"Except as otherwise provided in subsection 3".** A `condition` composition with NRS_484B_270_3_o2: this duty applies only where that rule is engaged, meaning the vehicle is in the lane and none of the (a)–(f) exceptions excuses it. `exception` would be wrong here: 270_3_o2 is engaged exactly when the vehicle is *not* excused.
- **"Proceed through".** Read at the entry.
- **Reversal:** if 270_3_o2 is coded with its exceptions inside the obligation rather than the applicability, this composition would need to become an explicit restatement of (a)–(f).

## Concept records

- **`drv.motion.stopped`** (definition DEF-NRS-484A-255, "complete cessation from movement"): speed at or below the resolution `tol`. "When required" is a residue, because it is the definition's scope and not the concept's. "Stop" in 270-3 is read under DEF-NRS-484A-260 and is subsumed by the occupancy reading, so no second record is proposed.
- **`drv.motion.turning_left`**: yaw rate above `tol`, to the left. It differs from `drv.motion.turning`, which reads the magnitude, a turn to either hand. It is used for "is making / making the left turn". `drv.motion.left_turn` was not used because it is recognized only after the heading change reaches 60°, which would miss a turn while it is under way.

## Parameters proposed

`p.stop_point_tolerance`, `p.approach_view_sight_distance`, `p.yield_sign_check_speed`, `p.conflict_time_horizon`, `p.conflict_centre_clearance`, `p.immediate_hazard_time_gap`, `p.opposed_approach_cos_tolerance`, `p.obstruction_encounter_reach`, `p.pedestrian_detour_side_distance`, `p.sidewalk_return_time`.

`p.motion_speed_tolerance` and `p.yaw_rate_tolerance` are proposed again with the values the earlier batch gave them, because the validator found them in no catalogue.

## For the operator

- **270-3 / 270-4 assumptions.** Exceptions (b), (d) and (f) of NRS 484B.270(3) are carried by trace assumptions. On a trace that does not declare them false, every bicycle-lane occupancy under NRS_484B_270_3_o2, and every intersection entry from the lane under NRS_484B_270_4, is `unknown`. An atom for a disabled vehicle, or a source convention that declares these facts, would make them decidable.
- **297-6 assumptions.** The missing or impassable sidewalk section, and the impassable area beside the bicycle lane, have no atom and are carried by assumptions. If the ontology gains an atom for sidewalk passability, these spans should move onto it.
- **Ramp vs mainline.** `st.controlled_access` covers the highway together with its entrance and exit lanes, so a source cannot tell a ramp from the mainline. NRS 484B.263 is therefore judged at entry into, or exit from, the whole controlled-access region.
- **Centre-distance clearance.** `p.conflict_centre_clearance` is a distance between centres, so one value has to serve car–car, car–bicycle and car–pedestrian pairs. Its proposed value should be reviewed against the labelled conflicts.
