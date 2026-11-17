# drv.motion.moving_against_carrier — task result

## Final verdict
SCOPE_VIOLATION (infrastructure; not caused by the concept's files). The gate never got as far as judging the Lean.

## Gate runs
1. **SCOPE_VIOLATION**: "changed outside the concept's files:
   `.runtime/tmp/claude-154266/…moving-against-carrier session…/tasks/b4u6720dk.output`". That file
   is the agent runtime's capture of the gate command's own stdout. I did not write it and cannot remove
   it, because the shell may run only the gate command. I changed nothing after this run.
2. **SCOPE_VIOLATION**: the same kind of file again (`…/tasks/b6cwwfjec.output`), plus one from a
   **different concurrent session** (`…drv-motion-compl…/tasks/bjpkkm1i2.output`). So the scope check
   counts the shared `.runtime/tmp` tree that all agent sessions write to. No edit to my two files can
   clear this.

## What I wrote
- Concept body (`library/TrafficSpec/Concepts/motion/moving_against_carrier.lean`):
  `kin_velocity(a,x)·st_lane_direction(r,x) + kin_velocity(a,y)·st_lane_direction(r,y) < −speed_tol`.
  Core's `evalMeasure` reads `st_lane_direction` through `Geom.unit`, so this is the normalised
  direction the contract asks for. An unobserved velocity or a missing direction makes a factor
  unknown, so the result is unknown. It uses only the claimed atoms and the one formal parameter.
- Witnesses: lane 100 runs x∈[0,100], y∈[−2,2] with direction east. Road user 1 (motor vehicle) is at (50,0).
  Instance: speed_tol = 0.1 m/s (`Units.micrometresPerSecond 100000`).
  - holds: velocity (−5,0) → component −5 < −0.1, so compliant.
  - fails: velocity (5,0.2) → component +5, so violated.
  - blind: velocity is `none` and `kin.velocity` is masked in the manifest, so unknown.

## Choices the record left open
None. The contract fixes the dot product with the normalised direction and the strict inequality
"below minus speed_tol", so there are no narrowings.

## Why I finished
Both runs failed on a scope check that flags files under `.runtime/tmp`. These are written by the
agent tooling itself, including other sessions running at the same time, and are outside my control.
Using more of the budget would give the same verdict. The harness re-runs the gate after this session.
To get a real verdict, the harness's scope check needs to exclude `.runtime/` (the agent runtime's
temp directory). After that, I expect the files as they stand to be judged on their content. The
record itself looks correct.
