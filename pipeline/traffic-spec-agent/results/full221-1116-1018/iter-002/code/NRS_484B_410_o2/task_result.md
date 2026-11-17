# NRS_484B_410_o2 — task result

**Final verdict: OK** (8 witnesses, 14 names, composes nothing)

## Gate runs (2 of 6 used)
1. `UNUSED_CLAIM` (dev_governs, dev_regulatory_sign, drv_motion_complete_halt, prim_closest_approach_distance, …).
   I ran this by mistake on the harness skeleton before writing anything (all formulas were still `.tt`).
   I also piped it through `head`, so it was not the exact command as written. It changed no files.
   After it, I wrote the rule and the witnesses.
2. `OK`.

## How the rule is written
- **Class (s1):** `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- **Entry (s4):** `onHighway` = ∃ region of kind `highway` that the subject occupies (`rel_occupies`). The entry is `.rises onHighway`.
- **Exception (s2), read at the observation before the entry:** `haltedWhereNoParking` = `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` ∧ one of two cases:
  - the subject occupies a `curb_zone` of kind no_parking / no_stopping / fire_lane, or whose curb is coloured red;
  - the subject occupies a `travel_region` that is governed (`dev_governs`) by a `regulatory_sign` with code no_parking / no_standing / no_stopping, and `prim_conditions_hold(sign, subject)`.
- **"Previous observation":** Core has no operator for "at the previous observation", so the applicability is written as `rises(onHighway) ∧ rises(onHighway ∨ haltedWhereNoParking)`.
  - The first conjunct makes the disjunction true at the current observation.
  - So the second conjunct means exactly that at the previous observation the subject was neither on a highway nor halted where no parking is permitted.
  - Together that is the record's applicability, and it involves no choice of my own. The rule's header explains it.
- **Obligation (s5):** for every road user `other` of the scene, `same(other, subject)` ∨ ¬(`prim_closest_approach_within(subject, other; p.conflict_horizon)` ∧ `prim_closest_approach_distance(subject, other; p.conflict_horizon) ≤ p.conflict_centre_clearance`).
- **Narrowings:** none. Every reading above is the record's.

## Witnesses
- **Geometry:** the highway is a strip y ∈ [0, 20] m. The subject leaves the lot to the south at 2 m/s and enters the highway at t = 3 s. The conflicting car is 10 m east on the highway, closing at 13 m/s; their closest approach is about 0.46 m, after about 0.77 s.
- **Window:** every witness has `window` = 1000–3000 ms, because `rises` at the first observation reads an unobserved past.
- **The four planned witnesses:**
  - `forbid` → violated
  - `permit` → compliant (no other road user)
  - `idle` → not_applicable (the subject is on the highway throughout)
  - `blind` → unknown (`rel.occupies` masked)
- **Added branches:** each exercises one limb of the exception.
  - `branch_1`: the subject halted in a fire-lane curb zone → not_applicable
  - `branch_2`: halted at a red passenger-loading curb → not_applicable
  - `branch_3`: halted in a lot aisle governed by an unconditional no-stopping sign → not_applicable
  - `branch_4`: halted at a white passenger-loading curb, so the exception does not hold → violated

## Choices the node left open
- **How to say "at the previous observation":** I wrote it with `rises`, as explained above.
- **Witness layout:** I placed the curb zones and the aisle in the lot, outside the highway polygon. That way the halt happens off the highway and the entry happens at the next observation.

## Why I finished
The gate returned OK on the second run.
