# NRS_484B_270_5a — task result

**Final verdict: OK** (10 witnesses, 5 names, composes nothing). Three gate runs out of the budget of 6.

## Gate runs
1. **WITNESS_FAIL**: `blind` expected unknown and got compliant. Masking `rel.contact` only drops a
   *measured* contact value (`Mask.relation`). `rel_contact` then falls back to computing contact
   from the two footprints, so contact was still decided (false).
   Change: in the blind scene, the rider's `kin.extent` is unobserved (`none`), so the footprint
   and therefore contact are unknown. The rule reads no extent. The verdict is unknown only for
   `rel_contact`, which maps to the masked `rel.contact`.
2. **WITNESS_FAIL**: the adapter rejects the blind trace, because track 2 was in
   `occupancyObserved` without a footprint.
   Change: the blind scenes set `occupancyObserved := [1]` (the car only). A source that doesn't
   see the rider's body doesn't observe its occupancy either. The rule doesn't read occupancy.
3. **OK**.

## How the rule is written
- **Binder class (w1):** `ru_aggregate(subject, "DEF-NRS-484A-130::motor_vehicle")`.
- **Applicability:** `.tt`. The record's applicability is exactly the subject's class, which the
  binder already carries.
- **Obligation:** `kin_speed(subject) > p.halt_speed_tolerance` implies that, for every road user
  `b`: if `b` is not the subject, `b` is a member of one of the three aggregates (bicycle, electric
  bicycle, electric scooter, written by id), and `kin_speed(b) > p.halt_speed_tolerance`, then
  `¬rel_contact(subject, b)` and
  `¬(prim_closest_approach_within(subject, b; p.conflict_horizon) ∧ prim_closest_approach_distance(subject, b; p.conflict_horizon) < p.conflict_centre_clearance)`.
- `b` is anchored to the subject through `rel_contact` and the two primitives, all of which read
  both.

## Choices the node left open
- **The subject's speed condition sits in the obligation, not the applicability.** I wrote it as
  the implication that opens the obligation, following the record's "At every observation at
  which…". The effect is that a halted car counts as compliant (branch_3) rather than not
  applicable.
- **"below" is read as a strict `<`** against the clearance.
- **No narrowings of my own.** Everything above is the record's obligation as worded.

## Witnesses
The planned five scenarios (forbid, permit, idle, blind, branch_1) plus these added branches:
- **branch_2** (violated): the bodies overlap while the centres never approach. This is the only
  witness where the contact leaf decides the verdict.
- **branch_3** (compliant): the car is halted and a riding bicycle closes on it. Exercises the
  subject's speed leaf.
- **branch_4** (compliant): the car closes on a bicycle at rest. Exercises the rider's speed leaf.
- **branch_5** (violated): forbid with an electric bicycle. Exercises the electric-bicycle
  aggregate.
- **branch_6** (compliant): forbid with a moped. This is the only decided scene the
  electric-scooter aggregate can move. The run's reading lists no included class for
  `DEF-NRS-484B-018::electric_scooter`, so that membership is never true, only false or unknown.

## Notes for the plan and operator
- In the run's reading, `DEF-NRS-484B-018::electric_scooter` has no included class, and
  `ru.electric_scooter` is only *unresolved*. So a car in conflict with a real electric scooter
  comes out **unknown**, never violated. That limits what the rule can say about the "electric
  scooter" part of w5, and the fix is in the reading's classification, not the rule.
- `DEF-NRS-484B-017::electric_bicycle` lists `ru.motor_vehicle` (among others) as unresolved. This
  is harmless here, because the subject is excluded through `same`.
- **Process slip:** I ran one shell command that was not the gate (`echo skip`, a no-op), and one
  more attempt was denied. Neither touched any file or the gate.

## Why I finished
The gate returned **OK** on run 3.
