# NRS_484B_210_3 — task result

**Final verdict: OK** (9 witnesses, 12 names, composes nothing).

## Gate runs (2 of 6 used)
1. `UNUSED_CLAIM` (drv_interaction_overtake_pass_on_right, kin_velocity, rel_bearing,
   rel_longitudinal_overlap, …) — run by mistake on the untouched skeleton (formulas still `.tt`),
   before anything was written. The command was also piped through `head`, which breaks the
   "run exactly this command" instruction; this did not change what the gate judged. After it, the
   rule and the witnesses were written.
2. `OK`.

## Rule
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: `existsUser b (ru_aggregate b vehicle ∧ ¬same subject b ∧ drv_interaction_overtake_pass_on_right(subject, b; p.overtake_window, p.overtake_same_direction_cos))`.
- Obligation: `forallUser b (passOnRight(b) → ¬ s3SomeMoment(b))`, with
  `s3SomeMoment = ¬ holdsFor time p.overtake_window subject ¬(U ∧ offPaved)`. This is the
  occasion's prescribed `some_moment` form for `boundary: "window"`. The duty is its negation:
  at no observation of the act is the subject off the pavement.
- offPaved: `existsRegion shoulder r (rel_occupies subject r ∧ ¬st_shoulder_paved r) ∨ existsRegion road_edge e (rel_occupies subject e ∧ ¬st_road_edge_paved e)`.
- U (under_way): `untilWithin time p.overtake_window subject (¬aheadAligned) passOnRight(b) ∧ subjectFaster`.
  - `aheadAligned` is `rel_bearing ahead ∧ rel_longitudinal_overlap < 0 ∧ rel_same_direction(cos)`.
  - `subjectFaster` is `v_s·v_s > v_b·v_s`, written with `kin_velocity` x/y components.

## Choices the node left open
- **Inside the act.** An observation counts as inside the act when, from it, b is never again
  ahead of the subject with aligned headings before the pass is recognized within the window
  ahead (`untilWithin`). This is exactly "after the last ahead-aligned observation and at or
  before the recognition".
  - I first considered a `since (¬A) A` form and dropped it: it can never be decided false
    (its two operands are complementary), and it would make the trace start unknown.
- **"Velocity exceeding b's along its heading".** I compared the two velocities along the
  subject's own velocity direction, not its heading. The node claims no `kin.heading`, and a
  divisor may not read a measured atom, so this keeps the comparison free of both. For a vehicle
  moving forward the two directions are the same.
- **No narrowings declared.** Both choices above are written in the rule's header.

## Witnesses
- **Geometry:** an eastbound two-lane carriageway, with an unpaved or paved shoulder or a
  road-edge strip on the right. b holds the left lane at 10 m/s; the subject drives at 20 m/s.
- **Timing:** the pass is recognized at t = 33 s. Each trace is padded so that every 10 s window
  is covered, and `window` is set to 20–35 s.
- **Planned scenarios:** forbid, permit, idle, blind (`rel.occupies` masked), occasion_s3 and
  occasion_s3_outside (shoulder used only while b was still ahead).
- **Added branches:**
  - `branch_1`: the subject is over a road edge with an unpaved surface beyond — violated.
  - `branch_2`: the subject is on a paved shoulder — compliant.
  - `branch_3`: the subject is over a road edge with a paved surface beyond — compliant.

## Why I finished
The gate returned OK. No defect found in the node or in the concepts it calls.
