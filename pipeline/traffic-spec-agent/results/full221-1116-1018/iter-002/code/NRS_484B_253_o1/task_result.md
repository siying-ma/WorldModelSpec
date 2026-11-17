# NRS_484B_253_o1 — task result

## Final verdict: OK

(7 witnesses, 10 names, composes nothing)

## Gate runs

1. **UNUSED_CLAIM** — this run was on the harness skeleton, before any edits, so every claimed name was still unused. I ran it to see a baseline; strictly it wasn't needed. Earlier, I also tried a malformed command (the gate command with `--help` piped to `head`). The sandbox denied it and it did not run.
2. **OK** — after writing the rule and the seven witnesses described below.

## How the rule is written

- **Class (a):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (b, c):** there is an intersection X (quantifier kind `intersection`) that the subject occupies (`rel_occupies`), with `intent int.left_turn subject X` read at the judged observation.
- **Obligation:**
  - **X:** re-bound with the same selection as the applicability, for every such X.
  - **c1:** every `travel_region` c1 for which `st_lane_enters c1 X` holds and `since (occupies subject X) (occupies subject c1)` holds (the subject has been in X continuously since it occupied c1).
  - **v:** every road user v that is a vehicle (aggregate), is not the subject, and has some `travel_region` c2 where:
    - `st_lane_enters c2 X` holds;
    - `since (occupies v X) (occupies v c2)` holds;
    - the dot product of the `st_lane_direction` vectors of c1 and c2 is below `−p.oncoming_heading_cos`;
    - and either v occupies X (g), or v occupies c2 and is in conflict (h). Conflict means `prim_closest_approach_within` at `p.conflict_horizon` and `prim_closest_approach_distance` below `p.conflict_centre_clearance`.
  - **Duty (d, e):** the subject is not in contact with v (`rel_contact`), and it is not the case that it proceeds (`kin_speed > p.halt_speed_tolerance`) while in that conflict.

## Choices the node left open

- **X excluded as a carrier (structural, not a narrowing):** c1 and c2 range over travel regions, and X is itself one. Core reads `st_lane_enters` on a region with no lane information as *unknown*, so X as a candidate carrier would leave compliant verdicts unknown. X is not a carrier that enters itself, so I added `not (same c1 X)` and `not (same c2 X)`. The header comment records this.
- **"Occupies c2 now" is covered by `since`:** the record says v "occupies a carrier c2 entering X, or overlaps X continuously since an observation at which it occupied such a c2". `since` already covers the first case, so a separate first disjunct would have been redundant.
- No narrowings were declared.

## Witnesses

- **`forbid`:** violated, with v on lane 12 and outside X.
- **`permit`:** compliant; the subject waits at rest while v crosses X, then turns.
- **`idle`:** not applicable, because the intent is declared false.
- **`blind`:** unknown, from the `forbid` trace with `kin.speed` masked.
- **`branch_1`:** compliant, with no other user in the scene.
- **`branch_2`:** compliant; v comes from the cross street on lane 13, whose direction is perpendicular to c1's.
- **`branch_3` (added):** violated, with v inside X and no longer on c2. This exercises the "within the intersection" limb (g).

## Why I finished

The gate returned OK.
