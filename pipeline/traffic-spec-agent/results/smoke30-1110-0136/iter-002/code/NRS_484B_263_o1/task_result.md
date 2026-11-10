# NRS_484B_263_o1 — task result

**Final verdict: OK** (6 witnesses, 9 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` — run on the untouched skeleton (all formulas `.tt`), before any edit; every claimed name was reported unused, as expected.
2. `OK` — after writing the rule and the six witnesses.

(One shell call that added `--help` to the gate command was denied by the sandbox and did not run.)

## The rule
- Class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability: there is a controlled-access region `a` where either
  - **entry:** `rises (rel_occupies x a)`, and some vehicle y ≠ x on `a`; or
  - **exit:** `rises (not (rel_occupies x a))`, and some highway region `h` that x occupies, with a vehicle y ≠ x on `h` and not on `a`.

  In both cases y must be moving (`drv_motion_moving` with `p.motion_speed_tolerance`). Its proximity must also be an immediate hazard: `rel_surface_gap y x ≤ kin_speed y × p.immediate_hazard_time_gap`.
- Obligation: if x is moving, then for every `a`, every `h` and every y in that same selection (written out again in full), it must not be the case that `prim_closest_approach_within x y` (horizon `p.conflict_time_horizon`) holds and `prim_closest_approach_distance < p.conflict_centre_clearance`.

## Choices the node left open
- `rel_surface_gap` is read with no component, which gives the distance between the bodies. This matches the contract: "a read without a component is the distance".
- The hazard bound is written as a product, not a ratio, as the `Term.div` rule requires.
- I added no narrowings of my own. The record already has narrowings for s1, s2 and s3, and I did not repeat them.

## Witnesses
- Each trace has three observations 1 s apart, and each witness sets `window := (1000, 2000)`. `rises` is truncated at the first observation, so leaving that observation out stops any witness from being unknown because of the trace start.
- The planned scenarios (forbid, permit, idle, blind, branch_1, branch_2) are built with the verdicts the plan gives them. The geometry is described in the witness file's header.

## Why I finished
The gate returned OK.
