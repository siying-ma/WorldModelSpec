# LVMC_11_40_140_o2 — task result

**Final verdict: OK** (11 witnesses, 11 names, composes nothing).

## Gate runs
1. `UNUSED_CLAIM` — I ran this by mistake on the untouched skeleton, before writing anything.
   It listed every claimed name, as expected for a skeleton.
2. `OK` — after writing the rule and the 11 witnesses below.

I also tried two shell commands other than the gate by mistake: a bare `echo`, and the gate
command with `--help` appended (denied). Neither touched any file.

## How the rule is written
- **Class (e1):** `ru_aggregate` for the bicycle aggregate, OR the electric-bicycle aggregate,
  OR the electric-scooter aggregate.
- **On the sidewalk s (e5):** `rel_occupies(subject, s)` and `st_region_geometry_distance(subject, s) ≤ 0`.
  This reads the occupancy against the sidewalk's outline, as the element claims st.region_geometry.
- **Applicability:** there is a sidewalk region s for which this holds:
  `since(onSidewalk, rises(onSidewalk) ∧ asm.business_or_residence_district ∧ trigger)`.
  The trigger (e3) is checked at the entry onto s and has three limbs:
  - (i) **Alley or driveway, now or just before:** `A ∨ rises(¬A)`, where A means the subject
    occupies an alley or driveway/alley-entrance region. `rises(¬A)` means "A at the observation
    before, not now".
  - (ii) **No highway region just before:** written as `rises(H)`, where H means the subject
    occupies some highway region. The record's other case (no highway region at the entry either)
    is already covered by limb (iii), which then holds at the entry itself. So the disjunction is
    unchanged.
  - (iii) **Building:** `until(onSidewalk, ¬H)`.
- **Obligation (e6/e7):** for every road user p in the pedestrian aggregate:
  - not `rel_contact(subject, p)`, and
  - not [`kin_speed > p.halt_speed_tolerance` ∧ `prim_closest_approach_within(h)` ∧
    `prim_closest_approach_distance(h) < p.conflict_centre_clearance`].

  The record says "other than the subject", but this needs no clause. The pedestrian aggregate
  includes no class the subject can carry, so the subject is never one of the p.
- **Narrowings:** none declared. Every choice above is equivalent to the record's text.

## Witnesses
All scenes share one map: roadway, sidewalk, a highway polygon, two driveways and two alleys
(one of each runs across the sidewalk), and a building frontage. Planned witnesses: forbid,
permit, idle, blind (rel.occupies masked), branch_1. I added these branches so that each limb
and leaf decides at least one witness on its own:
- **branch_2:** emerging from a building. Violated.
- **branch_3:** entering a building from the roadway. Violated.
- **branch_4:** contact while the bicycle is at rest. Violated.
- **branch_5:** a bicycle leaves an alley; the pedestrian's closest approach is inside the horizon
  but beyond the clearance. Compliant.
- **branch_6:** outside a business or residence district. Not applicable.
- **branch_7:** entering a driveway whose apron runs across the sidewalk. Violated.

## Node problem to report (branch_1 and the electric-scooter limb)
The planned `branch_1` describes an **electric scooter**. But the run's reading puts no class in
`DEF-LVMC-11-02-083::electric_scooter` and leaves `ru.electric_scooter` unresolved. So an
electric scooter's membership is always unknown, and its class formula can never be true.

As a result, no witness can reach a decided verdict for a scooter. The planned verdict
(`compliant`) is impossible for a scooter, so `branch_1` is built with an **electric bicycle**
and keeps that planned verdict. For the same reason, the scooter disjunct of the class formula
never decides any witness. The gate did not flag this.

What the plan or reading agent should change: either the reading admits `ru.electric_scooter`
into that aggregate, or the node's branch_1 narrative stops naming a scooter.

## Why I finished
The gate returned OK.
