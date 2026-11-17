# LVMC_11_38_030 — task result

## Final verdict
**OK** (6 witnesses, 5 names, composes nothing)

## Gate runs
1. `BUILD_FAIL`: the witness used string region ids in `Build.rect` (lines 24–25). `RegionId` is numeric, so I changed them to `10` (roadway) and `11` (sidewalk).
2. `OK`.

## The rule
- Class of `subject` (s1, s2): `ru_aggregate subject "DEF-NRS-484A-135::motorcycle"` or `ru_moped subject`.
- Applicability (s4, s5): `existsRegion "sidewalk" sw (rel_occupies subject sw)` and `asm "asm.within_city_limits"`.
  - `st.sidewalk` is used as the region quantifier's kind. `st_sidewalk` is not a Boolean atom name.
  - `rel_occupies` ties the region to the subject.
- Obligation (s3): `drv_motion_complete_halt subject [p.halt_speed_tolerance]`. Moving while on the sidewalk is violated.
- Declarations (laws, binders, assumptions, operationalizations, residues, surrogate) are unchanged from the skeleton.

## Choices the node left open
None. The record decides every span. I declared no narrowing, and I did not restate the record's own observable_reading narrowing on s3.

## Witnesses
- **Layout:** a roadway at y ∈ [0, 7] and a sidewalk at y ∈ [7, 11], both spanning x ∈ [0, 100].
- **Subject:** a two-wheeler, half-extents 1.0 × 0.4 × 0.7 m. On the sidewalk it runs along y = 9; on the roadway along y = 3.
- **Trace:** 3 instants, 1 s apart.

| Witness | Expected | Scene |
|---|---|---|
| forbid | violated | motorcycle at 3 m/s on the sidewalk, within city |
| permit | compliant | motorcycle at 0 m/s on the sidewalk, within city |
| idle | not applicable | motorcycle at 3 m/s on the roadway, within city |
| blind | unknown | motorcycle on the sidewalk, `kin.speed` masked in the manifest and `none` in the scene |
| branch_1 | violated | moped at 2 m/s on the sidewalk, within city |
| branch_2 | not applicable | motorcycle at 3 m/s on the sidewalk, `asm.within_city_limits` false |

## Why I finished
The gate returned OK on the second run.
