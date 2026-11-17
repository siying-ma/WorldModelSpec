# Plan — batch 12 (iteration 1)

Eight law lines, fourteen nodes. No new concepts, no law-local aggregates (`aggregates.jsonl` is empty), no gaps. Every node calls concepts this iteration has already proposed (`drv.motion.complete_halt`, `right_turn_through_region`, `left_turn`, `u_turn`, `moving_against_carrier`) by id. Every yield duty uses the same conflict reading: the subject breaks the duty when it touches the protected vehicle (`rel.contact`), or when it keeps moving (`kin.speed` above `p.halt_speed_tolerance`) while the two centres' closest approach falls within `p.conflict_horizon` at a distance below `p.conflict_centre_clearance`. "Right-of-way" (DEF-NRS-484A-210, "danger of a crash") and "immediate hazard" are standards. Each is operationalized with these primitives and parameters, and none is a surrogate. "Shall yield" and "yielding" reuse the index mapping (`kin.speed`, `rel.contact`). The drivers named in each node are read through the vehicle's controlled motion (`observable_reading`, agency).

The stop-before-entry duties (250-4 o1, 257-1 o1, 257-2 o1) follow the ontology's approach convention (rule 4c):
- **Event:** the subject's entry into X from a carrier `c` that `st.lane_enters` X.
- **Place:** a stop line marking `c`, else the crosswalk marking `c`, else `c`'s entrance end.
- **Search bound:** the search runs back to the approach start or to the previous entry. Each of these nodes has a `history_boundary` scenario.

The stop is DEF-NRS-484A-255. Its scope is a stop "when required". DEF-NRS-484A-260 governs stopping where it is prohibited, so it does not apply here. "The point nearest the intersection where the driver has a view of approaching traffic" is read as `c`'s entrance end. This is a perception reading: the view is read through the place the words describe, and no sight distance is measured. Reversal signal: a labelled scene where a halt at the edge of the intersection is judged non-compliant because the view was blocked there. That would require `st.sight_along_way` and a new sight parameter.

## NRS_484B_223_4b
The duty is: from the right-turn-only lane, do not pass through the intersection; the passage must be a right turn. It is judged at the exit from X using `drv.motion.right_turn_through_region(subject, X)`. That concept's onset is the entry into X and it is recognized at the exit; the occasion uses `boundary: event`. "While being driven in the right turn lane" is read `some_moment`, because at the entry the footprint overlaps the lane L and X together. The trigger (a right turn lane on the highway) is a fixed feature of the map, so it is read `at_recognition`.

"A single right lane" keeps the index mapping from 223-4a (`rel.occupies`, `st.turn_lane`). "Single" is read as "one lane": `st.lane` is "a strip ... for one line of vehicles". It is not read as a count of right turn lanes.

Reversal signal: a labelled dual right-turn approach judged out of scope.

## NRS_484B_227_1_o1 / _o2 / _o3
There are three obligation spans:
- **o1, "only upon the right-hand roadway":** the subject must not move against the designated direction of any roadway of the divided highway it occupies (`drv.motion.moving_against_carrier`).
- **o2, "over, across or within any dividing space":** the footprint must not overlap a `st.median_or_divider` on the highway.
- **o3, "left turn, semicircular turn or U-turn":** `drv.motion.left_turn` or `drv.motion.u_turn`. A semicircular turn is a reversal of direction, so it falls in the u_turn band.

"Divided highway" (DEF-NRS-484A-070) is read as a highway with a divider lying on it (`st.on_way`). The exception (an opening, or a crossover or intersection) is read as the footprint overlapping a divider region that has the `opening` attribute, or an intersection lying on the highway. The exception applies to all three nodes: o1 also needs it, because a vehicle crossing at an opening or intersection briefly moves across the opposing roadway.

In o3 the trigger and both exceptions are read `some_moment` within the turn window. A turn "through" an opening or "at" an intersection passes through that place for part of its path. Reading the exceptions `throughout` would excuse no turn, since every turn begins on the approach roadway. The turn window is `p.vehicle_turn_window`.

Reversal signal: a source that draws median openings as gaps rather than as divider regions. o2 is unaffected by this; o3 would then need the opening to be a region of its own.

## NRS_484B_250_4_o1 / _o2
**o1** is the stop. The trigger is the entry into X under a governing `dev.traffic_signal` that is `dev.inoperative` at that observation. The signal is "installed ... uncovered ... inoperative", which matches the contract of `dev.inoperative` word for word. "Proceed as if a stop sign had been erected at each entrance" and the list of places that follows form one obligation span.

**o2** is "proceed cautiously, yielding". It applies while the subject is in X after an entry made under an inoperative signal. Two cross-references:
- **Referring span:** "After making such a stop" (p1). **Defining span:** o1's obligation. p1 is carried as compliance with `NRS_484B_250_4_o1`, read at the subject's entry. o1 is engaged at exactly that observation, so compliance there means the stop was made at its place. The weaker fact "some halt on the approach" is not used. Branch 3 shows that omitting the stop makes o2 not applicable; the omission is judged by o1.
- **"Vehicles which have previously completed a stop":** another vehicle that halted on its own approach carrier before the subject's own halt (the order of a four-way stop), and that has stayed on its approach or in X since.

"Cautiously" is read only through the yielding joined to it (a narrowing on the standard span). Reversal signal: a label requiring a lower crossing speed when no vehicle is in conflict.

## NRS_484B_250_1 and NRS_484B_250_2
**250-1:** while the subject approaches X (it occupies a carrier entering X), it yields to a vehicle that has continuously occupied X since leaving a carrier on a highway on which the subject's carrier does not lie.

**250-2:** "enter ... at approximately the same time" is read as both vehicles arriving at the intersection's edge (body within `p.stop_point_tolerance`, which is a "standard" span operationalized with the new parameter `p.same_time_arrival_window`). The reason: a vehicle that yields at the edge never enters together with the other, so reading the footprint's entry would make the duty disappear exactly when it is performed. "On the right" is read with `rel.bearing` at the later of the two arrivals.

The controlled-intersection exception reuses the index mapping from LVMC 11.16.040 (signal, stop sign or yield sign governing X or one of its entrances).

The opposite-direction / left-turn exception is applied per pair of vehicles:
- Approach direction is read through each carrier's `st.lane_direction`, as `rel.oncoming`'s exclusion clause requires (`p.oncoming_heading_cos`).
- "Intending to" is the declared intention `int.left_turn` at X (reused id).
- "Is making a left turn" is a heading change since entering X, computed with heading-since over `kin.yaw_rate` and step `p.heading_since_step_carla_scene_graph`, between `p.turn_heading_min` and `p.u_turn_heading_min`.

**"Except as otherwise provided in subsection 4":** subsection 4 concerns only signal-controlled intersections, so the carve-out keeps subsection 4 itself in force. It does not reopen subsections 1–2 at those intersections. The span is therefore composed `as: exception` with `NRS_484B_250_4_o1` and `_o2` (one composition per node of the named rule). This adds nothing beyond the controlled-intersection exception, and is consistent with it. Reversal signal: an operator reading that 250-1/250-2 also apply at an intersection with an inoperative signal. The fix then is `as: unless` scoped to span h/j, with a rule whose engagement covers the approach.

## NRS_484B_253_o1 / _o2
**o1:** the subject is in X and declares `int.left_turn` at X. It yields to vehicles approaching from the opposite direction, read through the carriers' directions, that are within X or are an immediate hazard (a standard operationalized by the conflict primitives).

**o2:** "the drivers of all other vehicles approaching ... from the opposite direction" yield to the turning vehicle t. o2 has three cross-references to words stated elsewhere:
- **"Such driver" (spans a–c):** t is in X and declares `int.left_turn`.
- **"Having so yielded" (span i, defining span is o1's obligation):** composed as compliance with `NRS_484B_253_o1` (binder `subject ↦ t`), read at the observation where t's current movement in X began (its entry, or its start from rest). Reading it at the current observation would be circular: once the opposing vehicle closes in, t is "not yielding" by the same symmetric bound.
- **"Having given a signal when and as required":** a left indicator or left arm signal given at some point after t came onto its approach carrier. The signalling rule `NRS_484B_413_2` is listed as not composable, so its distances are not composed or inlined.

Branch 1 shows the verdict changing on the weaker fact: a t that did not yield is not protected. Reversal signal: `NRS_484B_413_2` becomes composable. Span j should then be composed `as: compliance`.

## NRS_484B_257_1_o1 / _o2
The exceptions are "traffic ... controlled by a police officer", read as `dev.human_direction` with role `police_officer` governing the approach or X, and "a traffic-control signal", read as an operating signal (not `dev.inoperative`). Both are read at the entry. They claim the admitted traffic aggregate, of which the subject is a member.

**o1:** at a stop sign, the act is a complete halt at the place. At a yield sign it is "slowed or stopped", the words of the next sentence: `kin.speed` within the place's stopping zone at or below the new parameter `p.yield_line_speed_max`. That is the speed from which the car can still halt within the stop-point tolerance.

**o2:**
- **Referring span:** "After having stopped or ... slowed or stopped". **Defining span:** o1's obligation. It is composed as compliance with `NRS_484B_257_1_o1` at the entry, as in 250-4.
- **"Such through highway"** (DEF-NRS-484A-275) is read from the devices: a highway X lies on, other than the subject's, none of whose entrances into X has a stop or yield sign.
- **"During the time such driver is moving across or within":** the subject occupies X and `kin.speed` is above the tolerance.

Reversal signal: a labelled scene where a driver who ran the stop sign is judged on the yield. That would turn j into an order word rather than a referenced act.

## NRS_484B_257_2_o1 / _o2
**o1:** stop in obedience to, or yield in compliance with, the sign governing the subject's own entrance. "In compliance with the manner prescribed in subsection 1" is composed as compliance with `NRS_484B_257_1_o1`, and the same place search is written out. "Prior to entering an intersection" is the trigger: the entry is the event.

"Although not a part of a through highway" is a concessive, carried as a residue of scope `none`. The duty at a signed entrance is the same whether or not the intersection is part of a through highway, and subsection 1 states the same act where it is. Reversal signal: an operator reading that excludes through-highway intersections from subsection 2.

**o2:** "proceed cautiously, yielding to vehicles not so obligated". This means vehicles whose approach carrier, and X itself, is governed by no stop or yield sign, and that are within X or are an immediate hazard, while the subject moves within X. Branch 2 (an all-way stop) shows that a vehicle under its own stop sign is not protected.

## For the operator
- **New parameters proposed:**
  - `p.same_time_arrival_window` (s): a two-second-rule headway, for "approximately the same time".
  - `p.yield_line_speed_max` (m/s): the speed from which a passenger car halts within the stop-point tolerance at a comfortable deceleration.

  Their values are in the nodes' `param_proposals`.

  All other parameters are proposed again with the values and conventions already recorded this iteration.
- **Compositions to nodes of this batch:** the validator accepted compositions to nodes planned in this same batch (`NRS_484B_250_4_o1/_o2`, `NRS_484B_253_o1`, `NRS_484B_257_1_o1`). Their build order follows the composed nodes.
- **`dev.governs` on an intersection:** the controlled-intersection readings assume a source that writes `dev.governs` on either the approach carriers or the intersection. If it writes neither, every "controlled" exception is unknown.
