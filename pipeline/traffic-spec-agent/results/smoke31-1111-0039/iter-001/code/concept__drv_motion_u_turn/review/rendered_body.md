Arguments: `x` (a track).
Parameters (bounds the caller sets): `window` in s, `reversal_tolerance` in deg.
It holds at an observation exactly when:
the absolute value of (the absolute value of the primitive `prim_heading_change` of `x` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] minus 180 degree) is at most `reversal_tolerance` (a parameter the caller sets)