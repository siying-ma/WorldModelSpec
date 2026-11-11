# Feedback from iteration 2

`NRS_484B_450_1c`: the repair session withdrew it — the vocabulary lacks operator `An operator that decides whether, at an observation, some rule of the set that is engaged for the subject there is complied with only if the subject is halted (e.g. `Formula.haltRequired (subject)`): whether the halt is made 'in compliance with law'. The exception decides the action the law forbids, since it excuses a halt within an intersection whenever any law requires that halt (yielding to a responding emergency vehicle, to a pedestrian, to a school bus, and so on). The law names no rule, so no fixed composition carries it. The planned surrogate, 'an emergency vehicle with lamps or siren is in the scene', reads a road user that is tied neither to the subject nor to the intersection (gate UNANCHORED_VARIABLE). Anchoring it with rel.occupies, st.lane_enters, rel.surface_gap or a distance parameter would add conditions that the words 'in compliance with law' do not state, and it would still stand in for the law's requirement with a neighbouring atom.` for span h5; gap G22 filed, law blocked
`NRS_484B_263_o2`: revised by a repair session; coded again this iteration
`NRS_484B_769`: revised by a repair session; coded again this iteration
`NRS_484B_363_3`: revised by a repair session; coded again this iteration
concept `drv.position.entered_via`: re-proposed by a repair session
concept `drv.position.entered_via`: gate WITNESS_FAIL — blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks
`NRS_484B_250_1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_253_o1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_253_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_257_1_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9a_o1`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9a_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o2`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o3`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_307_9b_o4`: held — uses ['drv.position.entered_via'], pending (under repair or waiting); no attempt counted
`NRS_484B_769`: gate OK — 9 witnesses, 5 names, composes nothing
`NRS_484B_263_o2`: gate OK — 6 witnesses, 9 names, composes nothing
`NRS_484B_363_3`: gate OK — 18 witnesses, 15 names, composes nothing
`NRS-484B-769` span s4 borrows from `DEF-NRS-484B-420` the words “(1) Left turn: Hand and arm extended horizontally. (2) Right turn: Hand and arm extended upward. (3) Stop or decrease speed: Hand and arm extended downward. (4) Reentering lane of traffic from parked position: Hand and arm extended horizontally.”

## Laws by state

- blocked: 7
- planned: 22

## Concepts by state

- accepted: 19
- returned: 1

## Returned concepts and why

- `drv.position.entered_via` (returned, attempt 2; used by NRS_484B_250_1, NRS_484B_253_o1, NRS_484B_253_o2, NRS_484B_257_1_o2, NRS_484B_307_9a_o1, NRS_484B_307_9a_o2, NRS_484B_307_9b_o1, NRS_484B_307_9b_o2, NRS_484B_307_9b_o3, NRS_484B_307_9b_o4): gate WITNESS_FAIL; blind: unknown for [window_truncated:rises, window_truncated:since], not for an atom the manifest masks

## Nodes held for a later iteration, and why (no attempt counted)

- `NRS_484B_250_1` waits on `drv.position.entered_via`
- `NRS_484B_253_o1` waits on `drv.position.entered_via`
- `NRS_484B_253_o2` waits on `NRS_484B_253_o1`, `drv.position.entered_via`
- `NRS_484B_257_1_o2` waits on `drv.position.entered_via`
- `NRS_484B_307_9b_o1` waits on `drv.position.entered_via`
- `NRS_484B_307_9a_o1` waits on `NRS_484B_307_9b_o1`, `drv.position.entered_via`
- `NRS_484B_307_9a_o2` waits on `NRS_484B_307_9b_o1`, `drv.position.entered_via`
- `NRS_484B_307_9b_o2` waits on `drv.position.entered_via`
- `NRS_484B_307_9b_o3` waits on `drv.position.entered_via`
- `NRS_484B_307_9b_o4` waits on `drv.position.entered_via`

## Gaps filed this iteration

- G22 (operator) on `or in compliance with law` — NRS-484B-450-1c
