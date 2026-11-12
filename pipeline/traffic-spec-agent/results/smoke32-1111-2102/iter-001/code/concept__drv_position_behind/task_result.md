# drv.position.behind — task result

**Final verdict: OK** (3 witnesses, 3 names, reads 3 atoms). 3 of 6 gate runs used.

## Body

`rel_same_direction(a, b)[alignment] ∧ rel_bearing(a, b, ahead) ∧ rel_longitudinal_overlap(a, b) < 0 m`

- "headings aligned": `.atom "rel_same_direction" [a, b] [.param "alignment"]`. The formal is the cosine tolerance.
- "bearing of b from a pointing forward": `.atom "rel_bearing" [a, b, .lit "ahead"] []`. This holds where the bearing's longitudinal component is positive.
- "projections sharing no length (below zero)": `.cmp (.measure "rel_longitudinal_overlap" [a, b]) .lt (.lit (Units.metres 0) .metre)`.
- Nothing else is read: no speed (either road user may be at rest) and no lane (b may be in another lane).

## Gate runs

1. **WITNESS_FAIL**: blind came back compliant. Masking `rel.longitudinal_overlap` only blanks a measured relation field. Core still computed the overlap from the footprints. **Change:** in the blind scene the source now also lacks b's `kin.extent`, so the overlap can't be computed. b's position and both headings stay observed, so the bearing and the alignment are still decided.
2. **WITNESS_FAIL**: the adapter rejected the blind trace because track 2 was in `occupancyObserved` without a defined footprint. **Change:** removed track 2 from `occupancyObserved` and `occupies` in the blind scenes.
3. **OK**.

## Choices the record left open

- **Narrowings:** none. The contract states each element exactly, including the strict "below zero".
- **Instance:** `alignment` = 9/10 (`Units.ratio 9 10`).
- **Witness geometry:**
  - Two east-bound lanes; cars with half-extent 2 m × 1 m.
  - holds: a in the left lane moves from x = 0 to x = 4 m at 2 m/s. b is at rest in the right lane at x = 20 m. There is a gap between them, and the bearing is forward.
  - fails: a is at x = 18 m and b at x = 20 m, so their projections share 2 m. The bearing is still forward and the headings aligned, so only the overlap decides.
  - blind: the holds geometry, with the overlap masked and b's extent unobserved.

## Why I finished

The gate returned OK on both files. The record was consistent: every claimed atom is used, and no atom outside the claims is read.
