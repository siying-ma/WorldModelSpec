# NRS_484B_287_1e — task result

**Final verdict: OK** (8 witnesses, 15 names, composes LVMC_11_30_140_B_o1, LVMC_11_30_140_B_o2)

## Gate runs
1. OK — first run; no changes after it.

## How the rule is written
- Class (s3): `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- Applicability:
  - s1: `not (ruleApplies LVMC_11_30_140_B_o1 {subject↦subject})` ∧ the same for `_o2`.
  - s2: some marked crosswalk the subject occupies (`existsRegion crosswalk c`, `rel_occupies`,
    `st_crosswalk_marked`) ∧ some intersection x with `diagonalEntry x`.
  - `diagonalEntry x` means: `rises(rel_occupies(subject, x))`, at least one lane enters x, and
    for every lane l with `st_lane_enters(l, x)`, `drv_motion_moving_across_carrier(subject, l)`
    holds at (p.halt_speed_tolerance, p.crossing_motion_cos) but not at
    (p.halt_speed_tolerance, p.right_angle_crossing_cos).
- Obligation (s4): for every intersection x satisfying the full `diagonalEntry x` selection
  again, and every `pedestrian_signal` device d that has `dev_governs(d, x)` and that the
  subject faces, d shows neither `dont_walk_steady` nor `dont_walk_flashing` without a
  countdown.
  - "Faces" is the record's test, with Δ = dev_position(d) − kin_position(subject) and
    h = kin_heading(subject): h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², and |Δ|² ≤ reach².

## Choices left open
None beyond the record. The obligation's re-binding of x uses the selection the record states
for it, which does not include the crosswalk condition. I declared no narrowings of my own; the
record's three are not restated.

## Witnesses
- Geometry: a 20 m square intersection; a northbound lane and an eastbound lane enter it; a
  marked diagonal crosswalk.
- The pedestrian moves on heading (0.6, 0.8) at 1.5 m/s and enters the intersection at t = 1 s.
- The signal head is 25 m straight ahead (40 m reach; cosine 1 against 0.87).
- In `idle` the pedestrian walks east, so the applicability is decided false.
- In `branch_4` the head governs a second intersection.

## Why I finished
The gate returned OK on the first run.
