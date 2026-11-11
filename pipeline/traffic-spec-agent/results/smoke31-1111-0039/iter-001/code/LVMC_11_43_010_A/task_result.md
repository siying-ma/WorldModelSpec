# LVMC_11_43_010_A — task result

**Final verdict: OK** (gate run 1 of 6: "5 witnesses, 4 names, composes nothing").

## Gate runs
1. OK — first run after writing the rule and the witnesses. Nothing changed afterwards.

(One accidental no-op shell call, `true`, was issued before the gate; it ran nothing and used no gate run.)

## Rule
- Class of `x`: `ru_aggregate(x, "DEF-NRS-484A-320::vehicle")`.
- Applicability (t3): `existsRegion roundabout r. rel_occupies(x, r)`.
- Obligation (t4): `forallRegion roundabout r. rel_occupies(x, r) → ¬ drv_motion_clockwise_about_region(x, r)`
  with `[p.speed_resolution, p.circulation_sine_tolerance]` (speed_floor, sine_tolerance, in the concept's order).
  The obligation repeats the applicability's full selection of the region and applies it to every
  selected roundabout, as the record's "for every" says.

## Choices left open
- None beyond what the record states. The record's own narrowing on t4 (counter-clockwise judged
  as the absence of clockwise motion; radial motion and standstill comply) is the plan's and is
  not repeated in `narrowings`, which stays empty.
- The harness-written `zeroMetres` helper is left in place, unused.

## Witnesses
Roundabout region 10: a 60 m square outline with its reference point at the origin. Car, track 1, motor vehicle.
- forbid (violated): drives clockwise at 10 m/s, radius 15 m. Cross product −150 against a tolerance bound of 30.
- permit (compliant): same radius, counter-clockwise.
- idle (not_applicable): on a roadway block at x≈200, outside the roundabout outline. Occupancy is observed and false.
- blind (unknown): same scene as forbid, with kin.velocity masked.
- branch_1 (compliant): an entry approach inside the outline, driving straight west toward the centre at 5 m/s. The motion is radial, so the cross product is 0.

## Why I finished
The gate returned OK on the first run.
