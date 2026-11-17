# NRS_484B_113_3 — task result

**Final verdict: OK** (8 witnesses, 8 names, composes nothing)

## Gate runs
1. OK — first run, on the rule and witnesses as first written. Nothing changed afterwards.

(Two stray shell calls were made before the gate: a no-op `echo`, and a `--help` variant of the gate that was denied and not run. Neither touched any file.)

## How the rule is written
- Binder class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability: `drv_motion_moving_backward(subject; p.halt_speed_tolerance)`. This is the record's backing case for s2.
- Obligation: `forallUser other`, of the form (not `same(subject, other)` ∧ (moving traffic ∨ pedestrian)) → (¬`rel_contact(subject, other)` ∧ ¬danger).
  - Moving traffic is `ru_aggregate(other, "DEF-NRS-484A-285::traffic")` ∧ `existsRegion highway way. rel_occupies(other, way)` ∧ ¬`drv_motion_complete_halt(other; p.halt_speed_tolerance)`.
  - Pedestrian is `ru_aggregate(other, "DEF-NRS-484A-165::pedestrian")`.
  - Danger is `prim_closest_approach_within(subject, other; p.conflict_horizon)` ∧ `prim_closest_approach_distance(subject, other; p.conflict_horizon) < p.conflict_centre_clearance`.
- `st.highway` is carried as the kind of the region quantifier (`.lit "highway"`), tied to `other` by `rel_occupies`.

## Choices the node left open
- None that change the reading. The obligation is written as the record states it, and `narrowings` is empty. The record's own narrowings (agency, and the backing reading of s2) are not repeated.

## Witnesses
- The six planned witnesses follow their narratives.
- `branch_2`: the pedestrian is placed about 2 m behind the car's rear bumper, because 2 m between the centres would put the two bodies in overlap. Its closest approach is therefore 2.25 s ahead at 0.5 m, not 1 s as the narrative says. That is still within the 3 s horizon and below the 3 m clearance.
- I added two witnesses:
  - `branch_3` (violated): the car's rear touches a pedestrian who is walking away from it. There is no closest approach ahead, so `rel_contact` alone decides the verdict.
  - `branch_4` (violated): a moving car crosses behind the backing car, inside the horizon and below the clearance. This exercises the moving-traffic leaves: the traffic aggregate, `rel_occupies` of a highway, and `complete_halt`.

## Why I finished
The gate returned OK on the first run.
