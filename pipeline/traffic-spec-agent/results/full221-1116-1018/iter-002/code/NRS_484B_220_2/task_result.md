# NRS_484B_220_2 — task result

**Final verdict: OK** (4 witnesses, 4 names, composes nothing)

## Gate runs
1. `OK` — first run, on the rule and witnesses as first written. Nothing changed after it.

## How the node is written
- s1 (subject): `clsSubject = ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- s2 (trigger): `applicability = ∃ r : roundabout. rel_occupies(subject, r)`. The claim st.roundabout is the quantifier's kind.
- s3 (obligation): `∀ r : roundabout. rel_occupies(subject, r) → ¬ drv_motion_circulating_clockwise_about(subject, r)`
  with speed_tol = `p.halt_speed_tolerance` and sin_tol = `p.roundabout_clockwise_sin_tol`. The obligation repeats the applicability's
  whole selection of the region (rule 3c) and applies to every roundabout the subject occupies, as the record's obligation says.

## Choices the node left open
None. The record's own narrowings (radial motion is not a breach; "driven" read through controlled motion) are the plan's, so they
are not restated. `narrowings` is empty.

## Witnesses
Roundabout `10`: the square (-30,-30)–(30,30), with its reference point at (0,0). Subject track 1 is a motor vehicle at 6 m/s.
- forbid: at (0,-15) heading west. d×v = -90, which is clockwise and clears sin_tol by a wide margin → violated.
- permit: at (0,-15) heading east. d×v = +90, which is counter-clockwise → compliant.
- idle: on a straight roadway at (0,-195), away from the roundabout. Occupancy is observed and false → not applicable.
- blind: as forbid, with kin.velocity masked and the field left unset → unknown.

## Why I finished
The gate returned OK on the first run.
