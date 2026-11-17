Arguments: `a` (a track), `r` (a region).
Parameters (bounds the caller sets): `step` in s, `u_turn_min` in deg.
It holds at an observation exactly when:
(
  (it is not the case that (`rel_occupies` holds of `a`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)])) holds now and did not hold at the previous observation
  AND
  (
    the absolute value of the heading change of `a` since ((`rel_occupies` holds of `a`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation) last became true, integrated with steps of at most `step` (a parameter the caller sets) is at least `u_turn_min` (a parameter the caller sets)
    AND
    the absolute value of the heading change of `a` since ((`rel_occupies` holds of `a`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation) last became true, integrated with steps of at most `step` (a parameter the caller sets) is at most (360 degree minus `u_turn_min` (a parameter the caller sets))
  )
)