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
