# NRS_484B_363_3 — task result

**Final verdict: OK** (16 witnesses, 16 names, composes nothing). Gate runs used: 2 of 6.

## Gate runs

1. **WITNESS_FAIL.** All 16 traces were rejected as traces "the adapter cannot produce". The car's yaw rate (20 deg/s over k 20–28) turned it, but its heading vector stayed fixed. 
   **Change:** I rebuilt the U-turn with exact rational headings: east → (4/5, 3/5) → north → (−4/5, 3/5) → west over k 20–23. The yaw rates are 36.870, 53.130, 53.130 and 36.870 deg/s (180° in total), each applied over the second before its scene, and positions follow a 1 m/s speed. I moved the LA/LB boundary to x = 5 so the car is in LA up to the turn, and moved the "halfway" switch points to k = 22.
2. **OK.**

## How the rule is written

- **Class (u1):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** `rises (drv_motion_u_turn x window min max)` ∧ the u3 span read at some moment, i.e. `not (holdsFor W x (not (U ∧ Z)))`.
  - `U` = `drv_motion_turning x p.yaw_rate_tolerance`.
  - `Z` = some `zone_sign` z of kind `school` or `school_crossing` governs a `travel_region` r that x occupies.
- **Obligation:** five disjuncts, each read throughout as `holdsFor W x (U → E)`, so the same exception must hold at every observation of the U-turn:
  - **(a)** For every school / school-crossing zone sign governing a travel region r that x occupies, and every `highway` h with `st_on_way r h`, no user with `ru_child` occupies h.
  - **(b)** `asm.school_not_in_session`.
  - **(c)** `asm.school_out_of_operation_period`.
  - **(d)** Some `speed_limit_beacon` b that is not `dev_inoperative` governs a travel region x occupies, b is not flashing, and `asm.pupils_in_class` holds.
  - **(e)** No such operational beacon governs a travel region x occupies, and for every school / school-crossing zone sign governing a travel region x occupies, `prim_conditions_hold z x` is false.

## Choices the node left open

- **Which zone sign z (a) and (e) refer to.** The record names "the" zone sign z from the applicability, but the applicability and obligation are separate formulas. Following rule 3c, I wrote the applicability's whole selection again in the obligation, using a universal quantifier: every school / school-crossing zone sign governing a region x occupies at that observation is held to the exception. At observations where x is in no zone region, (a) and (e)'s sign condition hold vacuously. This makes no difference for a U-turn inside a single zone. I declared no narrowing, because the gate forbids narrowings on exception spans.
- **Which users count as children in (a).** The child quantifier ranges over every road user of the scene, x included. x carries no child class, so it never decides (a) except where `ru.child` is masked, which is the blind case.

## Witnesses

All 16 witnesses share one layout:
- **Road:** a highway with lanes LA/LB (eastbound), LC/LD (westbound) and a sidewalk.
- **Car:** drives east in LA up to k = 19, makes the U-turn over k 20–23 (k 20–21 in LB, k 22–23 in LC), recognized at k = 23.
- **Child:** either on the sidewalk or off the highway.
- **Zone sign:** legend "weekdays 07:00–09:00", on Tuesday 2026-11-10.
- **Beacon:** an optional speed limit beacon, always operational.
- **Window:** each witness judges k 16–44 (`window := (16000, 44000)`), so every 15 s look-back is covered.

I added no `branch_<n>` witnesses; the gate found every leaf exercised by the planned 16.

## Why I finished

The gate returned **OK** on the second run.
