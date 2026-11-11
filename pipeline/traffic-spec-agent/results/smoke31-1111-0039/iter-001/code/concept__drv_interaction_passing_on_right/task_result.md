# drv.interaction.passing_on_right — task result

**Final verdict: OK** (3 witnesses, 4 names, reads 4 atoms). Gate runs used: 3 of 6.

## Body

The four elements are joined with `and`, at one observation:

- `rel_same_direction x y` with tolerance `.param "aligned_cosine"`
- `rel_longitudinal_overlap x y > 0` (the contract's word "positive"; zero written `Units.metres 0`)
- `rel_bearing x y "left"`: the Boolean reading of the bearing's lateral component, with positive meaning left in x's frame
- `kin_speed x - kin_speed y > .param "speed_margin"` (strict, from "by more than")

## Gate runs

1. **WITNESS_FAIL**: `blind` gave compliant, not unknown. Core's mask for `rel.bearing` blanks only a *measured* bearing. Core then computes the bearing from the positions and heading (`relFrame`). Fix: in the blind trace, y's position is not reported. Core then cannot compute the bearing (or the overlap), so the overlap is supplied as a measured relation from x to y (2 m, 4.5 m, 3 m, the holds geometry's values). Headings and speeds are still reported.
2. **WITNESS_FAIL**: the adapter check rejected track 2. It was in `occupancyObserved` but had no footprint. Fix: `occupancyObserved := [1]` in the blind scenes.
3. **OK**.

## Choices the record left open

- **Instance values:** `aligned_cosine = 9/10` and `speed_margin = 1 m/s`.
- **Geometry:** an eastbound shoulder and a rightmost lane, two cars 5 m × 2 m, three instants 0.5 s apart.
  - **holds:** x is on the shoulder at 20 m/s and y is 3.5 m to its left at 15 m/s. Their overlap goes 2 m, 4.5 m, 3 m.
  - **fails:** x is 10 m or more behind y in the same lane, so the overlap is negative and y is dead ahead.
  - **blind:** as described above.
- **Narrowings:** none. Each element maps directly to one atom reading the contract names.

## Why I finished

The gate returned OK. Both files are complete and the record needed no correction.
