# NRS_484B_253_o2 — task result

**Final verdict: OK** (7 witnesses, 12 names, composes NRS_484B_253_o1)

## Gate runs (6 of 6 used)

1. **UNUSED_CLAIM**: run by mistake on the untouched skeleton, which still had every formula as `.tt`. Nothing changed.
2. *(wasted run)*: I made a mistake and ran the gate command inside a compound shell command (piped into a `grep` that read a Core file). The gate ran and used up a run; I did not read its output. Nothing changed.
3. **BUILD_FAIL**: unbalanced parentheses in `turner`. I split it into `enteredFrom`, `signalledOn` and `approachOfTurner`.
4. **WITNESS_FAIL**: the harness rejects traces an adapter could not produce. A yaw rate of 15 deg/s with the heading unchanged, the speed and yaw rate at a scene being held over the interval before it. I rebuilt every trace so positions and headings integrate exactly:
   - 1 s steps, constant speeds between stops;
   - turns are exact quarter turns at 90 deg/s, not the narrative's 15 deg/s, which no rational heading can match exactly;
   - no padding, since repeating a moving scene would break position integration.
5. **VACUOUS**: the `sig_hand_signal` leaf in the obligation was never exercised. I added witness `branch_3` (violated): forbid with y's indicator off and an arm signal for left.
6. **OK**.

## How the rule is written

- **x's class:** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability:**
  - there is an intersection `i`;
  - there is a travel region `cx` that x occupies, with `cx ≠ i` and `st_lane_enters cx i`;
  - there is a road user `y` (`turner`) such that:
    - y is not x and is a vehicle;
    - y occupies `i`;
    - `intent int.turn_left y i` holds;
    - `drv_motion_turning_left y` holds;
    - y has an approach carrier `cy` (a travel region with `cy ≠ i` and `st_lane_enters cy i`) where:
      - the dot product of the `st_lane_direction` of `cx` and `cy` is below −`p.opposed_approach_cos_tolerance`;
      - `since (occ y i ∧ o1(y)) (rises (occ y i) ∧ occ y cy ∧ o1(y))`, i.e. compliance with NRS_484B_253_o1 at every observation from the onset of y's current occupancy of i, during which it occupied cy;
      - `since (¬rises (occ y cy)) (leftSignal y ∧ once (rises (occ y cy)))`, i.e. a left indicator or arm signal at some observation since y last came onto cy.
- **Obligation:**
  - for every `i` and `cx` selected as in the applicability, where x occupies `cx` and `i` and `drv_motion_moving x` holds;
  - every `y` meeting the whole `turner` selection again has no conflict with x;
  - a conflict is `prim_closest_approach_within x y h` with `prim_closest_approach_distance x y h` below `p.conflict_centre_clearance`.

## Choices the node left open

- **`cx ≠ i` / `cy ≠ i`** (`same`). The intersection is itself a travel region. It has no lane record, so `st_lane_enters i i` is unknown rather than false, and this unknown leaked into the unknown reasons. The contract says a carrier is an approach *to* an intersection, so the intersection is never its own carrier. This states what the contract already implies; it is not declared as a narrowing.
- **"At every observation since its current occupancy of i began"** includes the onset observation and the judged one.
- **"Since it last came onto cy"** is read from the latest rising edge of `rel_occupies y cy`, onset included. "Once" is written `since tt`.
- **No narrowings declared:** every span I wrote was carried as the record maps it.

## Notes for the plan

- **o1 and o2 overlap only when y is standing.** At the instant o2 is violated, y and x are in predicted conflict. If y were moving then, it would presumably break NRS_484B_253_o1, and o2 would not apply. So the forbid witness has y stop and turn *standing* (yaw rate 90 deg/s at 0 m/s). The forbid narrative ("yielded … and is now turning left" while x is in conflict) only holds in that case. This is a property of the node's reading, not a defect I could fix; a later session may want to look at it.
- **Unreadable composed rule.** I could not read NRS_484B_253_o1. The witnesses' results for it (compliant while y yields, violated in branch_2) are what the gate computed, and all of them passed.

## Why I finished

The gate returned OK on the sixth and last run.
