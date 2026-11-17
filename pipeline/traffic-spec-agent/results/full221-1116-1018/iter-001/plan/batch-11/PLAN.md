# Plan — batch 11 (NRS 484B.217(2)–(4), 484B.220, 484B.223)

No law-local aggregates (`aggregates.jsonl` is empty). Two new concepts are proposed:
`drv.motion.moving_against_carrier` and `drv.lane.entering_adjacent_lane`. All nodes and concepts
pass the validator (`accept`).

## NRS_484B_217_2

**Decision.** This is one node. Its one obligation span is "shall not drive on the left side of
the highway within such zone or drive across or on the left side of any pavement striping…".
- **Zone membership.** "Such zone" is the no-passing zone that subsection 1 lets an authority
  mark "by signs or markings". A vehicle is in the zone when either holds:
  - it occupies a travel region governed by a `dev.zone_sign` of kind `no_passing` that is not an
    end sign; or
  - the left `st.lane_marking` of its lane is a solid or double solid yellow line.
  - Where that marking is `solid_broken`, the atom does not say which side the solid half is on,
    so membership is unknown.
- **The breach.** Driving on the left side of the highway and crossing the zone striping are
  read as one fact: the body reaches past the centre line. That is, the
  `prim.region_lateral_offset` of `st.centre_line` is below half the `kin.extent` width minus
  `p.lateral_position_tolerance`. This reuses the index's mapping for NRS_484B_213_2a.
- **Subsections 3 and 4 are this line's own exceptions.** So "Except as otherwise provided in
  subsections 3 and 4" is boilerplate.
- **(3), crossing to an adjoining highway.** The vehicle reaches another highway within
  `p.vehicle_turn_window` (observable_reading `purpose`). It must also have given a left signal
  at the observation before the crossing, and there must be no closest-approach conflict with
  oncoming or following members of `DEF-NRS-484A-285::traffic`.
- **(4), crossing to make a left-hand turn.**
  - The vehicle has a declared `int.left_turn` at an intersection or driveway entrance.
  - It gave the left signal, and NRS_484B_413_2 is complied with (a `compliance` composition on
    the reference span).
  - "Safe" and "no impediment" are operationalized with the conflict technique
    (`p.conflict_horizon`, `p.conflict_centre_clearance`).
  - "Except where otherwise provided" names no rule, so it is a residue of scope `none`.
- **Subject.** "A driver" maps to `DEF-NRS-484A-320::vehicle` with an `agency` reading, as the
  index maps "the driver" (LVMC_11_16_030). The table lists no vehicle row for this law. The
  driver definition borrows "vehicle" ("drives … a vehicle").
- **Disclosed narrowing.** Zone striping is read only where it lies along the centre line. A
  no-passing line between two lanes of the same direction is not read.

**Reversal signals.**
- Labels that treat a lane-line no-passing stripe as the zone striping.
- A selection-role ruling that the vehicle aggregate may not be claimed for "driver" here.
- A source whose `solid_broken` record states the solid side.

## NRS_484B_220_1

**Decision.**
- The condition is a `st.one_way_roadway` the vehicle occupies. "Designated and signposted" is an
  observable_reading of category `status`: the one-way roadway's presence is the evidence.
- The obligation is that new concept `drv.motion.moving_against_carrier(subject, r)` does not
  hold. Its `speed_tol` is `p.halt_speed_tolerance`.
- Velocity across the direction, as when entering or leaving the roadway, is not a breach. This
  is a disclosed reading.
- "Traffic" is claimed as the admitted aggregate on the condition span. This follows the index's
  "(d) Upon any highway on which traffic is restricted…".

**Reversal signals.**
- Labels that require a recorded `one_way` sign.
- Labels that count backing along a one-way roadway as compliant.

## NRS_484B_220_2

**Decision.**
- The vehicle occupies a `st.roundabout`. Driving "to the right of such island" means that
  `drv.motion.circulating_clockwise_about(subject, r)` does not hold. This is the concept the
  index maps for LVMC_11_43_010_A.
- The island's centre is read as the roundabout's reference point. This is a disclosed reading.
- "Traffic" in "rotary traffic island" names a structure, not the road users the duty turns on,
  so the traffic aggregate is not claimed. The validator accepts this.

**Reversal signal.** A roundabout whose reference point is not its island centre in the
source's maps.

## NRS_484B_223_1b

**Decision.**
- The condition is the subject's lane, with a `st.lane_adjacency` count of at least the literal
  2. "Clearly marked" is a `status` reading.
- The obligation span covers both "Not be moved from that lane" and "until … appropriate turn
  signal". The validator requires one obligation span per node.
- The move is the new event concept `drv.lane.entering_adjacent_lane(subject, l1, l2, side)`.
  Its literal side is matched with `sig.turn_indicator` or `sig.hand_signal` of the same side.
  The signal is read at the move and at the observation before it.
- "Ascertained that such movement can be made with safety" is a `perception` reading of the
  outcome. Safety is operationalized as no contact and no closest-approach conflict at the onset
  of the move.

**Reversal signal.** Labels that require the signal for a duration, which would call for
composing NRS_484B_413_2. The words here do not name that rule.

## NRS_484B_223_3a

**Decision.**
- The vehicle occupies a `st.centre_turn_lane`. Its presence there is excused in either case:
  - **"From the highway":** a declared `int.left_turn` at an intersection or driveway entrance.
  - **"Onto the highway":** the vehicle has stayed in the lane since a `drv.motion.left_turn`
    recognized there, and some observation in the turn window before that turn found it off
    that highway. This is a `purpose` reading through conduct.
- An intention cannot carry the "onto" case: once the turn has been made, the plan declares it
  false.

**Reversal signal.** A source that declares intentions for completed turns.

## NRS_484B_223_3b

**Decision.**
- The duty is judged when a `drv.motion.left_turn` is recognized whose window shows that the
  vehicle came out of the centre turn lane.
- At the last observation in that lane, the continuous run in it (`Term.distanceWhile` over
  `rel.occupies`; claims `kin.path_length`) must be at most the literal 200 ft.
- A run that began before the recording is unknown.

**Reversal signal.** Labels that judge the travel before an intended turn that has not yet been
made. That reading would need `int.left_turn` in place of the act.

## NRS_484B_223_3c

**Decision.**
- The run is in the centre turn lane since a left turn recognized there, after the vehicle was
  off that highway within the turn window. Its `distanceWhile` must be at most the literal
  50 ft.
- "Merging" ends when the footprint leaves the lane. Distance travelled while straddling counts;
  this is a disclosed reading.

**Reversal signal.** Labels that end the count when the vehicle first overlaps the through lane.

## NRS_484B_223_4a

**Decision.**
- The vehicle occupies a `st.turn_lane` of side `right`. Its presence is excused only by a new
  declared intention `int.right_turn` at an intersection or driveway entrance.
- `int.right_turn` mirrors the catalogue's `int.left_turn`. "For the purpose of making a right
  turn" is intention to turn, so no act read ahead may carry it.

**Reversal signal.** None in the words. A source with no plans makes the rule unknown by
design.

## New parameter

`p.vehicle_turn_window` (10 s) is used by 217(2), 223(3)(a), 223(3)(b) and 223(3)(c). The
catalogue's `p.turn_window` is not used, because its convention is the turn of a bicycle or a
scooter.

## For the operator

- **No-passing striping.** `st.lane_marking` `solid_broken` does not say which side is solid. A
  no-passing striping is therefore unknown for a lane with that marking.
- **Composition on NRS_484B_413_2.** NRS_484B_217_2 composes NRS_484B_413_2, which is planned
  this iteration and not yet composable. Its coding waits on that node's publication.
- **"Driver" in NRS 484B.217(2).** The defined-terms table lists no vehicle aggregate for this
  law. The plan claims `DEF-NRS-484A-320::vehicle` for "a driver" through the driver
  definition's own words "drives … a vehicle".
