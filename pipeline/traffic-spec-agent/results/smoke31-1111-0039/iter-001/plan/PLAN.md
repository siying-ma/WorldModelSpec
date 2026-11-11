<!-- batch-01 -->
# Plan — batch 01 (iteration 001)

Eight law lines, nine nodes, seven concept records, one atom gap. No law-local aggregates
(`aggregates.jsonl` is empty): none of these clauses defines, adds or excludes members of a class.

## Nodes

**LVMC_11_38_030 — sidewalk riding.** The subject is `ru.aggregate=DEF-NRS-484A-135::motorcycle`
plus "motor scooter". No definition or aggregate applies to "motor scooter", so it is carried by
`ru.moped` and `ru.electric_scooter`, the classes whose contracts denote a scooter driven by a motor.
A scooter above the moped class already belongs to the motorcycle aggregate. "be ridden upon any
sidewalk" is read as `drv.motion.moving` while the vehicle occupies an `st.sidewalk`, disclosed as
an agency reading; a parked machine is not ridden. "of the City" is the legal region class
`asm.within_city_limits`. Reversal signal: if the operator reads "motor scooter" as excluding
stand-up electric scooters, drop `ru.electric_scooter` from the subject.

**LVMC_11_43_010_A — roundabout direction.** The subject is a vehicle (the admitted aggregate) that
occupies an `st.roundabout`. The obligation is that the vehicle is not moving clockwise about the
roundabout's reference point (`drv.motion.clockwise_about_region`). Clockwise is tested by the
sign of the cross product of the radius vector and the velocity, beyond a sine tolerance. Entering
or leaving radially, and standing still, are neither sense, so they comply. The reading that the
region's reference point is the centre of the circulatory roadway is disclosed. Reversal signal:
a source whose roundabout reference point is not near the island centre (see below).

**NRS_484B_113_2 — backing.** One obligation span covers three alternatives:
- `drv.motion.reversing` at the rise of occupancy of an `st.intersection` ("into");
- reversing while occupying an `st.crosswalk` ("on or over");
- reversing and `drv.motion.yawing` while occupying an intersection ("around a … corner").

"street" (DEF-NRS-484A-265, inside city limits) limits only the third alternative. It is carried by
`asm.within_city_limits` on its own span, and the coder joins it to that alternative alone.
"corner" is a condition span read as the intersection region. Backing is read from velocity against
heading, never from `kin.gear`. Reversal signal: a labelled scene that backs around a corner outside
any mapped intersection region.

**NRS_484B_127_3 — caravan spacing.**
- The subject is the admitted motor-vehicle aggregate on an `st.highway`.
- "outside of a business district" is `asm.outside_business_district`.
- "whether or not towing" is a scope-none residue: the duty is the same either way.
- The obligation is a longitudinal `rel.surface_gap` to the vehicle or combination (both admitted
  aggregates) ahead in the lane.
- The standard "so as to enable … to enter and occupy such space without danger" is bounded by
  `p.entering_combination_length` plus `p.entry_time_headway` × speed, once ahead of and once behind
  the entering vehicle (a gap-acceptance convention). It is not a surrogate: the standard qualifies
  a concrete spacing duty.

"in a caravan or motorcade" has no observable counterpart. Group membership is neither a
purpose that conduct reads nor a legal region class, and ordinary following looks the same. It is
mapped to the nearest atoms (`rel.ahead_behind_in_lane`, `rel.same_direction`) and filed as atom
gap `ru.procession_member`. Reversal signal: the operator accepting a following-based reading, or
admitting the atom.

**NRS_484B_210_3 — passing on the right off the pavement.** The condition "requires driving off
the paved portion" is read by the movement as made: the vehicle occupies an `st.shoulder`, or an
`st.road_edge`, whose paved attribute is false. The obligation is that the vehicle passes no vehicle
on its right (`drv.interaction.passing_on_right`: aligned headings, side by side, the other on the
subject's left, the subject faster). The pass is judged at its side-by-side phase, disclosed as a
narrowing. The other vehicle is quantified, not bound, so a vehicle alone on the shoulder is decided
compliant. Reversal signal: a labelled pass made off the pavement that never comes alongside.

**NRS_484B_223_4a — right turn lane used only to turn right.**
- The singled-out lane L is an `st.turn_lane` of side right on an `st.highway`.
- "single" means no adjacent lane (`st.lane_adjacency`) is also a right turn lane.
- "only for the purpose of making a right turn" is a purpose reading, judged by how the vehicle
  leaves L. It violates by leaving L for the adjacent lane on its left short of the intersection
  L enters (`st.lane_enters`).
- It also violates by leaving that intersection, having entered it from L, with a heading change
  since entry (`drv.motion.heading_change_since_entry`) short of minus `p.turn_recognition_angle`.

Reversal signal: a labelled lane exit to the left that the words treat as permitted.

**NRS_484B_223_4b — no travel through from the right turn lane.** It uses the same lane selection
as 4a. "travel through an intersection" is read as entering the intersection L enters while
occupying L, then leaving it without a right-turn heading change. Straight and left passages alike
violate. A through passage from the turn lane violates both 4a and 4b, as both lines say.

**NRS_484B_227_1_o1 and NRS_484B_227_1_o2 — divided highway.** The line has two "must" clauses, so
it has two nodes. A divided highway is an `st.highway` on which an `st.median_or_divider` lies.

- **o1 (right-hand roadway):** the vehicle does not move against the designated direction of a
  roadway of that highway it occupies (`drv.motion.against_carrier_direction`). This reads "the
  right-hand roadway" under right-hand traffic. Crossing a roadway at a wide angle is not against it.
- **o2 (dividing section and turns):** the vehicle neither occupies a median region nor moves
  against a roadway's direction. Both are excepted where it occupies a median region with the
  opening attribute (opening, crossover) or an `st.intersection`. "established by a public
  authority" is a status reading of the feature's presence.

The turns in o2 are read through their outcome: crossing the dividing section, or "so as to proceed
in the opposite direction" (DEF-NRS-484B-077). This is disclosed as a narrowing. A wrong-way
vehicle that never turned is judged by o2 too. Reversal signal: a labelled wrong-way entry from a
ramp that is expected not to violate o2. Then o2 would need a turn act concept (occasion
machinery) instead of the outcome reading.

## Concept records

All are states or quantities at an observation, so none declares an act and no node needs an
`occasion`.
- `drv.motion.moving`: speed above resolution.
- `drv.motion.reversing`: velocity component along heading below minus resolution, never gear.
- `drv.motion.yawing`: absolute yaw rate above resolution.
- `drv.motion.clockwise_about_region`: sense of motion about a region's reference point.
- `drv.motion.against_carrier_direction`: velocity against `st.lane_direction`.
- `drv.interaction.passing_on_right`: the side-by-side phase of an overtaking on the other's right.
- `drv.motion.heading_change_since_entry`: a quantity, the heading change since the footprint
  entered a region.

## Parameters proposed

`p.speed_resolution`, `p.yaw_rate_resolution`, `p.circulation_sine_tolerance`,
`p.opposed_direction_cosine`, `p.same_direction_cosine`, `p.overtaking_speed_margin`,
`p.turn_recognition_angle`, `p.entering_combination_length`, `p.entry_time_headway`. Each proposal
states its convention and source. The `headingSince` step bound is the catalogue's
`p.heading_since_step_carla_scene_graph`.

## For the operator

- **Gap `ru.procession_member` (NRS-484B-127-3, span "in a caravan or motorcade"):** nothing in the
  ontology tells a member of an organized motorcade from ordinary following traffic. The law stays
  blocked until the atom is admitted, or until a following-based reading is approved.
- **Roundabout centre:** LVMC-11-43-010-A relies on the `st.roundabout` reference point
  (`st.region_geometry`) lying at the centre of the circulatory roadway. The adapter's manifest
  should confirm this for `carla_scene_graph`; otherwise the clockwise test is taken about the wrong
  point.
- **"motor scooter":** LVMC 11.38.030 uses an undefined term. The plan includes mopeds and electric
  scooters. Please confirm or narrow this reading.
- **Attribute-valued kinds:** several nodes read attribute values: `st.turn_lane` side right,
  `st.median_or_divider` opening, and the paved attribute of `st.shoulder` / `st.road_edge`. The
  plan names the atoms and states the values in the justifications. The coder reads them through
  the atoms' attributes.

<!-- batch-02 -->
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

<!-- batch-03 -->
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

<!-- batch-04 -->
# Plan — batch 04 (iteration 001)

Six nodes over five laws. Two new concept records: `drv.position.within_clearance_since_entry` and
`drv.motion.stopping_distance`. Reused concepts from earlier batches: `drv.motion.moving`,
`drv.motion.halted` and `drv.motion.entering_region`. No law-local aggregates. One atom gap, on
NRS-484D-100-1(c).

## NRS_484B_560_7a — complete the railroad crossing without stopping

**Decision.** The subject is a vehicle (`ru.aggregate=DEF-NRS-484A-320::vehicle`). The duty applies
while the vehicle is crossing a railway level crossing and has not completely crossed it. That state
is the new concept `drv.position.within_clearance_since_entry(x, r; clearance)`: it is true from the
vehicle's entry onto `st.railway_crossing` until its body outline stands at the clearance or more
from the crossing region (`st.region_geometry`). The clearance is the section's own literal, 15 ft.
Once the body has left the crossing, the trailing end is the point of the outline nearest the
crossing, so this distance measures the section's definition of "completely cross". While the duty
applies, the vehicle must not halt (`drv.motion.halted`, with no minimum duration, as in "any
halting, even momentarily").

**Reasons.**
- The causes "due to insufficient (1) space … or (2) undercarriage clearance" say why the vehicle
  stops. Neither cause is observable. Following the ontology's convention on purpose, they are read
  through the conduct they explain: a halt before the crossing is complete. This is disclosed as an
  `observable_reading` of category `purpose`.
- The definition of stopping excepts a halt "necessary to avoid conflict with other traffic". That
  exception is deliberately not read. Clause (1) makes a halt forced by queued traffic beyond the
  crossing the very violation, so reading the exception in would empty clause (1).
- The other part of the exception, a halt directed by a police officer, is carried
  (`dev.human_direction`, role `police_officer`, indication `stop`, governing the region the vehicle
  occupies).
- Directions from a device are not read. No official device directs a halt on the tracks: a signal
  or stop sign further on directs a halt at its own line, and queueing on the tracks for it is
  clause (1).
- "Nearest rail" is read as the boundary of the crossing region.

**Reversal signals:**
- A label that excuses a halt on the tracks behind a queue.
- An ontology atom for undercarriage clearance or for the crossing's vertical profile; that would
  let clause (2) be read on its own evidence.

## NRS_484B_600_1a — basic speed rule (surrogate)

**Decision.** The duty is a standard, so the node is marked surrogate. The subject is a moving
vehicle (`drv.motion.moving`). Each factor the words name has its own bound, and the speed enters
every bound:
- **Surface and weather.** The stopping distance (new quantity concept
  `drv.motion.stopping_distance`) uses a braking deceleration chosen by the surface: ice or snow,
  else wet or precipitation, else dry.
- **Other highway conditions.** The stopping distance must not exceed the sight distance
  (`st.sight_distance`). The speed squared times the road's curvature must not exceed a lateral
  acceleration.
- **Weather.** The stopping distance must not exceed the visibility distance (`env.visibility`).
- **Width.** A lateral margin proportional to speed must fit between the lane's width and the
  vehicle's width.
- **Traffic.** A time headway to every road user ahead in the same lane.

**Reasons.**
- The traffic aggregate is not claimed. The validator does not accept an aggregate inside an
  operationalization. A road user in the lane ahead is, by the definition's words, traffic "using
  any highway for purposes of travel", so the rule reads every such road user whatever its class.
- Each narrower reading (highway width read as lane width; the catch-all read only through sight
  distance and curvature) is disclosed on the standard span.

**Reversal signals:**
- Labelled verdicts that disagree systematically with one bound: tune that bound's parameter, or
  drop the bound.
- The operator rejecting the lateral-margin convention for width.

## NRS_484B_769 — cyclist and scooter signals by hand and arm

**Decision.** The subject belongs to one of three aggregates: bicycle, electric bicycle or electric
scooter. The rule applies on a roadway whenever the rider shows a signal, either a lit turn
indicator or an arm signal. The signal must then be given by arm (`sig.hand_signal` other than
`no_signal`), and its meaning must match any lit indicator. A left indicator matches either `left`
or `re_enter`, because NRS 484B.420 uses the same horizontal arm for both.

"In the manner required by NRS 484B.420" is a `definition` reference to DEF-NRS-484B-420. Its four
listed meanings are exactly the values of `sig.hand_signal`. The right-arm alternative in the
exception decodes to the meaning `right`, so it is accepted.

**Reason.** `sig.hand_signal` records only the meaning of a signal, not which arm or side gave it.
This is disclosed as a narrowing.

**Reversal signal:** an atom for arm posture (which arm, which side). With it, the manner could be
checked directly.

## NRS_484D_100_1 — when lighted lamps are required

**Decision.** The subject is a vehicle on a highway that is not parked. The rule applies at any one
of three times:
- (a) `env.darkness`, with its sunset/sunrise boundary set to the literal one-half hour;
- (b) `env.visibility` below the literal 1,000 ft, an `observable_reading` of category
  `perception`;
- (c) a sign directing lamps on, which is an atom gap.

The list is joined by "and", but it names the times at which the duty arises, so any one of them
suffices. The obligation is headlamps lit (low or high beam).

**Reasons.**
- The parked-vehicle exceptions point to the chapters' provisions on parking lamps. They are read as
  excusing a parked vehicle (at a standstill with its engine off) from this headlamp duty.
- The class-by-class lamp sets "as respectively required in this chapter" are not in the corpus.
  They are a residue on the reference span, and the headlamp reading is a disclosed narrowing.
- "Of this State" is a residue of scope `none`, because the run applies Nevada law.

**Reversal signals:**
- The parked-vehicle lamp provisions entering the corpus: compose them as `unless` on s4.
- A source showing that trailers are separated from their combinations.

## NRS_484D_215_1_o1 — multiple-beam use: reveal at a safe distance (surrogate)

**Decision.** The subject is a motor vehicle being operated (moving, or with its engine running) on
the roadway or shoulder. "During the times specified in NRS 484D.100" is a composition `as:
condition` on `NRS_484D_100_1`. That is the referred state itself: the composed rule's applicability
is exactly those times, for the same vehicle. "Subject to the following requirements and
limitations" composes `NRS_484D_215_1_o2` `as: exception`.

The obligation is a beam lit. Wherever the stopping distance exceeds the low beam's reveal distance,
the beam must be the high beam. The safe-distance standard is the whole content of this duty, so the
node is marked surrogate.

**Reason.** Beam aim and intensity are not observed. They are read through the beam state.

**Reversal signals:**
- Urban night recordings labelled compliant with low beams at moderate speed. That points either to
  `p.low_beam_reveal_distance` or to missing street-lighting evidence, which no atom carries.

## NRS_484D_215_1_o2 — dim for an oncoming vehicle within 500 feet

**Decision.** The trigger (motor vehicle being operated, roadway or shoulder, the times of 484D.100)
is shared with o1. The rule also needs a road user of the vehicle aggregate, other than the subject,
that is oncoming (`rel.oncoming`, headings opposed and closing). Its surface gap must be within the
literal 500 ft. The obligation is low beam.

The deeming sentence and its reference to DEF-NRS-484D-210-1-2 make the low beam compliant
regardless of road contour and loading. The validator allows one obligation span per node, so those
words are segmented as `definitional`. High beam is read as projecting glare; headlamps off do not
"use a distribution of light".

**Reversal signal:** a source that observes beam aim, or adaptive high beams that mask the oncoming
driver.

## Concept records

- **`drv.position.within_clearance_since_entry`** is a state, not an act. It counts from the
  observed entry onto the region (past operator `since`) until the body outline first stands at the
  clearance or more from it. The side of the region is not distinguished, and the contract says so.
- **`drv.motion.stopping_distance`** computes speed × reaction time plus speed² over twice the
  deceleration. Both inputs are formal parameters. It carries no adequacy bound: the calling rule
  compares the distance with its standard.

## For the operator

- **Gap on NRS-484D-100-1(c), "When directed by an official traffic control device".** No catalogue
  code of `dev.regulatory_sign` directs road users to display lamps. The proposal is a lamps-on sign
  (`dev.lamps_on_sign`, or equivalently a code `lamps_on` of `dev.regulatory_sign`). The validator
  only accepts a new id at the head of the proposal, which is why it is written that way. If the gap
  is filed, it blocks NRS_484D_100_1. Through their `as: condition` composition it also blocks both
  NRS_484D_215_1 nodes.
- **Parameter values proposed for review:**
  - `p.perception_reaction_time`: 2.5 s
  - `p.braking_decel_dry` / `p.braking_decel_wet` / `p.braking_decel_ice`: 4.5 / 3.4 / 1.5 m/s²
  - `p.curve_lateral_accel`: 3.0 m/s²
  - `p.lateral_margin_time`: 0.02 s
  - `p.traffic_time_headway`: 1.0 s
  - `p.low_beam_reveal_distance`: 30.48 m, from the 100 ft lowermost-beam figure of NRS 484D.210(2)
  - `p.oncoming_heading_cosine`: 0.7

  With the low-beam reach at 100 ft, NRS_484D_215_1_o1 requires high beams above roughly 10 m/s at
  night. This is the strictest consequence of the surrogate, so review it first.
- **The definition of "stopping" against NRS-484B-560-7a.** DEF-NRS-484A-260's exception for
  traffic conflict would void clause (1) if applied literally. The plan does not apply it. Confirm
  this reading in the reading convention.
