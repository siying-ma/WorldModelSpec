# Feedback from iteration 2

`NRS_484D_100_1`: the repair session withdrew it — the vocabulary lacks atom `A control-device atom for an official traffic control device that directs road users to display lighted lamps (headlamps on), on the travel regions it governs (dev.governs), with the same structured conditions attribute as dev.zone_sign (proposed: dev.lamp_use_sign). f7 is condition (c): it decides when the lamp duty applies, namely when a device directs it even though neither darkness (f5, env.darkness) nor poor visibility (f6, env.visibility) does. Without it, the rule cannot tell a stretch where a device directs lamp use from any other stretch, so it misses that part of the duty's domain. The words state no other observable fact for that limb. It is not a legal region class: the direction is a feature displayed on the road, so it cannot be an assumption. A condition span cannot be narrowed or dropped. Writing it with the atoms the record maps (some dev.regulatory_sign governing a travel region x occupies) would make the duty apply under any no-parking, one-way or truck-route sign, which is a different condition.` for span f7; gap G17 filed, law blocked
`NRS_484B_769`: revised by a repair session; coded again this iteration
`NRS_484B_263_o1`: revised by a repair session; coded again this iteration
`NRS_484B_263_o2`: revised by a repair session; coded again this iteration
`NRS_484B_307_9b_o2`: revised by a repair session; coded again this iteration
`NRS-484D-215-1`: composes ['NRS_484D_100_1', 'NRS_484D_215_1_o2'], whose law(s) wait for the operator (`NRS-484D-100-1` blocked): the composition stands, and this law waits on ['G17']; no attempt counted
`NRS_484B_250_1`: not coded — `NRS_484B_250_1` composes or calls `NRS_484B_250_4_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_307_9a_o1`: not coded — `NRS_484B_307_9a_o1` composes or calls `NRS_484B_307_9b_o1` (pin_mismatch), `NRS_484B_307_9b_o2` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_307_9a_o2`: not coded — `NRS_484B_307_9a_o2` composes or calls `NRS_484B_307_9b_o1` (pin_mismatch), `NRS_484B_307_9b_o2` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
`NRS_484B_769`: gate OK — 8 witnesses, 5 names, composes nothing
`NRS_484B_263_o1`: gate OK — 6 witnesses, 9 names, composes nothing
`NRS_484B_270_4`: gate WITNESS_FAIL — blind: unknown for [window_truncated:since, window_truncated:until], not for an atom the manifest masks; the manifest masks rel.occupies
`NRS_484B_270_4`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_270_3_o1`: gate WITNESS_FAIL — branch_2: expected violated, got not_applicable
`NRS_484B_270_3_o1`: gate WITNESS_FAIL — sent to a node repair session; no attempt counted
`NRS_484B_307_9b_o2`: gate OK — 11 witnesses, 13 names, composes nothing
`NRS_484B_263_o2`: gate OK — 7 witnesses, 9 names, composes nothing
`NRS-484B-769` span c6 borrows from `DEF-NRS-484B-420` the words “extended horizontally”

## Laws by state

- blocked: 2
- planned: 25
- returned: 2

## Returned laws and why

- `NRS-484B-250-1` (attempt 0): `NRS_484B_250_1` composes or calls `NRS_484B_250_4_o1` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted
- `NRS-484B-307-9a` (attempt 0): `NRS_484B_307_9a_o2` composes or calls `NRS_484B_307_9b_o1` (pin_mismatch), `NRS_484B_307_9b_o2` (pin_mismatch), not usable for building: a superseded or missing record, or a fenced concept, is replaced by a re-plan (map the words to a usable record or a successor); no attempt counted

## Concepts by state

- accepted: 16

## Gaps filed this iteration

- G17 (atom) on `and (c) When directed by an official traffic control device.` — NRS-484D-100-1
