Arguments: `a` (a track).
Parameters (bounds the caller sets): `yaw_tolerance` in deg/s, `speed_tolerance` in m/s.
It holds at an observation exactly when:
(
  it is not the case that (the measured `kin_speed` of `a` [magnitude of velocity] is at most `speed_tolerance` (a parameter the caller sets))
  AND
  the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at least `yaw_tolerance` (a parameter the caller sets)
)