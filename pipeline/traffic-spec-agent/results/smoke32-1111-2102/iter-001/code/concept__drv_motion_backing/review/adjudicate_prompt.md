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

`drv.motion.backing`: A road user is backing at an observation: it moves in the direction opposite to the one its body points. Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none. Not a stand-in for the gear selected: a vehicle in reverse gear that stands still or rolls forward is not backing, and one in a forward gear that rolls backwards is.


### Record

```json
{
 "concept_id": "drv.motion.backing",
 "kind": "formula",
 "contract": "A road user is backing at an observation: it moves in the direction opposite to the one its body points. Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none. Not a stand-in for the gear selected: a vehicle in reverse gear that stands still or rolls forward is not backing, and one in a forward gear that rolls backwards is.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "motion_tolerance",
   "unit": "m/s",
   "meaning": "the speed below which a sampled motion along the heading counts as none"
  }
 ],
 "elements": [
  {
   "span": "the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector)",
   "atoms": [
    "kin.velocity",
    "kin.heading"
   ],
   "concepts": [],
   "justification": "kin.velocity 'velocity vector' and kin.heading 'direction the body points': their product along the heading is negative when the body moves rearward. kin.gear is not read: its contract says it is 'Not a stand-in for: the direction of motion'."
  }
 ],
 "residues": [],
 "literals": [],
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `a` (a track).
Parameters (bounds the caller sets): `motion_tolerance` in m/s.
It holds at an observation exactly when:
((the measured `kin_velocity` of `a`, 'x' [velocity vector] times the measured `kin_heading` of `a`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown]) plus (the measured `kin_velocity` of `a`, 'y' [velocity vector] times the measured `kin_heading` of `a`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown])) is less than the negative of `motion_tolerance` (a parameter the caller sets)


| id | contract |
|---|---|
| `drv.motion.at_rest` | A road user is at rest at an observation: the observable form of a stop where one is required, "complete cessation from movement". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations. |
| `kin.heading` | direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `kin.velocity` | velocity vector |


### Items

1. (holds_wrongly) The road user points northeast and moves southwest with velocity [-0.7071066, -0.7071066] m/s. Its rearward component along the unit heading is approximately 0.999999744 m/s, below the 1 m/s motion tolerance, but the heading's micrometre-truncated normalization makes the body compute a rearward component greater than 1 m/s.
   the contract's words, per the reviewer: "Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none."
   the reviewer's verdict for the contract: fails
   the body's executed verdict at t=0 ms: holds

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `a` = track 1
- the observation judged: t = 0 ms
- parameters: `motion_tolerance` = 1 m/s

Scene t = 0 ms (the observation judged):
- track 1: kin.heading [1, 1]; kin.velocity [-0.7071066, -0.7071066]
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
