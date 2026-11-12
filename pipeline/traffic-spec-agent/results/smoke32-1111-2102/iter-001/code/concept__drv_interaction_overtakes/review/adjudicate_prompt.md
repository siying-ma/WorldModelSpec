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

`drv.interaction.overtakes`: Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of b relative to a becomes true, provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels.


### Record

```json
{
 "concept_id": "drv.interaction.overtakes",
 "kind": "formula",
 "contract": "Road user a overtakes and passes road user b: travelling with headings aligned, a goes from wholly behind b to wholly ahead of it. The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of b relative to a becomes true, provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition. Its observed beginning is the last observation at which a was behind b before the recognition. The concept holds at the recognition observation only. Where the recording shows no observation of a behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false. Not a stand-in for a lane change or for contact between the bodies; it does not say in which lane either travels.",
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
   "name": "alignment",
   "unit": "ratio",
   "meaning": "the cosine of the largest angle between the two headings counted as aligned"
  }
 ],
 "act": {
  "boundary": "event",
  "onset": "Its observed beginning is the last observation at which a was behind b before the recognition.",
  "recognition": "The act is recognized at the observation at which a becomes wholly ahead of b",
  "extent": "The concept holds at the recognition observation only.",
  "history": "Where the recording shows no observation of a behind b before a becomes wholly ahead of it, with the headings aligned at every observation since the recording began, whether a overtook b is unknown, never false."
 },
 "elements": [
  {
   "span": "drv.position.behind of b relative to a becomes true",
   "concepts": [
    "drv.position.behind"
   ],
   "atoms": [],
   "justification": "drv.position.behind states one road user wholly behind the other with aligned headings; read both ways it gives the beginning (a behind b) and the recognition (b behind a)."
  },
  {
   "span": "the headings stayed aligned (rel.same_direction with the alignment tolerance)",
   "atoms": [
    "rel.same_direction"
   ],
   "concepts": [],
   "justification": "rel.same_direction: 'headings aligned: the cosine of the angle between the headings is above its tolerance'; held at every observation from the beginning to the recognition, so an oncoming crossing is no pass."
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
Parameters (bounds the caller sets): `alignment` in ratio.
It holds at an observation exactly when:
(
  ((
    `rel_same_direction` holds of `b`, `a` at `alignment` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
    AND
    (
      `rel_bearing` holds of `b`, `a`, 'ahead' [direction of b from a in a's frame (for "on the right of", "immediately to the rear")]
      AND
      the measured `rel_longitudinal_overlap` of `b`, `a` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
    )
  )) holds now and did not hold at the previous observation
  AND
  (
    `rel_same_direction` holds of `a`, `b` at `alignment` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
    SINCE
    (
      `rel_same_direction` holds of `a`, `b` at `alignment` (a parameter the caller sets) [headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1]
      AND
      (
        `rel_bearing` holds of `a`, `b`, 'ahead' [direction of b from a in a's frame (for "on the right of", "immediately to the rear")]
        AND
        the measured `rel_longitudinal_overlap` of `a`, `b` [the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies] is less than 0 metre
      )
    )
  )
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
| `rel.bearing` | direction of b from a in a's frame (for "on the right of", "immediately to the rear") |
| `rel.longitudinal_overlap` | the bodies overlap along the subject's heading (side by side): the length the two footprints' projections on that axis share, negative for the gap between the projections; a projection, so neither a contact nor a distance between the bodies |
| `rel.same_direction` | headings aligned: the cosine of the angle between the headings is above its tolerance, which is the cosine of the largest angle allowed, a ratio between -1 and 1 |


### Items

1. (holds_wrongly) At the second observation, different but aligned headings and lateral separation make each user wholly behind the other in its own heading projection. Neither was behind the other at the earlier observation, when their headings were opposed; the body nevertheless accepts the recognition observation itself as the SINCE witness.
   the contract's words, per the reviewer: "The act is recognized at the observation at which a becomes wholly ahead of b, that is, at which drv.position.behind of b relative to a becomes true, provided that a was behind b (drv.position.behind of a relative to b) at an earlier observation and the headings stayed aligned (rel.same_direction with the alignment tolerance) at every observation from that one to the recognition."
   the reviewer's verdict for the contract: fails
   the body's executed verdict at t=1000 ms: holds

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `a` = track 1, `b` = track 2
- the observation judged: t = 1000 ms
- parameters: `alignment` = 0.5 ratio

Scene t = 0 ms:
- track 1: kin.position [0, 0]; kin.heading [1, 0]; kin.extent [1, 0.5, 0.5]
- track 2: kin.position [0, 10]; kin.heading [-1, 0]; kin.extent [1, 0.5, 0.5]
- occupancy derived from the geometry before running: none
Scene t = 1000 ms (the observation judged):
- track 1: kin.position [0, 0]; kin.heading [1, 0]; kin.extent [1, 0.5, 0.5]
- track 2: kin.position [10, 30]; kin.heading [1, -1]; kin.extent [1, 0.5, 0.5]
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
