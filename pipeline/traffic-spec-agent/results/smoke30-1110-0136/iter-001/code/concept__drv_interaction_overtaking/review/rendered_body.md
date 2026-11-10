Arguments: `a` (a track), `b` (a track).
Parameters (bounds the caller sets): `cos_tol` in ratio, `speed_tol` in m/s.
It holds at an observation exactly when:
(
  `rel_same_direction` holds of `a`, `b` at `cos_tol` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
  AND
  (
    the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is at least 0 metre
    AND
    (the measured `kin_speed` of `a` [magnitude of velocity] minus the measured `kin_speed` of `b` [magnitude of velocity]) is more than `speed_tol` (a parameter the caller sets)
  )
)