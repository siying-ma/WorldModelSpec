# NRS_484B_110 — task result

**Final verdict: OK** (4 witnesses, 4 names, composes nothing)

## Gate runs
1. OK — first run; nothing changed afterwards.

## Rule
- Class (s1): `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability (s2): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`. The subject is moving at the observation. "At any time" means every observation is judged, so I added no time operator.
- Obligation (s3): `∀ z of kind safety_zone, ¬ rel_occupies(subject, z)`. The quantifier's kind spelling carries `st.safety_zone`, and `rel_occupies` ties each zone to the subject.

## Choices left open
None. The record's own observable-reading narrowings (s2, s3) are written from their atoms and not repeated in the rule, so `narrowings` is empty.

## Witnesses
The safety zone is the rectangle x ∈ [21, 29], y ∈ [-2, 2]. The car is a motor vehicle heading east.
- **forbid:** the car drives at 8 m/s along y = 0, sampled every 0.5 s. Its reference point is inside the zone at x = 22 and x = 26, so the trace is violated.
- **permit:** the car drives at 8 m/s along y = 8 and never overlaps the zone, so the trace is compliant.
- **idle:** the car stays at rest (0 m/s) at y = 8, so the rule does not apply.
- **blind:** same as permit, with `rel.occupies` masked, so the verdict is unknown.

## Why I finished
The gate returned OK on the first run.
