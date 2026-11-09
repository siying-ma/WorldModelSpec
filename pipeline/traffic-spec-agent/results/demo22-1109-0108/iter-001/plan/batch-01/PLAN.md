# Plan — batch 01, iteration 001

Nine nodes over eight law lines, and ten concept records. `aggregates.jsonl` is empty: none of these
lines defines, adds or excludes a member of its own, so every defined road-user word is claimed with
the aggregate id the definitions table admits, and no law-local aggregate exists. No gap is proposed:
every span of these eight lines grounds in the closed set, in a posted-definition concept, or in one
of the readings the ontology's section on what is not an atom states.

## `NRS_484A_450_2` — the halt at a stop-sign approach

The line is the paradigm of the ontology's "act due at a place before an event", so I planned it that
way rather than with a window of my own: the duty is a search back from the entry into the junction
for a standstill at the place the words name, the approach fixed by the map (the carrier the vehicle
occupies, `st.lane_enters`, and the mark recorded as marking that carrier, `st.entrance_of`) and never
by the vehicle's motion, distance or heading. The three places are read in the order the words give
them — the near-side crossing, then the clearly marked stop line, then the point with a view — and the
cascade falls through only where the source's complete record of a mark's entrances excludes the
carrier; where a mark's association is merely unobserved, the duty is unknown rather than read from
the next place. "Stop" has two posted definitions and the table marks it ambiguous, but I chose
between nothing: each definition states its own scope, and these words require a stop, so
`DEF-NRS-484A-255` applies by its own terms and `DEF-NRS-484A-260`, which speaks to a stop that is
prohibited, does not. I cut "where the driver has a view of approaching traffic on the intersecting
highway" as a `standard` span because the words leave the adequacy of the view open: the sight model
bounds it with one parameter, and the perception word is read through the sight atoms the ontology
names for exactly this. Reversal signal: if a labelled recording shows the duty read as unknown
wherever the crossing's entrances are merely unobserved while the label decides it from the stop line,
the cascade's fall-through condition is what changed, and only its reading in `obligation` moves.

## `NRS_484B_113_2` — backing into an intersection, a crosswalk, a corner

One obligation span, three places, so one node: the words forbid one act with three objects, and
splitting them into nodes would invent obligations the line does not state. Backing is read from
kinematics, as the ontology directs for exactly this word (`kin.gear` is excluded by its own
contract), and "back into an intersection" is the observation at which the rearward-moving footprint
first overlaps the junction, while "on or over a crosswalk" is the overlap itself — the words differ
and so do the readings. The one hard decision was "street corner": "street" is defined, and its
definition's "inside the territorial limits of a city" is a legal region class, which §9 admits only
as a per-map assumption. I therefore cut "street" into a span of its own under `condition` and carried
it as `asm.inside_city_limits`, leaving "corner." to the element that reads the junction of two
highways and the bending of the path. Reading the words without that assumption would forbid backing
round any corner anywhere, which is wider than the statute; dropping the corner limb instead would be
narrower. Because the three limbs are a disjunction, an undeclared assumption never makes a decided
limb unknown. Reversal signal: a label that treats a rural road junction as a street corner would show
the assumption is not how the corpus reads "street", and the span would move to an element.

## `NRS_484B_127_1` — following too closely

Marked **surrogate**. "More closely than is reasonable and prudent" is the entire measure of the duty:
the law states no distance, so any bound is the reading's policy and the verdicts are evidence, not a
legal conclusion. The operationalization reads each named factor by its degree rather than as a
switch: the subject's speed scales the headway term, the followed vehicle's speed enters through the
closing speed, the surface and the geometry select among headway bounds, and the density of the stream
adds a gap. Two narrowings disclose the limits: "the condition of the highway" is read through the
five contracts the vocabulary carries and no others, and "the traffic upon the highway" through the
count of road users on the way. The followed vehicle is quantified inside the obligation and is no
binder, so a subject alone is decided compliant (`branch_1`) instead of left unjudged. Reversal
signal: if the label set distinguishes mild from severe surface conditions at one bound, the
selection among bounds is wrong and the headway parameters, not the structure, change.

## `NRS_484B_127_2` — the 500-foot space between trucks

The width qualifier is read as attaching to "combination of vehicles" and not to "truck": the comma in
"any truck or combination of vehicles 80 inches or more in overall width" places the measure on the
combination, and reading it onto trucks as well would narrow the class the subsection binds, which a
subject span may not do silently. The figure is the law's, so 80 inches and 500 feet are `literals`,
never parameters. Two spans needed judgement. "shall, whenever conditions permit," is a `standard`
span: feasibility is a judgement the words leave open, and it is operationalized with a free-flow
speed, an intervening-vehicle count and the works-zone contracts, so a queue or a vehicle that has
moved into the space is not read as the subject's failure. "so that an overtaking vehicle may enter
and occupy such space without danger," is a residue with `scope: "none"`: the law fixes the space at
500 feet and the clause states what the figure is for, so no verdict turns on it, and the rule is held
to that. Both exceptions are the line's own words, so they are elements and not compositions.
Reversal signal: a labelled case in which a truck is held to the space while crawling in a queue would
show the feasibility reading too generous, and `p.conditions_permit_min_speed` moves.

## `NRS_484B_127_3` — caravan and motorcade spacing

Not marked surrogate, and this is the decision most open to challenge: the obligation is "sufficient
space", with no figure, which reads like a standard that is the whole duty. I kept it a plain rule
because the law states the functional test itself — the space must enable another vehicle to enter and
occupy it — so the operationalization quantifies a criterion the words supply rather than choosing one
the words leave blank, and the duty has concrete content beside it (a space between each member).
"outside of a business district" is a district defined by its buildings, so it is
`asm.outside_business_district` and never an atom. "whether or not towing other vehicles," is a residue
with `scope: "none"`: it states that the duty is the same either way. A caravan has no atom and no
definition, so `drv.interaction.vehicle_file` carries it by count, direction and reach, with the
motion stated by the rule and not by the concept. Reversal signal: if the review marks the node a
surrogate, nothing in the mappings changes but the flag; if labels show two-vehicle groups treated as
caravans, `p.caravan_min_members` moves.

## `NRS_484B_220_1` — one-way highway

The designation is carried twice, as the vocabulary carries it: the posted sign (`dev.regulatory_sign`
of code `one_way`, with `dev.governs` and `prim.conditions_hold`) for "designated and signposted", and
`st.lane_direction` for the direction itself, which the obligation compares the vehicle's velocity
with through `drv.position.direction_component`. I read the direction of travel from the velocity and
not from `kin.heading`: a vehicle may point one way while moving another, and the words govern the
direction it is driven in. The tolerance names only the resolution of a mapped direction and a measured
velocity, so a standstill or a lateral drift is not a violation (`branch_1`). Reversal signal: a label
that treats a vehicle reversing along a one-way roadway as compliant would show the sign convention
wrong; the sign of the component, not the atoms, would change.

## `NRS_484B_223_1b` — lane change: signal and safety

"that lane" is the lane the words single out, so the trigger binds it with the whole selection — a
marked lane of a highway with at least two lanes in its direction, occupied by the subject — and the
obligation binds it again with that selection and passes it to `drv.lane.lane_change` as a region
argument, so no concept finds a lane of its own. "until the driver has given the appropriate turn
signal" states no duration; I bounded the look-back with `p.turn_signal_advance_window` and disclosed
it as a reading, which rule 4d permits as a justified, parameterized recognition bound: a window that
reaches past the start of the recording leaves the duty unknown, never violated, so the bound never
manufactures a breach. "Appropriate" is determinate, not a standard: the indication must match the
side `st.lane_adjacency` records for the lane entered. "ascertained that such movement can be made
with safety" is read through the outcome the duty secures, as §9 directs for a duty to ascertain, and
the operationalization bounds it with an entry clearance that grows with the faster speed and a
closest-approach test over a horizon. Reversal signal: labels that count a signal given four or five
seconds ahead would move the window parameter only.

## `NRS_484B_227_1_o1` and `_o2` — divided highway

Two obligations in one line, so two nodes, each segmenting the whole line with the other's obligation
marked `sibling`; the exception is mapped in both, since "except through an opening … or at a
crossover or intersection" excuses departures from the right-hand roadway as much as crossings of the
divider. In `_o1` I wrote the duty positively — the footprint must overlap the right-hand roadway —
rather than as a prohibition on the other roadway, so that a vehicle on the shoulder or the median is
judged too (`branch_2`) instead of falling outside the rule; the right-hand roadway is identified both
by the designated direction and by the divider lying to the vehicle's left, which tells a vehicle that
crossed over and runs either way on the far roadway from one keeping its own side. In `_o2` the
prohibited turns are acts observed over a stretch of time, so the node declares `occasion` with an
event boundary: the onset is the rise of the yaw rate, recognition is the angle reached since that
onset, and `under_way` reads the vehicle's own motion, since it occupied the same roadway before the
turn began. The exception is read `throughout`, because an exception should excuse only an act it
covers whole: a U-turn begun in a crossover and finished on the travelled roadway is not excused
(`occasion_s4`), while a turn made wholly within a junction is (`occasion_s4_outside`). "semicircular
turn" is read through the same two concepts rather than a third near-duplicate, and the narrowing says
so: no contract tells a semicircle from a reversal except by the heading change, which
`drv.motion.u_turn` already states. Reversal signal: if a label excuses a turn that began at an opening
and ended beyond it, the occasion of `s4` is what changed, from `throughout` to `at_recognition`.

## Concepts

Ten records, all new; the catalogue was empty. Two are definition-born: `drv.motion.standstill` quotes
`DEF-NRS-484A-255` ("complete cessation from movement") with the sampling tolerance as its parameter,
and `drv.motion.u_turn` quotes `DEF-NRS-484B-077` ("so as to proceed in the opposite direction",
"whether accomplished by one continuous movement or not"), which is why halts and rearward movements
between its onset and its recognition do not end the manoeuvre. Only `drv.motion.left_turn` and
`drv.motion.u_turn` declare `act`: they are recognized once an angle has been reached from an observed
onset. `drv.motion.turning` deliberately does not — it is a state over a window behind, true at each
observation of a bend, which is what "around a street corner" needs — and `drv.lane.lane_change` does
not either, being the event of a crossing at the observation it happened. `drv.position.direction_component`
is a quantity with no parameters, so the bound stays in the rule that calls it; and no concept carries
a bound of adequacy: the following headway, the entry clearance, the view distance and the feasibility
speed are all in their rules' operationalizations, where they answer to the law. Every concept takes
the region it judges as an argument where a law singles one out, so none finds a region of its own.

## For the operator

- **Aggregates in an operationalization.** Rule 0 says a span whose words are a defined term claims
  `ru.aggregate=<id>`, but the validator accepts only a bare atom, primitive or concept id in an
  operationalization's `concepts`, and rejects both the bare atom and the `=<id>` form there. Four
  standard spans use a defined road-user word ("approaching traffic" in `NRS-484A-450-2`, "the traffic
  upon … the highway" in `NRS-484B-127-1`, "an overtaking vehicle" in `NRS-484B-127-2`, "any other
  vehicle or combination of vehicles" in `NRS-484B-127-3`). I resolved it by reading those words
  without a class restriction — every road user on the way, every road user that may enter the space —
  quoting the definition in the convention so the reading is on the record, and in each case the wider
  reading cannot weaken the duty (in `NRS-484B-127-3` the entering length is the greater of the design
  length and an observed body's length, so a short road user never shrinks the space owed). If the
  intent is that a standard may be bounded by an aggregate, the validator needs to admit the
  `ru.aggregate=<id>` form in `concepts`.
- **`p.heading_since_step_carla_scene_graph` is in milliseconds** while every other time quantity of
  the formula language is in seconds. `NRS_484B_227_1_o2` passes it as the `heading_step` formal of
  `drv.motion.left_turn` and `drv.motion.u_turn`, whose unit I declared `ms` to match it exactly. If
  Core expects the step bound in seconds, the parameter's unit, not the records, is what should change.
- **Parameter values are provisional.** Twenty-four new parameters are proposed with values taken from
  the conventions named on each one (AASHTO sight-distance and perception-reaction figures, the
  two-second-rule family, critical-gap values, manoeuvre-segmentation thresholds, measurement noise
  floors). None is reviewed. The ones most likely to move a verdict on a labelled recording are
  `p.following_headway_time_*` and `p.following_reaction_time` in the surrogate node,
  `p.intersecting_way_view_distance`, and `p.u_turn_reversal_angle`.
- **Two readings worth a second opinion.** `NRS-484B-127-3` is not marked surrogate, on the ground that
  the law supplies the functional test for "sufficient space"; and `NRS-484B-127-2`'s width qualifier is
  read as attaching to "combination of vehicles" alone. Both are stated in full above, and either can be
  reversed without touching the segmentation.
