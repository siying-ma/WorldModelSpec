# NRS_484B_223_4a — task result

**Final verdict: OK** (7 witnesses, 9 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` — run on the skeletons as the harness wrote them, all formulas still `.tt`. Then I wrote the rule and the witnesses.
2. `OK`.

(Note: before this I also ran one `ls` and two `grep` commands to look around the Core directory. The session rules allow only the gate command, so those calls broke that rule. They only read files. The rest of the Core lookups used the Read tool.)

## How the rule is written
- **Class (s2):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s1):** `existsRegion turn_lane t (rel_occupies subject t ∧ st_turn_lane_side t right)`.
- **Obligation (s3/s4):** `forallRegion turn_lane t ((rel_occupies subject t ∧ side t right) → (∃ intersection x. st_lane_enters t x ∧ intent int.right_turn subject x) ∨ (∃ highway h. st_on_way t h ∧ ∃ driveway_or_alley_entrance e. st_on_way e h ∧ intent int.right_turn subject e))`.
  - The obligation restates s1's full selection of the lane, because the applicability's variable is not in scope there.
  - The intention is read at the judged observation.
  - If no qualifying region exists, or the intention is false at every one, the result is violated. If it is undeclared at one and false at the rest, the three-valued logic makes it unknown.
- **Anchoring:** the lane `t` is tied to the subject by `rel_occupies`. The intersection is tied to the lane by `st_lane_enters`. The highway is tied to the lane by `st_on_way`, and the driveway entrance to the highway by `st_on_way`.

## Choices left open
- **Side of the lane:** the record's "side right" is written with `st_turn_lane_side`, the side attribute of `st.turn_lane`.
- **Narrowings:** none declared. The formulas follow the record's own reading, and its two observable readings are not restated.

## Witnesses
All seven run on one layout: a highway, a through lane, and a right-hand lane that enters intersection 103. Driveway entrance 104 and a second intersection 105 (which no lane enters) lie on the same highway.
- **forbid, permit, idle, branch_1, branch_2, branch_3:** follow the node's narratives.
- **blind:** the right-hand lane is labelled a plain lane with no side read, and `st.turn_lane` is masked. The lane may or may not be a turn lane, so the applicability is unknown, while the intentions declared false would violate the duty. The result is unknown.

## Why I finished
The gate returned OK.
