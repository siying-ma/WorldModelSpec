# NRS_484D_165_4 — task result

**Final verdict: OK** (6 witnesses, 3 names, composes nothing)

## Gate runs
1. `OK` — first run; nothing changed after it.

## Rule
- Class of `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: `drv_motion_parked subject [p.halt_speed_tolerance, p.parking_min_duration]`
  ∧ (`sig_headlamp subject low_beam` ∨ `sig_headlamp subject high_beam`) — s2 and s1. These are the
  record's applicability words.
- Obligation: `sig_headlamp subject low_beam` — s3, "depressed or dimmed" = low beam, per the element.

## Choices the node left open
None. The record states each span exactly, so I declared no narrowing.

## Witnesses
There are 31 scenes, one every 10 s from 0 to 300 s. Each witness is judged over the window 200–300 s, so the
180 s parked window is always covered.
- forbid: a motor vehicle at rest with high beam → violated.
- permit: the same with low beam → compliant.
- idle: the same with headlamps off → not applicable.
- blind: the same with `sig.headlamp` masked (and the field left unset) → unknown.
- branch_1 (planned): drives at 10 m/s until 270 s, then halts with high beam; it is not parked at any judged instant → not applicable.
- branch_2 (added): a bicycle (not in the vehicle aggregate) at rest with high beam → not
  applicable. It exercises the binder-class leaf.

## Notes
One read-only `grep` on Core files was denied because it used a `cd` in a compound command. I didn't need it: the surface had everything required.

## Why I finished
The gate returned OK on the first run.
