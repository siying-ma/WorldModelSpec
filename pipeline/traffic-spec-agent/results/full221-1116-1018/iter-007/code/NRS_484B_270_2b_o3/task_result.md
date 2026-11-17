# NRS_484B_270_2b_o3 — task result

## Final verdict: OK

`OK — 9 witnesses, 15 names, composes nothing`

## Gate runs
1. **OK** — first run, with the rule and nine witnesses written (forbid, permit, idle, blind,
   branch_1, branch_2, plus branch_3/4/5 for the wet, precipitation and ice headways).
2. **OK** — re-run after adding the per-span reading to the rule's header comment. Only the comment changed.

## How the node is written
- Class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: `existsUser r` with r's whole selection:
  - r is not the subject.
  - r is a member of one of the three aggregates.
  - r is moving: `kin_speed > p.halt_speed_tolerance`.
  - `rel_same_direction` (`p.overtake_same_direction_cos`).
  - At some point in the `p.overtake_window` behind, r was ahead with headings aligned. Ahead means `rel_bearing "ahead"` and the longitudinal overlap is below zero.
  - r is not yet behind, or `drv.interaction.overtake_pass` held somewhere in that window.
  - r is on the subject's right: `rel_bearing "right"`.
  - Some lane r occupies has `st_lane_adjacency "count" = 1`.
- Obligation: for every r with the same selection, unless the subject is safely clear, there is no lane r occupies for which `drv.lane.heading_right_of_carrier(subject, L)` holds.
  - Safely clear means r is behind, and `rel_surface_gap` is at least `kin_speed(r)` times the headway.
  - The headway is chosen with `Term.cond`: ice, otherwise wet road or precipitation, otherwise dry.

## Choices the node left open
- **"Has risen" for overtake_pass.** The concept holds only at the observation where the pass is recognised. So I wrote "risen at some observation of the window" as "held at some observation of the window", using `not (holdsFor W (not pass))`.
- **The count literal 1.** Units has no count constructor, so I wrote it as `.lit (Units.ratio 1 1) .count`. The gate accepted it.
- **The b11 `unless` compositions** (NRS_484B_213_1/2a/2b/2c, 217_2) are not written; the gate reports "composes nothing".
  - They are scoped to b12, but the node carries b12 only as a residue: the authorisation relaxes those other rules and leaves this duty unchanged.
  - With no b12 formula in this rule, there is nothing to conjoin `.not (.ruleApplies …)` into. Adding them anywhere else would change the applicability, which rule 6 forbids.
  - The planner may want to drop these compositions or re-point them, since they currently scope a span that is carried only as a residue.
- No narrowings of my own. Every reading above is the record's applicability/obligation text, and the record's own narrowings on b4, b9 and b10 are not restated.

## Why I finished
The gate returned OK, and OK again after the comment-only edit. I used 2 of the 6 runs.
