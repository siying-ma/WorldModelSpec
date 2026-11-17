# NRS_484B_307_12a — task result

## Final verdict: OK (10 witnesses, 12 names, composes nothing)

## Gate runs
1. **UNANCHORED_VARIABLE** (`l`, `h`, `d`). The device `d` with the green arrow was tied to the subject only by the s6 facing comparison (dev_position − kin_position)·kin_heading > 0, which put every read on one side against a zero literal.
   Change: I rewrote the comparison as the equivalent `dev_position·heading > kin_position·heading`.
2. **UNANCHORED_VARIABLE** (same three variables). The gate does not count a comparison as an anchor in either form, even though the surface says "a comparison that reads both" counts.
   Change: I tied the highway `h` to the subject with the claimed anchoring atom `rel_occupies(subject, h)`. That anchors `h`, then `l` through `st_on_way`, then `d` through `dev_governs`.
3. **OK**.

## Choices
- **The s6 facing test** is written as the record states it: the head's projection on the subject's heading is greater than the subject's own projection. This is algebraically the same as the dot product being above zero.
- **Anchoring (s1)**: the highway whose lanes carry the green arrow is the highway the subject occupies, via `rel_occupies(subject, h)` (`rel.occupies` is claimed under s7). This is the only addition to the record's wording. A driver who faces a head over a lane of a highway and drives in a signalled lane of it is on that highway, so the situation the record describes already includes this condition. Trigger spans may not be narrowed, so I did not declare it as a narrowing; it is explained in the rule header.
  - **Plan agent:** if this tie should be explicit, state it in the s1 element. Alternatively, Core/gate could accept the s6 comparison as an anchor, as the surface text implies.
- **Applicability**: the green-arrow lane exists, the subject drives in a signalled lane, and the subject is not at a complete halt.
  - The green-arrow lane: some lane `l` on highway `h` (the one the subject occupies) is governed by a lane-control signal `d` that shows `green_down_arrow` and faces the subject.
  - The signalled lane: some lane `l2` the subject occupies, governed by a lane-control signal `d2` that is not `dark` and faces the subject.
  - The halt test: `drv_motion_complete_halt(subject; p.halt_speed_tolerance)` does not hold.
- **Obligation**: for every lane `l2` and lane-control signal `d2` that meet the same selection (occupied while moving, governed, not dark, facing), `d2` shows `green_down_arrow`.
- **Narrowings**: none of mine.

## Witnesses
- **Layout**: highway 10, two eastbound lanes (11 and 12) lying on it, heads 21 and 22. The vehicle moves at 15 m/s at x = 20, 35 and 50 m.
- **Planned scenarios**:
  - **forbid** (violated): yellow X over the vehicle's lane, green arrow over the adjacent lane, both ahead.
  - **permit** (compliant): the vehicle is in the green lane.
  - **idle** (not applicable): no devices.
  - **blind** (unknown): the forbid scene with `dev.lane_control_signal` masked.
  - **branch_1** (not applicable): every head shows red X.
- **Added branches**, all expecting not applicable:
  - **branch_2**: the head over the vehicle's lane is dark (exercises the not-dark test).
  - **branch_3**: the yellow-X head over the vehicle's lane is behind it (exercises facing for `d2`).
  - **branch_4**: the only green arrow is behind the vehicle (exercises facing for `d`).
  - **branch_5**: the vehicle is stopped (exercises the halt test).
  - **branch_6**: the lanes lie on no highway (exercises `st_on_way` / `st_highway`).

## Why I finished
The gate returned OK on run 3 of 6.
