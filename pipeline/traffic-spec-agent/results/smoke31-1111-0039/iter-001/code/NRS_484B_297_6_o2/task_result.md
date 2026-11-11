# NRS_484B_297_6_o2 — task result

**Final verdict: OK** (gate run 1 of 6: `OK — 5 witnesses, 9 names, composes nothing`).

## Gate runs
1. `OK` on the first run. Nothing was changed after it.

## How the rule is written
- **Class (s1, s8):** `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
- **Leaving the sidewalk at the obstruction (s2–s4):** x occupies the sidewalk w (`rel_occupies`), is moving (`drv_motion_moving` with `p.speed_resolution`), and some `obstruction` region is within `p.obstruction_encounter_reach` of x's body (`st_region_geometry_distance`).
- **The detour (s5, s7):** `st_on_way w h`. x occupies the highway h and no sidewalk, both now and at every observation since the leaving moment (`since`).
- **Applicability:** some sidewalk w and some highway h meet the detour condition, and exception (c) does not hold.
- **Exception (c) (s12, s13):** x occupies a `bicycle_lane_or_path` while some obstruction is within `p.obstruction_encounter_reach` of x's body.
- **Obligation (s9, s10):** for every sidewalk w and highway h, the detour selection is written out again in full and implies `st_region_geometry_distance x w ≤ p.pedestrian_detour_offset`.

## Choices the node left open
- I used the record's whole w/h selection in the obligation, with "for every" (rule 3c). Because of the `since` anchor, only the sidewalk x actually left can meet the selection.
- I used separate variable names for the two obstruction quantifiers (`o` in the applicability, `q` in the exception).
- I added no narrowings of my own. Every span is written as the record maps it.

## Witnesses
- **Layout:** highway y ∈ [-10, 5] m, sidewalk y ∈ [2, 5] m (on the highway), and a barrier blocking the sidewalk at x ∈ [0, 1] m. The pedestrian's body is 0.5 m × 0.5 m.
- **Leaving moment:** at t = 0 the pedestrian is on the sidewalk, moving, with the barrier 0.75 m away.
- **forbid:** the body is 4 m from the sidewalk. Expected violated.
- **permit:** the body is 0.5 m from the sidewalk, then back on it at t = 3 s. Expected compliant.
- **idle:** the pedestrian stays on the sidewalk. Expected not applicable.
- **blind:** the same trace as forbid, with `st.region_geometry` masked. Expected unknown.
- **branch_1:** the pedestrian is in a bicycle lane 3 m from the sidewalk, with a second barrier 0.5 m from its body. Expected not applicable.

## Why I finished
The gate returned OK on the first run.
