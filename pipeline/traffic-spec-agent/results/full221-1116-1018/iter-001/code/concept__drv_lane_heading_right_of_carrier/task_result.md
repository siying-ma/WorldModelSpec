# drv.lane.heading_right_of_carrier — task result

## Final verdict
`SCOPE_VIOLATION` on both gate runs. The cause is infrastructure, not the concept files: the only
path flagged each time is the agent shell tool's own output-capture file,
`.runtime/tmp/claude-154266/…/tasks/<id>.output`. The tool writes that file inside the repository
tree each time it runs a command, including the gate command itself. Neither I nor my edits wrote
it. My edits touched only the two owned files (and this report). The gate never got far enough to
judge the body or the witnesses.

## Gate runs
1. `SCOPE_VIOLATION`: flagged `.runtime/tmp/…/tasks/bxffsili2.output`. I changed nothing in the
   files. I re-ran without an explicit timeout in case that had caused the capture file.
2. `SCOPE_VIOLATION`: flagged `.runtime/tmp/…/tasks/b5giiwcn9.output`, a new capture file from this
   run. Every shell call creates one. The shell may only run the gate command, so I cannot remove
   these files, and more runs would only spend budget. I stopped at 2 of 6 runs.

**For the harness:** exclude the shell tool's `.runtime/tmp` (`CLAUDE_TMPDIR`) from the scope
check, or put that directory outside the repo tree. The post-session gate re-run will hit the same
problem unless it ignores those files.

## What was written
**Concept body** (`library/TrafficSpec/Concepts/lane/heading_right_of_carrier.lean`):
- h = (`kin_heading a "x"`, `kin_heading a "y"`) and d = (`st_lane_direction r "x"`,
  `st_lane_direction r "y"`). Core reads both normalised (`Geom.unit`).
- The body is `d·h > 0 ∧ (d_x h_y − d_y h_x) < −sin_tol ∧ kin_speed a > speed_tol`.
- It uses only the claimed atoms and only the formals and formal parameters. Its one literal is
  zero.

**Witnesses** (`library/TrafficSpecWitness/Concepts/lane/heading_right_of_carrier.lean`):
- **Setup:** lane 100 spans x ∈ [0, 100] m and y ∈ [0, 4] m, direction east. Motor vehicle 1 is at
  (20, 2) m, moving at 10 m/s. Each trace has 3 observations 1 s apart. The instance sets
  sin_tol = 1/10 and speed_tol = 1 m/s.
- **holds:** heading (4/5, −3/5). The cross product is −3/5 < −1/10 and the dot product is 4/5 > 0,
  so the concept should hold.
- **fails:** heading east. The cross product is 0, so the concept should fail.
- **blind:** same scene as holds, with `st.lane_direction` masked, so the result should be unknown.

## Choices the record left open
None. The contract gives the inequalities exactly, so I declared no narrowings.

## Why I finished
Both gate runs returned `SCOPE_VIOLATION` because of files the shell tool itself creates. I can't
remove them from inside this session, and every further gate run creates another one.
