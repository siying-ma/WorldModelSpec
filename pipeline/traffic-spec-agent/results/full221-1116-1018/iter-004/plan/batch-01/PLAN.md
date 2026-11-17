# Plan — iteration 4, batch 01

No law-local aggregates are written: `aggregates.jsonl` is empty. No concept is proposed: every concept the nodes call is already accepted (`drv.motion.complete_halt`, `drv.motion.parked`, `drv.interaction.overtake_pass`, `drv.lane.heading_right_of_carrier`). Accepted nodes (`LVMC_11_40_180_C_o2`, `NRS_484B_257_2_o2`) are left out and are not re-planned. The validator accepts all ten records.

## LVMC-11-40-180-C

**`LVMC_11_40_180_C_o1`** (the yield duty). This is the iteration-3 record with scenario `branch_3` removed. In that scenario a passenger car on the sidewalk was expected to be not_applicable. It came out unknown because the run's reading leaves the car's class unresolved under the LVMC electric-bicycle and electric-scooter aggregates. The subject class is carried by the admitted aggregates and is not replaced by class atoms, so unknown is the rule's correct verdict for that scene, and the scenario was wrong. Every remaining scenario names a subject class whose membership is decided (`ru.bicycle`, `ru.electric_bicycle`). The segmentation still matches the accepted sibling `_o2`.
- Reversal signal: the gate reports the subject-class leaf for the electric-scooter aggregate as vacuous. That would need a gap on c1 like G86.

## LVMC-11-52-030-A

**`LVMC_11_52_030_A`**. The iteration-3 record is kept, now with an `atom` gap on s9. The gate returned it as VACUOUS on the tour-bus membership leaf.
- The run's reading includes no class under `DEF-LVMC-11-02-150::tour_bus`, `::shuttle_bus` or `DEF-LVMC-11-02-090::limo`.
- The only nearby class, `ru.tour_bus_or_limousine`, joins two services that the definitions keep apart (a tour bus is "other than a limousine"). It is therefore unresolved under each aggregate.
- As a result no witness can ever decide exception (2). An aggregate may not be expanded into a class atom (rule 3), so the span cannot be carried faithfully.
- The gap proposes splitting the class into `ru.tour_or_shuttle_bus` and `ru.limousine`. This is the same defect G83 names for the tour-bus aggregate.
- The node is not coded now. Once the gap is resolved, the record codes as written.
- Reversal signal: the operator's reading includes some class under these ids.

## LVMC-11-52-030-B

**`LVMC_11_52_030_B`**. The iteration-3 record is kept, now with `atom` gaps on s4 and s6. The gate returned it as VACUOUS on the commercial-vehicle membership leaf.
- s4: the reading includes no class under `DEF-LVMC-11-02-070::commercial_vehicle`. The definition turns on use "for the furtherance of a commercial enterprise", which `ru.commercial_motor_vehicle` (a mass class or licence) does not carry. The gap proposes `ru.business_vehicle`.
- s6: the reading leaves `ru.taxicab` unresolved under `DEF-LVMC-11-02-140::taxicab`, the same defect as G82. The gap proposes `ru.licensed_taxicab`. An operator decision that the taxicab's markings are the evidence of its licence would also close it.
- Reversal signal: the reading includes a class under either id.

## LVMC-11-52-300

**`LVMC_11_52_300`**. The iteration-3 record is kept, now with an `atom` gap on s1 ("Except for a motor vehicle,"). The gate failed forbid, permit and branch_1 as unknown, because the trailer's membership in `DEF-NRS-484A-130::motor_vehicle` is unresolved.
- The only class that carries a trailer, `ru.trailer_or_combination`, also carries the combination with its self-propelled towing vehicle.
- So no class is both a vehicle and decidedly not a motor vehicle, and the duty can never be decided. Its words concern exactly that class: a non-motor vehicle parked on a street at night.
- The gap proposes `ru.trailer`, a trailer observed as a body of its own. Animal-drawn vehicles, the other non-motor vehicles, are already open as G21.
- The scenarios now say "unhitched trailer".
- Reversal signal: the operator classifies an existing class as excluded from the motor-vehicle aggregate while it is included as a vehicle.

## NRS-484B-217-2

**`NRS_484B_217_2`**. Re-emitted unchanged. The return reason was a stale pin on `NRS_484B_413_2`, which was re-coded and accepted in iteration 3 and is composable now. The composition on s13 (`as: compliance`) names that node id again, so it binds the current record.
- The condition on s13 refers to the signal of NRS 484B.413(2). It requires compliance with that rule's manner, so composing it is the right representation. The node also reads the left signal itself on s12 (`sig.turn_indicator`, `sig.hand_signal`) at the observation before the crossing, so a signal that was never given is not excused by a composed rule that was not engaged.
- Reversal signal: another pin mismatch on `NRS_484B_413_2`.

## NRS-484B-257-2

**`NRS_484B_257_2_o1`**. Re-emitted unchanged. The return reason was a stale pin on `NRS_484B_257_1_o1`, which is composable now.
- Span f ("in compliance with the manner prescribed in subsection 1") composes it as compliance.
- The act itself (halt or slowed speed at the governing place) is still stated on span d with the full approach search of rule 4c. Compliance alone would not show that the act occurred.
- The `history_boundary` scenario is kept.

## NRS-484B-267-2a

**`NRS_484B_267_2a`**. Re-emitted with the stale pin on `NRS_484B_600_1a` refreshed (span t11, compliance), and now with an `operator` gap on t6.
- t6, with the words t7 borrows from DEF-NRS-484A-480-3 ("at least one flashing red warning lamp visible from the front"), engages the duty only for a vehicle using a flashing red lamp facing front.
- The formula surface reads `sig_warning_lamp` only by colour and mode, so the condition could only be written in a weaker form. Every sibling paragraph of NRS 484B.267 was withdrawn on the same words in iteration 3 (G79–G81, G84, G85).
- The NRS-484B-267-2f return note asks that this be filed as an operator gap rather than narrowed, so I filed it as `operator`: the atom's contract already has the facing, and only the formula form is missing.
- A new scenario, branch_4 (only rear-facing red flashers → not_applicable), separates the full condition from the weaker one.
- Reversal signal: Core exposes the facing selector. The record then codes as written.

## NRS-484B-270-2b

**`NRS_484B_270_2b_o1`, `_o2`, `_o3`**. Re-emitted unchanged in substance. The return reason was a stale pin on `NRS_484B_213_2c`, which is composable now.
- The `unless` compositions on b11 keep naming `NRS_484B_213_1`, `_213_2a`, `_213_2b` and `_213_2c` (all accepted) and `NRS_484B_217_2` (re-planned in this batch). Each one suspends the authorization on b12.
- The authorization is a residue of scope `none`, because these duties are the same whether or not it holds. So the compositions do not change any verdict, and the nodes do not depend on 217-2 being coded.
- `_o1` remains a surrogate (due care).
- Narrowings that had no kind before now say `kind: "reading"`, and the citations "as proposed this iteration by …" were dropped from the parameter sources. Neither change alters the meaning.

## For the operator

- **Unresolved aggregates block four records** (`LVMC_11_52_030_A` s9, `LVMC_11_52_030_B` s4/s6, `LVMC_11_52_300` s1). In each case the run's reading leaves every candidate class unresolved, so the membership leaf can never be decided. Two ways to unblock them:
  - a reading review: classify `ru.taxicab` as included under `DEF-LVMC-11-02-140::taxicab` by its markings (status), as G82 also asks;
  - the new class atoms the gaps propose.
- **`LVMC_11_52_030_A` s11** (`DEF-LVMC-11-02-120::rtc_bus`) may hit the same vacuity once s9 is resolved, if the reading leaves `ru.transit_bus` unresolved there. The gate named only the tour-bus leaf, so I filed no gap on s11. Please check that classification together with s9.
- **`NRS_484B_267_2a`** also claims `DEF-NRS-484A-020::authorized_emergency_vehicle`. G86 reports that every class is unresolved under that aggregate. Here the approached vehicle may also be a regulatory-agency official vehicle, so the duty can still be decided. However, an ambulance will read unknown until G86 is resolved.
