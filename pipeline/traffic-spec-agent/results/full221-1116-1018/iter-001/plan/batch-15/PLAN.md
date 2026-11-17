# Plan — batch 15 (iteration 1)

Eight laws, nine nodes. No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the nodes reuse `drv.interaction.overtake_pass`, `drv.motion.moving_across_carrier` and `drv.motion.complete_halt`, which earlier batches of this iteration proposed. The validator accepts every node. One node, `NRS_484B_270_3_o2`, carries three atom gaps and is not coded.

## NRS_484B_270_3_o1 — yield to riders and to 297(6) pedestrians on the bicycle lane

**Decision.** The subject is the motor-vehicle aggregate, with "driver" read through the vehicle's controlled motion (agency). "shall yield" reuses the index mapping (`kin.speed`, `rel.contact`).

"the right-of-way" is the standard. Its definition, DEF-NRS-484A-210, sets the bound: "danger of a crash". It is operationalized with the closest-approach primitives under `p.conflict_horizon` and `p.conflict_centre_clearance`. It is not a surrogate.

**The other party.** It is quantified inside the obligation and has no binder. It is either:
- a moving member of the bicycle, electric-bicycle or electric-scooter aggregates ("riding", read as an agency reading, as the index maps "a person lawfully riding"), or
- a pedestrian for whom `NRS_484B_297_6_o1` applies. This uses a `condition` composition with its subject mapped to the quantified pedestrian.

**The lane.** "on the pathway or lane" refers to the "pathway or lane provided for bicycles…" that the next sentence names. The node carries it with its full qualification as `st.bicycle_lane_or_path`, anchored by `rel.occupies` to the other road user. The obligation reads the same lane again for the subject.

**What counts as failing to yield.** Contact, or the subject overlapping that lane while moving with a conflicting closest approach. This is disclosed as a narrowing on the obligation: a conflict while the subject stays outside the lane is not read.

**The composition.** It names only `_o1` of NRS-484B-297-6, because `_o1` is the node that carries 297(6)(c), the pedestrian's permission to use the bicycle lane.

**Branch scenarios.** `branch_2` and `branch_3` differ only in whether 297(6) applies to the pedestrian.

**Reversal signal.** If `NRS_484B_297_6_o1`'s applicability turns out not to cover a pedestrian already in the bicycle lane, compose `_o2` as well, or carry 297(6)(c) as a `definition` reference.

## NRS_484B_270_3_o2 — no entering, stopping, standing, parking or driving within the bicycle lane (blocked)

**Decision.**
- **The verbs.** Every verb is the footprint overlapping the lane, whether moving or halted. "Stop" is prohibited here, so DEF-NRS-484A-260 states its own scope; the outcome does not depend on choosing between the two "stop" definitions.
- **(a) alley or driveway.** Read with `until`/`since` on the subject's stretch in the lane: the stretch ends in, or began from, an alley or a driveway/alley entrance.
- **(c) avoid conflict.** Read through conduct (purpose): when the subject came into the lane, a member of traffic had a conflicting closest approach with it.
- **(e) police officer.** Reuses the index mapping: `dev.human_direction` with role police_officer, governing the occupied region.

**Gaps.** Three exceptions have no carrier:
- **(b) disabled vehicle.** Re-filed as gap `ru.disabled` (pending G19 of smoke31).
- **(f) emergency.** Re-filed as gap `env.emergency` (pending G20).
- **(d) official duties.** The validator rejected reading this through the emergency or official class: a class is no evidence of what the vehicle is doing, and warning lamps show on duty and off it alike. It is filed as a new atom gap, `ru.on_official_duty`. The index maps the same words for `NRS_484B_117_1` to the classes; this node departs from that mapping for the validator's reason.

The node is not coded. Its law stays blocked until the gaps are decided.

**Reversal signal.** An ontology revision that adds a condition-of-vehicle atom, an emergency atom and an on-duty atom, or an operator ruling that the vehicle classes may carry (d).

## NRS_484B_270_4 — no entering an intersection while driving within the bicycle lane

**Decision.** The obligation is that the moving subject's footprint does not overlap both a bicycle lane or path and an intersection.

"Except as otherwise provided in subsection 3" is composed with `NRS_484B_270_3_o2` `as: compliance`. What subsection 3 "otherwise provides" is its exceptions (a)–(f). An `exception` composition would not work: it would remove the duty wherever o2 is engaged, which is every time the subject is in the lane. Compliance with o2 while the subject is in the lane is exactly "one of (a)–(f) holds".

**Consequence.** This node is valid but cannot be built until `NRS_484B_270_3_o2` is coded, so the law effectively waits on that node's gaps. The node does not inline the exceptions, which would only move the same gaps here.

**Reversal signal.** A ruling that "as otherwise provided" should be a `definition` reference borrowing the exception words.

## NRS_484B_270_5a — due care to avoid a collision with a rider (surrogate)

**Decision.** "Exercise due care" is a standard about state of mind, so the node is a surrogate.

While the subject moves, it must have no contact (from "to avoid a collision") and no conflicting closest approach (`p.conflict_horizon`, `p.conflict_centre_clearance`) with any riding member of the three aggregates. The catch-all character of "due care" is disclosed as a reading.

**Reversal signal.** Label evidence that riders at rest must be covered: drop the "riding = moving" reading.

## NRS_484B_270_7a — no intentional interference with a motor vehicle (surrogate)

**Decision.** The validator requires an obligation span, so the text is split:
- "shall not: Intentionally" is the standard (intent): a surrogate, operationalized through evasive braking and conflict.
- "interfere with the movement" is the obligation: the motor vehicle's motion (`kin.speed`, `kin.accel_longitudinal`), with the rider ahead of it (`rel.bearing`).

A violation is a moving motor vehicle, with the rider ahead of it, braking beyond `p.vehicle_evasive_decel` while their closest approach conflicts. `p.vehicle_evasive_decel` is a new parameter, proposed at about 0.4 g, above comfortable braking.

**Disclosed limit.** The node cannot tell intentional interference from accidental interference.

**Reversal signal.** Label disagreement on rider-ahead conflicts the car caused itself, for example a car overtaking too close. Such cases call for a condition on the rider's own deceleration.

## NRS_484B_270_7b — no overtaking a motor vehicle unless safe

**Decision.** The act is `drv.interaction.overtake_pass(subject, m)`, with occasion boundary `window` and window `p.overtake_window`. The node has no trigger, condition or exception spans, so the occasion maps no spans.

The "unless … safely" clause is a standard, not a surrogate. It is read in the obligation over the whole pass, from the concept's own beginning (the last observation with the vehicle ahead and headings aligned) to its recognition, using `since`. At every observation of the pass:
- there is no contact;
- the gap between bodies (`rel.surface_gap`) is at least `p.bicycle_pass_safe_gap`;
- no other road user has a conflicting closest approach with the subject.

The occupants are read through the passed vehicle's body. "can do so" is read through the pass actually made (perception). `p.bicycle_pass_safe_gap` is reused from `NRS_484B_270_2b_o2`, since it is the same clearance between a bicyclist's and a motor vehicle's bodies.

**Reversal signal.** The operator separates the passing-bicycle clearance into its own parameter.

## NRS_484B_280_1a — due care to avoid a collision with a pedestrian (surrogate)

**Decision.** Same construction as 270-5a, applied to the pedestrian aggregate.

**Reversal signal.** As for 270-5a.

## NRS_484B_280_1c — proper caution upon observing a pedestrian at the listed places (surrogate)

**Decision.** The validator requires an obligation span, so "shall: Exercise" is the obligation (`kin.speed`, `rel.contact`) and "proper caution" is the surrogate standard (closest approach).

**Trigger.** "upon observing" is `rel.visible`, a perception reading taken at the judged observation.

**Places.** "near" uses one new reach parameter, `p.pedestrian_near_reach`, for all the places:
- **(1) Highway, street or road.** Together these are every highway, so the node reads `st.highway`.
- **(2) Stops and boarding.**
  - "bus stop", "bench", "shelter" and "transit stop" are `st.transit_stop`. "stop" here is part of a place name, not the defined halt.
  - "boarding" is read through conduct (purpose): the pedestrian is within reach of a halted bus or transit bus with a door open.
- **(3) Zones and crosswalks.**
  - School zones and school crossing zones are "marked", so the zone sign is the atom (`dev.zone_sign` of kind school or school_crossing, through `dev.governs`). NRS 484B.363 is not in this corpus, so accordance with it is a status reading.
  - Crosswalks are `st.crosswalk`, marked or unmarked.

**Reversal signal.** Label evidence that pedestrians who were seen and are now occluded must be covered: read `rel.visible` in a window behind instead.

## NRS_484B_287_1c — pedestrians cross only in marked crosswalks between adjacent signalized intersections

**Decision.** The validator rejects narrowings on condition spans, so both conditions are carried as their words say, and the readings are argued in the justifications.

**"Between adjacent intersections".** It is read through relation atoms tied to the carriers the pedestrian occupies:
- **The first intersection (i1).** The pedestrian occupies a carrier that `st.lane_enters` an intersection i1. The carrier is the stretch from the previous junction, so no other intersection lies between.
- **The second intersection (i2).** It is found in one of two ways:
  - the pedestrian also occupies the opposing carrier, which enters i2; or
  - a lane that enters i2 leads into the occupied lane (`st.lane_connectivity`), directly or through one connector lane.
- **Exclusions.** A pedestrian inside either intersection, or in a crosswalk that `st.entrance_of` records as marking an occupied carrier's entrance, is at the intersection, not between.

**"Official traffic-control devices are in operation".** The words "in operation" limit the defined term (DEF-NRS-484A-145) to devices that operate. That means uncovered signal heads that are neither dark nor `dev.inoperative`. Signs and markings are posted or painted and do not operate, so stop-controlled intersections are not read.

**Crossing.** "Cross" is `drv.motion.moving_across_carrier` on the occupied carrier. The exception is occupancy of a crosswalk whose marked attribute is true.

**The reference.** `[LVMC-11-30-140-B]` names one law line with two nodes, so it is composed as an `exception` with both `LVMC_11_30_140_B_o1` and `_o2`.

**Reversal signal.**
- An operator ruling that stop and yield signs are "in operation". The fix would be to add `dev.stop_sign` and `dev.yield_sign` to v3.
- Label evidence on one-way mid-block crossings where lane connectivity is not mapped.

## For the operator

- **G19 and G20 (smoke31) still decide NRS-484B-270-3(b) and (f).** They are re-filed on the same words. A third atom gap, `ru.on_official_duty`, is filed for (d) "In the performance of official duties". The validator ruled that vehicle classes are no evidence of duty; that ruling also affects how the index maps the same words for `NRS_484B_117_1`, which reads them through the classes.
- **NRS-484B-270-4 waits on `NRS_484B_270_3_o2`.** It composes that node `as: compliance`, so it stays unbuildable until the three gaps above are decided.
- **The pedestrian and rider surrogates read conflicts by centre distance (270-5a, 280-1a, 280-1c, 7b's other-traffic check).** With `p.conflict_centre_clearance` at about 3 m, a vehicle passing close to a pedestrian standing at the curb can be flagged. The value is the operator's to review.
- **New parameters:**
  - `p.pedestrian_near_reach` (280-1c);
  - `p.vehicle_evasive_decel` (270-7a).
