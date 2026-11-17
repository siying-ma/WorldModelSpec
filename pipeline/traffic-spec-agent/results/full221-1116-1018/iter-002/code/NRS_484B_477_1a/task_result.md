# NRS_484B_477_1a — task result

**Final verdict: OK** (12 witnesses, 14 names, composes nothing)

## Gate runs
1. OK — first run. Rule and witnesses written in one pass; nothing changed after it.

(One stray non-gate shell command, `echo skip`, was issued by mistake before the gate run; it changed nothing.)

## The rule
- Class: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability (a1, a4, a5): some region of kind `alley` the subject occupies (`rel_occupies`), `asm.business_district`, and not `asm.local_alley_ordinance`.
- Obligation (a3, a6): `not (complete_halt ∧ parked ∧ ¬(deviceHalt ∨ queueHalt))`.
  - `complete_halt` takes `p.halt_speed_tolerance`, and `parked` takes `p.halt_speed_tolerance` and `p.parking_min_duration`.
  - `deviceHalt`: the subject occupies a `travel_region` that a device of kind traffic_signal, stop_sign, yield_sign, railway_signal_or_gate or human_direction governs (`dev_governs`).
  - `queueHalt`: some road user `other` with `rel_ahead_behind_in_lane other subject` (the other vehicle is ahead of the subject) and `rel_surface_gap subject other ≤ p.queue_halt_gap`.

## Choices the node left open
- **Surface gap:** I read it as the distance between the bodies (the two-argument form, with no component), which matches the record's "gap between bodies". I declared no narrowing.
- **Direction of `rel_ahead_behind_in_lane`:** the argument order follows Core's accessor: `a` is ahead of `b`.
- **`complete_halt` as its own conjunct:** I wrote it next to `parked`, even though `parked` already implies it, because the node claims it separately in span a3.

## Witnesses
The scenes are 10 s apart over 0–240 s, and every witness judges 220–240 s. The witnesses are the six the plan names plus six more:
- forbid, permit, idle, blind and branch_1, as planned.
- branch_2: a queue with a 2 m gap; compliant.
- branch_3: the vehicle ahead is 10 m away; violated. This tests the surface-gap leaf.
- branch_4 to branch_8: one witness per device kind, each governing the lane; compliant.

## Why I finished
The gate returned OK on the first run.
