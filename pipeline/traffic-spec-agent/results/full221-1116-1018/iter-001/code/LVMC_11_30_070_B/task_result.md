# LVMC_11_30_070_B — task result

## Final verdict

`SCOPE_VIOLATION` on both runs, from the harness environment and not from these files. The rule and the witness have not been judged yet.

## Gate runs

1. `SCOPE_VIOLATION`. The "changed outside the node's files" list held only agent-runtime scratch files under
   `.runtime/tmp/claude-154266/…/tasks/*.output` and `.runtime/tmp/claude-154266/cache-break-state-*.json`.
   These are the shell-output files of this session and of the concurrent coding sessions
   (LVMC_11_18_020, LVMC_11_30_050, LVMC_11_40_130, LVMC_11_43_010_B_o1). One of them is the output
   file of the gate command itself (`…LVMC-11-30-070-B/…/tasks/blv7wbr2o.output`). I wrote nothing
   outside the two node files and this report.
2. I re-ran the gate with no change. The verdict was the same, and this session's own entry was now
   the new gate command's output file (`blod26iaf.output`). Every gate invocation writes such a file,
   so the scope check can never pass from inside a session. That is an infrastructure fault in the
   scope filter: it should ignore `.runtime/tmp/`. I stopped there and kept the remaining 4 runs
   rather than spend them on a check I cannot influence. The harness re-runs the gate after the
   session ends, and that run should judge the files themselves.

## What was written

**Rule** (`library/TrafficSpec/Rules/LVMC_11/LVMC_11_30_070_B.lean`)
- Class: `ru_aggregate subject "DEF-NRS-484A-165::pedestrian"`.
- Applicability: `asm.business_district` ∧ ∃ roadway `rw`, `rel_occupies subject rw`.
- Obligation: `crossing → inCrosswalk`, where:
  - `crossing` = ∃ lane `ln` (`rel_occupies subject ln` ∧ `drv_motion_moving_across_carrier subject ln [p.halt_speed_tolerance, p.crossing_motion_cos]`) ∨ the same over a region of kind roadway.
  - `inCrosswalk` = ∃ crosswalk `cw`, `rel_occupies subject cw`.
  - The marked attribute is not read, so marked and unmarked crosswalks both satisfy it.
- Declarations are left as the skeleton wrote them. No narrowing: the s2 reading is the record's own.

**Witnesses** (`library/TrafficSpecWitness/LVMC_11/LVMC_11_30_070_B.lean`)
- Setting: a two-way roadway with an eastbound and a westbound lane, plus a sidewalk. The pedestrian
  walks north at 1.4 m/s, so the cosine against the lane direction is 0 against the reading's 0.94,
  and the speed is well above the 0.1 m/s tolerance.
- forbid: violated, with the crosswalk 30 m away.
- permit: compliant, inside a marked crosswalk.
- idle: not applicable, walking along the sidewalk.
- blind: unknown, with `kin.velocity` masked.
- branch_1: compliant, inside an unmarked crosswalk at an intersection.
- branch_2: not applicable, with `asm.business_district` false.
- branch_3 (added): violated. It uses an unlaned roadway that carries its own direction, so the roadway-carrier disjunct also decides one witness. In the other scenes the roadway has no direction and only the lane disjunct decides.

## Choices the node left open

- Whether to repeat "occupies a roadway" in the obligation's antecedent. I did not: the applicability
  already requires it at the judged observation, and the antecedent occupancy is the record's
  "lane or roadway it occupies".

## Why I finished

The gate returns `SCOPE_VIOLATION` because of runtime temporary files that the gate invocation
itself creates. Neither file edit can fix that, so further runs would only spend budget. Fixing it
requires excluding `.runtime/tmp/` from the harness's scope check.
