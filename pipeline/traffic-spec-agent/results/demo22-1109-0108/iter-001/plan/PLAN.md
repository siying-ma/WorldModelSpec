<!-- batch-01 -->
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

<!-- batch-02 -->
# Plan — batch 02: intersection right-of-way, sign-controlled entrances, yellow signal, left-turn approach

Eight law lines, thirteen nodes. Six lines state two duties each; the two that do not
(`NRS-484B-250-1`, `NRS-484B-250-2`, `NRS-484B-307-6a`, `NRS-484B-400-2a`) are single nodes. One new
concept, `drv.motion.region_entry`, is proposed; everything else is carried by the ontology's atoms,
two primitives for closest approach, one for the signed offset along a carrier, one for the lateral
offset, and the three concepts earlier batches proposed (`drv.motion.standstill`,
`drv.motion.left_turn`, and nothing else of theirs).

Four readings recur across the batch, and each is recorded on the spans that use them rather than
assumed once:

- **"Yield the right-of-way"** is `DEF-NRS-484A-210`'s right to proceed *in preference* to another,
  with its own standard inside it ("such circumstances of direction, speed and proximity as to give
  rise to the danger of a crash unless one grants precedence"). On a trace, granting precedence shows
  in three ways and no other: not entering the junction while the privileged road user is within it,
  not touching it, and not letting the closest approach under constant velocities within
  `p.yield_conflict_horizon` fall below `p.yield_min_clearance`. Where the subject is already inside
  the junction, the first is spent and the other two carry the duty. The reversal signal is a labelled
  case in which a subject that never entered after the other, never touched it and never came within
  the clearance is still labelled a failure to yield: that would mean precedence needs a further
  observable (a deceleration profile, a path concession) and the reading must be widened.
- **"So close(ly) … as to constitute an immediate hazard"** is a `standard` span wherever it appears
  (`253`, `257-1`, `257-2`) and is operationalized by *degree*, not by presence: the approaching
  vehicle's distance to the junction (`st.region_geometry`) against its own speed times
  `p.yield_headway_time`, together with the closest-approach bound. Both move with the measurement, so
  a fast distant vehicle and a slow near one are told apart. The reversal signal is a mismatch set in
  which the headway bound decides cases the labels split on speed alone.
- **The approach reading of rule 4c** governs every halt owed at a place before an entry
  (`250-4_o1`, `257-1_o1`, `257-2_o1`): the event is the entry into the junction, the target is the
  carrier the subject occupies whose entrance end is that junction, the place is the mark recorded for
  *that* carrier in the words' order, and the search runs back only to the start of that approach or to
  the subject's previous entry into the same junction. Each of those nodes carries the
  `history_boundary` scenario. The reversal signal is a trace in which the search's start is observed
  and the verdict still comes out unknown.
- **"The driver"** is read through the vehicle's controlled motion in every node (an
  `observable_reading` of category `agency`), since who or what is at the controls is not observable.

## `NRS_484B_250_4_o1` — halt at the place when the signal is inoperative

The trigger is the entry into a junction whose signal is installed, uncovered and inoperative *at the
entry*, so the inoperative state is read at the entry observation and not over the approach; that is
what the words say. The obligation is a rule-4c halt: the stop line marking the subject's carrier,
else the crosswalk marking it, else the point at which `st.sight_along_way` reaches
`p.intersecting_way_view_distance`. Two readings are disclosed on the obligation span. "Shall proceed as
if a stop sign had been erected" claims no `dev.stop_sign`: no sign is in the scene, and the as-if
clause's content is exactly the conduct the same sentence and the next prescribe — reading a device in
would make the rule turn on something the trace cannot show. "The through highway" is read as the
crossing highway, because at an inoperative signal nothing on the road displays the designation
`DEF-NRS-484A-275` describes, and the words' purpose is the view of the traffic the subject must give
way to. Reversal signal: a labelled case at an inoperative signal where the expected stopping point is
the one a (non-existent) sign's position would give rather than the marked line.

## `NRS_484B_250_4_o2` — proceed cautiously, yielding, after that halt

"After making such a stop" refers to the act of `_o1`, and rule 5 forbids weakening it: the condition
carries the halt *with its place*, re-claiming the stop line, crosswalk, view point, carrier direction
and body-to-mark distance, rather than composing `_o1` (a composed rule counts as complied with where
it is not engaged, which would say nothing about whether the halt happened). "Proceed cautiously" is a
`standard` qualifying a concrete duty, so the node is not a surrogate: it is bounded by
`p.cautious_proceed_max_speed` with the conflict bounds beside it, so the caution moves with the
proximity of the road users the same sentence names. "Vehicles which have previously completed a stop"
is read as a halt at an earlier observation on a carrier entering the same junction — the words give no
place, and the junction's entrances are where such a halt is owed. Reversal signal: a labelled case in
which a vehicle that halted far upstream, on no entrance carrier, is still owed precedence.

## `NRS_484B_250_1` — yield to a vehicle already in the junction from a different highway

"Approaching an intersection" is the ontology's own definition (a carrier occupied whose entrance end
is the junction), so a subject at rest or backing on that carrier is still approaching. "Has entered …
from a different highway" is read as an entry event plus present occupancy, the way compared through
`st.on_way` on the two entry carriers. The "except as otherwise provided in subsection 4" reference is
written as two `unless` compositions (one per node of that line) scoping **only** the
traffic-control-device exception: subsection 4 speaks to a signal-controlled junction whose signal has
failed, and it has nothing to say about the opposite-direction left-turn exception, which therefore
stays in force. Reversal signal: a labelled case at an inoperative signal where the left-turn exception
is also treated as suspended.

## `NRS_484B_250_2` — the vehicle on the left yields to the vehicle on the right

"At approximately the same time" is the one `standard` span of the line, operationalized by the
interval between the two entry observations against `p.simultaneous_entry_window`; the entries
themselves are concrete and carried by `drv.motion.region_entry`. "On the left" and "on the right" are
`rel.bearing`, the atom whose contract names exactly these words, read between the two vehicles the
trigger binds so no third road user can take the role. Because both vehicles are inside the junction by
the time the duty bites, the no-entry limb of the yield reading is spent and the clearance and contact
limbs carry it. Reversal signal: a labelled near-simultaneous pair outside the window that is still
judged under this subsection.

## `NRS_484B_253_o1` — the left-turning driver yields to oncoming traffic

The subject is the vehicle within the junction whose plan is declared to be a left turn there
(`int.left_turn`, read at or before the judged observation, never ahead of it); the act of turning is
*not* what engages the rule, so a vehicle waiting with its wheels straight is bound. "Approaching from
the opposite direction" is read through the carriers and their designated directions, as the ontology
directs and as this clause in particular needs: the subject's own heading swings through the turn while
the direction it came from does not. The permission clause ("but such driver, having so yielded … may
make such left turn") is marked `sibling` here: it states no duty of this node's subject, its operative
content is the other node's condition, and rule 5 provides for exactly this placement. Reversal signal:
a labelled case where a left-turning vehicle is excused because its heading had already left the
opposed sector.

## `NRS_484B_253_o2` — the other drivers yield to the vehicle making the left turn

The duty arises only on the three facts the words give: the left-turning vehicle *has yielded*
(`as: compliance` on `NRS_484B_253_o1` — the words require compliance with that very duty), *has given
a signal*, and *is making the turn*. The signal clause is kept, not dropped: "when and as required"
refers to the signalling provisions, which are outside this corpus, so the condition is carried by
`sig.turn_indicator` / `sig.hand_signal` within `p.turn_signal_advance_window` and the reading is stated
in the element's justification (a `reading` narrowing is not admissible on a condition span). The
obligation re-claims no manoeuvre: the turn is the condition that raises the duty, which is why
`drv.motion.left_turn` sits on `c3` and the obligation reads the road user that span binds — the node
therefore needs no `occasion`. Two `not_applicable` branches differ from the forbidding one only in the
weaker fact (no signal; no prior yielding). Reversal signal: a labelled case where the other drivers are
held to the duty although the turning vehicle signalled nothing.

## `NRS_484B_257_1_o1` — stop or yield at the place when signs are erected

Same rule-4c shape as `250-4_o1`, with the act split by the governing sign: a halt under
`dev.stop_sign`, a halt or `p.yield_sign_slowed_max_speed` under `dev.yield_sign`, whose own contract is
"yielding without a mandatory halt". Here the through-highway designation *is* observable — the sign
governing the subject's approach is the evidence `DEF-NRS-484A-275` points at — so the reading is a
`status` one rather than the substitution `250-4_o1` had to make. The police-officer exception is
`dev.human_direction` with role `police_officer` and an indication given, so an officer present but
directing nothing does not excuse the duty. Reversal signal: a labelled yield-sign approach judged a
violation for not halting.

## `NRS_484B_257_1_o2` — yield to through-highway traffic while crossing

The condition carries the first sentence's act in full, including the yield-sign alternative, for the
reason given under `250-4_o2`. The obligation's two limbs are kept apart as the words keep them: a
concrete limb (vehicles that have entered from the through highway) and a `standard` limb (vehicles
approaching so closely as to be an immediate hazard), the latter operationalized by degree. "During the
time such driver is moving across or within the intersection" fixes *when* the duty is read, carried by
occupancy of the junction and a speed above the standstill tolerance. Reversal signal: a labelled case
in which the duty is expected to persist after the subject has cleared the junction.

## `NRS_484B_257_2_o1` — obey the sign, in subsection 1's manner, before entering

The place of the act is not restated: "in compliance with the manner prescribed in subsection 1" is a
`compliance` composition on `NRS_484B_257_1_o1`, which is what rule 5 prescribes for these words, and
the node's own obligation states the event, the target and the history bound so the coder implements the
search without choosing a reading. "At one or more entrances thereto" is read over the junction's
entrance carriers, so a sign at another entrance engages the rule while the act the subject owes is
read from the sign governing its own carrier. "Although not a part of a through highway" is a residue
with `scope: none`: it is concessive and adds no observable condition, and reading it as one would
confine the rule to junctions off a through highway — narrower than the words. Reversal signal: a
labelled all-way-stop case where the duty is expected only where the junction is off a through highway.

## `NRS_484B_257_2_o2` — proceed cautiously, yielding to the unobligated

"Vehicles not so obligated to stop or yield" is read on the road — a vehicle whose own approach carrier
into that junction is governed by no stop or yield sign — and deliberately *not* as a composition: a
composed rule counts as complied with where it is not engaged, so composing it would say nothing about
whether that vehicle was obligated. Two standards sit in this sentence, "shall proceed cautiously" and
"approaching so closely as to constitute an immediate hazard", and each gets its own
operationalization; neither is the whole duty, so the node is not a surrogate. A third branch shows the
cautious bound deciding a case with no other road user in the scene at all. Reversal signal: a labelled
case where a vehicle whose own entrance carries a stop sign is nonetheless owed precedence.

## `NRS_484B_307_6a` — no entry on the red after a steady yellow

The obligation span and its condition are cut apart ("must not enter the intersection" /
"when the red signal is exhibited") because the words tie the trigger to the yellow face and the
prohibition to the red one, which one head cannot display as its only state at one observation. The
disclosed reading on the obligation span is therefore temporal: the duty arises for a road user that
faced the steady yellow alone on that carrier and forbids an entry made at an observation at which the
governing head exhibits the red; any other reading empties the prohibition. The subject carries two
class elements, `ru.aggregate=DEF-NRS-484A-285::traffic` and `ru.aggregate=DEF-NRS-484A-320::vehicle`:
"traffic" is the defined aggregate, and the law's own word "vehicular" limits which of its members the
duty reads, leaving out pedestrians and ridden or herded animals — the `branch_2` scenario is exactly
that pedestrian case. The warning clause is a residue with `scope: none`: it says what the yellow tells
the driver, the duty is the same whether or not the green is in fact being terminated, and what a driver
was warned of is a state of mind no trace carries. Reversal signal: a labelled case in which a
pedestrian entering on the red is judged under this paragraph, or one in which an entry made on the
yellow itself is judged a violation.

## `NRS_484B_400_2a` — the left-turn approach lies next to the centre line

The place words "at an intersection" are cut into their own span, as rule 2 requires, so that the
declared intention's span carries only "intends to turn" and its target region is the junction that
element binds. The obligation's own words select the left turn among the turns the earlier words allow,
which is disclosed on the obligation span. "That portion of the right half of the highway nearest the
centerline thereof" is read twice over, because a duty must cover its domain: where the carriageway is
laned, as the lane of ordinal 1 for the subject's direction (the ontology's ordinal 1 is the leftmost
looking along the lane's direction, hence the one adjoining the centre line on a two-directional
highway); where no lane is recorded, as a signed lateral offset to `st.centre_line` that is positive
(the centre line to the subject's left, so the subject on the right half) and at most
`p.centerline_adjacent_distance`, one design lane width. "Two-directional" is `DEF-NRS-484B-073` in its
copular form: undivided (no `st.median_or_divider` on the way) and carrying carriers with opposed
designated directions, the permission read as a `status` reading of the designated directions.
Reversal signal: a labelled case on a laned approach where the expected position is any lane left of
centre rather than the leftmost of the subject's direction.

## Concept record

`drv.motion.region_entry` (formula; `u:track`, `r:region`; no parameters; reads `rel.occupies`) is the
event of a footprint coming to overlap a region: it overlaps now and did not at the observation before.
It is proposed rather than written inline because eight nodes of this batch need the same event — an
entry into a junction — and because the distinction that matters legally (the entry, not the lying
inside) is exactly what the contract fixes: a road user already inside when a red appears makes no
entry, and a vehicle that has entered and left no longer holds the junction. It takes the region as an
argument, so every caller passes the junction its own words single out; nothing in the body looks for a
region of its own. No parameter: `rel.occupies` is three-valued and the rise needs no tolerance.

## Spans reused from the index

"The driver of a vehicle" and "The driver of a vehicle:" map, as in the index, to
`ru.aggregate=DEF-NRS-484A-320::vehicle` alone (five nodes here). No index mapping is contradicted;
no dispute is recorded.

## For the operator

1. **Parameter proposals are repeated per node by necessity.** The validator does not see parameters
   proposed by other batches of this iteration, so every node re-proposes each parameter it names,
   with the same unit and the same value as the earlier proposal (`p.standstill_speed_tolerance` 0.1,
   `p.stop_point_tolerance` 1.0, `p.intersecting_way_view_distance` 100.0,
   `p.same_direction_cosine_tolerance` 0.866, `p.turn_onset_yaw_rate` 3.0, `p.left_turn_angle` 45.0,
   `p.turn_signal_advance_window` 3.0, `p.lateral_offset_resolution` 0.5). New to this batch:
   `p.yield_conflict_horizon`, `p.yield_min_clearance`, `p.yield_headway_time`,
   `p.cautious_proceed_max_speed`, `p.yield_sign_slowed_max_speed`, `p.simultaneous_entry_window`,
   `p.centerline_adjacent_distance`. `p.cautious_proceed_max_speed` and
   `p.yield_sign_slowed_max_speed` carry the same provisional figure but different conventions (caution
   while crossing after a required act; having slowed at a yield-controlled entrance); if you would
   rather hold one figure, merging them is a one-line change to the reading and leaves every rule
   untouched.
2. **`int.left_turn` is declared here for the first time** and is read by four nodes
   (`250-1`, `250-2`, `253_o1`, `400-2a`) with one meaning: the source's current plan for the road user
   is a left turn at the declaration's target region. `484B.400(2)(a)`'s words are "intends to turn",
   with the left turn selected by the obligation; if you would rather have a separate `int.turn` whose
   meaning is a turn in either direction, that is a plan-level change, not a rule change.
3. **"Yield the right-of-way" has no operationalization span of its own.** `DEF-NRS-484A-210` contains a
   standard ("the danger of a crash"), but no `standard` span was cut from the obligations that use the
   defined phrase, because the words of those obligations contain no standard word; the clearance and
   horizon bounds are therefore carried on the obligation elements with a disclosed reading, and the
   parameters are named in `params`. If the review phase would rather see every use of "yield the
   right-of-way" cut as a `standard` span with its own operationalization claim, that is a uniform
   re-cut of five nodes and we would make it in one pass.
4. **`NRS 484B.413` (signals of intention) is not in the corpus**, so `253`'s "having given a signal
   when and as required" is carried by the signal atoms and the signalling convention rather than by a
   composition. Adding that section to the corpus would let the condition become an
   `as: compliance` composition and remove `p.turn_signal_advance_window` from this node.
5. **"Stop" is ambiguous in three of these lines** (`DEF-NRS-484A-255` vs `DEF-NRS-484A-260`, each
   stating its own scope). Every use here is a required halt, so `DEF-NRS-484A-255`'s "complete
   cessation from movement" is the one `drv.motion.standstill` carries; `DEF-NRS-484A-260` governs
   prohibited stopping and no span of this batch uses it. No selection decision is needed from you
   unless that reading is wrong.

<!-- batch-03 -->
# Plan — batch 03 (turning position, reversal on a blind place, turn signalling, basic speed rule)

Six laws, six nodes, one new concept record. No law-local aggregate: every defined term these
laws use is resolved in the definitions table, and none of the clauses defines, adds or excludes
a class of road users, so `aggregates.jsonl` is empty.

## `NRS_484B_400_2b` — the left turn must leave the junction right of the entered way's centre line

The line shares its opening words with (2)(a), already planned this iteration, so the three
spans the mapping index holds — "If the driver of a vehicle", "at an intersection and:" and
"Both intersecting highways are two-directional:" — are reused with exactly the atoms
`NRS_484B_400_2a` claimed; the words mean the same here, the condition being the same approach to
the same kind of junction between the same two kinds of way. Two spans are new. "intends to turn"
is a declared intention, carried by a new id `int.turn` (the catalogue holds only `int.left_turn`,
whose meaning is narrower: this paragraph's trigger is an intention to turn to either hand, and
the hand only enters later, through the obligation's own words), with the intersection of the next
span as its target, so the intention's span carries the intention alone. The obligation was cut so
that "the left turn" is a condition — the duty arises where the vehicle does make a left turn —
and "must be made so as to leave the intersection to the right of the centerline of the highway
being entered." is the obligation proper: the event of leaving the junction, with the vehicle on
the right of the entered way's centre line. That cut keeps the duty's meaning (given a left turn,
the departure must be on the right of the centre line) and keeps the act concept out of the
obligation span, so the node needs no occasion: the obligation is read at one observation, the
departure. "leave the intersection" has no catalogued carrier — `drv.motion.region_entry` is the
entry event and `drv.lane.lane_change` is a crossing out of a lane with lane adjacency in its body
— so a mirror concept `drv.motion.region_exit` is proposed, taking the region as a formal, which
is what the singled-out junction requires. Two readings are disclosed on the obligation span: the
highway being entered is the highway the vehicle occupies at the departure (the junction itself
lies on every way that meets there, so the way it is on once clear of the junction is the way
entered), and "to the right of the centerline" is the centre line's signed lateral offset from the
vehicle standing on the left-positive side by at least `p.lateral_offset_resolution`, the same
side-resolution parameter `NRS_484B_227_1_o1` proposed for a side of a roadway. Reversal signal: a
labelled scene in which a vehicle completes a left turn inside the junction but crosses to the
left of the entered way's centre line only after it is clear of the junction, and the label calls
it a violation, would show the departure observation to be the wrong moment and the condition to
belong to a window after it.

## `NRS_484B_407` — no reversal of direction on a curve or near a crest where the vehicle cannot be seen

The obligation is the manoeuvre itself, so this node is the one in the batch that declares an
occasion. `drv.motion.u_turn` carries the obligation span word for word: its contract was written
from DEF-NRS-484B-077 and quotes "so as to proceed in the opposite direction", so no new concept
is needed and the reversal angle, onset rate and step bound are its parameters. The act has no
window boundary — a reversal is recognized when the accumulated heading change reaches the
reversal angle, however long it takes — so the boundary is `event`, with the onset and the
under-way test both reading `kin.yaw_rate`, the only quantity the concept's own onset reads; no
place tells an observation inside the act from one before it, since the vehicle is on the same
bend and the same crest vicinity beforehand. The three conditions are read at `some_moment`: the
words place the place and the sight condition at the turning, not at its recognition, and reading
them only where the act is recognized would let a reversal begun on a blind bend escape by being
completed on a straight stretch. They are read at one and the same moment, because the law joins
them with "where". "upon any curve" names the feature with no size, so it is the curvature
standing clear of zero at `p.curvature_resolution`, a new parameter that names the source's
alignment resolution only; "the approach to or near the crest of a grade" is the ground distance
from the body to the crest region at most `p.crest_approach_distance`, a new parameter from the
crest vertical-curve convention — the words' own "or near" is why one distance, on either hand of
the crest, carries them. "cannot be seen by the driver of any other vehicle approaching from
either direction within 500 feet" is `st.sight_distance`, whose contract is exactly the mutual
quantity the words ask for, "whether or not any road user is there", which is also why the duty
binds with no second vehicle in the scene; 500 feet is the statute's own figure, declared as a
literal. The validator rejects a narrowing on a condition span, so the two readings this span
needs — one value for the place covering both directions, and the place's sight distance standing
for what an approaching driver could see — are carried in the element's justification instead of as
narrowings, which is where a span that decides when the rule applies must carry them. Reversal
signal: a labelled scene in which the sight distance is short in one direction only and the label
calls the reversal lawful would show the one-value reading of "either direction" wrong and call for
`st.sight_along_way` beside it.

## `NRS_484B_413_2` — the turn signal over the last 100 or 300 feet travelled

The sentence states one duty with two window lengths, so it is one node, not two: cutting the
300-feet alternative into a second obligation span would have left each node's obligation missing
words the other needs (the signal itself), which `sibling` may not carry. The district phrase and
the alternative length therefore sit in one condition span, carried by the assumption
`asm.in_business_or_residential_district` — a district defined by its buildings is a legal region
class the ontology admits only as a reading assumption — with the 300-feet figure declared as a
literal on that span and the 100-feet figure on the obligation span. The obligation then selects
the window length by the declaration, and where the trace declares neither the verdict is unknown.
The window is a distance-travelled window, so the obligation span claims `kin.path_length`, as a
time window claims the clock. "prior to changing the course of a vehicle." is `drv.motion.turning`,
a state concept and not an act, and the duty is judged at the observation at which it rises: that
is the course change the window runs back from. The signal is read as the indication of the hand of
the course change — the indicator lit on that hand or an arm signal of that meaning — the hand
taken from the sign of `kin.yaw_rate` at that observation, so a signal given on the other hand does
not discharge the duty; that reading is disclosed on the obligation span. The last sentence,
"regardless of the weather", adds no condition — the duty is identical whether or not rain or ice
is present — so it is a residue with `scope: "none"` and no weather atom is read. Reversal signal:
a labelled scene in which a vehicle signals the correct hand continuously but only over part of the
required path and the label calls it compliant would show the window should be measured from the
onset of the heading change rather than from its recognition.

## `NRS_484B_600_1a` — basic rule, reasonable and proper speed (surrogate)

The standard is the whole obligation, so the node is marked surrogate and its verdicts are
evidence, not a legal conclusion. The subject span is cut from the obligation so that "A rate of
speed greater than" carries `kin.speed` and the standard's own words carry the bound. Every factor
the words name is read, and by its degree where a magnitude carries it: the surface and the weather
select the wet or the winter decrement from a base design speed and enter it besides through the
visibility distance; the stream enters as a per-user decrement for each road user on the highway
occupied, so the bound falls as the stream thickens; the width of the highway enters as the
occupied lane's width divided by the lateral-recovery time; and the catch-all, "other highway
conditions", is read — and disclosed as read only — through the slope at the vehicle's place, the
place's sight distance and the visibility distance, the last two divided by the stopping-distance
model's perception-reaction-plus-braking time. Four narrowings disclose the narrower readings: the
stream as the road users present on the way, surface and weather as the four contracts the ontology
carries, the highway's width as the lane's width, and the catch-all as those three contracts. The
traffic aggregate is named in none of the carriers: an operationalization's bounding list takes
atoms, primitives and concepts, and the validator will not accept an aggregate id there, so the
count is over the road users of the scene on the occupied highway — which is what DEF-NRS-484A-285
reaches, every road user using a highway for travel — and the narrowing says so. Seven parameters
are proposed from the stopping-sight-distance and surface-friction conventions. Reversal signal: a
labelled recording on which the bound decides a plainly ordinary speed to be a violation, or a
plainly excessive one to be lawful, would move the base limit or a decrement, not the structure;
a mismatch that survives every value of them would show a factor read by a selection where its
degree should enter.

## `NRS_484B_600_1c` — speed above the posted limit

The obligation is concrete and needs no operationalization: the posted limit is the stated value of
a speed-limit sign of kind maximum, structure maximum or zone whose governance covers a travel
region the vehicle's footprint overlaps, that region lying on a highway. Three readings are
disclosed: "posted by a public authority" is the sign's presence on the road, the observable
evidence of its official posting, so neither the authority nor its jurisdiction under
DEF-NRS-484A-195 is read; "the particular portion of highway being traversed" is the governed
travel region the vehicle occupies, with the lowest posted maximum binding where several govern;
and a speed-limit sign carries no conditions attribute, so a legend stating hours is read as a
posting in effect. A minimum-kind sign is not read, the words reaching only a speed greater than
the posted one, and a branch scenario fixes that. Reversal signal: a labelled scene in which the
sign governing the lane and a differing one governing the roadway disagree, and the label follows
the higher value, would overturn the lowest-binds reading.

## `NRS_484B_600_1e` — the absolute cap

The figure is the statute's own, so it is a literal in miles per hour and no parameter enters;
"In any event," adds no observable condition — the cap binds whatever the subsection's other
paragraphs allow — so it is a residue with `scope: "none"`. The subject span is mapped exactly as
in the other two paragraphs of the section, the same words to the same atoms: the vehicle
aggregate, with the driving read through the vehicle's controlled motion (the motion-state concept
read negated), which the agency narrowing discloses. Reversal signal: nothing short of a change in
the section's text; a label mismatch here would be a trace or speed-unit defect, not a reading.

## Concept record

`drv.motion.region_exit` (formula, `u:track`, `r:region`, no parameters) is the mirror of the
accepted-this-iteration `drv.motion.region_entry`: the footprint overlapped the region at the
observation before and does not overlap it at the observation, read as the event at the observation
at which the overlap has ended. It takes the region as a formal, which is what a region the words
single out requires, states no direction, carrier or speed of departure, and reads `rel.occupies`
alone. `differs_from` records why it is not `drv.motion.region_entry` despite the same sorts and the
same atom. It is used by `NRS_484B_400_2b` only; any law whose words turn on leaving a region can
call it.

## For the operator

- Seven parameter proposals of this batch repeat, under the same name, unit and value, proposals an
  earlier batch of this iteration made (`p.turn_onset_yaw_rate`, `p.u_turn_reversal_angle`,
  `p.lateral_offset_resolution`, `p.left_turn_angle`, `p.turn_recognition_window`,
  `p.heading_change_noise_floor`, `p.standstill_speed_tolerance`): the validator does not count an
  unreviewed proposal of another node as catalogued, so each node that names one proposes it again.
  One review of each figure settles them all.
- The validator rejects any narrowing on a span whose role is `condition`, including an
  `observable_reading` of the kind rule 2 directs for a word with no observable counterpart
  ("cannot be seen by the driver"). In `NRS_484B_407` those readings are recorded in the element's
  justification instead. If the disclosure is meant to be machine-readable on such spans, the check
  needs to admit `observable_reading` narrowings on trigger, condition and exception spans, as rule
  2 says it may.
- An operationalization's `concepts` list will not take `ru.aggregate=<id>`, while the bare
  `ru.aggregate` is rejected as an unqualified aggregate claim; so a standard whose words name a
  defined aggregate ("due regard for the traffic") cannot bound itself with that aggregate. In
  `NRS_484B_600_1a` the stream is counted over the road users of the scene on the occupied highway,
  which DEF-NRS-484A-285's own words reach. If an aggregate should be nameable in an
  operationalization, the lookup there needs the same aggregate-aware resolution the element path
  has.
- `p.reasonable_speed_base_limit` (29.0 m/s) lies below the absolute cap of NRS-484B-600(1)(e)
  (80 mph) but close to the posted maxima of open Nevada highways; where
  `NRS_484B_600_1a` and `NRS_484B_600_1c` are evaluated on the same recording the surrogate will
  rarely bind before the posted limit does. That is a property of the convention, not of the rule,
  and the value is the operator's to set.
