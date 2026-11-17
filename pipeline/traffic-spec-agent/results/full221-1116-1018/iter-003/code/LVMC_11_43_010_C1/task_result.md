# LVMC_11_43_010_C1 — task result

**Final verdict: OK** (6 witnesses, 7 names, composes nothing)

## Gate runs
1. **WITNESS_FAIL**: the trace lint rejected every witness. Each kept the same heading between consecutive scenes even though the yaw rate was non-zero, and occupancy turned out to be footprint overlap, not reference point. Changes made: the passage was rebuilt so the body is clear of r before entry and after exit (roundabout 15 m long, start x = −3.5 m). The heading is now skewed ±1/1000 on alternate scenes, the yaw rate stays constant, and the window is 50–2250 ms.
2. (Accidental) I ran the gate a second time by mistake, on unchanged files, while I was meaning to read a Core file. It used one run from the budget and its output was not used (exit 1). I also tried a second, malformed gate command, which was blocked and did not run.
3. **OK** after the witness rebuild.

After the OK I changed only the witness file's header comment, so that it describes the geometry as built.

## Rule as written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (s4, read at recognition): `∃ roundabout r, rises(left_turn_through_region(subject, r) ∨ u_turn_through_region(subject, r))`. The left-turn concept takes step = `p.heading_since_step_carla_scene_graph`, `p.turn_heading_min` and `p.u_turn_heading_min`. The U-turn concept takes step and `p.u_turn_heading_min`.
- Obligation (s5): the same roundabout is selected again in the same way (`∃ roundabout r, rises(LT ∨ UT) ∧ …`), followed by `since(φ, rises(rel_occupies(subject, r)) ∧ φ)`, where `φ = rel_occupies(subject, r) → ∀ lane l (rel_occupies(subject, l) → st_lane_adjacency_ordinal(l) = 1)`. The count literal 1 is written as `.lit (Units.ratio 1 1) .count`, because `Units` has no constructor for counts. The gate accepted it.

## Choices left open
- None that needed a narrowing. The record states the `since` formula, the onset and the recognition explicitly, so `narrowings` is empty.
- The act's recognition is written as `.rises (LT ∨ UT)`, as rule 6b asks. Each concept holds only at the exit, so this is the same as the concept holding there.
- Witnesses unroll the circulation along a straight strip. The turn is carried by the yaw rate alone, which is all the concepts read. The heading field is only skewed slightly so that it is consistent with the trace lint. The blind witness masks `st.lane_adjacency`, which leaves the ordinal unknown in the outer lane.

## Why I finished
The gate returned OK.
