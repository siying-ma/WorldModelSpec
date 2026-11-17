# drv.motion.left_turn_through_region — task result

## Final verdict
**SCOPE_VIOLATION (infrastructure, not the concept's files).** The gate never got as far as judging the two files.

## Gate runs
1. `SCOPE_VIOLATION`: "changed outside the concept's files:
   `.runtime/tmp/claude-154266/…/tasks/bgckug0jd.output`". That file is the agent runtime's own
   capture of the gate command's output. It sits inside the repository tree, under `.runtime/tmp`.
   I did not write it and cannot remove it: the shell may only run the gate.
2. `SCOPE_VIOLATION` again, unchanged files: this time it flagged the new capture file for this run
   (`…/tasks/bpfql3vx6.output`) **and** a capture file from another concurrent session
   (`…concept--drv-motion-right-o25jtz/…/tasks/bt9yv9h5f.output`). Every gate run creates a new
   capture file, so every run inside this session will fail the scope check. I stopped there and
   kept the remaining 4 runs unused.

**What the harness should change:** the scope check should ignore `.runtime/` (the per-session
tool scratch area), or the runtime tmp directory should be moved outside the git tree. The harness
re-runs the gate after this session ends; outside the session no capture file is written, so the
re-run should reach the real checks.

## Body (concept file)
- `inR := rel_occupies a r`: a's footprint overlaps r.
- `exitR := rises (not inR)`: not overlapping now, overlapping at the previous observation. This is
  the exit. It holds at that observation only, and cannot hold again until a has re-entered r and
  left it.
- `turned := headingSince "a" step inR`: the heading change, left positive, integrated from
  `kin_yaw_rate` since the latest definite rise of the overlap (the entry), with `step` as the
  sampling bound. Core's semantics give exactly the contract's unknown cases: entry unobserved or
  hidden by an unknown overlap, an interval longer than `step` from the observation before the
  entry onwards, or a yaw rate missing.
- `body := exitR ∧ turned ≥ turn_min ∧ turned < u_turn_min` (inclusive / exclusive as the contract states).

Both claimed atoms are used. The only parameters are the formals, `step` is used directly as the
heading-change step bound, and there are no literals.

## Choices the record left open
None. The contract fixes the entry, the exit, the onset, the band and its endpoints, and the unknown
cases, so `narrowings` is empty.

## Witnesses
- r = 100: an intersection, the square (0,0)–(20,20) m. a = track 1: a motor vehicle with half extents 2×1×1 m.
- Six scenes, 1 s apart. a is at (-6,10), then (2,10) (the entry), (8,10±2), (10,10±8),
  (10,10±16) (the exit, t = 4000 ms), (10,10±22).
- Every scenario's window is the exit, 4000–4000 ms.
- Instance: step = 1 s, turn_min = 45°, u_turn_min = 135°.

| Scenario | Yaw rate | Heading change, entry → exit | Expected verdict |
|---|---|---|---|
| holds | +30°/s from the entry to the exit | +90°, the same under any integration rule | compliant |
| fails | −30°/s (mirror image, leaves heading south) | −90° < 45° | violated |
| blind | none supplied, and `kin.yaw_rate` masked in the manifest | heading change unknown | unknown at the exit |

The witnesses are unverified by the gate because of the scope failure above. I checked them by hand
against `Evidence/Builders.lean`: timestamps, the window filter, the geometry-derived occupancy and
the manifest masking.

## Why I finished
The gate cannot judge these files inside this session. Each run creates a new out-of-scope file
from the tool runtime itself, so spending more runs would not change the verdict. The files are
complete and hand-checked; the harness's re-run after the session ends is the run that can judge them.
