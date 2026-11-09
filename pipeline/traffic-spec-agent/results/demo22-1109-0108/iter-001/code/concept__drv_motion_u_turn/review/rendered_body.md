Arguments: `u` (a track).
Parameters (bounds the caller sets): `heading_step` in ms, `onset_yaw_rate` in deg/s, `reversal_angle` in deg.
It holds at an observation exactly when:
(
  the absolute value of the heading change of `u` since (the absolute value of the measured `kin_yaw_rate` of `u` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is more than `onset_yaw_rate` (a parameter the caller sets)) last became true, integrated with steps of at most `heading_step` (a parameter the caller sets) is at least `reversal_angle` (a parameter the caller sets)
  AND
  for some region `w` of kind ''highway'': (`rel_occupies` holds of `u`, `w` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)])
)