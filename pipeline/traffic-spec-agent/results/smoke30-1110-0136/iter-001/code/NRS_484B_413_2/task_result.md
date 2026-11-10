# NRS_484B_413_2 — task result

**Final verdict: OK** (6 witnesses, 7 names, composes nothing)

## Gate runs
1. `BUILD_FAIL` — the witness helper used `from` as a parameter name, and `from` is a Lean keyword. Renamed it to `onset`.
2. `CHECK_FAIL` — "window length is not a constant term" (twice). The record says the window length is selected with `Term.cond (asm …) 100 ft 300 ft`. `Rule.check` accepts only constant window lengths (a literal, a reading parameter, or arithmetic over them), and an assumption is none of those. So I moved the selection into the formula: `(asm → holdsFor .path 100ft x φ) ∧ (¬asm → holdsFor .path 300ft x φ)`. Wherever the assumption is decided, this gives the same result as the record's `Term.cond`.
3. `OK`.

## Rule
- Class: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Change of course (s7): for some `travel_region` c that x occupies (`rel_occupies`), `drv_lane_heading_offset_from_direction(x, c)` rises above `p.course_change_sin_tolerance` (left) or below its negative (right). `rises` is applied to the comparison only; occupancy is read at the judged observation.
- Applicability: a change to the left or a change to the right.
- Obligation: for each side, the change implies that the signal of that side (`sig_turn_indicator` of that side or `sig_hand_signal` of that side) held at every observation of the `.path` window behind. The window is the one the district selects, as described above.
- Following rule 3c, the obligation selects the region again with the same occupancy relation and the same rise.

## Choices the node left open
- I applied `rises` to the offset comparison inside the region quantifier, and read occupancy at the judged observation without requiring it at the previous one.
- I declared no narrowings. The district selection in the formula is equivalent to the record's `Term.cond`; it is not a narrowing.

## Note for the plan
The record's obligation says to use `Term.cond` over `asm.business_or_residence_district` for a window length, which Core's `Rule.check` refuses. Future records should state the selection as an implication at the formula level, as written here.

## Witnesses
There is one eastbound lane, and the vehicle moves at 10 m/s with one observation per second over 16 observations. Its heading departs by (5, ±1), an offset of about 0.196, at observation 15, which is at 150 m of path. The witness window excludes the first observation, which has no previous observation for `rises`.
- **forbid:** in a district, the indicator is left only over the last 10 m. Expected and got violated.
- **permit:** in a district, the indicator is left over the last 50 m. Expected and got compliant.
- **idle:** the heading stays aligned throughout. Expected and got not applicable.
- **blind:** same as permit, with the indicator and the hand signal masked. Expected and got unknown.
- **branch_1:** outside a district, the indicator is right over the last 50 m, then the vehicle changes course to the right. Expected and got violated.
- **branch_2 (added):** in a district, the arm signal is left over the last 50 m with the indicator off. Expected and got compliant. This is the only witness where the arm signal alone decides the verdict.

## Why I finished
The gate returned OK on the third run.
