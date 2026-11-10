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
