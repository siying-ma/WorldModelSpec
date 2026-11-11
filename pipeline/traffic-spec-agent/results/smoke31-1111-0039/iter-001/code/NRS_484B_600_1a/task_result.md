# NRS_484B_600_1a — task result

## Final verdict
**OK** (8 witnesses, 16 names, composes nothing; 1 coder narrowing).

## Gate runs
1. `OK` — first run after writing the rule and the witnesses; nothing changed after it.

(Before the first gate run, one accidental command — the gate command with an extra `--help` and a
shell suffix — was denied by the permission layer and never ran. I also listed `Core/Vocab` and
grepped `Core/Language/Semantics.lean` once each, to confirm the measure-argument forms of
`kin_extent` (width selector) and `rel_surface_gap` (no component = distance).)

## How the node is written
- Class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability: `drv_motion_moving x` with `p.speed_resolution` (the plan's observable reading of
  "drive or operate").
- Obligation: the conjunction of the five bounds.
  - Stopping distance S: a call to `drv_motion_stopping_distance` with `p.perception_reaction_time`.
    The call's parameters must be constant terms, so the `Term.cond` the record names selects
    between three calls (ice / wet-or-precipitation / dry) instead of sitting inside one call.
  - (1) S ≤ `st_sight_distance`, (3) v·v·`st_curvature` ≤ `p.curve_lateral_accel`, and
    (4) `p.lateral_margin_time`·v ≤ `st_lane_width` − `kin_extent(x, width)`. All three are
    stated for every lane x occupies (`forallRegion lane l`, with `rel_occupies x l`).
  - (2) S ≤ `env_visibility`.
  - (5) For every road user y where `not (same x y)` and `rel_ahead_behind_in_lane y x` holds:
    `p.traffic_time_headway`·v ≤ `rel_surface_gap x y`, read as a distance.

## Choices the node left open
- **"At x's place"** for the sight distance and the curvature: the record names no region for
  this. I read it as every lane x's footprint overlaps, which is the same region the lane-width
  bound reads. Where x occupies no lane, these two factors set no bound. This is declared as a
  `reading` narrowing on s3.
- The argument order of `rel_ahead_behind_in_lane` is (a, b) = "a ahead of b". "y ahead of x" is
  therefore `[y, x]`.

## Witnesses
All eight scenarios use one lane with its width, sight distance and curvature set. The weather is
observed in every scene (dry unless stated). Each scenario breaks or keeps its bound by a clear
margin against the run's reading:
- forbid: 62.5 m stopping distance vs 30 m visibility.
- permit: everything in bounds.
- idle: speed 0.
- blind: visibility masked.
- branch_1: on ice, 78 m stopping distance vs 60 m sight distance; dry would be 46 m.
- branch_2: lateral acceleration 7.2 vs 3 m/s².
- branch_3: required headway 12 m vs an 8 m gap.
- branch_4: lateral margin 0.6 m vs 0.4 m of room.

## Why I finished
The gate returned `OK` on the first run.
