# LVMC_11_16_090_A_o1 — task result

## Final verdict
SCOPE_VIOLATION on both gate runs. This is an infrastructure fault: the gate never judged the two node files.

## Gate runs
1. **SCOPE_VIOLATION.** The "changed outside the node's files" list holds only agent-runtime scratch files under
   `.runtime/tmp/claude-154266/...`:
   - the `tasks/<id>.output` file the shell tool writes for this gate command itself
   - `tasks/*.output` files of other concurrent coding sessions (LVMC_11_18_020, LVMC_11_30_050, LVMC_11_43_010_B_o1)
   - `cache-break-state-*.json`

   I did not write any of them, and no session can avoid them: the tool that runs the gate command
   creates a fresh `.output` file under the repository's `.runtime/tmp` on every call. Nothing changed
   between this run and the next.
2. **SCOPE_VIOLATION.** Same list, except my session's entry now names the new `.output` file of this run.
   The fault persists: each gate call creates a new file that the scope check flags. I stopped there
   rather than spend the rest of the budget on runs that cannot reach a verdict.

**Fix for the harness:** exclude `.runtime/` (the agent runtime's temp dir) from the scope diff, or move
`CLAUDE_TMPDIR` outside the worktree. After that, a re-run should judge the files below.

## What was written
The rule is `library/TrafficSpec/Rules/LVMC_11/LVMC_11_16_090_A_o1.lean`:
- class: `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`
- applicability (g4): `existsRegion "highway" h (rel_occupies subject h)`
- obligation (g1/g3): `not ((a) or (b) or (c))`, where:
  - (a) `kin_accel_longitudinal subject ≥ p.exhibition_accel_min`
  - (b) `kin_speed subject ≥ p.exhibition_speed_min`
  - (c) `existsUser o (not same subject o ∧ ru_aggregate o MV ∧ holdsFor time p.contest_window subject
    (rel_same_direction(subject,o; p.contest_same_direction_cos) ∧ rel_longitudinal_overlap(subject,o) > 0 ∧
    accel subject ≥ p.contest_accel_min ∧ accel o ≥ p.contest_accel_min))`

The witnesses are in `library/TrafficSpecWitness/LVMC_11/LVMC_11_16_090_A_o1.lean`. All seven run 6 instants
1 s apart, with the window judged at t = 4000–5000 ms:
- `forbid`: two cars abreast, both at 3 m/s²
- `permit`: alone, 2 m/s²
- `idle`: in a lot off the highway rectangle
- `blind`: alone at 15 m/s; `kin.accel_longitudinal` masked
- `branch_1`: alone at 5 m/s²
- `branch_2`: alone at 50 m/s; added so that (b) has a witness
- `branch_3`: abreast, but the other car accelerates at only 1 m/s², so compliant

Relations are computed from kinematics, not supplied.

## Choices the node left open
- **Contest quantifier placement.** The record says "one road user throughout", so the user quantifier
  stands outside `holdsFor`. The record dictates this, so I declared no narrowing.
- **Narrowings:** none.

## Why I finished
The gate's scope check flags runtime temp files that every gate invocation creates. My files cannot change
that verdict, so the remaining budget cannot produce a judgment on the rule or the witnesses. They have
not been checked by the gate, not even for build.
