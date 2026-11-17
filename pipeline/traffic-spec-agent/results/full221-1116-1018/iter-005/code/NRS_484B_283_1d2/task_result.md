# NRS_484B_283_1d2 — task result

**Final verdict: OK** (10 witnesses, 11 names, composes all nine exception rules).

## Gate runs
1. `UNUSED_CLAIM` — I ran this by mistake on the untouched skeleton, before writing anything. Every claimed name was unused because the formulas were still `.tt`. After this run I wrote the rule and the witnesses.
2. `OK` — this was the rule and witnesses as described below. I made no changes after it.

## How the rule is written
- **Class (s):** `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- **c0 / t:** some pedestrian head `d` (device quantifier) governs a region `r` that is a `roadway` or a `lane`, with one region quantifier per kind. The flashing countdown is written as `state = dont_walk_flashing ∧ countdown`.
- **c (latest entry, facing):** `entry = rises (rel_occupies subject r)`. `facing` is the record's test over Δ = dev_position − kin_position and h = kin_heading:
  - h·Δ > 0
  - (h·Δ)² ≥ cos²·|Δ|²
  - |Δ|² ≤ reach²

  `crossedUnderCountdown = since (flashingCountdown ∧ ¬entry) (entry ∧ flashingCountdown ∧ facing)`. This finds the latest entry, with no bound other than that entry. If the entry happened before the recording, `since` returns unknown.
- **Countdown's end:** `dont_walk_steady` here ∧ `rises (¬ crossedUnderCountdown)`. Steady here makes `crossedUnderCountdown` false here, so this conjunct says exactly that it held at the previous observation.
- **ob:** for every head and region selected the same way (the whole selection is written again in the obligation), `¬ rel_occupies subject r`.
- **r:** seven `¬ ruleApplies` with the map `subject↦subject`. The two LVMC_11_46_030 limbs are written as `¬ ∃ v. (applies o1 v ∨ applies o2 v)`.

## Choices left open
- **Narrowings:** none declared. The record's own two `ob` readings cover the countdown's end and "complete the crossing".
- **"Previous observation":** the language has no "previous" operator, so I wrote it with `rises (¬ …)`. This is exact under the semantics, so I added no narrowing.

## Witnesses
The planned scenes all use one street: a roadway with sidewalks on both sides and a marked crosswalk. The head is on the far side, 18 m ahead of where the pedestrian enters.
- **Planned:** `forbid`, `permit`, `idle`, `blind` (with `dev.pedestrian_signal` masked) and `history_boundary`.
- **Branches I added:**
  - `branch_1`: a street with only a lane, so the lane quantifier is exercised.
  - `branch_2`: the pedestrian faces away from the head.
  - `branch_3`: the pedestrian's heading is 45° off the head.
  - `branch_4`: the head is 59 m away, beyond the reach.
  - `branch_5`: the head governs a different roadway.

## Why I finished
The gate returned `OK`.
