# NRS_484B_307_4b — task result

**Final verdict: OK** (14 witnesses, 18 names; composes NRS_484B_283_1d1, 1d2, 1d3_o2, 1d4_o2).

## Gate runs
1. `UNUSED_CLAIM`: run on the skeleton with its placeholder formulas, before I wrote anything. I piped this run through `head`, which wasted one run of the budget.
2. `WITNESS_FAIL` (blind): I had removed the heading from the trace, which left the footprint undefined, and the adapter rejected the trace. Fix: blind now uses forbid's scenes, and only the manifest masks `kin.heading`.
3. `VACUOUS`: no witness exercised the applicability leaf `rel_occupies(subject, r0)` (the "overlapped no roadway on w at the previous observation" test). I added branch_9 (pedestrian already on the roadway).
4. `WITNESS_FAIL` (branch_9): I expected not_applicable but got compliant. The junction also lies on highway 102, and the pedestrian entered no roadway of 102, so the selection holds for w = 102 and the rule applies there. That matches the record, so I changed branch_9's expected verdict to compliant.
5. `VACUOUS` (same leaf): the w = 102 selection keeps the applicability true whatever the leaf's value. Fix: I added roadway 111 of highway 102 (north arm) and branch_10 (not_applicable). In branch_10 the pedestrian stands at the corner, already overlapping roadways of both ways at every observation.
6. `OK`.

## How the record is written
- s1 "green turn arrow alone": `dev_traffic_signal_shows` with `green_arrow(left|right|u_turn)`, plus the negation of every other indication: the circular, flashing, dark and unknown indications, the green straight arrow, and the yellow, red and flashing-yellow arrows in all four directions.
- s3/s5 facing: written exactly as the record states. Δ runs from `kin_position` to `dev_position` and h is `kin_heading`; the conditions are h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|² and |Δ|² ≤ reach². The traffic-signal parameters are used for the vehicular head and the pedestrian-signal parameters for the pedestrian head.
- s4: the head controls junction x in one of two ways:
  - it governs x directly (`dev_governs(s, x)`), or
  - it governs a `travel_region` l with `st_lane_enters(l, x)`.

  w is a highway with `st_on_way(x, w)`. The obligation repeats the whole selection for every s, x and w, and for every roadway r on w requires that the subject does not overlap r or is permitted.
- "At the previous observation": the language has no previous-observation operator, so I wrote it through `rises` as `rises ψ ∨ (¬ψ ∧ ¬rises ¬ψ)`, which is exactly "¬ψ at the previous observation". Because this looks back one observation, every witness judges `window = (1000, 2000)`.
- s5: some pedestrian head showing walk, or dont_walk_flashing with its countdown, that the subject faces and that governs either r or a lane on w that the subject overlaps.
- s6: the four exceptions are written as `.not (.ruleApplies …)` in the applicability.
- I added no narrowings: every choice is the record's own reading.

## Witnesses beyond the plan
- **branch_8 (compliant):** the walk head governs only the lane the pedestrian occupies, which exercises the lane limb of the permission.
- **branch_9 (compliant):** the pedestrian is already on the roadway, so there is no entry.
- **branch_10 (not_applicable):** the pedestrian already overlaps roadways of both ways at the corner.

## Observation for the plan
The applicability is existential over the highways on which the junction lies. As a result, a pedestrian already on the roadway of one way still engages the rule through the other way, and is compliant there rather than outside the rule. This follows the record; I note it only because it decided branch_9's verdict.

## Why I finished
The gate returned OK.
