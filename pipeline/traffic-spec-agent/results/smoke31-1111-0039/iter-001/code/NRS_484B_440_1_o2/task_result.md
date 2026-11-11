# NRS_484B_440_1_o2 — task result

**Final verdict: OK** (14 witnesses, 12 names, composes nothing).

## Gate runs
1. `OK` — the first run, on the rule and witnesses as written below. Nothing was changed afterwards.

## The rule
- Class of x: `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- Applicability is a conjunction of four parts:
  - x is halted (`drv_motion_halted x [p.speed_resolution]`).
  - There is a highway h with a roadway r on it (`st_on_way r h`) that x occupies (`rel_occupies x r`). This covers g1 and g5.
  - The district assumption does not hold: `not asm.within_business_or_residence_district`.
  - x is not disabled: `not (not kin_engine_running x ∧ sig_hazard x)`. This is g13.
- Obligation: the obligation first re-selects h the same way the applicability does (rule 3c). It then requires a lane L with all of these properties:
  - L is on h (`st_on_way L h`).
  - x does not occupy L.
  - `st_region_geometry_distance x L ≤ p.opposite_lane_reach`.
  - `st_lane_width L ≥ p.free_passage_width`.
  - No other user y that is halted and has `rel_longitudinal_overlap x y > 0` occupies L.

## Choices the node left open
- g13's "while on the paved or main-traveled portion" is not written as a separate `rel_occupies` leaf. The applicability already requires x to occupy a roadway (g5), so a second leaf would add nothing. The g13 atoms `rel.occupies` and `st.roadway` are still used.
- g1's "upon any highway" is written as "a roadway on a highway h" (`st_on_way`), following the record's applicability. There is no separate `rel_occupies x h`.
- If x stands on several highways, the obligation is met by any one of them that x occupies a roadway of (an existential over h, as the record's "a st.highway h" reads).
- I declared no narrowings of my own. The record's g8 narrowing is the plan's and is not restated.

## Witnesses
- The planned scenes are forbid, permit, idle, blind (with `st.lane_width` masked) and branch_1 (engine off with hazards on, so not applicable).
- I added these branch scenes:
  - branch_2: inside a district → not applicable.
  - branch_3: x on the shoulder → not applicable.
  - branch_4: the other lane is 2 m wide → violated.
  - branch_5: the other lane is 2.1 m from x's body, beyond the reach → violated.
  - branch_6: the other vehicle drives past alongside without halting → compliant.
  - branch_7: the other vehicle is halted 30 m ahead, not alongside → compliant.
  - branch_8: the free lane belongs to another highway → violated.
  - branch_9: engine off, no hazards → violated.
  - branch_10: hazards on, engine running → violated.

## Note
Before my first gate run I tried to run the gate command with `--help` added. The sandbox denied it and it did not execute. After that I ran only the exact gate command.

## Why I finished
The gate returned OK on the first run.
