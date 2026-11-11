# Feedback from iteration 5

`NRS_484B_307_9b_o2`: revised by a repair session; coded again this iteration
`NRS_484B_253_o2`: the repair session withdrew it; the law is returned to the planner
`NRS_484B_253_o1`: re-emitted unchanged; already accepted, not coded again
`NRS_484B_307_9a_o1`: not coded — `NRS_484B_307_9a_o1` composes or calls `NRS_484B_307_9b_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_307_9a_o2`: not coded — `NRS_484B_307_9a_o2` composes or calls `NRS_484B_307_9b_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_307_9b_o2`: gate OK — 10 witnesses, 12 names, composes nothing
`NRS_484B_253_o2`: gate OK — 9 witnesses, 10 names, composes NRS_484B_253_o1
`NRS-484B-253` span s8 composes accepted `NRS_484B_253_o1` (as: compliance)

## Laws by state

- blocked: 7
- planned: 21
- returned: 1

## Returned laws and why

- `NRS-484B-307-9a` (attempt 0): `NRS_484B_307_9a_o2` composes or calls `NRS_484B_307_9b_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted

## Concepts by state

- accepted: 19
- failed: 1

## Returned concepts and why

- `drv.position.entered_via` (failed, attempt 3; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
