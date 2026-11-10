# NRS_484B_297_6_o1 — task result

**Final verdict: OK** (9 witnesses, 9 names, composes nothing)

## Gate runs
1. `WITNESS_FAIL` — `blind` was unknown for `assumption_missing:asm.sidewalk_section_missing_or_impassable`, not for the masked `st.region_geometry`. The encounter is `obstruction within reach ∨ asm`, so with the assumption undeclared the masked distance did not decide it. Fix: the forbid, permit and blind traces now declare `asm.sidewalk_section_missing_or_impassable = false`, since only the excavation is in the way. The masked geometry then decides the unknown.
2. `OK`.

## How the rule is written
- Class: `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
- `detourFrom w`: there is a highway `h` with `st_on_way w h`, x occupies `h` and no sidewalk now, and `since (x on no sidewalk) (x occupies w ∧ drv_motion_moving x ∧ (∃ obstruction o, dist(x,o) ≤ p.obstruction_encounter_reach ∨ asm.sidewalk_section_missing_or_impassable))`. Core's `since` is non-strict, so the departure observation is the one where x is on `w`.
- Applicability: `∃ sidewalk w, detourFrom w`, and not exception (c), which is `(∃ bicycle_lane_or_path b, x occupies b) ∧ asm.area_beside_bicycle_lane_impassable`.
- Obligation: for every sidewalk `w` with `detourFrom w` (the whole selection is repeated so it is the same region, per rule 3c), `st_region_geometry_distance x w ≤ p.pedestrian_detour_side_distance`.

## Choices the node left open
- **Which sidewalk the duty applies to:** "the sidewalk w it left" is written as every sidewalk that meets the full detour selection. In practice this is the one x left.
- **No narrowings were declared.** Every span is written as the record maps it.

## Witnesses added beyond the plan
- `branch_3` (violated): no obstruction within reach, but the sidewalk section is declared missing or impassable. This exercises the assumption limb.
- `branch_4` (not applicable): no obstruction within reach, and the sidewalk is declared passable.
- `branch_5` (not applicable): x is standing still at its last observation on the sidewalk. This exercises `drv.motion.moving`.

## Why I finished
The gate returned `OK`.
