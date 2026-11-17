# Plan — batch 27 (iteration 1)

Eight law lines, nine nodes. No law-local aggregates (`aggregates.jsonl` is empty): every defined term the duties turn on is an admitted aggregate or a `not_aggregate` place word. No new concepts. The nodes reuse `drv.motion.complete_halt`, `drv.motion.parked` and `drv.interaction.overtake_pass`, all proposed earlier in this iteration. Three nodes carry gaps and will not be coded: `NRS_484B_769`, `NRS_484B_913` and `NRS_484D_100_1`.

## NRS_484B_769 — hand signals of bicycle, electric bicycle and electric scooter operators (gap)

**What the line requires.** It requires every signal to be given "by hand and arm in the manner required by NRS 484B.420". The exception lets a right-turn signal be given with the right arm extended horizontally to the right.

**How the words are carried.**
- The reference span s4 (`by NRS 484B.420 [DEF-NRS-484B-420],`) is a `definition` reference. It borrows the manner text of DEF-NRS-484B-420.
- The obligation element s3 carries the borrowed words, with `source_spans` set to s4.
- "by hand and arm" is carried by `sig.hand_signal`. A signal given by the turn indicator alone (`sig.turn_indicator`) fails it.

**Gap.** "The manner" is which arm is used, the side it is extended beyond, and the direction it points. The exception turns on that same posture. `sig.hand_signal` carries only the *meaning* of a signal. Meaning "right" is the same for the left arm extended upward and the right arm extended horizontally, so neither the duty's manner nor its exception can be decided. I filed an `atom` gap (`sig.hand_signal_posture`) on s3 and on s5, and did not treat the manner as a residue: the manner is what this section regulates, and dropping it would weaken the duty.

**Reversal signal.** I would revise this if the operator rules that the decoded meaning is enough evidence of the statutory manner. In that case s3/s5 map to `sig.hand_signal` alone and the node is coded.

## NRS_484B_777_1_o1 — ride as near to the right side of the roadway as practicable

The line has two obligation spans: "ride as near to the right side…" (o1) and "exercising due care when passing…" (o2). Each node segments the whole line.

**The duty.**
- "as practicable" (s9) is operationalized as the gap between the rider's body and a mapped road edge on its right. The edge must lie on a highway that the occupied roadway lies on. The gap is computed as `prim.region_lateral_offset` minus half of `kin.extent` width, and must be at most `p.bicycle_keep_right_gap` (proposed; AASHTO shy distance).
- Where no right-side edge is mapped, the verdict is unknown, not violated.

**Exception (a): lawful speed, commensurate with nearby traffic.** Its referring span is s3 ("a lawful rate of speed").
- Lawfulness is a composition `as: compliance` with `NRS_484B_785_1a`, the scooter speed line planned in this batch. For a bicycle or electric bicycle that rule is not engaged, so it counts as complied with.
- "commensurate with the speed of" (s4) is a standard. Every traffic-aggregate road user within `p.nearby_traffic_reach` may be faster than the subject by at most `p.commensurate_speed_margin`.
- "any nearby traffic" (s4b) is read in every direction, and holds vacuously when no traffic is nearby. So a lone rider is excused, which matches the exception's purpose of not holding traffic back.
- Reversal signal: a label that judges a lone mid-lane rider as violating.

**Exception (b): preparing to turn left.** This is the declared intention `int.left_turn`. The words name no place, so the intention is read at every kind of region where a left turn off a roadway is made: intersections and driveway/alley entrances.

**Exception (c): not safe.** The standard s7, the subsection-2 preamble s12 and the narrow-lane standard s14 are bounded by two conditions:
- **Something impedes the right side (s13):** an obstruction ahead on the rider's right within `p.right_side_impede_reach` (measured along the roadway's direction), or a vehicle, bicycle or pedestrian (admitted aggregates) ahead on its right within that reach. Animals and surface hazards are `st.obstruction`.
- **Lane too narrow (s14):** the occupied lane is narrower than `p.shared_lane_min_width` (14 ft wide-outside-lane guidance).

The catch-all "include, without limitation" is disclosed as read only through these contracts. That reading excludes electric bicycles and electric scooters, which the vehicle and bicycle definitions leave out.

**Span cut.** "shall, except:" is kept inside the condition span s2 ("upon a roadway shall, except:"), following the index precedent ("the driver or operator shall:"), so that no words that require anything are labelled boilerplate.

## NRS_484B_777_1_o2 — due care when passing a standing vehicle or one proceeding the same way (surrogate)

**The duty.** "exercising due care" is the whole obligation and a state-of-mind standard, so this node is a **surrogate**. It is bounded by the clearance kept while side by side during a pass recognized by `drv.interaction.overtake_pass`:
- There must be no contact.
- The lateral body gap must be at least `p.door_swing_reach` when the passed vehicle is at rest, and at least `p.bicycle_pass_safe_gap` when it is moving. The bound is selected at each side-by-side observation.

**Standing.** "standing" (DEF-NRS-484A-250, not an aggregate) is read as the vehicle at rest (`drv.motion.complete_halt`). The definition's exclusion of a halt to receive or discharge passengers turns on purpose, so it is disclosed as an `observable_reading` of category `purpose`.

**Exceptions do not apply.** I read the exceptions (a)–(c) as qualifying only the keep-right duty, so they are `sibling` spans here. Exception (c) speaks of "doing so", subsection 2 defines it entirely in keep-right terms, and a left-turn preparation cannot excuse care in passing. Reversal signal: a label that exempts a careless pass because the rider was preparing a left turn.

**When "upon a roadway" is read.** The validator rejected an `occasion` record because the obligation span maps to no act concept. The pass is therefore the trigger, recognized where the concept rises. "upon a roadway" is read at some observation since the pass began, as branch_3/branch_4 show.

**Known limit.** `overtake_pass` recognizes a pass only when the two headings were aligned as it began. A standing vehicle parked facing the other way is therefore not read as passed (see the operator section).

## NRS_484B_777_3 — not more than two abreast

The obligation forbids the moving subject from being in a row with two other moving riders of the bicycle, electric bicycle or electric scooter aggregates:
- every pair overlaps longitudinally;
- headings are aligned (`p.side_by_side_same_direction_cos`);
- at least two of the three pairs are within `p.abreast_gap_max` (proposed: group-riding spacing), so that riders lanes apart are not counted as abreast.

The exception (s4) is the subject's footprint on `st.bicycle_lane_or_path`. The three device words in s4 name whom the facility is reserved for, which is the kind's own contract, so they claim no aggregate. The permit scenario has the rider alone, which shows the duty binds the subject alone. Reversal signal: a label that counts a third rider in an adjacent lane at 2 m as abreast.

## NRS_484B_785_1a — electric scooter at most 15 mph on roadway, bicycle lane, path or route

**The duty.** The permission "may be operated … at a speed of not more than 15 miles per hour" is read as its limit, using the literal 15 mph against `kin.speed`.

**Places.** Roadway is `st.roadway`. Bicycle lane and path are `st.bicycle_lane_or_path`. A "route" runs on those, so it adds no place.

**"Except as otherwise provided" (s1).** The bracketed ordinance (DEF-LVMC-11-40-185-A) says where scooters may be operated and states no speed, so nothing in it provides otherwise on this bound. s1 is therefore a residue of scope `none`. Reversal signal: a posted ordinance text that sets a different scooter speed.

**"may be operated:" (s3).** This is also scope `none`, because a scooter at rest meets the bound anyway.

**Admitted bicycle aggregate.** The table lists `bicycle` for this law, but the word appears only inside "bicycle lane", the name of a structure kind, so no `ru.aggregate` for bicycle is claimed.

## NRS_484B_913 — driving over a fire hose (two gaps)

**How the words are carried.**
- Driving over the hose is the moving vehicle's footprint overlapping (`rel.occupies`) an `st.obstruction` of kind hose.
- "of a fire department" and "for use at any fire…" are `observable_reading`s, of categories `status` and `purpose`, carried by the hose laid on the way.
- "on any highway or private way or place" names every place, so it is a residue of scope `none`.

**Gaps.**
- "unprotected" distinguishes a bare hose from one under a hose bridge or ramp. No atom carries that, so I filed an `atom` gap (`st.protected_hose`).
- "the consent of the fire department official in command" has no carrier. `dev.human_direction`'s roles do not include a fire official, so I filed an `atom` gap (`dev.fire_official_direction`).

**Reversal signal.** I would revise this if the operator adds a protection attribute to `st.obstruction`, or a fire-official role to `dev.human_direction`.

## NRS_484D_100_1 — when lighted lamps are required (gap G21)

**How the words are carried.**
- Highway is `st.highway` with `rel.occupies`. "of this State" is a residue of scope `none`, because the corpus is applied in its own jurisdiction.
- The display duty is headlamps lit plus position lamps lit, reusing the index mapping of "lights … shall be burning".
- "as respectively required in this chapter for different classes" is a residue. The per-class equipment sections are not corpus lines, and no atom carries a lamp's specification.
- (a) is `env.darkness`; the sunset boundary is the reading parameter, and the law's figure is a literal.
- (b) is `env.darkness` or `env.visibility` below the literal 1,000 ft, as the index maps these words.

**Parked-vehicle exceptions (s4).** The reference to "exceptions with respect to parked vehicles as stated in chapters 484A to 484E" is composed `as: exception` with `NRS_484D_165_3`. That is the corpus line stating when a parked or stopped vehicle displays lamps, and this subsection yields to it. Reversal signal: a further corpus line on parked-vehicle lamps (e.g. 484D.165(2)), which would be added as a second exception composition.

**Gap (c).** "When directed by an official traffic control device" has no device atom. The open gap smoke31-1111-0039:G21 (`dev.lamps_on_sign`) is carried again on these words, so the law stays blocked until it is decided.

## NRS_484D_165_3 — lamps on a parked or stopped vehicle

**Trigger and place.** The trigger is the vehicle at rest (`drv.motion.complete_halt`, as indexed for "stopped or parked"). It must be on the roadway (the "traveled portion") or on a shoulder of the same highway.

**"the times mentioned in NRS 484D.100" (t4/t5).** The referring span t4 carries the borrowed periods (a) and (b) as `env.darkness` or `env.visibility` below 1,000 ft. t5 is a `definition` reference to NRS-484D-100-1.
- It is not a rule composition. 100-1 itself excepts parked vehicles by composing this node, so a composition would form a cycle, and it would read that line's exception, not its times.
- 100-1's third circumstance (a device directing lamps on) is not borrowed. The conjoined condition t6 (insufficient light to reveal within 1,000 ft) entails period (b), so the times hold wherever t6 holds. The G21 gap therefore does not reach this node.

**The lamps.** The obligation is `sig.position_lamp` lit, the parking and tail lamps. Their description is borrowed by the reference t8 from the appended subsection 1. The lamps' colour, 500-ft reach and location (t9, t10) are residues, because no atom carries lamp fitment.

**Reversal signal.** A labelled parked vehicle at night under street lighting whose label is `not_applicable`. That would show that `env.darkness` (natural light only) applies this duty more widely than "insufficient light" does.

## NRS_484D_165_4 — headlamps on a parked vehicle depressed or dimmed

The trigger is a parked vehicle (`drv.motion.parked` with `p.parking_min_duration`, as indexed for "parked") with headlamps lit. The obligation is `sig.headlamp` = `low_beam`, reusing the index mapping of "such lights shall be depressed or dimmed" from NRS_484B_473_2. A short halt in traffic is not parked (branch_1). Reversal signal: a label that treats a twenty-second halt with high beams as violating, which would call for `drv.motion.complete_halt` instead.

## For the operator

- **Gaps filed:**
  - `sig.hand_signal_posture`, on NRS_484B_769 s3 and s5.
  - `st.protected_hose` and `dev.fire_official_direction`, on NRS_484B_913.
  - `dev.lamps_on_sign`, on NRS_484D_100_1 s10. This re-carries the pending gap smoke31-1111-0039:G21.
- **Pass of an opposite-facing standing vehicle.** `drv.interaction.overtake_pass` requires aligned headings at the start of the pass, so NRS_484B_777_1_o2 does not recognize a pass of a standing vehicle parked facing the other way. A concept for passing a standing object whatever its heading would close this. I did not propose one here because the validator rejects narrowing a trigger.
- **Natural darkness only.** `env.darkness` is insufficient *natural* light. NRS_484D_165_3 and NRS_484D_100_1 speak of insufficient light, which street lighting can supply, so both apply wherever it is naturally dark. An atom for illumination at a place would decide this.
- **New parameters proposed:** `p.bicycle_keep_right_gap`, `p.nearby_traffic_reach`, `p.commensurate_speed_margin`, `p.right_side_impede_reach`, `p.shared_lane_min_width` and `p.abreast_gap_max`.
  - In particular, `p.shared_lane_min_width` (14 ft) makes most urban lanes "too narrow", which excuses keep-right in them. This follows the shared-lane guidance, but it largely decides the reach of NRS_484B_777_1_o1.
