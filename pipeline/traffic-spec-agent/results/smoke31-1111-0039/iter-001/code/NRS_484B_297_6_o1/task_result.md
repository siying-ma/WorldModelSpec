# NRS_484B_297_6_o1 — task result

**Final verdict: UNEXPRESSED** (s4, `no_atom`), plus a plan defect in the `blind` scenario (below).

## Gate runs (2 of 6)

1. **WITNESS_FAIL**: the rule built and passed its static checks. `forbid`, `permit` and `idle` reached
   their verdicts. `blind` failed: `unknown for [window_truncated:since], not for an atom the manifest masks`.
   After this run I added the `no_atom` declaration on s4.
2. **UNEXPRESSED**: s4 (`no_atom`), which files the gap the record already carries (`st.impassable_section`).

## The rule as written

- Class: `ru_aggregate x "DEF-NRS-484A-165::pedestrian"`.
- Applicability: there is a sidewalk `w` and a highway `h` with `st_on_way w h`, and right now `x` occupies `h` and no
  sidewalk (∀ sidewalk `s`, ¬`rel_occupies x s`). It is also `since(φ, ψ)`, where φ is that same now-condition
  and ψ is: `x` occupies `w`, `drv_motion_moving x [p.speed_resolution]`, and some obstruction `o` has
  `st_region_geometry_distance x o ≤ p.obstruction_encounter_reach`.
- Obligation: `moving x →` for every road user `z` other than `x`, not both
  `prim_closest_approach_within x z [p.immediate_hazard_gap]` and
  `prim_closest_approach_distance x z [p.immediate_hazard_gap] < p.conflict_clearance`.
- Choices the node left open: none of substance. "No sidewalk" ranges over every sidewalk in the scene, as the
  record says. `since` is Core's past strong since, so the onset at the sidewalk has to be recorded.
- Narrowings: only the s4 `no_atom` declaration. The record's own narrowings on s5 and s7 are not restated.

## Witnesses

There is a highway with a sidewalk and a roadway on it, and a barrier on the sidewalk. The pedestrian is
0.75 m from the barrier at t=0, then on the roadway at t=1 s and t=2 s. A vehicle 10 m ahead closes at
11.3 m/s, reaching its closest approach of 1 m in about 0.9 s. `idle` has no obstruction, and the
pedestrian never leaves the sidewalk.

## Why I finished — what the plan agent must change

1. **s4 gap (`no_atom`).** "A short section of the sidewalk that is missing or impassable" is not a physical
   object, so `st.obstruction` does not cover it. The record's own justification says so, and its gap
   proposes `st.impassable_section`. My formula covers only the case of an obstruction object. I declared
   `no_atom` so the gap is filed. This is a condition span, so it cannot be narrowed.
2. **The `blind` scenario is impossible as planned.** The applicability's `since` searches the past for a
   point where both operands are decided, and both operands read `rel.occupies`. Masking `rel.occupies`
   leaves φ and ψ unknown at every observation. Core's `sinceAll` (`ψ ∨ (φ ∧ since')`, with the unobserved
   past as the head) therefore carries `window_truncated:since` into every instant's unknown, and no trace or
   padding can remove it. The gate requires the unknown to come only from the masked atom. The plan should
   mask an atom read only at the judged observation:
   - `st.on_way` makes the applicability unknown, with absent `st.on_way` as the only reason.
   - Alternatively, `kin.velocity` makes the obligation unknown through the closest-approach primitives
     (`kin.speed` would not work, because ψ reads it too).

   The narrative would change to match, e.g. "As forbid, but st.on_way of the sidewalk is not observed".
   The forbid trace with that mask should then give unknown for the masked atom alone.
