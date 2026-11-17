# NRS_484B_283_1d3_o2 — task result

**Final verdict: OK** (6 witnesses, 12 names, all nine exception compositions resolved).

## Gate runs

1. **WITNESS_FAIL**: forbid, blind and history_boundary were unknown for
   `absent_atom:st_lane_direction`. A composed exception rule reads the direction of travel of r.
   **Fix:** I gave r (`lane := some { direction := some Build.east }`) a direction square to the
   crossing.
2. **WITNESS_FAIL**: forbid, blind and history_boundary were `not_applicable`. On the roadway
   scenes an exception rule engaged, most likely the one for a pedestrian crossing a roadway
   outside a crosswalk. branch_1, on a lane, still passed. **Fix:** I added a marked crosswalk
   (region 30) that spans r along the pedestrian's path.
3. **OK**.

(Before run 1 I made one stray call: the gate command with `--help` appended. It was denied
without running and used no gate budget.)

## How the rule is written

- **s2:** the binder class is `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **c0:** `existsDevice pedestrian_signal d` and a region `r` of kind roadway or of kind lane
  (one disjunct each), with `dev_governs d r`.
  - **Facing d** is written as the record states it, with Δ = dev_position − kin_position and
    h = kin_heading:
    - h·Δ > 0
    - (h·Δ)² ≥ cos²·|Δ|²
    - |Δ|² ≤ reach²
- **t / moment of ob2:** the judged observation is
  `rises (state dont_walk_steady) ∧ since (steady) (dont_walk_flashing ∧ ¬countdown)`. With the
  rise, the `since` reaches exactly the previous observation.
- **e1 (with ref2):**
  - The step is `rises (occupies subject r) ∧ since (occupies r) (∃ sidewalk s, occupies subject s)`:
    r is entered at this observation, and a sidewalk was occupied at this one or the one before.
  - "Latest step made under walk while facing d" is
    `since (¬step) (step ∧ walk ∧ facing)`. The look-back is unbounded, as the record's history
    bound says. Where the step lies before the recording, the `rises` and `since` are truncated
    and the result is unknown.
- **e2:** `since (¬rises F) (occupies r ∧ F)`, where F is flashing without countdown. In words:
  the pedestrian was on r at some observation since d last began showing F.
- **ob2:** the obligation repeats the full selection of (d, r) and requires `¬ occupies subject r`
  for every selected pair (forall device, forall roadway and forall lane).
- **r:** each exception is written as `¬ ruleApplies`. The two LVMC_11_46_030 limbs bind their
  vehicle with `existsUser "v"`.
- **Narrowings:** none of my own. The record's ob2 narrowing (any place off r counts as a place
  of safety) is used as given and not restated.

## Witnesses

- **Layout:**
  - Roadway r is x ∈ [0, 20], y ∈ [0, 10], with its direction of travel east.
  - Sidewalks lie to the south and north of r.
  - A marked crosswalk spans r at x ∈ [8, 12].
  - The signal head is at (10, 15) and never shows a countdown.
- **The pedestrian** walks north along x = 10, one observation per second. It faces the head
  head-on (cos 1 against 0.87) from at most 17 m (against 40 m).
- **forbid:** still on r when d turns steady → violated.
- **permit:** on the north sidewalk when d turns steady → compliant.
- **idle:** steps on while d is already flashing → not applicable.
- **blind:** the forbid trace with `dev.pedestrian_signal` masked → unknown.
- **history_boundary:** the recording opens with the pedestrian already on r under flashing →
  unknown, because the truncated `rises`/`since` can't find the step.
- **branch_1:** the forbid trace on a lane instead of a roadway, which exercises the lane
  disjunct → violated.

## Why I finished

The gate returned OK on run 3 of 6.
