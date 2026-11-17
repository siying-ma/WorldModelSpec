# NRS_484B_227_1_o1 — task result

**Final verdict: OK** (8 witnesses, 9 names, composes nothing)

## Gate runs
1. **VACUOUS** — the exception leaves (opening: `st_on_way o h`, `rel_occupies subject o`,
   `st_median_or_divider_opening o`; intersection: `st_on_way i h`, `rel_occupies subject i`) inside
   the obligation's re-written selection of h never moved a verdict, because every witness that
   engaged the rule had a single occupied highway on which no exception held. The rule stayed as written
   (3c requires the obligation to re-state the applicability's whole selection of h). I added two
   witnesses in which the subject occupies two highways: divided highway 100, where it drives with its
   roadway, and an overpass 200 with its own median, where its footprint is over 200's roadway against
   that roadway's direction:
   - `branch_3` (compliant): the subject overlaps an opening median section lying on 200 only.
   - `branch_4` (compliant): the subject overlaps an intersection lying on 200 only.
   If either exception leaf is dropped, 200 is selected and the scene becomes violated.
2. **OK**.

## How the rule is written
- a: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- b: some highway h that the subject occupies, with some median_or_divider lying on h (`st_on_way d h`).
- f, g: no median_or_divider lies on h, is occupied by the subject and has `st_median_or_divider_opening`;
  and no intersection lies on h and is occupied by the subject. Both are conjoined into the selection of h.
- c: for every highway selected the same way (exceptions included), for every roadway r that lies on h
  and is occupied by the subject, `drv_motion_moving_against_carrier(subject, r)` with
  `p.halt_speed_tolerance` does not hold.

## Choices left open
- The record left nothing open that needed a narrowing of my own, so `narrowings` is empty. The
  record's own narrowings and observable readings are not restated.
- I read the opening attribute through `st_median_or_divider_opening`, the accessor for the claimed
  atom `st.median_or_divider`'s opening attribute. The gate accepted this as covered by the claim.

## Witnesses
`forbid`, `permit`, `idle`, `blind` (st.lane_direction masked) and `branch_1` (intersection on h)
follow the plan's narratives. I added `branch_2` (the subject overlaps an opening median section on h,
not applicable), plus `branch_3` and `branch_4` as described above. Speeds are 10 m/s against a
0.1 m/s tolerance.

## Why I finished
The gate returned OK on the second run.
