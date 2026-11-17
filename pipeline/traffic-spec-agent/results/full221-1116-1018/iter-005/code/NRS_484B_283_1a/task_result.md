# NRS_484B_283_1a — task result

**Final verdict: OK** (12 witnesses, 18 names, composes all nine exception rules).

## Gate runs
1. `VACUOUS` — obligation leaves `dev_governs e re`, `rel_occupies p re`, `dev_pedestrian_signal_state e dark`
   (the pedestrian-head condition repeated in the obligation's selection of p) moved no witness:
   `branch_5` made it false only in the applicability. Added `branch_8` (compliant): one pedestrian
   engages the duty and is yielded to, a second in conflict is excluded by a pedestrian head showing
   walk on the lane it occupies, so flipping that leaf in the obligation alone changes the verdict.
2. `OK`.

(One stray shell call, the gate command with `--help`, was denied by permission before any run; it did
not execute.)

## How the record is written
- s: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- c1: every traffic signal head governing a travel region the subject occupies shows `dark` or is
  `dev_inoperative` (no such head = "not in place"); every pedestrian head governing a travel region p
  occupies shows `dark` (inside p's selection), as the applicability states.
- c2: p is `DEF-NRS-484A-165::pedestrian` and occupies some `crosswalk` (marked or not).
- c3 + d: p occupies a `lane` or `one_way_roadway` whose `st_lane_direction` has a positive dot
  product with the subject's `kin_heading` (components read through the `x`/`y` selectors).
- st2: p occupies a `lane` whose direction has a negative dot product with the heading, and
  `prim_closest_approach_within` ∧ `prim_closest_approach_distance < p.conflict_centre_clearance`
  (horizon `p.conflict_horizon`).
- ob + st: for every selected p: no `rel_contact`, and `kin_speed > p.halt_speed_tolerance` implies no
  such predicted conflict.
- r: `.not (.ruleApplies …)` — map subject ↦ p for NRS 484B.287 / LVMC 11-30-060 (inside p's
  selection), subject ↦ subject for LVMC 11-30-140(B) / 11-46-030 (in the applicability).
- The selection of p is a single formula (`pedestrianSelected`), read under `existsUser p` in the
  applicability and `forallUser p` in the obligation (rule 3c).

## Choices left open
- "(b) otherwise (p on the opposite half)" is written as the st2 operationalization states it (a lane
  p occupies whose direction points against the heading), not as the negation of (a).
- No narrowing declared: no choice narrower than the record's words was needed.

## Witnesses
forbid (violated), permit (compliant), idle (NA, green head), blind (unknown, `rel.occupies` masked),
branch_1 (NA, no pedestrian), branch_2 (NA, opposite half, approach beyond horizon), plus added:
branch_3 (violated, st2 danger from opposite half), branch_4 (violated, one-way roadway),
branch_5 (NA, pedestrian head shows walk), branch_6 (violated, inoperative head),
branch_7 (violated, dark head), branch_8 (compliant, see run 1).

## Why I finished
The gate returned OK on the second run.
