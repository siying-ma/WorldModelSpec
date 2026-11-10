<!-- batch-01 -->
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

<!-- batch-02 -->
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

<!-- batch-03 -->
# Plan — batch 03 (iteration 1)

Eight laws, sixteen nodes, four new concept records, no law-local aggregates (`aggregates.jsonl` is empty). The validator accepts every node and every concept.

New concepts:
- `drv.interaction.overtaking`: a passes b side by side, on either side. It is the side-free counterpart of `drv.interaction.passing_on_right`.
- `drv.motion.left_turn_through_region` and `drv.motion.right_turn_through_region`: turn counterparts of `drv.motion.straight_through_region`. They are recognized at the exit from the region, with the heading change since entry inside a turn band.
- `drv.lane.heading_offset_from_direction`: a quantity, the signed sine of the heading's departure from a carrier's designated direction.

New parameters:
- `p.overtaking_lateral_clearance`
- `p.right_turn_min_angle`
- `p.course_change_sin_tolerance`
- `p.queue_standstill_gap`
- `p.off_roadway_reach`
- `p.free_passage_width`

Every other parameter re-proposes an earlier batch's entry with the same value and unit.

New declared facts:
- `asm.business_or_residence_district`
- `asm.school_not_in_session`
- `asm.school_out_of_operation_period`
- `asm.pupils_in_class`
- `asm.disabled_vehicle_immovable`
- `asm.halt_required_by_law`

## Nodes

**NRS_484B_270_7b.** One node. The subject is the three admitted aggregates: bicycle, electric bicycle, electric scooter. The obligation "Overtake and pass a motor vehicle" is `drv.interaction.overtaking` against the `DEF-NRS-484A-130::motor_vehicle` aggregate. The motor vehicle is quantified in the rule, not bound. "unless … safely without endangering …" is a standard that qualifies a concrete act, so the node is not a surrogate. It is operationalized two ways:
- the lateral component of `rel.surface_gap` to the overtaken vehicle must be at least `p.overtaking_lateral_clearance`;
- no other road user may be in predicted conflict with the rider (`prim.closest_approach_*` with the conflict horizon and clearance).

The overtaken vehicle is checked by body gap, not by centre-distance conflict, because two road users side by side are always within the centre clearance. The act is read only in its side-by-side phase (narrowing). Reversal signal: labels that count the approach from behind or the cut-in ahead as part of the pass. That would need an act concept with an onset and recognition.

**NRS_484B_307_9b_o1 … _o4.** The validator requires exactly one obligation span per node. The permission "may proceed … if: (1) … (4)" is therefore cut into four nodes, one per requirement.
- In each node, the movement ("proceed straight through or turn in the direction opposite …") is a trigger. It is read at the exit through `straight_through_region` (any arrow), `right_turn_through_region` (under a left arrow) or `left_turn_through_region` (under a right arrow).
- The signal display (`circular_red` with `green_arrow(left|right)`, governing the approach carrier or the intersection) is read at the entry through a past operator. The entry is the event "facing the signal may proceed" ties it to.

The four requirements:
- **o1** is the stop before entering, a rule-4c duty. Place order: the stop line recorded as marking the approach, else the near-side crosswalk marking it, else the intersection edge. The search is bounded by the approach start or the previous entry, and a `history_boundary` scenario is planned.
- **o2** is the wait. Two complete arrow cycles are counted after the halt, using the literal "two" as a count, and no `circular_green` may show during the wait. "because of a malfunction or … failed to detect" is a scope-none residue: two complete cycles without a change is exactly that failure.
- **o3** is "no other device prohibits the turn". It reads a `no_left_turn` / `no_right_turn` regulatory sign governing the approach or the intersection, with `prim.conditions_hold`. "if applicable" limits o3 to turns.
- **o4** is the yield. It means no predicted conflict while moving through the intersection with pedestrians in an adjacent crosswalk (one recorded as marking the entrance of a carrier that enters this intersection) or with other traffic in the intersection. "lawfully" is read as presence (narrowing): the other road user's lawfulness depends on rules this corpus does not contain.

"trimobile" has no definition and no aggregate. It is mapped to `ru.motorcycle` (three-wheelers ridden astride), and an atom gap `ru.trimobile` is recorded for seated three-wheelers. Reversal signal: the coding session writing the subject with `ru.motorcycle` without a gap, or an operator ruling that "trimobile" means only astride machines.

**NRS_484B_307_9a_o1.** "vehicular traffic" is the admitted `DEF-NRS-484A-285::traffic` aggregate. The qualifier "vehicular" excludes pedestrians, carried by the admitted pedestrian aggregate as a condition beside it. I did not claim the vehicle aggregate, because the table does not list it for this law. Bicycles stay in: paragraph (b) names them as excepted, which shows they fall within (a).

The obligation "may enter … only to make the movement indicated by the green turn arrow" is the act concept trio, recognized at the exit:
- violation is a left turn without `green_arrow(left)`, a right turn without `green_arrow(right)`, or a through movement without `green_arrow(straight)`, each judged on the display at the entry;
- "only to make" is a purpose, read through the movement made (`observable_reading` purpose);
- crossings that none of the three concepts classes are not judged (narrowing).

The trigger and condition spans are declared `at_recognition` and read at the entry through a past operator. A narrowing on a5 discloses this. Neither `some_moment` nor `throughout` matches words tied to the entry: reading the display at any moment of the crossing would condemn a vehicle that entered on green.

"Except as otherwise provided in paragraph (b)" composes all four 9b nodes `as: exception`. Their union of applicability is 9b's whole scope. The referring span is a2; the defining text is 9b's trigger and movement spans. The advisory last sentence is a residue.

Reversal signal: the gate refusing composition with same-batch unpublished nodes. If so, re-cut a2 as a condition carried by the 9b subject classes plus movement, keeping its full qualification.

**NRS_484B_307_9a_o2.** This is the yield of 9a, read with `since` from an entry made under red with an arrow. It is otherwise the same as 9b_o4: predicted-conflict yield to pedestrians in adjacent crosswalks and other traffic in the intersection, "lawfully" read as presence. It has the same exception composition with 9b. One scenario has no other road user and expects `compliant`.

**NRS_484B_363_3.** The obligation is `drv.motion.u_turn` (DEF-NRS-484B-077), with `occasion` boundary `window` on `p.turn_recognition_window`. The zone condition is read `some_moment`: a lane governed by a `dev.zone_sign` of kind `school` or `school_crossing`, with designation read from the sign's presence (status reading). The exceptions are read `throughout`:
- (a) no `ru.child` on the highway the zone lies on;
- (d) an operational `dev.speed_limit_beacon` (not `dev.inoperative`) that is dark, together with `asm.pupils_in_class`;
- (e) no operational beacon, with the zone sign's `prim.conditions_hold` false.

(b), (c) and the pupils-in-class words are assumptions: school sessions and hours are legal region classes. The validator does not count assumption spans as occasion spans, so they have no occasion scenarios. The section's own definition of "speed limit beacon" maps to `dev.speed_limit_beacon`, whose contract it matches. Reversal signal: labels that excuse a U-turn when children leave mid-turn. That would argue for reading (a) at recognition.

**NRS_484B_400_1_o1 / _o2.** There are two obligations: the right turn lane, and otherwise the extreme right lane. "intends to turn" and "The turn is a right turn" are both carried by `int.turn_right` (reused) at the intersection the r3 element binds.
- **o1** applies where a single right turn lane, the rightmost lane of its direction, enters the same intersection on the same way. It requires every approach carrier occupied at the observation before entry to be that lane.
- **o2** applies where no such lane exists. It requires the approach lane's ordinal to equal its count.

"as set forth in subsection 4 of NRS 484B.223" is a `definition` reference to both 223-4a and 223-4b. It borrows "a single right lane to be used only for turning", is carried by r6 with `source_spans`, and composes no rule: this duty needs only that such a lane exists, not 223-4's own duties. The approach is read at the observation before entry (narrowing). Reversal signal: labels that also require a minimum upstream stretch in the turn lane.

**NRS_484B_413_2.** One node. The validator requires a single obligation span, so the signal, the course change and the 100-foot window form one span, and the 300-foot words are a condition span that selects the other bound (`Term.cond` on `asm.business_or_residence_district`). Both figures are literals in `ft`, read over `.path` windows on `kin.path_length`.
- The change of course is the rise of `drv.lane.heading_offset_from_direction` past ±`p.course_change_sin_tolerance` on the occupied carrier.
- The signal is `sig.turn_indicator` or `sig.hand_signal` of the matching side.
- "regardless of the weather" is a scope-none residue.

Reversal signal: in-lane heading wobble triggering the duty on recordings. That would argue for raising the tolerance or adding a lateral-displacement condition.

**NRS_484B_440_1_o1 / _o2 / _o3.** There are three obligations: no halt on the roadway when halting off it is practicable; leave an unobstructed width; keep a clear view from 200 ft. All three share:
- "Upon any highway";
- `asm.business_or_residence_district` false;
- "upon the paved or main-traveled part": `st.roadway` (paved and improved);
- the disabled-vehicle exception: `asm.vehicle_disabled` (reused), the roadway, and the new `asm.disabled_vehicle_immovable`, since lacking own power does not imply the vehicle cannot be moved.

Node by node:
- **o1** reads every halt (`drv.motion.stopped`). The stop definition (DEF-NRS-484A-260) excepts halts made to avoid conflict (queue ahead within `p.queue_standstill_gap`, or predicted conflict) or in compliance with an officer or a device. These are carried by the rule beside the concept and disclosed as a purpose reading on e3, because the passenger and loading purposes that tell parking and standing apart are not observable. "practicable" is operationalized as a shoulder of the same highway within `p.off_roadway_reach` with no halted road user alongside.
- **o2** requires a whole lane of the same highway beside the standing vehicle. That lane must be free of other halted road users alongside, with `st.lane_width` ≥ `p.free_passage_width` (the standard "free passage").
- **o3** requires `st.sight_distance` ≥ the 200 ft literal at the standing vehicle's place.

"whether attended or unattended" is a scope-none residue. Reversal signal for o1: labels that treat a halt at a red signal as "leaving standing". The narrowing would then be wrong and the union of the three definitions should be read literally.

**NRS_484B_450_1c.** "stop, stand or park" is every halt (`drv.motion.stopped`), read within an intersection (index mapping reused). The exceptions are the section's own:
- conflict with other traffic: predicted conflict, or a queued member of traffic ahead within the standstill gap;
- an officer's stop direction governing the place;
- a red, stop or yield device governing the place;
- "in compliance with law": `asm.halt_required_by_law`. No specific corpus rule is named, and the exception span cannot be a residue.

Reversal signal: an operator ruling that "in compliance with law" must compose specific rules. It would then become compositions with each named halt duty once they exist.

## Same words, different atoms

- "within an intersection" and "Within an intersection.": reused (`rel.occupies`, `st.intersection`).
- "upon any highway": reused.
- "The driver of a vehicle": reused (the vehicle aggregate).
- The "If a highway has been designed to provide a single right lane …" words that r6 borrows: reused (`rel.occupies`, `st.highway`, `st.lane_adjacency`, `st.on_way`, `st.turn_lane`), with `st.lane_enters` and `st.intersection` added to tie the lane to the junction the subject enters.
- "To avoid conflict with other traffic" (450-1c c3): reuses the index's `prim.closest_approach_*` with the traffic aggregate, and adds `rel.surface_gap` and `rel.bearing` for a queue halt, which a predicted closest approach between two halted road users cannot show.

## For the operator

- **`ru.trimobile` gap (NRS-484B-307-9b).** No definition applies to "trimobile". `ru.motorcycle` covers three-wheelers ridden astride but not seated ones. If the coding session confirms the gap, all four 9b nodes are blocked, and 9a's exception composition with them is blocked too.
- **Same-batch composition.** 9a composes the 9b nodes planned in this same batch. If unpublished same-iteration nodes cannot be composed, 9a waits on 9b's publication.
- **Re-proposed parameters.** Every parameter catalogued only as "proposed this iteration" had to be re-proposed in each node that uses it. I copied the earlier batch's values and units unchanged. The conventions and sources are paraphrased, because the table shows them truncated.
- **Arrow-cycle counting (9b_o2).** A cycle the wait begins inside is not counted. This needs operator review against labels.

<!-- batch-04 -->
# Plan — batch 04

Five laws, six nodes, one new concept (`drv.motion.stopping_distance`), one gap (NRS-484D-100-1 (c)). No law-local aggregates: `aggregates.jsonl` is empty. The validator accepts every node and the concept.

## Concept `drv.motion.stopping_distance` (quantity)

This is the distance a road user would cover before it halts: its speed times a reaction time, plus its speed squared over twice a deceleration. The magnitude is the road user's own and does not depend on the law. The bound it is compared with belongs to each rule's operationalization. Grade and surface are left to the caller, through the deceleration the caller passes in. It is used by NRS_484B_600_1a and NRS_484D_215_1_o1. Reversal signal: the reviewer finds that a reaction-time model bundles a standard into the concept. In that case the two terms would move inline into the rules.

## NRS_484B_560_7a

**One node, subject x, a vehicle (the admitted aggregate).**
- **Crossing.** The trigger "when crossing at grade" means x's footprint overlaps a railway crossing. It also covers the stretch after x has occupied the crossing during which its body has stayed less than the law's literal of 15 ft from it: `since(distance < 15 ft, occupies)`. That literal comes from the law's own definition of "completely cross", which is cut as a definitional span.
- **"Without stopping".** This is read with DEF-NRS-484A-260, the definition the table applies, through `drv.motion.stopped`. The halting is the same physical notion as in the concept's own definition. The exceptions of 484A.260 are carried beside the concept:
  - avoiding a conflict, through the closest-approach primitives;
  - a police officer's stop direction.
- **Device-direction exception: not read (disclosed).** A device directs a halt at the place it marks, never on the tracks. Reading it would excuse exactly the queue-from-a-signal case the law targets.
- **Cause (1): insufficient space.** "Due to insufficient space" is a purpose. It is read through the conduct it explains: x halts behind a road user directly ahead, within the queue standstill gap (`observable_reading`, purpose).
- **Cause (2): undercarriage clearance.** No atom carries this. It is the declared assumption `asm.undercarriage_grounded`, so a halt on the tracks with nobody ahead and nothing declared is unknown.
- **"Nearest rail".** This is read as the rail nearest the trailing end once the vehicle is across. Otherwise a vehicle sitting on a second track would count as "completely crossed".
- **Reversal signals:**
  - an operator ruling that "nearest rail" means the approach-side rail;
  - a label treating a halt behind a queue at a signal as excused.

## NRS_484B_600_1a

**One node, a surrogate: the standard is the whole duty.** Applicability is "x is being driven", read through `drv.motion.moving` (agency). The bound reads each named factor by its degree:
- **Surface** selects the deceleration: ice or snow, else wet or precipitating, else dry.
- **Sight and visibility:** the stopping distance must lie within the sight distance at x's place and within the visibility distance.
- **Traffic:** time headway to each road user ahead in x's lane.
- **Curvature:** lateral acceleration in a bend must stay within the surface's acceleration.
- **Width:** a time-to-line-crossing margin on the width of the lane x occupies.

**Disclosed narrowings:**
- traffic outside x's lane is not read;
- width is the lane's width, not the highway's;
- weather is read only through visibility and precipitation;
- the catch-all "other highway conditions" is read only through sight distance and curvature.

**Traffic aggregate.** The validator does not accept `ru.aggregate=…::traffic` inside an operationalization. Traffic is therefore read as every road user ahead in the lane, all of which fall within DEF-NRS-484A-285's "using any highway for purposes of travel".

**Reversal signal:** label disagreement concentrated on one factor. That would point to that factor's parameter, not the structure.

## NRS_484B_769

**One node, subject x, any of three aggregates:** bicycle, electric bicycle, electric scooter.
- **Applicability:** x occupies a roadway.
- **Obligation:** every turn signal x gives by lamp (`sig.turn_indicator`) is also given by arm with the same meaning (`sig.hand_signal`).
- **The manner of 484B.420 and the right-arm exception.** Both are postures of one meaning, and the source reads that meaning into `sig.hand_signal`. So both satisfy the duty, and the exception is carried by the same atom.
- **Brake lamps are not read** (disclosed narrowing). A brake lamp is an actuation of the brake, not a signal the rider chooses.
- **Scope.** Whether a signal is owed at all belongs to the signalling rules, not to this one. A rider who gives no signal is compliant here.
- **Reversal signal:** a label counting an automatic brake lamp as a lamp signal.

## NRS_484D_100_1

**One node, subject x, a vehicle on a highway.** The duty applies when any of the three listed times holds, and requires lit headlamps (low or high beam) and position lamps.
- **(a) Darkness.** `env.darkness`, whose sunset/sunrise boundary is the reading's parameter, set at the law's literal of one-half hour.
- **(b) Visibility.** `env.visibility` below the literal of 1,000 ft. The words' test is discernibility at that distance, whatever its cause.
- **(c) Device direction: atom gap.** No code of `dev.regulatory_sign` and no kind of `dev.zone_sign` directs road users to display lamps. The proposed new atom is `dev.lamp_use_sign`, mapped to the nearest atoms meanwhile.
- **Parked-vehicle exception.** The exceptions are "stated in chapters 484A to 484E" without naming a section, so no rule can be composed. "Parked" is read through conduct as halted with the engine off (`observable_reading`, purpose). The rule judges only vehicles that are not parked.
- **Per-class lamp lists.** "As respectively required … for different classes" is read as headlamps plus position lamps (disclosed).
- **Reversal signals:**
  - a corpus node for the parked-vehicle lamp provisions, which would then be composed as an exception;
  - the operator admitting a lamp-direction device.

## NRS_484D_215_1_o1 and NRS_484D_215_1_o2

**Two obligations, so two nodes.**
- **Shared frame.** Both read the opening frame:
  - a motor vehicle being operated, meaning moving or with its engine running (agency);
  - on the roadway, or the shoulder, of a highway;
  - during the times of NRS 484D.100, composed with `NRS_484D_100_1` as a condition, mapping x to x.

  The second node reads this frame because its words are a limitation of the first duty ("subject to the following requirements and limitations"). Without the frame it would demand low beams in daylight.
- **o1 (the upper-beam duty).** "Subject to the following…" is the composition `NRS_484D_215_1_o2` as an exception. While the dimming duty applies, o1 does not. The standard "high enough … to reveal … at a safe distance" is operationalized, not a surrogate, because the duty to use a beam is concrete. It is met by the high beam, or by the low beam when x's stopping distance lies within the low beam's seeing distance. Headlamps off violate it.
- **o2 (the dimming duty).** Its trigger is an oncoming vehicle (`rel.oncoming`, headings opposed and closing) within the literal of 500 ft (`rel.surface_gap`). Its obligation is the low beam. That is the lowermost beam the law deems to avoid glare: a definition reference to DEF-NRS-484D-210-1-2. The high beam is read as projecting glare, and lamps off are no beam at all.
- **Reversal signal:** a label that accepts headlamps off while meeting an oncoming vehicle at night. That would mean "use a distribution of light" is not read as requiring a lit beam.

## For the operator

- **Two definition texts were missing from the prompt.** The bracketed sources DEF-NRS-484B-420 (cited by NRS-484B-769) and DEF-NRS-484D-210-1-2 (cited by NRS-484D-215-1) were not among the injected definition texts. The `definition` references quote "extended horizontally" and "lowermost distribution of light". These are the phrases those sections use as I know them, and the validator accepted them, but please check them against the corpus text.
- **Gap `dev.lamp_use_sign`** (NRS-484D-100-1, clause (c)). This blocks that law, and therefore both NRS-484D-215-1 nodes, which compose it, until it is decided.
- **Earlier-batch parameters re-proposed.** The validator's catalogue did not yet contain the parameters proposed by earlier batches: `p.motion_speed_tolerance`, `p.queue_standstill_gap`, `p.conflict_time_horizon`, `p.conflict_centre_clearance`. They are proposed again here with the same values and units.
- **New parameters awaiting review:**
  - `p.perception_reaction_time`
  - `p.surface_friction_accel_dry`, `_wet`, `_ice_or_snow`
  - `p.following_min_time_headway`
  - `p.lane_keeping_margin_per_speed`
  - `p.low_beam_seeing_distance`
  - `p.oncoming_cos_tolerance`

  The low-beam seeing distance and the reaction time decide how often low beams on lit urban streets are flagged by NRS_484D_215_1_o1.
- **"Stopping" in NRS-484B-560-7a.** Its definition is DEF-NRS-484A-260. It reuses `drv.motion.stopped`, whose contract quotes DEF-NRS-484A-255; the halt is the same physical notion, and 260's exceptions are carried by the rule. If the operator wants one concept per definition, a qualified record would be needed.
