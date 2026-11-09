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

`drv.interaction.following`: Road user a is following road user b at the observation: b is ahead of a in the same lane along that lane's direction of travel, and the two bodies' headings are aligned within the same-direction tolerance, a cosine the caller sets. It is a relation of place and direction at the observation; it states no gap, no speed, no duration and no intention. Not a stand-in for: the size of the space between the two — a caller that bounds a space reads the gap atom itself — overtaking or passing, two road users abreast in neighbouring lanes, or a towed combination, which is one road user drawn by another.


### Record

```json
{
 "concept_id": "drv.interaction.following",
 "kind": "formula",
 "contract": "Road user a is following road user b at the observation: b is ahead of a in the same lane along that lane's direction of travel, and the two bodies' headings are aligned within the same-direction tolerance, a cosine the caller sets. It is a relation of place and direction at the observation; it states no gap, no speed, no duration and no intention. Not a stand-in for: the size of the space between the two — a caller that bounds a space reads the gap atom itself — overtaking or passing, two road users abreast in neighbouring lanes, or a towed combination, which is one road user drawn by another.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  },
  {
   "name": "b",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "same_direction_tolerance",
   "unit": "ratio",
   "meaning": "the cosine of the largest angle between the two headings still read as the same direction, a ratio between minus one and one"
  }
 ],
 "elements": [
  {
   "span": "b is ahead of a in the same lane along that lane's direction of travel",
   "atoms": [
    "rel.ahead_behind_in_lane"
   ],
   "concepts": [],
   "justification": "rel.ahead_behind_in_lane is “a is ahead of / behind b in the same lane, along the lane direction”, which is exactly the ordering and the frame this contract states; no other atom carries an in-lane order, rel.bearing giving only a direction in the subject's frame."
  },
  {
   "span": "the two bodies' headings are aligned within the same-direction tolerance",
   "atoms": [
    "rel.same_direction"
   ],
   "concepts": [],
   "justification": "rel.same_direction is “headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1”; the tolerance is the atom's own parameter, which this concept exposes as its formal parameter."
  }
 ],
 "residues": [],
 "literals": [],
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `a` (a track), `b` (a track).
Parameters (bounds the caller sets): `same_direction_tolerance` in ratio.
It holds at an observation exactly when:
(
  `rel_ahead_behind_in_lane` holds of `b`, `a` [a is ahead of / behind b in the same lane, along the lane direction]
  AND
  `rel_same_direction` holds of `a`, `b` at `same_direction_tolerance` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
)


| id | contract |
|---|---|
| `drv.motion.region_entry` | The road user's footprint comes to overlap a structure region at the observation: it overlaps the region at the observation and did not overlap it at the observation before. The concept is the event of that coming to overlap, read at the observation at which the overlap has begun, and not the state of lying inside the region afterwards. It states no direction of entry, no carrier the road user came through, no speed and no place within the region. Not a stand-in for: lying within the region, which the occupancy relation carries on its own; a later observation at which the road user is still inside; the carrier or the way the road user came from, which a caller reads with its own relations; a crossing of a boundary the source represents by no region; or a leaving of the region. |
| `drv.motion.region_exit` | The road user's footprint ceases to overlap a structure region at the observation: it does not overlap the region at the observation and did overlap it at the observation before. The concept is the event of that ceasing to overlap, read at the observation at which the overlap has ended, and not the state of lying outside the region at the later observations. It states no direction of departure, no carrier the road user leaves through, no speed and no place outside the region. Not a stand-in for: lying outside the region, which the occupancy relation carries on its own; a later observation at which the road user is still outside; the carrier or the way the road user goes on to, which a caller reads with its own relations; a crossing of a boundary the source represents by no region; or an entry into the region, which has its own concept. |
| `drv.motion.standstill` | The road user is motionless at the observation: the magnitude of its velocity is at most the speed tolerance, a speed the caller sets, so that a sampled reading at or below it is read as no movement at all. The definition this contract carries requires a “complete cessation from movement”, and because speed is sampled and measured with error, the tolerance is the bound within which a reading is read as that cessation; it is the contract's own magnitude and never a figure. The concept states the motion state at the observation and nothing else. Not a stand-in for: a halt of any duration or a halt repeated over a window, a vehicle standing, parked or waiting, the engine being off or a brake being applied, or a halt at a place a law names — it carries no place, no duration and no control state. |
| `drv.motion.turning` | The road user's heading is changing at the observation: the magnitude of its heading change over the window behind the observation is at least the heading change tolerance, a size the caller sets at the resolution of the source. It is a state the road user is in at each observation of a bending path, in either hand, and it states no direction, no angle reached, no beginning and no place. Not a stand-in for: a completed turn or a manoeuvre recognized from an observed onset — which counts the heading change from that onset and not over a window — a steering input, the curvature of the road, a lane change, or a signal or an intention. |
| `drv.position.direction_component` | The component, in metres per second, of a road user's velocity along the designated direction of travel of a structure region: positive where the road user moves with that direction, negative where it moves against it, and near zero where it stands or moves across it. The region's direction is read normalised, as its atom states, so the value is a speed along that direction. The quantity is geometric only: it does not state that the road user is on the region, that the region is the one a law names, or how far the road user is from it, and a caller states those with its own relations. Unknown where the road user's velocity is absent and where the region carries no designated direction — a centre turn lane carries none, and a place no carrier covers has none. Not a stand-in for: the direction the body points, which a road user may hold while moving another way, the road user's speed, which is unsigned, or an angle between the two directions. |
| `rel.ahead_behind_in_lane` | a is ahead of / behind b in the same lane, along the lane direction |
| `rel.same_direction` | headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1 |


### Items

1. (fails_wrongly) Both road users occupy the same eastbound lane, with b ahead of a and their headings identical. At the admissible cosine tolerance 1, their zero heading difference is within the allowed angle, but the body fails.
   the contract's words, per the reviewer: "Road user a is following road user b at the observation: b is ahead of a in the same lane along that lane's direction of travel, and the two bodies' headings are aligned within the same-direction tolerance, a cosine the caller sets."
   the reviewer's verdict for the contract: holds
   the body's executed verdict at t=0 ms: fails

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `a` = track 1, `b` = track 2
- the observation judged: t = 0 ms
- parameters: `same_direction_tolerance` = 1 ratio

Scene t = 0 ms (the observation judged):
- track 1: kin.position [0, 0]; kin.heading [1, 0]; kin.extent [2, 1, 1]
- track 2: kin.position [10, 0]; kin.heading [1, 0]; kin.extent [2, 1, 1]
- structure 1: kind "lane"; boundary [[-5, -3], [15, -3], [15, 3], [-5, 3]]; lane.direction [1, 0]
- occupancy_observed: true
- occupancy derived from the geometry before running: 1-1, 2-1



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
