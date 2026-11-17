Arguments: `a` (a track), `r1` (a region), `r2` (a region), `s` (a literal among ['left', 'right']).
Parameters (bounds the caller sets): (none).
It holds at an observation exactly when:
(
  `st_lane_adjacency` holds of `r1`, `s`, `r2` [left / right neighbouring lane of the same direction; lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane, looking along the lane's direction **Not a stand-in for:** the marking between two lanes]
  AND
  (
    (
      `rel_occupies` holds of `a`, `r1` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]
      AND
      it is not the case that ((`rel_occupies` holds of `a`, `r1` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation)
    )
    AND
    (`rel_occupies` holds of `a`, `r2` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation
  )
)