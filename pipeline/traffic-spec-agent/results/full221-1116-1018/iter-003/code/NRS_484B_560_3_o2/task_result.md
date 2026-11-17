# NRS_484B_560_3_o2 — task result

## Final verdict: OK (10 witnesses, 20 names, composes nothing)

## Gate runs
1. **BARE_LITERAL** — the formula carried no literal, but the node declares `4 count` (s8). I had
   written "four or more lanes" as four existential lane quantifiers, pairwise distinct, with no
   numeric literal.
   Change: the four pairwise-distinct lanes are still found by the quantifiers. They now feed the
   term `lanesOnWayUpToFour := cond(four distinct lanes on h, 4 count, 0 count)`, and the
   exception is `lanesOnWayUpToFour ≥ 4 count`. The text's figure now appears as `.lit 4 .count`,
   and the result is the same as before.
2. **OK**.

(After run 2 the only change was to the header comment, to describe the final s8 writing.)

## How the rule is written
- Class (s3): `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability = s2 ∧ s1 ∧ ¬s8:
  - s2: some `railway_crossing` region c with `st_region_geometry_distance(subject, c) ≤ p.railroad_crossing_approach_reach`.
  - s1: some `travel_region` r that the subject occupies, governed (`dev_governs`) by one of:
    - a railway signal or gate with lights flashing, or gate lowering or down;
    - a stop sign;
    - a traffic signal showing circular_red;
    - a human direction with role police_officer or railroad_flagger and indication stop.
  - s8: some `highway` h that the subject occupies has four or more lanes on it, counted as described under run 1.
- Obligation (s7): for every railway crossing c within the reach of the subject (the
  applicability's selection of c, written again), there is no road user v that:
  - is not the subject;
  - is a member of `DEF-NRS-484A-285::traffic`;
  - occupies a `lane`;
  - has its body within the reach of c;
  - has `rel_same_direction(subject, v)` with `p.side_by_side_same_direction_cos`;
  - has `rel_longitudinal_overlap(subject, v) > 0`.

## Choices the node left open
- **The four-lane count.** The language has no count over regions, so "four or more" is four
  pairwise-distinct lane quantifiers wrapped in a `cond` that carries the literal (see run 1).
  This does not narrow the text, so I declared no narrowing.
- **Which crossing.** The obligation uses ∀ over the crossings selected the same way as in the
  applicability, so the duty holds at each crossing the subject is at.
- **No narrowings of my own.** The record's own readings already cover s7 and the observable
  readings.

## Witnesses
The planned scenarios are `forbid`, `permit`, `idle`, `blind`, `branch_1` (four lanes, not
applicable) and `branch_2` (subject alone, compliant). In `blind`, the device has
`governsObserved := false`, and the manifest masks `dev.governs`.

I added four branches, each expecting violated, so that each halt-device limb is exercised:
- `branch_3`: lights dark, gate down.
- `branch_4`: stop sign.
- `branch_5`: red signal.
- `branch_6`: railroad flagger directing stop.

Geometry is in the witness header. Margins against the reading: the cars beside each other are
9 m and 10 m from the crossing (reach 15.2 m) and overlap by 3 m. In `permit` the subject is 13 m
from the crossing and the gap between the cars is 8 m (overlap −8 m).

## Why I finished
The gate returned OK on run 2 of 6.
