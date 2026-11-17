# Plan — batch 07 (LVMC 11.52 parking, 11.60.030 buses)

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts: every "park/stand" is the
earlier batch's `drv.motion.parked` (temporary halt excluded by `min_duration`, disclosed as a
`purpose` reading), every "stopped" is `drv.motion.complete_halt`. Re-proposed parameters keep the
earlier batches' name, value, unit and convention (`p.halt_speed_tolerance`, `p.parking_min_duration`,
`p.standing_min_duration`, `p.queue_halt_gap`). New: `p.curb_parallel_cos`,
`p.commercial_loading_max_halt`. Five nodes are codable. Three carry gaps (180-C, 305-A, A1/A2).

## LVMC_11_52_136 — parking in an access aisle
I map "No person shall park" to `drv.motion.parked` with `p.parking_min_duration`, the same as the
index's "It shall be unlawful for any person to park". "a vehicle" is the admitted vehicle
aggregate. "in an access aisle." is `st.parking_space` with designation `access_aisle`, anchored by
`rel.occupies`. The definition's design and marking clauses are read through the mapped designation
(`status`). Reversal signal: a source that maps access aisles as an area separate from the bays
rather than as a bay designation.

## LVMC_11_52_180_C — 30 minutes within any hour in an alley
"parked in an alley" is `drv.motion.parked` with `rel.occupies`/`st.alley`. The obligation limits
the **total** time parked within any one-hour window. `holdsFor` and `sinceRise` can only measure a
single continuous run. Writing the limit with them would let a vehicle that leaves for a moment and
comes back escape the limit, and that is a narrowing that drops what the words require. So the span
carries an `operator` gap (`durationWithin`) and the node is not coded. I read "otherwise lawfully"
as a residue of scope `none`: it says that complying with every other rule does not excuse going
over the limit. It does not exempt a vehicle that is unlawfully parked in some other way. Reversal
signal: a reviewer who reads "otherwise lawfully" as restricting the duty. That would need the
pending G22-style operator, "in compliance with law".

## LVMC_11_52_300 — non-motor vehicles, 1–6 a.m.
The subject is a vehicle and not a motor vehicle; the exception uses the admitted motor-vehicle
aggregate. "on any street" is mapped to `rel.occupies` and `st.highway`, the same as the index's
"upon any street". The city-limits part of the definition of "street" is the jurisdiction this city
ordinance already applies in, so it gets no assumption. The hours are compared on `env.civil_time`,
the same as the index's "between the hours of seven p.m. and six a.m.". Together with "for a period
of time longer than thirty minutes", this makes one continuous `.time` window. At every observation
in that window the vehicle is parked on the street within the hours. A period that starts before
1 a.m. only counts the minutes inside the hours (branch_1). Reversal signal: a label that counts
parking begun before 1 a.m. toward the thirty minutes.

## LVMC_11_52_305_A — commercial vehicles, RVs, trailers near residences, schools, parks
- **Subject.** The three admitted aggregates, plus `ru.trailer_or_combination` with the vehicle and
  trailer aggregates for "any combination of vehicle and trailer".
- **Length.** The overall length is `kin.extent`, compared with the literal 24 ft.
- **Location.** Adjacency to a residence district, public school or public park is a legal region
  class. It is the new assumption `asm.street_adjacent_to_residence_school_or_park`. The section's
  own meaning of "residence district" is a residue tied to that declaration.
- **Prohibited conduct.** "stand, park or store" is one standing prohibition
  (`p.standing_min_duration`).
- **Exception (1).** I read it as a commercial vehicle at rest with a door open. The `standard`
  "expeditiously" is operationalized as the current halt being no longer than
  `p.commercial_loading_max_halt`.
- **"Except as otherwise provided in this Section".** A residue of scope `none`, because the
  Section's other provisions are subsection (B), which is carried here.
- **Gaps (node not coded).** There are three atom gaps:
  - `dev.parking_permission_sign` for "as permitted by posted sign". No regulatory code or zone-sign
    kind permits parking for a class of vehicle.
  - `ru.unladen_mass` for the 8,000-pound weight. The earlier batch mapped LVMC_11_48_050's similar
    words to `ru.commercial_motor_vehicle`/`ru.truck`. I dispute that: the contract's "commercial
    mass class" is a threshold the jurisdiction sets, not this stated unladen weight. I declare no
    literal, because pounds is not a literal unit.
  - `ru.work_service_use` for exception (2).

  Reversal signal: the ontology adding any of these atoms.

## LVMC_11_52_340 — municipal parking spaces
"such space" points back to the space the first sentence designates. Both spans are carried by
`st.parking_space` with designation `municipal`, and the posted or marked designation is read
through the mapped bay (`status`). The second span is anchored by `rel.occupies`. "other than a City
vehicle" is `ru.official_vehicle` of kind `municipal`. I disclose that a city-owned vehicle without
municipal livery, such as a city fire engine labelled only as an emergency vehicle, is read as not a
City vehicle. Reversal signal: a label that excuses a city emergency vehicle parked in a municipal
space.

## LVMC_11_60_030_A1 — bus standing only at stops, stands and its own route's terminus
The subject is a bus and not a tour bus, with an `agency` reading for "operator". "Not stand or
park" is `drv.motion.parked` with `p.standing_min_duration`. The places come from LVMC 11.60.010
through a `definition` reference: "shall be designated by appropriate signs". So a bus stand and a
terminus are read as the signed bus zone (`st.curb_zone` kind `bus_stop`), and a bus stop is that
zone or `st.transit_stop`. "for the route to which such vehicle is assigned" has no carrier: nothing
ties a bus to its route or a route to its termini. It is an atom gap, `rel.route_terminus_of`, and
the node is not coded. Dropping the words would excuse standing at another route's terminus. Reading
them as never satisfied would forbid standing at the bus's own terminus. Reversal signal: a route
assignment atom in the ontology.

## LVMC_11_60_030_A2 — bus stops to load only at designated places
"stop" is a prohibited stop, so it falls under DEF-NRS-484A-260 by that definition's own scope. That
definition excludes halts made to avoid conflict with traffic, or made because a police officer or a
device directs them. `drv.motion.complete_halt` does not make those exclusions, so they are carried
beside it with the same atoms as the index's LVMC_11_52_130_A11: a queue gap (`p.queue_halt_gap`)
and governing devices or human direction. I use a bare road user rather than the traffic aggregate,
which the table does not admit for this law. The purpose "for loading or unloading passengers or
their baggage" is read as a door open while halted (`sig.door_open`, `purpose`). There are two atom
gaps: the same route gap as A1, and `env.emergency` for "except in case of an emergency". The
emergency gap matches the pending gap G20's proposal. The node is not coded. Reversal signal: both
atoms being added.

## LVMC_11_60_030_A4 — bus position at the curb when loading
- **Trigger.** A bus, not a tour bus, at rest with a door open while it occupies a bus stop, a
  signed bus zone (standing in for a bus stand or terminus, a `status` reading) or a passenger
  loading zone on a street.
- **Obligation.** Some road edge on the bus's right (`prim.region_lateral_offset` negative) is
  within the literal 18 in of the body outline (`st.region_geometry`).
- **Standard.** "approximately parallel to the curb so as not to unduly impede…" is operationalized
  with `p.curb_parallel_cos`, using the heading and the occupied carrier's direction.
- **Disclosed readings.** I read the wheel through the body outline: this is lenient by the tyre's
  inset from the body side. "Unduly impede" is read only through the alignment, and the movement of
  actual other traffic is not read.
- **Reversal signal:** a source that carries wheel positions, or a label that turns on another
  vehicle's movement being impeded.

## For the operator
- **Cumulative duration.** LVMC 11.52.180(C) needs an operator for the total time a condition holds
  within a sliding window (`durationWithin`). Several parking-limit ordinances with the shape "N
  minutes within any M-hour period" will hit the same gap.
- **Vehicle weight.** Unladen weight thresholds ("in excess of eight thousand pounds") have no atom.
  I dispute the earlier batch's mapping of LVMC_11_48_050's similar words to
  `ru.commercial_motor_vehicle`. The literal unit list has no pound, so the figure cannot be declared
  as a literal.
- **Bus route assignment** (`rel.route_terminus_of`) blocks both LVMC 11.60.030(A)(1) and (A)(2).
  **Emergency** (`env.emergency`) repeats the pending gap G20.
- **Permissive parking signs** have no regulatory code or zone kind (`dev.parking_permission_sign`).
