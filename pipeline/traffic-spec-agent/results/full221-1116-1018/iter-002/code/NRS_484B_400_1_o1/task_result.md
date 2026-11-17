# NRS_484B_400_1_o1 — task result

**Final verdict: OK** (`9 witnesses, 8 names, composes nothing`)

## Gate runs (5 of 6 used)

1. **UNUSED_CLAIM** (rel_occupies, ru_aggregate, st_intersection, st_lane). The skeleton was gated
   untouched: my first call wrongly chained the gate with an `ls`, which spent one run.
2. **VACUOUS**: the uniqueness leaves on `t2` ("single" right turn lane), in both the applicability
   and the obligation. I added `branch_2` (two aligned right turn lanes on the approach → not
   applicable) and `branch_3` (another approach's right turn lane pointing north, cos 0 → still
   violated).
3. **VACUOUS**: obligation leaves `st_turn_lane t2`, `st_turn_lane_side t2 right`,
   `st_lane_enters t2 i`. These sit in the obligation's copy of the selection, which rule 3c
   requires. I made two changes:
   - I dropped `st_turn_lane t2` inside `forallRegion turn_lane t2`. The quantifier already
     enforces that kind, so the leaf could never change a verdict. `st_turn_lane` is still used
     on `t` and in the obligation.
   - I added `branch_4` (a left turn lane on the same approach → violated) and `branch_5` (an
     eastbound right turn lane entering another intersection upstream → violated).
4. **OK**.
5. **OK**, after a cosmetic cleanup: the duplicate cosine helper was merged and a header note
   added.

## How the record is written

- **Judged observation:** the subject's entry into an intersection `i`:
  `st_intersection i ∧ rises (rel_occupies subject i)`, over every region of kind intersection.
- **"At the observation before e":** written `since (occ i) (¬occ i ∧ X)`. Where `rises (occ i)`
  holds, this is exactly X at the previous observation, because `since` is non-strict and
  three-valued (see `Temporal.sinceAll`). No time parameter is needed, and the intention is read
  only in the past.
- **s2/s4:** `intent "int.right_turn" subject i` at the observation before e.
- **s6+s7:** there is an approach lane `c`: a region of kind lane (turn lanes included by
  refinement) with `st_lane c`, occupied by the subject, entering `i`. For it there is exactly one
  turn lane `t` that is side right, enters `i`, and has
  `dir(t)·dir(c) ≥ p.approach_lane_same_direction_cos`. "Exactly one" is written as ∃t plus
  ∀t2 (same selection → `same t2 t`).
- **s5 (obligation):** for every intersection `i`, the whole applicability selection of `i` implies
  that at the observation before e the subject occupies a turn lane of side right entering `i`.
  - The s5 element claims no direction atom.
  - A right turn lane entering `i` that the subject occupies is a lane of the subject's own
    approach (c := t). The applicability already ensures there is only one such lane.
  - So this is the record's `t`, and it gives the record's "met whatever else is unobserved".
- **No narrowing declared:** every choice above follows from the record's applicability and
  obligation text.

## Witness choices

- **Geometry:** an eastbound approach of two 4 m lanes ending at an intersection
  x ∈ [0, 20], y ∈ [-20, 20]. The subject moves at 12 m/s with samples at x = -20, -8, 4 at
  t = 0, 1, 2 s, so it enters at t = 2 s.
- **Direction margin:** the aligned lanes have a direction cosine of 1 against the 0.9 bound; the
  misaligned one (`branch_3`) has a cosine of 0.
- **`branch_1`:** the declaration lists `int.left_turn` true and `int.right_turn` false. Leaving
  `int.right_turn` out would make the intention unknown, not false.

## Why I finished

The gate returned OK, confirmed by a second run after the cosmetic change. I found no defect in
the node or its concepts.
