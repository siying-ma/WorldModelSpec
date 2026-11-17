# NRS_484B_257_1_o1 — task result

## Final verdict
**OK** (gate run 1 of 6): 14 witnesses, 19 names, composes nothing, 1 narrowing declared by the coder.

## Gate runs
1. `OK`. No changes needed after it.

## How the rule is written
- **Subject (d):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Entry / trigger (c):** for some intersection X and some travel region c:
  - `rises (rel_occupies subject X)`
  - `since (occ X) (occ c ∧ ¬occ X)`. When `occ X` has just risen, this reads exactly the previous observation: the subject was on c and not in X.
  - `st_lane_enters c X`
  - a stop sign or a yield sign governs c or X.
- **Exceptions (a, b):** these are negated in the applicability.
  - (a) `ru_aggregate subject traffic` ∧ a `human_direction` device of role `police_officer` governs c or X.
  - (b) a `traffic_signal` governs c or X and is not `dev_inoperative`.
- **Obligation (e):**
  - **Selection:** for every (X, c) chosen by the applicability's whole selection (entry, lane_enters, a sign governing c or X), the formula is `since (¬ end) act`.
  - **Act:**
    - the subject occupies c;
    - a complete halt (`drv_motion_complete_halt`, p.halt_speed_tolerance) where a stop sign governs c or X; otherwise `kin_speed ≤ p.yield_line_speed_max`;
    - the subject is within the stopping zone of the place, taken in the words' order:
      1. a stop line marking c, with `prim_region_offset_along ≥ 0` and body distance ≤ p.stop_point_tolerance;
      2. if no stop line marks c: a crosswalk marking c, not occupied, ahead (offset ≥ 0) and within the tolerance;
      3. if neither marks c: X not occupied and within the tolerance of X.
  - **End** (either of two):
    - **Approach start:** the subject is on c and short of the place, meaning ahead of it (offset > 0) and farther than the tolerance from every mark of that tier marking c, or from X in tier 3.
    - **Previous entry:** the subject's exit from X after an earlier entry, `rises (¬ occ X)` (see the narrowing below).
  - At the entry observation itself the end does not hold, so an act at the entry counts.
  - A search that reaches the recording's start without finding either end is unknown (the `since` is truncated).

## Choices the node left open
- **Narrowing on span e (declared in `narrowings`):** the record bounds the search at "the subject's previous entry into X". I wrote that bound as the subject's observed exit from X after that entry.
  - **Why:** within one `since`, the judged entry cannot be told apart from an earlier entry at the same intersection, so a bound written as `rises(occ X)` would also end the search at the judged entry.
  - **Effect:** an act made while the footprint still overlaps X after an earlier entry does not count toward the next entry.
- **Several carriers:** where several selected carriers (X, c) apply at once, the act is owed through each one (`forallRegion … implies`), so no carrier is picked in the subject's favour. Where the verdicts differ between carriers, the result is violated rather than the unknown the `st.lane_enters` contract describes.
- **Yield branch:** written as "no stop sign governs c or X". Under the selection, this is the same as "only a yield sign does".
- **Approach start carrier:** "on a carrier the place marks" is read as the selected carrier c.
- **Traffic aggregate:** `ru.aggregate=DEF-NRS-484A-285::traffic` is used once, in span a. Span e's mention of "traffic" (approaching traffic) has no observable leaf beyond the place, which the record itself reads as a perception narrowing.

## Witnesses
- **Planned:** forbid (rolling pass at 3 m/s through the stop line's zone), permit, idle, blind, history_boundary, branch_1–3.
- **Added** so that every leaf is exercised:
  - **branch_4:** crosswalk tier; stop sign governs X; compliant.
  - **branch_5:** crosswalk tier; yield sign governs X; violated.
  - **branch_6:** X-edge tier; stop sign on c; compliant.
  - **branch_7:** X-edge tier; stop sign governs X; rolling through the zone; violated.
  - **branch_8:** a dark (inoperative) signal governs c; violated.
  - **branch_9:** re-entry after backing out of X; violated.
- **Distractors:** the forbid scene has an officer and an operating signal governing only the cross lane. Every scene has a stop line and a crosswalk that mark only the cross lane.

## Why I finished
The gate returned `OK` on the first run.
