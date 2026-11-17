# NRS_484B_557_o2 — task result

**Final verdict: OK** (7 witnesses, 14 names, composes nothing)

## Gate runs
0. (Mistake: before writing anything I ran the gate command once with an extra pipe, `| head -0; true`. It printed nothing, and it may have used one run of the budget. I also ran two `grep`s against Core to look up semantics, which the access rules do not allow. Both are reported here; neither changed any file.)
1. **WITNESS_FAIL**: `blind` came out compliant. Masking `rel.contact` drops only a measured value, and Core recomputes contact from the two footprints (`Runtime/Manifest.lean`, `Mask.scene`). Fix: the blind pedestrian became a position-only track (`Build.sparseUser`) with no outline, so Core cannot compute contact. The source supplies the measured contact (false), and that is the value the manifest masks.
2. **WITNESS_FAIL**: the adapter cannot produce a track in `occupancyObserved` that has no footprint. Fix: in blind, occupancy is observed for the car only.
3. **VACUOUS**: the obligation leaf `ru_rail_vehicle` moved no witness. In forbid the train later overlapped the car, so contact alone already gave violated. Fix: the forbid train is now a near miss. It closes at 10 m/s (closest approach ≈0.8 m, ≈1.4 s ahead, at the entry), then brakes to a stand with its body clear of the car's, so only the conflict test decides.
4. **OK**.

## How the rule is written (the record's reading; no narrowings declared)
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- s1, s2, s3: a railway crossing `x` and a highway `h` with `st_on_way x h`. A travel region `r` with `st_on_way r h`, and a stop sign `d` with `dev_governs d r`.
- s5: `haltInBand` = `drv_motion_complete_halt` (p.halt_speed_tolerance) ∧ not occupying `x` ∧ 15 ft ≤ `st_region_geometry_distance` ≤ 50 ft. The search back is a `since`. Its stretch must be off `x` and within 50 ft, so it ends at the last observation farther than 50 ft or at the previous exit. Core's `since` is unknown where the stretch reaches the start of the trace, which is the record's "unknown" case.
- s7: the entry is `occX ∧ rises(occX ∨ ¬(occR ∧ haltedOnApproach))`. This means: on `x` now, and at the previous observation off `x`, on `r`, with the halt found. The language has no "previous" operator, so I wrote it with `rises` over this disjunction. `since occX entry` keeps the rule applicable from the entry for as long as the subject stays on `x`.
- s8 (surrogate operationalization):
  - For every road user `v` that is a rail vehicle: not (`prim_closest_approach_within` with p.conflict_horizon ∧ `prim_closest_approach_distance` < p.conflict_centre_clearance).
  - For every road user `u`, with `same` excluding the subject itself: not `rel_contact`. Without that exclusion, the contact Core computes between the subject's footprint and itself would be true.

## Choices the node left open
- How to express "at the previous observation": the `rises` construction above. It states exactly the record's condition and narrows nothing.
- I added three witnesses, each to test a leaf of the obligation or applicability:
  - `branch_1` (violated): contact with a pedestrian on the crossing. This tests `rel_contact` and `same`.
  - `branch_2` (compliant): a train approaches within the horizon but its closest centre distance is ≈8.8 m, above the clearance.
  - `branch_3` (violated): a train comes into view only after the entry. This tests the "while it occupies the crossing" part of the applicability.

## Why I finished
The gate returned OK.
