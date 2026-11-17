# NRS_484B_283_1b — task result

**Final verdict: OK** (gate run 6 of 6: 9 witnesses, 12 names, all 9 compositions resolved).

After run 6 I only edited comments: the rule header and the witness header. The harness re-runs the gate on the final files.

## Gate runs
1. **BUILD_FAIL**: there was an extra `)` in the exceptions conjunction. I removed it.
2. **GATE_TIMEOUT** (stack overflow): the standard used the surface-selected deceleration `cond` four times (2·a·t < 2·a·t_r + v). I rewrote it in the equivalent form `a·((t+t) − (t_r+t_r)) < speed(v)`, so `a` is read once.
3. **WITNESS_FAIL**: every witness came back unknown with `absent_atom:st_lane_direction`, which the composed exceptions read. In `blind`, `rises` was truncated at k=0.
   - I added an eastbound lane to the scenes.
   - I set `blind`'s `window` to 1000–2000 ms.
4. **WITNESS_FAIL**: the decided witnesses came back `not_applicable`, so a composed exception was engaged. In `blind`, the reasons showed only `st_lane_direction` and `since`, never the masked `rel.occupies`. Changes:
   - I added a marked crosswalk where the pedestrian steps off. My guess is that 484B.287's crossing-outside-a-crosswalk exceptions were the engaged ones; I could not read them.
   - I gave the roadway region itself an eastbound lane direction.
   - I reordered the applicability conjuncts (exceptions first, then the occupancy leaves). This changes nothing logically. Unknown results seem to carry the right operand's reasons, so `blind` now reports `rel.occupies`.
5. **VACUOUS**: the `ru_aggregate(v, vehicle)` guard I had put around the LVMC_11_46_030 `ruleApplies` was never exercised, because the composed rule's own binder class already decides it. I removed it. The composition is now the rule-6 form `.not (.existsUser "v" (.ruleApplies … [("subject","v")]))`.
6. **OK**.

## Choices the node left open
- **"Previous observation"**: I wrote it as `onRoadway ∧ rises(onRoadway ∨ ¬onPlaceOfSafety)`. This is exactly the record's condition: on a roadway here, and at the previous observation on no roadway but on a sidewalk, safety zone or median/divider.
- **Factor 2**: it is written as a sum, `t+t`, because the node declares no literals.
- **Narrowings**: none. The formulas state the record's reading and its own narrowings, nothing narrower.
- **Witness geometry**: the scenes use a marked crosswalk and lane direction so that the composed exceptions are decidedly not engaged. These are scene facts only and nothing in the rule depends on them.
- **Extra witnesses**: `branch_2` (wet road: violated, but would comply if dry), `branch_3` (ice: violated, but would comply if wet or dry), `branch_4` (stepping off a safety zone) and `branch_5` (stepping off a median/divider). Together they cover the surface and place-of-safety leaves.

## Observation for the plan
The witnesses only became decided once the pedestrian stepped off inside a crosswalk. So, as composed, the 484B.287 exceptions appear to take every crossing outside a crosswalk out of this duty. That fits the statute's structure, but the plan agent may want to confirm it is intended.

## Why I finished
The gate returned OK.
