# NRS_484B_600_1a — task result

## Final verdict: OK

## Gate runs
1. **OK**: 10 witnesses, 16 names, composes nothing, 1 narrowing declared by the coder. Nothing changed after it.

One shell call that was not the gate command was denied before the first gate run. It ran nothing and did not use a gate run.

## How the node is written
- **Class (b2):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (b1):** `drv_motion_moving x [p.motion_speed_tolerance]`.
- **Obligation (b3, surrogate):** four bounds joined by "and":
  - **Surface deceleration `a`:** a `Term.cond` that picks ice-or-snow, else wet (`env_wet_road` or `env_precipitation`), else dry.
  - **Stopping distance SD:** the same selection over three calls of `drv_motion_stopping_distance`, each called with `p.perception_reaction_time` and its own deceleration parameter.
  1. SD ≤ `env_visibility`. Also, at each lane x occupies, SD ≤ `st_sight_distance` of that lane.
  2. For every road user y that is not x and is ahead of x in its lane (`rel_ahead_behind_in_lane y x`): speed × `p.following_min_time_headway` ≤ `rel_surface_gap x y` (the distance between the two bodies).
  3. At each lane x occupies: speed² × `st_curvature` ≤ `a`.
  4. At each lane x occupies: speed × margin + speed × margin ≤ `st_lane_width` − `kin_extent x width`. This is the record's "≤ half of (lane width − vehicle width)" with both sides doubled, so the formula needs no literal 2 (the node declares no literals).

## Choices the node left open
- **Where "the sight distance / curvature at x's place" is read:** on every lane x occupies (`forallRegion lane l`, tied to x by `rel_occupies x l`). These are the same lanes the width bound reads. Where x occupies no mapped lane, these two set no bound. This is declared as a `reading` narrowing on b3.

## Witnesses
- **The eight planned witnesses:** written from the narratives.
- **Two extra witnesses, so each surface-condition leaf changes a verdict:**
  - `branch_5` (violated): wet road, sight distance 120 m. SD is 130 m at the wet deceleration but about 109 m at the dry one, so the wet reading alone decides it.
  - `branch_6` (violated): the same scene, but rain is falling on a road not reported wet.
- **`blind`:** applies `Build.masked` with the manifest that masks `kin.speed`.

## Why I finished
The gate returned OK on the first run.
