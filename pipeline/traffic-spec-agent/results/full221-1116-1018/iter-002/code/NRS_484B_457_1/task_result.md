# NRS_484B_457_1 — task result

**Final verdict: OK** (13 witnesses, 27 names, composes nothing).

## Gate runs
1. `OK` on the first run. Nothing changed after it.

(Before the first gate run, one extra shell command was attempted by mistake: the gate command with
`--help` piped to `head`. The sandbox denied it and it never ran.)

## How the node is written
- **Class (s2):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability:** this is a conjunction of four parts:
  - **s3, halt:** `drv_motion_complete_halt` with `p.halt_speed_tolerance`.
  - **s4 + s5, curbed highway:** some highway `h` the subject occupies, on which (`st_on_way`) some lane has a left or right side marked type curb.
  - **s3, not held by control:** no travel region the subject occupies is governed by a device of any of the five kinds. There is one `existsDevice` quantifier per kind: traffic signal, stop sign, yield sign, railway signal/gate, human direction.
  - **s3, not queued:** no member of `DEF-NRS-484A-285::traffic` is ahead of the subject in its lane (`rel_ahead_behind_in_lane o subject`) with the body gap (`rel_surface_gap`, distance form) at or below `p.queue_halt_gap`.
- **Obligation:** the obligation selects `h` again with the applicability's whole selection (rule 3c), then requires one of three limbs:
  - **Right curb (s6):** an occupied travel region on `h`; heading·direction ≥ `p.parked_heading_cos`; a road edge on `h` with lateral offset < 0 and body distance ≤ `Units.inches 18`.
  - **Left curb (s7/s8):** `asm.left_curb_parking_permitted`; an occupied one-way roadway on `h`; the same parallel test; a road edge on `h` with offset > 0 and body distance ≤ 18 in.
  - **Angle parking (s9):** an occupied travel region governed by a regulatory sign with code `angle_parking` whose conditions hold (`prim_conditions_hold`), or an occupied parking space with |angle| > `p.parking_space_angle_resolution`.

## Choices the node left open
- **Curb marking:** I used the side/type form of `st_lane_marking`, which leaves the colour unconstrained because the words state none. Either side counts, since the record says "a side whose marking type is curb".
- **Parking-space angle:** I compared the absolute value of the angle with the resolution. The element says the angle "stands clear of zero", so a negative mapped angle still counts as angled. This is not narrower than the record, so I declared no narrowing.
- **The subject in the queue test:** I wrote no exclusion of the subject itself, because `rel_ahead_behind_in_lane` is decided false for a road user against itself.
- **Narrowings:** none declared.

## Witnesses
- **Planned:** all eight planned witnesses are built with the planned verdicts.
- **Added:** I added `branch_5`–`branch_8` (`not_applicable`), one each for a halt in a lane governed by a stop sign, a yield sign, a railway gate and a flagger. I also added `branch_9` (`compliant`) for an unconditional angle-parking sign governing the occupied lane. Without these, the device-kind and angle-sign leaves would have no witness that moves them.

## Why I finished
The gate returned OK on the first run.
