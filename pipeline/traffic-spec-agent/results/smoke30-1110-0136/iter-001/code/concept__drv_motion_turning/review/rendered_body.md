Arguments: `x` (a track).
Parameters (bounds the caller sets): `tol` in deg/s.
It holds at an observation exactly when:
the absolute value of the measured `kin_yaw_rate` of `x` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is more than `tol` (a parameter the caller sets)