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

`drv.motion.backing`: A road user moves backwards at the observation: the component of its velocity (kin.velocity) along the direction it points (kin.heading) is below minus `tol`, a tolerance that names only the source's speed resolution. Not denoted: the gear selected, since a vehicle in reverse gear standing still is not backing and one rolling backwards in a forward gear is; motion across the direction it points, such as a sideways slide; a road user standing still.


### Record

```json
{
 "concept_id": "drv.motion.backing",
 "kind": "formula",
 "contract": "A road user moves backwards at the observation: the component of its velocity (kin.velocity) along the direction it points (kin.heading) is below minus `tol`, a tolerance that names only the source's speed resolution. Not denoted: the gear selected, since a vehicle in reverse gear standing still is not backing and one rolling backwards in a forward gear is; motion across the direction it points, such as a sideways slide; a road user standing still.",
 "args": [
  {
   "name": "x",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "tol",
   "unit": "m/s",
   "meaning": "The source's speed resolution: a backward component at or below it in magnitude counts as none."
  }
 ],
 "elements": [
  {
   "span": "the component of its velocity (kin.velocity)",
   "atoms": [
    "kin.velocity"
   ],
   "concepts": [],
   "justification": "kin.velocity: 'velocity vector', m/s, world frame; its dot product with the heading is the signed motion along the body's axis."
  },
  {
   "span": "the direction it points (kin.heading)",
   "atoms": [
    "kin.heading"
   ],
   "concepts": [],
   "justification": "kin.heading: 'direction the body points', a unit vector read normalised; a zero vector reads unknown."
  }
 ],
 "residues": [],
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `x` (a track).
Parameters (bounds the caller sets): `tol` in m/s.
It holds at an observation exactly when:
((the measured `kin_velocity` of `x`, 'x' [velocity vector] times the measured `kin_heading` of `x`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown]) plus (the measured `kin_velocity` of `x`, 'y' [velocity vector] times the measured `kin_heading` of `x`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown])) is less than the negative of `tol` (a parameter the caller sets)


| id | contract |
|---|---|
| `drv.motion.moving` | A road user is in motion at the observation: the magnitude of its velocity (kin.speed) exceeds `tol`, a tolerance that names only the source's speed resolution, below which a reading counts as standing still. It denotes motion in any direction, forwards or backwards, whoever or whatever controls the road user. Not denoted: the direction of motion; a halt held over a window, since the concept reads the one observation. |
| `drv.motion.stopped` | A road user is at a complete halt at the observation: the definition's "complete cessation from movement", observed as the magnitude of its velocity (kin.speed) at or below `tol`, a tolerance that names only the source's speed resolution, below which a sampled speed counts as no movement. It denotes the halt whoever or whatever controls the road user. Not denoted: a halt held over a window, since the concept reads the one observation; where the road user halts, which the caller states. |
| `drv.motion.turning` | A road user's heading is changing at the observation: the magnitude of its yaw rate (kin.yaw_rate) exceeds `tol`, a tolerance that names only the source's yaw-rate resolution, to either hand and whether the road user moves forwards or backwards. Not denoted: the curvature of the road, which the concept does not read; a completed turn or the angle turned; the hand of the turn. |
| `kin.heading` | direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `kin.velocity` | velocity vector |


### Items

1. (holds_wrongly) The road user points along [5,12] and has velocity [-0.2,-1] m/s, giving an exact backward component of 1 m/s, equal to tol. Truncating the scaled heading's length from 13/12 to 1.083333 makes the body compute a backward component of 3250000/3249999 m/s, exceeding tol.
   the contract's words, per the reviewer: "A road user moves backwards at the observation: the component of its velocity (kin.velocity) along the direction it points (kin.heading) is below minus `tol`, a tolerance that names only the source's speed resolution."
   the reviewer's verdict for the contract: fails
   the body's executed verdict at t=0 ms: holds

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `x` = track 1
- the observation judged: t = 0 ms
- parameters: `tol` = 1 m/s

Scene t = 0 ms (the observation judged):
- track 1: kin.heading [5, 12]; kin.velocity [-0.2, -1]
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
