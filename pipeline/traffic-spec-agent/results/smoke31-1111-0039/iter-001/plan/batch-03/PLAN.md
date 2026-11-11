# Plan — batch 03 (iteration 001)

Eight laws, sixteen nodes, four new concept records. No law-local aggregates (`aggregates.jsonl` is empty). The validator accepts every node and concept. Two gaps are annotated, both still mapped to their nearest atoms: `ru.disabled` on NRS-484B-440-1 and the operator `Formula.haltRequired` on NRS-484B-450-1c.

## New concepts

- **`drv.interaction.overtaking_alongside`** (x, y): the side-by-side phase of an overtaking, on either side, read from `rel.same_direction`, `rel.longitudinal_overlap` and `kin.speed`. It differs from `drv.interaction.passing_on_right` only in not reading `rel.bearing`. NRS-484B-270(7)(b) names no side, so the right-only concept would leave a pass on the left unjudged. *Reversal:* a catalogue concept for side-agnostic overtaking is accepted first; then that one is reused.
- **`drv.motion.u_turn`** (x), born from DEF-NRS-484B-077. It is an act with a window boundary: the size of `prim.heading_change` over the window lies within `reversal_tolerance` of the literal half turn. The band is two-sided because a loop past the half turn no longer "proceeds in the opposite direction". "upon a highway" goes to the caller. A residue records that a hairpin bend reversing within the window is not told apart, since no atom states the way's course along the path. *Reversal:* an atom or primitive giving the way's heading change along a road user's path; with it the concept would subtract the road's own turning.
- **`drv.motion.veering_left` / `drv.motion.veering_right`** (x, c): the velocity departs to one side of a carrier's designated direction by more than a sine tolerance while x moves forward along it. These are two concepts because a literal side formal cannot select a sign. Bends of the carrier are excluded, because the designated direction bends with it. *Reversal:* the operator adds a lane-change or course-change concept to the catalogue.

## Nodes

**NRS_484B_270_7b.** Binder x carries one of the bicycle, electric bicycle or electric scooter aggregates. Each motor vehicle x overtakes alongside is quantified inside the rule, not bound as a binder. "safely without endangering himself or herself or the occupants" is a standard qualifying a concrete duty, so the node is not a surrogate. It is operationalized by two bounds:
- the surface gap to the passed vehicle is at least the new `p.passing_lateral_clearance` (three-foot convention);
- the closest approach to every other road user stays above `p.conflict_clearance` within `p.immediate_hazard_gap`.

A narrowing discloses that surface, sight and balance are not read. *Reversal:* a label that judges the approach or return phase of a pass. That would need an act concept for the whole manoeuvre.

**NRS_484B_307_9a_o1 / _o2.** The validator counts one obligation span per node, so the line has two nodes: the permitted movement (o1) and the yield (o2). Only "Except as otherwise provided in paragraph (b)" is planned as a composition, `as: exception`, on NRS_484B_307_9b_o1. The 9b nodes share one applicability (listed classes, red with green arrow facing them at entry, straight-through or opposite-turn passage judged at leaving), so composing o1 alone covers all of them.
- **Subject, "vehicular traffic":** the traffic aggregate, minus the pedestrian aggregate. The word "vehicular" excludes pedestrians and animals. Cycles stay in, which the (b) carve-out confirms.
- **o1:** judged at the leaving observation, reading the sign and size of `drv.motion.heading_change_since_entry` against `p.turn_recognition_angle`.
- **o2:** "but must yield the right-of-way" is the standard span. It is operationalized as not moving while a party's predicted closest approach is inside the conflict radius within the critical gap (DEF-NRS-484A-210, "danger of a crash").
- **Parties yielded to (one obligation span):** "lawfully" is not read, so every such party is yielded to, which is stricter than the words. "adjacent crosswalk" is read as a crosswalk marking the entrance of some carrier into the intersection.
- **Advisory sentence:** carried as a residue. It requires nothing.

*Reversal:* a label that excuses yielding to a pedestrian crossing against a signal. Lawfulness would then need a composition with a pedestrian-signal rule.

**NRS_484B_307_9b_o1 … _o4.** The permission ("may proceed … if (1)–(4)") is read as a prohibition on the straight or opposite movement unless each condition holds. The movement span is therefore a trigger. Each of (1)–(4) is its own obligation span, and the four nodes together give the conjunction.
- **Trimobile:** a `scope: none` residue. Every three-wheeled motor vehicle with a seat already falls under DEF-NRS-484A-135's "not more than three wheels" and so under the motorcycle aggregate. *Reversal:* the reading classifies a three-wheeled class outside the motorcycle aggregate. Then an `ru.trimobile` atom gap is due.
- **o1:** a 4c history search under the approach convention. The place, in order, is the stop line marking the carrier, else the crosswalk marking it, else the intersection entrance. A sign indicating a stop point without a line is disclosed as not read. It plans `history_boundary`.
- **o2 (waiting):** a `Formula.count` of rises of the facing signal's red-with-arrow display since the halt run began, with the comparison "greater than" the literal two. The first rise opens the first complete cycle. "does not change because of a malfunction or failed detection" is an `observable_reading` of category `perception`: no indication permitting x's movement appears during the wait. It also plans `history_boundary`. *Reversal:* the operator reads a "cycle" as starting at the halt. Then the comparison becomes `ge`.
- **o3:** no-left-turn or no-right-turn signs whose conditions hold, or a red arrow toward the turn's side, governing the approach or the intersection. A straight-through passage meets it.
- **o4:** the same yield operationalization as 9a o2.

**NRS_484B_363_3.** The U-turn is an act (`drv.motion.u_turn`), so the node declares `occasion`:
- the zone span is read `some_moment`;
- each excepting element span ((a), (d) and (e) together with their beacon and sign spans) is read `throughout`, so an exception excuses only a turn it covers whole;
- the `occasion_*` pair is planned for each of those spans.

How each span is carried:
- **Zone:** the school or school-crossing `dev.zone_sign` and the regions it governs (§9: where a category is also signed, the sign is the atom).
- **(a) children present:** an `ru.child` within the new `p.child_presence_reach` of a governed region.
- **(b), (c), the class hours of (d):** the new assumptions `asm.school_not_in_session_day`, `asm.outside_school_operation_margin` and `asm.pupils_in_class`. School session and hours are legal calendar classes. The obligation states them throughout the act.
- **(d), (e):** beacon presence (status reading of "operational"), its flashing attribute, and `prim.conditions_hold` on the zone sign.
- **Beacon definition sentence:** a residue. `dev.speed_limit_beacon`'s contract already states it.

*Reversal:* a label that counts children on adjoining property as "present". That would widen the reach or call for a different reading.

**NRS_484B_400_1_o1 / _o2.** "if the highway has a right turn lane … or … the extreme right lane" is two obligations, so there are two nodes split on the condition. "as set forth in subsection 4 of NRS 484B.223" is a `definition` reference to both 4(a) and 4(b). It borrows "a single right lane to be used only for turning" and composes neither rule.
- **Intention:** "intends to turn" is a declared intention under the new `int.turn`; `int.left_turn` is too narrow.
- **Right turn:** "The turn is a right turn" is the heading change since entry reaching minus `p.turn_recognition_angle`.
- **Approach and turn:** read as occupying the required lane at entry and over the last `p.turn_approach_length` of path, a new `.path` window that claims `kin.path_length`.
- **Same approach:** a right turn lane counts only if it is on the same highway and not opposed in direction to the approach carrier.

*Reversal:* a labelled short turn bay entered within that length. That would argue for reading the approach from the intention onset instead.

**NRS_484B_413_2.** One node. The obligation span runs from "A signal of intention" to "100 feet traveled", because the validator counts one obligation span per node. The 300-foot clause and the district clauses are condition spans selecting the bound.
- **Signal:** `sig.turn_indicator` or `sig.hand_signal` on the departure's side. The words are a signal "of intention", so they are the signal itself, not an `int.*`.
- **Event:** the rise of a veering concept on an occupied carrier.
- **Window:** a `.path` window of the literal 100 ft or 300 ft. The district is selected by the new `asm.within_business_or_residence_district`, which is distinct from `asm.outside_business_district` because residence districts count too.
- **Weather sentence:** a `scope: none` residue.

A narrowing discloses that turns begun while occupying only an intersection, which carries no direction, are not recognized. *Reversal:* missed turn onsets in labelled data. That would argue for adding a heading-change-since-entry branch.

**NRS_484B_440_1_o1 / _o2 / _o3.** Three obligations: no stop on the roadway when off-road is practicable; free width opposite; clear view of 200 ft.
- **District:** the negated `asm.within_business_or_residence_district`.
- **Paved or main-traveled part:** `st.roadway`. A paved shoulder is off it.
- **Stop (o1):** a prohibited stop, so DEF-NRS-484A-260 applies. Its exclusions (a queue ahead within `p.stopping_conflict_gap`; an officer, red signal or stop sign governing) are carried beside `drv.motion.halted`. Park and stand are read through the halt (purpose reading).
- **"practicable":** a shoulder within `p.offroad_stop_reach`.
- **o2:** a lane beside x within `p.opposite_lane_reach`, at least `p.free_passage_width` wide, free of halted road users alongside.
- **o3:** `st.sight_distance` at least 200 ft. "in each direction" is disclosed as read through the single reported distance.
- **Disabled-vehicle exception:** mapped in all three nodes to `kin.engine_running` false with `sig.hazard`, the same as this iteration's earlier mapping of "a disabled vehicle". It is annotated with an atom gap `ru.disabled`, because neither atom denotes "cannot proceed under its own power".

*Reversal:* the operator accepts engine-off with hazards as the reading. Then the gap is withdrawn.

**NRS_484B_450_1c.** One node, judged wherever x occupies an intersection; any halt there violates unless an exception holds.
- **"necessary to avoid conflict":** operationalized with `rel.bearing` and `rel.surface_gap` against `p.stopping_conflict_gap`.
- **Officer or device directions:** `dev.human_direction`, red or flashing-red signals, and stop signs governing the intersection or the entry carrier.
- **"in compliance with law":** mapped to its nearest observables (an emergency vehicle with lamps or siren) and annotated with an operator gap. No operator reads "some rule requires the halt".

*Reversal:* the operator accepts the emergency-vehicle reading as sufficient. Then the gap is withdrawn.

## Mapping-index departures

- "the driver of a vehicle", "vehicle", "traffic", "pedestrian" and "within an intersection" keep the index's atoms.
- "shall yield the right-of-way" maps differently from the index (`drv.motion.entering_region`). In 9a and 9b the duty runs through the whole passage after an entry already made, so it reads `drv.motion.moving` with the closest-approach primitives under a standard span.
- "a disabled vehicle" reuses the index's `kin.engine_running`/`sig.hazard`, now with a gap.

## For the operator

- **`ru.disabled` (atom gap, NRS-484B-440-1, all three nodes):** "disabled … impossible to avoid stopping" has no atom. The nodes use engine-off with hazards. Accept that reading, or add the atom. The same question applies to the earlier mapping of "(b) … a disabled vehicle" in NRS_484B_270_3_o2.
- **`Formula.haltRequired` (operator gap, NRS-484B-450-1c):** "in compliance with law" excuses any halt some rule requires. The node reads only an emergency vehicle showing lamps or siren.
- **New parameter values awaiting review:**
  - `p.passing_lateral_clearance` 0.9 m
  - `p.u_turn_window` 20 s
  - `p.u_turn_reversal_tolerance` 30 deg
  - `p.child_presence_reach` 5 m
  - `p.turn_approach_length` 15 m
  - `p.course_departure_sine` 0.05
  - `p.offroad_stop_reach` 5 m
  - `p.free_passage_width` 3 m
  - `p.opposite_lane_reach` 1 m
  - `p.stopping_conflict_gap` 5 m
- **New declared-fact ids:**
  - `asm.within_business_or_residence_district`
  - `asm.school_not_in_session_day`
  - `asm.outside_school_operation_margin`
  - `asm.pupils_in_class`
  - `int.turn`

  A source must declare `int.turn` separately from `int.left_turn`.
- **9b cycle count:** NRS-484B-307(9)(b)(2) is read strictly: two cycles completed during the wait need more rises of the red-with-arrow display than the literal two. If the operator's convention counts the cycle in progress at the halt's start, change `gt` to `ge`.
