# NRS_484B_210_2 — task result

## Final verdict

`WITNESS_FAIL`: `blind: expected unknown, got compliant; the manifest masks rel.bearing`.
**The node is wrong.** Its planned `blind` scenario cannot be satisfied under Core (see below).
The rule and the other five witnesses are written and build.

## Gate runs (3 of 6 used)

1. `UNUSED_CLAIM` on the harness skeleton (all `.tt`). This was a baseline run before any edit.
   It confirmed that the occasion's `under_way` atoms (`kin_velocity`, `rel_bearing`,
   `rel_longitudinal_overlap`, `rel_same_direction`) are claims that the rule must use.
2. `WITNESS_FAIL` (blind only) after writing the rule and six witnesses (forbid, permit, idle,
   blind, branch_1, branch_2). No other witness was reported as failing.
3. None. I stopped because the remaining failure is a defect in the node.

## How the rule is written

- **Class (s1):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (s2):** there is some road user `b` such that `ru_aggregate b vehicle`, `b`
  is not the subject, and `drv_interaction_overtake_pass_on_right(subject, b)` holds with
  `[p.overtake_window, p.overtake_same_direction_cos]`.
- **Obligation (occasion: window boundary, read throughout):** for every `b` that the same
  selection picks:
  `holdsFor .time p.overtake_window subject (underWay b → safe)`.
  - `underWay b` is `until (¬aheadAligned ∧ closing) (overtake_pass_on_right subject b)`.
    This reads as: from this observation up to the recognition, `b` is not ahead with aligned
    headings and the subject is gaining on it. So the observation lies after the act's beginning
    and at or before its recognition, as the under_way justification says.
  - `aheadAligned` is the conjunction of:
    - `rel_bearing(subject, b, "ahead")`
    - `rel_longitudinal_overlap < 0`
    - `rel_same_direction` with `p.overtake_same_direction_cos`
  - `closing` is `|v_s|² > v_b·v_s`, built from `kin_velocity` x/y components.
- **Standard (s3, operationalization):** for every road user `u` other than the subject, it is
  not the case that `rel_contact(subject, u)` holds, or that `prim_closest_approach_within`
  holds with `prim_closest_approach_distance` below `p.conflict_centre_clearance` (both over
  `p.conflict_horizon`).

## Choices the node left open

- **"Exceeding b's along its heading" uses velocity.** `kin.heading` is not claimed by the
  under_way element, so the subject's own velocity direction stands in for its heading. The
  comparison is written without division: (v_s − v_b)·v_s > 0. This is recorded in the header;
  it is not a narrowing on a duty span.
- **The act's beginning observation is excluded.** The obligation's prose says "from its
  beginning", but the under_way justification says an observation "lies after its beginning", and
  I followed the justification.
- **Two extra witnesses cover leaves the planned scenes don't reach:**
  - `branch_1` (compliant): the conflict happens before the act begins. It exercises
    `rel_bearing`, `rel_same_direction` and `rel_longitudinal_overlap`.
  - `branch_2` (violated): a third car touches the subject with no closest approach, so only
    `rel_contact` decides the verdict.

## Why the node is wrong (the `blind` scenario)

- **What the node plans.** The `blind` scenario masks `rel.bearing` alone and expects
  `unknown`: "whether a pass on the right occurred is unknown".
- **Why Core never makes the bearing unknown this way.** `rel.bearing` is a computed relation.
  `rel_bearing` falls back to `relFrame`, which computes it from `kin.position` and `kin.heading`
  (`Core/Vocab/Atoms.lean`, `rel_bearing` / `relFrame`). Masking only drops a *measured* value:
  `Mask.scene` documents "The computed relations are blanked through the kinematics they would
  be computed from only when the source lacks those too; a measured value is dropped"
  (`Core/Runtime/Manifest.lean`).
- **What happens as a result.** With `rel.bearing` absent but positions and headings observed,
  the bearing is still computed. The concept `drv.interaction.overtake_pass_on_right` is decided,
  and so is every formula reading it. The gate got `compliant`.
- **The only way to make the bearing unknown** is to leave a position or heading unobserved. That
  makes the concept's own direct reads unknown too: `kin.position`, `kin.heading`,
  `rel.longitudinal_overlap` and `rel.same_direction`. Those unknowns are not masked ids, so the
  witness would fail as "unknown for an unmasked atom".
- **The rule can't fix this.** No formula over the claimed names can make this witness unknown
  for `rel.bearing` alone. This is not a concept defect either: under Core's masking policy the
  concept is right to decide when the bearing can be computed.

**What the plan agent must change:** re-plan the `blind` scenario so that its masked set can
actually leave the pass undecided. For example, mask `kin.position` together with the relations
computed from it that the rule reads (`rel.bearing`, `rel.longitudinal_overlap`, `rel.contact`),
so that every resulting unknown traces to a masked id. Another option is to choose the masked
atoms so that each unknown they cause is itself masked. Masking `rel.bearing` alone can't work.

## Why I finished

The rule and the forbid, permit, idle, branch_1 and branch_2 witnesses pass the gate as far as it
reported. The only failure comes from the node's planned `blind` mask, which Core can't satisfy.
Fixing it means changing the node's `scenarios[blind].masked`, which belongs to the plan and not to
the coding session.
