# NRS_484B_213_2b — task result

**Final verdict: OK** (7 witnesses, 13 names, composes nothing)

## Gate runs
1. `CHECK_FAIL` — units: the approach test compared the dot product (m²/s) with a zero literal in metres.
   Changed: the test velocity·(reference point − position) > 0 is now written as `vx·dx > −(vy·dy)`,
   so both sides carry the same unit. It means the same thing.
2. `OK`.

## How the rule is written
- **s1**: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **s3**: there is some `intersection` region x, or some `railway_crossing` region x (two
  quantifiers over the same disjunction), for which either:
  - `rel_occupies subject x` holds (traversing), or
  - `st_region_geometry_distance(subject, x) ≤ Units.feet 100` and the dot product of
    `kin_velocity` with (`st_region_geometry` reference point of x − `kin_position`) is greater than 0 (approaching).
- **s4**: `not (existsRegion one_way_roadway w (rel_occupies subject w))`, joined into the applicability with `and`.
- **s2**: for every `highway` h the subject occupies, and every `centre_line` c with `st_on_way c h`,
  `prim_region_lateral_offset(subject, c) ≥ 0`.

## Choices the node left open
- None needed a narrowing. The record already gives the reading of "left side" (a negative offset)
  and the agency reading of "driven". I did not restate either.
- I wrote "approaching" as strictly positive, as the record states it ("is positive").

## Witnesses
- `forbid`, `permit`, `idle`, `blind`, `branch_1`, `branch_2`: as planned.
- `branch_1`: the subject is past the crossing's reference point, so it is not approaching.
  Only the traversal limb can make the rule apply.
- I added `branch_3` (violated): an approach to a railway crossing only. It exercises the
  railway quantifier's distance and direction limbs.

## Why I finished
The gate returned OK on the second run.
