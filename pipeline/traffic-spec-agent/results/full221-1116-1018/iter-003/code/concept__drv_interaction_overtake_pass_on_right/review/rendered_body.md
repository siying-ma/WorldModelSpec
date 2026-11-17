Arguments: `a` (a track), `b` (a track).
Parameters (bounds the caller sets): `window` in s, `same_dir_cos` in ratio.
It holds at an observation exactly when:
(
  (
    ((
      ((the measured `kin_heading` of `a`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'x' [position of the body's reference point] minus the measured `kin_position` of `a`, 'x' [position of the body's reference point])) plus (the measured `kin_heading` of `a`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'y' [position of the body's reference point] minus the measured `kin_position` of `a`, 'y' [position of the body's reference point]))) is less than 0 metre
      AND
      the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
    )) holds now and did not hold at the previous observation
    AND
    (
      (it is not the case that ((
        it is not the case that ((
          ((the measured `kin_heading` of `a`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'x' [position of the body's reference point] minus the measured `kin_position` of `a`, 'x' [position of the body's reference point])) plus (the measured `kin_heading` of `a`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'y' [position of the body's reference point] minus the measured `kin_position` of `a`, 'y' [position of the body's reference point]))) is less than 0 metre
          AND
          the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
        ))
        SINCE
        (
          (
            ((the measured `kin_heading` of `a`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'x' [position of the body's reference point] minus the measured `kin_position` of `a`, 'x' [position of the body's reference point])) plus (the measured `kin_heading` of `a`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'y' [position of the body's reference point] minus the measured `kin_position` of `a`, 'y' [position of the body's reference point]))) is more than 0 metre
            AND
            the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
          )
          AND
          `rel_same_direction` holds of `a`, `b` at `same_dir_cos` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
        )
      ))) holds now and did not hold at the previous observation
      AND
      at the last observation of the last `window` (a parameter the caller sets) of time of `a` at which ((
        (
          ((the measured `kin_heading` of `a`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'x' [position of the body's reference point] minus the measured `kin_position` of `a`, 'x' [position of the body's reference point])) plus (the measured `kin_heading` of `a`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'y' [position of the body's reference point] minus the measured `kin_position` of `a`, 'y' [position of the body's reference point]))) is more than 0 metre
          AND
          the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
        )
        AND
        `rel_same_direction` holds of `a`, `b` at `same_dir_cos` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
      )) held: (true) — false where it held at no observation of that stretch
    )
  )
  AND
  (
    `rel_bearing` holds of `a`, `b`, 'left' [direction of b from a in a's frame (for "on the right of", "immediately to the rear")]
    AND
    (
      (
        the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is at least 0 metre
        IMPLIES
        `rel_bearing` holds of `a`, `b`, 'left' [direction of b from a in a's frame (for "on the right of", "immediately to the rear")]
      )
      SINCE
      (
        (
          ((the measured `kin_heading` of `a`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'x' [position of the body's reference point] minus the measured `kin_position` of `a`, 'x' [position of the body's reference point])) plus (the measured `kin_heading` of `a`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times (the measured `kin_position` of `b`, 'y' [position of the body's reference point] minus the measured `kin_position` of `a`, 'y' [position of the body's reference point]))) is more than 0 metre
          AND
          the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
        )
        AND
        `rel_same_direction` holds of `a`, `b` at `same_dir_cos` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
      )
    )
  )
)