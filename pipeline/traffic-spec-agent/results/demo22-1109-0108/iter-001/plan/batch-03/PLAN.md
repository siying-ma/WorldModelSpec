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
