Arguments: `a` (a track).
Parameters (bounds the caller sets): `window` in s, `turn_min` in deg, `u_turn_min` in deg, `yaw_tol` in deg/s.
It holds at an observation exactly when:
((
  (
    the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is at least `turn_min` (a parameter the caller sets)
    AND
    the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is less than `u_turn_min` (a parameter the caller sets)
  )
  AND
  the absolute value of the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at most `yaw_tol` (a parameter the caller sets)
)) holds now and did not hold at the previous observation