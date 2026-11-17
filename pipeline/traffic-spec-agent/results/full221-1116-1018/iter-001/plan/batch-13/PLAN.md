# Plan — batch 13 (iteration 001)

Ten nodes for eight law lines. No concept is proposed: the nodes reuse `drv.motion.complete_halt`, and everything else is written with atoms and primitives. No law-local aggregate (`aggregates.jsonl` is empty). No gap. Every node is `accept` in the validator.

Some yield duties appear in several nodes: 260, 263, 267(1)(a), and the caution of 267(2)(b). They all use one representation, the mapping index's `shall yield` → `kin.speed`, `rel.contact`. The danger of a crash in the right-of-way definition (DEF-NRS-484A-210) is operationalized with the traffic-conflict pair `prim.closest_approach_within` / `prim.closest_approach_distance` under `p.conflict_horizon` / `p.conflict_centre_clearance`. These are the parameters an earlier batch proposed, and they are proposed again here unchanged. The yield is judged only while the subject moves, because a subject at rest grants precedence. "Driver" is always read through the vehicle's controlled motion (`observable_reading` / agency).

## NRS_484B_260 — entering a highway from a private way
- **Decision.** The rule judges each observation at which the moving subject straddles a `st.driveway_or_alley_entrance` region and a roadway on highway h, having come onto the entrance from off the roadway (formula `since`). At that observation, no moving vehicle on a travel region of h, with the subject ahead of it in its frame, may be in conflict or contact with the subject.
- **Private way.** "From a private way" is carried by the entrance atom plus the condition that the subject overlaps no `st.alley`. The atom's own exclusion says it cannot tell an alley entrance from a driveway, and an alley is a highway (DEF-NRS-484A-015). "Approaching" is carried by `rel.bearing` (subject ahead in v's frame) and v's speed.
- **About to.** "About to enter or cross" is an imminent movement, read by the entry itself (`observable_reading` / intention). A crossing beyond the straddle is judged through the constant-velocity closest approach at the straddle.
- **Reversal signal.** A labelled crossing whose conflict arises only after the subject has left the entrance region would argue for judging the whole crossing.

## NRS_484B_263_o1 / _o2 — entering or exiting a controlled-access highway
- **Why two nodes.** The line carries two obligation spans: "shall yield the right-of-way" and "shall continue to yield … until … reasonable safety".
- **o1.** Judged at the entry into or exit from a `st.controlled_access` region c: the rise of the subject's overlap with c, or of its non-overlap after overlap. The duty covers moving vehicles on c with the subject ahead of them, and "immediate hazard" is the conflict bound.
- **o2.** Judged at the observations strictly after that event, within the new `p.merge_window`. It concerns "that traffic", which refers back to o1's words. Those words are carried in o2 with every qualification (vehicles on c, approaching, the immediate-hazard bound) and claim the admitted traffic aggregate as well. "Reasonable safety" is read through the same conflict bound: the subject may proceed once no such vehicle is in conflict with it.
- **Reversal signal.** A source that maps entrance ramps inside the controlled-access region moves the judged entry to where the ramp begins (disclosed on a2). A labelled merge conflict that this misses would argue for an attribute that tells entrance lanes from through lanes (see the operator section).

## NRS_484B_267_1a — yield to an emergency or regulatory vehicle in immediate approach
- **Trigger.** e is either in the AEV aggregate (DEF-NRS-484A-020) or an `ru.official_vehicle` of kind `regulatory_agency`. It shows a lit warning lamp that is red, flashing and facing front. The words quote DEF-NRS-484A-480-3 as a `definition` reference: "at least one flashing red warning lamp visible from the front". The required lamp must be in use; blue, rotating or steady lamps alone do not engage the duty.
- **Immediate approach.** This is a standard, operationalized as: e moving, the subject ahead of e in e's frame, and their distance within the new `p.emergency_immediate_approach_reach`.
- **Exception.** "Otherwise directed by a law enforcement officer" reuses the index mapping: a police_officer `dev.human_direction` governs a region the subject occupies, whatever indication it gives.
- **Obligation.** While the subject moves, there is no conflict and no contact with e.
- **Reversal signal.** A labelled scene in which a police vehicle shows only blue lamps and is judged engaged would widen the lamp reading.

## NRS_484B_267_1b_o1 — drive immediately to the right-hand edge, clear of intersections
- **Why two nodes.** Paragraph (b) carries two obligations: the pull-over, and "shall not drive to and stop … on a paved shoulder … where lawfully placed signage allows …".
- **When it is judged.** At the rise of the trigger, the subject must reach the position within the new `p.emergency_pullover_window` ("immediately"). The duty ends early if e has passed (the subject behind e in its frame, with no longitudinal overlap).
- **The position.**
  - **Parallel:** the heading is within `p.curb_parallel_cos` of the occupied carrier's direction. That parameter was proposed by an earlier batch and is proposed again unchanged.
  - **As close as possible to the edge or curb (standard):** the body is within the new `p.pullover_edge_gap` of a `st.road_edge` on the subject's right, on the same highway, or the subject is on a paved shoulder.
  - **Clear of any intersection.**
  - **Not on a signed shoulder:** the subject does not occupy a paved shoulder governed by a `shoulder_use_permitted` sign. This is how the node carries "Except as otherwise provided in this paragraph".
- **Reversal signal.** A label that treats the outer boundary of the public way as "the edge of a highway".

## NRS_484B_267_1b_o2 — do not stop on a signed shoulder
- **Decision.** While the trigger holds, the subject must not come to rest (rise of `drv.motion.complete_halt`) on a paved shoulder governed by a `shoulder_use_permitted` regulatory sign. "Lawfully placed" is read through the sign's presence (`observable_reading` / status).
- **The appended list.** The list of NRS 484B.210(4) is the legend of that sign. It is carried as a `definitional` span on `dev.regulatory_sign`, and the classes it names are not read: the subject's duty does not depend on its own class.

## NRS_484B_267_1c — stop and remain until the vehicle has passed
- **"Such position".** This refers to the position paragraph (b) describes, and the words require the state itself, not compliance with 1b. So it is carried in full with 1b_o1's atoms and parameters: parallel, at the right edge or on a paved shoulder, clear of intersections, off signed shoulders.
- **Formula.** Judged at the trigger's rise: (not passed) strong-until (halted at the position, and halted at the position strong-until passed).
- **Witnesses.** Two scenarios differ only in where the subject halts: at the edge (compliant) and mid-lane (violated, `branch_1`).
- **Reversal signal.** A label that accepts a stop not yet complete when the vehicle passes.

## NRS_484B_600_1a — basic speed rule (surrogate)
- **Decision.** The standard is the whole duty, so this node is a surrogate. Each named factor is read by its degree:
  - **Surface and weather:** wet, icy and precipitation select the braking deceleration, using the earlier batch's `p.following_decel_*`, proposed again unchanged.
  - **Weather:** visibility caps the sight available.
  - **Traffic:** the assured clear distance to any road user ahead in the lane, crediting that road user's own braking distance. Any road user counts, because DEF-NRS-484A-285 counts all of them.
  - **Width of the highway:** the time-to-line-crossing bound against the occupied lane's width and the subject's width.
  - **Other conditions (catch-all):** read only through sight distance, curvature (side-friction bound) and darkness (low-beam reach).
- **Traffic aggregate.** The validator refused an aggregate id among an operationalization's concepts, so the road user ahead is unrestricted by class. That is exact under the traffic definition.
- **Reversal signal.** Labels that flag ordinary following at a reasonable headway would mean the traffic bound is too strict.

## NRS_484B_267_2a — decrease speed on approaching (subsection 2)
- **Trigger.** e is moving, or preparing to move. Preparing to move uses the section's own definition: an indication that is visible (`rel.visible`, `observable_reading` / perception) — a movement, a hand signal, or, from the open list, a turn indicator. The subject approaches e within the new `p.emergency_approach_reach`. "Arriving at or leaving the scene" is a scope-none residue: it only illustrates the moving case.
- **Reasonable speed.** "To a speed that is reasonable and proper, pursuant to … NRS 484B.600" is composed as compliance with `NRS_484B_600_1a`, which states that bound as its own obligation.
- **Decrease.** "Decrease the speed" is a deceleration beyond the new `p.speed_decrease_decel_min` before the subject draws level with e (strong until from the trigger's rise).
- **Reversal signal.** A label that counts an already slow, steady approach as compliant.

## NRS_484B_267_2b — proceed with caution (surrogate)
- **Decision.** Same trigger as 2a. Caution is a standard of the driver's care, so the node is a surrogate. It is operationalized through the clearance kept from e: no conflict, no contact, and, when side by side, a body gap of at least the new `p.emergency_pass_clearance`.
- **Reversal signal.** Labels that judge caution by speed, which 2a already covers.

## For the operator
- `st.controlled_access` has no attribute that tells its entrance or exit lanes from its through lanes. NRS 484B.263 is therefore judged where the source's controlled-access region begins and ends. If sources map ramps inside that region, the merge itself is judged only through the constant-velocity conflict at the region boundary and through o2's merge window.
- The validator rejects `ru.aggregate=<id>` in an operationalization's `concepts` list, but asks for that form when the bare atom is used. A standard whose factor is a legal aggregate ("the traffic") therefore cannot claim the aggregate. For NRS 484B.600(1)(a) this costs nothing, because the traffic definition covers every road-user class.
- New parameters awaiting review: `p.emergency_immediate_approach_reach`, `p.emergency_pullover_window`, `p.pullover_edge_gap`, `p.emergency_approach_reach`, `p.speed_decrease_decel_min`, `p.emergency_pass_clearance`, `p.merge_window`, `p.driver_reaction_time`, `p.curve_lateral_accel_max`, `p.lane_keeping_heading_error`, `p.lane_departure_time_min`, `p.low_beam_sight_reach`.
