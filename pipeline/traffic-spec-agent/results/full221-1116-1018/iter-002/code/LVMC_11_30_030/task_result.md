# LVMC_11_30_030 — task result

**Final verdict: OK** (12 witnesses, 13 names, composes nothing; 1 coder narrowing)

## Gate runs

1. **VACUOUS** — two obligation leaves had no effect on any witness:
   - `rel_same_direction(subject, b)` (inside the under-way formula U)
   - `rel_occupies(b, c)` (in the obligation's restatement of d1).

   I added two branch witnesses:
   - `branch_5` (compliant): the trigger holds only while the subject creeps up behind b, with b
     still ahead and headings aligned, so before the act begins. The pass comes after b has moved
     off. If `rel_same_direction` is forced false, the approach counts as part of the pass and the
     verdict flips.
   - `branch_6` (compliant): two cars queue at the crosswalk. Car 4 is 1 m before it, and b is 7 m
     short of it. The subject passes b and halts alongside car 4. Car 4 makes the rule apply, and the
     obligation's `rel_occupies(b, c)` leaf decides b.
2. **OK** — no further changes.

## How the rule is written

- **Class (d2):** `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- **d1 `stoppedAtCrosswalk` (for b):** all of the following hold:
  - `drv_motion_complete_halt b [p.halt_speed_tolerance]`
  - some crosswalk c with `rel_occupies b c` ∨ `st_region_geometry_distance b c ≤ p.stop_point_tolerance`
  - some `travel_region` l with `rel_occupies b l` ∧ `prim_region_offset_along b c l ≥ 0`
  - some p with `ru_aggregate p DEF-NRS-484A-165::pedestrian` ∧ `rel_occupies p c`
- **Applicability:** some b ≠ subject is a vehicle and satisfies
  `¬ holdsFor time p.overtake_window subject ¬d1`. That means d1 holds now or at some observation in
  the window behind.
- **Obligation:** there is no b ≠ subject that is a vehicle with both:
  - `drv_interaction_overtake_pass subject b [p.overtake_window, p.overtake_same_direction_cos]`
  - `¬ holdsFor time p.overtake_window subject ¬(U ∧ d1)`. This is the occasion's `some_moment`
    form, and it states d1's crosswalk, carrier and pedestrian selection again in full.
- **U (under way):** `kin_speed subject > p.halt_speed_tolerance ∧ (¬A until rises(behind))`.
  - A = `rel_bearing ahead` ∧ `rel_longitudinal_overlap < 0` ∧ `rel_same_direction(cos)`.
  - behind = `rel_bearing behind` ∧ `rel_longitudinal_overlap < 0`.

## Choices the node left open

- **The act's first observation (narrowing on d3, kind `reading`).** The record says the pass runs
  from the last observation at which b was ahead with headings aligned (inclusive) up to the
  recognition. The language has no operator for the next observation. Without one, a formula judged
  at an observation cannot tell the last aligned-ahead observation apart from the earlier ones in
  the same run. U therefore counts only the observations strictly after it, up to and including the
  recognition. The one observation left out is the one where b is still ahead of the subject with a
  gap between them.
- **`¬A until rises(behind)` matches the first recognition after the observation.** If the same b
  were passed twice within one window, an observation from the earlier pass could be counted for the
  later one. None of the witnesses passes the same b twice.
- **The `rel_occupies(b, c)` disjunct is kept as the record maps it.** It only matters where the
  distance cannot be read, because a body that occupies c has a distance of zero. `branch_6` exercises
  it through the gate's leaf test.

## Witnesses

All traces are padded with 12 s of their first scene, and `window` names the instants built from the
narrative.

| Witness | Map | Expected |
|---|---|---|
| forbid | marked crosswalk mid-block | violated |
| permit | marked crosswalk mid-block | compliant |
| idle | marked crosswalk mid-block | not applicable |
| blind | marked crosswalk mid-block, `kin.speed` masked | unknown |
| occasion_d1 | unmarked crosswalk at an intersection; pedestrian on the crosswalk only at the pass's first observation that U counts | violated |
| occasion_d1_outside | marked crosswalk mid-block | compliant |

Additional branches:

| Witness | What it shows | Expected |
|---|---|---|
| branch_1 | b halts 5 m short of the crosswalk | not applicable |
| branch_2 | b halts 1 m beyond the crosswalk, so the offset is negative | not applicable |
| branch_3 | the pedestrian waits on the curb | not applicable |
| branch_4 | b creeps at 0.5 m/s, so it is not halted | not applicable |
| branch_5 | trigger holds only during the approach | compliant |
| branch_6 | queue at the crosswalk | compliant |

## Why I finished

The gate returned OK on the second run. Both files are complete, and the one reading I chose is
declared as a narrowing on d3.
