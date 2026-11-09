Arguments: `u` (a track).
Parameters (bounds the caller sets): `speed_tolerance` in m/s.
It holds at an observation exactly when:
the measured `kin_speed` of `u` [magnitude of velocity] is at most `speed_tolerance` (a parameter the caller sets)