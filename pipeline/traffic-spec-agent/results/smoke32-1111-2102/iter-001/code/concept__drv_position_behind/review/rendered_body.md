Arguments: `a` (a track), `b` (a track).
Parameters (bounds the caller sets): `alignment` in ratio.
It holds at an observation exactly when:
(
  `rel_same_direction` holds of `a`, `b` at `alignment` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
  AND
  (
    `rel_bearing` holds of `a`, `b`, 'ahead' [direction of b from a in a's frame (for "on the right of", "immediately to the rear")]
    AND
    the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
  )
)