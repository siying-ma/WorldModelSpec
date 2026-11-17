# NRS_484B_587_1 — task result

**Final verdict: OK** (7 witnesses, 7 names, composes nothing)

## Gate runs
1. **VACUOUS**: applicability leaf `dev_regulatory_sign_code(d, entrance|exit)` was not exercised.
   `branch_3` had no devices at all, so the code was never read. I added a regulatory sign coded
   `keep_right` on the mainline lane to `branch_3`. That still matches its narrative ("no entrance-
   or exit-coded regulatory sign"), and the code leaf now decides it.
2. **OK**.

## How the rule is written
- Class (c2): `ru_aggregate(subject, "DEF-NRS-484A-320::vehicle")`.
- Applicability (c1 + c3): there is some `regulatory_sign` device coded `entrance` or `exit`, and
  for some `controlled_access` region ca, either `rises(rel_occupies(subject, ca))` (entry) or
  `rises(not rel_occupies(subject, ca))` (departure).
- Obligation (c4): this applies to every controlled-access region ca, re-selected with
  `forallRegion`:
  - Entry: the subject occupies some `travel_region` r that a regulatory sign coded `entrance`
    governs (`dev_governs`).
  - Departure: `rises(not (occupies ca ∧ occupies some travel region governed by an exit-coded
    regulatory sign))`. The record writes it this way.

## Choices left open
None beyond the record. I declared no narrowings. The record's applicability treats c1 as a sign
being present in the scene, and I wrote it that way. The gate did not flag the device quantifier
as unanchored.

## Witnesses
They share one map: a controlled-access region with a mainline lane, an entrance ramp lane and an
exit ramp lane, plus a frontage roadway. There are 3 observations, 1 s apart. `window` is
[1000, 2000] ms because entry and departure are `rises`, which need a previous observation.
- forbid: the subject goes from the frontage road into the mainline lane → violated.
- permit: the subject goes from the frontage road to the entrance ramp to the mainline → compliant.
- idle: the subject stays on the frontage road → not applicable.
- blind: the permit trace with `dev.governs` masked → unknown.
- branch_1: the subject goes from the mainline to the exit ramp to the frontage road → compliant.
- branch_2: the subject goes from the mainline straight out to the frontage road → violated.
- branch_3: the only sign is keep_right, and the subject enters across the verge → not applicable.

## Why I finished
The gate returned OK after the second run.
