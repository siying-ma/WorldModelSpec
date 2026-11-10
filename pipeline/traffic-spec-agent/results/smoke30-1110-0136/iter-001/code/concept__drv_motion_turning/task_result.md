# drv.motion.turning — task result

**Final verdict: OK** (3 witnesses, 1 name, reads 1 atom)

## Body

`.cmp (.abs (.measure "kin_yaw_rate" [x])) .gt (.param "tol")`: the magnitude of the road user's yaw rate exceeds `tol`.

## Gate runs

1. **WITNESS_FAIL**: in `holds`, the corner positions were more than 5 m apart in a straight line, but the path length grew by only 5 m between observations. The adapter cannot produce that. I moved the positions to (0, 0), (4.9, 0.7) and (9.5, 2.4) m so each straight-line step is shorter than the 5 m of path. The body did not change.
2. **OK**.

## Choices the record left open

- "Exceeds `tol`" is written as a strict `>`. This matches the parameter's meaning: "a yaw rate at or below it in magnitude counts as none".
- "To either hand" is the absolute value of the yaw rate.
- "Whether the road user moves forwards or backwards" needs no term, because the body reads no speed, gear or direction of travel.
- None of these is a narrowing: each follows from the contract's words, so `narrowings` is empty.

## Witnesses

- **Instance:** `tol` = 1 deg/s.
- **`holds`:** a car rounds a left-hand corner at 5 m/s with a yaw rate of 16 deg/s. Its heading goes east → (24/25, 7/25) → (527/625, 336/625).
- **`fails`:** a car drives straight east at 5 m/s with a yaw rate of 0.
- **`blind`:** the same straight drive. `kin.yaw_rate` is declared absent and its field is left unset.

## Why I finished

The gate returned OK on the second run (2 of the 6 allowed). The record was consistent and needed no repair.
