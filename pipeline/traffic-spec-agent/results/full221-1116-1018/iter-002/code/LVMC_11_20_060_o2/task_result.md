# LVMC_11_20_060_o2 — task result

**Final verdict: OK** (13 witnesses, 9 names, composes nothing)

## Gate runs
1. OK — first run, after writing both files in one pass. Nothing changed afterwards.

## Rule as written
- Class of `subject`: `ru_aggregate subject "DEF-NRS-484A-320::vehicle"`.
- Applicability: `asm.business_or_residence_district` ∧ (∃ `driveway_or_alley_entrance` region d occupied by subject ∨ ∃ `alley` region d occupied by subject) ∧ ∃ `sidewalk` region s occupied by subject.
- Obligation: ∀ road user p, (¬ same p subject ∧ `ru_aggregate p "DEF-NRS-484A-165::pedestrian"`) →
  ¬(`kin_speed subject` > `p.halt_speed_tolerance` ∧ `prim_closest_approach_within subject p [p.conflict_horizon]` ∧ `prim_closest_approach_distance subject p [p.conflict_horizon]` < `p.conflict_centre_clearance`) ∧ ¬`rel_contact subject p`.
  This is the record's obligation exactly as it is written.

## Choices the node left open
- e8 ("to any pedestrian") is the guard of the obligation's universal quantifier over road users. The record's obligation puts it there, and its applicability does not mention pedestrians.
- The regions bound in the applicability (d, s) are not read again in the obligation, because the duty is stated over pedestrians and not over regions. Rule 3c therefore does not apply.
- I added no narrowings. The record's own narrowings (agency on e1, the precedence reading on e7) are not restated.

## Witnesses
- The planned scenarios are forbid, permit, idle, blind (kin.speed masked) and branch_1.
- I added branch_2 to branch_9 so that every leaf is exercised:
  - branch_2: coming out of an alley (violated).
  - branch_3: contact while creeping at 5 cm/s, which is within the halt tolerance (violated).
  - branch_4: the pedestrian walks away from the subject, so the centres do not approach (compliant).
  - branch_5: the closest approach is about 4.5 m, above the clearance (compliant).
  - branch_6: the place is known not to be a business or residence district (not applicable).
  - branch_7: the subject is in the driveway but short of the sidewalk (not applicable).
  - branch_8: the subject is a bicycle (not applicable).
  - branch_9: the other road user is a motor vehicle, not a pedestrian (compliant).

## Why I finished
The gate returned OK on the first run.
