# NRS_484B_307_9b_o2 — task result

**Final verdict: OK** (11 witnesses, 13 names, composes nothing). 4 of 6 gate runs used.

## Gate runs
1. **WITNESS_FAIL** on `idle`, `branch_3` and `branch_4`: the trace admission rejected the turning
   traces, because the yaw rate was set but the heading vector stayed east. Fix: the heading now
   turns 15° per scene from the entry to the exit, following the yaw rate (±300 deg/s, held over
   the interval before each scene). The unit vectors are written to four decimals.
2. **VACUOUS**: obligation leaf `drv_motion_left_turn_through_region`. Only the compliant `branch_3`
   turned left under a right arrow, so this leaf could not change any verdict. Fix: added
   `branch_7` (violated: one right-arrow display, then a left turn).
3. **OK**.

## How the rule is written
- **Class (b2–b4):** a disjunction of the five admitted aggregates (`ru_aggregate` with the
  aggregate id) and `ru_motorcycle`.
- **Applicability (b1, b5, b6):** there exist an intersection i, a traffic signal s and a travel region c such that:
  - at the judged observation, x leaves i by a straight crossing, or by the turn opposite the arrow
    (a right turn under green_arrow(left), a left turn under green_arrow(right));
  - at x's entry into i, s shows circular_red and green_arrow(dir). The entry is the latest rise of
    `rel_occupies(x, i)`, written `since (¬rises occ) (rises occ ∧ …)`;
  - at the observation before the entry, x occupies c, `st_lane_enters(c, i)` holds, and s governs c or governs i.
    This is written `since (rises occ) (¬occ ∧ …)`, read at the entry.
- **Obligation (b8):** for every i, s and c, and for each direction, the selection implies the duty.
  - The duty is read at the observation before the entry.
  - H = stopped(x) ∧ occupies(x, c) ∧ ¬occupies(x, i). The wait runs from the latest rise of H to
    that observation. Through it, x is not in i, s shows no circular_green, and H does not rise again.
  - Within the wait, a chain of nested `since` must hold in order: the arrow lights, goes out,
    lights, goes out. Each cycle therefore lights and goes out inside the wait, as the record's own
    narrowing says. This is what makes `branch_2` violated.
  - No numeric threshold is written.
  - A wait whose start is not recorded leaves the chain unknown, through `since`'s unobserved past.
- **b9:** the record's residue, unchanged.

## Choices the node left open
- **The approach carrier when the signal governs the intersection.** The record says "the approach
  carrier c … (dev.governs(s, c) with st.lane_enters(c, i), or dev.governs(s, i))". I read c as
  always an approach carrier, so `st_lane_enters(c, i)` is required in both governance cases. This
  follows the record's term "approach carrier" and the `st.lane_enters` contract, so I declared no
  narrowing.
- **Direction.** dir is written as two explicit cases, left and right.
- **Narrowings.** I declared none of my own; `narrowings` stays empty.

## Witnesses
All witnesses share one layout:
- Scenes every 50 ms, the acquisition step, so `headingSince` is defined.
- An approach lane 10 that enters intersection 20, and a signal 100.
- The window starts at the second scene.

Planned witnesses, as narrated: forbid, permit, idle, blind, branch_1, branch_2.

Added branches:
- `branch_3` (compliant): right arrow, two cycles, left turn.
- `branch_4` (violated): left arrow, one cycle, right turn.
- `branch_5` (violated): the signal governs the intersection itself.
- `branch_6` (not applicable): circular_green with the arrow at the entry, not steady red.
- `branch_7` (violated): right arrow, one cycle, left turn.

## Why I finished
The gate returned OK.
