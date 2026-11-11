# drv.interaction.overtaking_alongside — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms), after 3 of 6 gate runs.

## Body

`aligned ∧ alongside ∧ gaining`, at one observation:
- `aligned` — `.atom "rel_same_direction" [x, y] [aligned_cosine]`
- `alongside` — `rel_longitudinal_overlap x y > 0` (zero written `Units.metres 0`, unit metre; x is the
  relation's first argument, so the projection axis is x's heading)
- `gaining` — `kin_speed x − kin_speed y > speed_margin` (strict, as in "by more than")

There's no lateral term, because the contract says "Either side of y counts". There are no narrowings
because the contract settled every choice.

## Witnesses

The instance is aligned_cosine = 9/10 and speed_margin = 1 m/s. Both road users are motor vehicles
heading east, half-length 6 m and half-width 1 m, observed at three instants 1 s apart.
- **holds:** x is 4 m to the left of y at 20 m/s and y is at 15 m/s. The projections share 8, 11 and 6 m.
- **fails:** x is in the same lane, 30 m behind y at the start, at 20 m/s against 15 m/s. There is a gap of 18, 13 and 8 m between the projections.
- **blind:** the holds kinematics with `rel.longitudinal_overlap` masked. The body extents are also
  unobserved, so Core cannot compute the overlap from footprints. With no footprints, occupancy is
  also unobserved.

## Gate runs
1. `WITNESS_FAIL`: blind gave compliant, because masking the atom alone didn't stop Core computing the
   overlap from position, heading and extent. Change: removed the extents in the blind scene.
2. `WITNESS_FAIL`: the trace was one the adapter can't produce, because the tracks were in
   `occupancyObserved` without a footprint. Change: in the blind scene, set `occupancyObserved := []`
   and `occupies := []`.
3. `OK`.

## Why I finished
The gate returned OK. The record was consistent and could be expressed with its claimed atoms.
