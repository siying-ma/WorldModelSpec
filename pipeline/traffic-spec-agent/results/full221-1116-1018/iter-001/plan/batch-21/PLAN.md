# Plan — batch 21 (iteration 1)

Eleven nodes for eight law lines. No new concept records: every manoeuvre or state of motion is a
concept already proposed in this iteration (`drv.motion.u_turn`, `drv.motion.complete_halt`). No
law-local aggregate (`aggregates.jsonl` is empty). Two kinds of gap are filed: the atom gap
`ru.disabled` (NRS-484B-440-1, three nodes) and the operator gap for "in compliance with law"
(NRS-484B-450-1a/1c/1e). Those six nodes are not coded until the operator decides the gaps.

## NRS_484B_403_3 — no U-turn in a business district

**Decision.** The act is `drv.motion.u_turn` on the vehicle aggregate. The definition DEF-NRS-484B-077
says "upon a highway", which the concept does not carry, so the rule carries it beside the concept:
`rel.occupies` of an `st.highway`. The index maps "shall not make a U-turn" to the concept alone
(NRS_484B_363_3). Here the defined word adds the highway, so the mapping adds it too. The business
district is the declared assumption `asm.business_district`, read where the act is recognized; the
validator does not let an occasion name an assumption-carried span. The exception "at an
intersection" is read `throughout` the act (the default for an exception). "On a divided highway" is
`rel.occupies` of a highway on which an `st.median_or_divider` lies, also read `throughout`. "Where an
appropriate opening or crossing place exists" is the divider's opening attribute that the footprint
overlaps at `some_moment` of the act, with a status reading of "appropriate". The reversal is
recognized with the act's window `p.vehicle_turn_window`. **Reversal signal:** a labelled
intersection U-turn whose turn begins on the approach lane before the intersection would show that
the intersection should be read `some_moment`, not `throughout`.

## NRS_484B_407 — no turn-around on a curve or near a crest without 500 ft of sight

**Decision.** The act is `drv.motion.u_turn`; its contract quotes "so as to proceed in the opposite
direction".
- "Upon any curve" is the feature with no size given. It is read as `st.curvature` at the subject's
  place on its `st.roadway` standing clear of zero, above `p.curvature_resolution` (a resolution only).
- "The approach to or near the crest of a grade" is the ground distance from the body to an
  `st.crest` region (`st.region_geometry`) at most `p.crest_near_reach` (proposed: 150 m, the AASHTO
  crest-curve and stopping-sight length).
- "Cannot be seen … within 500 feet" is `st.sight_distance` below the literal 500 ft, with a
  perception reading. The sight-distance contract states what could be seen at a place, whether or
  not another vehicle is there, so no other vehicle is quantified.

The conditions are read at `some_moment` of the act, (curve or crest) and sight together at one
observation. **Reversal signal:** if `p.crest_near_reach` is judged to widen the condition beyond the
words, the operator lowers the value. The rule names only the parameter.

## NRS_484B_410_o1 / NRS_484B_410_o2 — start or enter only with safety

**Decision.** There are two prohibited acts, so two nodes: starting a halted vehicle on a highway
(o1), and entering upon a highway (o2).
- "Stopped, standing or parked": the union of the three definitions is every halt, so it is read as
  `drv.motion.complete_halt`. Their exclusions (conflict or device halts, passenger halts, loading
  halts) overlap only on purposes that no conduct shows.
- **Start:** the halt held at the previous observation, on a highway, and does not hold now.
- **Entry:** occupancy of a highway rises.
- **The exception** "except when stopping, standing or parking where no parking is permitted" is read
  on the halt just before the event. It holds if the vehicle was halted in a no-parking curb zone or
  red curb, or in a travel region governed by a no-parking, no-standing or no-stopping sign whose
  conditions hold (status reading).
- **"With safety"** qualifies a concrete act, so it is not a surrogate. It is operationalized by the
  traffic-conflict technique: at the onset, no other road user has a closest approach within
  `p.conflict_horizon` at or below `p.conflict_centre_clearance`.

**Reversal signal:** if the exception's literal reading proves to have been meant only for the start
(o1), it is dropped from o2.

## NRS_484B_413_3 — signal before stopping or sudden slowing

**Decision.** There is one obligation span: "without first giving an appropriate signal". It is read
as `sig.brake_lamp` lit or `sig.hand_signal` stop_or_slow, shown at the onset or within
`p.stop_signal_lead_window` behind it.
- "Shall not stop" is a trigger: the onset of `complete_halt`. Here stopping is prohibited, so
  DEF-NRS-484A-260 applies, and its exclusion is carried beside the concept. That exclusion is a
  halt behind a road user ahead in the lane within `p.queue_halt_gap`, or one a stop sign, yield
  sign, red signal, railway signal or officer's stop direction requires in the region the vehicle
  occupies.
- "Suddenly decrease the speed" is the standard: deceleration beyond `p.sudden_decel_min`
  (proposed: the AASHTO comfortable deceleration, 3.4 m/s²).
- "Immediately to the rear" is a condition: a vehicle behind in the same lane within
  `p.rear_signal_reach`. No such vehicle means no duty (idle scenario).

**Reversal signal:** if a label treats the signal as owed with no follower present, the follower
condition is wrong.

## NRS_484B_440_1_o1 / _o2 / _o3 — stopping on rural highways

**Decision.** There are three obligations, so three nodes:
- **o1:** no halt on the roadway where it is practicable to leave the vehicle off it. "Practicable" is
  operationalized as a shoulder or bay on the same way within `p.offroad_refuge_reach`.
- **o2:** a free width of at least `p.free_passage_width` to the far road edge beside a standing
  vehicle, with no obstruction.
- **o3:** `st.sight_distance` of at least 200 ft at the standing vehicle.

All three share these readings:
- The district is the negation of `asm.business_or_residence_district`.
- "Whether attended or unattended" is a scope-none residue.
- The paved or main-traveled part is `st.roadway`.

The disabled-vehicle exception restricts the duty, and no atom carries a vehicle's condition. The
ontology forbids an assumption for it. So it is mapped to its nearest atoms (`kin.engine_running`,
`sig.hazard`) with the atom gap `ru.disabled`, the same proposal as smoke31 G19. **Reversal signal:**
acceptance of a `ru.disabled` atom (or of G19) lets all three nodes carry the exception and be coded.

## NRS_484B_450_1a / 1c / 1e — no halting on a sidewalk, within an intersection, on a crosswalk

**Decision.** "Stop, stand or park" is every halt (`complete_halt`), the same mapping as the index row
"No person shall stop, stand or park a vehicle". The DEF-260 exclusion is the law's own exception.
- **"Necessary to avoid conflict with other traffic"** is a standard. It is read as a road user
  ahead in the same lane within `p.queue_halt_gap`. The traffic aggregate is not listed: the
  validator does not admit an aggregate as an operationalization concept. "Traffic" covers every
  class, so any road user counts.
- **"The directions of a police officer"** and **"official traffic-control device"** reuse the index
  atoms.
- **"In compliance with law"** carries the operator gap. On 1c the validator requires smoke31 G22
  (still proposed). The same words in 1a and 1e mean the same thing, so they carry the same gap
  (rule 7). Device-required halts are only part of the halts that law requires. A left turner held
  inside an intersection by oncoming traffic, for example, halts in compliance with NRS 484B.253,
  and no device shows that.
- In 1a, subsection 3 (bicycles, electric bicycles and electric scooters on a sidewalk) is a
  scope-none residue. DEF-NRS-484A-320 excludes all three classes from "vehicle", so the duty never
  binds them. "Except as otherwise provided in subsection 3" is therefore boilerplate.

**Reversal signal:** an operator decision on G22 (an operator added, or a reading allowed) lets the
three nodes be re-recorded with `gap_resolutions` naming it.

## For the operator

- **G22 ("in compliance with law")** now blocks NRS-484B-450-1a, -1c and -1e. LVMC_11_52_130_A11 in
  this iteration maps the same words with device atoms and no gap. Whichever way G22 is decided
  should be applied to both.
- **`ru.disabled`** (as in G19) blocks NRS-484B-440-1 and, by the pending G19, NRS-484B-270-3.
- **NRS-484B-410's exception** "except when stopping, standing or parking where no parking is
  permitted" reads oddly in the corpus text. It is planned as written; the source wording may be
  worth checking.
- **New parameter proposals:** `p.crest_near_reach`, `p.sudden_decel_min`, `p.rear_signal_reach`,
  `p.stop_signal_lead_window`, `p.offroad_refuge_reach`, `p.free_passage_width`. All other
  parameters are re-proposed with the values already listed this iteration.
