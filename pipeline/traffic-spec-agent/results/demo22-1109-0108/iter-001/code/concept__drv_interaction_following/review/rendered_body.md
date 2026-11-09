Arguments: `a` (a track), `b` (a track).
Parameters (bounds the caller sets): `same_direction_tolerance` in ratio.
It holds at an observation exactly when:
(
  `rel_ahead_behind_in_lane` holds of `b`, `a` [a is ahead of / behind b in the same lane, along the lane direction]
  AND
  `rel_same_direction` holds of `a`, `b` at `same_direction_tolerance` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
)