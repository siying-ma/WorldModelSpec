# Plan — batch 04

Five laws, six nodes, one new concept (`drv.motion.stopping_distance`), one gap (NRS-484D-100-1 (c)). No law-local aggregates: `aggregates.jsonl` is empty. The validator accepts every node and the concept.

## Concept `drv.motion.stopping_distance` (quantity)

This is the distance a road user would cover before it halts: its speed times a reaction time, plus its speed squared over twice a deceleration. The magnitude is the road user's own and does not depend on the law. The bound it is compared with belongs to each rule's operationalization. Grade and surface are left to the caller, through the deceleration the caller passes in. It is used by NRS_484B_600_1a and NRS_484D_215_1_o1. Reversal signal: the reviewer finds that a reaction-time model bundles a standard into the concept. In that case the two terms would move inline into the rules.

## NRS_484B_560_7a

**One node, subject x, a vehicle (the admitted aggregate).**
- **Crossing.** The trigger "when crossing at grade" means x's footprint overlaps a railway crossing. It also covers the stretch after x has occupied the crossing during which its body has stayed less than the law's literal of 15 ft from it: `since(distance < 15 ft, occupies)`. That literal comes from the law's own definition of "completely cross", which is cut as a definitional span.
- **"Without stopping".** This is read with DEF-NRS-484A-260, the definition the table applies, through `drv.motion.stopped`. The halting is the same physical notion as in the concept's own definition. The exceptions of 484A.260 are carried beside the concept:
  - avoiding a conflict, through the closest-approach primitives;
  - a police officer's stop direction.
- **Device-direction exception: not read (disclosed).** A device directs a halt at the place it marks, never on the tracks. Reading it would excuse exactly the queue-from-a-signal case the law targets.
- **Cause (1): insufficient space.** "Due to insufficient space" is a purpose. It is read through the conduct it explains: x halts behind a road user directly ahead, within the queue standstill gap (`observable_reading`, purpose).
- **Cause (2): undercarriage clearance.** No atom carries this. It is the declared assumption `asm.undercarriage_grounded`, so a halt on the tracks with nobody ahead and nothing declared is unknown.
- **"Nearest rail".** This is read as the rail nearest the trailing end once the vehicle is across. Otherwise a vehicle sitting on a second track would count as "completely crossed".
- **Reversal signals:**
  - an operator ruling that "nearest rail" means the approach-side rail;
  - a label treating a halt behind a queue at a signal as excused.

## NRS_484B_600_1a

**One node, a surrogate: the standard is the whole duty.** Applicability is "x is being driven", read through `drv.motion.moving` (agency). The bound reads each named factor by its degree:
- **Surface** selects the deceleration: ice or snow, else wet or precipitating, else dry.
- **Sight and visibility:** the stopping distance must lie within the sight distance at x's place and within the visibility distance.
- **Traffic:** time headway to each road user ahead in x's lane.
- **Curvature:** lateral acceleration in a bend must stay within the surface's acceleration.
- **Width:** a time-to-line-crossing margin on the width of the lane x occupies.

**Disclosed narrowings:**
- traffic outside x's lane is not read;
- width is the lane's width, not the highway's;
- weather is read only through visibility and precipitation;
- the catch-all "other highway conditions" is read only through sight distance and curvature.

**Traffic aggregate.** The validator does not accept `ru.aggregate=…::traffic` inside an operationalization. Traffic is therefore read as every road user ahead in the lane, all of which fall within DEF-NRS-484A-285's "using any highway for purposes of travel".

**Reversal signal:** label disagreement concentrated on one factor. That would point to that factor's parameter, not the structure.

## NRS_484B_769

**One node, subject x, any of three aggregates:** bicycle, electric bicycle, electric scooter.
- **Applicability:** x occupies a roadway.
- **Obligation:** every turn signal x gives by lamp (`sig.turn_indicator`) is also given by arm with the same meaning (`sig.hand_signal`).
- **The manner of 484B.420 and the right-arm exception.** Both are postures of one meaning, and the source reads that meaning into `sig.hand_signal`. So both satisfy the duty, and the exception is carried by the same atom.
- **Brake lamps are not read** (disclosed narrowing). A brake lamp is an actuation of the brake, not a signal the rider chooses.
- **Scope.** Whether a signal is owed at all belongs to the signalling rules, not to this one. A rider who gives no signal is compliant here.
- **Reversal signal:** a label counting an automatic brake lamp as a lamp signal.

## NRS_484D_100_1

**One node, subject x, a vehicle on a highway.** The duty applies when any of the three listed times holds, and requires lit headlamps (low or high beam) and position lamps.
- **(a) Darkness.** `env.darkness`, whose sunset/sunrise boundary is the reading's parameter, set at the law's literal of one-half hour.
- **(b) Visibility.** `env.visibility` below the literal of 1,000 ft. The words' test is discernibility at that distance, whatever its cause.
- **(c) Device direction: atom gap.** No code of `dev.regulatory_sign` and no kind of `dev.zone_sign` directs road users to display lamps. The proposed new atom is `dev.lamp_use_sign`, mapped to the nearest atoms meanwhile.
- **Parked-vehicle exception.** The exceptions are "stated in chapters 484A to 484E" without naming a section, so no rule can be composed. "Parked" is read through conduct as halted with the engine off (`observable_reading`, purpose). The rule judges only vehicles that are not parked.
- **Per-class lamp lists.** "As respectively required … for different classes" is read as headlamps plus position lamps (disclosed).
- **Reversal signals:**
  - a corpus node for the parked-vehicle lamp provisions, which would then be composed as an exception;
  - the operator admitting a lamp-direction device.

## NRS_484D_215_1_o1 and NRS_484D_215_1_o2

**Two obligations, so two nodes.**
- **Shared frame.** Both read the opening frame:
  - a motor vehicle being operated, meaning moving or with its engine running (agency);
  - on the roadway, or the shoulder, of a highway;
  - during the times of NRS 484D.100, composed with `NRS_484D_100_1` as a condition, mapping x to x.

  The second node reads this frame because its words are a limitation of the first duty ("subject to the following requirements and limitations"). Without the frame it would demand low beams in daylight.
- **o1 (the upper-beam duty).** "Subject to the following…" is the composition `NRS_484D_215_1_o2` as an exception. While the dimming duty applies, o1 does not. The standard "high enough … to reveal … at a safe distance" is operationalized, not a surrogate, because the duty to use a beam is concrete. It is met by the high beam, or by the low beam when x's stopping distance lies within the low beam's seeing distance. Headlamps off violate it.
- **o2 (the dimming duty).** Its trigger is an oncoming vehicle (`rel.oncoming`, headings opposed and closing) within the literal of 500 ft (`rel.surface_gap`). Its obligation is the low beam. That is the lowermost beam the law deems to avoid glare: a definition reference to DEF-NRS-484D-210-1-2. The high beam is read as projecting glare, and lamps off are no beam at all.
- **Reversal signal:** a label that accepts headlamps off while meeting an oncoming vehicle at night. That would mean "use a distribution of light" is not read as requiring a lit beam.

## For the operator

- **Two definition texts were missing from the prompt.** The bracketed sources DEF-NRS-484B-420 (cited by NRS-484B-769) and DEF-NRS-484D-210-1-2 (cited by NRS-484D-215-1) were not among the injected definition texts. The `definition` references quote "extended horizontally" and "lowermost distribution of light". These are the phrases those sections use as I know them, and the validator accepted them, but please check them against the corpus text.
- **Gap `dev.lamp_use_sign`** (NRS-484D-100-1, clause (c)). This blocks that law, and therefore both NRS-484D-215-1 nodes, which compose it, until it is decided.
- **Earlier-batch parameters re-proposed.** The validator's catalogue did not yet contain the parameters proposed by earlier batches: `p.motion_speed_tolerance`, `p.queue_standstill_gap`, `p.conflict_time_horizon`, `p.conflict_centre_clearance`. They are proposed again here with the same values and units.
- **New parameters awaiting review:**
  - `p.perception_reaction_time`
  - `p.surface_friction_accel_dry`, `_wet`, `_ice_or_snow`
  - `p.following_min_time_headway`
  - `p.lane_keeping_margin_per_speed`
  - `p.low_beam_seeing_distance`
  - `p.oncoming_cos_tolerance`

  The low-beam seeing distance and the reaction time decide how often low beams on lit urban streets are flagged by NRS_484D_215_1_o1.
- **"Stopping" in NRS-484B-560-7a.** Its definition is DEF-NRS-484A-260. It reuses `drv.motion.stopped`, whose contract quotes DEF-NRS-484A-255; the halt is the same physical notion, and 260's exceptions are carried by the rule. If the operator wants one concept per definition, a qualified record would be needed.
