# Plan — batch 04 (LVMC 11.40.130 – 11.43.010)

Ten nodes over eight law lines, and two new concept records. Every node is `accept` by the
validator. Two nodes carry atom gaps: `LVMC_11_40_170` (two gaps) and `LVMC_11_40_180_B` (one gap).
The coder does not write those two nodes, and their laws stay blocked until the gaps are resolved.
`aggregates.jsonl` is empty. No law here defines its own members, and every aggregate claimed is
listed as admitted in the definitions table.

## Concepts proposed

- **`drv.motion.parked`** (definition `DEF-NRS-484A-155`). The road user is at rest at every
  observation of a window behind it, of length `min_duration`. The rest test reuses
  `drv.motion.complete_halt` with `speed_tol`.
  - The quoted words are "the standing of a vehicle, whether occupied or not", so no occupancy is
    read.
  - The definition's exclusion of a temporary loading halt is a purpose. A purpose cannot be
    observed, so it is a residue, read only through the halt's duration.
  - Reversal signal: a labelled recording where a long halt during loading is judged not parked.
    That would call for a gap on the purpose, not a different duration.
- **`drv.motion.circulating_clockwise_about`** (region formal `r`). The road user moves clockwise
  about `r`'s reference point.
  - The test is the sign of the cross product of the offset from that point with the velocity. A
    squared, sine-tolerance band excludes motion toward or away from the point (roundabout entry
    and exit).
  - Clockwise is read in the frame where a left turn is counter-clockwise, as `kin.yaw_rate`
    defines it.
  - The concept denotes clockwise, not counter-clockwise, so that radial motion is not a
    violation.
  - Reversal signal: a source whose roundabout reference point is not the centre of the island.

Reused, not re-proposed: `drv.motion.complete_halt` and `drv.interaction.overtake_pass`. Neither
record declares an `act`, so no node here declares `occasion`.

## Nodes

**`LVMC_11_40_130` — bicycle speed (surrogate).**
- The whole duty is the standard "reasonable and prudent under the conditions then existing". It is
  operationalized as a bicycle stopping-sight-distance bound: reaction distance plus braking
  distance must not exceed the visibility.
- The surface selects the deceleration: `Term.cond` picks ice/snow, else wet or precipitation, else
  dry. Darkness caps the distance seen at the reach of a bicycle headlamp. Each factor moves the
  bound by its degree, not through one fixed switch.
- `st.sight_distance` was dropped. It needs a region kind and an anchor, and the text names no
  place. The catch-all is therefore disclosed as read only through visibility, surface and
  darkness; bends, crests, traffic density and grade are not read.
- "operate" is an `agency` observable reading. The rule applies only while the bicycle moves.
- Reversal signal: an operator decision to judge speed against sight distance on the travel region
  occupied. That would add `st.travel_region` + `rel.occupies` and narrow where the rule applies.

**`LVMC_11_40_140_o1` — halt before crossing the sidewalk.**
- This is the rule-4c duty of an act before an event, mapped the same way as `LVMC_11_20_060_o1`:
  "shall stop such vehicle immediately prior to" → `drv.motion.complete_halt`, and the sidewalk
  words → `rel.occupies`, `st.region_geometry`, `st.sidewalk`.
- The event is the subject's footprint coming onto sidewalk `s`. The place is the zone outside `s`
  within `p.stop_point_tolerance` of it.
- The search runs back through the run of observations within that zone. It ends at the approach
  start (the subject farther than the tolerance from `s`) or at the subject's previous occupancy of
  `s`. If it reaches neither end, the verdict is unknown; a `history_boundary` scenario covers this.
- **Deviation from the mapping index:** the trigger "entering into or emerging from an alley,
  driveway or building" adds `st.highway` to the earlier atoms (`rel.occupies`, `st.alley`,
  `st.driveway_or_alley_entrance`).
  - Why: "building" means coming from, or going to, beyond the property line. That is observable as
    occupying no `st.highway` region at the observation before entry, or occupying `s` until no
    highway region is occupied (entering a building, read through the movement itself).
  - The earlier mapping drops "building", which would narrow the trigger.
- "such vehicle" does not add a class condition. It refers back to the device the subject operates.
  `DEF-NRS-484A-320` excludes human-powered devices, electric bicycles and electric scooters, so
  reading it as a class would leave the duty empty. The vehicle aggregate is deliberately not
  claimed.
- "stop" resolves to `DEF-NRS-484A-255` ("when required"), the definition `complete_halt` carries.
- Reversal signal: the selection role insisting that "such vehicle" be claimed as an aggregate.

**`LVMC_11_40_140_o2` — yield to pedestrians while crossing the sidewalk.**
- "yielding the right-of-way to any pedestrian" → `kin.speed`, `rel.contact` (as the index maps
  "yielding") plus the pedestrian aggregate.
- The standard "as may be necessary to avoid collision" is bounded by the conflict technique:
  closest approach within `p.conflict_horizon` and below `p.conflict_centre_clearance`, while the
  subject moves.
- The rule applies while the subject stays on the sidewalk it entered under the o1 trigger. The
  trigger conditions are restated in full, not composed: the o1 node is not yet coded, and
  composing it would test compliance, not the event.
- A scenario with no pedestrian shows that the duty binds the subject alone.

**`LVMC_11_40_170` — parking (two atom gaps).**
- "park" → the new `drv.motion.parked` (`p.parking_min_duration`), with a `purpose` observable
  reading. "upon a street" → `st.highway` + `rel.occupies`. The city-limits half of the street
  definition is the code's own territorial scope, as the justification records.
- The allowed places are `exception` spans:
  - roadway against the curb: `rel.contact` with `st.road_edge`;
  - on the sidewalk at the curb: `st.region_geometry` distance to `st.road_edge` within
    `p.parked_edge_reach`.
- The standard "least obstruction to" (pedestrian traffic → pedestrian aggregate) means the body is
  within the placement margin of its edge and no pedestrian is in contact with it. The comparative
  "least" is disclosed as a narrowing.
- **Gaps:**
  - "in a rack to support …": `st.obstruction{sidewalk_fixture}` cannot tell a rack from a pole or a
    bench.
  - "or against a building": no atom carries a building's wall; `st.highway`'s boundary is the
    property line.
  - Either nearest atom would widen the allowance, which is an approximation the termination rule
    forbids.
- Reversal signal: an ontology revision adding a rack or a building region.

**`LVMC_11_40_180_A` — no riding on the Fremont Street sidewalks.**
- The named stretch is a legal designation of a way, carried by a new assumption
  `asm.fremont_street_main_to_seventh`.
- "ride" → not `drv.motion.complete_halt`, consistent with the index's "shall be ridden". This is
  an `agency` reading: a bicycle pushed along on foot is not told apart from one ridden.
- The second sentence directs the City to post signs. The prohibition does not depend on the
  signs, so it is a residue with scope `none`.
- Reversal signal: a labelled walked-bicycle scene, which would require reading
  `ru.rider_posture`.

**`LVMC_11_40_180_B` — sign-posted riding prohibitions (one atom gap).**
- The roadway branch: a `dev.regulatory_sign` of code `bicycles_prohibited` that governs
  (`dev.governs`) the roadway the subject occupies. "in the City" → `asm.within_city_limits`, as
  `LVMC_11_22_020` reads it.
- The Director's authority and determination are read through the sign's presence (`status`
  observable readings). "by any person" is a residue with scope `none`.
- **Gap:** "on any other sidewalk". `dev.governs` excludes regions no vehicle travels in, so no
  atom ties a sign to a sidewalk. Distance cannot stand in for belonging.
- Reversal signal: `dev.governs` extended to sidewalks.

**`LVMC_11_40_180_C_o1` — yield to pedestrians on the sidewalk.**
- The trigger covers riding (not at rest) on a sidewalk.
- "such person shall yield" → `kin.speed`, `rel.contact`. "the right-of-way" is the standard,
  bounded by the conflict technique per the danger-of-crash words of `DEF-NRS-484A-210`, as in
  `LVMC_11_43_010_B_o1`.
- A scenario with no pedestrian is compliant.

**`LVMC_11_40_180_C_o2` — audible signal before passing a pedestrian.**
- The pass is `drv.interaction.overtake_pass`. The signal is `sig.horn` or `sig.siren` (horn,
  bell, whistle). A spoken warning has no atom and is disclosed as a narrowing.
- "before" is a rule-4c search back from the pass onset, the last observation at which the
  pedestrian was ahead with headings aligned (`atLast` over `p.overtake_window`). The search covers
  the run in which the pedestrian stayed ahead and ends at its start. The `history_boundary`
  scenario covers a run that begins before the recording.
- The sidewalk trigger is read at some moment of the pass, documented in `applicability`.
  `branch_1` and `branch_2` cover a pass partly on the sidewalk and one where the rider is on the
  sidewalk only before the pass.
- Reversal signal: the pass concept gaining an `act` declaration, which would require an
  `occasion` block.

**`LVMC_11_43_010_A` — counterclockwise travel in a roundabout.**
- The preamble's "within a roundabout" → `rel.occupies` + `st.roundabout`. "All vehicular travel"
  → vehicle aggregate, not at rest.
- The obligation is the negation of `drv.motion.circulating_clockwise_about` on the occupied
  roundabout `r`, with `p.roundabout_clockwise_sin_tol`.
- The reference point is read as the centre of the island (a narrowing). The circulatory-roadway
  definition `DEF-LVMC-11-02-040` ("travel counterclockwise around a central island") supports
  this.
- An electric scooter is not applicable, because the vehicle definition excludes it.

**`LVMC_11_43_010_B_o1` — yield to vehicles already in the roundabout.**
- The event is the footprint coming onto the roundabout. "Already in" means a vehicle occupying it
  at the observation before and at the entry.
- Same conflict bound as the other yield nodes, judged at the entry.

**`LVMC_11_43_010_B_o2` — enter only at a gap in traffic.**
- A second obligation verb ("and wait … before entering"). "wait" is read as entering only at a
  gap; no halt is required where a gap already exists (a narrowing).
- The gap is the gap-acceptance standard: no traffic-aggregate member in the roundabout (pedestrians
  on its crosswalks included) comes within the clearance before `p.roundabout_critical_gap`.
- Reversal signal: a label requiring a halt at every entry.

## Parameters

- Proposed again with the values and conventions catalogued this iteration:
  `p.halt_speed_tolerance`, `p.stop_point_tolerance`, `p.conflict_horizon`,
  `p.conflict_centre_clearance`, `p.overtake_window`, `p.overtake_same_direction_cos`.
- New: `p.bicycle_reaction_time`, `p.bicycle_decel_dry`, `p.bicycle_decel_wet`,
  `p.bicycle_decel_ice`, `p.bicycle_lamp_reach`, `p.parking_min_duration`, `p.parked_edge_reach`,
  `p.roundabout_clockwise_sin_tol`, `p.roundabout_critical_gap`.

## For the operator

- **Gaps filed:**
  - `st.bicycle_rack` and `st.building` (both `LVMC-11-40-170`).
  - `dev.governs_walkway` (`LVMC-11-40-180-B`). The same need will recur for any sign-posted
    sidewalk restriction.
- **Frame handedness:** `drv.motion.circulating_clockwise_about` relies on the world frame in which
  a left turn is counter-clockwise, as the ontology states for `kin.yaw_rate` and
  `prim.region_lateral_offset`. A CARLA adapter that passes raw left-handed coordinates would
  reverse the sense.
- **Roundabout reference point:** `LVMC_11_43_010_A` needs the `st.roundabout` region's reference
  point at the centre of the central island. The manifest should say whether it is.
- **Audio:** sources without audio declare `sig.horn` and `sig.siren` absent, so
  `LVMC_11_40_180_C_o2` is unknown on them by design.
- **Fog/visibility:** `LVMC_11_40_130` is unknown wherever `env.visibility` is not observed.
