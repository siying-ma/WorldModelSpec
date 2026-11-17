# NRS_484B_785_1a — task result

## Final verdict
**OK** (4 witnesses, 5 names, composes nothing)

## Gate runs
1. `OK` — first run, after writing the rule and the four witnesses in one pass. Nothing changed after it.

## Rule as written
- Binder `subject` class: `.atom "ru_electric_scooter" [subject] []` (s2).
- Applicability (s4): `existsRegion "roadway" rw (rel_occupies subject rw) ∨ existsRegion "bicycle_lane_or_path" bl (rel_occupies subject bl)`.
  Each quantifier ranges over its claimed kind and is tied to `subject` by `rel_occupies`. "Route" adds no place, per the record.
- Obligation (s5): `kin_speed subject ≤ Units.mph 15` (the text's literal, in m/s).
- s1 and s3 are the record's residues (scope none). They are left as written and not encoded.

## Choices the node left open
None. The record fixes every element. `narrowings` is empty, and the record's own s5 reading narrowing is not restated.

## Witnesses
The roadway runs over y ∈ [-5,5], the bicycle lane over y ∈ [5,7] and the sidewalk over y ∈ [7,10], all for x ∈ [0,200]. The scooter heads east with a half-extent of 0.6 × 0.3 × 0.6 m. There are 3 instants, 1 s apart. 15 mph is 6.7056 m/s.
- forbid: on the roadway at 8 m/s → violated.
- permit: in the bicycle lane at 5 m/s → compliant.
- idle: on the sidewalk at 8 m/s, with no overlap with the roadway or bicycle lane → not applicable.
- blind: on the roadway, with `kin.speed` masked → unknown.

## Why I finished
The gate returned OK on the first run.
