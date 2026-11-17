# Plan — batch 24 (NRS 484B.497 – 484B.557)

No law-local aggregates (`aggregates.jsonl` is empty); every class claim uses an admitted id of the
definitions table. No new concept: all nodes use `drv.motion.complete_halt` and `drv.motion.parked`
as proposed earlier in this iteration. No gap. The validator accepts all nine nodes.

**"Stop" with two posted definitions.** The table lists "stop" as ambiguous between
DEF-NRS-484A-255 ("when required") and DEF-NRS-484A-260 ("when prohibited"). Each definition states
its own scope, so the clause's own words pick one; that is not a choice between competing definitions.
The prohibitions (500, 503, 507, 510, 517) meet 260's scope: in 507, 510 and 517 the table itself
resolves "stopping" to 260. 557's "shall stop" meets 255's scope. In every "stop, stand or park"
obligation, 260's exclusions are carried beside the halt, as the mapping index does for "shall not
stop, stand or park a vehicle" (NRS_484B_477_2):
- a halt in a queue (`rel.ahead_behind_in_lane`, `rel.surface_gap` ≤ `p.queue_halt_gap`);
- a halt on a region governed by a stop sign, a yield sign, a red or yellow signal, a railway
  signal, or a police officer's stop indication.

"Other traffic" is read as any road user ahead, without the traffic aggregate, because that
aggregate is not admitted for these laws.
Reversal signal: a label that counts a halt queued in a loading zone as a violation.

## NRS_484B_497
- **Decision:** one node. "Stand or park" maps to `drv.motion.parked` with `p.standing_min_duration`, as in the index (LVMC_11_52_040_A).
- **Left-hand side:** the road edge nearest the vehicle, on the way of the one-way roadway, lies to the left of the roadway's designated direction. That side is `prim.region_lateral_offset`, turned into the roadway's frame by the sign of heading·direction, because a parked car may face either way.
- **Laned:** some `st.lane` lies on the same way.
- **Permitting devices:** a marked `st.parking_space`, an `angle_parking` regulatory sign, or a `parking_restricted` zone sign whose conditions hold.
- **Reversal signal:** a labelled recording that judges a vehicle parked against the left curb inside a signed time-limited zone as violating, or one that counts a laned two-way roadway's left curb.

## NRS_484B_500
- **Decision:** one node.
- **Designated places:** a hazardous place is a `dev.zone_sign` of kind `hazardous_place`. A congested place, which has no zone kind, is a `no_stopping` regulatory sign. Either sign's presence stands for the authority's designation (status reading).
- **Reversal signal:** an operator ruling that a no-stopping sign alone is not a congested-place designation. The `congested` branch would then become an atom gap (a zone kind `congested_place`).

## NRS_484B_503
- **Decision:** one node. "Expeditious" is operationalized as a halt that has not lasted `p.standing_min_duration`.
- **Loading passengers:** read by conduct, as a door open (`sig.door_open`) at some observation of the same halt (purpose reading).
- **Hours:** read from `parking_restricted` zone signs governing the vehicle's region (`prim.conditions_hold`). A marked zone with no such sign is read as effective at all hours.
- **Residue:** "for any purpose or period of time" is a scope-none residue.
- **Reversal signal:** a zone whose hours are set by ordinance, not posted. That would need an assumption for those hours.

## NRS_484B_507_1
- **Decision:** one node for both sentences, because 507(2) is an exception to 507(1).
- **Materials exception:** a door open during a halt by a truck or commercial motor vehicle, bounded by `p.commercial_loading_max_halt`. The class tells goods loading from passenger loading.
- **Passenger exception:** a door open during a halt within `p.standing_min_duration`, provided no truck (`ru.aggregate` motor_vehicle plus `ru.truck`, whose contract is "for carrying goods") stands halted outside the zone within the new `p.zone_entry_wait_reach`.
- The validator rejected a purpose reading carried by a class on "used for the transportation of materials". That span is now carried by `ru.truck`'s contract, not by a reading.
- **Reversal signal:** a passenger car making a package delivery labelled compliant past the standing duration.

## NRS_484B_510
- **Decision:** one node.
- **Restricted purpose:** a halt is for the restricted purpose where the governing `parking_restricted` zone sign's conditions hold for the vehicle. This includes its class condition, through `prim.conditions_hold`.
- **Known defect:** the primitive joins hours and class, so a halt outside the posted hours reads as not for the purpose (disclosed).
- **Passenger vehicle:** this term is undefined; it is read as the vehicle aggregate, neither `ru.truck` nor `ru.trailer_or_combination`.
- **Reversal signal:** a labelled halt outside posted hours that is judged compliant. That would need an operator that splits time conditions from class conditions (see below).

## NRS_484B_517
- **Decision:** one node.
- **Prohibition:** a non-bus in a `bus_stop` curb zone, or a non-taxicab in a `taxicab_stand` curb zone, may not halt. The admitted aggregates for bus and taxicab are used.
- **Designated and signed:** read from the curb zone's presence.
- **Exception:** "temporarily" and "expeditiously" are both bounded by `p.standing_min_duration`. Interference means a bus or taxicab halted outside the zone within the waiting reach.
- **Reversal signal:** a label treating a briefly halted car as compliant while a bus waits behind it.

## NRS_484B_533
- **Decision:** one node with a single obligation span. The validator requires exactly one, so the engine, brake and wheels spans were merged.
- **Applicability:** a halt (stand, DEF-NRS-484A-250) with nobody in the vehicle (`ru.occupant_count`). The grade must exceed `p.grade_resolution`: "perceptible" is the grade's presence at the source's resolution.
- **Obligation:** engine off, parking brake set, and the front wheels steered beyond `p.steer_angle_resolution` toward the nearest road edge.
- "Stand" here is the bare halt, not `parked`, because an unattended vehicle receives no passengers.
- **Reversal signal:** a label that counts a driver beside the car as attending it.

## NRS_484B_557_o1 / NRS_484B_557_o2
- **Decision:** two obligations — "shall stop within … of the nearest track" and "afterward may proceed only upon exercising due care".
- **First sentence:** it empowers the Department of Transportation and local authorities. It is carried as conditions: the crossing (`st.railway_crossing` on a highway) and the stop sign. The designation is read from the sign's presence. The sign is tied to the crossing through a chain: the sign governs the approach region, and that region lies on the same highway as the crossing.
- **o1:** a duty of rule 4c. The event is the entry into the crossing. The act is a halt with the body between the two literal distances, outside the crossing. The search runs back to the approach start (last farther than the upper literal) or to the previous exit. It has a `history_boundary` scenario.
- **o2:** the condition "afterward" refers to the halt that o1 states, so o2 carries that halt in full (the same span as a condition), not compliance with o1. "Due care" is a state-of-mind standard, so o2 is a **surrogate**. It is read as no rail-vehicle conflict (`p.conflict_horizon`, `p.conflict_centre_clearance`) and no contact while the vehicle is on the crossing.
- **Reversal signal for o1:** a crossing whose region outline does not begin at the nearest rail. Its distances would then need the rail itself.

## For the operator
- `kin.steer_angle` states no sign convention. NRS_484B_533 reads it left-positive, like `kin.yaw_rate`; a source with the opposite convention inverts that node's verdicts.
- `prim.conditions_hold` joins a sign's time windows and its class or occupancy conditions into one verdict. NRS_484B_510 needs the class condition alone ("the purpose to which parking … is restricted") outside the posted hours. Without a way to read them separately, a halt outside the posted hours reads as not for the restricted purpose.
- There is no device kind for a "congested place". NRS_484B_500 reads it as a `no_stopping` regulatory sign.
- New parameters proposed for review: `p.zone_entry_wait_reach` (10 m), `p.grade_resolution` (0.005), `p.steer_angle_resolution` (2 deg).
