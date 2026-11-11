Arguments: `x` (a track), `y` (a track).
Parameters (bounds the caller sets): `aligned_cosine` in ratio, `speed_margin` in m/s.
It holds at an observation exactly when:
(
  `rel_same_direction` holds of `x`, `y` at `aligned_cosine` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
  AND
  (
    the measured `rel_longitudinal_overlap` of `x`, `y` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is more than 0 metre
    AND
    (
      `rel_bearing` holds of `x`, `y`, 'left' [direction of b from a in a's frame (for "on the right of", "immediately to the rear")]
      AND
      (the measured `kin_speed` of `x` [magnitude of velocity] minus the measured `kin_speed` of `y` [magnitude of velocity]) is more than `speed_margin` (a parameter the caller sets)
    )
  )
)