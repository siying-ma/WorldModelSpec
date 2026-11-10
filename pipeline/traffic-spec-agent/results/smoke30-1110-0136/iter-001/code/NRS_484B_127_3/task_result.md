# NRS_484B_127_3 — task result

**Final verdict: OK** (6 witnesses, 7 names, composes nothing). The gate was run 3 times out of a budget of 6.

## Gate runs
1. **WITNESS_FAIL**: `blind` expected unknown and got violated. Masking `rel.surface_gap` only drops a *measured* gap. Core computes the gap from the two footprints, so with both cars fully observed the gap was still decided.
   - Change: the blind scene's leader now has no reported extent, so Core cannot compute the gap. The source supplies the gap as a measured value (5 m), which the mask then drops.
2. **WITNESS_FAIL**: the adapter rejects a track that is listed as occupancy-observed but has no footprint.
   - Change: in the blind scene only track 1's occupancy is observed (`occupies` = highway 10 and lane 11).
   - Without the leader's occupancy, Core cannot compute `rel.ahead_behind_in_lane`. The source supplies it as measured (`aAheadOfB` on relation 2→1).
   - Everything else in the scene is still decided, so the masked gap is the only thing that leaves the verdict unknown.
3. **OK**.

## How the rule is written
- **Class of x:** `ru_aggregate x "DEF-NRS-484A-130::motor_vehicle"`.
- **Applicability:**
  - `drv_motion_moving x [p.motion_speed_tolerance]`
  - and there is some region of kind `highway` that x occupies (`rel_occupies x h`)
  - and both declared assumptions hold.
- **Obligation:** for every road user y with
  - `¬same(x, y)`,
  - (`ru_aggregate y vehicle` ∨ `ru_aggregate y combination_of_vehicles`),
  - and `rel_ahead_behind_in_lane y x`,
  
  the gap must satisfy `rel_surface_gap x y ≥ p.caravan_entry_vehicle_length + p.caravan_entry_time_headway·kin_speed x + p.caravan_entry_time_headway·kin_speed x`. This is the record's obligation as written.

## Choices the node left open
- **How the gap is read:** `rel_surface_gap` is read with no component (the two-argument form). The atom's contract says that read is the distance between the nearest points of the two bodies, and the record writes `rel.surface_gap(x, y)` with no component. This adds no narrowing, so `narrowings` stays empty.
- **Witness geometry** (the reading's bound at 25 m/s is 72.4 m):
  - **forbid:** gap 5 m.
  - **permit:** gap 146 m.
  - **idle / branch_2:** the forbid geometry with one assumption set false.
  - **branch_1:** x alone on the highway.

## Why I finished
The gate returned OK.
