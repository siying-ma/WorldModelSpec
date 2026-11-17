# drv.motion.left_turn — task result

## Final verdict

`SCOPE_VIOLATION` on both gate runs. The cause is in the infrastructure, not in the concept's files.
The gate never reached the build or the witnesses.

## Gate runs

1. `SCOPE_VIOLATION`: "changed outside the concept's files: ['.runtime/tmp/claude-154266/…/tasks/bjcbjbha0.output']".
   The flagged file is not mine. The agent tool runtime writes it to capture each shell command's output,
   and it sits under `.runtime/tmp` in the worktree. I ran the gate again unchanged to see whether the
   file name was stable.
2. `SCOPE_VIOLATION`: same message, with a new file `tasks/bq4o9ogn7.output`. Every shell call (the
   gate included) writes a new file of this kind, so every gate run from inside the session will
   report `SCOPE_VIOLATION`. I can't remove these files because the only shell command allowed is the
   gate. I stopped at 2 of 6 runs because more runs would have spent budget without the gate ever
   judging my files.

Change after run 2: in the witness, `if 8 ≤ k && k ≤ 13` became `if 8 ≤ k ∧ k ≤ 13`, a precaution
about Prop/Bool. No gate run checked it.

**For the harness or operator:** exclude the session's `.runtime/tmp/…` directory from the gate's
scope check (or move the runtime tmp outside the worktree), then re-run the gate. My files have not
been built or checked against witnesses. I checked them only by reading them against Core
(`Vocab/Primitives.lean`, `Foundations/Time.lean`, `Language/RuleEval.lean`).

## The body

```
headingChange := Term.quantity "prim_heading_change" [a] [window]
inBand        := headingChange ≥ turn_min ∧ headingChange < u_turn_min
yawSettled    := |kin_yaw_rate a| ≤ yaw_tol
body          := rises (inBand ∧ yawSettled)
```

- "the band from turn_min inclusive to u_turn_min exclusive": `≥` / `<`. The primitive is signed
  with left positive, so a right turn, a drift and a reversal all fall outside the band.
- "yaw rate … at most yaw_tol in magnitude": `abs` and then `≤`.
- "recognized at the observation at which [the condition holds] where this did not hold at the
  previous observation … holds at that observation only, and not again until that condition has
  ceased to hold and then holds again": `rises`.
- Unknown where the window is truncated or a yaw rate is missing: this comes from
  `prim_heading_change` (`windowTruncated` / `absentAtom kin_yaw_rate`) and from `kin_yaw_rate`.

## Choices the record left open

None. The contract fixes the band's ends, the magnitude test and the rising-edge recognition, so I
declared no narrowing.

## Witnesses

Instance: window 10 s, turn_min 45°, u_turn_min 150°, yaw_tol 2 °/s. There is one bicycle (track 1)
at 5 m/s, observed 20 times one second apart (t = 0…19 s).

- **holds**: the yaw rate is 15 °/s at t = 8…13 s (90° left) and 0 at every other observation. At
  t = 14 s the window is covered, the heading change is 90° and the yaw rate is 0. At t = 13 s the
  yaw rate was 15 °/s, so the condition rises at t = 14 s. Scenario window: (14000, 14000).
- **fails**: a lane change to the left at +5 °/s for t = 8, 9 s, then −5 °/s for t = 10, 11 s. The
  heading change stays at or below 10° < 45°. Scenario window: (10000, 19000), where the 10 s
  window is covered.
- **blind**: the holds trace, with `kin.yaw_rate` masked through the manifest. Both the heading
  change and the yaw rate become unknown at t = 14 s. Scenario window: (14000, 14000).

## Why I finished

The gate can't judge these files from inside this session. Each shell call creates a new
runtime output file in the worktree, which the gate's scope check reports as `SCOPE_VIOLATION`.
More runs would have used up the budget without telling me anything new. The record looks
correct to me (both claimed names are used and the contract is fully expressible), so I am not
reporting a record defect. The harness's own re-run after the session should judge the files once
the runtime tmp directory is out of scope.
