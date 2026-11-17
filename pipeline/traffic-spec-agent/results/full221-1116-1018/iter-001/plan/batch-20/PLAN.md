# Plan — batch 20 (NRS 484B.363, 484B.400, 484B.403(2))

No new concepts, no law-local aggregates, no gaps. Concepts reused: `drv.motion.u_turn`,
`drv.interaction.overtake_pass`, `drv.motion.left_turn_through_region`,
`drv.motion.moving_against_carrier`. Declared facts introduced: `asm.school_in_session_day`,
`asm.school_outside_operation_margin`, `asm.pupils_in_class`; intentions reused: `int.right_turn`,
`int.left_turn`. New parameter: `p.approach_lane_same_direction_cos`; the others are proposed again
with the values and conventions already in the catalogue.

## NRS_484B_363_1 — school zone speed (15 mph)

Decision: a motor vehicle (admitted aggregate) whose footprint overlaps a travel region governed
by a `dev.zone_sign` of kind `school` (not an end sign) must not exceed the literal 15 mph.
"Designated as a school zone" is read through the sign, following ontology §9: where a sign marks
the category, the sign is the atom. "Designated" is an `observable_reading` of category `status`.
The exceptions are:
- (a) and (b) are calendar and clock conditions (§9 legal region classes), so they are carried as
  assumptions. (b) is one assumption whose meaning keeps the half-hour margins. Building it from an
  "in operation" assumption with half-hour windows would make almost every short trace unknown,
  because the windows would be truncated.
- (c) is an operational beacon (`dev.speed_limit_beacon` governing the region and not
  `dev.inoperative`) together with `asm.pupils_in_class` and the beacon not flashing.
- (d) is no operational beacon together with `prim.conditions_hold` false for the zone sign.

The section's own definition of "speed limit beacon" is the contract of
`dev.speed_limit_beacon`. Reversal signal: a gate ruling that `dev.inoperative` (contract: "a
signal head") cannot be read on a beacon. That would make "operational" an `atom` gap.

## NRS_484B_363_2 — school crossing zone speed (25 mph)

This node has the same structure as 363_1, with a zone sign of kind `school_crossing` and the
literal 25 mph. Exception (d) in this subsection says "the sign designating the *school zone*".
It is read as the sign designating the zone of this duty, the school crossing zone. The subsection
speaks of no other zone, and a crossing zone need not carry a school-kind sign. Reading the words
literally would make (d) unreachable in most crossing zones. Reversal signal: a label that treats a
crossing zone with no school-zone sign as never excused under (d).

## NRS_484B_363_3 — no U-turn in a school or school crossing zone

Decision: the obligation forbids `drv.motion.u_turn`, the window act with DEF-NRS-484B-077 as its
definition. Occasion:
- The zone trigger is read `some_moment` while the U-turn is under way. "Under way" means the yaw
  rate is above `p.turn_yaw_rate_tol` within the window `p.vehicle_turn_window`.
- The exceptions mapped by elements ((a), (d), (e)) are read `throughout`, each with its two
  occasion scenarios.
- The assumption spans are read the same way in the applicability text. The validator accepts the
  occasion only over element-mapped spans, so they have no occasion scenarios.

"No children present" means no `ru.child` within `p.pedestrian_near_reach` of any region the zone
sign governs. This reads presence in the area, including the sidewalk, and the reach relates a
region to a road user.

Disclosed narrowing of the exception: a child riding a device is not `ru.child`, so it is not
counted, which makes the duty slightly broader than the words. Reversal signal: a labelled scene
in which a child on a bicycle in the zone excuses the U-turn.

## NRS_484B_363_4 — no overtaking in a school or school crossing zone

Decision: the obligation forbids `drv.interaction.overtake_pass(subject, b)`. Here `b` is any other
road user in the vehicle aggregate, quantified in the rule and not a binder. The concept says
nothing of whether `b` moves, so "traveling" is carried beside it: `b`'s `kin.speed` must exceed
`p.halt_speed_tolerance` at some moment of the pass. Occasion:
- Window `p.overtake_window`.
- `under_way` reads the subject's speed together with the bearing, overlap and heading relations
  that begin the act.
- The zone trigger is read `some_moment` and the exceptions `throughout`.

The permit scenario has no other vehicle and expects compliance, which shows the duty binds the
subject alone. Reversal signal: a label that judges a pass of a vehicle at rest in the zone as a
violation (then drop the travelling condition).

## NRS_484B_400_1_o1 / NRS_484B_400_1_o2 — right turn lane or extreme right lane

Decision: the line holds two alternative duties: the right turn lane where the highway has one,
and otherwise the extreme right lane. These cannot be one contiguous obligation span, so they are
two nodes, each the other's `sibling`.

"Intends to turn" and "The turn is a right turn" are both carried by `int.right_turn` at the
intersection `i`. The approach and the turn are read at the observation before the subject enters
`i`: the approach ends there and the turn begins there.
- `_o1` requires occupying the single right `st.turn_lane` that enters `i` with a direction aligned
  to the subject's approach lane.
- `_o2` applies where there is no such lane. It requires the lane entering `i` whose
  `st.lane_adjacency` ordinal equals its count. An unlaned directed approach segment is read as a
  single line of traffic.

Referring and defining spans: "as set forth in subsection 4 of NRS 484B.223 [NRS-484B-223-4a,
NRS-484B-223-4b]" is a `definition` reference. It borrows "a single right lane to be used only for
turning"; "single" is kept as "exactly one". It composes neither rule, because the lane exists
whatever any vehicle does in it.

Disclosed narrowing: a lane change into the required lane earlier on the approach is not a breach.
Reversal signal: a label that judges such a late lane change a violation, which would require
reading the whole approach segment.

## NRS_484B_400_2a — left-turn approach next to the centerline

Decision: the node applies where `int.left_turn` is declared at intersection `i` and every highway
`i` lies on is two-directional. Two-directional (DEF-NRS-484B-073) means no `st.median_or_divider`
on the highway and two of its carriers with opposed designated directions, within
`p.lane_opposed_direction_cos`.

At the observation before entry, the subject must occupy a carrier entering `i` that is lane
ordinal 1 of its direction, or, where it occupies no lane entering `i`, a directed approach segment.
It must also occupy no carrier on the same way whose direction is opposed.

The side of the centerline is read through designated directions, because DEF-NRS-484A-040 says the
line marks "each portion of a highway allocated to traffic proceeding in the two opposite
directions". `st.centre_line` is not used: no relation ties a centre-line region to the subject's
approach without using distance as belonging. "That portion … nearest the centerline" is read at
the granularity of lanes; this narrowing is disclosed. Reversal signal: a label that requires a
lateral position within a single approach lane.

## NRS_484B_400_2b — leave the intersection right of the centerline

Decision: the act is `drv.motion.left_turn_through_region(subject, i)`. Its boundary is an event:
the onset is the entry into `i` and the recognition is the exit. At the exit, the subject must move
against the designated direction of no lane its footprint overlaps (`drv.motion.moving_against_carrier`,
speed tolerance `p.halt_speed_tolerance`).

The intention is read at some observation while the turn is under way (branch_2 and branch_3 show
both sides). The intersection kind and the two-directional condition are static map facts read at
recognition. The validator accepts the occasion only over element-mapped spans.

Disclosed narrowing: an entered highway with no mapped lane is not read. Reversal signal: a source
whose receiving roadways carry no lanes.

## NRS_484B_403_2 — obey a device prohibiting U-turns

Decision: the devices whose indication is a U-turn prohibition are read as `dev.regulatory_sign`
of code `no_u_turn` while its conditions hold. A signal's arrows indicate stop or go, and no marking
in the ontology states a U-turn prohibition. "Obey the directions" means that `drv.motion.u_turn`
is not recognized while, at some moment of the turn, the subject is under the sign. "Under the
sign" means one of:
- the subject occupies a region the sign governs; or
- the subject occupies an intersection that a governed lane enters, having come from that lane.

The second case reads the sign's control of the junction through `dev.governs` and
`st.lane_enters`, as the ontology prescribes.

The subject's class uses the run's admitted `DEF-NRS-484A-320::vehicle`. It is the vehicle named in
the words of the "driver" definition; the table lists no vehicle row for this law, and the
validator accepted the claim. Reversal signal: the selection role ruling that this law may not
claim that aggregate.

## For the operator

- **Beacon "operational".** It is read through `dev.inoperative`, whose contract names "a signal
  head". If a source cannot declare it for speed limit beacons, exceptions (c)/(d) of 363(1)–(4)
  will be unknown wherever a beacon is present. Consider widening that contract to lamp devices.
- **School assumptions.** `asm.school_in_session_day`, `asm.school_outside_operation_margin` and
  `asm.pupils_in_class` must be declared per trace. Wherever the duty would otherwise be breached,
  an undeclared assumption makes the verdict unknown.
- **Child presence.** `ru.child` covers pedestrians only. Children on bicycles or scooters in a
  school zone cannot be counted for 363(3)(a).
- **Pavement markings.** No marking atom carries a U-turn prohibition or similar word or symbol
  marking (403(2)).
