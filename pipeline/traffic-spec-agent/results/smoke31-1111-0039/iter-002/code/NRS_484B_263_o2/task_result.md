# NRS_484B_263_o2 — task result

## Final verdict
**OK** (6 witnesses, 9 names, composes nothing).

## Gate runs
1. **OK**: this was the first run, with the rule and all six witnesses written in one pass. Nothing changed after it.

## The rule
- **Class of x**: `ru_aggregate x DEF-NRS-484A-320::vehicle`.
- **Applicability (s2)**: there is a `controlled_access` region `a` that x enters (`drv_motion_entering_region x a`) or leaves (`drv_motion_leaving_region x a`) at this observation.
- **Obligation (s6, s4, s7, s8)**:
  - For every `controlled_access` region `a` that x enters or leaves (the applicability's selection written again), the obligation covers every road user y that:
    - is not x (`same`);
    - is a vehicle (`ru_aggregate … vehicle`);
    - is a member of traffic (`ru_aggregate … traffic`);
    - occupies `a` (`rel_occupies y a`);
    - is moving (`drv_motion_moving y [p.speed_resolution]`);
    - is approaching x (`prim_closest_approach_within x y [p.immediate_hazard_gap]`).
  - Each such y must have `rel_surface_gap x y` (the distance read) ≥ `kin_speed y × p.merge_time_headway`.

## Choices the node left open
- **Narrowings**: none. The record states the obligation in full.
- **Surface gap**: `rel_surface_gap` is read as the distance between the two bodies (2-argument form), not as one of its components. This matches the contract's "distance between the nearest points".
- **Witness window**: every witness names `window := (1000, 2000)` ms. `entering_region` and `leaving_region` are unknown at the first observation, because no earlier observation exists. This is not a history-boundary scenario.
- **Extra witness `branch_2` (violated)**: x leaves `a` while an approaching vehicle is about 10.8 m away. It exercises the `leaving_region` limb, which the planned scenes never reach.

## Why I finished
The gate returned OK on the first run.
