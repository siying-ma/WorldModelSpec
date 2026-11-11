# Feedback from iteration 7

`NRS_484B_307_9a_o1`: revised by a repair session; coded again this iteration
`NRS_484B_307_9a_o2`: revised by a repair session; coded again this iteration
`NRS_484B_307_9a_o2`: gate OK — 6 witnesses, 14 names, composes NRS_484B_307_9b_o1; narrowings declared by the coder: 1
`NRS_484B_307_9a_o1`: gate WITNESS_FAIL — forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter], not for an atom the manifest masks; the manifest masks dev.traffic_signal; branch_3: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; branch_5: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]
`NRS-484B-307-9a` span b2 composes accepted `NRS_484B_307_9b_o1` (as: exception)

## Laws by state

- blocked: 7
- planned: 21
- returned: 1

## Returned laws and why

- `NRS-484B-307-9a` (attempt 1): gate WITNESS_FAIL; forbid: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; blind: unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter], not for an atom the manifest masks; the manifest masks dev.traffic_signal; branch_3: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter]; branch_5: expected violated, got unknown for [aggregate_unresolved:DEF-NRS-484A-135::motorcycle, aggregate_unresolved:DEF-NRS-484A-125::moped, aggregate_unresolved:DEF-NRS-484B-017::electric_bicycle, aggregate_unresolved:DEF-NRS-484B-018::electric_scooter] — accepted already and not to be re-planned: NRS_484B_307_9a_o2

## Concepts by state

- accepted: 19
- failed: 1

## Returned concepts and why

- `drv.position.entered_via` (failed, attempt 3; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Readings the coding sessions narrowed (span, and what the formulas state more narrowly than its words)

- `NRS_484B_307_9a_o2` b9: x itself is not among the pedestrians yielded to (p ≠ x): a road user does not yield to itself, as the words exclude it from "other traffic".
