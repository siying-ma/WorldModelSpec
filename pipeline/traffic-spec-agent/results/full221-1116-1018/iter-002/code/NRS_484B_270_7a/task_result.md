# NRS_484B_270_7a — task result

**Final verdict: OK** (5 witnesses, 6 names, composes nothing)

## Gate runs (2 of 6 used)
1. Ran on the untouched skeleton by mistake, before writing anything. Result: `UNUSED_CLAIM` (all claimed names were unused because the formulas were still `.tt`).
2. Ran after writing the rule and the witnesses. Result: `OK`.

Note: I also ran one extra shell command (`python -m harness gate … --help; ls …`) by mistake. The permission layer denied it, so it never executed.

## How the rule is written
- **Class / applicability (q1):** the subject must be a member of at least one of the aggregates `DEF-NRS-484A-025::bicycle`, `DEF-NRS-484B-017::electric_bicycle` or `DEF-NRS-484B-018::electric_scooter` (a disjunction of three `ru_aggregate` atoms). The applicability is the same disjunction, as the record's `applicability` states.
- **Obligation (q3, q4, q2):** at each observation, `forallUser m`. The guard is: `m` is not the subject, `m` is a member of `DEF-NRS-484A-130::motor_vehicle`, and `kin_speed m > p.halt_speed_tolerance`. Under that guard, the following conjunction must not hold:
  - `rel_bearing m subject "ahead"` (the longitudinal component of the bearing is positive);
  - `kin_accel_longitudinal m ≤ −p.vehicle_evasive_decel`;
  - `prim_closest_approach_within(m, subject; p.conflict_horizon)`;
  - `prim_closest_approach_distance(m, subject; p.conflict_horizon) < p.conflict_centre_clearance`.
- Narrowings: none of my own. The record's two narrowings are not repeated.

## Choices made in the witnesses
- **idle:** the narrative says "a car", but the run's reading lists `ru.motor_vehicle` as *unresolved* for `DEF-NRS-484B-017::electric_bicycle`. A car subject would therefore make the class unknown, not false. I used a moped instead. It is a motor vehicle, and no class of any of the three aggregates includes it or leaves it unresolved, so the class is decidedly false.
- **blind:** the narrative says "an electric scooter", but `DEF-NRS-484B-018::electric_scooter` has *no included class*, and `ru.electric_scooter` is unresolved. An electric-scooter subject is therefore never decidedly a member, and the verdict would be unknown whatever the masked atom shows. I used an electric bicycle, so that the masked `kin.accel_longitudinal` alone decides the unknown.

## Observation for the plan agent (not a blocker)
With the run's reading, no road user is ever decidedly a member of `DEF-NRS-484B-018::electric_scooter`. As a result, the rule can never decide anything for an electric-scooter rider: the most it can return is unknown. This comes from the reading's classification of that aggregate, not from this node. It should be checked if electric-scooter riders are meant to be judged.

## Why I finished
The gate returned `OK`.
