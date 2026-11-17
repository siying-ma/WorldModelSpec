# Plan — batch 28

No law-local aggregates (`aggregates.jsonl` is empty). No new concepts were proposed.

## NRS_484D_215_1_o1 — use a beam that reveals at a safe distance (blocked: gap)

**Decision.** This line has two obligation spans: the beam that reveals at a safe distance (o1) and dimming for oncoming traffic (o2). The trigger reads a motor vehicle (DEF-NRS-484A-130 aggregate) on a roadway or shoulder lying on a highway, reusing the NRS_484D_165_3 mapping. The words "the times specified in NRS 484D.100" are a `definition` reference to NRS-484D-100-1. They borrow the three time qualifiers (a)–(c) whole, but none of that law's duty to show lamps. (a) and (b) map to `env.darkness`, plus `env.visibility` below the borrowed 1,000 feet. No atom carries (c), "when directed by an official traffic control device": `dev.regulatory_sign` has no lamps-on code. The span is mapped to its nearest atoms and carries an atom gap, `dev.lamps_on_sign`, which matches the pending smoke31-1111-0039:G21 on NRS-484D-100-1. The law therefore stays blocked.

**Obligation.** Using a beam means a headlamp state of `low_beam` or `high_beam`. The standard "directed high enough and of sufficient intensity to reveal … at a safe distance" uses a stopping-sight-distance model:
- the high beam always meets it;
- the low beam meets it only where `p.low_beam_sight_reach` is at least the stopping distance at the subject's speed, using `p.driver_reaction_time` and `p.following_decel_dry`.

**Limitation.** The oncoming limitation (s8) is the clause the first duty is "subject to". Here it is an exception that relaxes only the reach requirement: the low beam suffices while an oncoming vehicle is within 500 ft (surface gap). The lamps must still be lit.

**Narrowings.** The model assumes a dry surface. A following-vehicle limitation, which this line does not state, is not read.

**Reversal signals.**
- A label that judges low-beam night driving at urban speed compliant with no oncoming traffic: then reduce the obligation to "a beam lit".
- The operator retiring G21 or adding a lamps-on code: then the gap is resolved.

## NRS_484D_215_1_o2 — dim for an oncoming vehicle within 500 ft (blocked: same gap)

**Decision.** This node shares o1's trigger and times, so it carries the same gap. It applies when another vehicle is oncoming (`rel.oncoming`, `p.oncoming_heading_cos`) within 500 ft by `rel.surface_gap`. The surface gap is used rather than the centre distance, because the centre distance "overstates a clearance".

**Obligation.** The headlamp is not `high_beam`. The lowermost beam is a `definition` reference to DEF-NRS-484D-210-1-2, deemed to avoid glare "at all times, regardless of road contour and loading", so `low_beam` complies. An unlit lamp is left to o1. Reading glare through the beam selected is a disclosed narrowing.

**Reversal signal.** A label that judges a high beam aimed away from the oncoming driver (for example, on a divided road) as compliant.

## NRS_484D_400_5 — siren only when responding or in pursuit

**Decision.**
- **Subject:** the admitted aggregate DEF-NRS-484A-020::authorized_emergency_vehicle.
- **Obligation:** `sig.siren` is not sounding.
- **Exceptions (s4, s5):** "operated in response to an emergency call" and "immediate pursuit" are purposes. `ru.emergency_vehicle` says responding is conduct and not a class, so both exceptions are read through the vehicle's warning lamps flashing or rotating. This is an `observable_reading` of category `purpose`, and the lamp is never read as the sound.
- **Residues:** the equipment permission (s2), the restated permission "to warn pedestrians and other drivers" (s6, scope none) and the lamps-without-siren permission (s7) impose no duty.

**Reversal signal.** A label that excuses a siren used without lamps on a response. Such a response is not recognised here.

## NRS_486_341 — do not deprive a motorcycle or moped of its lane

**Decision.** The subject is a motor vehicle (DEF-NRS-484A-130). The motorcycle or moped (DEF-NRS-486-041 / DEF-NRS-486-038 aggregates) is quantified inside the obligation: it must be on the highway and occupying a lane. "Deprive … of such use" is read as sharing that lane side by side: the subject occupies the same lane and `rel.longitudinal_overlap` ≥ 0. This is a disclosed reading, and no parameter is needed. A scene with no motorcycle present is decided as compliant. "traffic lane" is read as `st.lane`, and the traffic aggregate is not claimed (the word names a lane, not road users); the earlier index mapping of "marked traffic lane" did the same.

**Reversal signals.**
- A label flagging deprivation from the adjacent lane without the subject entering the motorcycle's lane.
- A label excusing two motorcycles riding abreast with consent. NRS 486.351(3) allows this, and this line has no exception for it.

## NRS_486_351_1 — no lane splitting

**Decision.** The subject is a motorcycle or moped.

**Obligation.** There are no two vehicles v1 and v2 such that:
- v1 is to the subject's left and v2 to its right (`rel.bearing`);
- each is side by side with the subject;
- they occupy distinct lanes that are adjacent, either by `st.lane_adjacency` (same direction) or because the subject's footprint overlaps both lanes. Overlapping both shows the lanes touch whatever their directions.

The one case not read is a subject wholly within one lane between that lane's vehicle and a vehicle in an opposing lane (disclosed narrowing).

**Exception (s2).** The first draft read the police officer through the vehicle class alone, and the validator returned it: a class is no evidence of conduct. The exception is now read through conduct: a police vehicle displaying flashing or rotating warning lamps. This matches the index mapping of "(d) In the performance of official duties;" (`ru.emergency_vehicle` plus `sig.warning_lamp`).

**Reversal signal.** A label that excuses a police officer lane-splitting without lamps.

## NRS_486_351_2 — no riding abreast, overtaking or passing within one lane

**Decision.** The subject is a motorcycle, moped or trimobile.

**Obligation.** For every other vehicle in the subject's lane that is side by side with it, the pair must be excused, otherwise the duty is violated. The pair is excused (the subsection 3 sentence) when:
- both are motorcycles or mopeds;
- they travel in the same direction (`rel.same_direction`, `p.side_by_side_same_direction_cos`). This is how the drivers' consent is read, an `observable_reading` of category `intention`;
- no third vehicle is abreast in the lane ("two" is a literal).

"Except as provided in subsection 3" is a pointer to words this node carries, so it is a residue with scope none.

**Reading of "overtake or pass."** The index maps "overtake and pass" to `drv.interaction.overtake_pass`. Here the words forbid the *place* of the pass, within the same lane. A pass within one lane always brings the two side by side in that lane, so the duty is judged at those observations. The act concept is recognised only once the other vehicle is behind, when the subject may already have left the lane, so it is not used.

**Reversal signal.** A label that flags an unconsented same-direction pair, which this reading cannot tell from a consented one.

## For the operator

- **G21 blocks NRS-484D-215-1.** Both nodes carry the same atom gap as smoke31-1111-0039:G21 (`dev.lamps_on_sign`). Retiring G21, or adding a lamps-on code to `dev.regulatory_sign`, would unblock this law and NRS-484D-100-1 together.
- **Low beam at speed is a judgement call.** Under the stopping-distance reading of "safe distance", the low beam fails above about 17 m/s in darkness when no vehicle is oncoming. If the label contract treats any lit beam as compliant, `p.low_beam_sight_reach` (or the reading) needs review before labels drive repair.
