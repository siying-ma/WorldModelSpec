# LVMC_11_38_030 — task result

**Final verdict: OK** (5 witnesses, 6 names, composes nothing)

## Gate runs
1. `OK` on the first run. No changes after it.

(Before the first gate run I sent one stray shell command that tried to list Core files. The
permission layer denied it and it did nothing. It was not a gate run.)

## How the rule is written
- **Class of x (s1):** `ru_aggregate [x, "DEF-NRS-484A-135::motorcycle"] ∨ ru_moped x ∨ ru_electric_scooter x`.
- **Applicability (s3):** `asm "asm.within_city_limits"`.
- **Obligation (s2):** `¬ (drv_motion_moving x [p.speed_resolution] ∧ ∃ w : sidewalk. st_sidewalk w ∧ rel_occupies x w)`.
  "Any" is written as an existential over every sidewalk region in the scene. `rel_occupies`
  ties the region to x.

## Choices the node left open
- None beyond the record. The record already holds the agency reading of "be ridden" as an
  observable_reading narrowing, so I did not repeat it. I declared no narrowings of my own.

## Witnesses
The scene has a roadway at y 0–7 m, a lane at y 0–3.5 m and a sidewalk at y 7–10 m. Every
scene is inside city limits.
- **forbid:** a motorcycle on the sidewalk at 2 m/s, which is violated.
- **permit:** a motorcycle in the lane at 10 m/s, which is compliant.
- **idle:** a bicycle on the sidewalk, which is not applicable.
- **blind:** a moped moving at the curb with `rel.occupies` masked, which is unknown.
- **branch_1:** a motorcycle parked on the sidewalk at speed 0, which is compliant.

## Why I finished
The gate returned OK on the first run.
