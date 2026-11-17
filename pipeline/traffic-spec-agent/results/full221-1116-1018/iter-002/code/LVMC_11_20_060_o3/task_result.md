# LVMC_11_20_060_o3 — task result

**Final verdict: OK** (9 witnesses, 9 names, composes nothing).

## Gate runs
1. `OK`. This was the first run. Nothing changed after it.

## How the node is written
- **Class (e1):** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Applicability:** `asm.business_or_residence_district` and some roadway region r where:
  - `rel_occupies(subject, r)` holds (e11), and
  - for some region d of kind `driveway_or_alley_entrance`, or some region d of kind `alley`, `rel_occupies(subject, d)` has held since an observation where `rel_occupies(subject, d) ∧ ¬rel_occupies(subject, r)` (e3, emerging, written with `since`).
- **Obligation:** for every roadway r that meets the same selection (`emergingOnto`, the same formula as the applicability, rule 3c), and for every road user o that is not the subject, is in `ru_aggregate(o, vehicle)` and occupies r (e14), both of these must hold:
  - not (`kin_speed(subject) > p.halt_speed_tolerance` while `prim_closest_approach_within(subject, o; p.conflict_horizon)` holds and `prim_closest_approach_distance(...) < p.conflict_centre_clearance`), and
  - not `rel_contact(subject, o)`.

## Choices
The record left nothing open, so I declared no narrowings. The alley/driveway alternative is written as two region quantifiers joined by `or`, because the language's region quantifier takes a single kind.

## Witnesses
The node plans five: forbid, permit, idle, blind (with `rel.occupies` masked) and branch_1 (no other road user). I added four more so that every leaf is exercised:
- **branch_2:** contact alone (the subject is halted, touching a standing car) → violated.
- **branch_3:** the subject emerges from an alley → violated.
- **branch_4:** the crossing road user is a pedestrian, not a vehicle → compliant.
- **branch_5:** the car is on the other roadway of a divided highway → compliant.

## Why I finished
The gate returned OK.
