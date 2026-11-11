# Plan — NRS-484B-307-9a (iteration 6)

The law came back for one reason only. Both nodes composed `NRS_484B_307_9b_o1` against a record of it that is no longer current (pin_mismatch). Since then `NRS_484B_307_9b_o1` has been accepted again, and the library lists it as composable (build). Its current applicability is the condition this law's exception needs: a motorcycle, moped, bicycle, electric bicycle or electric scooter leaves the intersection after entering it under circular_red with green_arrow(d), and its passage is straight through or a turn opposite d. So the fix is to re-plan against that current record. Rule 11 says to keep every mapping the returned reason does not concern, so the segmentation, elements, operationalization, narrowings and scenarios carry over unchanged from the iteration-4 plan, which the validator accepted. Neither node claims the failed concept `drv.position.entered_via`. Approach and entry are read directly through `drv.motion.entering_region`, `rel.occupies`, `st.lane_enters` and `dev.governs` on the bound intersection and carrier.

## NRS_484B_307_9a_o1 — only the movement the arrow indicates

- **Decision:** The node is judged at x's leaving of the intersection i that it entered under a steady red with a green arrow from a governed approach. It requires the heading change since entry (`drv.motion.heading_change_since_entry`, step `p.heading_since_step_carla_scene_graph`) to reach `p.turn_recognition_angle` toward the arrow's side.
- **Subject:** "vehicular traffic" is the admitted traffic aggregate minus the pedestrian aggregate.
- **Exception:** "Except as otherwise provided in paragraph (b)" composes `NRS_484B_307_9b_o1` as an exception. Paragraph (b) covers exactly the cycle and scooter passages that go straight or turn opposite the arrow.
- **Reversal signal:**
  - If the operator holds the paragraph (b) exception to require (b)'s conditions to be met, not only engaged, the composition becomes a conjunction of compliance with `NRS_484B_307_9b_o1`…`_o4`.
  - If `NRS_484B_307_9b_o1` is superseded again, re-pin.

## NRS_484B_307_9a_o2 — yield to pedestrians in an adjacent crosswalk and to other traffic in the intersection

- **Decision:** While x is inside i after such an entry and moving, no pedestrian in a crosswalk marking an entrance into i, and no other traffic occupying i, may be on a predicted closest approach within `p.immediate_hazard_gap` and below `p.conflict_clearance`. This operationalizes the right-of-way standard of DEF-NRS-484A-210 and is not a surrogate.
- **Mapping:** The yield-parties span reuses the mapping index entry of `NRS_484B_307_9b_o4` for the same words.
- **Narrowing:** "Lawfully" is not read; this is disclosed as a narrowing.
- **Exception:** The exception composition is the same as in o1. The exception is engaged only at a leaving observation, so a cycle inside i stays under this duty. That duty is word for word the same yield that (b)(4) imposes, so no verdict changes.
- **Reversal signal:**
  - A labelled cycle passage on which this yield and (b)(4) diverge.
  - A gate finding that the exception must be engaged inside the intersection.

## For the operator

- The returned reason was a stale pin, not a defect of meaning. The nodes are re-emitted against the current `NRS_484B_307_9b_o1`, with no change in content.
- `drv.position.entered_via` stays failed. These nodes do not depend on it.
