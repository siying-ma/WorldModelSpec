# NRS_484B_533 — task result

**Final verdict: OK** (8 witnesses, 12 names, composes nothing; 1 coder narrowing).

## Gate runs
1. `VACUOUS` — obligation leaf `st_on_way e2 h` (in "no road edge lying on h is nearer") moved no
   decided witness: every edge in the scenes lay on h. Added `branch_4` (compliant): the nearest
   road edge belongs to a parallel way (not on h), and the wheels are turned toward h's own edge.
2. `OK`.

## Rule as written
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: `drv_motion_complete_halt subject [p.halt_speed_tolerance]` ∧ `ru_occupant_count subject = 0`
  ∧ ∃ highway h, `rel_occupies subject h` ∧ `|st_grade h| > p.grade_resolution`.
- Obligation: `¬kin_engine_running` ∧ `kin_parking_brake` ∧ ∀ highway h selected as in the applicability
  (occupied, grade beyond resolution), ∃ road edge e with `st_on_way e h` and `|offset(e)| ≤ |offset(e2)|`
  for every road edge e2 with `st_on_way e2 h`, and (offset(e) > 0 ∧ steer > res) ∨ (offset(e) < 0 ∧ steer < −res),
  offset = `prim_region_lateral_offset subject e`, steer = `kin_steer_angle subject`, both left-positive.

## Choices the node left open
- h in the obligation: the wheel duty is written for every highway selected as in the applicability
  (the record's "with h selected again as there"). Engine and brake don't depend on h, so they sit
  outside the quantifier.
- If two road edges on opposite sides are equally nearest, wheels turned toward either one comply.
  This is declared as a narrowing on s5 (`kind := "reading"`).
- An edge at zero offset (the reference point inside the edge region) gives no side, so no steering
  complies with it. The record's sign rule implies this; I'm noting it here, not declaring it.

## Witnesses
forbid (engine running) violated; permit (right curb nearest, wheels −15°) compliant; idle (grade 0.1 %)
not applicable; blind (permit with `kin.parking_brake` masked) unknown; branch_1 (wheels straight)
violated; branch_2 (one occupant) not applicable; branch_3 (left curb nearest, wheels +15°) compliant;
branch_4 (the nearer edge belongs to another way) compliant.

## Why I finished
The gate returned `OK` on run 2 of 6.
