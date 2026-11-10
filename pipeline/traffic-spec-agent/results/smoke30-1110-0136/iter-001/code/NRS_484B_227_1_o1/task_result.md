# NRS_484B_227_1_o1 — task result

## Final verdict
**OK** (6 witnesses, 8 names, composes nothing).

## Gate runs
1. OK. This was the first run, so nothing was changed afterwards.

## The rule
- Class of `x`: `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- Applicability (s2): `existsRegion highway h: rel_occupies(x, h) ∧ existsRegion median_or_divider m: st_on_way(m, h)`.
- Obligation (s3): `forallRegion highway h: (rel_occupies(x, h) ∧ ∃ median m on h) → (∀ roadway c: st_on_way(c, h) ∧ rel_occupies(x, c) → ¬ drv_lane_facing_against_direction(x, c; p.against_direction_cos_tolerance)) ∧ (the same for ∀ lane c)`.
  The obligation restates the whole highway selection from the applicability (rule 3c).

## Choices the node left open
- None of substance. The record's `obligation` states the formula in full, and its own narrowings cover "driven" and "only upon the right-hand roadway". `narrowings` is therefore empty.
- Witnesses: I added `branch_2` (violated). In it the left-hand roadway carries no direction and its lanes carry westbound directions. Only the lane leaf decides the verdict there, so the `forall lane` conjunct is exercised separately from the roadway one.
- `branch_1`: the median is split around an intersection region. The car turns from east, through north-east, to north, crossing the westbound roadway at a cosine of 0.

## Why I finished
The gate returned OK.
