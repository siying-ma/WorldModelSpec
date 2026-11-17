# NRS_484B_270_2b_o1 — task result

**Final verdict: OK** (5 witnesses, 8 names, composes nothing). 3 of 6 gate runs used.

## Gate runs
1. `WITNESS_FAIL` — blind: expected unknown, got compliant. Masking `rel.contact` clears only the
   measured `contact` field (`Runtime/Manifest.lean:248`); `rel_contact` (`Vocab/Atoms.lean:645`)
   then computes contact from the two outlines through `rel_surface_gap`. So it stays decided.
   Change: in blind the bicycle's extent is left unobserved, so contact can't be computed. The
   longitudinal overlap, which Core can then no longer compute, is supplied as a measured relation
   with the values the geometry gives (3.5 m − |offset|, 2 m when side by side).
2. `WITNESS_FAIL` — blind: the adapter rejects a track whose occupancy is observed but whose outline
   is undefined. Change: in blind, `occupancyObserved := [1]`. The rule reads no occupancy.
3. `OK`.

## How the rule is written
- Subject class: `ru_aggregate(subject, DEF-NRS-484A-130::motor_vehicle)`.
- Applicability: there exists r with r ≠ subject, and:
  - **b2:** r is in one of the three rider aggregates (bicycle, electric bicycle, electric scooter).
  - **b1:** `rises(drv_interaction_overtake_pass(subject, r; p.overtake_window, p.overtake_same_direction_cos))`.
  - **b3:** at some observation of the `p.overtake_window` window behind, `kin_speed(r) > p.halt_speed_tolerance`
    and `rel_same_direction(subject, r)`.
- Obligation: for every r with the same whole selection, at every observation of the window behind:
  no `rel_contact`, and `rel_longitudinal_overlap ≥ 0` → `kin_accel_longitudinal(r) ≥ −p.rider_evasive_decel`.

## Choices the node left open
- **Compositions (b11, `unless`, scoping b12):** none of them is written. b12 is a residue with
  scope "none", and the record says the authorization does not change this duty. So there is no b12
  formula to conjoin `¬ruleApplies` into. The gate accepted this ("composes nothing"). The plan
  agent may want to check whether keeping five compositions that scope a residue is intended.
- No narrowings declared.

## Witness notes
- All scenes have a car passing at 10 m/s and the overtaken road user moving at 5 m/s. The pass is
  recognized at t = 13 s. Each witness has window 11–15 s, so the 10 s look-back stays inside the trace.
- **idle uses a moped, not a car.** The run's reading lists `ru.motor_vehicle` as an *unresolved*
  class of DEF-NRS-484B-017::electric_bicycle and DEF-NRS-484B-018::electric_scooter. So for any car,
  the rider-class disjunction is unknown, not false, and an idle scene with an overtaken car would
  be unknown. The moped is the only motor-vehicle class in none of the three aggregates.
  Consequence worth flagging for the plan or reading: on real data, every pass of a car by a car
  would come out *unknown* under this rule, not not_applicable.
- branch_1 (electric bicycle braking at −4 m/s² while side by side) exercises the deceleration leaf.

## Why I finished
The gate returned OK.
