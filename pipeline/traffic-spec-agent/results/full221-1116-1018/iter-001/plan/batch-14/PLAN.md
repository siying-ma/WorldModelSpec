# Plan — batch 14 (NRS 484B.267(2)(c)–(f), 484B.270(1)–(2)(b), 484B.297(6))

No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the nodes reuse
`drv.interaction.overtake_pass`, `drv.lane.heading_right_of_carrier` and `drv.motion.complete_halt`,
all proposed earlier this iteration.

## Shared reading of NRS 484B.267(2)

All five 267(2) nodes use the same cut of the common lead-in.

- **s1, trigger.** The opening words through "in any direction" form one span. It carries the
  approach and the vehicle's class: the admitted authorized-emergency-vehicle aggregate or
  `ru.official_vehicle` of kind `regulatory_agency`. It also carries the vehicle's state, moving or
  preparing to move. This keeps the occasion scenarios of 2d to four spans.
- **Approach.** The subject is moving and has the vehicle ahead (`rel.bearing`), within
  `p.emergency_approach_reach` (`rel.centre_distance`). This reuses the atoms and parameter of
  NRS_484B_267_2a's "Upon approaching".
- **Preparing to move.** The section defines this as a visible indication. It is read as
  `rel.visible` plus an arm signal or a lit turn indicator, or as the vehicle's own movement. The
  intention and perception readings are disclosed on s1, because the validator does not accept a
  narrowing on a definitional span.
- **Flashing lights.** The words "subsection 3 of NRS 484A.480" are a `definition` reference to
  DEF-NRS-484A-480-3. They borrow "at least one flashing red warning lamp visible from the front",
  so the lamp is `sig.warning_lamp` red, flashing, facing front.
- **Examples.** The "arriving at or leaving the scene" list adds no restriction and is a residue
  with scope `none`.
- **Officer exception.** The officer is `dev.human_direction` of role `police_officer`, governing
  a travel region the subject occupies.
- **Reversal signals.**
  - A labelled case where the vehicle approaches from behind and the label expects 267(2) to apply
    would widen the approach to mutual closing, which needs `kin.velocity`.
  - A case where a blue-only light bar triggers the duty would drop the colour constraint.

## Nodes

**NRS_484B_267_2c — accept.**
- **Decision.** "Be prepared to stop." is the whole obligation and has no observable meaning of its
  own. It is a surrogate. The subject's stopping distance (reaction plus braking, deceleration
  chosen by ice, wet road or dry) must not exceed the body gap to the vehicle (`rel.surface_gap`).
- **Definition of "stop".** "Stop" is ambiguous between two definitions. DEF-NRS-484A-255 ("when
  required") is the reading, because the stop here is one the driver must be ready to make.
- **Reversal signal.** A label that treats any slowing as preparedness would replace the model with
  a deceleration check.

**NRS_484B_267_2d — accept.**
- **Decision.** Two prohibited behaviours, each re-binding the approached vehicle:
  - "Overtake" is `drv.interaction.overtake_pass`, an act with window `p.overtake_window`.
  - "Drive abreast" is side by side (`rel.longitudinal_overlap ≥ 0`) while the subject moves. This
    is a disclosed narrowing.
- **Condition.** The vehicle is moving with aligned headings.
- **Occasion.** The trigger, lamp and condition spans are read `some_moment` of the pass. The
  officer exception is read `throughout`. The four pairs of occasion scenarios are planned.
- **Reversal signal.** A label that counts a stationary subject being passed as "abreast".

**NRS_484B_267_2e — accept.**
- **Adjacency.**
  - A lane is adjacent when it is the same-direction neighbour (`st.lane_adjacency`).
  - For a vehicle moving the opposite way, the two leftmost lanes (ordinal 1) are adjacent when
    their directions are opposed on one shared `st.roadway`. A divided highway's separate
    roadways are never adjacent.
  - The vehicle's own lane is not adjacent to itself, which is the literal reading.
- **"If possible"** is operationalized two ways:
  - The approach must have lasted `p.emergency_lane_change_window` (new parameter).
  - A candidate lane must exist: a lane of the subject's direction on the same highway that is not
    adjacent to the vehicle's lane.
- **"Unless … unsafe or impossible"** excuses the duty where:
  - every candidate lane is closed (`dev.temporary_traffic_control`), or
  - every candidate lane is blocked by a road user nearer than speed × headway (headway chosen by
    surface), or
  - the road is icy, or
  - visibility is below speed × the lane-change time.

  The catch-all "other conditions" is read only through these, which is disclosed.
- **Traffic in the gap check.** The gap check reads any road user other than the subject. The
  validator rejects an aggregate in an operationalization's concepts, and the posted definition of
  traffic ("pedestrians, ridden or herded animals, vehicles and other conveyances") covers every
  road user on the highway.
- **Reversal signal.** A label that treats following the vehicle in its own lane as a breach.

**NRS_484B_267_2f_o1 — accept.**
- **Decision.** "Proceed" is the obligation span, carried by the subject's motion. "As required
  pursuant to subsection 1 […]" is a reference span. It is carried by four `compliance`
  compositions: NRS_484B_267_1a, NRS_484B_267_1b_o1, NRS_484B_267_1b_o2 and NRS_484B_267_1c.
- **Condition.** "Approaches the driver's vehicle" is the vehicle moving with the subject ahead of
  it, within the approach reach.
- **Narrowing.** Together with the subject's own approach, this applies to head-on closing only. A
  vehicle coming from behind is still governed directly by the subsection 1 rules.
- **Reversal signal.** The same as for the shared approach reading.

**NRS_484B_267_2f_o2 — returned by the validator.**
- **Decision.** "Stops" is `drv.motion.complete_halt` on the vehicle. It must have held at every
  observation since an observation at which the trigger held (the past mirror of until). This
  bounds the history by the halt's onset. "As required pursuant to NRS 484B.607 […]" is a
  `compliance` composition of NRS 484B.607's nodes.
- **Why it is returned.** No NRS 484B.607 node is accepted or planned. The validator therefore
  rejects the compositions (NRS_484B_607_1a … _1d).
- **Why it is not worked around.** The duty is compliance with that section. Inlining it is
  forbidden, and dropping it would lose the duty. The record is kept as written.
- **Reversal signal.** Once NRS 484B.607 is planned, re-run with its actual node ids, which may
  carry `_oN` suffixes.

**NRS_484B_270_1 — accept, carries an operator gap.**
- **Decision.** "intentionally interfere" is a state of mind and is a surrogate. Interference is
  read as either:
  - contact, or
  - a closest-approach conflict (`p.conflict_horizon`, `p.conflict_centre_clearance`) during which
    the rider brakes beyond `p.rider_evasive_decel` (new parameter).
- **Gap.** "Lawfully riding" restricts the protected riders to those whose conduct is lawful. The
  ontology reads that only through rule composition, and the words name no rule. So the span is
  an `operator` gap: `lawful(who)`. This is close to, but not the same as, the pending G22 ("in
  compliance with law"). The law stays blocked until it is resolved.
- **Reversal signal.** An operator decision that "lawfully" adds no restriction (scope `none`)
  would remove the gap.

**NRS_484B_270_2a_o1 / NRS_484B_270_2b_o1 — accept (surrogate).**
- **Decision.** "shall exercise due care and:" is an obligation of its own: a standard of care,
  which is a state of mind. Each line gives it its own node, so that the surrogate does not
  contaminate the concrete lane and clearance duties.
- **Reading.** It is read through the outcome of the pass: no contact, and no evasive braking by
  the rider while the two are side by side.
- **Trigger.** "When overtaking or passing" is `drv.interaction.overtake_pass` plus
  `rel.longitudinal_overlap`, with the same atoms in all five 270(2) nodes. The duty is judged at
  the pass's recognition over the window behind.
- **Reversal signal.** A label that judges care by the lateral gap would merge it into the
  clearance node.

**NRS_484B_270_2a_o2 — accept.**
- **Condition.** More than one lane exists: the rider's lane has a same-direction count greater
  than 1 (literal).
- **Obligation.** At every side-by-side observation of the pass, the subject is wholly in the left
  neighbour of the rider's lane.
- **Standard.** "If the lane is available and moving into the lane is reasonably safe" is read at
  the pass's start, the last observation at which the rider was ahead. The lane is available and
  safe when its left neighbour exists, is not closed, and has no road user nearer than speed ×
  headway.
- **Traffic.** In "lanes for traffic", "traffic" names the lanes' direction, which
  `st.lane_adjacency` carries. No membership is read, and no aggregate is claimed. This matches
  the index's precedent for "path for bicycles … has been provided".
- **Reversal signal.** A label that accepts a partial lane change (straddling) as compliance.

**NRS_484B_270_2b_o2 — accept.**
- **Condition.** Only one lane (literal 1).
- **Obligation.** "Pass to the left" means that while side by side, the rider is on the subject's
  right (`rel.bearing` lateral component negative).
- **Clearance.** "At a safe distance, which must be not less than 3 feet …" is one standard span.
  The body gap (`rel.surface_gap`, "any portion of the vehicle") must be at least the larger of
  the literal 3 ft and `p.bicycle_pass_safe_gap` (new parameter).
- **Reversal signal.** A label expecting a speed-dependent clearance.

**NRS_484B_270_2b_o3 — accept.**
- **Obligation.** "Shall not move again to the right side of the highway" is
  `drv.lane.heading_right_of_carrier` on the rider's lane, after the subject has the rider on its
  right.
- **Standard.** "Until … safely clear" means the rider is behind the subject with a gap of at
  least the rider's speed × headway, headway chosen by surface.
- **Reversal signal.** A label that counts a slow drift back as a move.

**The 270(2)(b) authorization sentence.** It permits passing left of the center or in a no-passing
zone. That relaxes NRS 484B.213 and 484B.217, not this paragraph.
- In all three 2b nodes it is an exception span carried as a residue with scope `none`.
- Its "Except as otherwise provided in NRS 484B.213 and 484B.217 […]" reference is carried by five
  `unless` compositions scoping it, as rule 5 requires.

**NRS_484B_297_6_o1 / NRS_484B_297_6_o2 — accept, carry an atom gap.**
- **Trigger.** The pedestrian, on a sidewalk, came within `p.obstruction_encounter_reach` of an
  obstruction. Since then it has been off every sidewalk and on a travel region of the same
  highway.
- **"On the sidewalk".** No atom relates the obstruction's region to the sidewalk's. These words are
  read through the pedestrian being on that sidewalk when it meets the object.
- **(a).** The body must be within `p.pedestrian_side_margin` of the sidewalk, or of the obstruction
  where it reaches off the sidewalk.
- **(d).** A pedestrian still off the sidewalk after a full `p.pedestrian_return_window` beyond the
  obstruction violates the duty.
- **Permissions.**
  - "With due care" qualifies the permission and is a residue with scope `none`.
  - (b) does not change (a) or (d) and is a residue with scope `none`.
  - (c) is an exception of (a) and a sibling in (d).
- **Gap.** "A short section of the sidewalk that is missing or impassable" extends the trigger
  beyond objects, and (c)'s "area … impassable" needs the same notion. Neither is an
  `st.obstruction`. Both are the atom gap `st.impassable_section`, the same proposal as the pending
  smoke31-1111-0039:G18. The law stays blocked until it is decided.
- **Reversal signal.** An operator ruling that an excavation-kind obstruction covers a missing
  section.

## For the operator

- **NRS 484B.607 has no node.** NRS_484B_267_2f_o2 composes its rules (`compliance`) and is
  returned only for that reason. Plan NRS 484B.607 first. Then re-run 2f with the actual node ids.
- **Proposed operator gap `lawful(who)`.** Raised on NRS 484B.270(1) "a person lawfully riding".
  Consider it together with G22 ("or in compliance with law"). Both need compliance with every
  engaged rule rather than one named rule.
- **Pending atom gap G18 (`st.impassable_section`).** It is carried again on NRS 484B.297(6).
- **New parameters.** `p.emergency_lane_change_window`, `p.rider_evasive_decel`,
  `p.bicycle_pass_safe_gap`, `p.obstruction_encounter_reach`, `p.pedestrian_side_margin`,
  `p.pedestrian_return_window`.
