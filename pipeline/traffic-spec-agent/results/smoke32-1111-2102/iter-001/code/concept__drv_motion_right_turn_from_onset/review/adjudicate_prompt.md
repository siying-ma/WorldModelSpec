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

`drv.motion.right_turn_from_onset`: Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle.


### Record

```json
{
 "concept_id": "drv.motion.right_turn_from_onset",
 "kind": "formula",
 "contract": "Road user a turns to the right from an observed onset: over one continuous stretch in which it moves and its heading turns to the right, its heading changes to the right by at least the turn angle, the heading change below which turning counts as no change of course. Measured as drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true, and the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound, the largest interval between consecutive observations integrated across) at or below the negative of the turn angle. The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle. The concept holds at the recognition observation only. Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown. A stretch that ends before its heading change reaches the negative of the turn angle is no turn; a road user that follows a bend of the way through that angle turns in this sense. Not a stand-in for the turn indicator or a declared intention to turn, nor for a lane change, whose heading change stays short of the turn angle.",
 "args": [
  {
   "name": "a",
   "sort": "track"
  }
 ],
 "params": [
  {
   "name": "turn_angle",
   "unit": "deg",
   "meaning": "the heading change below which turning counts as no change of course"
  },
  {
   "name": "yaw_tolerance",
   "unit": "deg/s",
   "meaning": "the yaw rate magnitude below which a change of heading counts as none"
  },
  {
   "name": "speed_tolerance",
   "unit": "m/s",
   "meaning": "the speed at or below which the road user counts as at rest"
  },
  {
   "name": "step",
   "unit": "ms",
   "meaning": "the step bound of the heading integration"
  }
 ],
 "act": {
  "boundary": "event",
  "onset": "The act's observed beginning is the observation at which drv.motion.turning_right last became true.",
  "recognition": "The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle.",
  "extent": "The concept holds at the recognition observation only.",
  "history": "Conduct before the observed beginning is no part of the act, and where that beginning is not observed (the stretch began before the recording, or an unknown turning state could hide its start) whether the act occurred is unknown."
 },
 "elements": [
  {
   "span": "drv.motion.turning_right (with the yaw tolerance and the speed tolerance) holding at every observation since the observation at which it last became true",
   "atoms": [],
   "concepts": [
    "drv.motion.turning_right"
   ],
   "justification": "drv.motion.turning_right is the state 'it moves and its heading turns to the right' at each observation; its last rise is the onset and its holding since is the continuous stretch."
  },
  {
   "span": "the heading change since that observation (integrated from kin.yaw_rate, degrees, left positive, with the step bound",
   "atoms": [
    "kin.yaw_rate"
   ],
   "concepts": [],
   "justification": "kin.yaw_rate, 'positive when the heading turns to the left', integrated since the onset (Term.headingSince with the step bound): a right turn is a negative heading change; 'Not a stand-in for: road curvature' is stated in the contract."
  }
 ],
 "residues": [],
 "literals": [],
 "differs_from": {
  "concept": "drv.motion.left_turn_from_onset",
  "why": "the opposite hand: a rightward stretch and a negative heading change"
 },
 "narrowings_by_the_coder": []
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `a` (a track).
Parameters (bounds the caller sets): `turn_angle` in deg, `yaw_tolerance` in deg/s, `speed_tolerance` in m/s, `step` in ms.
It holds at an observation exactly when:
(
  (
    it is not the case that (the measured `kin_speed` of `a` [magnitude of velocity] is at most `speed_tolerance` (a parameter the caller sets))
    AND
    the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at most the negative of `yaw_tolerance` (a parameter the caller sets)
  )
  AND
  (the heading change of `a` since ((
  it is not the case that (the measured `kin_speed` of `a` [magnitude of velocity] is at most `speed_tolerance` (a parameter the caller sets))
  AND
  the measured `kin_yaw_rate` of `a` [rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres] is at most the negative of `yaw_tolerance` (a parameter the caller sets)
)) last became true, integrated with steps of at most `step` (a parameter the caller sets) is at most the negative of `turn_angle` (a parameter the caller sets)) holds now and did not hold at the previous observation
)


| id | contract |
|---|---|
| `drv.motion.at_rest` | A road user is at rest at an observation: the observable form of a stop where one is required, "complete cessation from movement". It holds at each observation at which the road user's speed (kin.speed, m/s) is at or below the speed tolerance, the speed at or below which a sampled measurement counts as no movement, and at no other. Not a stand-in for the brake lamp or the brake input, which are actuations and not motion, or for a halt at a particular place, which a caller states with its own relations. |
| `drv.motion.backing` | A road user is backing at an observation: it moves in the direction opposite to the one its body points. Measured as the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, unit vector) lying below the negative of the motion tolerance, the speed below which a sampled motion counts as none. Not a stand-in for the gear selected: a vehicle in reverse gear that stands still or rolls forward is not backing, and one in a forward gear that rolls backwards is. |
| `drv.motion.decelerating` | Road user a is decelerating at an observation: its forward speed is falling. Measured as its acceleration along its heading (kin.accel_longitudinal, m/s², signed) at or below the negative of the deceleration tolerance, the magnitude below which a sampled acceleration counts as none, while a is not backing (drv.motion.backing with the speed tolerance does not hold), since for a backing road user a negative value is a gain of speed. Not a stand-in for its speed or for the brake lamp: a lit lamp without a deceleration is no deceleration. |
| `drv.motion.heading_change_since_entry` | The heading change of road user a since it entered region r: the signed change of the direction its body points (degrees, left positive), accumulated from the observation at which a's footprint last came to overlap r, where it is zero, to the observation, whether or not a still overlaps r. Measured by integrating a's yaw rate (kin.yaw_rate, deg/s, left positive) from the observation at which a's occupancy of r (rel.occupies) last became true, with the step bound, the largest interval between consecutive observations integrated across. It is unknown where that entry is not observed (a occupied r from the start of the recording, or an unknown occupancy could hide the entry), where an interval between consecutive observations since the observation before the entry exceeds the step bound, or where a yaw rate since the entry is missing. Not a stand-in for a turn: it is a magnitude that a caller bounds, and a road user that follows a bend of the way through r accumulates the bend's heading change. |
| `drv.motion.left_turn` | Road user a makes a left turn: within the window behind the observation its heading turns to the left by an angle within the turn band, from the lower bound, below which a heading change counts as no turn, up to the upper bound, above which the road user's direction counts as reversed. Measured as the signed heading change over the window (prim.heading_change, degrees, left positive) at or above the lower bound and at or below the upper bound. The act is recognized at the observation at which the heading change over the window first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the heading change over the window lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for the turn indicator or for a declared intention to turn. |
| `drv.motion.stopping_distance` | The distance road user a would travel before coming to rest if it began to brake after a reaction time, at the observation: its speed (kin.speed, m/s) times the reaction time, plus the square of its speed divided by twice the deceleration (m). Computed from the current speed only, under a constant deceleration on a level road. Not a stand-in for a sight distance or a gap to another road user, which a caller compares it with, nor for a braking manoeuvre actually made. |
| `drv.motion.turning_left` | Road user a is turning to the left at an observation: it moves and its heading turns to the left. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or above the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the left. Not a stand-in for the turn indicator or for a declared intention to turn. |
| `drv.motion.turning_right` | Road user a is turning to the right at an observation: it moves and its heading turns to the right. Measured as a not at rest (drv.motion.at_rest with the speed tolerance does not hold) and its yaw rate (kin.yaw_rate, deg/s, left positive) at or below the negative of the yaw tolerance, the rate below which a change of heading counts as none. A state at each observation while a turn is under way, not a completed manoeuvre: it does not say how far the turn goes, and it holds alike where the road user follows a bend of the road to the right. Not a stand-in for the turn indicator or for a declared intention to turn. |
| `drv.motion.u_turn` | Road user a makes a U-turn: "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not". Observed as a heading change within the window behind the observation, to either hand, whose magnitude lies within the reversal band: from the lower bound, at or beyond which the road user's direction counts as reversed, up to the upper bound, beyond which it has turned past the opposite direction. Measured as the magnitude of the signed heading change over the window (prim.heading_change, degrees). The window admits a turn made in several movements, forward and reverse. The act is recognized at the observation at which the magnitude first reaches the lower bound. Its observed beginning lies within the window behind that observation. The concept holds at every observation at which the magnitude lies within the band, and ends where it leaves the band. It is unknown where the window reaches past the start of the recording or a yaw rate in it is missing. Not a stand-in for backing: a reversal of travel without a change of heading is no U-turn. |
| `drv.position.behind` | Road user a is behind road user b at an observation: their headings are aligned and b's body lies wholly ahead of a's along a's heading. Measured as headings aligned (rel.same_direction with the alignment tolerance, the cosine of the largest angle between the headings counted as aligned), the bearing of b from a (rel.bearing) pointing forward in a's frame, and the two footprints' projections on a's heading sharing no length (rel.longitudinal_overlap below zero). Either road user may be at rest. Not a stand-in for following in the same lane: b may travel in another lane. |
| `drv.position.near_region` | Road user a is at region r at an observation: r lies within the reach of a's body, the distance within which a region counts as the place the road user is at. Measured as the ground distance from a's body outline to r (st.region_geometry, m; zero when they overlap) at or below the reach. Not a stand-in for occupancy: a body within the reach may lie wholly outside the region. |
| `kin.speed` | magnitude of velocity |
| `kin.time` | instant of observation of a scene |
| `kin.yaw_rate` | rate of change of heading, positive when the heading turns to the left (counter-clockwise) **Not a stand-in for:** road curvature — a vehicle yaws on a straight road whenever it manoeuvres |


### Items

1. (fails_wrongly) With turn_angle set to zero, a second observed right-turn onset is itself a recognition observation. The body misses it because the heading-change comparison was already true at the intervening non-turning observation.
   the contract's words, per the reviewer: "The act's observed beginning is the observation at which drv.motion.turning_right last became true. The act is recognized at the observation at which the heading change since that beginning first reaches the negative of the turn angle. The concept holds at the recognition observation only."
   the reviewer's verdict for the contract: holds
   the body's executed verdict at t=750 ms: fails

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `a` = track 1
- the observation judged: t = 750 ms
- parameters: `turn_angle` = 0 deg, `yaw_tolerance` = 1 deg/s, `speed_tolerance` = 0.1 m/s, `step` = 500 ms

Scene t = 0 ms:
- track 1: kin.speed 5; kin.yaw_rate 0
- occupancy derived from the geometry before running: none
Scene t = 250 ms:
- track 1: kin.speed 5; kin.yaw_rate -20
- occupancy derived from the geometry before running: none
Scene t = 500 ms:
- track 1: kin.speed 5; kin.yaw_rate 0
- occupancy derived from the geometry before running: none
Scene t = 750 ms (the observation judged):
- track 1: kin.speed 5; kin.yaw_rate -20
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
