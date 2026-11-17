# LVMC_11_30_060_A — task result

## Final verdict

`SCOPE_VIOLATION` on both gate runs. The gate never judged my files. It flagged only files under
`.runtime/tmp/claude-154266/…`: the agent runtime's own task-output files (`tasks/*.output`) and
`cache-break-state-*.json`. Some belong to this session and some to concurrent sessions
(LVMC_11_18_020, LVMC_11_30_050, LVMC_11_43_010_B-o1). I did not write any of them. They appear
whenever the runtime runs a shell command, and running the gate is itself a shell command, so
running it again cannot clear the verdict. I would call this an infrastructure fault rather than a
verdict on the node, and I stopped after 2 of the 6 runs so the harness's own re-run can judge the
files as they are now.

## Gate runs

1. Skeleton, unchanged: `SCOPE_VIOLATION`. The flagged paths were runtime tmp files, as above.
2. After writing the rule and the witnesses: `SCOPE_VIOLATION`. The flagged list had grown with
   other sessions' tmp files and this run's own output file. Nothing in the node's files was flagged.

## What was written

Rule (`TrafficSpec.Rules.LVMC_11_30_060_A`):
- Class: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- Applicability: there is a roadway `r` (`existsRegion "roadway"`) where:
  - the subject occupies `r`;
  - the subject moves across a carrier it occupies (`drv_motion_moving_across_carrier` with
    `p.halt_speed_tolerance` and `p.crossing_motion_cos`). The carrier is either `r` itself or a
    lane `k` that the subject occupies (`existsRegion "lane"`).
  - no `regulatory_sign` with code `pedestrians_prohibited` governs `r` (`dev_governs`).

  The whole applicability also requires that the subject occupies no `crosswalk`.
- Obligation: for every user `v` that is a member of `DEF-NRS-484A-320::vehicle` and occupies a
  roadway `r`, where `r` is re-bound with the same selection (occupied and crossed by the subject),
  both of these hold:
  - the subject is not in contact with `v` (`rel_contact`);
  - it is not the case that the subject's `kin_speed` is above `p.halt_speed_tolerance` while
    `prim_closest_approach_within(p.conflict_horizon)` holds and
    `prim_closest_approach_distance(p.conflict_horizon)` is below `p.conflict_centre_clearance`.
- The f8 exception sits inside f2's roadway quantifier, so it applies to the same roadway `r`.
- I declared no narrowings of my own. The carrier being "lane or the roadway" is the record's own
  wording.

Witnesses: `forbid`, `permit`, `idle`, `blind` (masks `kin.velocity`) and `branch_1`, as planned. I
added three more:
- `branch_2` (violated): an unlaned roadway that has its own direction. It exercises the roadway
  limb of the carrier choice.
- `branch_3` (violated): the car's rear clips the pedestrian while their centres are already moving
  apart. It exercises `rel_contact`.
- `branch_4` (not applicable): a `pedestrians_prohibited` sign governs the roadway. It exercises f8.

None of these witnesses has been checked by the gate.

## Choices the node left open

- The carrier `k` is written as `r` itself, or any lane the subject occupies. I did not require the
  lane to lie within `r`, because the record does not say so.
- The obligation's re-bound roadway repeats f2's selection (occupies plus moving across a carrier).
  It does not include the f8 sign condition, because the record defines the selection as "the
  roadway the subject occupies and crosses".

## Why I finished

The gate rejects the run with `SCOPE_VIOLATION`. It cites only files the agent runtime writes under
`.runtime/tmp`, outside my two files and outside my control. Every gate invocation adds another
such file, so spending the rest of the budget could not produce a judgment on the node. The
operator should exclude `.runtime/tmp/**` from the gate's scope check, or move the runtime tmp
directory out of the tracked tree, and then re-run the gate.
