# Plan — batch 08 (iteration 001)

Eight laws, eight nodes, one new concept (`drv.motion.moving_backward`). Every node passes the validator. One node, `LVMC_11_60_030_A5`, carries an atom gap and will not be coded. No law-local aggregates (`aggregates.jsonl` is empty).

## New concept

**`drv.motion.moving_backward`** (used by `NRS_484B_113_2` and `NRS_484B_113_3`). The road user's velocity, projected onto its heading, is below minus `speed_tol`. It is a state at one observation, not an act, so the nodes that use it need no `occasion`. Backing is read from kinematics, never from `kin.gear`, as `kin.gear`'s contract requires. There is one parameter, the speed resolution, filled with `p.halt_speed_tolerance`. Nothing in the catalogue or the concepts proposed this iteration denotes backing. **What would reverse this:** an accepted concept that denotes motion against the heading; that concept would then be reused instead.

## Nodes

**`LVMC_11_60_030_A5` — gap, not coded.**
- **Spans reused from the index:**
  - subject: bus aggregate
  - exception: "other than a tour bus" (tour-bus aggregate)
  - place: bus-stop curb zone or transit stop, anchored by `rel.occupies`
- **Obligation:** "Not stand or park a bus", read as `drv.motion.complete_halt`.
- **The gap:** the duty turns on "a period of time longer than has been designated for such bus stop". The span borrows from LVMC 11.60.010 through a `definition` reference: "he may designate the length of time that a bus may stand or park at each".
  - The period belongs to each stop and is posted on that stop's sign.
  - The `conditions` attribute of `dev.zone_sign` and `dev.regulatory_sign` lists "a duration limit", but §11 gives no measure to read it. `prim.conditions_hold` decides only time windows, occupancy and class.
  - A reading parameter would fix one period for every stop, which contradicts "such bus stop".
  - So the node files the atom gap `dev.posted_duration_limit`.
- **What would reverse this:** an ontology measure (or primitive) that exposes a sign's posted duration.

**`LVMC_11_60_040`.**
- **Subject:** taxicab aggregate.
- **Applicability:** the taxicab is on a highway ("upon any street", same atoms as the index).
- **Obligation:** wherever it stands (`drv.motion.parked` with `min_duration = p.standing_min_duration`), it is in a `taxicab_stand` curb zone.
  - "stand or park" is read as standing, because standing contains parking under DEF-NRS-484A-250 and DEF-NRS-484A-155.
- **"at any place other than in a taxicab stand…"** is an exception span. A node may carry only one obligation span.
- **The second sentence (temporary passenger stop):**
  - It is carried by the halt-duration reading of purpose: a halt shorter than `p.standing_min_duration` is not standing.
  - "in accordance with other stopping or parking regulations" is a scope-`none` residue. This provision does not forbid such a stop. Whether the stop complies with other regulations is judged by those rules, and a non-standing halt gets the same verdict here either way.
- **What would reverse this:**
  - a label that treats a short passenger stop that breaks another regulation as a violation of this section; or
  - an accepted operator for "in compliance with law" (gap G22). The span would then become a composition.

**`LVMC_11_60_090`.**
- **Subject:** "cab" has no applicable definition in the table, so it maps to `ru.taxicab`.
- **"stand":** the table resolves it to DEF-NRS-484A-250, which defines the *act* of halting. Here the word is a noun for a place, so the element maps it to the `taxicab_stand` curb zone and says why.
- **The sign:** a `right_turn_only` regulatory sign that governs the region the cab occupies as it leaves the stand, with its conditions holding for the cab (status reading).
- **Obligation:** at the exit from the first intersection after leaving the stand, `drv.motion.right_turn_through_region` holds.
  - "First" is written as: no other intersection occupied *since* the departure from the stand with the sign condition.
  - The occasion is boundary `event`: onset at entry into r, recognition at exit.
  - All trigger and condition spans are read `at_recognition`, looking back to the departure. None is read while the turn is under way, so there are no occasion scenarios.
- **What would reverse this:** a source or label where the notice sign is recorded as governing the intersection rather than the cab's lane, or as a sign kind other than `right_turn_only`.

**`NRS_484A_450_2` (stop sign; approach convention, rule 4c).**
- **Trigger:**
  - Entry into intersection r, through a carrier c that `st.lane_enters` r, where a stop sign governs c.
  - "before entering the intersection" is the event span.
- **Obligation:** one span, holding the three ordered places, each read through c:
  - the crosswalk marking c (`st.entrance_of`), halting off it and short of it within `p.stop_point_tolerance`;
  - else the stop line marking c;
  - else c's entrance end at r.
- **History bound:** the obligation text states it in full — the search back to the approach start or the previous entry, what begins a new approach, and where missing evidence leaves the verdict unknown.
- **The view clause:** "where the driver has a view of approaching traffic" is disclosed as a reading on the obligation span.
  - The point nearest the intersecting highway before entering is the intersection's edge, and the view along that highway is widest there.
  - So the edge within the tolerance is read as that point, and `st.sight_along_way` is not compared with a bound.
  - **What would reverse this:** a label that counts a halt at the edge with an obstructed view as non-compliant (or a halt farther back with a view as compliant). That would need a sight-distance parameter.
- **Stop sign governance:** a stop sign that governs only the intersection is not read as facing c. Otherwise through traffic would owe a stop.
- **Scenarios:** besides the standard ones, branches cover each place and a halt far back, plus `history_boundary`.

**`NRS_484A_450_3` (yield sign).**
- Same structure as 450-2, with a yield sign governing c.
- **"if required for safety to stop"** is a standard, operationalized with the traffic-conflict technique:
  - At some observation of the approach, another road user of traffic on a highway is on a closest approach with the subject within `p.conflict_horizon`, at a centre distance below `p.conflict_centre_clearance`.
  - If no such observation exists, the duty does not arise.
  - Not a surrogate: the standard qualifies a concrete duty.
- **Traffic aggregate:** claimed on the obligation span, whose words name "approaching traffic". The validator rejects an aggregate id inside an operationalization's concept list.
- **What would reverse this:** a label requiring a stop at a yield sign only for a conflict at the moment of entry. The window would then move to the observation before entry.

**`NRS_484B_110`.**
- **Subject:** vehicle aggregate.
- **"shall at any time be driven"** is the trigger: the vehicle is moving (not `complete_halt`), an agency reading.
- **Obligation:** its footprint overlaps no `st.safety_zone`.
- A vehicle at rest is idle.
- **What would reverse this:** a label that counts a vehicle standing inside a safety zone as violating. The rule would then drop the motion trigger.

**`NRS_484B_113_2`.**
- **Applicability:** the vehicle is backing (`drv.motion.moving_backward`).
- **Obligation (one span):** none of the following holds:
  - its footprint comes to overlap an intersection (backing *into* it);
  - it overlaps a crosswalk;
  - it occupies an intersection and its heading has changed by at least `p.turn_heading_min` since backing within that intersection began (`Term.headingSince`), which is "around a street corner".
- **Disclosed readings:**
  - Backing straight out of an intersection is not "into" it.
  - The city-limit qualifier in the definition of "street" is not read for the corner (noted as a broadening).
- **What would reverse this:** a label that treats any backing inside an intersection as backing into it.

**`NRS_484B_113_3`.**
- **Applicability:** the line is subsection (3) of "Limitations on backing", so "in every case" is read as every case of backing. Applicability is the vehicle backing. This is disclosed on the obligation span, because reading it everywhere would require every vehicle always to yield.
- **Standard:** "the right-of-way" (DEF-NRS-484A-210, "danger of a crash"), operationalized with the closest-approach primitives and the conflict parameters.
- **Who is yielded to (condition span):**
  - moving traffic: the traffic aggregate, on a highway, not at rest;
  - pedestrians: the pedestrian aggregate, moving or not, because moving pedestrians are already traffic.
- **What would reverse this:**
  - a corpus decision that the line binds forward driving too; or
  - a label showing that "moving" also qualifies pedestrians.

## Mapping reuse and departures

- The following reuse their index mappings:
  - "The operator of a bus,"
  - "other than a tour bus,"
  - "The driver of a vehicle"
  - "No vehicle"
  - "upon any street"
  - "approaching the intersection" (plus the sign)
- "such vehicle" in LVMC-11-60-040 also claims the vehicle aggregate, because the word is the defined term. The taxicab carries it.

## For the operator

- **Gap `dev.posted_duration_limit` (LVMC-11-60-030(A)(5)).**
  - The sign `conditions` attribute already lists "a duration limit" but no §11 measure exposes it.
  - Adding a measure (for example `dev_zone_sign_duration_limit`, in s) would unblock this law. It would also unblock any time-limited parking posting.
- **`p.halt_speed_tolerance` and friends.** Parameters re-proposed here with the values and conventions already proposed this iteration:
  - `p.halt_speed_tolerance`
  - `p.standing_min_duration`
  - `p.stop_point_tolerance`
  - `p.conflict_horizon`
  - `p.conflict_centre_clearance`
  - `p.turn_heading_min`
  - `p.u_turn_heading_min`
- **Stop and yield sign governance.** The NRS 484A.450 nodes read a sign only where the source records it governing the approach carrier. A source that records only junction-level governance will make these rules not applicable on such approaches.
