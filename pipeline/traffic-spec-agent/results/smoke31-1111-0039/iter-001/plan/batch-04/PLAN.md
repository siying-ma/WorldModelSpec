# Plan — batch 04 (iteration 001)

Six nodes over five laws. Two new concept records: `drv.position.within_clearance_since_entry` and
`drv.motion.stopping_distance`. Reused concepts from earlier batches: `drv.motion.moving`,
`drv.motion.halted` and `drv.motion.entering_region`. No law-local aggregates. One atom gap, on
NRS-484D-100-1(c).

## NRS_484B_560_7a — complete the railroad crossing without stopping

**Decision.** The subject is a vehicle (`ru.aggregate=DEF-NRS-484A-320::vehicle`). The duty applies
while the vehicle is crossing a railway level crossing and has not completely crossed it. That state
is the new concept `drv.position.within_clearance_since_entry(x, r; clearance)`: it is true from the
vehicle's entry onto `st.railway_crossing` until its body outline stands at the clearance or more
from the crossing region (`st.region_geometry`). The clearance is the section's own literal, 15 ft.
Once the body has left the crossing, the trailing end is the point of the outline nearest the
crossing, so this distance measures the section's definition of "completely cross". While the duty
applies, the vehicle must not halt (`drv.motion.halted`, with no minimum duration, as in "any
halting, even momentarily").

**Reasons.**
- The causes "due to insufficient (1) space … or (2) undercarriage clearance" say why the vehicle
  stops. Neither cause is observable. Following the ontology's convention on purpose, they are read
  through the conduct they explain: a halt before the crossing is complete. This is disclosed as an
  `observable_reading` of category `purpose`.
- The definition of stopping excepts a halt "necessary to avoid conflict with other traffic". That
  exception is deliberately not read. Clause (1) makes a halt forced by queued traffic beyond the
  crossing the very violation, so reading the exception in would empty clause (1).
- The other part of the exception, a halt directed by a police officer, is carried
  (`dev.human_direction`, role `police_officer`, indication `stop`, governing the region the vehicle
  occupies).
- Directions from a device are not read. No official device directs a halt on the tracks: a signal
  or stop sign further on directs a halt at its own line, and queueing on the tracks for it is
  clause (1).
- "Nearest rail" is read as the boundary of the crossing region.

**Reversal signals:**
- A label that excuses a halt on the tracks behind a queue.
- An ontology atom for undercarriage clearance or for the crossing's vertical profile; that would
  let clause (2) be read on its own evidence.

## NRS_484B_600_1a — basic speed rule (surrogate)

**Decision.** The duty is a standard, so the node is marked surrogate. The subject is a moving
vehicle (`drv.motion.moving`). Each factor the words name has its own bound, and the speed enters
every bound:
- **Surface and weather.** The stopping distance (new quantity concept
  `drv.motion.stopping_distance`) uses a braking deceleration chosen by the surface: ice or snow,
  else wet or precipitation, else dry.
- **Other highway conditions.** The stopping distance must not exceed the sight distance
  (`st.sight_distance`). The speed squared times the road's curvature must not exceed a lateral
  acceleration.
- **Weather.** The stopping distance must not exceed the visibility distance (`env.visibility`).
- **Width.** A lateral margin proportional to speed must fit between the lane's width and the
  vehicle's width.
- **Traffic.** A time headway to every road user ahead in the same lane.

**Reasons.**
- The traffic aggregate is not claimed. The validator does not accept an aggregate inside an
  operationalization. A road user in the lane ahead is, by the definition's words, traffic "using
  any highway for purposes of travel", so the rule reads every such road user whatever its class.
- Each narrower reading (highway width read as lane width; the catch-all read only through sight
  distance and curvature) is disclosed on the standard span.

**Reversal signals:**
- Labelled verdicts that disagree systematically with one bound: tune that bound's parameter, or
  drop the bound.
- The operator rejecting the lateral-margin convention for width.

## NRS_484B_769 — cyclist and scooter signals by hand and arm

**Decision.** The subject belongs to one of three aggregates: bicycle, electric bicycle or electric
scooter. The rule applies on a roadway whenever the rider shows a signal, either a lit turn
indicator or an arm signal. The signal must then be given by arm (`sig.hand_signal` other than
`no_signal`), and its meaning must match any lit indicator. A left indicator matches either `left`
or `re_enter`, because NRS 484B.420 uses the same horizontal arm for both.

"In the manner required by NRS 484B.420" is a `definition` reference to DEF-NRS-484B-420. Its four
listed meanings are exactly the values of `sig.hand_signal`. The right-arm alternative in the
exception decodes to the meaning `right`, so it is accepted.

**Reason.** `sig.hand_signal` records only the meaning of a signal, not which arm or side gave it.
This is disclosed as a narrowing.

**Reversal signal:** an atom for arm posture (which arm, which side). With it, the manner could be
checked directly.

## NRS_484D_100_1 — when lighted lamps are required

**Decision.** The subject is a vehicle on a highway that is not parked. The rule applies at any one
of three times:
- (a) `env.darkness`, with its sunset/sunrise boundary set to the literal one-half hour;
- (b) `env.visibility` below the literal 1,000 ft, an `observable_reading` of category
  `perception`;
- (c) a sign directing lamps on, which is an atom gap.

The list is joined by "and", but it names the times at which the duty arises, so any one of them
suffices. The obligation is headlamps lit (low or high beam).

**Reasons.**
- The parked-vehicle exceptions point to the chapters' provisions on parking lamps. They are read as
  excusing a parked vehicle (at a standstill with its engine off) from this headlamp duty.
- The class-by-class lamp sets "as respectively required in this chapter" are not in the corpus.
  They are a residue on the reference span, and the headlamp reading is a disclosed narrowing.
- "Of this State" is a residue of scope `none`, because the run applies Nevada law.

**Reversal signals:**
- The parked-vehicle lamp provisions entering the corpus: compose them as `unless` on s4.
- A source showing that trailers are separated from their combinations.

## NRS_484D_215_1_o1 — multiple-beam use: reveal at a safe distance (surrogate)

**Decision.** The subject is a motor vehicle being operated (moving, or with its engine running) on
the roadway or shoulder. "During the times specified in NRS 484D.100" is a composition `as:
condition` on `NRS_484D_100_1`. That is the referred state itself: the composed rule's applicability
is exactly those times, for the same vehicle. "Subject to the following requirements and
limitations" composes `NRS_484D_215_1_o2` `as: exception`.

The obligation is a beam lit. Wherever the stopping distance exceeds the low beam's reveal distance,
the beam must be the high beam. The safe-distance standard is the whole content of this duty, so the
node is marked surrogate.

**Reason.** Beam aim and intensity are not observed. They are read through the beam state.

**Reversal signals:**
- Urban night recordings labelled compliant with low beams at moderate speed. That points either to
  `p.low_beam_reveal_distance` or to missing street-lighting evidence, which no atom carries.

## NRS_484D_215_1_o2 — dim for an oncoming vehicle within 500 feet

**Decision.** The trigger (motor vehicle being operated, roadway or shoulder, the times of 484D.100)
is shared with o1. The rule also needs a road user of the vehicle aggregate, other than the subject,
that is oncoming (`rel.oncoming`, headings opposed and closing). Its surface gap must be within the
literal 500 ft. The obligation is low beam.

The deeming sentence and its reference to DEF-NRS-484D-210-1-2 make the low beam compliant
regardless of road contour and loading. The validator allows one obligation span per node, so those
words are segmented as `definitional`. High beam is read as projecting glare; headlamps off do not
"use a distribution of light".

**Reversal signal:** a source that observes beam aim, or adaptive high beams that mask the oncoming
driver.

## Concept records

- **`drv.position.within_clearance_since_entry`** is a state, not an act. It counts from the
  observed entry onto the region (past operator `since`) until the body outline first stands at the
  clearance or more from it. The side of the region is not distinguished, and the contract says so.
- **`drv.motion.stopping_distance`** computes speed × reaction time plus speed² over twice the
  deceleration. Both inputs are formal parameters. It carries no adequacy bound: the calling rule
  compares the distance with its standard.

## For the operator

- **Gap on NRS-484D-100-1(c), "When directed by an official traffic control device".** No catalogue
  code of `dev.regulatory_sign` directs road users to display lamps. The proposal is a lamps-on sign
  (`dev.lamps_on_sign`, or equivalently a code `lamps_on` of `dev.regulatory_sign`). The validator
  only accepts a new id at the head of the proposal, which is why it is written that way. If the gap
  is filed, it blocks NRS_484D_100_1. Through their `as: condition` composition it also blocks both
  NRS_484D_215_1 nodes.
- **Parameter values proposed for review:**
  - `p.perception_reaction_time`: 2.5 s
  - `p.braking_decel_dry` / `p.braking_decel_wet` / `p.braking_decel_ice`: 4.5 / 3.4 / 1.5 m/s²
  - `p.curve_lateral_accel`: 3.0 m/s²
  - `p.lateral_margin_time`: 0.02 s
  - `p.traffic_time_headway`: 1.0 s
  - `p.low_beam_reveal_distance`: 30.48 m, from the 100 ft lowermost-beam figure of NRS 484D.210(2)
  - `p.oncoming_heading_cosine`: 0.7

  With the low-beam reach at 100 ft, NRS_484D_215_1_o1 requires high beams above roughly 10 m/s at
  night. This is the strictest consequence of the surrogate, so review it first.
- **The definition of "stopping" against NRS-484B-560-7a.** DEF-NRS-484A-260's exception for
  traffic conflict would void clause (1) if applied literally. The plan does not apply it. Confirm
  this reading in the reading convention.
