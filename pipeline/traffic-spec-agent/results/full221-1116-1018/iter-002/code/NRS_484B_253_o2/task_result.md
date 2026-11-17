# NRS_484B_253_o2 — task result

## Final verdict
**OK** (`7 witnesses, 12 names, composes NRS_484B_253_o1`)

## Gate runs
1. **OK**. This was the first run, made after both files were written. Nothing changed after it.

## How the rule is written
- **Class (l):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** ∃ intersection X, ∃ travel_region c2:
  - **m:** the subject occupies c2, `st_lane_enters c2 X` holds, and the subject does not occupy X.
  - Then ∃ user t with:
    - **a, p:** `¬ same t subject` and t is of the vehicle aggregate.
    - **b:** t occupies X.
    - **c:** `intent int.left_turn t X`.
    - ∃ travel_region c1 with:
      - **Entry:** `since (occ t X) (occ t c1 ∧ ¬occ t X)`.
      - `st_lane_enters c1 X` holds.
      - **m:** c1 and c2 are opposed: the dot product of their `st_lane_direction` (x, y) components is below −p.oncoming_heading_cos.
      - **j:** `since (¬ rises (occ t c1)) (indicator left ∨ hand signal left)`.
    - **k, i:** `since (moving t ∧ occ t X) (rises (moving t ∧ occ t X) ∧ rule NRS_484B_253_o1 {subject ↦ t})`. "Moving" means kin.speed > p.halt_speed_tolerance.
- **Obligation (n, o):** ∀ X, ∀ c2, ∀ t: (the whole selection above) → (¬ rel_contact(subject, t) ∧ ¬(subject moving ∧ prim_closest_approach_within(subject, t; p.conflict_horizon) ∧ prim_closest_approach_distance(subject, t; p.conflict_horizon) < p.conflict_centre_clearance)).

## Choices the node left open
- **"Since it came onto c1" (j):** written as a left signal at some observation with no later rise of t's occupancy of c1. That is the literal reading of the record, so I declared no narrowing.
- **Onset of the current movement (k):** the latest rise of "moving ∧ occupies X". This rises both when t enters X already moving and when t starts moving while inside X. It is the record's "later of" rule, written as one edge.
- **Witnesses:** I added `branch_3` (violated): the forbid scene with only an arm signal, so that the `sig_hand_signal` limb of the disjunction is tested.

## Caveat
I could not read NRS_484B_253_o1. The `branch_1` witness (t did not yield under o1 at its onset) depends on o1 being decided violated in that scene. In that scene, at t's onset, the subject is on c2, 20 m away, with a closest approach 1.6 s ahead at a 2 m centre distance. The gate accepted it, so o1 is decided as the record intends there.

## Why I finished
The gate returned OK on the first run. Every planned scenario is built with its planned verdict, plus `branch_3`. The node needed no changes.
