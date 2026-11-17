# NRS_484B_600_1a — task result

**Final verdict: OK** (9 witnesses, 15 names, composes nothing; 2 coder narrowings).

## Gate runs (4 of 6)
1. **GATE_TIMEOUT** (stack overflow). The deceleration `Term.cond` (two nested conds) appeared
   four times per comparison. Core's `elimCond` splits each cond of a comparison into four copies,
   which blew up. Fix: one `Term.cond` selection per comparison over the whole quantity
   (`bySurface f = cond ice (f ice) (cond wet (f wet) (f dry))`). Each bound is written as
   `2a·v·tr + v² − 2a·D ≤ 0`.
2. **CHECK_FAIL** (units: compared m²/s² with m). The zero on the right was in metres. Fix: a zero
   in m²/s², written `0 m/s × 0 m/s`.
3. **VACUOUS** (obligation leaf 2, the darkness/low-beam bound). Added `branch_4` (darkness,
   S = 63.3 m > 50 m low beam) and `branch_5` (fog, visibility 40 m < S) so that every limb of
   bound (i) is exercised.
4. **OK**.

Note: by mistake I also issued one extra shell command (the gate command with `--help` and a
pipe). The permission layer denied it, and it did not run.

## The rule
- The subject's class is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- The rule applies when `kin_speed subject > p.halt_speed_tolerance`.
- The obligation is the conjunction of:
  - (i) the stopping distance S fits within `env_visibility`; and, where `env_darkness`, within
    `p.low_beam_sight_reach`; and, at each lane the subject occupies, within `st_sight_distance`.
  - (iii) `v²·st_curvature ≤ cond(ice, p.following_decel_ice, p.curve_lateral_accel_max)` at
    each lane the subject occupies.
  - (iv) `2·v·err·tmin ≤ st_lane_width − kin_extent(subject,"width")` at each lane the subject
    occupies. The record's "half of" is moved across the inequality as a doubling.
  - (ii) for every road user u ahead of the subject in the lane (`rel_ahead_behind_in_lane u
    subject`, with u not the subject), `2a·S ≤ 2a·rel_surface_gap(subject,u) + v_u²`.
- The deceleration a is a `Term.cond`: ice where `env_ice_or_snow`; otherwise wet where
  `env_wet_road ∨ env_precipitation`; otherwise dry.
- No division is used anywhere, and "2a" is written `a + a`, so the rule has no bare literal.

## Choices the node left open (declared as narrowings on p4)
- **"At the subject's place"** (for sight distance and curvature) is read at every lane whose
  footprint the subject overlaps (`forallRegion lane` + `rel_occupies`). Each such lane must
  satisfy the bound.
- **`rel.surface_gap`** is read as the distance between the nearest points, not as a single
  component.

## Witnesses
All share one eastbound lane 4 m wide. The subject is 2 m wide, and every environment field is
decided in every scene.

| Witness | Expected | Scene |
|---|---|---|
| `forbid` | violated | Sight distance 40 m at 20 m/s on a dry road |
| `permit` | compliant | Sight 300 m, visibility 1000 m, 20 m/s |
| `idle` | not applicable | Speed 0 |
| `blind` | unknown | As `forbid`, with `st.sight_distance` masked |
| `branch_1` | violated | Ice, 10 m/s, sight 40 m |
| `branch_2` | violated | Curvature 1/50 at 20 m/s |
| `branch_3` | violated | A vehicle 30 m ahead moving at 0.5 m/s |
| `branch_4` | violated | Darkness |
| `branch_5` | violated | Fog, visibility 40 m |

## Why I finished
The gate returned OK.
