# LVMC_11_43_010_B_o2 — task result

## Final verdict
**OK** (6 witnesses, 5 names, composes nothing).

## Gate runs
1. **OK**: this was the first run, so nothing changed after it.

## How the rule is written
- **Class (b2, b4):** `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- **Applicability (b3, b5, b12):** `existsRegion roundabout r (rises (rel_occupies subject r))`. This is the entry event: the subject occupies `r` at this observation and did not at the one before.
- **Obligation (b9, b10, b11):** `forallRegion roundabout r (rises (rel_occupies subject r) → forallUser u ((¬ same u subject ∧ ru_aggregate u "DEF-NRS-484A-285::traffic" ∧ rel_occupies u r) → ¬ (prim_closest_approach_within(subject,u; p.roundabout_critical_gap) ∧ prim_closest_approach_distance(subject,u; p.roundabout_critical_gap) < p.conflict_centre_clearance)))`.
  - The obligation repeats the applicability's whole selection of `r`.
  - Where the centres do not approach within the horizon, the first operand of the conjunction is false. So the undefined distance never decides the result.

## Choices the node left open
- None that needed a narrowing; `narrowings` is empty.
- The "every roundabout entered" quantifier and the order of the conjunction are as the record states them.

## Discrepancy in the node (reported, not repaired)
- The record's `obligation` text says "the subject is not in contact with u (rel.contact)". But **rel.contact is claimed by no element or operationalization**.
- Rule 3 allows formulas to use only claimed names, so the rule leaves the contact conjunct out. It states only the closest-approach gap test.
- This matters in one case: `closestApproach` returns none when the closing time t* < 0 (the bodies are moving apart). So a road user that is already in contact with the subject but moving away is not caught by the gap test.
- **What the plan agent should change:**
  - either add `rel.contact` to the b10/b11 element (or to the operationalization), so it can be written;
  - or drop the contact clause from the obligation text.

## Witnesses
- **forbid:** a pedestrian on a crosswalk inside the roundabout. Closest approach is about 0.5 m after about 1.5 s.
- **permit:** the car waits, then enters.
  - One circulating car approaches, but its closest approach is 10 m at 3.8 s.
  - A second car is moving away and never approaches.
- **idle:** a car on a roadway with no roundabout.
- **blind:** the forbid trace with `rel.occupies` masked.
- **branch_1:** the car enters an empty roundabout.
- **branch_2** (added): a following car outside the roundabout closes on the subject as it enters. The result is compliant, because only road users in the roundabout count.

## Why I finished
The gate returned OK on the first run.
