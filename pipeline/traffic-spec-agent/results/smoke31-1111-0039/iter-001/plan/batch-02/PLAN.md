# Plan — batch 02 (iteration 001)

Eight law lines, fifteen nodes, seven new concept records. No law-local aggregates (`aggregates.jsonl` is empty): every road-user word is a use of a posted definition and claims its admitted id.

## Concepts proposed

- `drv.motion.halted` (DEF-NRS-484A-255, "complete cessation from movement"): speed at or below the resolution. The required stop of 250(4) and 257(1), and the halting of 270(3). DEF-NRS-484A-260 ("any halting, even momentarily") describes the same physical halt; its exceptions are legal, so the caller carries them. I made no second record for it. Reversal: a reviewer who wants the prohibited halt as its own record because some physical difference matters.
- `drv.motion.entering_region` / `drv.motion.leaving_region`: the observation at which a footprint overlap with a region begins or ends. These are the entry and exit events most yield duties here are judged at.
- `drv.position.entered_via`: x is in r on its current entry, and at that entry's first observation it also overlapped c. This is how "has entered … from" and "approaching from the opposite direction" read the carrier a road user came through. `rel.oncoming`'s contract says the direction of approach is read through that carrier, not through headings.
- `drv.road.opposed_directions`: the designated directions of two carriers are opposed within a tolerance. Region-only; it reads no road user.
- `drv.motion.turning_left`: moving, with yaw rate above the resolution and left positive.
- `drv.motion.slowing`: moving forward along the heading, with longitudinal deceleration above the resolution. This is the "slowed" of a yield sign.

Reused: `drv.motion.moving` and `drv.motion.heading_change_since_entry`, which an earlier batch proposed.

## Nodes

**NRS_484B_250_4_o1** — the stop owed when the signal is dark. Rule 4c applies: the halt is owed on the approach to the entry into the intersection. The event is the entry, on the carrier x occupies, while a governing signal is `dev.inoperative`. The places are the stop line, else the near-side crosswalk, else the point outside the intersection with a view of the crossing way. Each place is tied to the carrier by `st.entrance_of`, and the history bound follows the ontology's approach convention; `history_boundary` is planned. The validator requires exactly one obligation span per node, so "proceed as if a stop sign … at the point nearest the intersection" is one obligation span carrying the halt and all three places. "where the driver has a view of approaching traffic on the through highway" is a standard, bounded by `st.sight_along_way` ≥ `p.intersection_sight_distance` (AASHTO case B). Two readings are disclosed:
- "nearest" is not checked against other candidate points.
- With a dark signal, "the through highway" is read as the way the intersection lies on that the subject's carrier does not.

I did not claim the `traffic` aggregate on the view span: the sight atom measures the view whether or not any traffic is present. Reversal: a label that treats a halt at a viewpoint farther upstream as non-compliant would require "nearest" to be modelled; the closest available tool is an `operator` gap comparing points along the approach.

**NRS_484B_250_4_o2** — yield after the stop. The referring span is "After making such a stop," (s9); the words it refers to are o1's obligation (s4). It is carried as `compliance` with `NRS_484B_250_4_o1` (x→x). Applicability already requires the exact event o1 is engaged on (entry under a dark signal). So o1's compliance there is the qualified fact itself: the halt at the place, on this approach. It is not the weaker "not engaged". `branch_2` shows that a halt somewhere else on the approach does not make this duty arise. The yield is judged at entry and covers vehicles within the intersection, and vehicles that completed their stop on another approach before x's halt began and still wait there. "cautiously" is operationalized as no predicted conflict at entry (`prim.closest_approach_*`, `p.immediate_hazard_gap`, `p.conflict_clearance`). That operationalization is marked surrogate, because caution is a standard of care. Reversal: the gate rejecting a compliance composition on a node not yet coded. In that case the stop fact would be restated inline as o1's approach search.

**NRS_484B_250_1** — yield to a vehicle already in the intersection from a different highway. "approaching" is judged at x's entry from its approach carrier. "from a different highway" means the carrier y entered through lies (`st.on_way`) on a highway x's carrier does not. The device exception covers traffic signals, stop signs and yield signs governing the intersection or the approach. That narrowing is disclosed: markings and warning signs control no right-of-way. "Except as otherwise provided in subsection 4" is `unless` → `NRS_484B_250_4_o1`, scoped to the device exception, so the duty applies again at a dark signal. The opposite-direction/left-turn exception works per pair:
- the carriers are opposed;
- and either party declares `int.left_turn` (new id) or has turned at least `p.turn_recognition_angle` since entry.

Reversal: a corpus convention that "approaching" must be judged before the entry, not at it.

**NRS_484B_253_o1** — the left turner yields. x is in the intersection with `int.left_turn` declared. Yielding means not turning left (`drv.motion.turning_left`) while an opposing vehicle is in the intersection or is an immediate hazard. "So close thereto as to constitute an immediate hazard" is bounded as distance to the intersection ≤ speed × `p.immediate_hazard_gap` (HCM critical headway), so both proximity and speed enter the bound. Reversal: labels that count creeping straight ahead into the opposing path as failing to yield.

**NRS_484B_253_o2** — the others yield to the left turner. The referring spans are "having so yielded" (s8), referring to o1's s4–s7, and "having given a signal" (s9). s8 is `compliance` with `NRS_484B_253_o1` (x→y), required at every observation since y entered the intersection. Here the words require compliance with the yield rule, and y's engagement is guaranteed by the declared intention required beside it. s9 reads a left `sig.turn_indicator` or a left `sig.hand_signal`. "when and as required" refers to signalling law outside the corpus and is a residue. `branch_1` (no signal) and `branch_2` (y did not yield) each differ from `forbid` in one referred fact only. Reversal: the signalling section entering the corpus, which would turn s10 into a composition.

**NRS_484B_257_1_o1** — stop or yield at the place under a stop or yield sign. The structure is the same as 250(4) o1. The act depends on the sign:
- a stop sign requires a halt at the place;
- a yield sign requires a halt at the place, or slowing on the approach before passing it. This uses the second sentence's own words, "slowed or stopped".

The exception for a police officer or a traffic-control signal reads x as a member of `DEF-NRS-484A-285::traffic`. Its approach or the intersection must be governed by a `dev.human_direction` with role police_officer, or by a signal that is not inoperative. A dark signal is left to 250(4). The node id carries `_o1` because the law has two obligations. Reversal: labels that require a full halt at yield signs.

**NRS_484B_257_1_o2** — yield to through-highway traffic after the stop. "After having stopped or … slowed or stopped" (s9) refers to o1's s4. It is `compliance` with `NRS_484B_257_1_o1` on the same entry event, with the same reasoning as 250(4) o2; `branch_2` is the no-stop pair. The through highway is read as a way the intersection lies on that the subject's signed approach does not. The hazard is distance-to-intersection ≤ speed × `p.immediate_hazard_gap`, standing in for the subject's crossing time ("during the time such driver is moving across"). Reversal: through-highway designation becoming observable, for example as a `dev.zone_sign` kind or a road attribute.

**NRS_484B_263_o1 / _o2** — the controlled-access yield. The validator counts "shall yield" and "shall continue to yield … until" as two obligations, so the line has two nodes. "about to enter or exit" is read through the entry into, or exit from, the `st.controlled_access` region (an `observable_reading` of the intention category).
- o1: no moving vehicle on the highway in predicted conflict at the event.
- o2: reasonable safety. Every approaching vehicle of "that traffic" is at a surface gap ≥ its speed × `p.merge_time_headway`.

Reversal: `st.controlled_access` regions in the data that include their ramps, so the entry fires on the ramp rather than at the merge. That needs an atom separating ramp lanes from through lanes (not filed; the contract names "its entrance and exit lanes" as part of the atom).

**NRS_484B_297_6_o1 / _o2 / _o3** — a pedestrian going around a sidewalk obstruction. The situation they share: since leaving a sidewalk while within `p.obstruction_encounter_reach` of an `st.obstruction`, the pedestrian has been on that highway and off every sidewalk.
- o1: "may proceed with due care" binds the proceeding to due care. It is a surrogate (no predicted conflict).
- o2: (a), stay within `p.pedestrian_detour_offset` of the sidewalk. (c) is its exception.
- o3: (d), back on a sidewalk within `p.sidewalk_return_time` once no obstruction is within reach.

(b) is a residue of scope none, because no node restricts direction. **Gap** `st.impassable_section`: "a short section of the sidewalk that is missing or impassable", and the impassable area of (c), are not objects, so `st.obstruction` cannot carry them. Without the gap the trigger would be narrowed. Reversal: the coder writing the missing section with existing sidewalk geometry. If so, the gap is not filed.

**NRS_484B_270_3_o1** — yield to riders and to pedestrians covered by 297(6), on the bicycle lane. "the right-of-way" is treated as a standard span. The definition's "danger of a crash" is bounded by predicted conflict, because without a proximity bound any rider anywhere on the lane would bar a crossing. The pedestrian is limited by `condition` → `NRS_484B_297_6_o1` (x→y), the rule whose applicability is the 297(6) situation. Reversal: the reviewer rejecting a defined term as a standard span. Then the conflict bound moves into the obligation element as the definition's reading.

**NRS_484B_270_3_o2** — no entering, stopping, standing, parking or driving within a bicycle lane, except (a)–(f). The exceptions are in the applicability, so that `ruleApplies` of this node means "no exception holds" (used by 270(4)). Readings:
- (a): a driveway or alley entrance within `p.access_crossing_reach`;
- (c), purpose: a predicted conflict with other traffic when the lane was entered;
- (d), purpose: the vehicle's official or emergency class;
- (e): an officer governing.

**Gaps** `ru.disabled` (b) and `env.emergency` (f): nothing observable carries either. Reversal: either atom being admitted.

**NRS_484B_270_4** — no entering or crossing an intersection while driving in a bicycle lane. "Except as otherwise provided in subsection 3" is `condition` → `NRS_484B_270_3_o2`. That node's applicability holds exactly where none of (a)–(f) holds, so this duty applies only where subsection 3 provides nothing otherwise. Reversal: the coder of 270(3) o2 putting the exceptions in the obligation instead of the applicability. This composition would then need `as: exception` over a split node.

## Mapping consistency

"The driver of a vehicle" and "vehicles" reuse the index mapping (`ru.aggregate=DEF-NRS-484A-320::vehicle`). "within a pathway or lane provided for bicycles …" maps to `st.bicycle_lane_or_path` only. The bicycle, electric bicycle and electric scooter aggregates are not claimed there, because the words name a lane kind, not road users the duty turns on. They are claimed in 270(3) o1 s4, where riders are the parties.

## For the operator

- Three gaps were proposed: `st.impassable_section` (297(6), and through it the pedestrian half of 270(3) o1), `ru.disabled` and `env.emergency` (270(3)(b),(f)). If they are filed, 297(6), 270(3) and, through its composition, 270(4) wait on them.
- `p.immediate_hazard_gap` serves two roles across the batch: a time-to-arrival bound (253, 257(1)) and a closest-approach horizon (250(4) o2, 263, 270(3), 297(6)). The proposed value, 4.1 s, is the HCM left-turn critical headway. A crossing manoeuvre (257(1)) conventionally uses a longer headway. If the operator wants that difference, a second parameter is the fix; the rules name the parameter, not the value.
- `st.controlled_access` merges ramp lanes and through lanes. The 263 nodes judge entry and exit at the region's boundary.
