# NRS_484B_307_9a_o1 — task result

## Final verdict

**UNUSED_CLAIM** (`drv_motion_moving`). The node is wrong; see below. The files are left in their
intended state: complete formulas and nine witnesses, with no workaround.

## Gate runs

1. **Accidental run on the untouched skeletons.** I ran the gate command wrapped in a shell pipe
   (`… | head -0; true`), which broke the "exactly this command" rule. Its output was discarded, so
   I have no verdict from it. It probably used one gate run from the budget.
2. **UNUSED_CLAIM `drv_motion_moving`.** This was the first real run, with the full rule and
   witnesses. No other defect was reported before this check stopped the gate.
3. **Diagnostic, PARAM_MISMATCH.** I temporarily added the tautology `moving(x) ∨ ¬moving(x)` to the
   obligation, passing a zero literal as `tol`. The gate rejected it: `drv_motion_moving` parameter
   `tol` (m/s) needs a reading parameter, and the node declares none. I removed the tautology
   immediately, so the rule is back to its run-2 state.

## The defect in the node (for the plan agent)

- **Where:** `occasion.under_way` claims `derived: ["drv.motion.moving"]`.
- **Why it can't be written:**
  - `occasion.boundary` is `"event"`, and the only spans the occasion reads (`a1`, `a4`) are both
    `at_recognition`. No span is read `some_moment` or `throughout`, which are the only readings
    that use the under-way formula `U`. So the rule has nowhere faithful to put it.
  - Even if it did, `drv.motion.moving` takes a `tol` (m/s) parameter. Neither `params` nor
    `literals` provides one, so any call to it fails PARAM_MISMATCH.
- **What to change:** for this occasion, either
  - drop `drv.motion.moving` from `occasion.under_way.derived` (preferred; the under-way element
    does no work here), or
  - map a span `some_moment`/`throughout` that genuinely needs it, and add the speed-resolution
    tolerance parameter to `params`.

  Nothing else in the rule needs to change.

## How the rule is written (also in the rule file's header)

- **Class:** `ru_aggregate x "DEF-NRS-484A-285::traffic"`.
- **Applicability:** `¬ru_aggregate x "DEF-NRS-484A-165::pedestrian"`, and some intersection `i`
  and traffic signal `s` are selected. Then `¬ruleApplies` of `NRS_484B_307_9b_o1` … `_o4` with
  `x ↦ x`.
- **Selection of `i` and `s`:**
  - x leaves `i` at the judged observation (`rises ¬rel_occupies x i`).
  - At x's latest entry into `i`, `s` showed `circular_red` with `green_arrow(left|right|u_turn)`.
    The entry is read through `since (¬rises occ) (rises occ ∧ θ)`.
  - At that entry, either `s` governs `i`, or `s` governs a `travel_region` `c` with
    `st_lane_enters c i` that x occupied at the observation before the entry. "The observation
    before" is written with `rises` alone: `rises ¬φ ∨ (φ ∧ ¬rises φ)`.
- **Obligation:** for every selected `i` and `s`, the whole selection is written again:
  - `rises(left_turn) → green_arrow(left)` at the entry;
  - `rises(right_turn) → green_arrow(right)` at the entry;
  - `rises(straight_through) → green_arrow(straight)` at the entry.

  The left turn's band is `[left_turn_min, reversal_min)`, the right turn's
  `[right_turn_min, reversal_min)`, and the through bound is `straight_through_max`. The step is
  `p.heading_since_step_carla_scene_graph`.
- **Choices the node left open:**
  - The "green turn arrow" in the trigger is left, right or u_turn, as the a1 element lists them.
  - Each act is judged once at recognition with `.rises(<act>)`, as rule 6b asks.
  - No narrowings were declared.

## Witnesses

The trace is 20 Hz, 28 scenes, with occupancy stated per scene: entry at scene 4, exit at scene 25.
`window` is 50–1350 ms, because `rises` has no past at scene 0.

| Scenario | Setup | Expected |
|---|---|---|
| forbid | red + left arrow, straight through | violated |
| permit | red + left arrow, left turn | compliant |
| idle | circular green | not applicable |
| blind | no yaw rate | unknown |
| branch_1 | motorcycle (paragraph (b) exception) | not applicable |
| branch_2 | signal governs the intersection itself, straight through | violated |
| branch_3 | red + right arrow, right turn | compliant |
| branch_4 | red + left arrow, right turn | violated |
| branch_5 | red + left + straight arrows, straight through | compliant |

None of these were run past the UNUSED_CLAIM check, so their outcomes, and branch_1's dependence on
what the 9b nodes require, are untested.

## Why I finished

The UNUSED_CLAIM comes from the node itself: the claim has no reading to use it, and no parameter
it could be called with. The procedure says to end and report rather than work around this, and
the diagnostic run confirmed the missing parameter.
