Arguments: `a` (a track), `b` (a track).
Parameters (bounds the caller sets): `same_direction_tolerance` in ratio, `min_speed_excess` in m/s.
It holds at an observation exactly when:
(
  `rel_same_direction` holds of `a`, `b` at `same_direction_tolerance` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
  AND
  (
    (the measured `kin_speed` of `a` [magnitude of velocity] minus the measured `kin_speed` of `b` [magnitude of velocity]) is at least `min_speed_excess` (a parameter the caller sets)
    AND
    (
      the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is more than 0 metre
      OR
      `rel_ahead_behind_in_lane` holds of `b`, `a` [a is ahead of / behind b in the same lane, along the lane direction]
    )
  )
)