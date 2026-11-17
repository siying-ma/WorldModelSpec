# NRS_484B_307_4a_o1 — task result

**Final verdict: OK** (9 witnesses, 11 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` — an accidental run on the untouched skeleton (I wrapped the gate command in a pipe by mistake), before I had written anything. Nothing changed because of it.
2. A second accidental call ran in the background with a 1 ms timeout and failed. It ran on the skeleton, and I never read its verdict. A third stray command (`--help`) was refused by the permission layer and did not run.
3. `WITNESS_FAIL` — in `permit`, `branch_1` and `branch_2` the heading stayed fixed while the yaw rate said it should turn ("not one the adapter can produce"). Fix: the heading vectors now follow the yaw rate. Each interval turns by the rate of the scene that ends it. The vectors come from a Taylor series with π ≈ 355/113, floored to 10⁻⁹. Positions now advance 0.72 m per scene along the heading.
4. `OK`.

## Rule
- Class: `ru_aggregate subject DEF-NRS-484A-285::traffic` ∧ `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- Occasion (event): the rule is judged when the subject exits intersection `i`: `rises (¬ rel_occupies subject i)`. The act starts at the latest entry, `rises (rel_occupies subject i)`. The stretch from entry to exit is written as `since (¬ rises occ_i) …`, which stops at the latest entry and cannot reach an earlier passage.
- s2: carrier `c` (`travel_region`) with `st_lane_enters c i`, occupied by the subject at the entry. Traffic signal `d` with `dev_governs d c`.
- s1, read at `some_moment` in [entry, exit]: `since (¬rises occ_i) (arrowAlone dir ∧ since (¬rises occ_i) (rises occ_i ∧ occ_c))`, for dir ∈ {left, right, u_turn}.
- s3: at the exit, the turn concept for the arrow's direction must hold over `i`, with the node's parameters. The u-turn concept takes only the step and `p.u_turn_heading_min`.
- Obligation: the applicability's whole selection (i, c, d, dir) is restated, and for that selection the passage must match the arrow's direction.

## Choices the node left open
- **"Alone"**: the green arrow is shown and none of the other concrete states of the enumeration is shown (all circular and flashing states, `dark`, every other arrow). If the head shows `unknown` (a face the source could not read), I don't treat the arrow as decidedly not alone. Instead the arrow is wrapped in `definedWhen (¬ shows unknown)`, so the result is unknown. This follows the three-valued rule that unobserved is never false. It is not a narrowing: s1 is a trigger and is carried as written.
- **Quantifier over selections**: the obligation is existential over (i, c, d, dir). I took this from the record's own words ("Re-binding i, c, d and dir with the whole selection … matching any one of them complies"), so I declared no narrowing. One point for review: `st.lane_enters` says a rule never picks the carrier that favours the road user. If the subject occupied two approach carriers at entry with different signals, the existential choice could favour the subject. The record does not separate that case. None of the witnesses has it.

## Witnesses
`forbid`, `permit`, `idle`, `blind` (`kin.yaw_rate` masked), `occasion_s1` (arrow alone from entry until k=5, then yellow arrow) and `occasion_s1_outside` (arrow alone only before entry, then circular red), as planned. I added:
- `branch_1`: right arrow alone, 90° right turn, compliant.
- `branch_2`: u-turn arrow alone, 180° reversal, compliant.
- `branch_3`: left arrow shown with circular red, so not alone; not applicable.

All witnesses use `window = 50…1200 ms`, because the `rises` edges cannot be observed at the first scene. Occupancy is stated scene by scene. On the turning traces this is the witness's own schedule (entry at k=2, exit at k=22), not occupancy derived from the turned geometry. The gate accepted it.

## Why I finished
The gate returned `OK`.
