# LVMC_11_40_180_C_o1 — task result

## Final verdict: OK (7 witnesses, composes nothing)

## Gate runs
1. **OK** — first run, on the rule and witnesses as first written. Nothing changed afterwards.

## The rule
- **Subject class:** the disjunction of `ru_aggregate` for `DEF-NRS-484A-025::bicycle`,
  `DEF-LVMC-11-02-082::electric_bicycle` and `DEF-LVMC-11-02-083::electric_scooter`.
- **Applicability (c1):** `existsRegion "sidewalk" sw (rel_occupies subject sw)` and
  `not drv_motion_complete_halt(subject; p.halt_speed_tolerance)`. The node's own observable
  reading ("riding" means the subject is not at rest) is not restated.
- **Obligation (c2, c3, c4):** for every road user `ped` that is not the subject and is a member
  of `DEF-NRS-484A-165::pedestrian`, both must hold:
  - `not rel_contact(subject, ped)`
  - `not (prim_closest_approach_within(subject, ped; p.conflict_horizon) and
    prim_closest_approach_distance(subject, ped; p.conflict_horizon) < p.conflict_centre_clearance)`

  The `within` conjunct guards the distance where it is undefined. A scene with no pedestrian
  satisfies the universal, so it is compliant.

## Choices the node left open
- None beyond the record's own narrowings, so `narrowings := []`.
- The pedestrian quantifier excludes the subject with `same`, as the record says ("other than the
  subject").

## Witnesses
- **Geometry:** a sidewalk strip (y from 0 to 3 m) with a roadway beside it. The bicycle rides at
  4 m/s and the pedestrian walks at 1 m/s.
- **`forbid` and `branch_2`:** head-on, closest approach in 0.4–2.4 s at a 0.5 m centre distance,
  with no contact.
- **`permit`:** the pedestrian is behind the bicycle on a diverging course.
- **`idle`:** the bicycle is on the roadway.
- **`blind`:** the `forbid` geometry with `rel.occupies` masked.
- **`branch_1`:** the bicycle is alone on the sidewalk.
- **`branch_3` (added, not_applicable):** the subject is a pedestrian, so a person on foot falls
  outside the three aggregates. I added it pre-emptively so that the electric-scooter class leaf
  moves a decided witness.

## Why I finished
The gate returned OK on the first run.
