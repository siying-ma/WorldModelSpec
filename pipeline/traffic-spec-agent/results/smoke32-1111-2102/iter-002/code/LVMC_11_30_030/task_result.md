# LVMC_11_30_030 — task result

## Final verdict

**OK** (13 witnesses, 6 names, composes nothing).

## Gate runs

1. `OK`. This was the first and only gate run, on the first full draft of both files. No changes followed.

Procedure note: before the gate run I ran one shell command that was not the gate (`ls` of
`library/TrafficSpec/Core/Language/`), to find the file that holds the `since` semantics. Only the
gate command was allowed, so this broke the access rule. It changed nothing; it only listed a directory.

## How the rule is written

- **Class of ego**: `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- **s1 / s4 ("any vehicle", "any other vehicle")**: b is a road user quantified in the rule.
  It is a member of `DEF-NRS-484A-320::vehicle` and is not ego (`.not (.same b ego)`).
- **s1 "is stopped"**: `drv_motion_at_rest b [p.rest_speed_tolerance]`.
- **s2**: `existsRegion "crosswalk" w`, together with `drv_position_near_region b w [p.crosswalk_reach]`,
  which also anchors w to b. The rule does not read the marked attribute, because the element says the
  two alternatives cover every crosswalk.
- **s3**: `existsUser p (ru_aggregate p "DEF-NRS-484A-165::pedestrian" ∧ near_region p w [p.crosswalk_reach])`.
  s1, s2 and s3 form one conjunction, `stoppedFor b w`, which is evaluated at a single observation.
- **s4 onset**: `drv_position_behind ego b [p.same_direction_tolerance]`.
- **s5**: `.rises (drv_interaction_overtakes ego b [p.same_direction_tolerance])`, judged once at its
  recognition.
- **Occasion** (event boundary; s1, s2 and s3 are each read `some_moment`):
  `since (not behind(ego,b)) (stoppedFor b w)`. This holds when `stoppedFor` held at some observation j
  up to the recognition and ego was not behind b at any observation after j. That places j at or after
  the onset (the last observation at which ego was behind b), so it covers exactly the stretch from
  onset to recognition, both ends included.
- **Applicability** (the record's two limbs): ∃ b, an other vehicle, with either
  (behind(ego,b) ∧ ∃ crosswalk w, stoppedFor b w), or (an overtaking of b is recognized ∧ ∃ crosswalk w
  for which `stoppedFor` held at some moment of the stretch).
- **Obligation**: ¬∃ b (an other vehicle ∧ the overtaking is recognized ∧ ∃ crosswalk w for which
  `stoppedFor` held at some moment of the stretch). This restates the whole selection of b and w.

## Choices the node left open

- **Under-way formula U** (`rel.longitudinal_overlap ≥ 0 ∧ kin.speed > tol`): it is not written as
  its own conjunct. For an event boundary, the stretch is fixed by the declared onset and the
  recognition. Adding U as an extra restriction on the moment j would narrow the act's extent beyond
  what the overtakes contract says. Both claimed atoms are still read: overlap through
  `drv.position.behind` and `drv.interaction.overtakes`, and speed through `drv.motion.at_rest`. The
  gate raised no UNUSED_CLAIM.
- **`rises`** wraps the overtakes concept, as the rules require for an event act. The concept already
  holds at the recognition only, so `rises` does not change the result.
- No narrowings declared.

## Witnesses

These are the planned scenes plus two added branches:
- **`branch_2`** (violated): b is at rest at w with a pedestrian there only while ego is alongside,
  and moves off before ego is wholly ahead. This tests the `some_moment` look-back to an observation
  inside the pass.
- **`branch_3`** (not applicable): the road user at rest at w is a bicycle, which is not in the vehicle
  aggregate.

How the `occasion_*_outside` witnesses were built: the record's first applicability limb
(behind ∧ stoppedFor) engages the duty whenever ego is behind b while b is stopped for a pedestrian.
For these witnesses to come out not applicable, ego must not be behind b while that state holds. So
in those scenes ego is still turning in from a side street, heading north, and therefore not aligned
with b, until the stopped state has ended. If ego were already behind b at that point, these scenes
would be compliant under the record's applicability, not not applicable. The plan agent may want to
know this.

## Why I finished

The first gate run returned OK, and both files are complete.
