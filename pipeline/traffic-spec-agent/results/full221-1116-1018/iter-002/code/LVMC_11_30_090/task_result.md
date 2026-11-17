# LVMC_11_30_090 — task result

## Final verdict
**OK** (7 witnesses, 9 names, composes nothing, 1 coder narrowing).

## Gate runs
1. `OK` — first run, on the rule and witnesses written in one pass. Nothing changed afterwards.

## Rule as written
- Class (s2): `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- Selection (s1 + s3): there is a roadway `r` the subject occupies (`rel_occupies`), `r` lies on a highway `h` (`st_on_way r h`), and a sidewalk `w` lies on the same `h` (`st_on_way w h`).
- Applicability: some roadway `r` and highway `h` meet that selection.
- Obligation: for every roadway `r` and highway `h` that meet the whole selection again, the subject must be at rest (`drv_motion_complete_halt`, p.halt_speed_tolerance), or moving across `r` itself, or moving across a lane `c` it occupies that lies on `h` (`drv_motion_moving_across_carrier`, p.halt_speed_tolerance, p.crossing_motion_cos).

## Choices the node left open
- **Carriers read existentially (narrowing on s3, kind `reading`).** The record says "for a lane or roadway carrier c of r that it occupies … it is not moving across c". It does not say whether crossing one carrier is enough or whether all must be crossed. I read it as: crossing any one carrier (the roadway, or an occupied lane on the same highway) counts as crossing, not walking along. A moving pedestrian is therefore in violation only when its motion runs along every such carrier. This is declared in `narrowings` and explained in the file header.

## Witnesses
- `forbid`: the pedestrian walks east at 1.4 m/s in an eastbound lane. The roadway also carries direction east, and a sidewalk lies on the same highway. Expected violated.
- `permit`: the pedestrian walks north across the lane. Expected compliant.
- `idle`: same as `forbid`, but no sidewalk is on the highway. Expected not applicable.
- `blind`: same as `forbid`, with `kin.velocity` masked. Expected unknown.
- `branch_1`: the pedestrian is at rest in the lane. Expected compliant.
- `branch_2`: the pedestrian walks on the sidewalk and is on no roadway. Expected not applicable.
- `branch_3`: added by me. The pedestrian walks north across the lane, and the roadway has no designated direction, so only the occupied lane can decide the crossing. Expected compliant. This makes the lane leaves (`rel_occupies c`, `st_on_way c h`, moving across `c`) decisive.

## Why I finished
The gate returned OK on the first run.
