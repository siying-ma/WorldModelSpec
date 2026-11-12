# drv.position.near_region — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom).

## Body

```lean
.cmp (.measure "st_region_geometry_distance" [aA, aR]) .le pReach
```

This is the ground distance from a's body outline to r, read through the distance accessor of the claimed atom `st.region_geometry` (zero when they overlap). It holds when that distance is at or below `reach`. The body does not read occupancy.

## Gate runs

1. **WITNESS_FAIL** — in `blind`, crosswalk 100 had no boundary while occupancy was observed. The trace linter rejects that combination. I changed the `blind` scenes to set `occupancyObserved := []`: a source that maps the crosswalk without its outline cannot observe occupancy of it either. The body was not changed.
2. **OK**.

## Choices the record left open

- **No narrowings.** The contract fixes the measure (body outline to region, zero on overlap), the comparison ("at or below", so `.le`) and the bound (`reach`).
- **Witness figures (the witness's own):**
  - `reach` = 3 m.
  - Crosswalk 100 is the rectangle x ∈ [10, 14] m, y ∈ [-5, 5] m.
  - Vehicle 1 heads east and stands still, with half-extents 2 × 1 × 1 m.
- **The three scenarios:**
  - `holds`: the vehicle's centre is at (7, 0) and its front 1 m before the crosswalk. 1 m ≤ 3 m.
  - `fails`: the vehicle's centre is at (-40, 0), 48 m away. 48 m > 3 m.
  - `blind`: the same geometry as `holds`, but the crosswalk has no boundary or reference point, `st.region_geometry` is declared absent, and occupancy is not observed.

## Why I finished

The gate returned OK on the second run (2 of 6 runs used). The record was sufficient as written.
