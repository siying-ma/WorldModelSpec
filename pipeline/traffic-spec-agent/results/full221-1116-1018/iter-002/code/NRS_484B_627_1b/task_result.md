# NRS_484B_627_1b — task result

**Final verdict: OK** (9 witnesses, 18 names, composes nothing)

## Gate runs
1. **VACUOUS**: applicability leaf 9, the `rel_surface_gap(subject, o) ≤ p.rear_signal_reach` bound in the "no road user ahead in the lane" clause, did not change the outcome of any witness. Fix: added `branch_5` (violated), where a car is 100 m ahead of the subject in the same lane, beyond the reach. The rule did not change.
2. **OK**.

## How the rule is written
- **Class (u1/u5)**: `ru_aggregate subject DEF-NRS-484A-130::motor_vehicle`.
- **Applicability**: two parts.
  - **u2 + u3 + u4**: `holdsFor .time p.left_lane_move_over_time` over four conditions, all of which must hold:
    - the subject's speed is above `p.halt_speed_tolerance`;
    - some `speed_limit_sign` of kind `maximum` governs a `travel_region` the subject occupies, with speed + `p.impeding_speed_margin` below the sign's value;
    - some road user of DEF-NRS-484A-285::traffic has the subject ahead of it in the same lane, at a surface gap of at most `p.rear_signal_reach`;
    - no road user is ahead of the subject in the same lane within `p.rear_signal_reach`.
  - **v6**: at the judged instant, the subject occupies a lane that lies on a `highway` (`st_on_way`) and whose `st_lane_adjacency_count` is at least the literal 2.
- **Obligation**: (v7) or (v8 + v9).
  - **v7**: two conditions, both required:
    - some lane meets the applicability's full lane selection and has ordinal equal to count;
    - every lane the subject occupies has ordinal equal to count ("no other lane of that direction").
  - **v8 + v9**: some road user of DEF-NRS-484A-320::vehicle meets all of these:
    - it moves above `p.halt_speed_tolerance`;
    - it is slower than the subject, which also excludes the subject itself;
    - it is on the subject's right (`rel_bearing … "right"`);
    - either its longitudinal overlap is ≥ 0, or it is ahead (`rel_bearing … "ahead"`) at a surface gap ≤ (speed difference) × `p.overtake_window`.

## Choices the node left open
- The exception (v9) is placed in the obligation as an alternative, not in the applicability. This follows the node's `obligation` text and makes the planned `branch_1` come out compliant.
- "No other lane of that direction" is written as: every lane the subject occupies is the rightmost of its own direction.
- The literal "two" is written as `.lit (Units.ratio 2 1) .count`, because Units has no count constructor.
- No narrowings were declared.

## Witnesses
All witnesses use one 0–14 s trace sampled every 1 s, and each is judged at 12–14 s (`window`). The scenes are a three-lane eastbound highway under a 30 m/s maximum sign, with a slow subject and a follower 12 m behind it.
- `forbid`: violated.
- `permit`: compliant.
- `idle`: not applicable (subject at 29 m/s).
- `blind`: unknown (`st.lane_adjacency` masked).
- `branch_1`: compliant (truck side by side on the right).
- `branch_2`: violated (truck about 200 m ahead).
- `branch_3`: compliant (truck about 30 m ahead, within 60 m).
- `branch_4`: violated (subject straddles lanes 2 and 3).
- `branch_5`: violated (car ahead beyond the reach).

## Why I finished
The gate returned OK on the second run.
