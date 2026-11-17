# Plan — batch 25 (iteration 001)

Eight law lines, nine nodes. No law-local aggregate (`aggregates.jsonl` is empty). No new concept record. The plan reuses `drv.motion.complete_halt` and `drv.lane.entering_adjacent_lane` from earlier batches. No gap is carried.

## NRS_484B_560_3_o1 — keep as far right when a stop is required at a railroad crossing
- **Decision.** The line has two obligations, so it becomes two nodes. In this node the second obligation and its "unless … four or more lanes" exception are `sibling`.
- **Trigger ("When stopping is required").** The requirement to stop is read from the devices that require a halt of the subject's traffic. Each must govern a travel region the subject occupies. They are:
  - a railway signal with its lights flashing, or its gate lowering or down;
  - a stop sign;
  - a traffic signal showing circular red;
  - a police officer or railroad flagger directing stop.
- **"At a railroad crossing".** The subject's body is within the new parameter `p.railroad_crossing_approach_reach` of a `st.railway_crossing`.
- **The standard "as far to the right … as possible".** It is bounded by a road edge on the subject's right (negative lateral offset), on the way the subject occupies, within `p.pullover_edge_gap`. That parameter was proposed earlier this iteration by NRS_484B_267_1b_o1 and is proposed again here with the same value.
- **Subject.** "The driver" claims `DEF-NRS-484A-320::vehicle`, through the driver definition "drives … a vehicle". The run's index maps "the driver" the same way.
- **What would reverse this.** A label that judges vehicles of the subsection 1 classes at crossings that have no device; see "For the operator" below.

## NRS_484B_560_3_o2 — do not form two lanes of traffic
- **Trigger and condition.** Same as o1.
- **Obligation.** No other member of the traffic aggregate stands or moves side by side with the subject, at the same crossing. "Side by side" means:
  - it occupies a lane;
  - it heads the same direction (`p.side_by_side_same_direction_cos`, newly proposed);
  - the two bodies' longitudinal overlap is positive.
- **Why the other road user must occupy a lane.** This leaves out a pedestrian on a sidewalk, who forms no lane of traffic.
- **Exception.** "Marked for four or more lanes" holds where four pairwise distinct lanes lie on the highway the subject occupies. The four is a literal.
- **Who formed the second line.** Both road users of the pair are held to have formed it; arrival order is not told apart.
- **What would reverse this.** A label that blames only the vehicle that pulled alongside. That would need an arrival-order reading.

## NRS_484B_560_7a — completely cross without stopping
- **Applicability.** A `since` over the traversal: the body has been within the literal 15 ft of the crossing at every observation since its footprint last overlapped the crossing.
- **Obligation.** `drv.motion.complete_halt` does not hold.
- **Where the definition's distance comes in.** Subsection (8)'s definition of "completely cross" is carried as an element on its own definitional span, with the 15 ft literal. Its reading (crossing outline as the nearest rail, body outline as the trailing end) is disclosed on the obligation span.
- **"Due to insufficient space / undercarriage clearance".** This is read as an `observable_reading` of category `purpose`, through the halt those causes explain.
- **What would reverse this.** A label that excuses a halt on the tracks for some other cause, such as a flagger's direction. The cause words would then need an observable carrier (a vehicle ahead, a crest), or a gap.

## NRS_484B_560_7b — obey devices and police at a railroad crossing
- **When it is judged.** At the subject's entry into a railroad crossing.
- **Obligation.** Every device governing a region the subject occupies at that entry is obeyed:
  - **railway lights and gate:** not flashing, gate not lowering, down or raising;
  - **traffic signal:** not circular red;
  - **police stop:** no entry;
  - **yield sign:** no rail vehicle in conflict within `p.conflict_horizon` and `p.conflict_centre_clearance`;
  - **stop sign:** a halt before the entry.
- **The stop-sign search (rule 4c).** It runs back to the approach start (the subject leaving `p.railroad_crossing_approach_reach`) or to the previous entry. A `history_boundary` scenario is planned.
- **Not read.** Instructions that do not bear on entering the crossing, and directions to proceed. This is disclosed on the obligation span.
- **What would reverse this.** A labelled violation that turns on another instruction, such as a do-not-enter sign at the crossing.

## NRS_484B_587_1 — enter or leave a controlled-access highway only at indicated entrances and exits
- **The notice condition.** Read from the presence of an entrance- or exit-coded `dev.regulatory_sign`.
- **Why these words map differently from NRS_484B_493.** The run's index maps the same words, for NRS_484B_493, to curb zones. Here they mean notice of controlled access, not of a parking restriction, so they are mapped to the sign alone (rule 7).
- **Entry.** The subject's footprint comes to overlap the controlled-access region while it occupies a travel region governed by an entrance-coded sign.
- **Departure.** At the observation before the departure, the subject occupied the highway and a travel region governed by an exit-coded sign. This is written as `rises(not X)`.
- **What would reverse this.** Sources that mark ramps without signs. "Indicated" would then need a lane-role atom.

## NRS_484B_587_2a — stay within marked lanes on a controlled-access highway
- **Obligation.** While moving on the controlled-access highway, the subject overlaps:
  - no median or divider;
  - no shoulder other than an authorized one;
  - and it overlaps some lane, unless every non-lane region it overlaps is an authorized shoulder.
- **"Required by an emergency".** Read through the conduct that shows it: hazard lamps, or an emergency vehicle with a lit warning lamp (`purpose` reading).
- **Why this departs from the index.** The index maps "in an emergency" to the emergency-vehicle class plus hazard lamps. Here the warning lamp is added, because the class alone "is not responding".
- **Subsection 3 and the 484B.210(4) list.**
  - The vehicles are mapped as the index maps them in NRS_484B_210_1: authorized emergency vehicle aggregate, official vehicle (incident-management and coroner kinds), tow-car aggregate, and bus aggregate together with `ru.transit_bus`.
  - The permission is a paved shoulder governed by a `shoulder_use_permitted` sign whose conditions hold.
  - The reference to the list is a `definition` composition; it composes no rule.
  - The list's introductory sentence about 484B.210(1)(c)(1) is a residue.
- **What would reverse this.** A source that maps gore areas, which would need a kind of their own.

## NRS_484B_587_2b — do not cross a solid white line between entrance/exit lanes and traffic lanes
- **Obligation.** `drv.lane.entering_adjacent_lane` from lane r1 into r2, across a solid or double-solid white marking on that side of r1, is forbidden where one of the two lanes is governed by an entrance- or exit-coded sign and the other is not.
- **How entrance and exit lanes are identified.** By the sign that indicates them (`status` reading).
- **Exceptions.** Carried exactly as in 2a, for consistent mapping of the shared words.
- **What would reverse this.** A lane-role attribute on `st.controlled_access`, which would replace the sign reading.

## NRS_484B_600_1c — the posted speed
- **Applicability and obligation.** For every speed limit sign governing a region the subject occupies, of kind maximum, structure maximum or zone, `kin.speed` is not above the sign's value. No parameter is needed.
- **Mapping.** "Drive or operate" and "a vehicle of any kind or character" reuse the index mappings. "Posted by a public authority" is a `status` reading.

## NRS_484B_600_1e — 80 mph
- **Obligation.** `kin.speed` is not above the literal 80 mph.
- **"In any event".** A residue of scope none: it adds no condition.

## For the operator
- **NRS-484B-560-3, "When stopping is required".** This is read only through devices that require a halt. NRS 484B.560(1) requires certain classes of vehicle to stop at every crossing, but its text is not in this line and no node for it is in the library. Such a vehicle at a crossing with no device is therefore not judged by these two nodes. A trigger narrowing is not accepted, so this is recorded here rather than in the record. If 484B.560(1) enters the corpus, the trigger should also compose it, `as: condition`.
- **The emergency exception in 2a/2b.** The open gap smoke31-1111-0039:G20 (`env.emergency`) concerns the same notion. Once that gap is decided, the hazard-lamp/warning-lamp reading of "required by an emergency" should be revisited.
