# NRS_484B_310_1 — task result

## Final verdict: OK

The gate reported: 10 witnesses, 14 names, composes nothing, 1 narrowing declared by the coder.

## Gate runs (2 of 6 used)
1. **UNUSED_CLAIM**: I ran this on the harness skeleton before writing anything, so every claimed name was reported unused. This run was wasted.
2. **OK**: run on the full rule plus 10 witnesses (the 6 planned scenarios and branch_2 to branch_5).

## How the rule is written
- **Class (s2, s4):** `ru_aggregate` on both admitted aggregates (traffic, vehicle), joined with "and".
- **Applicability (s1, s3):** there is some intersection `i` and some travel region `c` where all of these hold:
  - The subject enters `i` from `c`: it occupies `i` now, and at the previous observation it occupied `c` and not `i`. The previous observation is reached with `occ i ∧ rises (occ i ∨ ¬occ c)`.
  - `st_lane_enters c i` holds.
  - Some traffic-signal head that governs `c` or `i` shows `flashing_red`.
- **Obligation (s5):** for every intersection, and every carrier picked by the same selection as the applicability (signal included, per rule 3c), a stop was made. A stop counts if either of these holds:
  - A halt (`drv_motion_complete_halt`, speed tolerance `p.halt_speed_tolerance`) within `p.stop_point_tolerance` of a stop line or crosswalk recorded as marking `c`. The halt must be short of that mark along `c`'s direction (`prim_region_offset_along` > 0) and must overlap neither the mark nor `i`.
  - If none: the entrance lists are observed, show no mark for `c`, and the same halt is made short of `i`'s edge.
- **History bound:** `since (¬approachStart ∧ ¬occ i) haltFound`.
  - The approach start is defined as in the record. For each mark marking `c`, the subject is on a carrier that mark marks, off the mark, short of it, and farther from it than the tolerance.
  - The previous entry into `i` is read as any earlier occupancy of `i`. The observation just before the judged entry never occupies `i`.
  - If the search reaches the start of the recording, the result is unknown (`windowTruncated "since"`).
- **Where the search starts:** the search runs back from the observation before the entry. At the entry, `since` is always false because the subject occupies `i`. So `rises (¬ since …)` at the entry equals the value of `since …` at the previous observation.
- **Several carriers:** the `st.lane_enters` contract says that if the verdict differs between carriers entering the same intersection, it is unknown. I wrote this as `definedWhen (all selected comply ∨ all selected fail) (all selected comply)`.
- **s6:** kept as the record's residue.

## Choices the node left open
- **Narrowing on s5 (kind `reading`):** the record defines the approach start only for marks. For the "if none" branch I read it the same way against `i`'s edge:
  - the subject is on a carrier entering `i`;
  - it does not overlap `i`;
  - it is short of `i` along `c`;
  - it is farther from `i` than `p.stop_point_tolerance`.
- Mark alternatives are written as two separate quantifiers, one over `stop_line` and one over `crosswalk`.

## Witnesses
| Scenario | Verdict | What happens |
|---|---|---|
| forbid | violated | Stop line; the car drives through at 8 m/s. |
| permit | compliant | The car halts 0.5 m short of the stop line, then enters. |
| idle | not applicable | The signal shows `circular_green`. |
| blind | unknown | `dev.traffic_signal` is masked. |
| history_boundary | unknown | The recording starts with the car 1 m short of the line, rolling at 1 m/s. The search reaches the start of the recording. |
| branch_1 | compliant | The observed lists show no mark for `c`; the car halts 1 m short of `i`'s edge. |
| branch_2 | compliant | Crosswalk only; the car halts 1 m short of it. |
| branch_3 | violated | Crosswalk only; no halt. |
| branch_4 | violated | No mark; no halt. |
| branch_5 | violated | The head governs `i` rather than `c`; no halt. |

## Why I finished
The gate returned OK on the second run.
