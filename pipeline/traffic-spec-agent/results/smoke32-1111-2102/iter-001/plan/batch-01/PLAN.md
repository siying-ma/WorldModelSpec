# Plan — batch 01 (iteration 001)

Eight laws, thirteen nodes, nine proposed concepts, no law-local aggregates (`aggregates.jsonl` is empty).
The validator accepts every node and concept record. `NRS_484B_117_1` carries atom gaps and will not be coded.

## Concepts proposed

- `drv.motion.at_rest` (definition DEF-NRS-484A-255, "complete cessation from movement"): speed at or below a tolerance. This is the stop "when required". The run never uses DEF-NRS-484A-260, which covers a halt "when prohibited", because none of these laws prohibits stopping.
- `drv.motion.backing`: the component of velocity along the heading is negative. It does not read gear.
- `drv.motion.decelerating`: longitudinal acceleration is below a negative tolerance and the road user is not backing.
- `drv.motion.turning_left`: a state concept. The road user is moving and its yaw rate is leftward above a tolerance. It covers "is making a left turn" while the turn is under way.
- `drv.motion.left_turn` / `drv.motion.u_turn` (definition DEF-NRS-484B-077): window acts. They read `prim.heading_change` within a band. The U-turn window allows a turn made in several movements, which the definition requires with "whether accomplished by one continuous movement or not".
- `drv.position.near_region`: the body-to-region distance is within a reach.
- `drv.position.behind`: headings are aligned and the other road user is wholly ahead. This is not limited to the same lane.
- `drv.interaction.overtakes`: an event act. It goes from `behind` to wholly ahead with aligned headings and is recognized when the passing vehicle becomes ahead.

**Mapping "yield".** Throughout the run, "yield (the right-of-way)" means that ego does not go on with its movement while a vehicle that has precedence is in conflict with it. The obligation reads `drv.motion.at_rest`, with one exception: in NRS 484B.113(3), the movement in question is backing, so the obligation reads `drv.motion.backing`. These are different words ("Shall in every case yield"), and the reason is given in that node's paragraph.

**Mapping "the right-of-way".** It is always a `standard` span. It is operationalized from DEF-NRS-484A-210 ("danger of a crash") through `prim.closest_approach_within` / `prim.closest_approach_distance`, with `p.conflict_horizon` and `p.conflict_clearance`.

**Mapping "immediate hazard".** It is the body-to-intersection distance compared with speed × `p.immediate_hazard_time` (gap-acceptance critical headway).

## Nodes

**LVMC_11_30_030.**
- Ego is barred from overtaking a vehicle b that is at rest at a crosswalk (marked, or unmarked at an intersection) while a pedestrian is at that same crosswalk.
- The act is `drv.interaction.overtakes`, which has an event boundary. Its onset is the last observation at which ego was behind b, and it is recognized when ego becomes wholly ahead.
- The trigger and condition spans are read `some_moment` while the pass is under way.
- "approaching from the rear" stays in the subject span, read as the onset of the pass (`drv.position.behind`).
- The purpose "to permit a pedestrian to cross" is read as a pedestrian at the same crosswalk (`observable_reading` purpose).
- "unmarked crosswalk at an intersection" needs no `st.intersection` read: the contract of `st.crosswalk` already places unmarked crosswalks at an intersection.
- Reversal signal: a labelled scene in which the stopped vehicle's pedestrian waits on the sidewalk outside `p.crosswalk_reach` and the label still calls the pass a violation. That would widen the purpose reading.

**NRS_484B_113_3.**
- The duty to yield to moving traffic and to pedestrians is read on ego's backing movement only (narrowing on s2). The line is item (3) of "Limitations on backing".
- Read literally, it would require every vehicle to yield to every moving road user at every moment. That is not coherent.
- "moving" qualifies traffic, not pedestrians, because pedestrians are already traffic.
- Reversal signal: a label that judges a forward-moving vehicle under this line. The reading would then have to drop the backing restriction.

**NRS_484B_117_1.**
- The obligation itself is fully mapped: ego does not move with its footprint on a sidewalk, except where it is also on a driveway or alley entrance.
- The subsection-2 exemption cannot be carried. No atom states that a vehicle is "powered solely by electricity and designed to travel on three wheels" (s6). No atom states that its operator is a law-enforcement officer or employee, or a security guard, "in the course of his or her official duties" (s9, s11, s12, s14).
- Under rule 2, an exception span cannot be dropped and a duty a person holds is never an assumption, so these spans are gaps. The node is blocked until the operator decides them.
- (a) "As an authorized emergency vehicle" is carried by its admitted aggregate.
- The two borrowed definitions (DEF-NRS-239C-065, DEF-NRS-648-016) are `definition` references.
- The penalty sentence and "Except as otherwise provided in subsection 2 …" (which only points at the appended exemption) are boilerplate.
- Reversal signal: an ontology revision that adds a wheel-count/propulsion attribute and an operator-duty atom.

**NRS_484B_227_1_o1 / _o2 / _o3.** The line has three obligations: right-hand roadway, not over or within the divider, and no left, semicircular or U-turn.
- **"Divided highway"** is a highway that has a `st.median_or_divider` lying on it (`st.on_way`).
- **o1 (right-hand roadway):** read without a lane direction. Every divider of the highway lies to ego's left (`prim.region_lateral_offset` > 0).
- **o2:** footprint overlap with the divider.
- **o3:** the alternative window acts `left_turn` and `u_turn`, with occasions `some_moment`. A turn made "through" an opening passes through it, so it is not inside the opening throughout.
- **Shared exception:** a divider region with the `opening` attribute, or an intersection on the highway. "Established by a public authority" is read as status. The exception closes the whole sentence, so it is kept on o1 as well.
- **"semicircular turn":** a half-circle reversal of direction, read by the U-turn concept.
- Reversal signal: a labelled crossover transit in which o1 reports a violation on the far roadway. In that case the exception on o1 would be read `throughout` a crossing act.

**NRS_484B_250_4_o1.**
- This is a rule-4c approach duty.
- Event: ego enters an intersection while every signal head that governs its approach or the intersection is `dev.inoperative`.
- Place: the stop line marking the approach. Failing that, the near-side crosswalk marking it (halt short of it, footprint not overlapping it). Failing that, the carrier's entrance end, outside the intersection.
- History bound: the approach start or the previous entry, following the ontology's §9 convention. `history_boundary` is planned.
- "proceed as if a stop sign had been erected at each entrance" is read as the stop-sign duties at ego's own entrance: the halt here and the yield in o2. The other entrances bind other vehicles.
- "where the driver has a view …" is read through the place, the edge of the intersection (perception reading). "clearly marked" is read as status.
- Reversal signal: a labelled halt short of the edge with an obstructed view at the edge.

**NRS_484B_250_4_o2.**
- Referring span: a9 "After making such a stop". Defining spans: a5–a8, which are sibling here.
- The referent is carried in full in a9's element: the halt at the governing place, found by o1's search. A halt anywhere else does not count; branch_3 differs from forbid only in the halt's place.
- "cautiously" is operationalized as the conflict test. A narrowing restricts it to the vehicles ego yields to.
- "previously completed a stop" means the other vehicle's rest at its own entrance began before ego's halt.
- A vehicle with precedence that keeps waiting is not in conflict (narrowing).
- Reversal signal: a label that calls ego's entry a violation while an earlier-stopped vehicle is still waiting.

**NRS_484B_250_1.**
- Ego, approaching an intersection, yields to a vehicle that entered it from a carrier lying on a different highway.
- "Except as otherwise provided in subsection 4 [NRS-484B-250-4]" is an `unless` composition with both NRS_484B_250_4 nodes. It suspends only the device exception (e7), which an inoperative signal would otherwise trigger.
- e7 reads the signals and stop/yield signs that govern the intersection or any of its approaches. "controlled" excludes devices that only warn or guide.
- The opposite-direction exception reads the approach carriers' directions, never the headings. The left-turn intention is `int.left_turn`, and "is making a left turn" is `drv.motion.turning_left`.
- Reversal signal: a label that treats a single warning sign as controlling the intersection.

**NRS_484B_253_o1.**
- Ego is within an intersection and declares `int.left_turn`. It yields to opposing vehicles that are within the intersection or within the immediate-hazard bound.
- "Opposite direction" is read through the carriers.
- Reversal signal: a label that counts as "opposite" an oncoming vehicle whose approach carrier is not opposed (a skewed approach beyond `p.opposite_direction_tolerance`).

**NRS_484B_253_o2.**
- Opposing drivers yield to the vehicle t that is making the left turn.
- Referring spans: f10 "having so yielded", which refers to f4–f8 (sibling here). It is carried as compliance with NRS_484B_253_o1, with t mapped to that node's ego, at every observation since t entered. The words ask that t yielded "so", meaning as required. Where no opposing vehicle was close, there was nothing to yield to, and compliance-when-not-engaged reads that correctly.
- f11 is the signal itself, `sig.turn_indicator` / `sig.hand_signal`. "when and as required" refers to a statute outside the corpus and is read as a signal given before the judged observation.
- branch_1 (no signal) and branch_2 (t did not yield) each differ from forbid only in the referred fact.
- Reversal signal: a label that holds the opposing driver to the duty even though t never signalled.

**NRS_484B_257_1_o1.**
- This is a rule-4c approach duty at an entrance governed by a stop or yield sign. The police-officer and operating-signal exception is read at the entry.
- Under a stop sign, ego must halt at the governing place.
- Under a yield sign alone, ego must either halt, or be "slowed", using the line's own words "slowed or stopped". "Slowed" is read as `drv.motion.decelerating` within a `.path` window `p.yield_slowing_distance` before the stopping zone (narrowing on g4).
- Reversal signal: a labelled yield approach where the slowing ended before the window and the label calls it compliant.

**NRS_484B_257_1_o2.**
- Referring span: g8 "After having stopped or, in the event of a yield sign, slowed or stopped". Defining spans: g4–g7, which are sibling here. The act at the place is carried in full.
- "Through highway" (DEF-NRS-484A-275) is read as the other highway's approach carrier, governed by neither a stop nor a yield sign.
- The duty is judged while ego moves within the intersection.
- branch_1 (halt only upstream) differs from forbid only in the referred act.
- Reversal signal: a four-way-stop label that expects a yield to a cross vehicle. Under this reading there is no through highway there.

## For the operator

- **Gaps on NRS_484B_117_1:**
  - `ru.electric_three_wheeler`: wheel count and electric-only propulsion.
  - `ru.operator_on_official_duty`: role ∈ {law_enforcement, security_guard}, from an assignment record. This one is filed on four spans.
  - The node is blocked on these gaps alone. Its prohibition is ready to code once they are decided.
- **Parameters proposed for review:** all are new, and each carries the same convention wherever it is proposed.
  - `p.rest_speed_tolerance`, `p.crosswalk_reach`, `p.same_direction_tolerance`, `p.opposite_direction_tolerance`
  - `p.conflict_horizon`, `p.conflict_clearance`, `p.immediate_hazard_time`
  - `p.stop_point_tolerance`, `p.decel_tolerance`, `p.yield_slowing_distance`
  - `p.turn_window`, `p.left_turn_min_angle`, `p.left_turn_max_angle`, `p.u_turn_min_angle`, `p.u_turn_max_angle`, `p.turn_yaw_tolerance`
- **Proposed bands share a boundary:** the left-turn upper bound equals the U-turn lower bound, so a heading change matches exactly one band at that boundary.
- **Declared intention `int.left_turn`** ("the road user's current plan includes turning left at the target region") is introduced by NRS_484B_250_1 and NRS_484B_253 with an identical meaning. Sources must declare it per road user per intersection.
- **NRS 484B.113(3)'s backing reading** depends on the section heading, not on the words of the line. If the corpus line is meant to be read standalone, the node needs a different, coherent obligation.
