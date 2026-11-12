Arguments: `a` (a track).
Parameters (bounds the caller sets): `window` in s, `min_angle` in deg, `max_angle` in deg.
It holds at an observation exactly when:
(
  the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is at least `min_angle` (a parameter the caller sets)
  AND
  the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is at most `max_angle` (a parameter the caller sets)
)