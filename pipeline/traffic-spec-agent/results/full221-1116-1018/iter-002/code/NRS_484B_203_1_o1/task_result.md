# NRS_484B_203_1_o1 — task result

## Final verdict

`WITNESS_FAIL` on `blind` only. The `blind` scenario the node plans can't be built: masking only
`rel.bearing` can never make this rule unknown on a trace the adapter accepts. **The node is wrong:**
its planned `blind` masks need to change (see below).

## The rule (as written)

- Class of `subject`: `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability (h1, "proceeding"): `¬ drv_motion_complete_halt(subject; p.halt_speed_tolerance)`.
- Obligation (h1 + h2), for every road user `other`:
  `ru_aggregate(other, vehicle) ∧ ∃ highway way (rel_occupies(subject, way) ∧ rel_occupies(other, way))
   ∧ rel_oncoming(subject, other; p.oncoming_heading_cos) ∧ rel_longitudinal_overlap(subject, other) > 0`
  → `rel_bearing(subject, other, left)`.
- Narrowings: none of my own. Every reading comes from the record: "alongside" is a shared projection
  length above zero, and "keeping to the right" is the other vehicle's lateral component on the
  subject's left.
- Choice: I wrote no `same` exclusion of the subject from the `other` quantifier. A road user is never
  oncoming to itself because its headings are aligned, so the case is already decided.

## Witnesses

These are the planned witnesses plus extra `branch_<n>` tests:
- `forbid`: an oncoming car is alongside on the right.
- `permit`: an oncoming car is alongside on the left.
- `idle`: the subject is at rest.
- `blind`: the planned scenario, which can't be built (see below).
- `branch_1`: the subject is alone on the road.
- `branch_2`: an oncoming bicycle passes on the right (not a vehicle). Expects compliant.
- `branch_3`: an oncoming car passes on the right on a different highway. Expects compliant.
- `branch_4`: a same-direction car is alongside on the right. Expects compliant.
- `branch_5`: an oncoming car on the right is still 30 m ahead, not alongside. Expects compliant.
- `branch_6`: the subject is a bicycle. Expects not_applicable.

In run 3 the gate reported only `blind` as failing.

## Gate runs

1. On the untouched skeleton, by mistake: `UNUSED_CLAIM`, since every claim was still `.tt`.
2. An accidental re-run while piping the output, with the skeleton unchanged: `UNUSED_CLAIM`.
3. After writing the rule and all witnesses: `WITNESS_FAIL — blind: expected unknown, got violated`.
   I then read `Runtime/Manifest.lean`. Masking `rel.bearing` drops only the measured `bearing` field.
   `rel_bearing` falls back to computing from `kin.position` (both tracks) and `kin.heading` (subject).
4. An accidental run with no change to the files (`… | head -0`): its verdict is the same as run 3.
5. I changed `blind` so the source didn't report the subject's heading, and supplied a measured
   `oncoming` and `longitudinalOverlap`. Result: `WITNESS_FAIL — blind: its trace is not one the
   adapter can produce: track 1 is in occupancy_observed but lacks a position, a non-zero heading or
   an extent`. Afterwards I put `blind` back to the admissible forbid geometry, which evaluates to
   violated.

## Why I finished — the node is wrong (scenario `blind`, masked `["rel.bearing"]`)

The obligation needs both vehicles' occupancy: `rel.occupies` with `st.highway`, which comes from h2's
element. The adapter accepts a track with observed occupancy only if it has a position, a non-zero
heading and an extent, so that its footprint is defined. Those same fields are everything
`rel_bearing`'s fallback reads (`relFrame`: both positions and the subject's heading). So on any
accepted trace where `rel_bearing(subject, other)` matters, Core computes it, and masking `rel.bearing`
removes nothing that decides the verdict.

There are two ways around this, and both break the plan:
- Leave a track's occupancy unobserved. The rule is then unknown because of `rel.occupies`, which is
  not masked.
- Remove the kinematics. The source then can't compute `rel.oncoming` or `rel.longitudinal_overlap`
  either.

**What the plan agent must change:** the `blind` scenario's `masked` set. One option that can be
built is `["rel.bearing", "rel.occupies"]`. Masking `rel.occupies` clears the occupancy observation,
so the subject's heading may be missing. The source can then supply measured
`oncoming`/`longitudinal_overlap`, which Core can't compute without that heading, and the only unknowns
come from `rel_occupies` and `rel_bearing`, both masked. The alternative is to plan `blind` on another
claimed atom that Core cannot compute from the scene. The rule itself needs no change.
