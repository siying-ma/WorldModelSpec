# NRS_484B_270_7b — task result

**Final verdict: OK** (5 witnesses, 5 names, composes nothing)

## Gate runs
1. **WITNESS_FAIL**: `blind` gave violated, not unknown. Masking `rel.surface_gap` blanks only a
   *supplied* gap (`Runtime/Manifest.lean`, `Mask.relation`). `rel_surface_gap` still computes the
   gap from the footprints, so the 0.2 m gap was decided.
   *Change:* in the blind scene the car's extent is unobserved, so no footprint gap can be
   computed. The source supplies `longitudinalOverlap` (1 m, 2 m, 1 m) as a measured relation,
   because Core cannot compute it without that footprint.
2. **WITNESS_FAIL**: the adapter refused the blind trace. Track 2 was in `occupancyObserved` with
   no footprint.
   *Change:* in the blind scene `occupancyObserved := [1]` (the car's occupancy is not observed;
   the rule reads no occupancy).
3. **OK**.

## How the rule is written
- Class of `x`: the three `ru_aggregate` atoms (bicycle, electric bicycle and electric scooter
  aggregate ids), joined by `or`.
- Applicability (v4): `existsUser y`, where `y` is not `x`, is in `ru_aggregate y DEF-NRS-484A-130::motor_vehicle`,
  and `drv_interaction_overtaking [x, y] [p.same_direction_cos_tolerance, p.motion_speed_tolerance]` holds.
- Obligation (v4 + v5): for every `y` with that same condition, two things must hold:
  - the lateral gap `rel_surface_gap [x, y, "lateral"]` is at least `p.overtaking_lateral_clearance`;
  - for every road user `z` other than `x` and `y`, this is false: `prim_closest_approach_within(x, z; p.conflict_time_horizon)`
    and also `prim_closest_approach_distance(x, z; p.conflict_time_horizon) < p.conflict_centre_clearance`.

## Choices the node left open
- None beyond the record. The obligation text gives the quantifier structure exactly. No
  narrowing is declared.
- `z` is tied to the binder through the two primitives, which read both `x` and `z`.

## Witnesses
The road runs east and the scenes are 1 s apart. The rider moves at 7 m/s and the car at 5 m/s,
overlapping along the rider's heading.
- **forbid:** lateral gap 0.2 m.
- **permit:** lateral gap 2.0 m.
- **idle:** a lone electric scooter, so applicability is decided false.
- **blind:** as described under run 1.
- **branch_1:** ample gap, plus a head-on truck 2.5 m to the side. Its predicted closest approach
  is 0.4–2.4 s ahead at a 2.5 m centre distance.

## Observation (not a defect report)
The reading lists the aggregate `DEF-NRS-484B-018::electric_scooter` as *included: (none)*, with
`ru.electric_scooter` only *unresolved*. So the class of an electric-scooter rider is always
unknown, never true. The `idle` witness still reaches not_applicable because applicability is
decided false. Even so, an electric scooter's overtaking can only ever be judged unknown under
this reading. The planning/reading side may want to resolve the scooter's membership of its own
aggregate.

## Why I finished
The gate returned OK on run 3 of 6.
