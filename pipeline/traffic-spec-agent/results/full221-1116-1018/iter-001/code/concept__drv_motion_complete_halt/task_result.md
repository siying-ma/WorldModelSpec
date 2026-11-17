# drv.motion.complete_halt — task result

## Final verdict
`SCOPE_VIOLATION` on both runs. The cause is the environment, not the two concept files (see below).
The gate never got to build or judge the body and witnesses.

## Body
`.cmp (.measure "kin_speed" [aA]) .le pSpeedTol`: the sampled speed of `a` at the observation is at
or below `speed_tol`. This is a state at one observation, with no window, place or cause, as the
contract says. It uses the one claimed atom `kin.speed` (one argument, per `Semantics.lean:274`) and
the one formal parameter. It has no literals and no narrowings.

## Witnesses
One motor vehicle (track 1) heading east, 3 observations 1 s apart; `speed_tol` = 0.1 m/s
(`Units.micrometresPerSecond 100000`).
- holds: stationary; speeds are 0, 0.05 m/s and exactly 0.1 m/s (the boundary, "at or below").
- fails: creeps forward at 0.5 m/s.
- blind: stationary; `kin.speed` is masked in the manifest.

## Gate runs
1. `SCOPE_VIOLATION`. It flagged `.runtime/tmp/claude-154266/.../tasks/bjpkkm1i2.output` and a
   `.output` file from another concurrent session (`drv.motion.moving…`). These are the agent
   tool's captures of command output. The session temp directory sits inside the repository
   (`traffic-spec-agent/.runtime/tmp`), so every shell command writes a file there. I changed
   nothing and re-ran the gate to rule out a one-off.
2. `SCOPE_VIOLATION`. It flagged only `.runtime/tmp/.../tasks/bcwk7rwxn.output`, which is this gate
   command's own output capture.

## Choices the record left open
None. "At or below" maps directly to `.le`. The tolerance value in the witness is the witness's own.

## Why I finished
Every gate run produces a new file under `.runtime/tmp` inside the repository, so in this
environment the gate returns `SCOPE_VIOLATION` no matter what the concept files contain. Spending
more of the budget would give the same result. This is an infrastructure problem: `.runtime/` should
be excluded from the gate's scope check, or the temp directory moved out of the repository. The
harness re-runs the gate itself after the session, outside the tool, and that run should judge the
files on their merits. The record itself looks correct.
