# Plan — batch 03, iteration 4

## `NRS_484B_363_4` (NRS-484B-363-4)

**Decision.** I kept the iteration-3 record and changed only the `blind` scenario. It now masks
`rel.longitudinal_overlap` instead of `kin.position`.

**Reason.** The returned reason was the gate's WITNESS_FAIL on `blind`:
- Masking `kin.position` (iteration 3) made the derived relations `rel_longitudinal_overlap` and `rel_bearing` absent, and the trace had a truncated window. The rule was unknown, but not because of the masked atom.
- Masking `rel.bearing` (iteration 2) left the pass decided. `drv.interaction.overtake_pass` takes the bearing from `kin.position` and `kin.heading`, not from `rel.bearing`.

The concept reads `rel.longitudinal_overlap` directly: "b is ahead … and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative)". Masking it therefore leaves "ahead" and "behind" undecided, so the pass and its verdict are unknown for the masked atom itself. The narratives of `blind` and `forbid` now say the recording begins more than `p.overtake_window` before the recognition, so the window is not truncated.

`param_proposals` is now empty, because every parameter it names is in the catalogue. Every span mapping matches the index (NRS_484B_363_1/2/3).

**Reversal signal.** A gate run in which the masked overlap does not make the rule unknown. That would mean the coded pass never reads the overlap.

## `NRS_484B_587_2a` (NRS-484B-587-2a)

**Decision.** I kept the record and added atom gaps on e12 (authorized emergency vehicle; e13 shares its aggregate) and e15 (tow car). The law blocks until the operator decides.

**Reason.** The gate returned VACUOUS: the subject's `ru.aggregate` leaves for `DEF-NRS-484A-020::authorized_emergency_vehicle` were never exercised, and neither literal variant was. In iteration 2 the gate already reported `aggregate_unresolved` for both this id and `DEF-NRS-484A-280::tow_car` on a transit bus. The operator's feedback on G86 confirms that the run's reading classifies every class under the AEV id as unresolved, so membership is unknown for every road user. No witness can make the leaf decide, and a third coding attempt would close the law as failed.

Rule 0/3 rules out the alternatives:
- The admitted aggregate cannot be replaced by `ru.emergency_vehicle` or by `ru.official_vehicle` kind tow.
- Dropping the class restriction would widen subsection 3's exception to every vehicle a sign admits.

So the gaps record what is missing: either a class atom or an operator decision on the reading. That is the same decision G86 asks for, and the same kind of decision G82/G83 ask for.

The other mappings are unchanged: e14/e16 use `ru.official_vehicle`, e17 uses `ru.transit_bus`, and e8 is a definition reference to NRS 484B.210.

**Reversal signal.** The operator classifies included members under either id (or retires the gaps). The record is then coded as is and lists both gaps in `gap_resolutions`.

## `NRS_484B_777_1_o1` (NRS-484B-777-1)

**Decision.** I re-emitted the record unchanged except that `param_proposals` is now empty, because all six parameters are in the catalogue. The composition on s3 still names `NRS_484B_785_1a` as `compliance`.

**Reason.** The returned reason was a pin mismatch: `NRS_484B_785_1a` was revised and re-accepted in iteration 3, after this node was planned against its earlier version. The accepted version keeps the duty this exception relies on: an electric scooter on a roadway or bicycle lane/path travels at no more than 15 mph. A bicycle or an electric bicycle does not engage it, so for them it counts as complied with, which is the intended reading of "lawful rate of speed". Re-planning against the current record restores the pin.

The accepted sibling `NRS_484B_777_1_o2` is not re-planned or re-emitted. Its segmentation (same cut; s1 subject, s2 condition) is unchanged here.

**Reversal signal.** A further revision of `NRS_484B_785_1a`, or a gate defect on exception (a).

## For the operator

- **DEF-NRS-484A-020::authorized_emergency_vehicle (G86, and the new gap on NRS-484B-587-2a e12).** The reading includes no class. Every rule that lists authorized emergency vehicles as an exception or a subject is therefore vacuous on that leaf. A reading decision, such as `ru.emergency_vehicle` and `ru.fire_apparatus` included and the other classes excluded, would unblock this and the other affected laws together.
- **DEF-NRS-484A-280::tow_car (new gap on NRS-484B-587-2a e15).** The gate evidence shows no included class. Including `ru.official_vehicle` of kind tow, and excluding the bus classes, would decide it.
