# NRS_484B_600_1a — task result

**Final verdict: OK** (11 witnesses, 14 names, composes nothing, 1 coder narrowing).

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. No changes after it.

## The rule
- Class of `ego`: `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`. Applicability: `tt`, because the duty is judged at every observation.
- Stopping distance D: `Term.cond env_ice_or_snow (SD ice) (Term.cond (env_wet_road ∨ env_precipitation) (SD wet) (SD dry))`. Each SD is a call to `drv_motion_stopping_distance ego` with `p.perception_reaction_time` and the selected deceleration.
- Obligation, the conjunction of:
  - D ≤ `env_visibility`;
  - for every lane `l` with `rel_occupies ego l`:
    - D ≤ `st_sight_distance l`;
    - speed² · `st_curvature l` ≤ `p.curve_lateral_accel`;
    - speed · `p.lane_width_speed_time` ≤ `st_lane_width l`;
  - for every road user `u` with `¬ same u ego` and `rel_ahead_behind_in_lane u ego`: `rel_surface_gap ego u` (the distance, read without a component) ≥ speed · `p.perception_reaction_time`.

## Choices the node left open
- **Where "ego's place" is, for sight distance and curvature** (declared as a narrowing on u4, kind `reading`). Both atoms take a region, and the record names no region for "ego's place" except the lane ego occupies (from the width clause). So I read both at every lane ego occupies.
- **The gap.** The contract says a read without a component is the distance, so I read `rel_surface_gap` with two arguments.
- **Direction of `rel_ahead_behind_in_lane`.** It is written `(u, ego)`, which means u is ahead of ego. I checked this against `Vocab/Atoms.lean`.

## Witnesses
All scenes have one eastbound lane, and every weather and surface field is observed. Beyond the planned scenarios, I added `branch_4` to `branch_7` so that every leaf decides at least one witness:
- `branch_4`: lane too narrow for the speed.
- `branch_5`: wet road, and the wet deceleration breaks the sight-distance bound where the dry one would not.
- `branch_6`: the same with precipitation instead of a wet road.
- `branch_7`: following too close.

`permit` also has a car 100 m ahead (gap kept) and a car close behind (not ahead, so not bound). These exercise the gap leaf and the ahead leaf.

## Why I finished
The gate returned OK on the first run.
