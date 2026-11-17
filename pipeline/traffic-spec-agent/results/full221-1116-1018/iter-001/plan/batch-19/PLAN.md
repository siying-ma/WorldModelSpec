# Plan — batch 19 (NRS 484B.307(8)(e), (9)(a)–(c); 484B.300(1); 484B.310(1); 484B.330(1); 484B.360(1))

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts: every manoeuvre or state is a
concept this iteration already proposed (`drv.motion.complete_halt`, `drv.motion.parked`,
`drv.motion.{left,right,u}_turn_through_region`), reused by id. Two nodes carry gaps
(`NRS_484B_300_1`, `NRS_484B_360_1`), so they will not be coded. The other seven are complete.

## NRS_484B_307_8e — no cutting through property around a steady red
**Decision.** A single prohibition. The rule applies to vehicular traffic (traffic ∩ vehicle
aggregates, as the index maps "Vehicular traffic facing the signal"). It must earlier have occupied an
approach carrier `c` into intersection `i` while the governing head showed `circular_red` and no other
state. It is violated when the vehicle comes onto a highway `h2` on which `i` lies, without being in
`i`, having occupied no `st.highway` region at the previous observation. That way it reaches the
cross street from private or public property, which means ground outside every public way's boundary
lines; a sidewalk or shoulder does not count. The cross street's traffic must not face red: some head
governing an approach of `h2` into `i` shows a state other than `circular_red`. "street" is
`asm.within_incorporated_city`, a new assumption: DEF-NRS-484A-265 limits a street to a city, and a
city limit is a legal region class. "to avoid the red signal" is a purpose, read through conduct
(`observable_reading`/purpose). Since facing the red, the vehicle has neither entered `i` nor parked
(`drv.motion.parked`). A vehicle that parks on the lot is using the property, not getting around the
signal.
**Reversal.** If labels count a sidewalk-only cut as property, the property reading on s3 widens. If
labels judge a brief business stop (shorter than `p.parking_min_duration`) as compliant, the purpose
reading needs a shorter dwell parameter.

## NRS_484B_307_9a_o1 — under red + green turn arrow, enter only to make the arrow's movement
**Decision.** This is an act duty (rule 4b). The act is the passage through `i`. Its onset is the
entry (`rel.occupies` rises) and it is recognized at the exit, using the arrow direction's
through-region turn concept (left, right or U). The signal display is read at the entry observation
by a past operator. In `occasion` it is declared `some_moment`, which includes the onset; the
`occasion_s1` and `occasion_s1_outside` scenarios separate the two readings. The subject span is not
an occasion span. "Except as otherwise provided in paragraph (b)" is an `exception` composition with
`NRS_484B_307_9b`. The advisory sentence to drivers is `definitional`: a residue with no duty.
"may enter the intersection only to make the movement" is one obligation span, because the validator
allows only one per node.
**Reversal.** If labels judge a straight passage in which the red + arrow came on only after entry,
the trigger must be read only at the onset. That would need an "at onset" occasion, which the
occasion vocabulary lacks.

## NRS_484B_307_9a_o2 — yield while proceeding under red + green turn arrow
**Decision.** Applies while the subject is in `i` after entering under red + arrow. It owes way to
pedestrians in a crosswalk recorded as marking an entrance of `i`, and to other traffic in `i`.
"the right-of-way" is the standard. It is operationalized with the traffic-conflict technique:
`prim.closest_approach_within` and `prim.closest_approach_distance` with `p.conflict_horizon` and
`p.conflict_centre_clearance`, while moving faster than `p.halt_speed_tolerance`, and `rel.contact`.
The objects of the yield are condition spans. "lawfully" is not composed: every pedestrian and every
other road user is yielded to, a reading disclosed on the obligation span. The rule shares the 9b
exception. `branch_1` has no other party, to show the duty binds the subject alone.
**Reversal.** If labels excuse yielding to a road user that was itself unlawfully in the
intersection, compose the other road users' rules as `compliance`.

## NRS_484B_307_9b — motorcycle/bicycle exception under red + green turn arrow
**Decision.** Applies to the five admitted aggregates plus `ru.motorcycle` for the undefined
"trimobile", reusing the 8d mapping. The rule is judged at the exit from `i`. It applies to a passage
that entered under red + green arrow and is neither a turn in the arrow's direction nor a U-turn,
which covers straight through or turning opposite. Conditions (1)–(4) form the one obligation span:
- (1) A halt before entry, under the rule-4c approach convention with a `history_boundary` scenario.
- (2) While at rest at the place, the red + arrow display has risen at least the literal two times.
  That is how a "complete cycle" is counted, a reading disclosed on the span.
- (3) No `circular_green` appeared during the wait. The cause ("malfunction" or "failed to detect") is
  device status, read through the displays (`observable_reading`/status).
- (4) For a turn, no `no_left_turn` or `no_right_turn` regulatory sign governs.
- (5) The right-of-way is yielded, operationalized as in 9a_o2.

The occasion act is the left and right through-region concepts named in the obligation (the
validator requires exactly these). s1 and s3 are read `some_moment`, s4 `at_recognition`, and the
yield objects s8 and s9 `some_moment`, each with its occasion scenarios.
**Reversal.** If labels show that a different cycle event (for example a rise of red alone) is the
cycle the operator expects, change the counting reading.

## NRS_484B_307_9c — pedestrians facing red + green turn arrow
**Decision.** Facing a head is read as the head being within `p.ped_traffic_signal_facing_reach`
and within the facing angle `p.ped_traffic_signal_facing_cos`, the index mapping of 307_2b.
"Enter the highway" is entering the roadway, the index mapping of 307_8b. The pedestrian already
stands on the highway's sidewalk; that reading is disclosed. "unless permitted … as provided in
NRS 484B.283" is one `exception` per pedestrian-signal rule: `NRS_484B_283_1d1`, `_1d2`, `_1d3_o1`
and `_1d4_o1`. Where a pedestrian signal governs, its own rule decides. Under the "don't walk"
indications, that rule itself forbids starting.
**Reversal.** If labels judge a pedestrian under "don't walk" by 9c rather than by 283, compose only
1d1 and 1d2 as exceptions.

## NRS_484B_300_1 — obey any official traffic-control device (gap)
**Decision.** "the instructions of any official traffic-control device" names no rule. No atom
carries what a device instructs: device atoms carry a state or a code, never the conduct it requires.
The span is mapped to the nearest device atoms and filed as an `operator` gap,
`compliesWithDeviceRules`. The "Except as otherwise provided in NRS 484B.307" list is composed as one
`exception` per 307 node. `NRS-484B-307-11` has no node in the library or this plan, so its bracket
id is its own reference span with a residue. The police-officer exception reuses the index mapping.
**Reversal.** An operator for compliance with every engaged device rule (compare G22) is admitted, or
the operator names the device rules to compose as `compliance`.

## NRS_484B_310_1 — flashing red: stop before entering
**Decision.** A rule-4c duty: a halt is owed before the entry into `i` through a carrier governed by
a `flashing_red` head. The crosswalk and the limit line are read as alternative places (a disclosed
reading). Where the complete entrance lists show neither, the place is `i`'s edge. The search bound
follows the ontology's approach convention, with a `history_boundary` scenario. "the right to
proceed shall be subject to the rules applicable after making a required stop" names no rule. It is
a `reference` span with a residue: the proceeding is judged by those rules themselves.
**Reversal.** If the operator identifies the rules meant (for example `NRS_484B_257_2_o2`), compose
them as `compliance`.

## NRS_484B_330_1 — comply with an authorized flagger
**Decision.** Applies where a `dev.human_direction` with role flagger governs the subject's travel
region. That region must be on a highway and governed by temporary traffic control devices, or by a
temporary-traffic-control zone sign. "Authorized", "clearly marked" and "designated" are status
readings. Compliance is read per indication:
- stop: not passing the flagger's position (`dev.position` against `kin.position`/`kin.heading`).
- slow: not accelerating toward the flagger (`kin.accel_longitudinal` against `p.speed_decrease_decel_min`).
- turn(dir): by the time the subject passes the flagger, its heading has turned toward dir by at
  least `p.turn_heading_min`, or `p.u_turn_heading_min` for a U-turn (`Term.headingSince` from the
  indication's rise).
- proceed: a permission, so not acting on it is not judged.

**Reversal.** If labels treat a constant-speed approach under "slow" as a violation, the slow reading
must require deceleration. If labels judge a vehicle that stays halted under "proceed", that reading
must change.

## NRS_484B_360_1 — school bus 55 mph (gap)
**Decision.** The speed limit is the literal 55 mph on `kin.speed`. "when transporting pupils to and
from school" is a condition the validator will not let `ru.occupant_count` carry as a purpose
reading, because it is an identity attribute. No conduct in the scene tells a pupil trip from any
other. The span is mapped to `ru.occupant_count` as its nearest atom and filed as an `atom` gap,
`ru.pupil_transport_service`.
**Reversal.** The operator admits a service-state atom, or rules that carrying passengers is an
acceptable reading of the words.

## For the operator
- **G (NRS-484B-300-1, operator `compliesWithDeviceRules`).** This decides what conduct a governing
  device requires. It is related to the pending G22 ("in compliance with law"); a single
  "compliance with the engaged rules of a named class" operator would retire both.
- **G (NRS-484B-360-1, atom `ru.pupil_transport_service`).** Needed only if carrying passengers
  (`ru.occupant_count`) is not acceptable as the reading of "transporting pupils".
- **NRS-484B-307-11** is named in 484B.300(1)'s exception list but has no node; it is carried as a
  residue until one exists.
- **Occasion vocabulary.** Signal-phase triggers fixed to the moment of entry (9a_o1, 9b) are
  declared `some_moment`, the nearest available value. An `at_onset` occasion value would state them
  exactly.
- **Vehicle aggregate.** "Vehicular traffic" (8e, 9a) and "driver" (300-1) claim
  `DEF-NRS-484A-320::vehicle`, following the index precedent (NRS_484B_307_2a, LVMC_11_16_030),
  although the term table for those laws lists only `traffic` or `driver`. The validator accepted
  this.
