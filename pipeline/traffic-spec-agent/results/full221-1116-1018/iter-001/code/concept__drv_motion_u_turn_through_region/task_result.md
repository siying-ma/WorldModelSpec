# drv.motion.u_turn_through_region — task result

## Final verdict

**Not judged: SCOPE_VIOLATION on infrastructure, not on my files.** Every gate run returned
`SCOPE_VIOLATION`, and each time the "changed" file was the session's own tool-output capture:
`.runtime/tmp/claude-154266/.../tasks/<id>.output`. The agent runtime writes that file inside the
repository while the gate command runs. I did not write it and cannot stop it from being written,
so the gate never got to my two files. This is really an `INFRA` condition. The harness re-runs the
gate after the session ends, and that run should not produce the file.

## Gate runs

1. Run 1: `SCOPE_VIOLATION` (the `.runtime/tmp/.../tasks/*.output` file). This run used the skeleton
   files, and I mistakenly piped the command through `head`. After it I wrote the body and the
   witnesses.
2. Run 2: the exact command on the finished files. `SCOPE_VIOLATION` again, from a new
   `.runtime/tmp/.../tasks/*.output` file. The verdict does not depend on my files, so I stopped
   rather than spend the rest of the budget on the same result.

## The body

```
occ    := rel_occupies(a, r)
entry  := rises occ                         -- overlap here, none at the previous observation
exitR  := rises (not occ)                   -- no overlap here, overlap at the previous observation
turned := abs (headingSince "a" step entry) -- |yaw-rate integral since the latest entry|
body   := exitR ∧ turned ≥ u_turn_min ∧ turned ≤ 360° − u_turn_min
```

- The concept holds only at the exit edge, and not again until a enters and leaves again: the
  `rises` edge gives this directly.
- The unknown cases come from `headingSince`, as Core defines it. It is unknown when the entry was
  not observed (before the recording, or hidden by an unknown overlap since), when an interval from
  the observation before the entry is longer than `step`, or when a yaw rate since the entry is
  missing.
- `step` is passed to `headingSince` directly as the formal parameter. 360° is the record's
  declared literal, written as `Units.degrees 360`.
- Claimed names: `rel_occupies` and `kin_yaw_rate` (read through `headingSince`). No other atoms
  and no concepts.

## Witnesses

- **Setup:** r = 100 is a roundabout, the square (0,0)–(40,40) m. a = track 1 is a motor vehicle
  with half-extent 2 × 1 × 1 m. There are 6 scenes at 1 s spacing, and occupancy is derived from
  the geometry.
- **Instance:** step = 1 s, u_turn_min = 150°, so the band is [150°, 210°].
- **Window:** every scenario is judged at the exit instant only (`window := (4000, 4000)`), because
  the concept is an event that holds only at the exit.
- **Scenes:** a enters at k1. The exit is at k4. The yaw rate is 90°/s at the two scenes where the
  heading changes, and 0 elsewhere, which matches the heading lint.
  - `holds`: east → north → west, a 180° heading change → compliant.
  - `fails`: east → north, a 90° heading change → violated.
  - `blind`: the `holds` trace with `kin.yaw_rate` masked → unknown, with absentAtom kin_yaw_rate as
    the only reason.

## Choices the record left open

None. Every part of the formula comes from the contract's words, so `narrowings` is empty. One
point was outside the contract: judging the witnesses at the exit instant, through `window`. That
belongs to the witnesses, not to the concept.

## Why I finished

The only verdict the gate gave was a scope violation caused by a file the agent runtime writes
inside the repo (`.runtime/tmp/.../tasks/*.output`), not by my edits. Running the gate again would
use up the budget without judging the concept. The harness's own re-run after the session will
judge the two files as they are now. If the harness keeps the session's runtime tmp directory
inside the checked worktree, it should exclude `.runtime/` from its scope check.
