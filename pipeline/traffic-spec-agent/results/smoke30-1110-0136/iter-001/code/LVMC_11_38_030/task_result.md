# LVMC_11_38_030 — task result

**Final verdict: OK** (8 witnesses, 6 names, composes nothing).

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. Nothing changed after it.

## How the node is written
- Class of `x` (s1, s2): `ru_aggregate x "DEF-NRS-484A-135::motorcycle"` ∨ `ru_moped x` ∨ `ru_electric_scooter x`.
- Applicability (s4): `asm "asm.within_city_limits"`.
- Obligation (s3): `not (drv_motion_moving x [p.motion_speed_tolerance] ∧ existsRegion sidewalk s (st_sidewalk s ∧ rel_occupies x s))`.
  The sidewalk region is tied to `x` by `rel_occupies`. The region kind is written as the record names it.

## Choices the node left open
- None beyond the record. The record already carries its own reading of "ridden" as motion, so
  I added no narrowing.
- I added one witness that the node did not plan: `branch_4` (violated), an electric scooter moving on the sidewalk.
  Without it, the `ru_electric_scooter` leaf would not change the verdict of any witness.
  An electric scooter is listed as *unresolved* in the motorcycle aggregate. That makes the
  aggregate atom unknown for it, so the scooter's own class atom has to decide the class.

## Witness geometry
- The roadway is region 11 (y from −10 m to 0 m) and the sidewalk is region 10 (y from 0 m to 3 m), both 100 m long.
- Track 1 heads east. Its reference point is at y = 1.5 m on the sidewalk and at y = −3 m on the roadway.
- A moving subject goes 5 m/s (the bicycle 4 m/s), well above the 0.2 m/s tolerance. A parked subject has speed 0.
- Each trace has 3 instants, 1 s apart.

## Why I finished
The gate returned OK on the first run.
