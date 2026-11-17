# LVMC_11_40_180_C_o1 — task result

## Final verdict

`WITNESS_FAIL`: `branch_1: expected compliant, got unknown for [aggregate_unresolved:DEF-LVMC-11-02-083::electric_scooter]`.
The planned `branch_1` scenario can't be reached under the run's reading. The node/reading is wrong (see below).

## Gate runs

1. `UNUSED_CLAIM` (every claimed name). I ran it by mistake on the untouched skeleton before
   writing anything, so this run was spent without testing any of my work.
2. `WITNESS_FAIL`: only `branch_1` failed (unknown, `aggregate_unresolved` on the electric-scooter
   aggregate). The gate reported no other witness failing. forbid, permit, idle, blind and branch_2..4
   were not reported as failing.

## How the rule is written

- Class: `ru_aggregate(subject, DEF-NRS-484A-025::bicycle) ∨ ru_aggregate(subject, DEF-LVMC-11-02-082::electric_bicycle) ∨ ru_aggregate(subject, DEF-LVMC-11-02-083::electric_scooter)`.
- Applicability (c1): `∃ sidewalk r. rel_occupies(subject, r)` ∧ `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)` (the record's observable reading of "riding"; kin.speed is read through the concept).
- Obligation (c2, c3, c4): `∀ p. (¬ same(p, subject) ∧ ru_aggregate(p, DEF-NRS-484A-165::pedestrian)) → ¬ rel_contact(subject, p) ∧ ¬ (prim_closest_approach_within(subject, p; p.conflict_horizon) ∧ prim_closest_approach_distance(subject, p; p.conflict_horizon) < p.conflict_centre_clearance)`.
- I chose no other readings, so `narrowings` is empty.
- I added witnesses: branch_2 (contact only → violated), branch_3 (bicycle at rest → not applicable), and branch_4 (electric bicycle → violated). Together they exercise the contact, complete_halt and electric-bicycle leaves.

## Why I finished: the node (with the run's reading) is wrong

**Span c1, claim `ru.aggregate=DEF-LVMC-11-02-083::electric_scooter`; planned scenario `branch_1`.**
The run's reading classifies the aggregate `DEF-LVMC-11-02-083::electric_scooter` with
**no included class**. Every class that could hold, `ru.electric_scooter` included, is listed as *unresolved*.
So by the `ru.aggregate` contract, a road user's membership in it is never true: it is unknown
for an electric scooter and false otherwise. As a result:

- `branch_1` ("An electric scooter rides on an empty sidewalk … compliant") can't be compliant.
  The subject's class is unknown, so the engagement is unknown, and with a vacuously true obligation
  the verdict is unknown (what the gate reported). Giving the scooter a second class (e.g. bicycle)
  would make it pass, but the scene would no longer match the planned narrative, so I didn't do it.
- The electric-scooter aggregate leaf can never move a decided witness either. So once branch_1 is
  satisfied some other way, the rule would be `VACUOUS` on that leaf.

**What the plan or reading must change:** classify `ru.electric_scooter` as *included* under
`DEF-LVMC-11-02-083::electric_scooter`. The definition defines exactly that device, and the
reading's representation decision currently leaves it unresolved. Alternatively, if the reading's
choice stands, the plan must withdraw the electric-scooter branch of c1 as a gap, and re-plan
`branch_1` (e.g. a bicycle on an empty sidewalk). After that, the rule and the other witnesses
should need no change.
