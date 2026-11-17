# NRS_484B_250_4_o1 — task result

## Final verdict
**OK** (13 witnesses, 15 names, composes nothing).

## Gate runs
1. `BUILD_FAIL`: an extra closing parenthesis in `approachStart`. Removed it.
2. `OK`.

## How the rule is written
- **Class (v, dr):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (t1–t3):** there is an intersection X and a travel region c with
  `st_lane_enters c X`, where:
  - `rises (occupies X)` holds: the subject is in X now and was not at the previous observation;
  - `rises (occupies X ∨ ¬occupies c)` holds: given the first condition, this means c was occupied
    at the previous observation;
  - some `traffic_signal` d has `dev_traffic_signal_uncovered`, `dev_governs d c ∨ dev_governs d X`
    and `dev_inoperative`.
- **Obligation (o):** for every (X, c) chosen the same way as in the applicability (the entry plus
  an inoperative governing signal), the rule requires `rises (occupies X ∨ ¬search)`. At an entry
  this is exactly `search` evaluated at the previous observation, so the current entry is never
  treated as "the previous entry into X".
  - `search = since (¬rises(occupies X) ∧ ¬approachStart) haltAtPlace`.
  - Core's `since` returns true if the halt is found first. It returns false (violated) if either
    end is reached first. If it reaches the trace start without finding either, it returns
    unknown (`windowTruncated since`).
- **Choosing the stopping place:** written `(B1 ∧ ·) ∨ (¬B1 ∧ B2 ∧ ·) ∨ (¬B1 ∧ ¬B2 ∧ ·)`, where B1
  is "some stop line has `st_entrance_of` c" and B2 is "some crosswalk has `st_entrance_of` c".
  This form is used both for the halt place and for the approach start.
- **Halt place:** `drv_motion_complete_halt(p.halt_speed_tolerance)` ∧ `occupies c`, and then:
  - with a stop line: offset along c ≥ 0 and distance ≤ `p.stop_point_tolerance`;
  - with only a crosswalk: the footprint is off the crosswalk, offset > 0 and distance ≤ tolerance;
  - with neither: the footprint is off X and distance ≤ tolerance.
- **Approach start:** the subject occupies a carrier c′ that the place marks, and is outside the
  stopping zone upstream:
  - for stop lines or crosswalks: every mark of c also marks c′, and each one has offset > 0 and
    distance > tolerance;
  - with no mark: `st_lane_enters c′ X`, X's offset > 0 and distance > tolerance.

## Choices the node left open
- **Several carriers c through which X was entered:** the obligation applies to every such carrier
  (`forallRegion`), so the rule never picks the carrier that favours the subject. This means that
  when carriers disagree, the result is violated rather than unknown. That is stricter than the
  `st.lane_enters` contract ("which governs is unknown") on that rare configuration.
- **"Off the mark" in the approach start** is carried by "distance > tolerance": by the
  `st.region_geometry` contract the distance is zero on overlap. I did not add a separate
  `¬occupies` conjunct there.
- **"A carrier the place marks"** (approach start) is read as: every mark of c's kind that marks c
  also marks c′. For the no-mark case it is read as: c′ enters X.
- **No narrowings were declared.** The record's own observable readings are not restated.

## Witnesses
The planned ones are forbid, permit, idle, blind, history_boundary, branch_1 and branch_2. I added:
- branch_3: re-entry, where the previous entry ends the search → violated;
- branch_4: the signal governs X, not c → violated;
- branch_5: crosswalk-only, compliant;
- branch_6: halt on the crosswalk → violated;
- branch_7: no mark, no halt → violated;
- branch_8: halt outside the line's zone → violated.

## Note for the plan
The claim `ru.aggregate=DEF-NRS-484A-285::traffic` (span o) appears in no formula. The record's own
narrowing reads "view of approaching traffic" through the place, and no formula leaf carries it.
The gate did not flag it as `UNUSED_CLAIM`. Still, the plan may want to drop that claim, since
nothing in the obligation reads it.

## Why I finished
The gate returned OK on the second run.
