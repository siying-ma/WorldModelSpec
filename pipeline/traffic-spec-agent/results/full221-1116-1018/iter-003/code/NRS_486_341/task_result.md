# NRS_486_341 — task result

**Final verdict: OK** (6 witnesses, 5 names, composes nothing)

## Gate runs
1. OK — first run; nothing changed after it.

## Rule as written
- Binder class (s4): `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`. The applicability is that class only, as the record's applicability states.
- Obligation: `forallUser m`, guarded by `not (same m subject)` ∧ (motorcycle aggregate ∨ moped aggregate) (s1) ∧ `existsRegion highway h (rel_occupies m h)` (s2); then `forallRegion lane L (rel_occupies m L → ¬(rel_occupies subject L ∧ rel_longitudinal_overlap(subject, m) ≥ 0))` (s3, s5).

## Choices the node left open
- s1–s3 go into the guard of the obligation's quantifier, not into the applicability. That way a scene with no motorcycle or moped is compliant (`branch_1`) rather than not applicable, as the plan's scenarios require.
- There are no narrowings: the record's quantifiers (every m, every L) and its zero bound are written as they are.

## Witnesses
The highway is region 10. Lane L is 11 (y 0…4) and the adjacent lane is 12 (y −4…0). The car is track 1 and the motorcycle is track 2. Both move east at 10 m/s.
- `forbid`: side by side in L, overlap 2 m, so violated.
- `permit`: the motorcycle is 20 m ahead in L, so the overlap is negative and the scene is compliant.
- `idle`: the subject is a bicycle, so the class is false and the rule is not applicable.
- `blind`: same scene as `forbid` with `rel.occupies` masked, so unknown.
- `branch_1`: no motorcycle, so compliant.
- `branch_2`: the car is in lane 12 beside the motorcycle in L, so compliant.

## Why I finished
The gate returned OK on the first run.
