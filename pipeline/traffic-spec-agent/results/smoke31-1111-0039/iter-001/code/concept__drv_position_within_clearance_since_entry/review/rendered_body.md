Arguments: `x` (a track), `r` (a region).
Parameters (bounds the caller sets): `clearance` in m.
It holds at an observation exactly when:
(
  the measured `st_region_geometry_distance` of `x`, `r` [the reference point and the boundary polygon of a structure region in the world frame, and the ground distance from a road user's body outline to it (zero when they overlap); a source that maps regions without their outline declares it absent, and every such distance is then unknown **Not a stand-in for:** occupancy — a footprint inside a boundary is `rel.occupies`, which a source may observe without geometry] is less than `clearance` (a parameter the caller sets)
  SINCE
  (`rel_occupies` holds of `x`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation
)