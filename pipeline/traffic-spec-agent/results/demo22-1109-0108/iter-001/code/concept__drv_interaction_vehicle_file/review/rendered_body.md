Arguments: `u` (a track).
Parameters (bounds the caller sets): `min_member_count` in count, `file_reach` in m, `same_direction_tolerance` in ratio.
It holds at an observation exactly when:
the count of 0 count over the road users `v` of the scene for which ((
  `v` and `u` are the same entity
  OR
  (
    `rel_same_direction` holds of `v`, `u` at `same_direction_tolerance` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
    AND
    (
      (
        `rel_ahead_behind_in_lane` holds of `v`, `u` [a is ahead of / behind b in the same lane, along the lane direction]
        OR
        `rel_ahead_behind_in_lane` holds of `u`, `v` [a is ahead of / behind b in the same lane, along the lane direction]
      )
      AND
      the measured `rel_surface_gap` of `u`, `v` [distance between the nearest points of two bodies, each body's footprint read with its own heading and extent: zero when they touch or overlap, never negative; its longitudinal and lateral components are the lengths of the vector between those nearest points along and across the subject's heading, and a read without a component is the distance; a supplied gap with a negative component reads unknown, never as its magnitude, as zero or as contact] is at most `file_reach` (a parameter the caller sets)
    )
  )
)) is at least `min_member_count` (a parameter the caller sets)