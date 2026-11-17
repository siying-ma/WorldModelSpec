<!-- batch-01 -->
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

<!-- batch-02 -->
# Plan — iteration 4, batch 02

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts. All ten nodes validate `accept`.

## NRS-484B-283 (1)(a), (1)(b), (1)(d)(1)–(4): eight nodes, re-emitted unchanged

`NRS_484B_283_1a`, `NRS_484B_283_1b`, `NRS_484B_283_1d1`, `NRS_484B_283_1d2`, `NRS_484B_283_1d3_o1`, `NRS_484B_283_1d3_o2`, `NRS_484B_283_1d4_o1` and `NRS_484B_283_1d4_o2` came back for one reason only: a pin mismatch on `LVMC_11_30_060_A`. A repair session revised that node this iteration, it passed the gate (OK, 10 witnesses) and it is accepted under the same id. That makes it the successor the return asks for. Re-planning the composition on span `r` ("Except as otherwise provided in NRS 484B.287 [... LVMC-11-30-060-A ...]") pins it to the current record. No word or mapping was wrong, so every record is kept exactly as it passed the validator in iterations 1–3: same segmentation, elements, compositions, operationalizations and scenarios (rule 11).

The revised `LVMC_11_30_060_A` still has the same meaning here: a pedestrian crossing a roadway outside any crosswalk owes the yield. As an exception it therefore never overlaps 1a's crosswalk pedestrian, and it only removes the out-of-crosswalk crossings from the pedestrian duties in 1b and 1d.

The nodes also compose `NRS_484B_287_1c` and `NRS_484B_287_1e`. Neither is accepted yet: they failed the gate and went to node repair. Those compositions stand, because the reference names those laws, and the nodes wait for them.

**Reversal signal:** a further pin mismatch, or a revision of `LVMC_11_30_060_A` that changes its applicability to cover pedestrians inside a crosswalk.

## NRS-484B-307 (8)(d): `NRS_484B_307_8d`, now blocked by an operator gap on s7

This record is the iteration-3 repair, kept whole: its wording of s4 fixed the earlier witness failure. The gate then returned it as BARE_LITERAL.

The law states the figure "two" ("waits for two complete cycles"), so rule 8 requires it as a declared literal `(2, count)`. But the only operator that counts rising edges, `Formula.count`, takes its bound as a bare Nat that `Formula.literals` does not report. No faithful formula can carry the figure. The two ways round it are both forbidden:
- adding a made-up `Term.lit 2 count` conjunct, or
- dropping the figure from the literals.

This is the same defect the repair of `NRS_484B_307_9b` filed as G87. Span s7 is now mapped to its nearest atoms, with an `operator` gap proposing a count whose bound is a count-typed Term, or literal reporting for `Formula.count`. The law stays blocked until the operator decides.

**Reversal signal:** G87 resolved, or Core reporting `count`'s bound as a literal. Once that happens, the record codes as written.

## NRS-484B-307 (8)(a): `NRS_484B_307_8a_o2`, re-planned

`o1` and `o3` are accepted and are left out of this file; they are not re-planned. `o2` was returned because its roles for the paragraph (c) words (s7–s15) were `exception`, while the accepted `o3` segments them as `condition` (s7, s9, s10, s11, s13, s14, s15) and `subject` (s8, s12). The role of words is fixed once a node of the law is accepted.

`o2` now uses `o3`'s roles exactly. s16–s18, the yield duty only `o3` needs, are `sibling`. The elements are `o3`'s mappings, word for word.

The permission of paragraph (c) is still read as a release from the duty to remain stopped, so the applicability states that the duty does not apply where those conditions hold. The conditions themselves are the full referent of the s3 requirement: the halt itself at the stop line, else the crosswalk, else the intersection's edge, with `o1`'s zone and history bound. A weaker fact is not substituted.

`o3` was not composed instead, for two reasons:
- The reference on s5 names only NRS-484B-307-8d.
- `o3`'s applicability needs the footprint already inside the intersection. A lawful right turn on red passes through the near crosswalk first, and that entry would then be read as a violation.

So the permission here no longer requires the subject to be in the intersection, and `branch_1` now tests the entry into the crosswalk. Paragraph (d) stays a composition of `NRS_484B_307_8d` on s5, as an exception. The intentions on s10 and s14 reuse the catalogue ids `int.right_turn` and `int.left_turn`.

**Reversal signal:** the validator rejecting a negatively read `condition` span. If that happens, compose `o3` on s5 and narrow the crosswalk case explicitly.

## For the operator

- **G87 needs a decision.** It now blocks both NRS-484B-307-9b and NRS-484B-307-8d (the operator gap on s7 here). Either fix closes both: let `Formula.count` take a Term bound in unit count, or have the literal collection report its Nat bound as `(n, count)`.
- **The (8)(d) exception in `o2` is narrower than the law.** `NRS_484B_307_8d`'s applicability, like the accepted `o3`'s, starts at the rider's entry into the intersection. So `o2`'s exception for paragraph (d) does not cover a rider who has waited two cycles and is crossing the near crosswalk on the way in; until the rider reaches the intersection, `o2` may report that crossing as a violation. Widening both yield nodes to an event of "entered the crosswalk marking the approach, or the intersection" would close this. That needs `o3` to be re-opened, and `o3` is accepted, so it was not done here.

<!-- batch-03 -->
# Plan — batch 03, iteration 4

## `NRS_484B_363_4` (NRS-484B-363-4)

**Decision.** I kept the iteration-3 record and changed only the `blind` scenario. It now masks
`rel.longitudinal_overlap` instead of `kin.position`.

**Reason.** The returned reason was the gate's WITNESS_FAIL on `blind`:
- Masking `kin.position` (iteration 3) made the derived relations `rel_longitudinal_overlap` and `rel_bearing` absent, and the trace had a truncated window. The rule was unknown, but not because of the masked atom.
- Masking `rel.bearing` (iteration 2) left the pass decided. `drv.interaction.overtake_pass` takes the bearing from `kin.position` and `kin.heading`, not from `rel.bearing`.

The concept reads `rel.longitudinal_overlap` directly: "b is ahead … and the two bodies' projections on a's heading share no length (rel.longitudinal_overlap negative)". Masking it therefore leaves "ahead" and "behind" undecided, so the pass and its verdict are unknown for the masked atom itself. The narratives of `blind` and `forbid` now say the recording begins more than `p.overtake_window` before the recognition, so the window is not truncated.

`param_proposals` is now empty, because every parameter it names is in the catalogue. Every span mapping matches the index (NRS_484B_363_1/2/3).

**Reversal signal.** A gate run in which the masked overlap does not make the rule unknown. That would mean the coded pass never reads the overlap.

## `NRS_484B_587_2a` (NRS-484B-587-2a)

**Decision.** I kept the record and added atom gaps on e12 (authorized emergency vehicle; e13 shares its aggregate) and e15 (tow car). The law blocks until the operator decides.

**Reason.** The gate returned VACUOUS: the subject's `ru.aggregate` leaves for `DEF-NRS-484A-020::authorized_emergency_vehicle` were never exercised, and neither literal variant was. In iteration 2 the gate already reported `aggregate_unresolved` for both this id and `DEF-NRS-484A-280::tow_car` on a transit bus. The operator's feedback on G86 confirms that the run's reading classifies every class under the AEV id as unresolved, so membership is unknown for every road user. No witness can make the leaf decide, and a third coding attempt would close the law as failed.

Rule 0/3 rules out the alternatives:
- The admitted aggregate cannot be replaced by `ru.emergency_vehicle` or by `ru.official_vehicle` kind tow.
- Dropping the class restriction would widen subsection 3's exception to every vehicle a sign admits.

So the gaps record what is missing: either a class atom or an operator decision on the reading. That is the same decision G86 asks for, and the same kind of decision G82/G83 ask for.

The other mappings are unchanged: e14/e16 use `ru.official_vehicle`, e17 uses `ru.transit_bus`, and e8 is a definition reference to NRS 484B.210.

**Reversal signal.** The operator classifies included members under either id (or retires the gaps). The record is then coded as is and lists both gaps in `gap_resolutions`.

## `NRS_484B_777_1_o1` (NRS-484B-777-1)

**Decision.** I re-emitted the record unchanged except that `param_proposals` is now empty, because all six parameters are in the catalogue. The composition on s3 still names `NRS_484B_785_1a` as `compliance`.

**Reason.** The returned reason was a pin mismatch: `NRS_484B_785_1a` was revised and re-accepted in iteration 3, after this node was planned against its earlier version. The accepted version keeps the duty this exception relies on: an electric scooter on a roadway or bicycle lane/path travels at no more than 15 mph. A bicycle or an electric bicycle does not engage it, so for them it counts as complied with, which is the intended reading of "lawful rate of speed". Re-planning against the current record restores the pin.

The accepted sibling `NRS_484B_777_1_o2` is not re-planned or re-emitted. Its segmentation (same cut; s1 subject, s2 condition) is unchanged here.

**Reversal signal.** A further revision of `NRS_484B_785_1a`, or a gate defect on exception (a).

## For the operator

- **DEF-NRS-484A-020::authorized_emergency_vehicle (G86, and the new gap on NRS-484B-587-2a e12).** The reading includes no class. Every rule that lists authorized emergency vehicles as an exception or a subject is therefore vacuous on that leaf. A reading decision, such as `ru.emergency_vehicle` and `ru.fire_apparatus` included and the other classes excluded, would unblock this and the other affected laws together.
- **DEF-NRS-484A-280::tow_car (new gap on NRS-484B-587-2a e15).** The gate evidence shows no included class. Including `ru.official_vehicle` of kind tow, and excluding the bus classes, would decide it.
