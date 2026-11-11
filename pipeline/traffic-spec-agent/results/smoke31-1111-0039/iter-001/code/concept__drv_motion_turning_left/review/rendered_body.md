Arguments: `x` (a track).
Parameters (bounds the caller sets): `speed_floor` in m/s, `yaw_floor` in deg/s.
It holds at an observation exactly when:
(
  the measured `kin_speed` of `x` [magnitude of velocity] is more than `speed_floor` (a parameter the caller sets)
  AND
  the measured `kin_yaw_rate` of `x` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is more than `yaw_floor` (a parameter the caller sets)
)