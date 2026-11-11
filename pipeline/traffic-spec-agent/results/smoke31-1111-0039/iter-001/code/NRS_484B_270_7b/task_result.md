# NRS_484B_270_7b — task result

**Final verdict: OK** (5 witnesses, 5 names, composes nothing), after 4 of 6 gate runs.

## Gate runs

1. `WITNESS_FAIL` — blind: expected unknown, got compliant. The blind scene kept the permit clearance (1.3 m gap), so the duty was met whether or not x was overtaking. Change: blind takes the forbid geometry (0.3 m gap).
2. `WITNESS_FAIL` — blind: expected unknown, got violated. Masking `rel.longitudinal_overlap` only drops a *measured* overlap; Core recomputed it from the footprints (`Mask.scene`: "computed relations are blanked through the kinematics … only when the source lacks those too"). Change: in blind the car's extent is not observed, so Core cannot compute the overlap or the surface gap. The source supplies both as a measured relation x→y (overlap 1.8 m, gap (0, 0.3 m)), and the manifest drops the overlap.
3. `WITNESS_FAIL` — the trace lint: track 2 had no footprint but was in `occupancyObserved`. Change: blind's scenes set `occupancyObserved := [1]`.
4. `OK`.

## How the rule is written

- **Class of x (a1):** `ru_aggregate` of x for each of the three admitted aggregate ids, joined by `or`.
- **Applicability (a2):** `existsUser y`, where y is not x, y carries `ru_aggregate DEF-NRS-484A-130::motor_vehicle`, and `drv_interaction_overtaking_alongside(x, y)` holds with `p.same_direction_cosine` and `p.overtaking_speed_margin`.
- **Obligation (a2 + a4):** for every such y (same selection, repeated in full):
  - `rel_surface_gap(x, y) ≥ p.passing_lateral_clearance`, and
  - for every z other than x and y: not (`prim_closest_approach_within(x, z; p.immediate_hazard_gap)` and `prim_closest_approach_distance(x, z; p.immediate_hazard_gap) < p.conflict_clearance`).

## Choices the node left open

- **Which surface-gap reading:** I used `rel_surface_gap` with no component, which is the distance between the nearest points. That is the record's "the surface gap between x and y". I did not pick the lateral component, so no narrowing is declared.
- **Order of the two prim conjuncts:** `closest_approach_distance` is undefined when the users don't approach within the horizon. Pairing it in an `and` with `closest_approach_within` means the false `within` decides the case instead.
- **Witness geometry:** all figures are in the witness header. The cycle gains 1 m/s on the car, against a 0.5 m/s margin. The bodies overlap by 1.8 m along x's heading. The gap is 0.3 m (forbid, blind) or 1.3 m (permit, branch_1), against 0.9 m. In branch_1 the oncoming car reaches its closest approach in 2 s (horizon 4.1 s) at 2 m (radius 3 m).

## Deviation from a planned narrative, and something for the plan to look at

The `branch_1` narrative makes x an `ru.electric_scooter`. Under this run's reading, `DEF-NRS-484B-018::electric_scooter` includes **no** class, and `ru.electric_scooter` is only *unresolved*. So a scooter's membership in x's class is always unknown, and a scooter witness could never be decided violated. I built x in branch_1 as an `ru.electric_bicycle` instead; that class is included in `DEF-NRS-484B-017`. Nothing else in the scene changes.

The rule itself is fine. But the reading means no road user can ever be decidedly bound through the electric-scooter aggregate. The plan or reading agent should check whether `ru.electric_scooter` should be **included** in `DEF-NRS-484B-018::electric_scooter`, since the definition is the electric scooter's own.

## Why I finished

The gate returned `OK` on run 4.
