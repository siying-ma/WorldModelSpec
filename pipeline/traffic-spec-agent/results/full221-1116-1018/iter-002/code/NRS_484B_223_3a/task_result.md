# NRS_484B_223_3a — task result

**Final verdict: OK** (7 witnesses, 9 names, composes nothing)

## Gate runs
1. `UNANCHORED_VARIABLE` — the intersection / driveway-entrance variables of the "from" limb were
   bound only by the declared intention `int.left_turn`, which does not anchor. Fixed by tying the
   target region to the highway g on which the occupied centre turn lane c lies (`st_on_way c g`,
   `st_on_way i g` / `st_on_way e g`), using s6's claimed `st.on_way`; the witness's driveway and
   intersection regions were given `ways := [10]`.
2. `WITNESS_FAIL` — branch_1/branch_3: the headings did not follow the integrated yaw rate (the
   adapter check). Fixed by headings of 120°, 150° and 175° matching the 30/30/25 deg/s yaw
   rates, positions after the turn following the 175° heading, and traces cut to 22 s so the
   subject stays inside c.
3. `OK`.

## Rule as written
- Class: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- Applicability (s1): `ru_aggregate subject DEF-NRS-484A-285::traffic ∧ ∃ centre_turn_lane c, rel_occupies subject c`.
- Obligation (s4 with s5/s6): `∀ centre_turn_lane c, occupies c → (FROM ∨ ONTO)` where
  - FROM: `∃ highway g, on_way(c,g) ∧ (∃ intersection i, on_way(i,g) ∧ intent int.left_turn subject i ∨ ∃ driveway_or_alley_entrance e, on_way(e,g) ∧ intent int.left_turn subject e)`, read at the judged observation;
  - ONTO: `since (occupies c) (drv_motion_left_turn(subject; p.vehicle_turn_window, p.turn_heading_min, p.u_turn_heading_min, p.turn_yaw_rate_tol) ∧ occupies c ∧ ∃ highway h, on_way(c,h) ∧ ¬ holdsFor[time, p.vehicle_turn_window] (occupies h))`.

## Choices the node left open
- The traffic aggregate of s1 (`DEF-NRS-484A-285::traffic`) has no road user of its own in the
  record; it is carried on the subject in the applicability (every vehicle class is included in
  it, so it narrows nothing).
- "The highway h on which c lies" is written existentially over the highway regions c lies on.
- "From the highway": the record says only "some intersection or driveway/alley entrance region".
  The gate requires that region to be tied to the subject; I tied it through the span's own words
  "the highway" (the highway on which c lies), with s6's claimed `st.on_way`. No narrowing is
  declared. A planner should check that this is the intended reading: a declared left turn at an
  intersection or entrance on a *different* highway no longer excuses the presence.

## Witnesses
forbid (violated), permit (compliant, intent true at a driveway entrance 40 m ahead), idle (no
centre turn lane), blind (middle lane of unobserved kind `centre_turn_lane`, atom masked),
branch_1 (compliant, 85° left turn from off the highway into c), plus my own branch_2 (compliant,
intent at an intersection: the intersection limb of FROM) and branch_3 (violated, the same 85°
turn made from the highway's own shoulder area, so the off-highway leaf decides).

## Why I finished
The gate returned OK.
