# drv.interaction.passing_on_right — task result

**Final verdict: OK** (3 witnesses, 4 names, reads 4 atoms). 4 of 6 gate runs used.

## Body

`sameWay ∧ sideBySide ∧ bOnLeft ∧ aGains`, at the observation:
- `rel_same_direction a b [cos_tol]`
- `rel_longitudinal_overlap a b ≥ 0` (zero written `Units.metres 0`, unit metre)
- `rel_bearing a b "left"`: the lateral component of the bearing from a to b is strictly positive
- `kin_speed a > kin_speed b + speed_tol` (strictly greater, because a difference at or below `speed_tol` counts as none)

## Gate runs

1. WITNESS_FAIL: `blind` gave compliant. Masking `rel.longitudinal_overlap` only drops a value the source measured. When no measured value is given, Core still computes the overlap from the footprints. Fix: in the blind trace the source also reports no body extents (`kin.extent := none`). Nothing else the body reads uses extent.
2. WITNESS_FAIL, same as run 1. I ran the gate by mistake before changing anything.
3. WITNESS_FAIL: admission rejected the blind trace. A track whose occupancy is observed must have a footprint. Fix: the blind scenes also observe no occupancy (`occupancyObserved := []`, `occupies := []`). The body doesn't read occupancy.
4. OK.

## Witnesses

Two eastbound cars, 5 m × 2 m. b drives along y = 0 and a along y = −4, so b is 4 m to a's left. There are three instants, 1 s apart.
- `holds`: a at 12 m/s, b at 10 m/s. The cars' projections along the road share 3 m, 5 m and 3 m.
- `fails`: a at 8 m/s, b at 10 m/s, side by side.
- `blind`: the `holds` trace with `rel.longitudinal_overlap` masked, as in the record, and no extents or occupancy observed.

Instance values: `cos_tol` = 98/100, `speed_tol` = 0.5 m/s.

## Choices the record left open

None needed a narrowing; `narrowings` is empty:
- "not negative" is ≥ 0.
- "positive" is the bearing's `left` selector (strictly > 0).
- "by more than" is strict.

In the blind trace, the missing extents and occupancy are a choice of the witness, not of the concept. They were needed because Core computes the overlap whenever the kinematics are present.

## Why I finished

The gate returned OK.
