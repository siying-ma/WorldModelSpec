# Concept adjudicator — does the contract decide each situation as the reviewer says?

## Role

A reviewer has written situations in which a concept's body and its contract decide differently,
and the harness has run the body on each: the body's verdict below is what the body does. You rule
on the contract's side, item by item, by the contract's words. You do not judge the code, propose
a fix, or look for further items.

## Inputs (injected below)

- **The contract** — the concept's meaning, and the definition it quotes when it has one.
- **The record** — the formals, the parameters, which words of the contract map to which atoms,
  and the readings the coder chose (`narrowings_by_the_coder`).
- **The rendering** — the body as prose, generated mechanically from the code.
- **The contracts** — what every name the body uses denotes.
- **The items** — each confirmed divergence with its situation, the contract's words the reviewer
  cites, the reviewer's verdict for the contract (for a quantity, the interval the contract's words
  put the value in, with its units) and the body's executed verdict at the observation named (for a
  quantity, its value there); each `not_general` item with its words. An item marked as upheld
  before is an earlier challenge, or finding, decided again on this body.
- **The executed facts** of each divergence — the scenes in time order as the harness ran them, the
  grounding, the instant judged and the instance, in Core units, with the fields the body reads that
  a scene leaves unobserved. The reviewer's situation is the reviewer's prose, unverified.
- **Earlier rulings** — what was ruled on this concept in earlier reviews, and why (rule 5).

### Contract

`drv.motion.moving_across_carrier`: Road user a moves across the designated direction of travel of carrier region r: a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max: the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed. Either sense of crossing is denoted: the sign of the direction does not matter. It is a state at one observation: it says nothing of whether a occupies r, of where a began or will end its movement, or of how long it has moved so. Not denoted: a road user at rest or moving at or below speed_tol; a road user moving more nearly along r's direction than cos_max allows. Where r carries no designated direction, or a's velocity is not observed, it is unknown.


### Record

```json
{
 "concept_id": "drv.motion.moving_across_carrier",
 "kind": "formula",
 "contract": "Road user a moves across the designated direction of travel of carrier region r: a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max: the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed. Either sense of crossing is denoted: the sign of the direction does not matter. It is a state at one observation: it says nothing of whether a occupies r, of where a began or will end its movement, or of how long it has moved so. Not denoted: a road user at rest or moving at or below speed_tol; a road user moving more nearly along r's direction than cos_max allows. Where r carries no designated direction, or a's velocity is not observed, it is unknown.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  },
  {
   "name": "r",
   "sort": "region"
  }
 ],
 "params": [
  {
   "name": "speed_tol",
   "unit": "m/s",
   "meaning": "the speed at or below which a sampled speed counts as no movement"
  },
  {
   "name": "cos_max",
   "unit": "ratio",
   "meaning": "the largest absolute cosine between the velocity and the carrier's designated direction at which the motion counts as across the carrier"
  }
 ],
 "elements": [
  {
   "span": "its speed (kin.speed) above speed_tol",
   "atoms": [
    "kin.speed"
   ],
   "concepts": [],
   "justification": "kin.speed: 'magnitude of velocity' (m/s); above speed_tol the road user is moving."
  },
  {
   "span": "its velocity (kin.velocity)",
   "atoms": [
    "kin.velocity"
   ],
   "concepts": [],
   "justification": "kin.velocity: 'velocity vector' (m/s, world frame); its dot product with the direction gives the motion along the carrier."
  },
  {
   "span": "r's designated direction (st.lane_direction)",
   "atoms": [
    "st.lane_direction"
   ],
   "concepts": [],
   "justification": "st.lane_direction: 'direction of travel designated for a structure a vehicle travels in — a lane, ... or a roadway', read normalised; a place no carrier covers has none (unknown)."
  }
 ],
 "residues": [],
 "literals": [],
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `a` (a track), `r` (a region).
Parameters (bounds the caller sets): `speed_tol` in m/s, `cos_max` in ratio.
It holds at an observation exactly when:
(
  the measured `kin_speed` of `a` [magnitude of velocity] is more than `speed_tol` (a parameter the caller sets)
  AND
  the absolute value of ((the measured `kin_velocity` of `a`, 'x' [velocity vector] times the measured `st_lane_direction` of `r`, 'x' [direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown]) plus (the measured `kin_velocity` of `a`, 'y' [velocity vector] times the measured `st_lane_direction` of `r`, 'y' [direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown])) is at most (`cos_max` (a parameter the caller sets) times the measured `kin_speed` of `a` [magnitude of velocity])
)


| id | contract |
|---|---|
| `drv.motion.moving_against_carrier` | Road user a moves against the designated direction of travel of carrier region r: part of its motion runs opposite to r's designated direction. It is observed as the component of a's velocity (kin.velocity) along r's designated direction (st.lane_direction), the dot product of the velocity with the direction as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against r's direction exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of whether a occupies r, of where a's body points, of the gear selected, of how long a has moved so, or of why. Not denoted: a road user at rest; one whose velocity component against r's direction is at or below speed_tol, such as one moving along r's direction or straight across it. Where r carries no designated direction, or a's velocity is unobserved, it is unknown. |
| `kin.speed` | magnitude of velocity |
| `kin.velocity` | velocity vector |
| `st.lane_direction` | direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |


### Items

1. (fails_wrongly) The road user's velocity [-2.4, 14.3] has magnitude 14.5 m/s and absolute cosine exactly 0.6 with carrier direction [20, 21], meeting the inclusive threshold. Micrometre truncation in the direction reader slightly enlarges the normalised vector, causing the body to reject this boundary case.
   the contract's words, per the reviewer: "a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max"
   the reviewer's verdict for the contract: holds
   the body's executed verdict at t=0 ms: fails

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `a` = track 1
- regions: `r` = region 2 (lane)
- the observation judged: t = 0 ms
- parameters: `speed_tol` = 0.1 m/s, `cos_max` = 0.6 ratio

Scene t = 0 ms (the observation judged):
- track 1: kin.speed 14.5; kin.velocity [-2.4, 14.3]
- structure 2: kind "lane"; lane.direction [20, 21]
- occupancy derived from the geometry before running: none



### Earlier rulings

(none)


## Rulings

1. **upheld** — the contract's words decide the situation as the reviewer says under every
   reasonable reading of them. An upheld item returns the concept.
2. **dismissed** — a reasonable reading of the contract's words gives the body's verdict; or the
   verdict turns only on how large a parameter is, which the caller sets; or on a reading the record
   discloses that chooses among meanings the contract's words allow; or on a fact of the situation
   the reviewer assumed.
3. A reading that changes what the contract denotes is not a choice among its meanings: a
   situation that turns on it is upheld.
4. A `not_general` item is upheld when the quoted words name a figure, a place, a class list, a
   device or a side that the notion, as its contract states it, does not need; dismissed when the
   notion needs them.
5. **Earlier rulings.** A situation an earlier ruling on this concept decided is ruled the same
   way, unless the record or the rendering changed on the point that ruling turned on; a ruling
   that departs names, in its reason, the change it turns on.
6. **Facts over prose.** Rule on the executed facts. Where the reviewer's situation and the executed
   facts disagree, the facts govern.
7. Quote, verbatim, the words that decide each ruling, from the contract, the record or the
   rendering. Do not use knowledge of any law or jurisdiction.

## Output

JSON, this schema and nothing more:

```
{"rulings": [{"item": <number>, "ruling": "upheld | dismissed",
              "reason": "<one or two sentences>", "quote": "<the deciding words, verbatim>"}]}
```

Every item listed appears once.

## Finish

Finish when the JSON is written. No commentary outside it.
