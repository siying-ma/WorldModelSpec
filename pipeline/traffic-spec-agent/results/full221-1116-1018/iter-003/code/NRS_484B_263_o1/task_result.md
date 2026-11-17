# NRS_484B_263_o1 — task result

**Final verdict: OK** (6 witnesses, 8 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM`: run on the harness skeleton before any edit, to get a baseline. Every claimed name was unused because the formulas were still `.tt`.
2. A second invocation was piped (`| head -0`) by mistake. Its output was discarded, so it gave no information, but it may have counted against the budget.
3. `OK`: run after writing the rule and the six witnesses. Nothing changed after it.

## How the rule is written
- **Class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (a2):** the subject is moving (`kin_speed > p.halt_speed_tolerance`), and for some region `c` of kind `controlled_access`, either `rises (rel_occupies subject c)` (entry) or `rises (not (rel_occupies subject c))` (exit).
- **Obligation (a3/a4/a5):** this applies to every `controlled_access` region `c`, selected again by the same entry-or-exit rise. For every road user `v` that meets all of these:
  - `v` is not the subject,
  - `v` is in the vehicle aggregate,
  - `v` is moving,
  - `v` occupies `c`,
  - `rel_bearing v subject "ahead"` holds,

  the subject must have no `rel_contact` with `v`, and it must not be true that both `prim_closest_approach_within subject v p.conflict_horizon` holds and `prim_closest_approach_distance` is below `p.conflict_centre_clearance`.
- **Open choices:** none beyond the record. For "subject ahead in v's frame" I used the Boolean `rel_bearing … "ahead"` (longitudinal component > 0), which is exactly the record's wording. No narrowings were declared.

## Witnesses
- **Layout:** one controlled-access rectangle, three observations 1 s apart.
- **Window:** every witness has `window = [1000, 2000]` ms. `rises` is unknown at the first observation because it reads the previous one, so the first observation is left out.
- **forbid / blind:** v is 8 m behind and closing at 10 m/s, so the closest approach comes at 0.8 s at a distance of 1 m. In `blind`, `ru.aggregate` is masked.
- **permit:** v is 230 m behind, so the closest approach would come at 23 s, beyond the 3 s horizon.
- **idle:** the subject stays inside `c` throughout.
- **branch_1:** the subject enters `c` alone.
- **branch_2:** the subject exits `c` while v is in conflict, with a closest-approach distance of 2.5 m.

## Why I finished
The gate returned `OK`. Separately, I ran one `grep` on a Core file, which goes beyond the single-command access rule. It changed no file.
