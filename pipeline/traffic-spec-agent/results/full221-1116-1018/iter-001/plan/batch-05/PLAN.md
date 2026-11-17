# Plan — batch 05 (iteration 001)

No law-local aggregates: `aggregates.jsonl` is empty.

## New concepts

`drv.motion.left_turn_through_region`, `drv.motion.right_turn_through_region` and `drv.motion.u_turn_through_region` are new. Each takes a road user `a` and a region `r`. Each is recognized at the observation where `a` leaves `r`, and its band is applied to the heading change since `a` entered `r` (`headingSince`, onset = the rise of `rel.occupies(a, r)`).

The proposed `drv.motion.left_turn`, `drv.motion.right_turn` and `drv.motion.u_turn` concepts do not fit a roundabout:
- Their fixed window behind the observation does not start at the entry, so a turn that takes longer than the window is lost.
- They are recognized when the yaw rate settles, not at the exit from the region the words name.

The U-turn record quotes DEF-NRS-484B-077. A full turn is a geometric literal, so that a loop is told apart from a reversal.

**Reversal signal:** the concept review finds `headingSince` cannot take a formal step parameter in a concept body.

## LVMC_11_43_010_C1 / LVMC_11_43_010_C2

One node per subsection. Each is judged at the observation where the vehicle leaves the roundabout `r` after a left turn or U-turn (C1) or a right turn (C2) through it.

**How the words are read:**
- **"who intends to exit"** is read through the exit itself (`observable_reading` intention, occasion `at_recognition`). It is not a declared intention: rule 2 limits `int.*` to an intention to turn, and the words state an intention to exit.
- **Turn direction** is read from the net heading change between entry and exit, so the counter-clockwise circulation in between does not count.
- **"Use the left lane"** means: every lane the vehicle occupies within `r`, from entry to exit, has ordinal 1.
- **"Use the right lane"** means: every such lane has ordinal equal to the count of lanes in that direction.

A single-lane roundabout complies trivially.

**Reversal signal:** the source declares route intentions (`int.*`) at roundabouts, or labels judge the lane on approach before entry.

## LVMC_11_46_030_o1

The duty is to stop not less than fifty feet from the crosswalk while the warning is given. It is planned under rule 4c.

**Event:** the vehicle comes within the literal fifty feet of the crosswalk (body distance from `st.region_geometry`) while a device governing its travel region warns. The warning is either:
- an active `dev.crossing_warning_signal`, or
- a `dev.human_direction` of any role with indication stop.

**Which crosswalk:** "the school pedestrian lane where [the device] is stationed" is the nearest crosswalk ahead of the vehicle (`prim.region_offset_along` > 0) on the same way (`st.on_way`). No atom relates a device's position to a crosswalk, so the device is tied to the crosswalk through the travel region it governs and the way both lie on (`observable_reading` status/intention). The warning's content, children crossing, is read through the warning itself.

**Search for the halt:** it runs back through observations where the warning holds continuously and the crosswalk stays ahead. It ends at whichever comes first:
- the warning's onset (a halt before the warning is no halt for it), or
- the previous entry into the fifty-foot zone, or
- an observation where the crosswalk is not ahead.

If the search runs into the recording's start, the result is unknown (`history_boundary`).

"stop" is read with DEF-NRS-484A-255, because its own scope ("when required") is the one these words meet.

**Reversal signal:** an atom relating a device's station to a crossing is added, or labels count a halt made before the warning began.

## LVMC_11_46_030_o2

"Unlawful to proceed" refers to the stop of the first clause. That stop is carried in full as a condition of this node: a halt at or beyond fifty feet while that device warns. It is not composed from o1, because it requires the act, not compliance with o1.

The duty holds while that device's warning lasts (`since`). It ends when:
- the signal goes inactive or disappears, or
- the person shows proceed, leaves, or no longer governs the lane.

**Reversal signal:** labels judge a vehicle that stopped closer than fifty feet as bound not to proceed. Then the fifty-foot qualification would be dropped from the condition.

## LVMC_11_48_050

The node is blocked by two atom gaps:
- **`ru.unladen_weight`:** "in excess of eight thousand pounds unladen weight" has no atom. `ru.commercial_motor_vehicle` and `ru.truck` are classes, not a weight.
- **`ru.special_permit`:** the Department's written special permit, with its conditions, has no observable counterpart. The proviso and the permit-conditions sentence are one exception span.

The weight figure has no literal, because the literal units have no mass unit. The gap carries the figure.

**What the node carries:**
- "Street" maps to `st.highway`, as in the index.
- "Truck route" is read through the truck_route regulatory sign (§9: a designation marked by a sign is read by the sign).
- "Residence district" is the new assumption `asm.residence_district`. The catalogue holds only the business-district ids, which have a different meaning.
- The hours are `env.civil_time` against the literals seven p.m. and six a.m.

The definitions table lists the truck aggregate for this law, but "truck" appears only in "truck route", which names a route, not road users. So the aggregate is not claimed.

**Reversal signal:** a mass attribute and a permit atom enter the ontology.

## LVMC_11_48_060

The words name no road user. The node reads the duty as binding trucks (`ru.aggregate=DEF-NRS-484A-305::truck`, claimed on "from one truck route to another"), the vehicles truck routes exist for. Binding every vehicle would forbid ordinary traffic from crossing between two truck routes, which the section does not mean.

**Trigger:** the truck comes onto a travel region governed by a truck_route sign.

**Violation:** in the stretch behind it, the truck stayed continuously on streets off truck routes, back to a truck-route region on a highway the new one does not lie on (`st.on_way`). That different highway is "another".

**Exception:** "unless pick-up, delivery or essential use is required" is a purpose. It is read through a parked halt on the stretch (`drv.motion.parked`, minimum duration `p.delivery_halt_min_duration`). An "essential use" that shows in no such halt is not read.

**Reversal signal:** the selection role or a label shows the ban binds every vehicle, or that a stretch returning to the same truck route counts.

## LVMC_11_52_030_A

**The duty:** red means no stopping. "Stopping" (DEF-NRS-484A-260) is any halt, carried by `drv.motion.complete_halt`, so standing and parking add nothing. Subsection (1) restates no parking for a red curb, so it is a condition span, not a second obligation.

**The definition's own exclusions** are carried beside the halt:
- **Avoiding conflict with traffic:** a road user ahead in the same lane within `p.queue_halt_gap`.
- **Following an officer or device:** a police stop indication, a red signal indication, or a stop sign governing the vehicle's travel region.

**Exceptions:**
- **(2) Tour buses, shuttle buses and limos:** the admitted aggregates, in a zone of kind `tour_bus_loading`, for up to the literal thirty minutes.
- **(3) RTC buses:** the admitted aggregate, in a zone of kind `bus_stop`, for up to the literal thirty minutes.
- **(4) Armored cars and emergency vehicles:** any halt. "The period necessary to conduct their business" is a purpose read through the halt.
- **(5) Mail drop box:** the vehicle's body is within `p.mail_drop_box_reach` of the box, and the halt so far is within `p.mail_deposit_max_halt`. "Expeditiously" is an operationalized standard; it is not a surrogate.

The duration tests in (2), (3) and (5) use `sinceRise` from the halt's start in the zone.

The second sentence ("shall be established by posting…") is the city's duty. It is read only as the signed or marked zone's presence (status).

**Reversal signal:** labels treat a vehicle queued at a red curb behind a vehicle farther away than the queue gap as compliant.

## LVMC_11_52_030_B

The yellow zone is "for" commercial vehicles and taxicabs. It is read as barring any other halt in the zone. The two listed uses are exceptions: the admitted aggregate, plus the conditions of an accompanying `dev.zone_sign` (kind `parking_restricted`) governing the curbside lane holding for the vehicle (`prim.conditions_hold`).

**Narrowing:** a halt outside the sign's posted times is read as outside "the conditions and times posted", so it is restricted, not freed.

"stop" has two posted definitions, each with its own scope. Both are a halting, which is all the node reads, so no choice between them is made.

**Reversal signal:** labels treat parking in a yellow zone outside the posted hours as compliant. The posted hours would then move to applicability, which would need an operator that tests a sign's time windows alone (`prim.conditions_hold` couples time and class).

## LVMC_11_52_040_A

**Trigger:** a vehicle stands or parks (`drv.motion.parked`, minimum duration `p.standing_min_duration`) in a roadway. The definitions' exclusion for passengers or loading is read through the halt's length.

**Duty:** the vehicle's heading is aligned, within `p.parked_heading_cos`, with the designated direction of every carrier it occupies. The edge runs along that direction, so this one reading gives both "parallel with the edge" and "headed in the direction of lawful traffic". The definitions table admits "traffic" for this law, so the traffic aggregate is claimed on that span.

**"Except as otherwise provided in this Chapter":** no corpus node states such a provision. It is read through a posted angle_parking sign (status).

**Reversal signal:** a corpus node of the Chapter that states a different placement rule appears. The exception would then become an `unless` composition.

## For the operator

- **LVMC-11-48-050** is blocked until the ontology carries a vehicle's unladen mass (`ru.unladen_weight`) and a permit status (`ru.special_permit`).
- The literal units have no mass unit (for example `lb`). The figure "eight thousand pounds" therefore lives only in the gap.
- No atom relates a device's position to a crossing or a curb zone (a device "stationed at" a pedestrian lane, or a sign "accompanying" a curb zone). LVMC-11-46-030 and LVMC-11-52-030-B read the link through the travel region the device governs. A `dev.stationed_at` relation would make that link exact.
- The definitions table lists the truck aggregate for LVMC-11-48-050 and LVMC-11-48-060, where the word occurs only in "truck route". It is claimed only in LVMC-11-48-060, where it names the road users the ban concerns.
