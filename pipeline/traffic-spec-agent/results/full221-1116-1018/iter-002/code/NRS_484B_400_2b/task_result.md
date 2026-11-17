# NRS_484B_400_2b — task result

**Final verdict: OK** (9 witnesses, 13 names, composes nothing). 5 of 6 gate runs used.

## Gate runs

1. `UNUSED_CLAIM` (all claims). This was the untouched skeleton: an extra run I spent by mistake before writing anything. One more call that tried to pass `--help` was denied and never ran.
2. `UNUSED_CLAIM`, the same output. I re-ran by mistake on the unchanged skeleton, so this run was wasted. After it I wrote the rule and the witnesses.
3. `WITNESS_FAIL`: the adapter-plausibility check said highways 100 and 101 had no boundary. A boundary is required wherever occupancy is observed. **Change:** I gave both highways rectangle boundaries.
4. `WITNESS_FAIL`: the subject kept its heading while its yaw rate said it should be turning. The check holds the rate at a scene over the interval before that scene. **Change:** the turning path is now generated, not hand-written. Each heading is an exact unit vector at the angle the yaw rate implies (built from a half-angle tangent rounded to 10⁻⁶). Each position is the previous one plus velocity × 50 ms, rounded to the micrometre. The trace now has 58 scenes at 50 ms.
5. **OK.**

## How the rule is written

- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** there is an intersection `i` (`existsRegion "intersection"`) such that all three of these hold:
  - **Occasion, s3:** `drv_motion_left_turn_through_region(subject, i; p.heading_since_step_carla_scene_graph, p.turn_heading_min, p.u_turn_heading_min)`. The concept holds only at the exit after the entry, so the judged observation is the act's recognition. s3 and s4 are read there.
  - **s2:** `since (not (rises occ(subject,i))) (intent int.left_turn subject i ∧ U)`.
    - This looks for an observation from this passage's entry up to the judged one at which the intention was declared while the act was under way.
    - The search stops at the entry, so it cannot reach the approach or an earlier passage.
    - `U` is the occasion's under_way element: `occ(subject,i) ∧ headingSince(subject, p.heading_since_step_carla_scene_graph, occ(subject,i)) ≥ 0°`.
  - **s4:** every highway `h` with `st_on_way i h` is two-directional:
    - no `median_or_divider` lies on `h`; and
    - one of three unordered pairs of carriers lying on `h` (lane–lane, lane–roadway, roadway–roadway) has a dot product of normalised `st_lane_direction` ≤ −`p.lane_opposed_direction_cos`.
- **Obligation (s5):** for every lane `l` with `rel_occupies subject l`, `not drv_motion_moving_against_carrier(subject, l; p.halt_speed_tolerance)`.

## Choices the node left open

- **How `U` reads `kin.yaw_rate`.** The occasion's under_way element claims `kin.yaw_rate`, and the gate requires every claim to be used.
  - I wrote it as the heading change since the entry, through `headingSince` with the reviewed step parameter. The comparison is "≥ 0°": the subject is not turning right. That is my reading of "moving through it and turning".
  - The record states no sign or bound here, so this is a choice I made. It is in the rule's header but not in `narrowings`, because the occasion is not a duty or standard span.
- **The window of the intention.** I used `since`, with "no new entry into i" as the condition that must keep holding. This makes the act stretch run from the declared onset (the entry) to the recognition.
- **Lane or roadway pairs in s4.** I wrote them unordered (lane–lane, lane–roadway, roadway–roadway), because the dot product is symmetric. With an ordered roadway–lane copy, some leaves would always be redundant, so no witness could move them.
- **Obligation.** It names no intersection. The lanes it reads are the ones the subject overlaps at the judged observation, which is the exit. This follows the record's obligation text.
- **No narrowings declared.**

## Witnesses added

- **`branch_4`** (violated): the approach highway is mapped as two opposed roadway segments with no lanes. It exercises the roadway–roadway pair.
- **`branch_5`** (violated): the approach highway has one lane and one opposed roadway segment. It exercises the lane–roadway pair.

## Why I finished

The gate returned OK on run 5. The rule uses exactly the claimed names and parameters, and all planned witnesses (forbid, permit, idle, blind, branch_1–3) reach their planned verdicts, as do the two I added.
