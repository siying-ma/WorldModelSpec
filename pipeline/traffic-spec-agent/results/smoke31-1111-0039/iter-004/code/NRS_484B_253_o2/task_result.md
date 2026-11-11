# NRS_484B_253_o2 — task result

**Final verdict: WITNESS_FAIL (node defect, reported below).** The rule is written exactly as the
record states. The planned `forbid`, and with it `blind`, cannot be built: the record's own
composition (s8) makes them compliant.

## Gate runs (4 of 6 used)

1. **Skeleton, before any edit: UNUSED_CLAIM.** I ran it by mistake while reading Core. Nothing
   else changed.
2. **Rule and witnesses written: WITNESS_FAIL.** forbid, blind, branch_3, branch_4 and branch_5
   came out compliant. permit, idle, branch_1 and branch_2 passed. In every turning scene x was
   in the recording throughout and 60 m (6 s) from i when y began its turn. I suspected that the
   composed NRS_484B_253_o1 was violated by y, so the next scenes bring x into the recording only
   after y's turn has begun.
3. **x appears late: WITNESS_FAIL.** forbid, blind, branch_3 and branch_4 were still compliant.
   **branch_5 became violated as planned.** In branch_5 y turns 60° since entering i and stands
   still before x appears. The four failing scenes had y still turning (slowly, under 45°) at x's
   entry.
4. **y keeps turning: WITNESS_FAIL.** forbid, blind, branch_3, branch_4 and the new branch_6 were
   compliant. In these scenes y turns at 4 m/s and 15 deg/s, reaches a quarter turn by x's entry,
   and x appears late. This shows that y's heading relative to x does not matter: o1 is violated
   whenever y is still moving or turning while x is near or in i.

Why o1 is the cause, by elimination: forbid (run 4) and branch_5 have the same signals, the same
declared intention, the same carriers c and c2, and the same entry of y into i through c2. In both
the "making the turn" disjunct is true, since in forbid the heading change is 90° ≥ 45° besides
the turning. The one remaining conjunct is the `since` that carries
`.rule "NRS_484B_253_o1" [("x","y")]`. It is false in forbid and true in branch_5. The only
difference between the two is that y is still turning while x is near and entering i.

## Node defect — what the plan agent must change

**Spans s8 / s11 and the `forbid` scenario.** The obligation requires that "y has so yielded
(rule NRS_484B_253_o1 {x -> y} complied with at every observation since y's latest entry into i)".
That range includes the judged observation, x's entry into i, and the observations just before it.

NRS_484B_253_o1 (with y as its x) is violated whenever y is turning while an opposing vehicle is
within the intersection or close to it. At x's entry, x is within i and approaching from the
opposite direction by construction. So o1 is violated there whenever y is turning, and o2 can then
never be violated. As a result:

- The planned `forbid` cannot be violated. In it y "now turns left (kin.yaw_rate 15 deg/s, 4 m/s)"
  as x enters. The same holds for `blind`, which is "as forbid".
- The `drv.motion.turning_left` reading of s11 can never decide a verdict. It would also be
  reported VACUOUS once the witnesses passed.
- The only violated case the record admits is y standing still mid-turn, past the turn
  recognition angle, when x arrives (my branch_5). That is the opposite of the narrative.

**Repair:** judge "having so yielded" over y's waiting, not over its turn. That means o1 complied
with at every observation from y's latest entry into i up to the observation at which its turn
began. For example: o1 complied at every observation from the entry up to the latest rise of the
turn, or o1 complied at the onset of the turn. Vehicles that arrive after y has lawfully begun the
turn are the ones the second clause makes yield. Once the composition is limited this way, the
planned forbid (x arrives while y turns) is violated and branch_2 (y began its turn with x 15 m
away at 15 m/s) stays compliant. The repair should state where the onset of the turn is read
(`drv.motion.turning_left` rising, or the heading change since entry), so that the coder does
not choose it.

## How the record is written (choices the node left open)

- **Applicability (s13).** Some `intersection` i and some `travel_region` c, with
  `rel_occupies x c`, `st_lane_enters c i` and `drv_motion_entering_region x i`.
- **Carrier is not i itself.** I added `not (same c i)`. An intersection is never its own
  approach carrier, so this excludes nothing the record selects. Without it, the intersection's
  unrecorded `st_lane_enters` would make the quantifier unknown, and `blind` would carry a stray
  reason. I did the same for c2.
- **Obligation (s14).** It re-states the whole (i, c) selection under `forallRegion` and
  `implies`, then requires that no user y satisfies the following:
  - **Who y is (s1, s15):** `not (same x y)`, and `ru_aggregate y vehicle`.
  - **Opposed carrier (s13):** some carrier c2 with `drv_road_opposed_directions c c2`.
  - **Entry and so-yielded (s2, s8):** `since (occ y i ∧ o1) (entering y i ∧ occ y c2 ∧
    lane_enters c2 i ∧ o1)`. This gives the latest entry, the carrier at that entry, and o1
    complied with at every observation since.
  - **Intention (s3):** `intent int.left_turn y i`, read at the judged observation.
  - **Making the turn (s11):** `turning_left y [p.speed_resolution, p.yaw_rate_resolution]`, or
    the heading change since entry, with step `p.heading_since_step_carla_scene_graph`, at least
    `p.turn_recognition_angle`.
  - **Signal (s9):** `since (occ y c2 ∨ occ y i) (signal ∧ since (occ y c2 ∨ occ y i) (entering
    y c2))`, where the signal is the turn indicator left or the hand signal left.
- **No narrowings declared.**
- **Extra witnesses.** branch_3 (hand signal), branch_4 (signal given only once in i), branch_5
  (heading disjunct) and branch_6 (turning disjunct, with the heading change unknown) were added
  so that each disjunctive leaf can move a witness.

## Why I finished

The gate's failures come from the node, not from the files. The record places the o1 compliance
condition over observations at which, by its own forbid scenario, o1 is necessarily violated. No
witness can satisfy the planned `forbid` or `blind`, and no faithful writing of the record changes
that. I stopped with 2 gate runs unused, rather than build witnesses around the defect or rewrite
the composition. The repair belongs in the plan.
