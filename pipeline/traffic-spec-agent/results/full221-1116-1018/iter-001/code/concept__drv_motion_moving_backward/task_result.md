# drv.motion.moving_backward — task result

## Final verdict
SCOPE_VIOLATION on both runs. This is caused by the tooling, not by the concept files. The gate never judged the concept or the witnesses.

## Gate runs
1. **SCOPE_VIOLATION**: the only path reported was
   `.runtime/tmp/claude-154266/.../tasks/bg7x5ej7f.output`. That is the output-capture file the agent
   runtime writes for each shell command, and it sits inside the repository's `.runtime/tmp`. I did not
   write it and cannot remove it, because the only command I may run is the gate.
2. **SCOPE_VIOLATION** (re-run with nothing changed, to check the cause): this time the reported path was a
   different capture file, `.../tasks/b6sic3dug.output`, created by that run's own command. So every gate
   run started from this session creates a new out-of-scope file and gets the same verdict. That is why I
   stopped instead of using the remaining four runs.

The two concept files are the only files I edited (plus this report). The harness should re-run the gate
from outside the session, ignore `.runtime/tmp`, or move the agent's tmp directory out of the worktree.

## What was written
- **Body**: `(vx·hx + vy·hy) < −speed_tol`. The velocity and heading x/y components are read as
  `Term.measure "kin_velocity" [a, "x"|"y"]` and `Term.measure "kin_heading" [a, "x"|"y"]`. The evaluator
  normalises the heading, as the contract states (`Semantics.evalMeasure`). The comparison is strict, so a
  component of exactly −speed_tol is not denoted ("at or below speed_tol" is excluded). If the velocity or
  heading field is `none`, the result is unknown.
- **Witness**: speed_tol = 0.1 m/s. One car (track 1) heading east, three scenes 1 s apart.
  - holds: velocity (−1.5, 0), position moving west.
  - fails: velocity (2.0, 0.1), position moving to match.
  - blind: like holds, but velocity is `none` and `kin.velocity` is masked.

## Choices left open by the record
None. The contract fixes the dot product, the strict threshold and when the result is unknown, so no
narrowing is declared.

## Why I finished
The gate cannot judge the files from inside this session. Each run creates a file outside the concept's
scope and returns SCOPE_VIOLATION whatever the files contain. More runs would only use up budget with the
same result. The record itself looks sound.
