# NRS_484B_450_1o — task result

## Final verdict: OK

Gate output: `OK — 16 witnesses, 23 names, composes nothing`.

## Gate runs
1. **OK** on the first run. Nothing was changed afterwards.

Before that run I tried to call the gate with an extra `--help` flag. The permission layer denied the call, so it never ran and used no gate budget.

## How the rule is written
- **Subject class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s9):** the rule applies when either:
  - a `regulatory_sign` with code no_stopping, no_standing or no_parking has conditions that hold for the subject (`prim_conditions_hold`) and governs (`dev_governs`) a `travel_region` the subject occupies (`rel_occupies`); or
  - the subject occupies a `curb_zone` of kind no_stopping or no_parking.
- **Obligation (s2):** `not prohibitedHalt or excused`.
  - `prohibitedHalt` repeats each place selection from the applicability in full and pairs it with the halt it forbids:
    - no_stopping (sign or curb) → `drv_motion_complete_halt`
    - no_standing → `drv_motion_parked` with `p.standing_min_duration`
    - no_parking (sign or curb) → `drv_motion_parked` with `p.parking_min_duration`
  - **Queue exception (s3/s4):** some road user that is not the subject, belongs to `DEF-NRS-484A-285::traffic`, is ahead of the subject in the same lane (`rel_ahead_behind_in_lane o subject`), with `rel_surface_gap` (the distance, no component selected) ≤ `p.queue_halt_gap`.
  - **Device exceptions (s5/s7):** a stop sign; a yield sign; a traffic signal showing circular_red, red_arrow (any direction) or flashing_red; or a railway signal or gate with lights flashing or the gate lowering or down. Each must govern a travel region the subject occupies.
  - **Police exception (s6):** a `human_direction` with role police_officer and indication stop, governing a travel region the subject occupies.

## Choices the node left open
- **Where the exceptions go:** in the obligation, as the record words it ("unless at that observation one of the exceptions holds"). A halt an exception excuses is compliant, which matches the planned verdict for branch_4.
- **Overlapping exceptions:** exception (b) (s5) is a subset of (d) (s7), so I wrote the combined set once. That way no leaf duplicates another. This is not a narrowing.
- **red_arrow(dir):** written once for each of the four directions, since the record says "a red_arrow" without a direction.
- **Narrowings:** I declared none of my own beyond the record's.

## Witnesses
- The 8 planned scenarios have their planned verdicts. Scenarios that look back over the parking or standing window name the instants that window covers.
- I added these branch witnesses:
  - branch_5: no_standing sign, at rest 120 s → violated
  - branch_6: no_stopping curb zone, 2 s halt → violated
  - branch_7 to branch_12: a no_stopping sign and a halt, each excused by one device → compliant. The devices are a stop sign, a yield sign, a red signal, railway lights flashing, a railway gate down, and a police stop.
- `blind` is `forbid` with `kin.speed` masked through `Build.masked`.

## Why I finished
The gate returned OK on the first run.
