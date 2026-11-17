# NRS_484B_410_o1 — task result

**Final verdict: OK** (10 witnesses, 14 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` — run on the harness skeleton before any edit (all formulas were still `.tt`), so every claimed name was reported unused. This run was not needed and used up one gate run.
2. `OK` — after writing the rule and the ten witnesses.

## How the rule is written
- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Start (s3):** `heldOnHighway := complete_halt(subject; p.halt_speed_tolerance) ∧ ∃ highway the subject occupies ∧ ¬noParkingPlace`.
  Applicability is `¬complete_halt ∧ rises(¬heldOnHighway)`. This is true exactly where the subject is not halted now and `heldOnHighway` held at the previous observation. So the halt, the highway occupancy and the exception are all read at the previous observation, as the record says.
- **Exception (s2):** `noParkingPlace` is true in either of two cases:
  - The subject occupies an `st.curb_zone` whose kind is `no_parking`, `no_stopping` or `fire_lane`, or whose colour is `red`.
  - The subject occupies an `st.travel_region` that a `dev.regulatory_sign` governs (`dev.governs`), the sign's code is `no_parking`, `no_standing` or `no_stopping`, and `prim.conditions_hold(sign, subject)` is true.
- **Obligation (s5):** for every road user `other`, either `other` is the subject (`same subject other`), or it is not the case that both `prim.closest_approach_within(subject, other; p.conflict_horizon)` holds and `prim.closest_approach_distance(subject, other; p.conflict_horizon) ≤ p.conflict_centre_clearance`.
- **Not carried:** s4, the sibling clause, is not carried by this node.

## Choices left open
- **Writing "the previous observation":** I wrote it with `rises` over the negation of `heldOnHighway`, conjoined with `¬halt`. This is an exact encoding of the record's applicability, not a narrowing, so `narrowings` stays empty.
- **Judged instants:** at the first observation of a trace, `rises` cannot see a previous observation and is unknown. Every witness therefore sets `window := (1000, 2000)`, so only observations that have one before them are judged.
- **Blind witness:** it masks `kin.speed` in its manifest. Its scenes also leave `kin.speed` unset, and it includes the closing car, so the unknown halt is what leaves the verdict open.
- **Extra branches that exercise every leaf:**
  - **branch_2:** a red curb whose kind is `restricted_parking`, so the colour alone marks no parking. Expects not applicable.
  - **branch_3:** an unpainted curb zone of kind `no_parking`, so the kind alone marks it. Expects not applicable.
  - **branch_4:** a lane governed by a no-parking sign with no conditions (`conditions := some {}`). Expects not applicable.
  - **branch_5:** the same sign, but its conditions are weekdays 08:00–18:00 and the scene is a Sunday at noon. The conditions fail, so the duty applies. Expects violated.
  - **branch_6:** a car passes in the next lane, 5 m to the subject's side. Their paths approach within the horizon, but the centres stay farther apart than the clearance. Expects compliant.

## Why I finished
The gate returned `OK`.
