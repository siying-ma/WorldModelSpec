# NRS_484B_283_1d4_o1 — task result

**Final verdict: OK** (7 witnesses, 12 names; composes the 9 exception rules).

## Gate runs (4 of 6)

1. `UNUSED_CLAIM` — run on the untouched skeleton by mistake, before any formula was written. Lists every claimed atom as unused, as expected.
2. `UNCLAIMED_ATOM st_travel_region` — I had quantified over `travel_region` and held the region to `st_roadway ∨ st_lane`. The gate counts a quantifier kind as a claimed atom. Fix: one region quantifier per named kind, `roadway` and `lane`, joined by `or` for "exists" and `and` for "for all". The redundant kind atoms were dropped.
3. `WITNESS_FAIL` — `forbid` and `blind` came back unknown for `absent_atom:st_lane_direction`. A composed exception rule reads the lane direction of the roadway the pedestrian occupies, and my roadway had none. Fix (witness only): the crossed carriageway got `lane.direction = east`, and a marked crosswalk was laid over the crossing, as at a normal signalised crossing.
4. `OK`.

Two other things happened during the session:
- One stray shell command (`gate --help`) was denied by the permission system and did not run. It cost no gate run.
- I read `Core/Language/Semantics.lean`, `Core/Foundations/Temporal.lean`, `Core/Evidence/Builders.lean` and the top of `Core/Vocab/World.lean`. I needed them for the semantics of `since`, `rises` and vector components, for masking and `window`, and for the id types.

## How the record is written

- **s1 / class:** `ru_aggregate(subject, "DEF-NRS-484A-165::pedestrian")`.
- **c0 + t:** some `pedestrian_signal` head `d` in state `dont_walk_steady`, plus a roadway or lane `r` with `dev_governs d r`.
- **Facing:** the subject faces `d`, using the record's own inequalities. With Δ = `dev_position(d) − kin_position(subject)` (x and y components) and h = `kin_heading`:
  - h·Δ > 0
  - (h·Δ)² ≥ cos²·|Δ|²
  - |Δ|² ≤ reach²
- **"Did not overlap r at the previous observation":** Core has no previous-value operator, so this uses `rises` only: `rises(occ) ∨ (¬occ ∧ ¬rises(¬occ))`. When both values are known this is exactly "occ was false at the previous observation".
- **ob1 / obligation:** for every pedestrian head and every roadway and lane, the record's whole selection (governs, steady, faces, not overlapping before) implies `¬rel_occupies(subject, r)` now. This follows rule 3c: the obligation repeats the selection rather than relying on a shared variable name.
- **s2 + e1 + e2 (ref2 borrowed, nothing composed):** `since(¬onSidewalk, lawfulEntry) ∧ ru_aggregate(subject)`.
  - `onSidewalk` = the subject overlaps some sidewalk.
  - `lawfulEntry` = `rises(¬onSidewalk)`, while the subject overlaps a roadway or lane `r2`, which is governed by a pedestrian head `d2` that shows `walk` or (`dont_walk_flashing` ∧ countdown), and the subject faces `d2`.
  - `since` includes the entry observation itself, so the latest such step with no sidewalk overlapped since is what excepts the subject.
- **r (compositions):** each composed rule is written as `.not (.ruleApplies id [("subject","subject")])`. The LVMC_11_46_030 pair, whose binder is a vehicle `v`, sits under `existsUser "v"`.
- **Choices the node left open:** only two, both in the writing, not the reading:
  - the `rises` form of "previous observation";
  - the squared form of the facing test.
  
  Neither narrows any span, so `narrowings` is empty.

## Witnesses

Each witness names its instants from the second observation onward (`window`), because the rule looks back one observation.

- **Planned:** `forbid`, `permit`, `idle`, `blind` (masks `dev.pedestrian_signal`), and `branch_1` (entered under flashing-with-countdown, crosses the median, steps onto the second roadway under steady → not applicable).
- **Added:**
  - `branch_2` (violated): the governed region is a lane, which exercises the lane quantifiers of the applicability and obligation.
  - `branch_3` (not applicable): entry onto a lane under `walk`, which exercises the `walk` limb and the lane quantifier of the exception.

## Why I finished

The gate returned OK. Nothing in the node looked wrong.
