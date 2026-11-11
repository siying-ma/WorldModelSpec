# drv.position.within_clearance_since_entry — task result

## Final verdict
**OK** (gate run 1 of 6): 3 witnesses, 2 names, reads 2 atoms, 1 narrowing declared.

## Body
```lean
def entry : Formula := .derived "drv_motion_entering_region" [aX, aR] []
def withinClearance : Formula :=
  .cmp (.measure "st_region_geometry_distance" [aX, aR]) .lt pClearance
def body : Formula := .since withinClearance entry
```
`since φ ψ` is evaluated as `ψ ∨ (φ ∧ since')`, and before the first observation the past is unobserved, so its value there is unknown. That makes the concept:
- true at an entry;
- true while the distance stays below clearance;
- false from the first observation at clearance or more, and false until the next entry;
- unknown before any decided entry, except where the distance already decides it.

## Gate runs
1. **OK**: the first submission. No changes were needed after it.

## Choices the record left open
- **Narrowing (declared):** the contract says "at every observation from that entry up to the observation". I check the distance at every observation after the entry, up to the judged one, but not at the entry itself. At the entry the footprint overlaps r, and the contract says the distance is zero while it overlaps. So the distance is below clearance there and cannot decide anything. This also means no leaf in the formula is redundant.

## Witnesses
- **Region and road user:** lane 100 is x ∈ [10, 20] m, y ∈ [−2, 2] m. Road user 1 has half-extents 2 × 1 × 1 m and heads east. Observations are 1 s apart.
- **Instance:** clearance = 3 m.
- **holds:** x is at −10, 0, 12, 15, 18, 23.5 and 23.5 m. It enters at t = 2000. At t = 5000 it has left r and stands 1.5 m from it. Judged at 5000; the expected result is compliant.
- **fails:** x enters at t = 2000 and leaves at t = 4000. At t = 7000 it stands 4 m from r, which is at least clearance. It then comes back to 2 m without entering again. Judged over [7000, 9000]; the expected result is violated at every observation.
- **blind:** the holds trace with `st.region_geometry` masked. Judged at 5000; the expected result is unknown.

## Why I finished
The gate returned OK on the first run.
