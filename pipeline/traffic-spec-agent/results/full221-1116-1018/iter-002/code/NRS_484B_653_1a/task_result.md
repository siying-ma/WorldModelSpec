# NRS_484B_653_1a — task result

**Final verdict: OK** (6 witnesses, 7 names, composes nothing)

## Gate runs
1. `BUILD_FAIL` — the witness gave region ids as strings (`"hw"`) to `Build.rect`. Changed them to the numeric region id `10`.
2. `OK`.

## How the rule is written
- Binder class (d2): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (d4 ∨ d5): there is some region of kind `highway` that the subject `rel_occupies`, **or** `asm.public_access_premises`.
- Obligation (d1 + d3, a surrogate): `¬(speed ≥ p.exhibition_speed_min ∨ (accel_longitudinal ≥ p.exhibition_accel_min ∧ ∃ o ≠ subject. closest_approach_within(subject, o, p.conflict_horizon) ∧ closest_approach_distance(subject, o, p.conflict_horizon) ≤ p.conflict_centre_clearance))`.
  - The distance is read only together with the `within` primitive. Its contract leaves it undefined when the two do not approach within the horizon.

## Choices left open
- I wrote the record's "some road user other than the subject" as `existsUser o` with `¬ same o subject`.
- The highway kind is written as `highway` with no exclusions: kinds that refine it are covered.
- I declared no narrowings. The formulas carry the record's own words and nothing narrower.

## Witnesses
Every scene is held still across 3 instants 1 s apart. No look-back is used, so no window is set.
- **forbid:** 50 m/s on a highway.
- **permit:** 15 m/s at 1 m/s², with a pedestrian 20 m behind.
- **idle:** the highway is 500 m away and the assumption is false.
- **blind:** `kin.speed` is masked and the car is alone, so the conflict branch is decided false.
- **branch_1:** in a parking lot (the assumption is true and there is no highway), 5 m/s at 5 m/s² toward a standing pedestrian 10 m ahead. They meet in 2 s at 0 m.
- **branch_2:** alone on a highway at 25 m/s.

## Why I finished
The gate returned OK on the second run.
