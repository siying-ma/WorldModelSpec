# Plan — batch 06 (LVMC 11.52.060, 11.52.070, 11.52.130 (A)(2), (4), (5), (7), (11), (12))

No law-local aggregates (`aggregates.jsonl` is empty). No new concept records: the nodes reuse
`drv.motion.complete_halt` and `drv.motion.parked`, which an earlier batch of this iteration proposed.

## LVMC_11_52_060 — projection into street (coded)

**Decision.** There is one node with one obligation span: "project into the street more than fifteen feet
measured on a line at right angles to the curb." The subject is a vehicle or a trailer, both
claimed as their admitted aggregates.
- "project" is read for a vehicle that is **parked** (`drv.motion.parked` with
  `p.halt_speed_tolerance`, `p.parking_min_duration`). The section sits in the
  stopping/standing/parking chapter and measures from the curb the vehicle stands at. Read
  literally, every vehicle driving in a lane more than fifteen feet from the curb would violate.
- "street" (DEF-NRS-484A-265) is `st.highway` anchored by `rel.occupies`, as the mapping index
  already reads it.
- "the curb" is the `st.road_edge` lying on that street (`st.on_way`) that is nearest the body.
- The projection is the body-to-curb ground distance (`st.region_geometry`) plus the body's extent
  across the curb line. That extent is length·|heading × dir| + width·|heading · dir|, where dir is
  the designated direction (`st.lane_direction`) of the travel region the vehicle occupies. That
  direction is read as the curb's line, and the reading is disclosed.
- A load is judged only inside the body outline the source reports. That limit is disclosed as a
  narrowing, because no atom carries an overhanging load.
- "attached to such vehicle" is a scope-none residue: a trailer is "a vehicle" by DEF-LVMC-11-02-170,
  so its own body is judged whether or not it is attached.

**What would reverse it.** If a labelled moving vehicle is judged under 11.52.060, drop the parked
reading. If an ontology atom for a curb's direction or for a load overhang is added, use it in
place of the carrier direction or kin.extent.

## LVMC_11_52_070 — angle parking (coded)

**Decision.** There is one node.
- The Traffic Engineer's determination and the duty to sign or mark the streets are not road-user
  duties. They are read as `status` observable readings: what shows them is an `angle_parking`
  regulatory sign governing the occupied travel region, or an occupied marked bay whose angle
  stands clear of zero. "Clear of zero" uses the new parameter `p.parking_space_angle_resolution`,
  which only states the source's resolution. The same mapping as the index precedent "The City
  Traffic Engineer is authorized to determine…" applies.
- The obligation span reuses the index mapping of "No person shall stand or park a vehicle"
  (`drv.motion.parked` with `p.standing_min_duration`). It also reuses the index mapping of
  "headed in the direction of lawful traffic movement" (`kin.heading`, `st.lane_direction`,
  `rel.occupies`, `st.travel_region`, traffic aggregate).
- "Front pointed toward" is a positive dot product of heading and designated direction on every
  selected travel region the vehicle occupies.
- A vehicle wholly inside a bay that overlaps no travel region is not judged. This is disclosed as
  a reading.

**What would reverse it.** If the source's `st_parking_space_angle` is not measured from the curb
line (for example, 90° for a parallel bay), the bay-angle test must change. A label that judges a
vehicle that is entirely within a bay would require a different direction source.

## LVMC_11_52_130 (A)(2), (A)(4), (A)(5), (A)(7), (A)(11), (A)(12) — no stopping at places (gapped)

**Decision.** All six share one preamble, and it is segmented the same way in each node:
- **"stop, stand or park".** "Stop" is prohibited here, so DEF-NRS-484A-260 applies by its own
  scope ("when prohibited, any halting, even momentarily"). The three verbs together therefore
  mean any halt: `drv.motion.complete_halt`. The index maps "No person shall stand or park" to
  `drv.motion.parked`; the word "stop" is why this mapping differs.
- **"except when necessary to avoid conflict … with other traffic".** This is a standard. It is
  operationalized by a road user of traffic (the admitted aggregate) ahead in the same lane within
  `p.queue_halt_gap` (`rel.ahead_behind_in_lane`, `rel.surface_gap`). Reading conflict only as
  traffic ahead in the lane is disclosed as a narrowing.
- **"the directions of a police officer".** `dev.human_direction` with role police_officer and
  indication stop, governing the occupied region. This is the index mapping.
- **"a traffic control device".** A stop sign, yield sign, red/yellow signal or active railway
  signal or gate governing the occupied region.
- **"in compliance with law" is an `operator` gap.** It excepts any halt that another law requires:
  yielding to a pedestrian at a crosswalk, stopping before the sidewalk when emerging from a
  driveway, stopping for a school bus or an emergency vehicle. No atom carries this, and
  `Formula.rule` composes only one named rule. The composable candidates are all "not composable"
  this iteration. The open gap smoke31-1111-0039:G22 proposes the same operator for the same
  words. Dropping the exception would make A12 and A11 report every lawful yield at a crosswalk or
  intersection as a violation. So all six nodes carry the gap and are not coded.

Places and their own gaps:
- **A11.** `st.intersection` and `st.region_geometry` within the literal fifteen feet.
- **A12.** Marked `st.crosswalk` within the literal twenty feet.
- **A2.** `st.curb_zone` of kind fire_lane, occupied. The designation and posting are a status
  reading. The Fire Code reference is out of the corpus and is a residue. "attended or unattended"
  and "public or private property" are scope-none residues.
- **A4.** `st.fire_hydrant` within a bound chosen by `Term.cond`: twenty feet where an
  angle-parking or no-parking sign, an angled bay or a no-parking/no-stopping/fire-lane zone
  applies, otherwise fifteen feet. The "posted / painted red / public or private" clauses are
  scope-none residues.
- **A5.** Has a second gap, an atom gap `st.sidewalk_elevator_or_chute`. `st.obstruction` kind
  sidewalk_fixture cannot tell an elevator from a bench. The frontage is read with the new
  parameter `p.curb_frontage_reach` and with `prim.region_offset_along` within five feet plus half
  the vehicle's length.
- **A7.** Has three further atom gaps:
  - `st.driveway_entrance`: the contract of `st.driveway_or_alley_entrance` says it cannot tell a
    driveway from an alley.
  - `rel.premises_privilege`: the exemption for the driveway's owner, controller, family or
    invitee.
  - `ru.postal_vehicle`: `ru.official_vehicle` has no postal kind.

  Also on A7:
  - "near a private driveway" is a standard, bounded by `p.driveway_near_reach`.
  - "on official business" is a `purpose` reading through the halt.
  - Paragraph (B)'s mention of Paragraph (1) concerns another line, so this node carries only the
    exception for (7).

**What would reverse it.** If the operator accepts G22, or an equivalent `requiredByRuleSet`
operator, the four laws whose only gap is p4 can be re-planned unchanged and coded: A2, A4, A11,
A12. If the operator rejects the gap with an allowed reading, for example "a law-required halt is
read through the device and traffic exceptions", p4 becomes an `observable_reading` on those atoms.

## For the operator

- **G22 ("in compliance with law") blocks LVMC-11-52-130 (A)(2), (4), (5), (7), (11) and (12).** It
  is the same open gap as smoke31-1111-0039:G22, proposed here as `Formula.requiredByRuleSet`. One
  decision on G22 unblocks four of these laws outright.
- **New parameters proposed:** `p.parking_space_angle_resolution` (deg), `p.curb_frontage_reach`
  (m) and `p.driveway_near_reach` (m).
- **`st.parking_space` angle attribute.** Its reference direction is not stated in the ontology.
  These plans assume 0° means parallel to the curb.
