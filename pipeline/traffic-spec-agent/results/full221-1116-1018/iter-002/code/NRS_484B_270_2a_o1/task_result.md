# NRS_484B_270_2a_o1 — task result

**Final verdict: OK** (5 witnesses, 8 names, composes nothing).

## Gate runs
1. `WITNESS_FAIL` — blind: expected unknown, got compliant. Masking `rel.contact` only drops a
   *measured* contact; Core then computes contact from the two footprints (`rel_surface_gap`), so
   the masked atom never went unknown. Fix: in `blind` the source does not measure the rider's
   extent, so it has no footprint and Core cannot compute contact. The source supplies the
   measured `longitudinalOverlap` (1→2). Core cannot compute that value without the rider's
   footprint, so supplying it is allowed.
2. `WITNESS_FAIL` — blind's trace was not one an adapter can produce: track 2 was in
   `occupancyObserved` without a footprint. Fix: `occupancyObserved := [1]` in blind's scenes
   (the trace has no regions).
3. `OK`.

## How the rule is written
- Class (a4): `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
- Applicability: `existsUser r` with this selection: `not (same subject r)`; r in one of the three
  admitted aggregates (a2); `rises (drv_interaction_overtake_pass subject r [p.overtake_window,
  p.overtake_same_direction_cos])` (a1); and at some observation of the time window behind of
  length p.overtake_window, `kin_speed r > p.halt_speed_tolerance ∧ rel_same_direction subject r
  [p.overtake_same_direction_cos]` (a3), written `not (holdsFor … (not …))`.
- Obligation (a5, the surrogate): `forallUser r (selection → holdsFor time p.overtake_window subject
  (¬ rel_contact subject r ∧ (rel_longitudinal_overlap subject r ≥ 0 → kin_accel_longitudinal r ≥
  −p.rider_evasive_decel)))`. The selection is re-bound in full.
- No narrowings of my own; residues, operationalizations and the other declarations are unchanged.

## Choices the node left open / deviations from the planned narratives
- **`idle` overtakes a moped, not a car.** Under the run's reading, `ru.motor_vehicle` is
  *unresolved* for both `DEF-NRS-484B-017::electric_bicycle` and
  `DEF-NRS-484B-018::electric_scooter`. So when the overtaken road user is a car, the class
  disjunction is unknown, and the pass makes the applicability unknown rather than false. Moped
  is the only class that is decided *outside* all three aggregates. A moped is still a motor
  vehicle and not a bicycle, electric bicycle or electric scooter.
- **`branch_1` overtakes an electric bicycle, not an electric scooter.** Under the run's reading,
  `DEF-NRS-484B-018::electric_scooter` includes **no** class, and `ru.electric_scooter` itself is
  unresolved. An electric scooter therefore never makes this rule apply decidedly: the planned
  "violated" verdict cannot be reached with a scooter. The branch still tests the evasive-braking
  leaf (−3 m/s² < −2 m/s² while side by side, with no contact).
- **Reading defect to report (not the node's):** under the run's reading, no road user is ever
  decidedly a member of `DEF-NRS-484B-018::electric_scooter`, not even one labelled
  `ru.electric_scooter`. Every rule that claims this aggregate is unknown for scooters. The
  classification of `ru.electric_scooter` under that definition should probably be *included*.
- Witness geometry: all witnesses speak about t ∈ [11, 16] s. The pass is recognized at t = 14 s,
  so its 10 s look-back [4, 14] lies inside the 17-instant trace.

## Why I finished
The gate returned `OK` on the third run.
