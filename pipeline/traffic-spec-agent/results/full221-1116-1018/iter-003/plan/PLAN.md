# Plan — iteration 3

## `NRS_484B_413_2` (NRS-484B-413-2)

**Decision.** I re-planned the node from its iteration-1 record. The segmentation, elements, assumptions, residue, scenarios and literals stay as they were. The law came back because the plan did not carry the concept record `drv.lane.heading_left_of_carrier`, which span s6 ("prior to changing the course") claims. The validator had returned that record because it has the same sorts and atoms as the accepted `drv.lane.heading_right_of_carrier`. This plan proposes it again with `differs_from`.

The left concept is the mirror state: the heading is turned left of the carrier's direction, so the cross product is above +sin_tol. The accepted right concept's contract expressly excludes this case ("a heading … turned to its left"). Its formals are a track and a region, so neither swapping them nor negating anything gives the left side. A literal side formal would decide nothing, because no operator compares a literal formal with a spelling. So the two sides have to be separate concepts. The law needs both, because the signal must show the side the course departs to.

**Obligation wording.** The obligation now states the district split as two branches with constant window lengths:
- the assumption holds and the 100 ft `.path` window applies; or
- the assumption does not hold and the 300 ft window applies.

Before, it was a `Term.cond` inside the window length. A window's length must be a constant term, and a condition is not one.

**Signals that would reverse this.**
- The concept review finds the left contract to be a restatement of the right one. Then the remedy is an operator change: a side argument the language can read.
- The gate finds that `definedWhen` on lane occupancy makes the rule unknown on ordinary intersection traversals. Then the trigger would be re-read over occupied carriers that have a designated direction.

## Concept `drv.lane.heading_left_of_carrier`

**Decision.** Proposed with the same contract shape as `drv.lane.heading_right_of_carrier`, mirrored. It reads `kin.heading`, `st.lane_direction` and `kin.speed`, and takes the parameters `sin_tol` (ratio) and `speed_tol` (m/s). The `differs_from` field states why it is a separate concept.

**Reversal signal.** A catalogue entry that covers either side with one formal the language can honour.

## For the operator

- `drv.lane.heading_right_of_carrier` and `drv.lane.heading_left_of_carrier` differ only in the sign of one cross product. The duplicate-concept check flags such mirror pairs automatically. Whenever a law needs "to the side of the manoeuvre", it requires a `differs_from` declaration, or a Core way to pass a side the body can read.
