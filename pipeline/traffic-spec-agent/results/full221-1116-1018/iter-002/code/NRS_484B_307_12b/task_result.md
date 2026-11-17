# NRS_484B_307_12b — task result

**Final verdict: OK** (7 witnesses, 12 names, composes nothing)

## Gate runs
1. `UNUSED_CLAIM` (dev_governs, dev_lane_control_signal, dev_position, drv_motion_complete_halt, …):
   I ran the gate by mistake before editing, so it judged the harness skeleton with `.tt` placeholders.
   After it I wrote the rule and the witnesses.
2. `OK`.

## How the rule is written
- Class: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability: there is a lane `l` lying on a highway (`st_on_way l h`) and a lane-control signal `d`
  (`dev_lane_control_signal d`) with `dev_governs d l`, `dev_lane_control_signal_state d red_x`, and facing:
  (dev_position d − kin_position subject) · kin_heading subject > 0, written component by component.
- Obligation: for every lane `l` and lane-control signal `d`, the whole selection again (on a highway,
  governs, red_x, facing) implies `¬rises(rel_occupies subject l)` (enter) and
  `¬(rel_occupies subject l ∧ ¬drv_motion_complete_halt(subject; p.halt_speed_tolerance))` (drive in).
- No narrowings were declared. The record fixes every reading, including the at-rest case.

## Witnesses
These are on an eastbound two-lane highway, with signals 21 (over lane 1) and 22 (over lane 2) at x = 90 m.
- forbid: moves at 15 m/s from lane 1 into the red-X lane 2 → violated.
- permit: stays in lane 1 (green) while lane 2 shows red_x → compliant.
- idle: both signals show green_down_arrow → not applicable.
- blind: the same scene as forbid, with `dev.lane_control_signal` masked → unknown.
- branch_1: already in lane 2 when its signal turns red_x, and keeps going at 12 m/s → violated (drive-in limb).
- branch_2 (added): enters lane 2 and is sampled at rest from that instant on → violated by the enter limb only.
- branch_3 (added): in lane 2, 60 m past its red-X head, so the head is behind the vehicle → not applicable (facing).

## Choices left open
None beyond the scene geometry. The added branches exist so that every leaf (the enter limb and
facing) changes the result of a decided witness.

## Why I finished
The gate returned OK.
