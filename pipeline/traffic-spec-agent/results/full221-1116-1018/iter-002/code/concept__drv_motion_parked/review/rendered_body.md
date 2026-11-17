Arguments: `a` (a track).
Parameters (bounds the caller sets): `speed_tol` in m/s, `min_duration` in s.
It holds at an observation exactly when:
at every observation of the last `min_duration` (a parameter the caller sets) of time of `a`: (the measured `kin_speed` of `a` [magnitude of velocity] is at most `speed_tol` (a parameter the caller sets))