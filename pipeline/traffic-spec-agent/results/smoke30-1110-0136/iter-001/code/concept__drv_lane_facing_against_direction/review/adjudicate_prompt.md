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

`drv.lane.facing_against_direction`: A road user points against the designated direction of travel of a carrier at the observation: the cosine of the angle between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), read as the dot product of the two normalised vectors, is below minus `cos_tol`, the cosine of the largest angle off exactly opposed that still counts as against. Not denoted: occupancy of the carrier, which the caller states; the direction of motion, since a vehicle pointing against the direction points against it whether it moves forwards or backs; travel across the carrier, with headings near perpendicular to it; a carrier with no designated direction, for which the concept is unknown.


### Record

```json
{
 "concept_id": "drv.lane.facing_against_direction",
 "kind": "formula",
 "contract": "A road user points against the designated direction of travel of a carrier at the observation: the cosine of the angle between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), read as the dot product of the two normalised vectors, is below minus `cos_tol`, the cosine of the largest angle off exactly opposed that still counts as against. Not denoted: occupancy of the carrier, which the caller states; the direction of motion, since a vehicle pointing against the direction points against it whether it moves forwards or backs; travel across the carrier, with headings near perpendicular to it; a carrier with no designated direction, for which the concept is unknown.",
 "args": [
  {
   "name": "x",
   "sort": "track"
  },
  {
   "name": "c",
   "sort": "region"
  }
 ],
 "params": [
  {
   "name": "cos_tol",
   "unit": "ratio",
   "meaning": "Cosine of the largest angle off exactly opposed at which a heading still points against the direction."
  }
 ],
 "elements": [
  {
   "span": "its heading (kin.heading)",
   "atoms": [
    "kin.heading"
   ],
   "concepts": [],
   "justification": "kin.heading: 'direction the body points', read normalised."
  },
  {
   "span": "the carrier's designated direction (st.lane_direction)",
   "atoms": [
    "st.lane_direction"
   ],
   "concepts": [],
   "justification": "st.lane_direction: 'direction of travel designated for a structure a vehicle travels in — a lane ... or a roadway, one-way roadway or shoulder', read normalised; a place no carrier covers has none (unknown)."
  }
 ],
 "residues": [],
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `x` (a track), `c` (a region).
Parameters (bounds the caller sets): `cos_tol` in ratio.
It holds at an observation exactly when:
((the measured `kin_heading` of `x`, 'x' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times the measured `st_lane_direction` of `c`, 'x' [direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown]) plus (the measured `kin_heading` of `x`, 'y' [direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown] times the measured `st_lane_direction` of `c`, 'y' [direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown])) is less than the negative of `cos_tol` (a parameter the caller sets)


| id | contract |
|---|---|
| `drv.motion.moving` | A road user is in motion at the observation: the magnitude of its velocity (kin.speed) exceeds `tol`, a tolerance that names only the source's speed resolution, below which a reading counts as standing still. It denotes motion in any direction, forwards or backwards, whoever or whatever controls the road user. Not denoted: the direction of motion; a halt held over a window, since the concept reads the one observation. |
| `kin.heading` | direction the body points; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |
| `st.lane_direction` | direction of travel designated for a structure a vehicle travels in — a lane, reserved lane, turn lane, bicycle lane or path, or a roadway, one-way roadway or shoulder; a centre turn lane carries none. The direction is local to its carrier (a bend or a loop is written as segments), carriers that overlap or cross may carry different directions, and a place no carrier covers has none (unknown). It is written at any length; a formula reads it normalised: divided by its larger absolute component, then by its length taken to a micrometre, so the vector read is the unit vector times a factor of at least 1 and below 1 + 2·10⁻⁶ (exactly the unit vector where that scaled length is a whole number of micrometres, as for an axis-aligned direction); a zero vector reads unknown |


### Items

1. (holds_wrongly) The heading is [-7,-1] and the carrier direction is [1,1], so their exact cosine is -8/sqrt(50·2) = -0.8. With cos_tol = 0.8 the strict comparison must fail, but the formula's truncated vector lengths inflate the negative dot product past the threshold.
   the contract's words, per the reviewer: "the cosine of the angle between its heading (kin.heading) and the carrier's designated direction (st.lane_direction), read as the dot product of the two normalised vectors, is below minus `cos_tol`"
   the reviewer's verdict for the contract: fails
   the body's executed verdict at t=0 ms: holds

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `x` = track 1
- regions: `c` = region 1 (lane)
- the observation judged: t = 0 ms
- parameters: `cos_tol` = 0.8 ratio

Scene t = 0 ms (the observation judged):
- track 1: kin.heading [-7, -1]
- structure 1: kind "lane"; lane.direction [1, 1]
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
