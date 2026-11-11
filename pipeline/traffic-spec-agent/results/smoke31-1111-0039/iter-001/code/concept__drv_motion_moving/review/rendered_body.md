Arguments: `x` (a track).
Parameters (bounds the caller sets): `speed_floor` in m/s.
It holds at an observation exactly when:
the measured `kin_speed` of `x` [magnitude of velocity] is more than `speed_floor` (a parameter the caller sets)