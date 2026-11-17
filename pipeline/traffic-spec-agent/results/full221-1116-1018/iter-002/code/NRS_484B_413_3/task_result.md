# NRS_484B_413_3 — task result

## Final verdict: OK

`OK — 13 witnesses, 21 names, composes nothing`

## Gate runs (2 of 6 used)

1. **UNUSED_CLAIM** on the skeleton as the harness wrote it (I ran it once before editing, to get a baseline). Every claimed name was reported, as expected for `.tt` placeholders. After this run I wrote the rule and the witnesses.
2. **OK** with the rule and 13 witnesses (the 6 planned and 7 added branches).

## How the rule is written

- **s1/s4 (class):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **s2 (stop):** the onset of the halt is `rises (drv_motion_complete_halt subject p.halt_speed_tolerance)`. The halt counts only if it is not excused under DEF-NRS-484A-260. It is excused in two cases:
  - **Queue:** some road user `lead` (not the subject) satisfies `rel_ahead_behind_in_lane lead subject` with body gap (`rel_surface_gap`, distance form) ≤ `p.queue_halt_gap`.
  - **Device or officer:** some `travel_region` `occ` satisfies `rel_occupies subject occ` and is governed (`dev_governs d occ`) by any of these:
    - a stop sign;
    - a yield sign;
    - a traffic signal showing `circular_red`, `flashing_red` or `red_arrow(left|right|straight|u_turn)`;
    - a railway signal or gate with lights `flashing` or gate `lowering`/`down`;
    - a human direction with role `police_officer` and indication `stop`.
- **s3 (suddenly):** the node's operationalization is written as `rises (kin_accel_longitudinal subject ≤ −p.sudden_decel_min)`.
- **s6 (rear vehicle):** some `rear` (not the subject) in the aggregate DEF-NRS-484A-320::vehicle satisfies `rel_ahead_behind_in_lane subject rear` with body gap ≤ `p.rear_signal_reach`.
- **Applicability:** `((haltOnset ∧ ¬(queue ∨ device)) ∨ suddenOnset) ∧ rearVehicle`.
- **Obligation (s5):** `¬ holdsFor time p.stop_signal_lead_window subject ¬(sig_brake_lamp ∨ sig_hand_signal stop_or_slow)`. The Core window `[E − W, E]` includes E, which matches "at E or at some observation of the window behind E".

## Choices the node left open

- **Red arrow:** the record says "red_arrow" without a direction, so I wrote all four directions as disjuncts. This is a literal expansion, not a narrowing.
- **Gap form:** I used the distance form of `rel_surface_gap` (two arguments), as the contract says ("a read without a component is the distance").
- **Narrowings:** none. Every span is written as the record maps it.

## Witnesses

All 13 witnesses share one setup:

- **Road and cars:** one eastbound lane, cars 4.5 m long.
- **Frames:** 16 frames at 0.5 s, with the event at t = 4000 ms.
- **Judged range:** `window = (4000, 7500)`. The lead window [1000, 4000] ms lies inside the trace, and the frame-0 `rises` (which has no previous observation) is never judged.
- **Follower:** 15 m behind the subject, which keeps the 30 m reach by 15 m.
- **Halting deceleration:** 2 m/s², below the 3.4 m/s² threshold.

| Witness | Verdict | Scene |
|---|---|---|
| forbid | violated | Halts with no signal |
| permit | compliant | Brake lamps lit from 2 s before the halt |
| idle | not applicable | No other road user |
| blind | unknown | `sig.brake_lamp` masked in the manifest; the trace sets it false |
| branch_1 | violated | Decelerates at 6 m/s² without halting; no signal |
| branch_2 | not applicable | Stop sign governs the lane |
| branch_3 | not applicable | Yield sign governs the lane |
| branch_4 | not applicable | Traffic signal shows circular red |
| branch_5 | not applicable | Railway lights flashing, gate up |
| branch_6 | not applicable | Railway gate down, lights dark |
| branch_7 | not applicable | Police officer directing stop |
| branch_8 | not applicable | Halted car 2 m ahead (queue; the gap limit is 5 m) |
| branch_9 | compliant | Stop-or-slow arm signal from 2 s before the halt; brake lamps unlit |

## Why I finished

The gate returned OK on the second run.
