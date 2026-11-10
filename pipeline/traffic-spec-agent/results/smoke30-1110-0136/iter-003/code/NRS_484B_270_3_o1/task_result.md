# NRS_484B_270_3_o1 — task result

**Final verdict: OK** (10 witnesses, 6 names, composes NRS_484B_297_6_o2)

## Gate runs
1. `WITNESS_FAIL` — branch_1: expected not_applicable, got unknown `[window_truncated:since]`. The
   pedestrian was off every sidewalk from the first observation, so NRS_484B_297_6_o2's look-back
   ("off every sidewalk since …") could not rule out a detour that began before the recording.
   Fix (witness only): the branch_1 pedestrian now starts on sidewalk w (moving, no obstruction,
   assumption false), steps onto the crosswalk inside b, then walks east in b into the conflict.
   That decides the look-back as false.
2. `OK`.

## Rule
- Class of x: `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: there is a region b of kind `bicycle_lane_or_path` where `rel_occupies x b` holds,
  x is moving (`drv_motion_moving x p.motion_speed_tolerance`), and there is a road user y such that
  `¬ same y x`, `rel_occupies y b`, and y is in the bicycle, electric bicycle or electric scooter
  aggregate, or in the pedestrian aggregate with `ruleApplies NRS_484B_297_6_o2 [x ↦ y]`. The
  composition applies only to the pedestrian limb, as s8 attaches to "or a pedestrian".
- Obligation: for every such b (same selection), for every y with the same whole selection, it is
  not the case that `prim_closest_approach_within x y p.conflict_time_horizon` holds with
  `prim_closest_approach_distance x y p.conflict_time_horizon < p.conflict_centre_clearance`.

## Choices the node left open
- None beyond the record. No narrowings of my own; the record's s1 and s2 narrowings are not
  restated. The obligation re-binds b with x moving as well as occupying it, which mirrors the
  applicability's selection. This changes nothing where the rule is engaged.

## Witnesses
- The planned ones: forbid, permit, idle, blind, branch_1 to branch_4.
- Two I added:
  - branch_5 (compliant): a bicycle 40 m away whose closest approach comes after the horizon.
    This exercises the `within` leaf.
  - branch_6 (violated): as forbid, with the rider on an electric bicycle. This exercises the
    electric-bicycle limb.
- The permit narrative ("40 m away, predicted to pass 15 m") cannot be built as written. A bicycle
  inside the 2 m lane cannot pass 15 m from x with a closest approach inside a 3 s horizon. Permit
  is therefore built with the bicycle 15 m away, predicted to pass 7.7 m from x at 2.2 s, so the
  distance comparison is what decides it. The 40 m case is branch_5.
- The electric-scooter limb can never be decided true: its aggregate includes no class. No
  witness makes it true.

## Process note
Before writing, I ran two read-only `grep` commands in the shell over Core files (`Primitives.lean`,
`Atoms.lean`, `Builders.lean`, `World.lean`, `Foundations`). They looked up the closest-approach
computation, the occupancy and geometry accessors, and the id types. The brief allows only the
gate command in the shell, so I should have used the Read tool. Nothing outside the two owned files
and this report was written.

## Why I finished
The gate returned OK on the second run.
