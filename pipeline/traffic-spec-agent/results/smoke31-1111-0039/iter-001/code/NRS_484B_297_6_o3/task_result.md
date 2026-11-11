# NRS_484B_297_6_o3 — task result

**Final verdict: OK** (4 witnesses, 9 names, composes nothing)

## Gate runs
1. OK. This was the first run, so nothing changed afterwards.

## Rule
- Class of x: `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
- Applicability has two parts, joined by "and":
  - Part 1: there is a sidewalk `w` and a highway `h` with `st_on_way w h`. Now, x occupies `h` and no sidewalk, and has done so `since` an observation where three things held:
    - x occupied `w`;
    - `drv_motion_moving x` held at `p.speed_resolution`;
    - some `obstruction` region was within `p.obstruction_encounter_reach` (by `st_region_geometry_distance`).
  - Part 2: every obstruction is now farther away than `p.obstruction_encounter_reach`.
- Obligation: `within .time p.sidewalk_return_time "x"`, x occupies some sidewalk.

## Choices left open
- The sidewalk x returns to can be any sidewalk. This is what the record's obligation says ("w2 of kind st.sidewalk"), so it is not a narrowing.
- `since` is read as the usual past mirror of strong until: φ must hold at every observation after the ψ-observation, but not at that observation itself. The gate's witnesses confirm this reading.
- I declared no narrowings of my own; the record's two narrowings (s7, s16) are not repeated.

## Witnesses
- **Layout:** a highway (10), with a sidewalk (11) lying on it and an excavation (12) cutting the sidewalk.
- **Pedestrian:** walks east at 1 m/s and steps onto the roadway after coming within 1.7 m of the excavation. It is 2.7 m past the excavation at k = 13.
- **forbid:** stays on the roadway until k = 46, so it is violated.
- **permit:** back on the sidewalk at k = 15, so it is compliant.
- **idle:** stays on the sidewalk throughout, so the rule does not apply.
- **blind:** the forbid trace with `st.region_geometry` masked, so the result is unknown.

## Why I finished
The gate returned OK on the first run.
