# NRS_484B_510 — task result

**Final verdict: OK** (13 witnesses, 27 names, composes nothing, 1 coder narrowing).

## Gate runs
1. `WITNESS_FAIL` — the rule had been written but the witnesses were still the harness's empty
   skeletons. I ran the gate too early by mistake. The rule built and passed the static checks.
   The six skeleton witnesses failed because their scenes had no track 1. After this run I wrote
   all the scenes.
2. `OK` — with the 6 planned witnesses plus `branch_3` … `branch_9`.

(An extra shell command I tried, separate from the gate, was denied by the session's permissions.
It was not run and changed nothing.)

## How the rule is written
- Subject: `ru_aggregate subject DEF-NRS-484A-320::vehicle`.
- Applicability (s3): some `curb_zone` z of kind `restricted_parking` that the subject occupies.
- Obligation: for every such z, selected the same way again (s7), the subject is not halted
  (`drv_motion_complete_halt`, p.halt_speed_tolerance), unless one of these holds:
  - (a) another road user is ahead in the same lane (`rel_ahead_behind_in_lane q subject`) with a
    surface gap ≤ p.queue_halt_gap;
  - (b) a travel region the subject occupies is governed by a stop sign, a yield sign, a red or
    yellow signal or flashing_red, a railway signal with lights flashing or a gate not up, or a
    police officer indicating stop;
  - (c) the conditions of a parking_restricted zone sign that governs an occupied travel region
    hold for the subject (`prim_conditions_hold`);
  - (d) all of the following:
    - the subject is not a truck or a trailer/combination;
    - it is not parked (`drv_motion_parked`, p.standing_min_duration);
    - a door is open at some observation of the same halt. This is written as
      `since halt (halt ∧ door) ∨ until halt (halt ∧ door)`;
    - `¬ since halt (halt ∧ W)`, where W is a vehicle other than the subject that does not occupy
      z, is halted, is within p.zone_entry_wait_reach of z by `st_region_geometry_distance`, and
      meets the conditions of a parking_restricted sign governing an occupied travel region.

## Choices the node left open
- **s1, signal indications (declared narrowing, kind `reading`).** I read "a red or yellow
  indication" as `circular_red`, `circular_yellow`, `red_arrow(*)` and `yellow_arrow(*)`, plus
  `flashing_red`. `flashing_yellow` and `flashing_yellow_arrow` are not read, because they are
  cautionary and do not require a halt.
- **s1, "gate not up".** I wrote this as gate ∈ {lowering, down, raising}. A device whose gate is
  `none` has no gate, so it cannot have a gate that is not up. I did not declare this as a
  narrowing because it is what the element's words say ("a gate not up"); the header records it.
- **"At some observation of the same halt".** I wrote this as the run of halted observations
  through the judged one, using `since` and `until` over `halt`. Either end of the trace is
  unknown, as Core's finite-trace policy requires.

## Witness notes
- The brief-halt scenes (`blind`, `branch_1`, `branch_2`) start with the subject moving. This
  decides the `since` searches and the look-back for `parked`.
- In `blind` and `branch_1` the subject is also moving at the last observation, which decides the
  `until`. So `blind` is unknown only because `sig.door_open` is unobserved.
- `branch_1` has the door open only at the middle observation of the halt. That way both the
  `since` and the `until` branch decide a verdict.

## Why I finished
The gate returned OK.
