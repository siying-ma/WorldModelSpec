# NRS_484B_450_1m — task result

## Final verdict: OK (18 witnesses, 18 names, composes nothing)

## Gate runs
1. `OK` — first run, on the files as first written (after one type-cast fix in the permit trace's
   position, `(k : Int)`, made before running). No further changes.

Note: before the first gate run I mistakenly issued one malformed shell command (the gate
command with an extra `--help` and a pipe); it was denied by the permission layer and never ran.
It did not count as a gate run.

## How the rule is written
- Binder class (s1): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (s9, s10): `∃ e : elevated_structure. rel_occupies subject e`.
- Obligation (s2): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`, or one of the
  exceptions below holds:
  - (a) s3/s4, the operationalization: `∃ o ≠ subject`, `ru_aggregate o "DEF-NRS-484A-285::traffic"`,
    `rel_ahead_behind_in_lane o subject` (o is ahead), `rel_surface_gap(subject, o) ≤ p.queue_halt_gap`.
    The gap is read as the distance, with no longitudinal or lateral component.
  - (b)/(c)/(d) s5–s7: `∃ r : travel_region` with `rel_occupies subject r`, governed (`dev_governs`)
    by one of these: a stop sign; a yield sign; a traffic signal showing circular_red,
    red_arrow(left/right/straight/u_turn) or flashing_red; a railway signal or gate with lights
    flashing or gate lowering/down; or a human direction with role police_officer and indication stop.

## Choices the node left open
- The record's exception (b) is a subset of (d). I wrote the union once, under one travel-region
  quantifier, rather than repeating the stop sign and red signal. Writing them twice would leave
  duplicate leaves that no witness can separate. This changes nothing about what the record says.
- I put the exceptions in the obligation, as the record's obligation text does. An excused halt
  is therefore compliant, not not_applicable, which matches the planned `branch_1` verdict.
- `red_arrow` covers all four arrow directions, because the record says "a red_arrow".
- No narrowings: every choice above is within the record's own wording.

## Witnesses added beyond the plan
- branch_3: the vehicle ahead is beyond the queue gap (violated).
- branch_4 and branch_5: a stop sign on the subject's lane (compliant) and on the other lane only (violated).
- branch_6: a yield sign (compliant).
- branch_7 and branch_8: a red signal (compliant) and a green signal (violated).
- branch_9, branch_10 and branch_11: rail lights flashing (compliant), gate down (compliant), and dark lights with the gate up (violated).
- branch_12, branch_13 and branch_14: a police officer signalling stop (compliant), a police officer signalling proceed (violated), and a flagger signalling stop (violated).

## Why I finished
The gate returned OK on the first run.
