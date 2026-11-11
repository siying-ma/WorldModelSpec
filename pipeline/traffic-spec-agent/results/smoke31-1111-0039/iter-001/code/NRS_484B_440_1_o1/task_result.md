# NRS_484B_440_1_o1 — task result

## Final verdict
**OK** (9 witnesses, 18 names, composes nothing).

## Gate runs
1. **OK**. This was the first and only gate run. Nothing changed after it.

(An earlier shell call I made, the gate command with `--help` appended, was denied by the sandbox and never ran. It was not a gate run.)

## How the rule is written
- **Class (g4):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability:**
  - **g1:** x occupies some `highway` region.
  - **g2:** `not asm.within_business_or_residence_district`.
  - **g13:** not (engine not running ∧ hazard on ∧ x occupies some `roadway`).
- **Obligation:** not (`drv_motion_halted x [p.speed_resolution]` ∧ x occupies some `roadway` (g5) ∧ some `shoulder` within `p.offroad_stop_reach` by `st_region_geometry_distance` (g6) ∧ not excluded).
  - **g3 exclusions** (the "excluded" above is any one of these):
    - Some other user y (`not same x y`) with `rel_ahead_behind_in_lane y x` (y ahead of x) and a `rel_surface_gap x y` distance ≤ `p.stopping_conflict_gap`.
    - A `human_direction` device indicating `stop` that governs a `travel_region` x occupies.
    - A `traffic_signal` showing `circular_red`, `red_arrow(left|right|straight|u_turn)` or `flashing_red` that governs a `travel_region` x occupies.
    - A `stop_sign` that governs a `travel_region` x occupies.

## Choices the node left open
- **g5 placement:** the roadway condition goes in the obligation, as the record's `obligation` text places it. The record's `applicability` text does not mention it.
- **"a red_arrow":** written as all four arrow directions, in one disjunction.
- **Surface gap:** read as the distance, with no component, as the contract allows.
- **"within" and "at most":** both written as `≤`.
- **Narrowings:** none declared, because no reading narrower than the record's words was chosen.

## Witnesses
- **The six planned scenes:** `forbid`, `permit`, `idle`, `blind`, `branch_1` and `branch_2`, each with its planned verdict.
- **`permit`:** the nearest shoulder is about 58 m from x, beyond the end of the bridge.
- **Three added scenes,** so the device exclusions are exercised. Each is the `forbid` scene with one device added, and each expects compliant:
  - `branch_3`: a police officer directing stop, governing x's lane.
  - `branch_4`: a signal showing circular red, governing the roadway.
  - `branch_5`: a stop sign governing the roadway.

## Why I finished
The gate returned OK on the first run.
