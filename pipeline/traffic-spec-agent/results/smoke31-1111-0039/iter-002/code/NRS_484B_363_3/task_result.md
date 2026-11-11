# NRS_484B_363_3 — task result

**Final verdict: OK** (18 witnesses, 15 names, composes nothing).

## Gate runs (3 of 6 used)

1. `UNUSED_CLAIM` — run by mistake on the untouched skeleton, which listed every claimed name as unused. Then I wrote the rule and the witnesses.
2. `WITNESS_FAIL` — the adapter rejected every trace. The scenes held x's heading fixed while a 45 deg/s yaw rate was turning it, and Core holds the rate at a scene over the interval before it. I changed the turn to 90 deg/s at k = 23 and 24, with the heading east up to 22, north at 23 and west from 24, and moved every scenario's "first part / rest / before the act" split to match.
3. `OK`.

## How the rule is written

- **Class of x:** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Act (d2):** `drv_motion_u_turn x` with `p.u_turn_window` and `p.u_turn_reversal_tolerance`. It is judged once, where it rises.
- **Under-way formula U:** `drv_motion_yawing x` with `p.yaw_rate_resolution`.
- **Window forms:** `some_moment` is `¬holdsFor W x ¬(U ∧ φ)` and `throughout` is `holdsFor W x (U → φ)`, with W = `p.u_turn_window`.
- **Selecting the zone sign (d3):** a zone sign z of kind school or school_crossing, not an end sign, governing a travel region that x occupies at some moment of the act.
- **Applicability:** the U-turn rises, and some zone sign z is selected as above.
- **Obligation:** for every zone sign z selected the same way, one of the alternatives (a)–(e) must hold throughout the act. Each alternative is its own `throughout`, because the record requires one exception to cover the whole act.
  - **(a)** No `ru_child` is within `p.child_presence_reach` (measured with `st_region_geometry_distance`) of a travel region z governs.
  - **(b)** `asm.school_not_in_session_day`.
  - **(c)** `asm.outside_school_operation_margin`.
  - **(d)** Some speed-limit beacon governs a travel region that x occupies or z governs, `asm.pupils_in_class` holds, and that same beacon is not flashing.
  - **(e)** No such beacon exists, and `prim_conditions_hold z x` is false.

## Choices the node left open

- **No narrowings.** Everything is written as the record states it.
- **"Within" the presence reach** is written as `≤`. The witnesses keep a clear margin either way (1.8 m and 31.8 m against 5 m), so `<` would give the same verdicts.
- **Wording in `occasion_d13`.** Its narrative says civil time "leaves" z's posted window, but also says z's conditions "do not hold for the first part of the act and hold for the rest". I built it to match the second statement: the time enters the 07:00–08:00 window during the act.
- **Extra witness `branch_2` (compliant).** It sets `asm.outside_school_operation_margin` true so that exception (c) has a scene of its own.

## Why I finished

The gate returned OK.
