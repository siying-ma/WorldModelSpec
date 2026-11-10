# NRS_484B_250_1 — task result

## Final verdict

**VACUOUS** — only one leaf is left: `obligation leaf 8: ruleApplies NRS_484B_250_4_o2`. Every other leaf is exercised and all 19 witnesses give their expected verdicts.

## Gate runs

1. **UNUSED_CLAIM** on the untouched skeleton (`.tt` placeholders). I ran it by mistake before writing anything. Then I wrote the rule and 12 witnesses.
2. **WITNESS_FAIL** on branch_1, branch_4 and branch_6: "track keeps the heading … but its yaw rate turns it 10° over the interval". The adapter check holds each yaw rate over the interval before its scene. **Change:** turning vehicles now get headings turned 10° per second (east10, west10, west20, given to 10⁻⁸).
3. **VACUOUS** on the obligation's restated leaves: `st_lane_enters r i` and `dev_governs` (s8), the two `int.turn_left` intents and the two `drv_motion_turning_left` leaves (s10/s11), and `ruleApplies NRS_484B_250_4_o2`. These restated leaves only matter at an instant where the rule applies and the restatement changes which y or i counts. **Changes:**
   - Added a third vehicle z: it entered i from cB, is leaving it, and is in no conflict. It keeps the rule applicable, so an excepted y that would conflict now moves the verdict. This gave branch_9–12 (compliant), one per exception limb.
   - Added branch_13 (violated): a stop sign governs the approach L2 to a second intersection i2, so it does not control i.
   - Moved the opposed vehicle y to 3 m lateral offset from x so that it conflicts.
4. **VACUOUS** with only o2 left. **Change:** added branch_14 (violated). The signal is inoperative, and x halts at a marked stop line for two instants before entering while y crosses. This guessed that o2 is a "proceed after stopping" duty that engages without o1.
5. **VACUOUS**, o2 still not exercised; branch_14 passes as violated.

## Choices the node left open

- **Carriers exclude intersections.** c, cy and the s8 region r are quantified over `travel_region`, as the record maps them. Because an intersection is a travel region, c and cy also carry `not (st_intersection ·)`. The `st.lane_enters` contract defines a carrier as a lane or a roadway-like directed segment, so this states the contract rather than narrowing the reading. Without it, an intersection region (whose entry topology no source records) reads `st_lane_enters` as unknown and blocks every decided verdict.
- **s8 regions.** "Governs i or a carrier whose entrance end is i" is one region quantifier with `(same r i ∨ st_lane_enters r i)`. It is followed by one device quantifier per kind (traffic signal, stop sign, yield sign) with `dev_governs d r`.
- **s7 compositions.** The two `unless` compositions are conjoined into s8 as `¬ruleApplies` with x ↦ x. The applicability and the obligation both negate the whole of s8.
- **Exception directions.** The s9 dot product uses the `st_lane_direction` components `x` and `y` of c and cy.
- **"Entered" (s5)** is `since (rel_occupies y i) (rel_occupies y cy ∧ st_lane_enters cy i)`.
- **Obligation.** For every c and i, it restates the whole selection: approach, ¬s8, the y-selection with s6 and the exception. Then it requires: where x also occupies i and is moving, no selected y is in conflict.
- **Narrowings:** none added.

## Why I finished

The o2 leaf can only be exercised by a scene in which NRS_484B_250_4_o2 applies to x and NRS_484B_250_4_o1 does not. That situation is defined by o2's applicability, which I may not read. Branch_2 shows o1 engaging without o2 when x drives straight in under an inoperative signal. Branch_14 (x halts first, then enters) did not separate them either. One gate run was left, but there was no informed change to make with it.

## For the plan agent

Span **s7**, composition `NRS_484B_250_4_o2` (as `unless`, scopes s8): the node plans no scenario in which o2 applies and o1 does not, so its suspension of s8 is never exercised. The plan should do one of these:

- add a `branch_<n>` scenario, written from o2's applicability, in which o2 applies to x and o1 does not, at an observation where x enters i with a vehicle that entered from another highway in conflict (expected violated); or
- if o2's applicability implies o1's, drop the o2 composition as redundant.
