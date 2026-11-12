Arguments: `a` (a track).
Parameters (bounds the caller sets): `turn_angle` in deg, `yaw_tolerance` in deg/s, `speed_tolerance` in m/s, `step` in ms.
It holds at an observation exactly when:
((
  (
    it is not the case that (the measured `kin_speed` of `a` [magnitude of velocity] is at most `speed_tolerance` (a parameter the caller sets))
    AND
    the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at most the negative of `yaw_tolerance` (a parameter the caller sets)
  )
  AND
  the heading change of `a` since ((
  it is not the case that (the measured `kin_speed` of `a` [magnitude of velocity] is at most `speed_tolerance` (a parameter the caller sets))
  AND
  the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at most the negative of `yaw_tolerance` (a parameter the caller sets)
)) last became true, integrated with steps of at most `step` (a parameter the caller sets) is at most the negative of `turn_angle` (a parameter the caller sets)
)) holds now and did not hold at the previous observation