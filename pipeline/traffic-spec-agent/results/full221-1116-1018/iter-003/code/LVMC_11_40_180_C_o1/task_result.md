# LVMC_11_40_180_C_o1 — task result

## Final verdict

`WITNESS_FAIL`: only `branch_3` fails. It expects not_applicable and gets unknown, with
`aggregate_unresolved:DEF-LVMC-11-02-082::electric_bicycle` and
`aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter`.
The fault is in the node's planned scenario, not in the rule or the scene (see "The node is wrong").

## Gate runs

1. `WITNESS_FAIL` (branch_3 only: expected not_applicable, got unknown). Nothing was changed
   after this run, because the failure cannot be fixed honestly inside my two files (see below).

## How the rule is written

- **Subject class:** `ru_aggregate(subject, DEF-NRS-484A-025::bicycle) ∨ ru_aggregate(subject, DEF-LVMC-11-02-082::electric_bicycle) ∨ ru_aggregate(subject, DEF-LVMC-11-02-083::electric_scooter)`.
- **Applicability (c1):** `∃ sw : sidewalk. rel_occupies(subject, sw)` ∧ `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- **Obligation (c2/c3/c4):** for every road user `ped` that is not the subject (`same`) and is in
  `DEF-NRS-484A-165::pedestrian`:
  - `¬ rel_contact(subject, ped)`, and
  - `¬ (prim_closest_approach_within(subject, ped; p.conflict_horizon) ∧ prim_closest_approach_distance(subject, ped; p.conflict_horizon) < p.conflict_centre_clearance)`.

  A scene with no pedestrian is compliant.
- **Choices left open:** none beyond the record. I declared no narrowings: the "riding" reading is
  the node's own `observable_reading`, and the yielding reading is the node's own narrowing.

## Witnesses

- **Layout:** a sidewalk (x −50..50, y 0..4) next to a roadway (y −8..0). Three scenes, 1 s apart.
- **forbid, blind, branch_2, branch_3:** the subject and the pedestrian meet head-on on y = 2. Their
  centre gap is 15, 9 and 3 m, closing at 6 m/s. The time to closest approach (2.5, 1.5, 0.5 s) is
  within 3 s, and the closest-approach distance is 0 m (under 3 m).
- **permit:** the pedestrian is behind the subject and walking the other way, so there is no
  approach within the horizon.
- **idle:** the subject rides on the roadway.
- **branch_1:** no pedestrian is in the scene.

The gate reported no failure for any scenario other than branch_3.

## The node is wrong: scenario `branch_3`

Planned: "A passenger car moves along the sidewalk toward a pedestrian … not_applicable."

The run's reading leaves `ru.motor_vehicle` **unresolved** for both
`DEF-LVMC-11-02-082::electric_bicycle` and `DEF-LVMC-11-02-083::electric_scooter`. So for a
passenger car (`classes = [.motorVehicle]`):

- its membership of those two aggregates is unknown;
- the subject's class formula is `false ∨ unknown ∨ unknown`, which is unknown;
- the scene is moving and on the sidewalk, so no other conjunct is false.

The verdict is therefore unknown, not not_applicable. Every class a passenger car could honestly
carry (motor_vehicle, taxicab, …) is unresolved under at least one of the two electric aggregates.
To get not_applicable I would have to give the car no class or a false one, and hard rule 7
forbids making an unobserved fact false to reach not_applicable.

**What the plan agent must change**, one of:
- **(a)** Re-plan `branch_3` to expect `unknown` (the faithful verdict under this reading), or drop it.
- **(b)** Use a subject the reading excludes from all three aggregates, if the words support one.
- **(c)** Resolve the readings of the two electric aggregates so that `ru.motor_vehicle` is
  excluded (or covered). This is a reading decision, not a coding one.

## Why I finished

All the other scenarios match their planned verdicts. The only failure comes from a planned
verdict that the run's reading makes impossible, and no faithful edit to the rule or the witness
can reach it. So the node itself is wrong, and I stopped after one gate run instead of spending the
budget.

Process note: before writing the files I ran one `ls` on the Core directory to find the file to
read. It was not the gate command; nothing was changed by it.
