# drv.motion.halted — task result

**Final verdict: OK** (gate run 1 of 6: "3 witnesses, 1 names, reads 1 atom(s)").

## Body

`.cmp (.measure "kin_speed" [.var "x"]) .le (.param "speed_floor")`: the road user's speed is at or
below the speed floor at the observation. There is no time operator, because the contract states
no minimum duration. If the speed is unobserved, the comparison is unknown.

## Gate runs

1. **OK.** This was the first run after I wrote the body and the witnesses. Nothing changed after it.

## Choices the record left open

- **Narrowings:** none. The contract fixes the comparison (at or below, so `.le`), the atom and the
  parameter.
- **Witness figures (the witness's own):**
  - `speed_floor` is 0.1 m/s, written as `Units.micrometresPerSecond 100000`.
  - The road user is track 1, a motor vehicle with half-extents 225 cm, 90 cm and 75 cm, heading
    east.
  - Each trace has 3 observations, 1 s apart.
- **holds:** the road user stands at (0, 0) at 0 m/s.
- **fails:** the road user drives east at 4 m/s, at x = 4·k m at observation k.
- **blind:** the road user stands at (0, 0). Its `speed` field is unset, and the manifest leaves
  out `kin.speed`.

## Why I finished

The gate returned OK on the first run. The record matched what the formula language can express,
so there was nothing to report.
