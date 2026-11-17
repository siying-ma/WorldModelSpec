# NRS_484A_450_2 — task result

**Final verdict: OK** (10 witnesses, 13 names, composes nothing).

## Gate runs (5 of 6)

1. **VACUOUS**: these leaves were never exercised:
   - the stop-line approach start (off / short / farther than the tolerance from the line);
   - "no stop line marks c" in the no-mark approach start;
   - the no-mark approach start (on a carrier entering r).

   Branches 1 and 2 found the halt before the search reached the approach start, so those leaves never decided anything. I added `branch_4` (violated: halts 20 m short of the stop line, then enters) and `branch_5` (violated: no marks, halts 21 m short of r, then enters).
2. **VACUOUS**: one leaf was still unexercised: `st_entrance_of lq c` ("no stop line marks c") in the no-mark approach start. `branch_5` had no stop line at all, so the leaf was never evaluated. I added a stop line 41 that is recorded (entrances observed) as marking a different approach only.
3. **WITNESS_FAIL**: stop line 41's `entranceOf` named region 11, which was not in the scene. I added the opposing lane 11, which enters r from the east.
4. **OK.** After this I only edited a header comment in the witness file.
5. **OK** again, on the final files.

## How the rule is written

- **Class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s2, s9):** `∃ intersection r, ∃ travel_region c: occ r ∧ rises(occ r ∨ ¬P(c,r))`.
  - P(c,r) = `occ c ∧ st_lane_enters(c,r) ∧ ∃ stop_sign d: dev_governs(d,c)`.
  - Combined with `occ r` now, this is exactly the record's condition: occupies r at t, not at t-1, and P at t-1.
  - The language has no "previous observation" operator. Taking `rises` of that disjunction is how the rule reads a value at t-1.
- **Obligation (s3):** `∀ r, ∀ c: [the same selection] → rises(occ r ∨ ¬(P ∧ search))`. Where the selection holds, this equals `search` at t-1.
  - `search = since(¬approachStart ∧ ¬rises(occ r), haltedAtPlace)`.
  - **haltedAtPlace:** `complete_halt(p.halt_speed_tolerance)` at a place, taken in the record's order:
    1. Some crosswalk marking c: off it, offset along c > 0, and distance ≤ `p.stop_point_tolerance`.
    2. Otherwise, no crosswalk marks c and some stop line marking c: offset ≥ 0 and distance ≤ tolerance.
    3. Otherwise, neither marks c: off r, offset to r along c > 0, and distance to r ≤ tolerance.
  - **approachStart:** the subject is on a carrier that a governing mark (one marking c) also marks, and is outside the upstream zone of every mark of that kind marking c (off it, offset > 0, distance > tolerance).
  - **Previous entry into r:** `rises(occ r)` inside the search ends it.
  - **Start of the recording:** ends nothing. `since` is unknown there, which is what `history_boundary` shows.
  - `st.lane_direction` is read through `prim_region_offset_along`, and `st.region_geometry` through `st_region_geometry_distance`.

## Choices the node left open

- **Approach start in branch 3 (no mark):** the record says the approach start is "on a carrier the governing mark is recorded as marking", but in this branch there is no mark. I read it as being on a carrier entering r (`st_lane_enters(c2, r)`) and outside r's upstream zone. This reads the history bound, not the law's words, so I declared no narrowing. It is recorded in the rule header.
- **Witness occupancy:** each witness states occupancy from the car's footprint (x ± 2 m) rather than from its reference point, so a body across two regions occupies both, as the `rel.occupies` contract says.

## Note for the plan (not a defect I could fix)

The record says an unobserved `dev.governs` should make the verdict unknown only where it matters: "a halt found at a place known to govern … decided whatever the missing fact".

The rule can't do that. The stop sign is part of the trigger (s2), so it belongs in the applicability. Core's `verdictAt` returns unknown whenever the applicability is unknown, whatever the obligation says. So with an unobserved `dev.governs`, even a recorded compliant halt comes out unknown. The planned `blind` witness (no halt) is unknown either way.

## Why I finished

The gate returned OK.
