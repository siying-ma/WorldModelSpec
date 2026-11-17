# NRS_484B_400_1_o2 — task result

**Final verdict: OK** (10 witnesses, 10 names, composes nothing).

## Gate runs

1. Run by mistake, with its output piped away (`| head -0`), before any edit. This was against
   the one-command rule, and the verdict was not seen. I'm reporting it in case it counted
   against the budget.
2. Run by mistake on the untouched skeleton, when I meant to read `World.lean`. Verdict
   `UNUSED_CLAIM`, as expected for the `.tt` placeholders. No change followed from it.
3. After writing the rule and 8 witnesses: `VACUOUS`. The leaf was `st_lane_enters t i` in the
   obligation's restated selection; no violated witness had a right turn lane that did not
   enter the judged intersection. Fix: added `branch_6` (violated). It has a northbound right turn
   lane entering a different intersection 20, and the subject is in lane 1 of 2.
4. `OK`.

## How the rule is written

- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Entry (s3):** an intersection `i` of kind `intersection` with `rises (rel_occupies subject i)`.
- **"At the observation before e":** Core has no previous-observation operator, and `since` is
  non-strict. So X at the observation before the entry is written
  `rises (rel_occupies subject i ∨ ¬X)`. Together with the entry, this equals X at e−1 exactly;
  at e the disjunction is settled by the occupancy. The declared intention is read inside this
  form, never ahead of the judged observation.
- **Approach carrier (s3):** a region of kind `lane` (turn lanes included, by refinement) or
  `roadway`, which the subject occupies and which satisfies `st_lane_enters c i`.
- **No right turn lane (s6/s7):** the carrier has no *single* region of kind `turn_lane` that
  meets all of these:
  - `st_turn_lane_side … right`;
  - it enters `i`;
  - the dot product of its `st_lane_direction` with the carrier's is at least
    `p.approach_lane_same_direction_cos`.

  "Single" is written `∃t (R t ∧ ∀u (R u → same t u))`.
- **Obligation (s8):** the obligation repeats the whole selection of `i`, under `forallRegion`
  (the duty applies at every selected intersection). At e−1 it requires one of:
  - a lane entering `i` that the subject occupies, with `st_lane_adjacency` ordinal equal to
    count;
  - or, if the subject occupies no lane entering `i`, a roadway directed approach segment
    entering `i`.

## Choices the node left open

None beyond the record's own text, so no narrowing is declared. The previous-observation
encoding states exactly what the record states; it is not a narrower reading.

## Witnesses

| witness | expected | what it shows |
|---|---|---|
| forbid | violated | two northbound lanes enter the intersection; the subject is in lane 1 of 2 at the observation before entry |
| permit | compliant | same layout, the subject is in lane 2 of 2 |
| idle | not applicable | same layout; `int.left_turn` is declared and `int.right_turn` is declared false |
| blind | unknown | same as forbid with `st.lane_adjacency` masked |
| branch_1 | compliant | an unlaned roadway segment (13) entering the intersection |
| branch_2 | not applicable | a single aligned right turn lane enters on the subject's approach |
| branch_3 | violated | two right turn lanes, so there is no single one; the subject is in lane 1 of 4 |
| branch_4 | violated | the only right turn lane serves the opposite approach (cosine −1) |
| branch_5 | violated | a left turn lane is on the approach; the subject is in lane 2 of 3 |
| branch_6 | violated | an aligned right turn lane enters a different intersection |

## Why I finished

The gate returned `OK`.
