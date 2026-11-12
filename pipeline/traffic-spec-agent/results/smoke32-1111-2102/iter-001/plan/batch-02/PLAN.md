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
