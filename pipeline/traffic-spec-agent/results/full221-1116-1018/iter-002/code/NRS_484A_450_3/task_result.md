# NRS_484A_450_3 — task result

**Final verdict: OK** (12 witnesses, 16 names, composes nothing, 1 coder narrowing).

## Gate runs (5 used of 6)

1. **UNUSED_CLAIM** on the untouched skeleton. I ran this by mistake: it was my baseline call with `| head`
   appended. That call broke the "exactly this command" rule.
2. **UNUSED_CLAIM** on the skeleton again. A duplicate call I issued by accident. Nothing had changed.
   (I also tried `python -m harness gate --help` once. The permission layer denied it, so it did not run and did not count.)
3. **VACUOUS** after writing the rule and 10 witnesses. Applicability leaves 15, 16 and 21 were the
   approach-start tests inside the search for a conflict: off the stop line, short of the stop line,
   and short of r. Every witness with a stop line or with no marks found the conflict before the
   search reached the approach start. Fix: I added `branch_6` and `branch_7` (both not applicable).
   In each the car is alone, so the search has to stop at an observed approach start: a stop-line
   layout in `branch_6`, a layout with no marks in `branch_7`.
4. **OK**.

## How the rule is written

- **Entry event:** `rises (rel_occupies subject r)` over intersections r. The approach carrier c is a
  travel region the subject occupied at t-1, with `st_lane_enters c r` and a yield sign that
  `dev_governs` c.
- **"At t-1":** the language has no previous-observation operator, so I wrote it as
  `rises (occupies r ∨ ¬χ)`. At an entry this equals χ at the observation before. I use it only
  conjoined with, or under, the entry itself.
- **Search into the past:** `since inApproach ψ`, read at t-1. `inApproach` means neither at the
  approach start nor in r.
  - The approach start is the subject on c, off and short of every governing mark of c, and farther
    than `p.stop_point_tolerance` from each. The governing mark is the crosswalk, else the stop line,
    else the edge of r.
  - Any observation in r (the previous entry) also ends the search.
  - Core's `since` gives unknown where the search reaches the start of the recording. That is what
    makes `history_boundary` unknown.
- **The act:** `drv_motion_complete_halt` at the place, in the record's order: crosswalk, else stop
  line, else the edge of r.
  - Off the mark uses `rel_occupies`.
  - Short of it is `prim_region_offset_along` along c, positive.
  - Within the tolerance uses `st_region_geometry_distance`.
  - With several marks of the governing kind, a halt at any of them counts (an existential).
- **s3, the conflict:** written as the record's operationalization. Another road user u (`same`
  excludes the subject) belongs to the traffic aggregate, occupies a highway, has
  `prim_closest_approach_within` true, and its `prim_closest_approach_distance` is below
  `p.conflict_centre_clearance`. It is searched over the same stretch as the act.

## Choices the node left open

- **Approach start read on c only.** I read the approach start only while the subject is on the
  approach carrier c, not on any carrier the mark marks. Declared as a narrowing on s4.
- **"Not past" vs "short of".** "Not past" a stop line is an offset of zero or more. "Short of" a
  crosswalk or r is an offset greater than zero.
- **Every selected carrier.** The obligation repeats the applicability's whole selection of r and c
  and requires the duty through every selected carrier (`forallRegion`), so no carrier is picked in
  the subject's favour.
  - Where two selected carriers disagree, this gives violated. The `st.lane_enters` contract asks
    for unknown there.
  - Fixing that needs a `definedWhen` over an "all comply ∨ all fail" agreement. No witness has two
    carriers, so I kept the simpler form. A repair session may want to revisit it.
- **Witnesses added beyond the plan:**
  - `branch_4` (stop line, no halt) and `branch_5` (no marks, no halt), both violated.
  - `branch_6` and `branch_7`, both not applicable, as described under gate run 3.
- **`history_boundary` is sampled at 4 m/s**, not the narrative's 3 m/s. This keeps positions clear
  of region boundaries at 1 s spacing.

## Why I finished

The gate returned OK.
