# NRS_484B_440_1_o3 — task result

**Final verdict: OK** (5 witnesses, 8 names, composes nothing; 1 narrowing declared by the coder)

## Gate runs
1. `BUILD_FAIL` — the witness gave region ids as strings (`"hw"`, `"rw"`); `RegionId` is numeric. Changed them to `10` and `11`.
2. `OK`.

## How I wrote the rule
- Class of `x`: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability: x is halted (`drv_motion_halted x p.speed_resolution`), x occupies some `highway` region (g1) and some `roadway` region (g5), the assumption `asm.within_business_or_residence_district` does not hold (g2), and the g13 exception does not apply. The exception is "engine not running ∧ hazard lamps on ∧ x occupies some roadway".
- Obligation (g12): for every `roadway` x occupies, while x also occupies a highway (the applicability's selection written again), that roadway's `st_sight_distance` is at least `Units.feet 200`.

## Choices the node left open
- **g12, declared as a `reading` narrowing:** "The sight distance at x's place" is read from the roadway regions x occupies. If x straddles more than one roadway, the 200 ft is required at each of them.
- No other choices: every span that decides when the rule applies is written as the node maps it.

## Witnesses
The scene is a rural highway (0–400 m × ±10 m) with a roadway (±4 m). x is a motor vehicle at (100, 0). The assumption is declared false in every scene. The engine is running and the hazard lamps are off unless a scenario says otherwise.

| Scenario | Expected | Scene |
|---|---|---|
| forbid | violated | Halted; sight distance 30 m (200 ft is 60.96 m) |
| permit | compliant | Halted; sight distance 300 m |
| idle | not applicable | Driving at 15 m/s; sight distance 30 m |
| blind | unknown | As forbid, with `st.sight_distance` masked |
| branch_1 | not applicable | As forbid, but engine off and hazard lamps on |

## Why I finished
The gate returned `OK`. Two of six gate runs were used.
