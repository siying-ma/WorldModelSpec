Arguments: `u` (a track), `r` (a region).
Parameters (bounds the caller sets): (none).
It holds at an observation exactly when:
(
  (it is not the case that (`rel_occupies` holds of `u`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)])) holds now and did not hold at the previous observation
  OR
  (
    (
      `rel_occupies` holds of `u`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]
      AND
      it is not the case that ((`rel_occupies` holds of `u`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation)
    )
    AND
    for some region `n` of kind ''lane'': ((
      (
        `st_lane_adjacency` holds of `r`, 'left', `n` [left / right neighbouring lane of the same direction; lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane, looking along the lane's direction **Not a stand-in for:** the marking between two lanes]
        OR
        `st_lane_adjacency` holds of `r`, 'right', `n` [left / right neighbouring lane of the same direction; lane ordinal within the carriageway and the count of lanes in that direction; ordinal 1 is the leftmost lane, looking along the lane's direction **Not a stand-in for:** the marking between two lanes]
      )
      AND
      (`rel_occupies` holds of `u`, `n` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation
    ))
  )
)