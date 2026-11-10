Arguments: `x` (a track), `i` (a region).
Parameters (bounds the caller sets): `step` in ms, `max_angle` in deg.
It holds at an observation exactly when:
(
  (it is not the case that (`rel_occupies` holds of `x`, `i` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)])) holds now and did not hold at the previous observation
  AND
  the absolute value of the heading change of `x` since (`rel_occupies` holds of `x`, `i` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) last became true, integrated with steps of at most `step` (a parameter the caller sets) is less than `max_angle` (a parameter the caller sets)
)