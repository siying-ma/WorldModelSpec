# NRS_484B_307_7a_o3 — task result

**Final verdict: OK** (6 witnesses, 12 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` (every claimed name) — run by mistake on the untouched skeleton (all formulas `.tt`); no information beyond the expected baseline. (A no-op `echo` was also issued before it; it changed nothing.)
2. `OK` — after writing the rule's class, applicability and obligation and the six witnesses.

## How the rule is written
- **Class (s2/s6):** `ru_aggregate subject "DEF-NRS-484A-285::traffic"` ∧ `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **s1:** a traffic_signal device `s` with `dev_traffic_signal_shows` flashing_yellow_arrow(left) ∨ (right) ∨ (u_turn). The test is whether the state is among those displayed, so other states shown at the same time are allowed ("alone or in combination").
- **s2 (facing):** some `travel_region` `c` that the subject occupies, with `st_lane_enters c i` and `dev_governs s c`; `i` ranges over intersections.
- **Applicability:** ∃ s ∃ i of either (A) facing ∧ arrow now, or (B) `occupies subject i ∧ since (occupies subject i) (facing ∧ arrow)`, which is the record's "has occupied i since entering it from such a c while s displayed the arrow".
- **Obligation:** for each `s` and `i` satisfying the same full selection (restated under rule 3c), and for each `p` that is of the traffic aggregate, is not the subject (`same`) and occupies `i`: ¬(speed > p.halt_speed_tolerance ∧ prim_closest_approach_within ∧ prim_closest_approach_distance < p.conflict_centre_clearance) ∧ ¬rel_contact.
- **Choices left open:** none beyond writing the entry in limb B as `since`. I added no narrowings. The record's s10 narrowing (lawfulness not judged) belongs to the plan and is not restated.

## Witnesses
- forbid (violated), permit (compliant), idle (not_applicable, green_arrow(left) alone) and blind (unknown, `kin.speed` masked) follow the narratives.
- `branch_1` (violated): the duty applies only through limb B. The subject entered `i` under the arrow, the head now shows circular_red, and there is a conflict inside `i`.
- `branch_2` (compliant): the subject is halted in `c` while the oncoming car's centre approaches within the horizon and clearance. This exercises the speed and contact leaves.

## Why I finished
The gate returned OK.
