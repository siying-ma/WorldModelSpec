# LVMC_11_43_010_A — task result

## Final verdict
`WITNESS_FAIL` (1 gate run of 6). The rule and the forbid/permit/idle/blind witnesses work. `branch_1` cannot
meet its planned verdict, because the node and the run's aggregate reading disagree (see below).

## Gate runs
1. `WITNESS_FAIL` — `branch_1: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484A-320::vehicle]`.
   Nothing changed after this run: the failure is a defect in the node, not in the files.

(One extra shell call by mistake, a no-op `python -` heredoc, was denied before it ran. It was not a gate run.)

## The rule as written
- Binder class (a2, a4): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: `existsRegion roundabout r (rel_occupies subject r)` (a3, with st.roundabout as the quantifier kind),
  joined by "and" to `not drv_motion_complete_halt(subject; p.halt_speed_tolerance)` (a4, "travel").
- Obligation (a5): `forallRegion roundabout r (rel_occupies subject r → not drv_motion_circulating_clockwise_about(subject, r; p.halt_speed_tolerance, p.roundabout_clockwise_sin_tol))`.
  The obligation writes out the applicability's whole selection of r again, and applies at every roundabout the subject occupies.
- Narrowings: none of my own. The record's reading of "counterclockwise" (radial motion within the tolerance is
  compliant) is the concept's contract, and I did not restate the record's own narrowings.

## Witnesses
- Roundabout region 10: a 60 m square centred on (0,0), with its reference point at (0,0). The subject is at (20,0), moving at 10 m/s.
- forbid: heading south, so the cross product is −200 (clockwise). Expected violated.
- permit: heading north, so the cross product is +200 (counterclockwise). Expected compliant.
- idle: the car is on a roadway rectangle and the scene has no roundabout. Expected not_applicable.
- blind: the forbid scene with occupancy stated explicitly and `st.region_geometry` masked. Expected unknown.
- branch_1: an electric scooter circulating clockwise. Planned not_applicable, but the gate returns **unknown**.

## Why I finished — the node is wrong (span a2 / a4 and scenario branch_1)
The element justification for a2 and the narrative of `branch_1` say electric scooters are **excluded**
from DEF-NRS-484A-320::vehicle. The run's reading of that aggregate, as given to this session, lists
`ru.electric_scooter` (and `ru.rail_vehicle`) as **unresolved**. Under the `ru.aggregate` contract, a
road user that carries only an unresolved class has unknown membership. So a circulating scooter makes the episode
unknown, and no scene that is true to the narrative can be `not_applicable`. Making the scooter stop to get
not_applicable would leave the exclusion untested, and rule 7 forbids it.

What the plan must change, in one of two ways:
- Either the aggregate reading for `DEF-NRS-484A-320::vehicle` classifies `ru.electric_scooter` as
  **excluded**. That matches the definition's words "excluding ... electric scooters", which the element itself quotes,
  and `branch_1` then holds as planned with no change to the rule or the witness.
- Or `branch_1` is re-planned to expect `unknown` (membership unresolved), or dropped.

The rule itself needs no change in either case.
