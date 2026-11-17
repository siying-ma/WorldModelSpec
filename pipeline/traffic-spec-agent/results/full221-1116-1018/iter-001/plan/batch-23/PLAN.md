# Plan — batch 23 (NRS 484B parking: curb position, angle, night lamps, alleys, narrow and one-way highways)

No new concepts: every node reuses `drv.motion.complete_halt` or `drv.motion.parked` from this iteration. No law-local aggregates (`aggregates.jsonl` is empty). No composition: the library has no composable node, and no span of these laws names another rule. Every parameter is one an earlier batch proposed, reused with its value and convention unchanged, except `p.bay_angle_cos_tolerance` and `p.entrance_block_gap`, both of which are new and belong to gapped nodes.

**How "stop, stand or park" is read where it is prohibited (NRS_484B_460, NRS_484B_477_1a, NRS_484B_477_1b, NRS_484B_477_2).** The table resolves "stop" to two definitions, each with its own scope. Where stopping is prohibited, DEF-NRS-484A-260 applies: "any halting, even momentarily … except when necessary to avoid conflict with other traffic or in compliance with the directions of a police officer or official traffic-control device". Standing and parking are halts too, so the three verbs together are read as the halting they all are (`drv.motion.complete_halt`), with the stopping definition's exception carried by observable conduct:
- a halt in a travel region governed by a signal, a stop sign, a yield sign, a railway device or a person directing traffic; or
- a halt queued behind a road user ahead in the lane within `p.queue_halt_gap`.

This follows the index mapping of "shall not stop" (NRS_484B_413_3). The words "No person shall stop, stand or park a vehicle" are mapped in the index to the halt alone (LVMC_11_52_130_A11). That node carries the exception on other spans of its own, which is why the device and queue atoms here sit on the obligation span. Each node discloses this as a narrowing. The signal that would reverse it: a labelled recording in which a vehicle queued or halted at a signal inside the regulated place is labelled violated.

**NRS_484B_457_1** — one obligation: the right-hand wheels parallel to the right-hand curb and within 18 inches of it. Subsections (2) and (3), which the text appends, are exceptions of this node.
- **Trigger.** "stopped or parked" is a halt (`complete_halt`). A halt made for traffic (at a device governing the subject's region, or queued) is read as not the stop the section speaks of. This is disclosed as an `observable_reading` of category `purpose`, since why a vehicle is stopped is not observed; DEF-NRS-484A-260 supports it. The validator refused a plain narrowing on the trigger.
  - Reversal: a label that treats a vehicle halted at a red light away from the curb as violating 457(1).
  - The words "stopped or parked" are mapped differently from the index (450_1l maps them to the halt alone): there they describe another vehicle; here they decide when the subject's duty arises.
- **Curbs.** "Adjacent curbs" is read from `st.lane_marking` type `curb`, because `st.road_edge` ("curb or edge") cannot tell a curbed edge from a plain one. The distance to the curb is measured to a road edge on the same way, on the subject's right.
- **Wheels and parallel.** The body outline stands for the wheels, which is lenient by the wheels' inset (a narrowing). "Parallel" means within `p.parked_heading_cos` of the carrier direction, headed with it.
- **Left-curb exception (2).** Permission by ordinance shows on no road feature, so it is the assumption `asm.left_curb_parking_permitted`, a legal designation of the way.
- **Angle-parking exception (3).** Read from the posted `angle_parking` sign or an angled bay (status). The words binding the Department and local authorities, on where angle parking may be permitted, are part of the device's presumed lawful status: they are carried inside that exception span, not as a road-user condition.
- **The opening words.** "Except as otherwise provided in this section" only points at (2) and (3), so it is a residue of scope `none`.

**NRS_484B_460** — planned but not codable: an `operator` gap.
- The vehicle's angle to the curb has a cosine (its heading dotted with the carrier direction), while the angle the device indicates is the bay's `angle` attribute in degrees. Term has no trigonometric operator, so the two cannot be compared. The gap proposes `Term.cosDeg`.
- The obligation words are one span (the validator requires one obligation span), carried by the halt plus the nearest atoms of the angle.
- "Those highways which have" devices is read as the region the angle sign governs, or an angled bay the subject occupies, where an indicated angle exists.
- Reversal: an operator able to compare the two, or an ontology row giving a bay's orientation as a direction.

**NRS_484B_473_2** — planned but not codable: an `operator` gap on "lawfully".
- "Lawfully parked" turns on the verdict of every parking rule the vehicle engages, and the words name none. `Formula.rule` composes one named rule. No published parking rule exists to compose either.
- The gap repeats the need of carried-over gap smoke31-1111-0039:G22 ("in compliance with law").
- The rest is planned:
  - parked: `drv.motion.parked`;
  - nighttime: `env.darkness`;
  - on a highway: `st.highway`;
  - lights displayed: headlamp or position lamp;
  - "cowl or parking lamps not used": the headlamps are lit. `sig.position_lamp` also lights with the headlamps, so it cannot tell parking lamps used in their place.
  - The duty is that the headlamp is not `high_beam`.
- Reversal: the operator retires G22 or decides this gap.

**NRS_484B_477_1a**
- "Unless otherwise provided by ordinance" is the assumption `asm.local_alley_ordinance`: an administrative designation of the alley, with no road feature.
- "In a business district" reuses `asm.business_district`.
- The standard "expeditious loading or unloading of goods" is operationalized by `drv.motion.parked` with `p.parking_min_duration`. The unobserved purpose is read through the halt's brevity: a halt beyond the temporary-halt bound is not excepted. This is disclosed on the standard span.
- Reversal: a labelled short halt without loading judged violated, which would call for door-open evidence (`sig.door_open`) instead of duration.

**NRS_484B_477_1b**
- "In any other" refers to paragraph (a)'s "alley in a business district". It is carried as `asm.business_district` not holding, so the alleys of (a) are left out with their qualification intact.
- The words "in such a manner, or under such conditions as to leave available less than 10 feet …" are a condition on the prohibited halt (the validator requires one obligation span).
- The free width is measured on each side of the body:
  - to the nearest road edge (ground distance, side from the lateral offset);
  - or to an obstruction or a halted member of traffic alongside on that side;
  - a side is free when everything on it is at least 10 feet away.
- "Vehicular traffic" claims the traffic and vehicle aggregates: members of traffic halted alongside narrow the width, and the width serves vehicles whether or not one is present.
- The obligation is the halt's prohibition, with the stopping definition's exception.

**NRS_484B_477_2** — planned but not codable: an `atom` gap.
- `st.driveway_or_alley_entrance` "does not tell an alley's entrance from a private road's or driveway's". Inside an alley it would mark the alley's own mouth onto the street, which is no "entrance to any abutting property".
- The gap proposes `st.property_entrance`.
- "Block" is read as overlapping the entrance's mouth, or standing within `p.entrance_block_gap` of it (newly proposed).
- Reversal: an attribute or atom telling property entrances apart.

**NRS_484B_490**
- "Devices … prohibiting parking upon a narrow highway" is the `dev.zone_sign` kind `narrow_highway` governing the subject's travel region, with its conditions holding. The highway's narrowness is the posting's designation, read from the sign (status).
- "Upon any such highway" is the same governed region.
- "Park" is `drv.motion.parked` with `p.parking_min_duration`.
- Reversal: if the narrow_highway zone sign proves to be a warning only, the trigger needs a no_parking regulatory sign inside such a zone.

**NRS_484B_493**
- Notice is read from:
  - a `no_standing` or `no_parking` regulatory sign whose conditions hold, governing the subject's region; or
  - a `no_parking` / `no_stopping` curb zone the subject occupies.
- "Street" is a highway inside a city (DEF-NRS-484A-265), carried by `asm.within_incorporated_city` on its own span. The way itself is carried by the one-way roadway it lies on.
- The left-hand side is relative to the roadway's designated direction: the subject is nearer a road edge on the left of that direction than every edge on its right. The side is taken from the lateral offset, signed by heading·direction.
- "Stand or park" is `drv.motion.parked` with `p.standing_min_duration`, following the index mapping of "No person shall stand or park a vehicle".

## For the operator

- Three nodes carry gaps and will not be coded until they are decided:
  - `Term.cosDeg` (NRS_484B_460);
  - a compliance-with-all-engaged-rules operator for "lawfully" (NRS_484B_473_2, the same need as G22);
  - `st.property_entrance` (NRS_484B_477_2).
- `asm.local_alley_ordinance` (new) and `asm.business_district` must be declared per map for the alley nodes. An undeclared assumption leaves their verdicts unknown.
- `p.parking_min_duration` (180 s) and `p.standing_min_duration` (60 s) are windows behind the observation. On recordings shorter than these windows, every long halt reads unknown, not violated.
- `st.lane_marking` type `curb` is the only atom that shows the presence of curbs in NRS_484B_457_1. A source that does not label curb-type lane sides leaves that law unknown.
