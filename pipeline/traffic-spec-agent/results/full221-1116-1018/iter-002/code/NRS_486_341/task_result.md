# NRS_486_341 — task result

## Final verdict
WITNESS_FAIL (on `blind` only). The planned `blind` witness can't be built under Core. **The node is wrong; see below.**

## Gate runs (3 of 6 used)
1. **WITNESS_FAIL**: `blind: expected unknown, got violated; the manifest masks rel.longitudinal_overlap`.
   All other witnesses passed: forbid, permit, idle, branch_1, branch_2, and the added branch_3 and branch_4.
   The cause is in `Core/Runtime/Manifest.lean` (`Mask.relation`, `Mask.scene`). Masking
   `rel.longitudinal_overlap` clears only a measured `MeasuredRelation.longitudinalOverlap`. The doc comment there says
   "the computed relations are blanked through the kinematics they would be computed from only when the
   source lacks those too". The accessor `rel_longitudinal_overlap` (`Vocab/Atoms.lean:594`) then
   recomputes the overlap from the subject's position and heading and from both footprints.
   - Change: I set the motorcycle's `kin.extent` to `none` in the blind scene.
2. **WITNESS_FAIL**: the adapter rejected the trace: `track 2 is in occupancy_observed but lacks a position, a
   non-zero heading or an extent, so its footprint is undefined`.
   - Change: I also made the motorcycle's occupancy unobserved, with only the subject's occupancy supplied.
3. **WITNESS_FAIL**: `blind: unknown for [absent_atom:rel_occupies], not for an atom the manifest masks`.
   This was expected: the unknown came from occupancy, not from the masked atom.
   - After this run I put `blind` back to the scene as planned: car and motorcycle both in L, overlap masked.
     The files show the defect plainly, not a workaround that doesn't match the narrative.

## The rule (as written)
- Class of `subject` (s4): `ru_aggregate subject "DEF-NRS-484A-130::motor_vehicle"`.
- Applicability: `.tt`. The record's applicability is only the subject class, which the binder carries.
  The conditions in s1–s3 guard the duty per road user and per lane inside the obligation, as the
  record's obligation states. So `branch_1` (no motorcycle) is compliant, not not_applicable.
- Obligation: `forallUser m. (¬same m subject ∧ (agg m motorcycle ∨ agg m moped) ∧ ∃ highway h. occupies m h)
  → ∀ lane L. occupies m L → ¬(occupies subject L ∧ rel_longitudinal_overlap(subject, m) ≥ 0)`.
- Choices the node left open: none beyond the record. I declared no narrowings.
- Added witnesses, so that every leaf is exercised:
  - `branch_3` (violated): a moped in place of the motorcycle.
  - `branch_4` (compliant): the motorcycle beside the car in L, with the highway region away from the lanes.

## Why the node is wrong (for the plan agent)
The `blind` scenario masks only `rel.longitudinal_overlap`, and its narrative needs both the car and the
motorcycle to *occupy L* (`rel.occupies` decided). Core's adapter requires a position, a non-zero heading
and an extent for every track whose occupancy is observed. Those are exactly the inputs from which Core
recomputes `rel.longitudinal_overlap` when the measured value is masked. So no producible trace has
both occupancies decided and the overlap unknown. Making either occupancy unobserved moves the unknown to
`rel.occupies`, which the gate correctly refuses.

The plan should change `blind`'s `masked`, either:
- add the kinematics the overlap is computed from, e.g. `["rel.longitudinal_overlap", "kin.extent"]`.
  The manifest mask applies after the adapter check, and occupancy stays as stored. The plan would need
  to admit `kin.extent` as a maskable id for this node.
- or mask a claimed atom that decides on its own, e.g. `["rel.occupies"]`, with the narrative "car
  beside the motorcycle; lane occupancy not observed".

The rule itself is not in question: all decided witnesses pass.

## Why I finished
The only failing witness is a planned scenario whose mask Core can't realise while keeping the narrative.
Fixing it needs a change to the node's `blind` masks, which isn't mine to make, so more gate runs
wouldn't help.
