# Plan — batch 26 (iteration 1)

There are 9 nodes across 8 laws. No concept records were proposed: the only concept used is `drv.motion.complete_halt`, which an earlier batch proposed. There are no law-local aggregates (`aggregates.jsonl` is empty). The validator accepts every node. `NRS_484B_627_1c` carries an atom gap.

## NRS_484B_603_1_o1 — decrease speed under listed conditions (surrogate)

**Decision.** The line has two obligation spans, so it gives two nodes:
- `o1` covers "does not relieve … from the duty to decrease speed when …".
- `o2` covers "and speed must be decreased as may be necessary …".

`o1` applies when any listed condition holds. The conditions read as follows:
- **Intersection.** The subject occupies an intersection, or a carrier that `st.lane_enters` one. This reuses the index mapping of "approaching an intersection".
- **Curve.** The roadway curvature is clear of `p.curvature_resolution` at the subject's place, or within a `.path` window ahead of `p.curve_approach_reach` (new parameter).
- **Hill crest.** A crest lies ahead of the subject's velocity within `p.crest_near_reach`. This reuses the mapping of the 213-2a crest.
- **Narrow or winding highway.** Lane width is at or below `p.narrow_lane_width` (new parameter), or curvature is clear of resolution.
- **Pedestrians or other traffic.** A pedestrian aggregate is on a roadway, or a traffic road user is in predicted conflict.
- **Weather.** Precipitation, a wet road, ice or snow, or visibility below the sight distance.
- **Other highway conditions.** This is the catch-all of the "special hazards" standard. It is read through obstructions within the stopping distance and through temporary traffic control, and a narrowing discloses that.

The duty to "decrease speed" is a standard with no stated amount, so I marked the node **surrogate**. The bound is the AASHTO stopping-sight model: the stopping distance must fit within the sight distance and the visibility at the subject's surface deceleration. On a bend there is also a lateral-acceleration bound, and toward a road user in conflict the stopping distance must fit within the surface gap. Each factor enters the bound by its degree.

The clause "speed lower than the prescribed limits" adds no restriction. It is carried as a residue of scope `none`.

**Reversal signal.** A label set that judges "decrease speed" as an observed deceleration on every approach, rather than as reaching an adequate speed, would reverse the reading on `s4`.

## NRS_484B_603_1_o2 — decrease speed as necessary to avoid colliding (surrogate)

**Decision.** For every other road user on or entering a highway that is in predicted conflict (`p.conflict_horizon`, `p.conflict_centre_clearance`), the subject must do one of the following:
- be at rest;
- be decelerating by at least `p.speed_decrease_decel_min`;
- have a stopping distance within the surface gap. This is the due-care bound.

Contact while moving is a violation. "Any person, vehicle or other conveyance" covers every road user, so the rule quantifies over all of them, and the vehicle aggregate is claimed only for its word. I read "in compliance with legal requirements" as qualifying the speed decrease, carried through the due-care bound, and disclosed it as a narrowing on that standard span.

**Reversal signal.** The words could instead mean "a person lawfully entering". A corpus reading that restricts the parties that way would turn the clause into a lawfulness composition.

## NRS_484B_620_2 — speed in a speed zone

**Decision.** The rule applies to a motor vehicle in a travel region on a highway that is governed by a `dev.zone_sign` of kind speed_zone and a speed limit sign of kind zone or maximum. The speed must not exceed that sign's value. The establishment of the zone is read from the signs (an observable reading of category status).

"Upon the road" uses DEF-NRS-484A-215, under which a road lies outside the territorial limits of a city. That legal region class is carried by `asm.within_incorporated_city`, reused and declared false. I reused it rather than minting its complement.

**Reversal signal.** If the operator decides "road" here means any highway, the assumption should be dropped.

## NRS_484B_627_1a, _1b, _1c — slow vehicle impeding traffic

**Shared trigger.** "So slow as to impede" is a standard. It is operationalized as conduct sustained over `p.left_lane_move_over_time` (the time to move over). Over that window:
- the subject moves at least `p.impeding_speed_margin` (new parameter, about 10 mph) below the posted maximum governing its region;
- a traffic road user is behind it in the same lane within `p.rear_signal_reach`;
- no road user is ahead of it within that reach, so the subject is not itself queued.

Where no maximum sign governs the subject's region, the reference speed is unobserved and the result is unknown. A narrowing on `u3` discloses this.

- **1a.** The condition is one lane in the subject's direction plus an opposed-direction lane on the same highway that also has a count of one, using `p.lane_opposed_direction_cos`. "The width of the paved portion permits" is a standard: the paved half-width, from the centre line to the right edge, must be at least the vehicle's width plus `p.free_passage_width`. The obligation is that the right side of the body is within `p.pullover_edge_gap` of the right roadway edge. "Comply with NRS 484B.630" is a residue because NRS 484B.630 has no node in the library.
- **1b.** The condition is a lane count of at least two (a literal) in the subject's direction. The obligation is to occupy the lane whose ordinal equals the count. The exception covers passing a slower vehicle on the right that is either side by side with the subject or ahead and closing within `p.overtake_window`.
- **1c.** "Use alternate routes whenever possible" depends on whether another route exists, and no atom carries that. The node carries an **atom gap** (`st.alternate_route`), mapped to its nearest atoms `rel.occupies` and `st.controlled_access`. The law stays blocked until the gap is decided.

**Reversal signal.** The labels might call a vehicle impeding where no posted limit governs it. In that case the reference speed should come from the traffic behind instead.

## NRS_484B_627_2 — complete stop on a roadway impeding traffic

**Decision.** The subject is a vehicle on a roadway. It violates the rule when it is at rest (`drv.motion.complete_halt`) while a traffic road user behind it in its lane, within `p.rear_signal_reach`, is halted or decelerating. Two exceptions apply:
- **"Necessary for safe operation"** is a standard. It holds when the subject is queued behind a road user within `p.queue_halt_gap`, or a road user is in predicted conflict.
- **"In compliance with law"** holds when a control requiring a halt governs the subject's region: a stop sign, a yield sign, a red signal, a person directing traffic to stop, or a railway signal or gate.

For "in compliance with law" I extended the index mapping of NRS_484B_450_1a (stop sign and signal only) with the other halt-requiring controls that NRS_484B_477_1a's mapping reads. The words call for every legal requirement, and the validator does not allow a narrowing on an exception span.

The term "stop" is marked ambiguous between DEF-NRS-484A-255 and DEF-NRS-484A-260. I did not choose between them. Both denote the halt `drv.motion.complete_halt` reads, and DEF-260's own exceptions ("to avoid conflict with other traffic", "directions of a police officer or official traffic-control device") fall within this node's two exceptions.

**Reversal signal.** If gap G22 (an operator for "in compliance with law") is accepted, `x8` should be re-planned through it.

## NRS_484B_633_2 — speed over a signposted bridge or elevated structure

**Decision.** The subject is a vehicle on an `st.elevated_structure` lying on a highway. When a `dev.speed_limit_sign` of kind structure_maximum governs the travel region it occupies there, its speed must not exceed the sign's value. "Maximum speed … with safety to the bridge" is the authority's declared value, not a driver's judgement, so it is not a standard. The appended subsection (3) is carried as follows:
- The investigation, the finding and the declaration are residues: the rule reads the posted sign as their evidence (status reading on `y4`).
- "Suitable signs stating such maximum speed" maps to the sign and its value.
- The placement 100 feet before each end is a residue, because the rule reads the sign's governance, not its position.

**Reversal signal.** A label that excuses a vehicle because the sign is misplaced would require reading `dev.position` against the structure.

## NRS_484B_653_1a — reckless driving (surrogate)

**Decision.** "Willful or wanton disregard" is a state of mind, so the node is **surrogate**. It is read through conduct: a speed of at least `p.exhibition_speed_min`, or acceleration of at least `p.exhibition_accel_min` into a predicted conflict with another road user. "On a highway" reuses the index mapping. "Premises to which the public has access" is a legal region class that the ontology names explicitly. It is carried by a new assumption, `asm.public_access_premises`.

**Reversal signal.** Labels that call collisions or near-misses at ordinary speed reckless would add a conflict branch that does not depend on acceleration.

## For the operator

- **New parameters** (proposed, awaiting review): `p.narrow_lane_width` (3.0 m), `p.curve_approach_reach` (150 m), `p.impeding_speed_margin` (4.5 m/s). Every other parameter repeats an earlier batch's proposal with the same value and convention.
- **Atom gap `st.alternate_route`** (NRS-484B-627-1c): whether an alternate route exists between a road user's entry to and exit from a controlled-access highway. Without it the duty to "use alternate routes whenever possible" cannot be judged.
- **"In compliance with law"** (NRS_484B_627_2 `x8`) is carried by halt-requiring controls. A halt that another law requires and no control displays (for example, yielding to a school bus or to an emergency vehicle) is not covered. The pending operator gap G22 would carry it in full.
- **NRS 484B.630**, which NRS-484B-627-1a refers to, has no node in the library, so that reference is a residue. If it is added to the corpus, 627-1a should compose it (`as: compliance`).
