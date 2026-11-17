# drv.interaction.overtake_pass_on_right — task result

## Final verdict
**OK** (gate run 1 of 6): 3 witnesses, 6 names, reads 6 atoms.

## Gate runs
1. `OK` — first run, on the body and witnesses described below. Nothing changed after it.

## Body
`overtake_pass(a, b; window, same_dir_cos) ∧ onLeft ∧ since (sideBySide → onLeft) aheadAligned`
- `onLeft` = `rel_bearing a b "left"` (the lateral component of b's bearing is positive).
- `sideBySide` = `rel_longitudinal_overlap a b ≥ 0`.
- `aheadAligned` = `lon > 0 ∧ overlap < 0 ∧ rel_same_direction a b [same_dir_cos]`. Here `lon` is the
  component of b's position minus a's position along a's heading (`kin_heading`, `kin_position`),
  computed the same way `overtake_pass` computes it.
- `since` is ψ ∨ (φ ∧ previous). It therefore reaches back to the latest observation where b was
  ahead with the headings aligned. That observation is the act's onset, and `overtake_pass`
  requires it to lie in the window. The recognition, the extent ("not again until…") and the
  history limit all come from `overtake_pass`.

## Choices the record left open
None needed a narrowing. The words map directly onto the operators: "at every observation since
the act began at which the two are side by side" becomes `since` with an implication.

## Note for the plan agent (the blind scenario)
In Core, a computed `rel.bearing` is `relFrame`, built from `kin.position` and `kin.heading`.
Masking `rel.bearing` only drops a *measured* bearing. When the positions and headings are
observed (and `overtake_pass` needs them at the recognition), the side is always computable. So
the narrative as written ("rel.bearing not observed … the side … there and while side by side
cannot be read") cannot be realised at the recognition instant.

How the blind witness reaches unknown:
- Its source loses the positions while the two are side by side (k5–k7) and measures the bearing
  and the overlap on the relation instead.
- Core cannot compute either value there, so supplying them is allowed.
- `overtake_pass` does not need positions at side-by-side observations, because the measured
  overlap already decides that b is neither ahead nor behind.
- With `rel.bearing` masked, the side-by-side part of the condition is unknown, and the only
  reason given is the bearing that was dropped. With the bearing observed, the trace is the
  compliant pass.

The gate accepted this. A future record that needs a bearing-blind witness should expect it to
work only where the positions are not observed.

## Why I finished
The gate returned OK.
