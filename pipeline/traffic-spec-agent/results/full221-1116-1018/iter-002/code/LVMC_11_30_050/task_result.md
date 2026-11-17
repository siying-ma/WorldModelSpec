# LVMC_11_30_050 — task result

**Final verdict: OK** (7 witnesses, 6 names, composes nothing)

## Gate runs
1. OK — first run; no changes after it.

## Rule
- Class: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- Applicability (e2, e4): the subject occupies some `roadway`; occupies no `crosswalk`; and there is a carrier k it occupies and moves across (`drv_motion_moving_across_carrier` with `p.halt_speed_tolerance`, `p.crossing_motion_cos`). k can be a `lane` or a `roadway`, written as two disjoined region quantifiers.
- Obligation (e3): for every `lane` k and every `roadway` k, the e2 selection written out again in full (occupied, moved across within `p.crossing_motion_cos`) implies moving across k within `p.right_angle_crossing_cos`. That makes the duty apply at every selected carrier, as the record says.

## Choices the node left open
- None needed a narrowing. The record lists the carrier kinds as "a lane, st.lane, or a roadway", so I wrote them as quantifiers over the two kinds the record names. The record's own e3 narrowing is not repeated.

## Witnesses
The road runs east–west and the pedestrian walks at 1.4 m/s using exact unit headings. The diagonal heading (3/5, 4/5) is 36.9° off perpendicular, with |cos| = 0.6. The near-square heading (21/221, 220/221) is 5.5° off perpendicular, with |cos| ≈ 0.095.
- forbid (violated) and permit (compliant): a one-way roadway with two eastbound lanes, and the roadway itself has direction east.
- idle (not_applicable): the pedestrian is on the sidewalk.
- blind (unknown): `kin.velocity` is masked.
- branch_1 (not_applicable): the same diagonal crossing as forbid, but inside a marked crosswalk.
- branch_2 (violated, added): an unlaned one-way roadway that has a direction, so the roadway carrier decides.
- branch_3 (violated, added): a two-way roadway with lanes, where the roadway itself has no direction, so the lane carrier decides.

## Why I finished
The gate returned OK on the first run.
