# NRS_484B_263_o1 — task result

**Final verdict: OK** (6 witnesses, 8 names, composes nothing)

## Gate runs
1. `WITNESS_FAIL`. I ran this too early: the witnesses were still the harness skeletons with no users, so "subject names track 1, which is not in this scene". The rule itself built and passed its static checks. After this run I wrote the scenes and added `branch_2`.
2. `OK`.

## How the rule is written
- Class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability (s2): `existsRegion controlled_access a (entering_region x a ∨ leaving_region x a)`.
- Obligation (s3–s5): `forallRegion controlled_access a ((entering ∨ leaving) x a → ¬ ∃ y. y ≠ x ∧ ru_aggregate y vehicle ∧ rel_occupies y a ∧ moving y [p.speed_resolution] ∧ closest_approach_within x y [p.immediate_hazard_gap] ∧ closest_approach_distance x y [p.immediate_hazard_gap] < p.conflict_clearance)`.
  - It restates the applicability's region selection in full (rule 3c).
  - It requires the condition at every region that x enters or leaves.

## Choices the node left open
- **Region quantifier:** the obligation uses `forallRegion` over the region selection. The record says "at this entry or exit", so the duty applies at each region selected.
- **Narrowings:** none added. The record's own narrowings (s1, s2, s3) are not restated.
- **Witness window:** every witness sets `window := (1000, 2000)`. The entry/exit concepts are unknown at the first observation because there is no earlier one, so the first instant is excluded.
- **`branch_2` (violated):** added so the `leaving_region` limb is tested. x exits onto the ramp while y, 15 m behind at 25 m/s, closes to 2 m in 1.5 s.

## Why I finished
The gate returned OK.
