# Plan — iteration 3 (returned laws NRS-484B-250-1, NRS-484B-307-9a)

Both laws came back for one reason only: the records they compose (`NRS_484B_250_4_o1`;
`NRS_484B_307_9b_o1`, `NRS_484B_307_9b_o2`) no longer matched the versions pinned when the
plans were written (`pin_mismatch`). `NRS_484B_307_9b_o2` was revised by a repair session in
iteration 2. The library now lists every composed node as composable (build): `NRS_484B_250_4_o1`,
`NRS_484B_250_4_o2`, and `NRS_484B_307_9b_o1` through `_o4`. No failing case, label mismatch or
validator defect concerns the mappings themselves, and on a fresh reading the words do not show
any of them wrong. Under rule 11, each node is therefore re-emitted with its segmentation,
elements, compositions and scenarios unchanged. The compositions name the same node ids, so the
harness pins the current composable records. The parameters are all in the catalogue now, so
the earlier `param_proposals` are dropped and the values are not proposed again. The validator
accepts all three nodes.

## NRS_484B_250_1

Decision: one node, and the duty is "shall yield". The subject is the vehicle aggregate, read
through controlled motion. "Approaching an intersection" is occupying a carrier that enters
`i`. The yield is no predicted conflict (traffic-conflict operationalization of
"right-of-way") while `x` moves within `i`, owed to a vehicle that entered `i` from a carrier
on a different highway. There are two exceptions:
- **Devices:** a signal, stop sign or yield sign governs `i` or its approaches.
- **Left turn on opposed approaches:** carriers whose directions are opposed, combined with
  `int.turn_left` or `drv.motion.turning_left`.

"Except as otherwise provided in subsection 4" is an `unless` on the device exception (s8),
composing `NRS_484B_250_4_o1` and `_o2`. These are the inoperative-signal duties, and they are
now composable again, which addresses the returned reason. Reversal signal: a gate witness
where an inoperative-signal entry is judged not applicable would mean the `unless` does not
reach the judged observation. In that case, s7 would be rewritten to read the inoperative
signal at `x`'s entry directly.

## NRS_484B_307_9a_o1

Decision: the first obligation is "may enter … only to make the movement indicated by the
green turn arrow". It is judged at the exit, where the crossing movement is recognized
(through, left or right turn through `i`). The signal is read at the entry through a past
operator. The exception for paragraph (b) composes `NRS_484B_307_9b_o1`–`_o4`, all of which
are now composable. "Vehicular" narrows the traffic aggregate to non-pedestrians. Reversal
signal: a recorded repair of `NRS_484B_307_9b_o1`/`_o2` that changes their applicability, so
that a motorcycle going straight on the arrow is no longer excepted (branch_1 would fail).

## NRS_484B_307_9a_o2

Decision: the second obligation, the yield to pedestrians in an adjacent crosswalk and to
other traffic in the intersection. It is read as no predicted conflict while `x` moves in the
intersection it entered under red with a green arrow. "Lawfully" is narrowed to presence. The
same paragraph (b) exception composes `NRS_484B_307_9b_o1`–`_o4`. Reversal signal: a witness
in which a bicycle under paragraph (b) is judged by this node mid-crossing with a verdict that
differs from `NRS_484B_307_9b_o4`'s. That would call for reading the exception at the entry
instead of at each observation.

## For the operator

- Composed records that are repaired after a dependant is planned trigger `pin_mismatch` returns.
  These cost a planning iteration even though the dependant's words are unaffected. A re-pin
  that skips re-planning, when the composed node keeps its id and its binders, would avoid that.
