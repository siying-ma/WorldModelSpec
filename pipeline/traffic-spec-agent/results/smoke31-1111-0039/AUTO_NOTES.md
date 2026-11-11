# Feedback from iteration 6

`NRS_484B_307_9a_o2`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian], not for an atom the manifest masks; the manifest masks dev.traffic_signal; branch_1: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian]
`NRS_484B_307_9a_o2`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_307_9a_o1`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian, aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; permit: expected compliant, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian, aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter], not for an atom the manifest masks; the manifest masks dev.traffic_signal; branch_2: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-165::pedestrian, aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS_484B_307_9a_o1`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted

## Laws by state

- blocked: 7
- planned: 22

## Concepts by state

- accepted: 19
- failed: 1

## Returned concepts and why

- `drv.position.entered_via` (failed, attempt 3; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
