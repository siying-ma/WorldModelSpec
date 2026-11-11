Arguments: `x` (a track).
Parameters (bounds the caller sets): `speed_floor` in m/s, `decel_floor` in m/s^2.
It holds at an observation exactly when:
(
  ((the measured `kin_velocity` of `x`, 'x' [velocity vector] times the measured `kin_heading` of `x`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown]) plus (the measured `kin_velocity` of `x`, 'y' [velocity vector] times the measured `kin_heading` of `x`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown])) is more than `speed_floor` (a parameter the caller sets)
  AND
  the measured `kin_accel_longitudinal` of `x` [acceleration along heading, signed **Not a stand-in for:** speed] is less than the negative of `decel_floor` (a parameter the caller sets)
)