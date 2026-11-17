# Feedback from iteration 6

concept `drv.motion.right_turn`: not repaired, no node uses it
`NRS-484B-307-9a` names ['NRS-484B-307-9b'], not yet accepted; not planned this iteration, no attempt counted
`NRS_484B_307_2b` proposed `p.ped_traffic_signal_facing_cos` = 0.87 ratio: cosine of the largest angle (about thirty degrees) between a pedestrian's heading and the line from its position to a ve
`NRS_484B_307_2b` proposed `p.ped_traffic_signal_facing_reach` = 60.0 m: the largest distance from a pedestrian to a vehicular signal head at which the head counts as one the pedestrian faces a
`NRS_484B_307_4b`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `s` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_307_4b`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_307_2b`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `d` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_307_2b`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_307_9c`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `h` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_307_9c`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_270_2b_o1`: gate OK — 5 witnesses, 8 names, composes nothing
`NRS_484B_307_8b`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `head` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_307_8b`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_270_2b_o2`: gate OK — 7 witnesses, 11 names, composes nothing
`NRS_484B_270_2b_o3`: gate WITNESS_FAIL — idle: expected not_applicable, got unknown for [aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; blind: unknown for [absent_atom:rel_same_direction, window_truncated:holdsFor, absent_atom:rel_bearing, absent_atom:rel_longitudinal_overlap], not for an atom the manifest masks; the manifest masks kin.heading; branch_1: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS_484B_270_2b_o3`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_1` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2a` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2b` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2c` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_217_2` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_1` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2a` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2b` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_213_2c` (as: unless)
`NRS-484B-270-2b` span b11 composes accepted `NRS_484B_217_2` (as: unless)

## Laws by state

- blocked: 61
- failed: 1
- planned: 158
- returned: 1

## Returned laws and why

- `NRS-484B-307-9a` (attempt 1): NRS_484B_307_9a_o1: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; NRS_484B_307_9a_o2: the normative reference “Except as otherwise provided in paragraph (b) [NRS-484B-307-9b]” names NRS-484B-307-9b, and no composition of a usable node on its span s2 composes a node of NRS-484B-307-9b: each law the reference names is composed (how they combine is stated by the compositions' kinds), even one not yet accepted; composes ['NRS_484B_307_9b'], whose law waits for the operator: that composition stands, and the law waits for it once the defects above are fixed

## Concepts by state

- accepted: 16
- returned: 1

## Returned concepts and why

- `drv.motion.right_turn` (returned, attempt 1; used by LVMC_11_40_080_o1, LVMC_11_40_080_o2): gate WITNESS_FAIL; holds (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); fails (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it 18° over the interval (the rate at a scene is held over the interval before it); blind (drv.motion.right_turn@w): its trace is not one the adapter can produce: scene t=9000: track 1 keeps the heading it had at t=8000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=10000: track 1 keeps the heading it had at t=9000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it); scene t=11000: track 1 keeps the heading it had at t=10000, but its yaw rate turns it -18° over the interval (the rate at a scene is held over the interval before it)
