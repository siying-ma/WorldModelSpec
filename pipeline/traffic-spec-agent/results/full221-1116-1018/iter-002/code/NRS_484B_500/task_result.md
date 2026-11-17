# NRS_484B_500 — task result

**Final verdict: OK** (20 witnesses, 23 names, composes nothing)

## Gate runs
1. `OK` — first run, on the rule and witnesses as written below. Nothing changed after it.

(Process note: before the first gate run I made two shell calls that were not the gate command. The first was a no-op `echo`. The second, a gate invocation with extra flags, was denied by the sandbox. Neither one ran the gate or changed any file.)

## How the rule is written
- **Class:** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **s1 + s3 (applicability):** there is a travel region `r` that the subject occupies (`rel_occupies`) and that is governed (`dev_governs`) by one of two designating devices, whose conditions hold for the subject (`prim_conditions_hold d subject`):
  - a `zone_sign` of kind `hazardous_place` with `dev_zone_sign_end` false, or
  - a `regulatory_sign` of code `no_stopping`.
- **s2 (obligation):** for every region selected the same way, the subject must not be halted (`drv_motion_complete_halt subject [p.halt_speed_tolerance]`), with two exceptions:
  - **(a) queue:** some other road user `o` (`not same o subject`) is ahead of the subject in the same lane (`rel_ahead_behind_in_lane o subject`), and `rel_surface_gap subject o` (read as the distance) is at most `p.queue_halt_gap`.
  - **(b) device or officer:** some travel region the subject occupies is governed by one of:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing `circular_red`, `circular_yellow`, `flashing_red`, `red_arrow(*)` or `yellow_arrow(*)`;
    - a railway signal or gate with lights flashing or gate not up;
    - a `police_officer` giving the indication `stop`.

## Choices the node left open
None beyond the record. No narrowing was declared. The arrow indications are listed for all four directions, because the record says "a red arrow, a yellow arrow".

## Witnesses
- **Planned:** forbid, permit, idle, blind (`kin.speed` masked), branch_1 (queue within the gap), branch_2 (no-stopping sign plus a red signal).
- **Added, to exercise every leaf:**
  - branch_3: stop sign
  - branch_4: yield sign
  - branch_5: railway lights flashing
  - branch_6: railway gate down
  - branch_7: police officer
  - branch_8: zone end sign → N/A
  - branch_9: legend restricted to trucks → N/A
  - branch_10: car ahead beyond the queue gap → violated
  - branch_11: signal showing green → violated
  - branch_12: railway lights dark and gate up → violated
  - branch_13: school zone sign → N/A
  - branch_14: no_parking sign → N/A
  - branch_15: stop sign governing only the adjacent lane → violated
  - branch_16: car in the adjacent lane, not ahead in the subject's lane → violated

## Why I finished
The gate returned OK on the first run.
