# NRS_484B_293 — task result

**Final verdict: OK** (9 witnesses, 13 names, composes nothing).

## Gate runs
1. `UNUSED_CLAIM` (drv_motion_complete_halt, kin_position, kin_speed, kin_velocity, …): the skeleton
   as written by the harness, before any edit. This run was accidental: I combined the gate
   command with an `ls` of the Core directories in one shell call, which broke the
   one-command rule. Nothing changed because of it.
2. `OK`: the rule and witnesses below.

## How the node is written
- s1: binder class `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- s2: applicability `existsRegion crosswalk cw (rel_occupies subject cw) ∧ ¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- s4: obligation `forallRegion crosswalk cw (rel_occupies subject cw → right-half ∨ impracticable)`.
  This repeats the applicability's selection of the crosswalk. The right-half test is
  `v_x(r_y−p_y) − v_y(r_x−p_x) ≥ −(p.pedestrian_lateral_tolerance · kin_speed)`. Here `r` is
  `st_region_geometry` with x/y components, and `v`/`p` are `kin_velocity`/`kin_position`.
- s3: two limbs.
  - Some other user (`¬ same other subject`) occupies cw, has `rel_bearing` "ahead" and "right"
    (Boolean forms: longitudinal > 0, lateral < 0), and has `rel_surface_gap` ≤ p.pedestrian_near_reach.
  - Or some `obstruction` region has `prim_region_lateral_offset` < 0 and
    `st_region_geometry_distance` ≤ p.pedestrian_near_reach.

## Choices left open
None beyond the record's own narrowings, so `narrowings` is empty. I used the Boolean
`rel_bearing` "ahead"/"right" atoms because they are exactly the record's sign conditions on the
longitudinal and lateral components.

## Witnesses
- The planned six: forbid, permit, idle, blind (trace and manifest both mask kin.velocity),
  branch_1 and branch_2.
- branch_3 (compliant): a barrier lies on the right within reach.
- branch_4 (violated): a pedestrian is ahead-right but beyond reach.
- branch_5 (violated): a barrier lies on the left within reach.

## Why I finished
The gate returned OK.
