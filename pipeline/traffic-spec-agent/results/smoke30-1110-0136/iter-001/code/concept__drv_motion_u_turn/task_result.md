# drv.motion.u_turn — task result

**Final verdict: OK** (gate run 1 of 6).

## Gate runs
1. `OK` — 3 witnesses, 1 name, reads 1 atom. Nothing changed after it.

## Body
`|prim_heading_change(x; window)| ≥ min_angle ∧ |prim_heading_change(x; window)| ≤ max_angle`

- "the magnitude of its heading change" → `Term.abs (Term.quantity "prim_heading_change" [x] [window])`.
  This is the one claimed element. The primitive integrates the yaw rate over forward and backing
  moves alike.
- "at least `min_angle` and at most `max_angle`" → `.ge` / `.le`, so both ends are inclusive.
- Recognition, extent and end: the body is the band condition at each observation, with no
  latching. So it starts holding when the window's change enters the band, holds while it stays
  there, and stops when it leaves. Nothing before the window is read.

## Choices the record left open
None that needed a narrowing; `narrowings := []`. Taking the absolute value of the signed change
is what the contract's "magnitude" says, so a reversal to either side counts.

## Witnesses
The instance uses a 10 s window and a band of 150°…210°. There is one car (track 1), observed
once a second over 30 s. Each scenario is judged over t = 17 000…21 000 ms, where every look-back
window is covered.

- **holds:** a three-point turn at 30 °/s over six observations (forward left, backing, then
  forward left again). That is 180°, which is in the band → compliant.
- **fails:** a left turn at 30 °/s over three observations, 90° → violated.
- **blind:** the holds trace with `kin.yaw_rate` masked → unknown, and only for the absent yaw
  rate.

## Why I finished
The gate returned `OK` on the first run.
