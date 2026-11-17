# LVMC_11_60_040 — task result

## Final verdict
`WITNESS_FAIL` (1 of 6 gate runs used). The session stopped because the node and the reading
cannot give a decided verdict on any witness. The Lean is not the cause.

## Gate runs
1. `WITNESS_FAIL`: forbid, permit and branch_1 came out unknown, and blind was unknown for the
   wrong reason. Every one carried the same reason:
   `aggregate_unresolved:DEF-LVMC-11-02-140::taxicab`. idle passed with not_applicable.
   I changed nothing after this run (see below).

Note: at the start of the session I mistakenly ran one shell command that was not the gate (a
no-op `echo`). It touched nothing.

## What was written
- Rule (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_60_040.lean`):
  - The binder class is `ru_aggregate subject "DEF-LVMC-11-02-140::taxicab"` (s1).
  - Applicability is `ru_aggregate subject "DEF-NRS-484A-320::vehicle"` (s2, "such vehicle")
    ∧ some `highway` h with `rel_occupies subject h` (s3).
  - Obligation is `(drv_motion_complete_halt subject [tol] ∧ drv_motion_parked subject [tol, min_dur])`
    → some `curb_zone` z with `rel_occupies subject z` ∧ `st_curb_zone_kind z taxicab_stand`.
    This covers s2, s4, s5 and s7. s6 stays the node's residue.
  - No narrowings are declared, because the record left no choice open.
- Witnesses (`library/TrafficSpecWitness/LVMC_11/LVMC_11_60_040.lean`):
  - Five scenes: forbid, permit, idle, blind and branch_1. They use a highway rectangle, a
    taxicab_stand curb zone and a private lot.
  - Each witness sets `window` so that the 60 s look-back is covered.
  - The subject is track 1, with classes `[.taxicab, .motorVehicle]`.

## Why I finished — the node/reading is wrong
- **The problem:** the run's reading lists **no included class** for the aggregate
  `DEF-LVMC-11-02-140::taxicab`, and `ru.taxicab` itself is listed as *unresolved*.
- **The consequence:** by the `ru.aggregate` contract, the atom is true only for a user that
  carries an included class. So the s1 binder class can never be true. A road user can only
  make it unknown (if it carries any listed class) or false (if it carries none). No witness can
  then be violated or compliant: forbid, permit, blind and branch_1 can never pass, whatever the
  geometry.
- **Which part is at fault:** span s1, the subject class `ru.aggregate=DEF-LVMC-11-02-140::taxicab`.
  The definition reads "a motor vehicle which is properly licensed under State and local law to
  provide taxicab service".
- **What the plan agent must change**, one of these:
  1. In the reading, classify `ru.taxicab` as **included** in `DEF-LVMC-11-02-140::taxicab`. The
     `taxicab` class is the licensed-taxicab class, so its own label is the membership evidence.
  2. Re-map s1 to a claim the reading can decide, such as the `ru.taxicab` class atom, if the run's
     representation decisions allow it.

  Until then, the binder class is unknown on every scene. The rule's formulas and the witnesses
  need no change once the aggregate decides for `ru.taxicab`.
