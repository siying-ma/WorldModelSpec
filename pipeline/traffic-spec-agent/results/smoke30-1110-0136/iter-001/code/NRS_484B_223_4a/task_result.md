# NRS_484B_223_4a — task result

## Final verdict
**OK** (7 witnesses, 11 names, composes nothing).

## Gate runs
1. **VACUOUS**: obligation leaf 5, `st_turn_lane_side [M, right]`. This is the obligation's copy of
   "the left neighbour is not a right turn lane". No witness reached it, because branch_2 is
   decided as not applicable before the obligation is evaluated. I did not change the rule. I
   added the witness `branch_3` (violated): the right turn lane's left neighbour is a *left* turn
   lane, so the lane is still the single right turn lane, and the car in it has `int.turn_right`
   declared false.
2. **OK**.

(Before run 1 I mistakenly issued a second, compound shell command (the gate command with
`--help`). The permission layer denied it and nothing ran. No gate run was charged for it.)

## How the rule is written
- **Class (s2):** `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s1):** there is a highway `h` that x occupies, and a `turn_lane` `L` that is
  `singleRightTurnLane h L`. That means: the side is right, `st_on_way(L, h)`,
  `st_lane_adjacency_ordinal L = st_lane_adjacency_count L`, and there is no `turn_lane` `M` with
  `st_lane_adjacency(L, left, M)` whose side is right.
- **Obligation (s3/s4):** for every highway `h` that x occupies, and every `turn_lane` `L` with
  the same whole selection (`singleRightTurnLane h L`) that x also occupies, the formula is
  `definedWhen (∃ intersection i: st_lane_enters(L, i)) (∃ intersection i: st_lane_enters(L, i) ∧ intent(int.turn_right, x, i))`.
  The intention is read at the judged observation. If no entrance is recorded, the verdict is
  unknown, as the record states.

## Choices the node left open
- **Spelling of the adjacency atom.** I used the `st_lane_adjacency_ordinal` and
  `st_lane_adjacency_count` measures, and the Boolean atom `st_lane_adjacency [L, "left", M]`.
  All of them are accessors of the claimed `st.lane_adjacency`.
- **Narrowings.** None declared. Every choice above is the record's own selection.

## Witnesses
| Witness | Expected | Scene |
|---|---|---|
| forbid | violated | The car is in single right turn lane 102; turn-right intention declared false at intersection 200. |
| permit | compliant | As forbid, with the intention declared true. |
| idle | not applicable | Two through lanes; no turn lane. |
| blind | unknown | `rel.occupies` masked. |
| branch_1 | compliant | The car is in through lane 101 beside the turn lane; no intention declared. |
| branch_2 | not applicable | Two adjacent right turn lanes; the car is in the rightmost one with the intention declared false. |
| branch_3 | violated | Added by me: the left neighbour is a left turn lane, so the lane is still single. Exercises the obligation's neighbour-side leaf. |

## Why I finished
The gate returned OK on the second run (2 of 6 runs used).
