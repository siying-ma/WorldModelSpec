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

`drv.motion.left_turn`: Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.


### Record

```json
{
 "concept_id": "drv.motion.left_turn",
 "kind": "formula",
 "contract": "Road user a has completed a turn to the left. Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive, so that a heading change too small to be a turn and a reversal of direction both lie outside it. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a turn that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the lane, the intersection or the way on which a turns, of its speed, or of why it turns. Not denoted: a heading change to the left smaller than turn_min, such as a lane change or a drift; a heading change of u_turn_min or more, which is a reversal of direction; a turn to the right; a turn still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "window",
   "unit": "s",
   "meaning": "the length of the window behind the observation over which the heading change is integrated: the longest duration of a turn"
  },
  {
   "name": "turn_min",
   "unit": "deg",
   "meaning": "the smallest heading change that is a turn"
  },
  {
   "name": "u_turn_min",
   "unit": "deg",
   "meaning": "the smallest heading change that is a reversal of direction, which bounds the band of a turn from above"
  },
  {
   "name": "yaw_tol",
   "unit": "deg/s",
   "meaning": "the yaw-rate magnitude at or below which the heading counts as no longer turning: the source's yaw-rate resolution"
  }
 ],
 "act": {
  "boundary": "window",
  "window": "window",
  "onset": "The act begins within the window behind the observation at which it is recognized.",
  "recognition": "The act is recognized at the observation at which the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning.",
  "extent": "The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again.",
  "history": "Conduct before the window behind is not read: a turn that takes longer than the window is not recognized."
 },
 "elements": [
  {
   "span": "Its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from turn_min inclusive to u_turn_min exclusive",
   "atoms": [
    "prim.heading_change"
   ],
   "concepts": [],
   "justification": "prim.heading_change is 'the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from kin.yaw_rate; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing'; a positive value in the band from turn_min to u_turn_min is a turn to the left, and a negative value, a turn to the right, lies outside it."
  },
  {
   "span": "a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude",
   "atoms": [
    "kin.yaw_rate"
   ],
   "concepts": [],
   "justification": "kin.yaw_rate is the 'rate of change of heading, positive when the heading turns to the left (counter-clockwise)'; at or below the tolerance in magnitude the heading has stopped turning, which marks the turn complete. It is not read as road curvature, its exclusion: it is the road user's own heading change."
  }
 ],
 "residues": [],
 "literals": [],
 "differs_from": {
  "concept": "drv.motion.u_turn",
  "why": "drv.motion.u_turn denotes a reversal of direction to either hand: the magnitude of the heading change lies from u_turn_min to 360 degrees minus u_turn_min. This concept denotes a turn to the left only: the signed heading change, left positive, lies from turn_min inclusive to u_turn_min exclusive, so a reversal, which u_turn denotes, and a turn to the right are excluded here, and a left turn short of a reversal, which this concept denotes, is excluded from u_turn. The two notions are disjoint and neither can be stated through the other."
 },
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `a` (a track).
Parameters (bounds the caller sets): `window` in s, `turn_min` in deg, `u_turn_min` in deg, `yaw_tol` in deg/s.
It holds at an observation exactly when:
((
  (
    the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is at least `turn_min` (a parameter the caller sets)
    AND
    the primitive `prim_heading_change` of `a` with `window` (a parameter the caller sets) [the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing] is less than `u_turn_min` (a parameter the caller sets)
  )
  AND
  the absolute value of the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at most `yaw_tol` (a parameter the caller sets)
)) holds now and did not hold at the previous observation


| id | contract |
|---|---|
| `drv.lane.heading_right_of_carrier` | Road user a, moving, points to the right of the designated direction of travel of carrier region r by more than a tolerance: its heading has turned off r's direction toward the right. With h a's heading (kin.heading) and d r's designated direction (st.lane_direction), both as a formula reads them normalised, the dot product of d and h is positive, so that a points along d rather than against it, and the cross product d_x times h_y minus d_y times h_x is below minus sin_tol, so that h lies to the right of d, clockwise in the world frame, by more than the angle whose sine is sin_tol; and a's speed (kin.speed) is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of how long its heading has been so, of the path a will follow, or of why it turns. Not denoted: a road user at rest or moving at or below speed_tol; a heading within that angle of d, or turned to its left; a heading that points against d, the dot product being at or below zero. Where r carries no designated direction, or a's heading or speed is unobserved, it is unknown. |
| `drv.motion.circulating_clockwise_about` | Road user a travels clockwise about the reference point of region r, as seen from above: the point lies to the right of a's direction of travel and a's velocity turns about it clockwise. It is observed with a's position (kin.position), a's velocity (kin.velocity), a's speed (kin.speed) and r's reference point (st.region_geometry), in the world frame, in which a turn to the left is counter-clockwise (the frame of kin.yaw_rate): with d the vector from r's reference point to a's position, the cross product of d with a's velocity is negative, and its square exceeds sin_tol squared times the squared length of d times the square of a's speed, so that the share of a's motion that turns about the point is above sin_tol; and a's speed is above speed_tol. It is a state at one observation: it says nothing of whether a occupies r, of the path a followed before, or of why a moves so. Not denoted: a road user at rest or moving at or below speed_tol; one travelling counter-clockwise about the point; one moving towards or away from the point within the angle sin_tol allows; one at the point itself. Where r's reference point, a's position or a's velocity is unobserved, it is unknown. |
| `drv.motion.complete_halt` | The road user is at rest at the observation — "complete cessation from movement" — observed as its speed (kin.speed) at or below a tolerance the caller sets for the source's speed resolution. It denotes a state at one observation: it says nothing of how long the road user stays at rest, where it is, or why. Not denoted: a slowing whose sampled speed stays above the tolerance. |
| `drv.motion.moving_across_carrier` | Road user a moves across the designated direction of travel of carrier region r: a is moving, its speed (kin.speed) above speed_tol, and its velocity (kin.velocity) makes with r's designated direction (st.lane_direction) an angle whose cosine, in absolute value, is at most cos_max: the absolute value of the dot product of the velocity with the normalised direction is at most cos_max times the speed. Either sense of crossing is denoted: the sign of the direction does not matter. It is a state at one observation: it says nothing of whether a occupies r, of where a began or will end its movement, or of how long it has moved so. Not denoted: a road user at rest or moving at or below speed_tol; a road user moving more nearly along r's direction than cos_max allows. Where r carries no designated direction, or a's velocity is not observed, it is unknown. |
| `drv.motion.moving_against_carrier` | Road user a moves against the designated direction of travel of carrier region r: part of its motion runs opposite to r's designated direction. It is observed as the component of a's velocity (kin.velocity) along r's designated direction (st.lane_direction), the dot product of the velocity with the direction as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against r's direction exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of whether a occupies r, of where a's body points, of the gear selected, of how long a has moved so, or of why. Not denoted: a road user at rest; one whose velocity component against r's direction is at or below speed_tol, such as one moving along r's direction or straight across it. Where r carries no designated direction, or a's velocity is unobserved, it is unknown. |
| `drv.motion.moving_backward` | Road user a is moving backward: it moves against the direction its body points. It is observed as the component of a's velocity (kin.velocity) along a's heading (kin.heading), the dot product of the velocity with the heading as a formula reads it normalised, being below minus speed_tol: the part of a's motion that runs against its heading exceeds the speed the source cannot tell from rest. It is a state at one observation: it says nothing of the gear selected, of the path a has followed or will follow, of where a is, or of why it moves so. Not denoted: a road user at rest, or one whose velocity component against its heading is at or below speed_tol; a road user moving forward. Where a's velocity or heading is unobserved, it is unknown. |
| `drv.motion.right_turn_through_region` | Road user a has made a turn to the right through region r, recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from minus u_turn_min exclusive to minus turn_min inclusive: a turn to the right by at least turn_min and by less than u_turn_min, so that a passage whose heading changes too little to be a turn and a reversal of direction both lie outside it. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change is above minus turn_min, such as one straight through or a turn to the left; a heading change of minus u_turn_min or less, which is a reversal of direction; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |
| `drv.motion.u_turn` | Road user a has turned "so as to proceed in the opposite direction": its heading has reversed, "whether accomplished by one continuous movement or not". The magnitude of its heading change over the window behind the observation (prim.heading_change over a window of length window, degrees, positive to the left) lies in the band from u_turn_min to 360 degrees minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them, is denoted where its integrated heading change lies in the band. The act begins within the window behind the observation at which it is recognized. The act is recognized at the observation at which the magnitude of the heading change over the window behind lies in that band and a's yaw rate (kin.yaw_rate) is at most yaw_tol in magnitude, where this did not hold at the previous observation: the heading has stopped turning. The concept holds at that observation only, and not again until that condition has ceased to hold and then holds again. Conduct before the window behind is not read: a reversal that takes longer than the window is not recognized. It denotes the change of a's heading only: it says nothing of the way on which a turns, of its class, of its speed, or of why it turns. Not denoted: a heading change smaller than u_turn_min, such as a turn to the left or the right; a full loop, whose heading change exceeds 360 degrees minus u_turn_min; a reversal still under way, whose yaw rate exceeds yaw_tol. Where the window is truncated or a yaw rate in it is missing, it is unknown. |
| `drv.motion.u_turn_through_region` | Road user a has turned "so as to proceed in the opposite direction" through region r, "whether accomplished by one continuous movement or not", recognized as it leaves r. The act begins at the observation at which a's footprint came to overlap r (rel.occupies), having not overlapped it at the previous observation: its entry into r. The act is recognized at the observation at which a's footprint does not overlap r, having overlapped it at the previous observation: its exit from r. The concept holds at that observation only, and not again until a has entered r again and left it. At that observation the magnitude of the heading change of a since its entry into r, in degrees and positive to the left, integrated from its yaw rate (kin.yaw_rate) with no interval between consecutive observations longer than step, lies in the band from u_turn_min to a full turn minus u_turn_min, both inclusive, so that a turn short of a reversal and a full loop both lie outside it; a reversal to either hand is denoted, and one made in several movements, with halts or backing between them inside r, is denoted where its integrated heading change lies in the band. Conduct before the entry is not read. It denotes the change of a's heading between its entry into r and its exit only: it says nothing of the lanes a uses, of its speed, of its class, or of why it turns. Not denoted: a passage through r whose heading change magnitude is below u_turn_min, such as a turn to the left or the right or a passage straight through; a heading change magnitude above a full turn minus u_turn_min, which is a loop; an observation at which a is still in r. Where the entry was not observed (it lies before the recording, or a's overlap with r was unknown at an observation since), where an interval between consecutive observations since the observation before the entry is longer than step, or where a yaw rate since the entry is missing, it is unknown. |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |
| `prim.heading_change` | the signed heading change (degrees, left positive) of a road user over the window behind the observation, integrated from `kin.yaw_rate`; unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing |


### Items

1. (holds_wrongly) A continuous leftward turn is already under way at t=0 and is still under way at t=4000 ms; the first stopped observation is t=6000 ms. The act began before the four-second window behind that observation, but the body recognizes the in-band remainder of the turn.
   the contract's words, per the reviewer: "The act begins within the window behind the observation at which it is recognized."
   the reviewer's verdict for the contract: fails
   the body's executed verdict at t=6000 ms: holds

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `a` = track 1
- the observation judged: t = 6000 ms
- parameters: `window` = 4 s, `turn_min` = 45 deg, `u_turn_min` = 135 deg, `yaw_tol` = 1 deg/s

Scene t = 0 ms:
- track 1: kin.yaw_rate 30
- occupancy derived from the geometry before running: none
Scene t = 2000 ms:
- track 1: kin.yaw_rate 30
- occupancy derived from the geometry before running: none
Scene t = 4000 ms:
- track 1: kin.yaw_rate 30
- occupancy derived from the geometry before running: none
Scene t = 6000 ms (the observation judged):
- track 1: kin.yaw_rate 0
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
