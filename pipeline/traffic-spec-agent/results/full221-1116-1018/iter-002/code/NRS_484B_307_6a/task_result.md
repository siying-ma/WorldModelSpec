# NRS_484B_307_6a — task result

**Final verdict: OK** (12 witnesses, 8 names, composes nothing).

## Gate runs
1. `UNUSED_CLAIM` — on the harness skeleton (all formulas `.tt`), run before writing; no change from it.
2. `WITNESS_FAIL` — branch_8 set `lane.enters_intersection` to a region (15) absent from the scene,
   which the adapter cannot produce. Removed branch_8 (a "c enters an intersection outside the
   scene" variant of branch_9).
3. `OK`.

After run 3 I only deleted an unused constant (`farId`) from the witness file. Nothing referenced
it; the harness re-runs the gate anyway.

## How the rule is written
- **Class (s2/s5):** `ru_aggregate subject "DEF-NRS-484A-285::traffic"` ∧ `ru_aggregate subject
  "DEF-NRS-484A-320::vehicle"` ("vehicular traffic" = traffic that is vehicular).
- **Yellow alone (s1):** `shows s circular_yellow` ∧ ¬(shows s of any other spelling of the
  enumeration: circular_green/red, flashing_red/yellow, dark, unknown, and every arrow of every
  direction).
- **Facing (s2):** ∃ intersection i, travel region c, traffic signal s with `st_lane_enters c i`,
  `dev_governs s c`, and `A ∨ rises(¬A)` where
  `A := since (occupies c) (occupies c ∧ yellowAlone s)`. A is the record's "s displayed yellow
  alone at some observation since the subject has occupied c without interruption", and
  `rises(¬A)` is A at the previous observation wherever A is false now. Together they give the
  record's "at the judged observation, or at the previous one".
- **Obligation (s6 + s7):** for every (i, c, s) of the same whole selection (repeated in full, per
  rule 3c): ¬(`rises (occupies i)` ∧ `shows s circular_red` ∧ no green arrow and no flashing
  yellow arrow of any direction). The arrow exclusion is the record's own s6 narrowing.

## Choices the node left open
- Class conjunction rather than disjunction of the two aggregates. This follows the words
  "vehicular traffic". It is not declared as a narrowing because the subject span is carried as
  mapped.
- "No other state" includes `dark` and `unknown`, following the record's "no other state" literally.
- "At the previous observation" is expressed through `rises(¬A)` because the language has no
  `prev`. At the trace's first observation this is unknown, so every witness names
  `window = (500, 4000)`, which excludes the first instant. This is not a history-boundary
  witness.
- No narrowings of my own were declared.

## Witnesses
forbid (violated), permit (compliant), idle (not applicable), blind (unknown, `st.lane_enters`
masked), plus branches:
- **branch_1 (N/A):** yellow shown with a green arrow, so not alone.
- **branch_2 (compliant):** the red has a green arrow beside it at the entry.
- **branch_3 (N/A):** the subject is a bicycle (traffic, not a vehicle).
- **branch_4 (violated):** the footprint straddles c and i at the entry.
- **branch_5 (N/A):** the yellow was seen before the car occupied c.
- **branch_6 (N/A):** the head governs only the adjacent lane.
- **branch_7 (compliant):** the car's head stays yellow while the adjacent lane's head is red.
- **branch_9 (compliant):** the car backs out of c's exit end into another intersection on the red.

Speeds in the scenes are nominal; the rule reads no speed.

## Why I finished
The gate returned OK on run 3 of 6.
