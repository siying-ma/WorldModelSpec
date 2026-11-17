# Feedback from iteration 8

concept `drv.motion.right_turn`: not repaired, no node uses it
`NRS-484B-307-9a` names ['NRS-484B-307-9b'], not yet accepted; not planned this iteration, no attempt counted
`NRS_484B_307_4b`: gate OK — 14 witnesses, 18 names, composes NRS_484B_283_1d1,NRS_484B_283_1d2,NRS_484B_283_1d3_o2,NRS_484B_283_1d4_o2
`NRS-484B-307-4b` span s6 composes accepted `NRS_484B_283_1d1` (as: exception)
`NRS-484B-307-4b` span s6 composes accepted `NRS_484B_283_1d2` (as: exception)
`NRS-484B-307-4b` span s6 composes accepted `NRS_484B_283_1d3_o2` (as: exception)
`NRS-484B-307-4b` span s6 composes accepted `NRS_484B_283_1d4_o2` (as: exception)

## Laws by state

- blocked: 62
- failed: 1
- planned: 157
- returned: 1

## Returned laws and why

- `NRS-484B-307-9a` (attempt 1): NRS_484B_307_9a_o1: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; NRS_484B_307_9a_o2: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; composes ['NRS_484B_307_9b'], whose law waits for the operator: that composition stands, and the law waits for it once the defects above are fixed

## Concepts by state

- accepted: 16
- returned: 1

## Returned concepts and why

- `drv.motion.right_turn` (returned, attempt 1; used by LVMC_11_40_080_o1, LVMC_11_40_080_o2): gate WITNESS_FAIL; holds (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); fails (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); blind (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it)
