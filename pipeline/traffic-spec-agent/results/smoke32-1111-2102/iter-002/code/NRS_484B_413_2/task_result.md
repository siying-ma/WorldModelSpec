# NRS_484B_413_2 — task result

**Final verdict: OK** (7 witnesses, 8 names, composes nothing). Two gate runs out of the budget of 6.

## Gate runs
1. **WITNESS_FAIL**: the trace was rejected as one the adapter cannot produce. The yaw rate during the turn (40 deg/s) did not match the heading, which stayed east. I rebuilt the witness kinematics so that each turning instant rotates the heading by an exact rational unit rotation (1624/1625, ±57/1625), which is 2.010° per 50 ms. The yaw rate is set to the matching ±40.203 deg/s, and each position moves 0.5 m along the instant's heading. The rule did not change.
2. **OK**.

## The rule
- Class: `ru_aggregate ego "DEF-NRS-484A-320::vehicle"`.
- Applicability (t8): `drv_motion_left_turn_from_onset ∨ drv_motion_right_turn_from_onset`. Each concept holds only at its recognition.
- Obligation, per side: `turn → since turning (rises turning ∧ W)`. This reads W at the observed onset, the last rise of `drv_motion_turning_left/right`. Nothing after the onset is read.
- W: `holdsFor .path 100ft ego sig ∧ (asm ∨ holdsFor .path 300ft ego sig)`, where `sig` is the turn indicator on that side or an arm signal meaning that side.

## Choices the node left open
- **How the district condition is combined with the two windows.** I chose `H100 ∧ (asm ∨ H300)`. Both windows end at the onset, so the 300 ft window contains the 100 ft one and H300 implies H100. The formula therefore gives:
  - H100 where the assumption holds;
  - H300 where it fails;
  - where the assumption is undeclared, a verdict when the two windows agree and unknown when they differ.

  That is exactly what the record's obligation states. The literal form `(asm→H100) ∧ (¬asm→H300)` would be unknown even when both windows fail, which the record does not ask for. This is not a narrowing: it is the record's reading, so `narrowings` is empty.
- **One extra witness.** I added `branch_3`: a right turn with the indicator off and an arm signal meaning right, district declared, compliant. It exercises the right-hand 100 ft window and the right arm signal.
- **Window.** Every witness sets `window` to 1000–15950 ms.

## Why I finished
The gate returned OK.
