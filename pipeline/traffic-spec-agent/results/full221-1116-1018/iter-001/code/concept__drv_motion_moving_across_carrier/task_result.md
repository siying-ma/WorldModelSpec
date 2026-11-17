# drv.motion.moving_across_carrier: task result

## Final verdict
The gate has not judged the files yet. Both runs I made returned `SCOPE_VIOLATION`, each caused by
an infrastructure artefact and not by my files (details below).

## Gate runs
1. `SCOPE_VIOLATION`: "changed outside the concept's files:
   ['.runtime/tmp/claude-154266/.../tasks/br604dyry.output']". That file is the shell tool's own
   capture of the gate command's output. The agent runtime writes it inside the repository tree.
   I did not write it, and I cannot remove or prevent it.
2. I changed nothing and ran the gate again to confirm. It returned `SCOPE_VIOLATION` again, now
   naming a new capture file (`tasks/b60f0szz9.output`). Every gate run from this session creates
   such a file, so further runs would only use up budget. I stopped at 2 of 6 runs.

## What was written
- Body: `kin_speed a > speed_tol ∧ |vx·dx + vy·dy| ≤ cos_max · kin_speed a`
  - `vx, vy` are the components of `kin_velocity a` (`.lit "x"` / `.lit "y"`).
  - `dx, dy` are the components of `st_lane_direction r`. Core reads the direction normalised,
    and an absent or zero direction is unknown.
  - The absolute value makes either sense of crossing count.
  - The speed bound is strict, as the contract says ("at or below speed_tol" is not denoted).
  - No division is used: the cosine bound is the product form the contract itself states.
- Every claimed atom is used (`kin.speed`, `kin.velocity`, `st.lane_direction`), and no other
  atom is. The only variables are the formals `a` and `r`.
- Witness:
  - Lane 100 is x ∈ [0, 30] m, y ∈ [-2, 2] m, direction east.
  - Pedestrian 1 starts at (10, 0) and walks at 1.4 m/s; there are 3 scenes, 1 s apart.
  - Instance: `speed_tol` = 0.1 m/s, `cos_max` = 1/2.
  - holds: the pedestrian walks north, so the dot product is 0 ≤ 0.7.
  - fails: the pedestrian walks east, so |dot| = 1.4 > 0.7.
  - blind: walking north with `kin.velocity` masked. Speed is still above the tolerance, so the
    unknown dot product is what makes the verdict unknown.

## Choices the record left open
None. The contract states the comparison exactly, so I declared no narrowings.

## Why I finished
The gate cannot judge these files from inside this session. Every gate run makes the tool runtime
write an output-capture file under `.runtime/tmp/` in the repository, and the gate counts that file
as a scope violation. This is an infrastructure problem: the runtime's tmp directory should be
outside the tracked tree, or the gate should exclude `.runtime/`. It is not a problem with the
concept or the witnesses. The harness re-runs the gate after this session, and that run should
judge the two files as they now stand.
