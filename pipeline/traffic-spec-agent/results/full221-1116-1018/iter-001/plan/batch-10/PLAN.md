# Plan — batch 10 (NRS 484B.210, 484B.213, 484B.413(2))

No law-local aggregates: `aggregates.jsonl` is empty. Every class word claims its admitted aggregate
(`DEF-NRS-484A-320::vehicle`, `DEF-NRS-484A-285::traffic`, `DEF-NRS-484A-020::authorized_emergency_vehicle`,
`DEF-NRS-484A-280::tow_car`, `DEF-NRS-484A-030::bus`). "Driver" is read through the vehicle's controlled
motion (observable_reading, agency).

## New concepts

- `drv.interaction.overtake_pass_on_right` — the proposed `drv.interaction.overtake_pass` (reused by id,
  same window and heading tolerance) plus the side: b lies on a's left (rel.bearing lateral component
  positive) at recognition and at every side-by-side observation (rel.longitudinal_overlap ≥ 0) since
  the act began. Act concept, window boundary. Used by 210-1, 210-2, 210-3. *Reversal signal:* the
  reviewer finds the side should come from lane order (`rel.ahead_behind_in_lane`, `st.lane_adjacency`)
  rather than the bearing.
- `drv.lane.heading_left_of_carrier` / `drv.lane.heading_right_of_carrier` — a moving road user's
  heading turned left (right) of a carrier's designated direction by more than `sin_tol` and still
  pointing along it. These are separate concepts because a literal formal cannot pick the side. They are
  state concepts, not acts. Used by 413-2 as the onset of a course change. *Reversal signal:* junction
  turns in the traces whose heading never departs from any occupied lane (the turn follows a junction
  connector lane from its first observation), which would call for a heading-change onset instead.

## Nodes

**NRS_484B_210_1** (gap, so it is not coded). Passing on the right (`overtake_pass_on_right`, b of vehicle)
is forbidden unless one of (a)–(d) holds. Each condition is read as an exception: (a), (b), (c) and (d)
must hold `throughout` the act, and the subsection-4 exemption (the 200-ft limit of (c)(1) does not apply)
must also hold throughout for its shoulder and sign spans. (a) is read as b's left indicator or arm
signal, or b's `drv.motion.left_turn` completed within the turn window ahead. "Sufficient width for two
or more lines" is a lane count, since a lane is "a strip of roadway for one line of vehicles". (c)(1)
uses `Term.distanceWhile` on the unmarked pavement (a paved shoulder, or roadway outside every lane)
against the literal 200 ft. Subsection 4's "Except as otherwise provided" pointer is a scope-none residue,
because its content is carried by spans s12–s21. The references to NRS 484A.480 and 484A.490 are
residues: those laws are outside the corpus. **Gap:** "past any private way that is used to enter or exit
the highway". `st.driveway_or_alley_entrance` is expressly not a stand-in for telling an alley's
entrance from a private road's or driveway's. Under DEF-NRS-484A-190 a private way excludes an alley,
and an alley is a public highway, so the distinction decides whether passing an alley mouth on the
shoulder is permitted. I proposed `st.private_way_entrance`. *Reversal signal:* an ontology revision
adds a kind attribute to the entrance atom that separates a driveway or private road from an alley.

**NRS_484B_210_2** (surrogate). The movement is "in safety" when, throughout the right-side pass, no
road user is in contact with the subject and none has a constant-velocity closest approach within
`p.conflict_horizon` closer than `p.conflict_centre_clearance`. It is marked surrogate because the
safety standard is the whole content of the duty: the act itself is lawful under 210-1. *Reversal
signal:* the operator classes "conditions permitting ... in safety" as a qualification of a concrete
duty, as in a hazard-qualified yield. That would drop the surrogate flag and change no formula.

**NRS_484B_210_3.** The duty is violated if, at some moment of the right-side pass, the subject's
footprint overlaps a shoulder with `paved` unset or a road edge whose surface beyond is unpaved. The
condition span is read `some_moment`. "Requires" is read through the movement as made. *Reversal
signal:* a label that counts a pass needing, but not making, a move off the pavement.

**NRS_484B_213_1.** The obligation span is one cut covering left of the centre line, the two-lane
two-directional highway and the act of overtaking (`drv.interaction.overtake_pass`). The validator
requires one obligation span holding the act. A pass on a wider road is therefore compliant, not
not-applicable. Left of centre means `prim.region_lateral_offset` to the `st.centre_line` on the
occupied highway is negative. Two-directional means a centre line lies on the way, which by its
contract divides one two-way roadway. Two-lane means one lane in each direction (`st.lane_adjacency`
count). The exception spans are read throughout the act, at the observations on the left side:
- the sight distance at the subject's point is at least its speed × `p.passing_sight_time` (MUTCD
  Table 3B-1 passing sight distance ÷ speed);
- every oncoming member of traffic is at least that far away;
- there is no conflict (contact, or a closest approach within `p.conflict_horizon` closer than
  `p.conflict_centre_clearance`) with an oncoming vehicle or with b.

*Reversal signal:* labels that judge visibility only at the start of the pass, which would read the
exception at the act's beginning instead.

**NRS_484B_213_2a / 2b / 2c.** These are three state rules with one obligation: the subject's reference
point is not left of the centre line of the highway it occupies. A one-way roadway exempts it in each.
- 2a applies where the subject is approaching a crest or is on a curve, and the sight distance is
  below speed × `p.passing_sight_time`. Approaching a crest means the velocity points toward the
  crest's reference point and the crest is within that same distance. On a curve means `st.curvature`
  is above `p.curvature_resolution`, the feature's presence.
- 2b applies within the literal 100 ft of an intersection or railway crossing while moving toward it,
  or while overlapping it.
- 2c applies within 100 ft of an `st.elevated_structure`, while moving toward it, with the view
  obstructed. That span is a standard bounded by the same passing-sight-distance convention.

"Approaching" is read by the velocity toward the region, not by `st.lane_enters`: a vehicle on the left
side occupies the opposing lane, which does not enter that junction. *Reversal signal:* a reviewer who
reads the crest or structure "approach" through an along-carrier offset (`prim.region_offset_along`).

**NRS_484B_413_2.** The trigger is a course change: the rise of `heading_left/right_of_carrier` for an
occupied lane. It is read only where the subject occupies a lane (definedWhen), and is unknown
elsewhere. The obligation is that the matching-side indicator or arm signal held at every observation
of a `.path` window. The window is the literal 100 ft where `asm.business_or_residence_district` holds
and the literal 300 ft where it does not (`Term.cond`). The words fix their own window, so this is not a
rule-4c search and has no history_boundary scenario. "Regardless of the weather" is a scope-none
residue. The window lengths are cut as condition spans so that the node carries one obligation span.
*Reversal signal:* a label that counts a turn signalled by its indicator only after the heading began
to turn.

## For the operator

- Gap on 210-1 s10 (`st.private_way_entrance`): the entrance atom cannot tell a private way from an
  alley. This blocks NRS-484B-210-1 only.
- New parameters proposed: `p.passing_sight_time` (11 s, MUTCD Table 3B-1),
  `p.curvature_resolution` (0.0005 1/m), and `p.course_departure_sin_tol` (0.035). The other
  parameters re-propose the values earlier batches proposed, unchanged.
- `rel.bearing` carries the unit m and gives no sign convention for its lateral component. The
  on-the-right concept assumes left is positive, as `prim.region_lateral_offset` states. A source
  with the opposite sign would swap the sides.
