# NRS_484B_280_1a — task result

**Final verdict: OK** (9 witnesses, 5 names, composes nothing). 3 of 6 gate runs used.

## Rule as written
- Binder class (x1): `ru_aggregate(subject, "DEF-NRS-484A-130::motor_vehicle")`.
- Applicability: `.tt`. The record's applicability is the subject's class alone, and that class is the binder's.
- Obligation:
  `kin_speed(subject) > p.halt_speed_tolerance →
   ∀ p. (¬ same(p, subject) ∧ ru_aggregate(p, "DEF-NRS-484A-165::pedestrian")) →
        ¬ rel_contact(subject, p) ∧
        ¬ (prim_closest_approach_within(subject, p; p.conflict_horizon) ∧
           prim_closest_approach_distance(subject, p; p.conflict_horizon) < p.conflict_centre_clearance)`
  This follows the record's obligation sentence. The speed guard covers the whole quantified duty, and x4 sits inside the user quantifier, so a scene with no pedestrian is compliant (branch_1).
- Narrowings: none added. The record's own two narrowings (x1 observable reading, x2 reading) are not restated.

## Gate runs
1. **WITNESS_FAIL**: `blind` was expected unknown but came back compliant. Core masks only the *measured* `contact` field, and `rel_contact` falls back to computing contact from the footprints (`Mask.scene`: "computed relations are blanked through the kinematics … only when the source lacks those too"). Fix: in `blind` the source also gives no body extent for the pedestrian, so contact cannot be computed. The closest-approach primitives read only position and velocity, so they stay decided.
2. **WITNESS_FAIL**: the adapter lint refused track 2 in `occupancyObserved` without a footprint. Fix: in `blind` only the car's occupancy is observed (`occupancyObserved := [1]`). The rule doesn't read occupancy.
3. **OK**.

## Choices the node left open
- **Witness geometry.** Car half-extents are 2.2 × 0.9 m and pedestrian 0.3 × 0.3 m. Every bound is broken or kept by a clear margin: forbid closes to ≈1.0 m within ≈2.0 s, and in permit the car's projected position stays at least 6.7 m from the pedestrian's line.
- **Extra branch witnesses**, so every leaf moves a decided verdict:
  - branch_2 (violated): contact with no closest approach (equal velocities), which exercises `rel_contact`.
  - branch_3 (compliant): a conflict with a stopped *car*, which exercises the pedestrian aggregate.
  - branch_4 (compliant): passing at 5 m inside the horizon, which exercises the distance bound.
  - branch_5 (compliant): a halted car with a pedestrian passing 1.6 m away, which exercises the speed guard.
  - permit's first instants have their closest approach beyond the horizon, which exercises the within-test.
- **Blind scene.** It masks only `rel.contact`, as planned. Because Core computes contact from geometry, the scene also leaves the pedestrian's extent (and so its occupancy) unobserved. This isn't a node defect, but a later planner should know that masking `rel.contact` alone never makes contact unknown when both bodies' footprints are observed.

## Why I finished
The gate returned OK.
