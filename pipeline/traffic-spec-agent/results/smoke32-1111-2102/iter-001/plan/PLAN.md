<!-- batch-01 -->
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

<!-- batch-02 -->
# Plan — batch 02 (iteration 001)

Seven laws, sixteen nodes, five new concept records. There are no law-local aggregates, so `aggregates.jsonl` is empty. Three laws (297-6, 307-9b and 440-1) carry atom gaps and stay blocked until the operator decides on them. The other four are ready to code.

## Nodes

**NRS_484B_280_1a (surrogate).** "Exercise due care" is the whole duty and describes a state of mind, so the node is a surrogate. Care is read as two things: no contact (`rel.contact`), and no projected close approach to any pedestrian while the motor vehicle moves (`prim.closest_approach_*` with `p.conflict_horizon` and the new `p.pedestrian_conflict_clearance`). Contact while ego is at rest is not read as a want of care. *Reversal signal:* a label that judges care through lookout or warning conduct rather than the outcome.

**NRS_484B_297_6_o1/o2/o3 (blocked: gap `st.sidewalk_interruption` on s4).** The line has three duties, in text order:
- **o1 — "may proceed with due care".** A surrogate yield-like conflict test against non-pedestrian road users.
- **o2 — (a) keep to the side near the sidewalk.** Body-to-sidewalk distance must be within `p.pedestrian_edge_margin`, or the same margin to an obstruction lying laterally between ego and the sidewalk. Exception (c), "impassable", is operationalized as an obstruction between ego and the sidewalk.
- **o3 — (d) return as soon as practicable.** Ego must be back on the sidewalk before `p.sidewalk_return_time` has passed since it left the obstruction behind.

The trigger reads "encounters an obstruction" as ego on a sidewalk within `p.obstruction_reach` of an `st.obstruction`. "To move around" is read as a purpose: ego left the sidewalk there and has not yet returned. The example "a short section of the sidewalk that is missing" widens where the duties apply. No atom carries it, because a missing section is no object. Dropping the example would leave the rule unapplied where the law applies, so it is a gap, not a residue. Permission (b) is a scope-none residue in each node. *Reversal signal:* an ontology row for a sidewalk interruption, or an operator ruling that the example adds nothing beyond `st.obstruction`.

**NRS_484B_307_9b_o1..o4 (blocked: gap `ru.trimobile` on b3).** The words "may proceed … if (1)…(4)" are read as four duties. Each binds a rider of the listed classes who, having entered on red with a green turn arrow, proceeds straight or turns against the arrow. Each is judged at the exit, using the heading change since entry.
- **o1 — the stop.** Uses the rule 4c approach convention: stop line, else near crosswalk, else intersection entrance. It includes the `history_boundary` scenario.
- **o2 — the wait.** One stretch of rest on the approach, with the red steady and the arrow rising at least the literal count plus one times, so that two complete cycles fall inside the wait. The search is bounded by ego's arrival on its approach carrier, which gives the second `history_boundary` scenario. The cause of the non-change (malfunction or detection failure) is a scope-none residue. Two complete cycles with a steady red is itself what such a failure shows.
- **o3 — no device prohibits the turn.** Only checked when ego turns ("if applicable").
- **o4 — the yield.**

"Trimobile" has no applicable definition. `ru.motorcycle` covers only astride riders, and `ru.motor_vehicle` would admit cars, so it is an atom gap rather than a subject narrowing. *Reversal signal:* the operator admits that `ru.motorcycle`'s "three-wheeled variants" covers trimobiles.

**NRS_484B_307_9a_o1.** "May enter only to make the movement indicated by the green turn arrow". Ego's heading change through the intersection (`drv.motion.heading_change_since_entry`, read at the exit) must lie in the band of a green turn arrow displayed at entry. The signal is read at the entry through a `since` operator. "Vehicular traffic" is the traffic aggregate with the law's own qualifier carried as "not `ru.pedestrian`". "Except as otherwise provided in paragraph (b)" is an exception composed with all four 9b nodes, which share one applicability. While 9b is blocked, this composition is the only open dependency. The advisory sentence is a scope-none residue. *Reversal signal:* a label that judges "the movement" by the lane ego exits into, not by its heading change.

**NRS_484B_307_9a_o2.** "Must yield the right-of-way …" is one obligation span. The danger of a crash in DEF-NRS-484A-210 is read as a projected close approach of the centres (the same reading as the earlier batch's "shall yield": `drv.motion.at_rest` plus the closest-approach primitives).
- "Adjacent crosswalk" means any crosswalk recorded as marking the entrance of a carrier that enters the intersection. It is tied by relation atoms, never by distance.
- "Lawfully" is not read: the rules on the other road users' lawfulness are not in the library. This is disclosed as a narrowing on the obligation span.
- The 9b exception is `sibling` here. Paragraph (b) qualifies only the movement restriction, and 9b_o4 imposes the same yield anyway.

*Reversal signal:* a pedestrian rule entering the library, at which point "lawfully" becomes a composition.

**NRS_484B_413_2.** Judged where a left or right turn from an observed onset is recognized (new act concepts `drv.motion.left_turn_from_onset` and `drv.motion.right_turn_from_onset`). The signal must hold continuously over the literal 100 ft of path behind the observed onset where `asm.business_or_residence_district` holds, and over the literal 300 ft elsewhere. Following rule 4d, the window ends at the onset (the last rise of `drv.motion.turning_left` or `turning_right`), never at the sliding recognition. The district is an assumption (§9 legal region class). A turn indicator or a matching arm signal both count. "Regardless of the weather" is a scope-none residue. The narrowing is disclosed: lane changes are not read, because their heading change stays below the turn angle, while a bend followed through the turn angle is read as a turn. *Reversal signal:* a label that requires a signal for a lane change under this law, which would call for a lateral course-change concept.

**NRS_484B_440_1_o1/o2/o3 (blocked: gap `ru.disabled` on e13).**
- **o1 — no halt on the paved or main-traveled part when an off-road place is practicable.** Practicable means an unpaved shoulder or parking space within `p.offroad_stop_reach`.
- **o2 — leave an unobstructed width opposite.** A free lane of at least `p.free_passage_width`.
- **o3 — clear view from the literal 200 ft.** Read as `st.sight_distance` at the place.

"Stop" here is the prohibited stop of DEF-NRS-484A-260. Its exceptions (avoiding a conflict with traffic, or complying with an officer or device) are carried beside the halt as conditions. The outside-district condition is the same assumption as in 413-2, negated. The disabled-vehicle exception changes where the rule applies and no atom carries it, so it is an atom gap. *Reversal signal:* an atom for a vehicle that cannot move under its own power.

**NRS_484B_600_1a (surrogate).** Reasonable speed is operationalized with the stopping-sight-distance model, in five parts:
- Stopping distance (new quantity concept `drv.motion.stopping_distance`), with a deceleration selected by surface or weather (ice, wet or precipitation, dry), must be within the sight distance and within the visibility distance.
- The gap to the road user ahead in the lane must be at least the reaction distance.
- The curve's lateral acceleration (speed² × curvature) has a bound.
- Speed times `p.lane_width_speed_time` must be within the lane width.

Each factor's measured magnitude enters its bound. The catch-all "other highway conditions" is read only through curvature and sight distance (narrowing). *Reversal signal:* operator-reviewed values or labels showing that the width relation is too strict on urban lanes; that clause can then be withdrawn as a narrowing.

## Concepts proposed

`drv.motion.heading_change_since_entry` (quantity, region formal), `drv.motion.turning_right` (mirror of `turning_left`), `drv.motion.left_turn_from_onset` and `drv.motion.right_turn_from_onset` (event acts with an observed onset), and `drv.motion.stopping_distance` (quantity). The existing `drv.motion.left_turn` was not reused for 413-2 because its onset is a sliding window, which rule 4d forbids as the boundary of a duty placed before the act.

## Deviations from the mapping index

- "yield" spans here also claim the closest-approach primitives and the party relations inside the single obligation span. The validator requires one obligation span, so the earlier batch's separate standard span could not be kept. The meaning is unchanged.
- `st.lane_direction` is not claimed beside `prim.region_offset_along`, because the primitive reads it (rule 0b). The approach prose still names it for the coder.

## For the operator

- **Gaps filed:** `st.sidewalk_interruption` (297-6), `ru.trimobile` (307-9b) and `ru.disabled` (440-1). Each blocks its whole law.
- **9a and 9b:** 9a_o1 composes the 9b nodes as an exception, so it waits on the trimobile decision even though 9a itself carries no gap.
- **Parameters proposed for review:**
  - `p.pedestrian_conflict_clearance`, `p.right_turn_min_angle` and `p.right_turn_max_angle`.
  - `p.obstruction_reach`, `p.pedestrian_edge_margin` and `p.sidewalk_return_time`.
  - `p.queue_gap`, `p.offroad_stop_reach` and `p.free_passage_width`.
  - `p.perception_reaction_time`, `p.stopping_decel_dry`, `p.stopping_decel_wet`, `p.stopping_decel_ice`, `p.curve_lateral_accel` and `p.lane_width_speed_time`.
  - The earlier batch's parameters are proposed again here with their values unchanged.
- **Stop definition:** "stop" is ambiguous between DEF-NRS-484A-255 and DEF-NRS-484A-260. Each states its own scope, so the plan reads 255 where a stop is required (307-9b) and 260 where it is prohibited (440-1).
