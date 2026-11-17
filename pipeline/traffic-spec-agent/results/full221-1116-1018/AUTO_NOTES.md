# Feedback from iteration 4

concept `drv.motion.right_turn`: not repaired, no node uses it
`NRS_484B_250_2`: revised by a repair session; coded again this iteration
`NRS_484B_210_2`: revised by a repair session; coded again this iteration
`NRS_484B_287_1c`: revised by a repair session; coded again this iteration
`NRS_484B_287_1e`: revised by a repair session; coded again this iteration
`NRS-484B-307-9a` names ['NRS-484B-307-9b'], not yet accepted; not planned this iteration, no attempt counted
`NRS_484B_283_1d1`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d2`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d3_o1`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d3_o2`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d4_o1`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1d4_o2`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_2b`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o1` (unpublished), `NRS_484B_283_1d3_o2` (unpublished), `NRS_484B_283_1d4_o1` (unpublished), `NRS_484B_283_1d4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_4b`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o2` (unpublished), `NRS_484B_283_1d4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_8b`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o2` (unpublished), `NRS_484B_283_1d4_o2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9c`: not coded, composes or calls `NRS_484B_283_1d1` (unpublished), `NRS_484B_283_1d2` (unpublished), `NRS_484B_283_1d3_o1` (unpublished), `NRS_484B_283_1d4_o1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_2b_o1`: not coded, composes or calls `NRS_484B_217_2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_2b_o2`: not coded, composes or calls `NRS_484B_217_2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_270_2b_o3`: not coded, composes or calls `NRS_484B_217_2` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1a`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_283_1b`: not coded, composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_8a_o2`: composes ['NRS_484B_307_8d'], whose law(s) wait for the operator (`NRS-484B-307-8d` planned): the composition stands, and this law waits on ['G93']; no attempt counted
`NRS_484B_217_2` proposed `p.vehicle_turn_window` = 10.0 s: the longest duration of a turn by a motor vehicle at a junction or into or out of a driveway, from the start of its head
`LVMC_11_40_180_C_o1`: gate OK — 7 witnesses, 7 names, composes nothing
`NRS_484B_287_1e`: gate OK — 8 witnesses, 15 names, composes LVMC_11_30_140_B_o1,LVMC_11_30_140_B_o2
`NRS_484B_210_2`: gate OK — 4 witnesses, 10 names, composes nothing
`NRS_484B_777_1_o1`: gate UNANCHORED_VARIABLE — in the formula, the quantified variable `i` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked); in the formula, the quantified variable `d` shares no atom with a binder, nor with a variable that does: the region, device or user it ranges over is any in the scene, not the subject's — tie it in the formula through `rel_occupies`, `st_region_geometry_distance`, `dev_governs` or a relation to a binder (the record's claims are already checked)
`NRS_484B_777_1_o1`: gate UNANCHORED_VARIABLE — sent to a node repair session; no attempt counted
`NRS_484B_217_2`: gate WITNESS_FAIL — branch_4: expected violated, got compliant
`NRS_484B_217_2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_287_1c`: gate OK — 9 witnesses, 16 names, composes LVMC_11_30_140_B_o1,LVMC_11_30_140_B_o2
`NRS_484B_250_2`: gate OK — 14 witnesses, 20 names, composes NRS_484B_250_4_o1,NRS_484B_250_4_o2
`NRS_484B_257_2_o1`: gate OK — 14 witnesses, 19 names, composes NRS_484B_257_1_o1
`NRS_484B_363_4`: gate OK — 20 witnesses, 17 names, composes nothing
`NRS-484B-287-1e` span s1 composes accepted `LVMC_11_30_140_B_o1` (as: exception)
`NRS-484B-287-1e` span s1 composes accepted `LVMC_11_30_140_B_o2` (as: exception)
`NRS-484B-287-1c` span v1 composes accepted `LVMC_11_30_140_B_o1` (as: exception)
`NRS-484B-287-1c` span v1 composes accepted `LVMC_11_30_140_B_o2` (as: exception)
`NRS-484B-250-2` span i composes accepted `NRS_484B_250_4_o1` (as: exception)
`NRS-484B-250-2` span i composes accepted `NRS_484B_250_4_o2` (as: exception)
`NRS-484B-257-2` span f composes accepted `NRS_484B_257_1_o1` (as: compliance)
`LVMC-11-52-030-A`: ['LVMC_11_52_030_A'] carry gap(s) ['G88'], filed; not coded, law blocked
`LVMC-11-52-030-B`: ['LVMC_11_52_030_B'] carry gap(s) ['G89', 'G90'], filed; not coded, law blocked
`LVMC-11-52-300`: ['LVMC_11_52_300'] carry gap(s) ['G91'], filed; not coded, law blocked
`NRS-484B-267-2a`: ['NRS_484B_267_2a'] carry gap(s) ['G92'], filed; not coded, law blocked
`NRS-484B-307-8d`: ['NRS_484B_307_8d'] carry gap(s) ['G93'], filed; not coded, law blocked
`NRS-484B-587-2a`: ['NRS_484B_587_2a'] carry gap(s) ['G94', 'G95'], filed; not coded, law blocked

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

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_283_1d1` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_283_1d2` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_283_1d3_o1` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_283_1d3_o2` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_283_1d4_o1` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_283_1d4_o2` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_307_2b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o1`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_4b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_8b` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o2`
- `NRS_484B_307_9c` waits on `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d4_o1`
- `NRS_484B_270_2b_o1` waits on `NRS_484B_217_2`
- `NRS_484B_270_2b_o2` waits on `NRS_484B_217_2`
- `NRS_484B_270_2b_o3` waits on `NRS_484B_217_2`
- `NRS_484B_283_1a` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building
- `NRS_484B_283_1b` held: composes or calls `NRS_484B_287_1c` (unpublished), `NRS_484B_287_1e` (unpublished), not usable for building

## Gaps filed this iteration

- G88 (atom) on `(2) When the location is accompanied by signage which indicates that parking is ` — LVMC-11-52-030-A
- G89 (atom) on `(1) Commercial vehicles to stop, stand or park for the purpose of loading or unl` — LVMC-11-52-030-B
- G90 (atom) on `(2) Taxicabs to stop, stand, park for the purpose of loading, unloading or waiti` — LVMC-11-52-030-B
- G91 (atom) on `Except for a motor vehicle,` — LVMC-11-52-300
- G92 (operator) on `and making use of flashing lights meeting the requirements of` — NRS-484B-267-2a
- G93 (operator) on `(1) The person waits for two complete cycles of the lights or lighted arrows of ` — NRS-484B-307-8d
- G94 (atom) on `(a) An authorized emergency vehicle described in NRS 484A.480;` — NRS-484B-587-2a
- G95 (atom) on `(d) A tow car;` — NRS-484B-587-2a
