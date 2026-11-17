# NRS_484B_363_4 — task result

**Final verdict: OK** (`20 witnesses, 17 names, composes nothing`), on gate run 6 of 6.

## Gate runs

1. **UNUSED_CLAIM.** This run was a mistake: I ran the gate on the untouched skeleton by accident, before editing anything. Its list of unused claims confirmed that U must use the `rel_bearing`, `rel_longitudinal_overlap` and `rel_same_direction` atoms.
2. **WITNESS_FAIL**, on `blind`: expected unknown, got violated. Masking `rel.longitudinal_overlap` does not hide a value Core computes from the footprints (`Runtime/Manifest.lean`, `Mask.scene`: a computed relation is blanked only when its kinematics are absent too).
   - Fix: in `blind`, the source no longer reports the other vehicle's extent, so the overlap can be neither measured nor computed.
3. **WITNESS_FAIL** again, unchanged files. This run was also a mistake: a placeholder command I had not meant to run reached the gate. It used up a budgeted run.
4. **WITNESS_FAIL**, on `blind`: admission rejects a track whose occupancy is observed but whose footprint is undefined.
   - Fix: the subject keeps its extent and its observed occupancy. The other vehicle has no extent and no observed occupancy (the rule never reads its occupancy).
5. **VACUOUS**: obligation leaves `dev_governs bc r` and `asm.pupils_in_class` (the obligation's copy of exception (c)).
   - Fix: added two violated witnesses in which (c) fails on just one of those limbs:
     - `branch_5`: pupils not in class.
     - `branch_6`: the beacon governs only the adjacent lane.
6. **OK.**

Two of the six runs were wasted by my own mistakes (runs 1 and 3).

## How the rule is written

- **Binder `subject`:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **The other vehicle `b` (s2):** quantified as `existsUser` / `forallUser "b"`, with `ru_aggregate b vehicle` and `¬same b subject`.
  - The act is `drv_interaction_overtake_pass(subject, b; p.overtake_window, p.overtake_same_direction_cos)`.
  - "traveling" means `kin_speed b > p.halt_speed_tolerance` at `some_moment` of the pass.
- **Occasion (boundary `window`):**
  - `some_moment φ` = `¬holdsFor time W subject ¬(U ∧ φ)`.
  - `throughout φ` = `holdsFor time W subject (U → φ)`.
  - W is `p.overtake_window`.
- **U (the under-way formula), built from the under_way atoms:**
  - AA (ahead-aligned) = subject moving ∧ `rel_bearing ahead` ∧ overlap < 0 ∧ `rel_same_direction`.
  - Behind = `rel_bearing behind` ∧ overlap < 0.
  - alongside = ¬AA ∧ ¬Behind ∧ subject moving.
  - U = ¬AA ∧ `since(alongside ∨ rises Behind, AA)`.
- **s3 (`some_moment`):** `existsRegion travel_region r`, `existsDevice zone_sign z`, with `rel_occupies subject r ∧ dev_governs z r ∧ kind ∈ {school, school_crossing} ∧ ¬end`.
- **Exceptions, each `throughout` and each negated in the applicability:**
  - (a) `¬asm.school_in_session_day`.
  - (b) `asm.school_outside_operation_margin`.
  - (c) some speed limit beacon governs r and is not `dev_inoperative` ∧ `asm.pupils_in_class` ∧ every such beacon is not flashing.
  - (d) no such beacon ∧ `¬prim_conditions_hold(z, subject)`.
- **Applicability:** `existsUser b (selected b)`, or the subject is alone in a school zone (see choice 2 below).
- **Obligation:** `forallUser b (selected b → ¬overtake_pass)`. Following rule 3c, `selected b` is written out again in the obligation.

## Choices the node left open

1. **U starts one observation late.** It starts at the observation *after* the last ahead-aligned one, not at that observation itself.
   - Marking the last ahead-aligned observation requires knowing the next observation. The `holdsFor`/`since` shape cannot express that.
   - The alternative was to count every ahead-aligned observation of the approach. That would read observations from before the pass began.
   - U ends at the recognition (`rises Behind`) and is false after it.
   - The occasion witnesses switch conditions so that they read the same under either boundary. They switch at k ≤ 9 versus k ≥ 10 for "before the pass", and at k ≤ 12 versus k ≥ 13 for "first" versus "later".
   - This is recorded in the rule header, not under `narrowings`: it is a choice about the occasion, not about a span.
2. **"With no other vehicle in the scene the duty is met."** This is a second disjunct of the applicability: no other road user is a vehicle, and the subject occupies a travel region governed by a school or school_crossing zone sign that is not an end sign.
   - I kept the zone so that the s3 trigger still decides whether the rule engages.
   - Without this disjunct, `permit` would be not_applicable rather than compliant.
3. **"The subject moves" is part of U.** It is inside AA and alongside, from the under_way justification ("while the subject moves"). This also makes the `since` decided false at the first observation, where the subject is at rest. That is what keeps `blind` unknown only on the masked atom.
4. **`narrowings` is empty.** Every span is a trigger, exception or obligation span carried as mapped.

## Witnesses

- **Common setup:**
  - Instants k = 0…14 at 1 s; every witness's window is k = 11…14 (11 000–14 000 ms), where each 10 s look-back is covered.
  - The pass is under way at k = 11…14 and recognized at k = 14, with the other vehicle 7 m/s slower than the subject's 10 m/s.
- **Added beyond the plan:**
  - `branch_4` (compliant): the subject is the only vehicle, with a pedestrian beside the road.
  - `branch_5` and `branch_6` (violated): as described under run 5.
- **`blind` departs slightly from its narrative:** the other vehicle's extent and occupancy are unreported. With only the manifest mask, Core computes the overlap anyway.

## Why I finished

The gate returned OK, and the 6-run budget is now used up. The node itself raised no defect.
