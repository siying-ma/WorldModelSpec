# Feedback from iteration 7

concept `drv.motion.right_turn`: not repaired, no node uses it
`NRS_484B_270_2b_o3`: revised by a repair session; coded again this iteration
`NRS_484B_307_8b`: the repair session withdrew it — the vocabulary lacks atom `A relation between a road user and the signal head that faces it: which vehicular signal head's face is directed at a given pedestrian (the head's face orientation, or a road-user-faces-device relation), so that the head named by 'facing such a signal' is tied to the subject. The only reading the vocabulary allows is the pedestrian's heading compared with the line to the head's location (kin.heading, kin.position, dev.position). That says only that the pedestrian looks toward the head. It does not say that the head's face is addressed to the pedestrian. The gate also does not accept that comparison as tying the device variable to the subject (UNANCHORED_VARIABLE, run twice, including with the comparisons rewritten without products). The anchors the gate accepts do not carry the words. dev.governs ties a device only to travel regions. A vehicular head that a crossing pedestrian faces governs the approach lanes of traffic moving parallel to that pedestrian, or the junction itself. It does not govern the roadway the pedestrian steps onto. Requiring the faced head to govern the region entered would leave the duty unengaged in the ordinary case: a pedestrian at a corner facing the far-side head for parallel traffic and stepping into the cross street. Tying it by a distance to some governed region would add a condition the words do not state. The span decides which road users the steady red alone addresses: the pedestrians the duty concerns.` for span s3; gap G96 filed, law blocked
`NRS_484B_307_2b`: revised by a repair session; coded again this iteration
`NRS_484B_307_4b`: revised by a repair session; coded again this iteration
`NRS_484B_307_9c`: the repaired record kept a defect; the law is returned to the planner — NRS_484B_307_9c: reference span s5 is carried by compositions (one per rule it names) or by one residue, never by ['elements']: a reference to a rule composes that rule, a reference that only borrows words is a `definition` reference; NRS_484B_307_9c: definition reference on span s5 borrows from the law `NRS-484B-283-1d1` and states no `why`: say which qualifiers it borrows and why that law's rule need not apply, hold or be complied with here (where it must, the reference is an execution composition)
`NRS-484B-307-9a` names ['NRS-484B-307-9b'], not yet accepted; not planned this iteration, no attempt counted
`NRS_484B_270_2b_o3`: gate OK — 9 witnesses, 15 names, composes nothing
`NRS_484B_307_2b`: gate OK — 12 witnesses, 17 names, composes NRS_484B_283_1d1,NRS_484B_283_1d2,NRS_484B_283_1d3_o1,NRS_484B_283_1d3_o2,NRS_484B_283_1d4_o1,NRS_484B_283_1d4_o2
`NRS_484B_307_9c`: gate OK — 9 witnesses, 19 names, composes NRS_484B_283_1d1,NRS_484B_283_1d2,NRS_484B_283_1d3_o1,NRS_484B_283_1d4_o1
`NRS_484B_307_4b`: gate WITNESS_FAIL — branch_1: expected not_applicable, got violated
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_1` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2a` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2b` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2c` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_217_2` (as: unless)
`NRS-484B-307-2b` span s6 composes accepted `NRS_484B_283_1d1` (as: exception)
`NRS-484B-307-2b` span s6 composes accepted `NRS_484B_283_1d2` (as: exception)
`NRS-484B-307-2b` span s6 composes accepted `NRS_484B_283_1d3_o1` (as: exception)
`NRS-484B-307-2b` span s6 composes accepted `NRS_484B_283_1d3_o2` (as: exception)
`NRS-484B-307-2b` span s6 composes accepted `NRS_484B_283_1d4_o1` (as: exception)
`NRS-484B-307-2b` span s6 composes accepted `NRS_484B_283_1d4_o2` (as: exception)
`NRS-484B-307-9c` span s6 composes accepted `NRS_484B_283_1d1` (as: exception)
`NRS-484B-307-9c` span s6 composes accepted `NRS_484B_283_1d2` (as: exception)
`NRS-484B-307-9c` span s6 composes accepted `NRS_484B_283_1d3_o1` (as: exception)
`NRS-484B-307-9c` span s6 composes accepted `NRS_484B_283_1d4_o1` (as: exception)

## Laws by state

- blocked: 62
- failed: 1
- planned: 156
- returned: 2

## Returned laws and why

- `NRS-484B-307-4b` (attempt 1): gate WITNESS_FAIL; branch_1: expected not_applicable, got violated
- `NRS-484B-307-9a` (attempt 1): NRS_484B_307_9a_o1: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; NRS_484B_307_9a_o2: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; composes ['NRS_484B_307_9b'], whose law waits for the operator: that composition stands, and the law waits for it once the defects above are fixed

## Concepts by state

- accepted: 16
- returned: 1

## Returned concepts and why

- `drv.motion.right_turn` (returned, attempt 1; used by LVMC_11_40_080_o1, LVMC_11_40_080_o2): gate WITNESS_FAIL; holds (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); fails (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); blind (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it)

## Gaps filed this iteration

- G96 (atom) on `facing such a signal` — NRS-484B-307-8b
