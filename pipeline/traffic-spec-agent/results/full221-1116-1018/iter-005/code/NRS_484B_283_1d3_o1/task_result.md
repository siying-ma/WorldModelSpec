# NRS_484B_283_1d3_o1 — task result

**Final verdict: OK** (7 witnesses, 12 names, all nine compositions resolved).

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. Nothing changed after it.

## How the record is written
- **s1/s2:** the binder's class is `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **c0 + t:** `existsDevice "pedestrian_signal" d`, then a roadway or lane `r`, written as two
  quantifiers (`roadway`, `lane`) because the record names both kinds. The selection is
  `dev_governs d r`, `dev_pedestrian_signal_state d "dont_walk_flashing"` and
  `¬dev_pedestrian_signal_countdown d`, plus "faces". "Faces" is the record's three comparisons
  over Δ = dev_position − kin_position and h = kin_heading:
  h·Δ > 0, (h·Δ)² ≥ cos²·|Δ|², and |Δ|² ≤ reach².
- **ob1:** the selection also requires that the footprint was off `r` at the previous
  observation. The obligation is `¬rel_occupies subject r` at every selected (d, r). Per rule 3c,
  the obligation repeats the whole selection under `forallDevice`/`forallRegion`.
- **"At the previous observation":** the only operator that reads the previous observation is
  `rises`, so I wrote it with that: ¬prev(P) ≡ rises(P) ∨ (¬P ∧ ¬rises(¬P)), and
  prev(P) ≡ rises(¬P) ∨ (P ∧ ¬rises(P)). These are exact identities, not narrowings.
- **e1/e2 (borrowing ref2's words):** `since (¬ on any sidewalk) (lawful step)`. A lawful step is
  an observation where all of these hold:
  - the subject occupies a roadway or lane r2;
  - it occupied a sidewalk at the previous observation;
  - some pedestrian head d2 governs r2, shows walk, and is faced by the subject.

  Any later step from a sidewalk passes through an observation on the sidewalk, which ends the
  `since` run, so the step that counts is the latest one. One edge case: if the footprint is on
  both the sidewalk and the roadway at one observation, that observation and the next can both
  count as "the step".
- **r:** seven compositions are `¬ruleApplies id [("subject","subject")]`. The two
  LVMC_11_46_030 compositions are `¬existsUser v (ruleApplies o1 [("subject","v")] ∨ ruleApplies o2 [("subject","v")])`.
- **Narrowings:** none of my own.

## Witnesses
- **Window:** the rule reads the previous observation, so every witness sets `window` to the
  instants after the first.
- **Planned witnesses:**
  - `forbid` → violated
  - `permit` → compliant
  - `idle` (head shows walk) → not applicable
  - `blind` (dev.pedestrian_signal masked) → unknown
  - `branch_1` (divided crossing: entered the first roadway on walk, then steps onto the second
    roadway during flashing) → not applicable
- **Added witnesses**, so the lane copy of each roadway/lane quantifier is exercised:
  - `branch_2`: the head governs only the lanes → violated
  - `branch_3`: as branch_1, but the lawful entry is onto lanes → not applicable
- **Crosswalks:** every crossing scene includes a marked crosswalk. This is so the composed
  pedestrian-crossing rules are not engaged by crossing outside a crosswalk.

## Why I finished
The gate returned `OK` on the first run.
