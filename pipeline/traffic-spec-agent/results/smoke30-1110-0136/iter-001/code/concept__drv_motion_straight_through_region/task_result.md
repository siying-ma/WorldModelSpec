# drv.motion.straight_through_region — task result

## Final verdict: OK

## Gate runs
1. **WITNESS_FAIL**: the `fails` trace could not come from the adapter. The yaw rate at a scene applies to the interval *before* that scene, and the headings I gave did not match a -45 deg/s rate. **Change:** the turn is now a single interval: east at t = 1 s, south at t = 2 s, with yaw rate -90 deg/s at t = 2 s and 0 elsewhere. Positions moved to (11, -6) and (11, -16).
2. **OK**: 3 witnesses, 3 names, reads 3 atoms.

## Body
`rises (¬ rel_occupies(x, i)) ∧ |headingSince x step (rel_occupies(x, i))| < max_angle`

- **Exit:** `rises (¬occ)` holds where the overlap is false now and was true at the observation before. That is only the exit observation, and it ends at the next one.
- **Entry:** the entry is where `occ` last rose, and `headingSince` integrates the yaw rate from there with `step` as the sampling bound. If the recording does not show the entry, or the yaw rate is missing, the result is unknown, as the contract requires.
- **Bound:** "below" is written as strict `<`.

## Choices the record left open
None that needed a narrowing; every part of the body is dictated by the contract's words. In the witnesses I chose:
- `step` = 2 s, `max_angle` = 30°.
- Intersection 100 is the rectangle [0, 20] × [-10, 10] m.
- Observations are 1 s apart, at t = 0–3 s.
- Each scenario is judged only at the exit observation (`window = (3000, 3000)`), the only instant at which the concept can hold.

## Why I finished
The gate returned OK.
