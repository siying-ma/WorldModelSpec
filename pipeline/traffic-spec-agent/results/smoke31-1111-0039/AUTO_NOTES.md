# Feedback from iteration 4

`NRS_484B_307_9a_o1`: not coded, composes or calls `NRS_484B_307_9b_o1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9a_o2`: not coded, composes or calls `NRS_484B_307_9b_o1` (unpublished), not usable for building; kept for the next iteration, no attempt counted
`NRS_484B_307_9b_o3`: gate OK — 6 witnesses, 14 names, composes nothing
`NRS_484B_253_o1`: gate OK — 7 witnesses, 10 names, composes nothing
`NRS_484B_257_1_o2`: gate OK — 15 witnesses, 17 names, composes NRS_484B_257_1_o1
`NRS_484B_250_1`: gate OK — 14 witnesses, 14 names, composes NRS_484B_250_4_o1
`NRS_484B_307_9b_o4`: gate OK — 5 witnesses, 16 names, composes nothing
`NRS_484B_307_9b_o2`: gate BARE_LITERAL — formula literals [] ≠ the node's declared literals [('2', 'count')]; a figure the law states is declared on its span, any other magnitude belongs in the reading
`NRS_484B_307_9b_o2`: gate BARE_LITERAL — sent to a node repair session; no attempt counted
`NRS_484B_307_9b_o1`: gate OK — 11 witnesses, 17 names, composes nothing; narrowings declared by the coder: 1
`NRS_484B_253_o2`: gate WITNESS_FAIL — forbid: expected violated, got compliant; blind: expected unknown, got compliant; the manifest masks sig.turn_indicator, sig.hand_signal; branch_3: expected violated, got compliant; branch_4: expected violated, got compliant
`NRS_484B_253_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS-484B-257-1` span s9 composes accepted `NRS_484B_257_1_o1` (as: compliance)
`NRS-484B-250-1` span s5 composes accepted `NRS_484B_250_4_o1` (as: unless)

## Laws by state

- blocked: 7
- planned: 22

## Concepts by state

- accepted: 19
- failed: 1

## Returned concepts and why

- `drv.position.entered_via` (failed, attempt 3; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_307_9a_o1` held: composes or calls `NRS_484B_307_9b_o1` (unpublished), not usable for building
- `NRS_484B_307_9a_o2` held: composes or calls `NRS_484B_307_9b_o1` (unpublished), not usable for building

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `NRS_484B_307_9b_o1` c8: Where no stop line or crosswalk marks the approach, 'before entering the intersection' is read against the intersection region's own outline: the distance from x's body and the offset along the approach carrier are taken to the intersection region, whose edge is the carrier's entrance end.
