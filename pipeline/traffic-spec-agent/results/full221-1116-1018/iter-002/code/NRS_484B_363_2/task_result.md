# NRS_484B_363_2 — task result

**Final verdict: OK** (13 witnesses, 12 names, composes nothing).

## Gate runs
1. By mistake, I ran the gate command with a pipe added (`| head -0; true`). That was not the
   command as written, and it may have used one run. The output was discarded and nothing changed.
2. I then ran the plain command by mistake, before any edit: `UNUSED_CLAIM` on every claimed
   name, as expected for the untouched skeleton.
3. After writing the rule and 13 witnesses: **OK**.

## How the rule is written
- Class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: `∃ r : travel_region` with `rel_occupies subject r`, and `∃ z : zone_sign` with
  `dev_governs z r`, `dev_zone_sign_kind z school_crossing` and `¬ dev_zone_sign_end z`. Inside
  that scope:
  `¬ (a ∨ b ∨ c ∨ d)`, where
  - (a) `¬ asm.school_in_session_day`
  - (b) `asm.school_outside_operation_margin`
  - (c) some beacon governing r that is not inoperative, `asm.pupils_in_class`, and every beacon
    governing r that is not inoperative is not flashing
  - (d) no beacon governing r that is not inoperative, and `¬ prim_conditions_hold z subject`

  This follows the record's applicability text exactly. When several pairs (z, r) qualify, the
  duty applies if it applies for any one of them.
- Obligation: `kin_speed subject ≤ Units.mph 25`.

## Choices left open
None that needed a narrowing: the record's applicability sets out each exception's structure.
`narrowings` stays empty.

## Witnesses
These are the 8 planned scenarios plus 5 extra branches:
- `branch_5`: not in session → not applicable
- `branch_6`: pupils not in class with an operational beacon that is not flashing → violated
- `branch_7`: inoperative beacon while the sign's conditions hold → violated
- `branch_8`: end sign → not applicable
- `branch_9`: a flashing beacon governs only another lane → not applicable

## Why I finished
The gate returned OK.
