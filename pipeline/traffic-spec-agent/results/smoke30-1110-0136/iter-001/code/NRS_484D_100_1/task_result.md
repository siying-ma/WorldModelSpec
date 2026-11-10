# NRS_484D_100_1 — task result

## Final verdict

`SCOPE_NARROWED`. The node is wrong on span f7. The session ended there instead of writing f7 around the missing atom.

## Gate runs

1. `SCOPE_NARROWED`: the gate refused the `no_atom` declaration on f7 (condition): "a span that decides when the rule applies is carried as the node maps it, or the node is wrong: report it in the result note". The files were not changed after this run (1 of 6 runs used).

## What is written

- **Rule file:**
  - f1 is the binder class `ru_aggregate x "DEF-NRS-484A-320::vehicle"`.
  - f2 is `existsRegion highway h (rel_occupies x h)`.
  - f3 is `¬(drv_motion_stopped x p.motion_speed_tolerance ∧ ¬kin_engine_running x)`.
  - f5 is `env_darkness`.
  - f6 is `env_visibility < Units.feet 1000`.
  - f5 and f6 are joined by `or`.
  - f4 is `(sig_headlamp x low_beam ∨ sig_headlamp x high_beam) ∧ sig_position_lamp x`.
  - f7 is declared `no_atom` and is not in the formula.
- **Witness file:** the six planned scenes, plus two extra ones:
  - `branch_3`: high beams lit, position lamps off → violated.
  - `branch_4`: halted with the engine running at night → violated, which exercises the engine limb of the exception.
- These scenes have not been judged yet, because the gate stopped at the f7 declaration.

## Choices the node left open

- **f5's one-half hour:** this is the boundary of `env.darkness`, which the reading sets. It enters no formula, so the declared 0.5 h literal is not used. The gate has not yet ruled on whether this counts as an unused or bare literal.
- **Order of the conditions:** the "at any time … ; at any other time … ; and when …" limbs are read as alternatives (`or`), as the record's applicability states.

## Why I finished — the node is wrong on f7

- **Span:** f7 (condition), "When directed by an official traffic control device."
- **The mapping:** the node maps f7 to `dev.regulatory_sign`, `dev.governs`, `rel.occupies` and `st.travel_region`. Its own justification and its gap record say these atoms cannot carry the words. No `dev.regulatory_sign` code, and no `dev.zone_sign` kind, is a direction to display lighted lamps.
- **Why I could not write it as mapped:** the only formula these atoms allow is "some regulatory sign governs a travel region x occupies". That would make the lamp duty apply under every no-parking, one-way or truck-route sign, which misstates the law.
- **Why I could not declare it unexpressed:** f7 is a condition span. The gate refuses any narrowing of a condition span, including `no_atom`, so the plan's gap cannot be filed that way from coding.

**What the plan agent must change:** either

- withdraw f7 as a gap. File the proposed atom `dev.lamp_use_sign`: a sign directing road users on the stretch it governs (`dev.governs`) to display lighted lamps. Drop f7's element and remove its atoms from the claims. `rel.occupies` stays claimed for f2. `dev.regulatory_sign`, `dev.governs` and `st.travel_region` would then be unclaimed. Or
- once such an atom exists, re-map f7 to it, anchored by `rel.occupies` on a governed travel region.

Everything else in the node (f1–f6) is written and ready.
