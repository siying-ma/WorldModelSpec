# LVMC_11_43_010_A — task result

## Final verdict: OK (4 witnesses, 5 names, composes nothing)

## Gate runs
1. **WITNESS_FAIL** — blind: the roundabout was built with no boundary, and with occupancy stated explicitly (`occupies := some [(1, 10)]`). The adapter rejects a structure without a boundary when occupancy is observed. Fix: the blind scene now reuses the mapped roundabout from the permit scene. The manifest masks `st.region_geometry`, so the reference point is unobserved and the clockwise concept is unknown, while occupancy stays observed.
2. **OK**.

## Rule
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")` (a2/a4).
- Applicability: `existsRegion roundabout r. rel_occupies(subject, r)` (a3) ∧ `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)` (a4 "travel").
- Obligation: `forallRegion roundabout r. rel_occupies(subject, r) → ¬ drv_motion_circulating_clockwise_about(subject, r; p.halt_speed_tolerance, p.roundabout_clockwise_sin_tol)` (a5). This repeats the applicability's roundabout selection in full and puts the duty on every occupied roundabout, as the record's obligation says.

## Choices left open
- I used `p.halt_speed_tolerance` for the clockwise concept's `speed_tol`, as the record's obligation names it.
- I added no narrowings of my own; the record's narrowings (a5 reading, a2 observable reading) are its own and are not restated.

## Witnesses
The roundabout is the square (-30,-30)–(30,30), with its reference point at (0,0). A car moving at 8 m/s follows a 20 m circle, one quarter turn per instant.
- **forbid**: clockwise → violated.
- **permit**: counter-clockwise → compliant.
- **idle**: a straight roadway with no roundabout → not applicable.
- **blind**: the permit scene with `st.region_geometry` masked → unknown.

## Why I finished
The gate returned OK on run 2 of 6.
