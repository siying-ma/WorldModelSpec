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

`drv.position.within_clearance_since_entry`: Road user x has entered structure region r and has not since stood clear of it by clearance: x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before) at the observation or at an earlier one, and at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance. It becomes true at an entry, holds while x stays on r or within clearance of it, becomes false at the first observation at which x's body stands at clearance or more from r, and stays false until x's next entry. Unknown where it is undecided whether x entered r at an observation since which the distance stayed below clearance (at x's first observation, whether it entered there is unknown), or where the distance is unobserved at an observation that decides it. Not denoted: the side of r on which the body stands (a body that backs out of r and stays within clearance of it still holds), x's direction or speed, or a halt: the caller reads those.


### Record

```json
{
 "concept_id": "drv.position.within_clearance_since_entry",
 "kind": "formula",
 "contract": "Road user x has entered structure region r and has not since stood clear of it by clearance: x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before) at the observation or at an earlier one, and at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance. It becomes true at an entry, holds while x stays on r or within clearance of it, becomes false at the first observation at which x's body stands at clearance or more from r, and stays false until x's next entry. Unknown where it is undecided whether x entered r at an observation since which the distance stayed below clearance (at x's first observation, whether it entered there is unknown), or where the distance is unobserved at an observation that decides it. Not denoted: the side of r on which the body stands (a body that backs out of r and stays within clearance of it still holds), x's direction or speed, or a halt: the caller reads those.",
 "args": [
  {
   "name": "x",
   "sort": "track"
  },
  {
   "name": "r",
   "sort": "region"
  }
 ],
 "params": [
  {
   "name": "clearance",
   "unit": "m",
   "meaning": "the ground distance from x's body outline to r at or beyond which x counts as clear of r; the caller passes the distance its words state"
  }
 ],
 "elements": [
  {
   "span": "x entered r (drv.motion.entering_region: its footprint overlaps r at that observation and did not at the observation before)",
   "atoms": [
    "rel.occupies"
   ],
   "concepts": [
    "drv.motion.entering_region"
   ],
   "justification": "The entry is the co-proposed concept drv.motion.entering_region, whose contract is “Road user x enters structure region r at the observation: its footprint overlaps r (rel.occupies) at the observation and did not at the observation before”; it is the event from which the state is counted, and the formula's past operator (since) reads it at the observation it occurred. rel.occupies is the atom the entry reads: “a road user's footprint overlaps a lane / region”."
  },
  {
   "span": "the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r)",
   "atoms": [
    "st.region_geometry"
   ],
   "concepts": [],
   "justification": "st.region_geometry carries “the ground distance from a road user's body outline to it (zero when they overlap)”. Not a stand-in for occupancy: the state does not read the distance as occupancy; the entry is read through rel.occupies, and the distance only decides when the body stands clear."
  }
 ],
 "residues": [],
 "literals": [],
 "narrowings_by_the_coder": [
  {
   "kind": "reading",
   "span": "at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance",
   "why": "the distance is read at every observation after the entry up to the judged one, not at the entry itself: there the footprint overlaps r, so by the contract's own words the distance is zero and below clearance, and it does not decide"
  }
 ]
}
```

Literal formals to instantiate: none, so `instance.literals` is `{}`.


### Rendering

Arguments: `x` (a track), `r` (a region).
Parameters (bounds the caller sets): `clearance` in m.
It holds at an observation exactly when:
(
  the measured `st_region_geometry_distance` of `x`, `r` [the reference point and the boundary polygon of a structure region in the world frame, and the ground distance from a road user's body outline to it (zero when they overlap); a source that maps regions without their outline declares it absent, and every such distance is then unknown **Not a stand-in for:** occupancy — a footprint inside a boundary is `rel.occupies`, which a source may observe without geometry] is less than `clearance` (a parameter the caller sets)
  SINCE
  (`rel_occupies` holds of `x`, `r` [a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure)]) holds now and did not hold at the previous observation
)


| id | contract |
|---|---|
| `drv.interaction.overtaking_alongside` | Road user x is overtaking road user y alongside at the observation: the side-by-side phase of an overtaking, on either side of y. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Either side of y counts. Not denoted: the approach from behind or the return ahead of y, the side on which x passes, where either body is on the road, a lane change, contact, or the clearance between the bodies. |
| `drv.interaction.passing_on_right` | Road user x is passing road user y on y's right at the observation: the side-by-side phase of an overtaking. It holds where their headings are aligned (rel.same_direction, with aligned_cosine as the relation's tolerance), their bodies overlap along x's heading (rel.longitudinal_overlap positive), y lies on x's left (the lateral component of rel.bearing of y from x, in x's frame), and x's speed exceeds y's (kin.speed, m/s) by more than speed_margin, the speed resolution below which the two count as keeping pace. Not denoted: the approach from behind or the return ahead of y, where either body is on the road, a lane change, contact, or the clearance between the bodies. |
| `drv.motion.against_carrier_direction` | A road user moves against the designated direction of a travel carrier at the observation. It holds where the road user is moving (drv.motion.moving with speed_floor) and the component of its velocity along the carrier's designated direction is below minus opposed_cosine times its speed: the angle between its velocity and that direction is wider than the angle whose cosine is minus opposed_cosine. Velocity (kin.velocity) and speed (kin.speed) are in m/s in the world frame; the designated direction (st.lane_direction) is read normalised and is unknown where the carrier carries none. Crossing the carrier, or any motion at a smaller angle to the designated direction than that, is not against it. Not denoted: the road user's heading opposing the carrier (a body backing along a lane faces against it but moves with it), two road users being oncoming, or the road user being on the carrier: the caller states occupancy. |
| `drv.motion.entering_region` | Road user x enters structure region r at the observation: its footprint overlaps r (rel.occupies) at the observation and did not at the observation before. The entry is that one observation; the later observations at which the overlap continues are not the entry again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, the region x came from, or its whole body being inside r: an overlap by any part of the footprint counts. |
| `drv.motion.halted` | A road user is at a standstill at the observation. This is the corpus definition of a required stop, "complete cessation from movement", observed on sampled speeds: the road user's speed (kin.speed, m/s) is at or below speed_floor, the source's speed resolution, below which a reading counts as no movement. The state holds at each observation at which the speed is that low, with no minimum duration. Not denoted: where the road user stands, why it stands, or whether its engine runs or a brake is set. |
| `drv.motion.leaving_region` | Road user x leaves structure region r at the observation: its footprint overlapped r (rel.occupies) at the observation before and does not overlap it at the observation. The exit is that one observation; the later observations at which x stays off r are not the exit again. Unknown where the overlap is unobserved at the observation or at the one before, or where there is no observation of x before it. Not denoted: x's direction or speed, or the region x moves into. |
| `drv.motion.moving` | A road user is in motion at the observation: its speed exceeds speed_floor. The floor names only the source's speed resolution, below which a reading counts as no motion; speed (kin.speed) is in m/s. The concept says nothing of the direction of motion relative to the body or to the road, of a manoeuvre, or of who or what controls the motion. Not denoted: a halt held for a duration, travel along a particular carrier, or a road user being driven by a person. |
| `drv.motion.reversing` | A road user moves backwards relative to its own body at the observation: the component of its velocity along its heading is below minus speed_floor. Velocity (kin.velocity) is in m/s in the world frame and heading (kin.heading) is read normalised; speed_floor is the source's speed resolution, so a standing or barely creeping body is not reversing. It is read from kinematics only, never from the gear selected: a vehicle in reverse gear that rolls forward is not reversing, and one in a forward gear that rolls backwards is. Not denoted: a turn, the path followed, or the place the road user is in. |
| `drv.motion.slowing` | Road user x is slowing while moving forward at the observation: the component of its velocity (kin.velocity, m/s, world frame) along its heading (kin.heading, read normalised) exceeds speed_floor, and its longitudinal acceleration (kin.accel_longitudinal, m/s², signed along the heading) is below minus decel_floor, the source's acceleration resolution. Not denoted: slowing while backing, a brake lamp or a brake input, a halt, or how much the speed has fallen. |
| `drv.motion.stopping_distance` | The distance road user x would cover from the observation to a standstill if it kept its present speed for reaction_time and then slowed at the constant deceleration deceleration: its speed (kin.speed, m/s) times reaction_time, plus the square of its speed divided by twice deceleration; in metres, zero for a body at a standstill. Not denoted: the distance x actually covers before a later halt, the deceleration the surface, the grade or the vehicle allows (the caller passes deceleration), whether anything lies within the distance, or whether x is required to stop. |
| `drv.motion.turning_left` | Road user x is turning to its left at the observation: it is moving (drv.motion.moving with speed_floor) and its yaw rate (kin.yaw_rate, deg/s, left positive) exceeds yaw_floor, the source's yaw-rate resolution. It does not tell a turn at a junction from following a left-hand bend: the caller states the place. Not denoted: a completed turn manoeuvre, an intention to turn, or a turn indicator. |
| `drv.motion.u_turn` | Road user x has turned so as to proceed in the opposite direction: the turning that the corpus defines as "the turning of a vehicle upon a highway so as to proceed in the opposite direction, whether accomplished by one continuous movement or not", observed as a reversal of x's heading. It holds at an observation where the absolute value of x's signed heading change over the window behind it (prim.heading_change with window; degrees, left positive) differs from the literal half turn by no more than reversal_tolerance: the heading now points the opposite way within the tolerance, and a heading change that has gone past the half turn by more than the tolerance (a loop back toward the first direction) does not count. A turning made in several movements, forward and backing, counts, since the heading change is integrated through all of them. The act begins within the window behind the observation of recognition; it is recognized at the observation at which this condition rises; it holds at the later observations at which the reversal still lies within the window behind them, which are not the act again, and it ends when the reversal leaves that window. Unknown where the window is truncated, sampled too sparsely, or a yaw rate is missing. Not denoted: a turning by less than a reversal, or the place of the turning: the caller states the highway or the zone. |
| `drv.motion.yawing` | A road user's heading is changing at the observation: the absolute value of its yaw rate exceeds yaw_floor. Yaw rate (kin.yaw_rate) is in deg/s, left positive, and either hand counts; yaw_floor is the source's yaw-rate resolution. Not denoted: a turn at a junction, a lane change, or the curvature of the road: a road user yaws wherever its path bends, and one running straight does not. |
| `drv.road.opposed_directions` | The designated directions of two travel carriers point opposite ways: the dot product of their designated directions (st.lane_direction, read normalised, world frame) is below minus opposed_cosine, so the angle between them is wider than the angle whose cosine is minus opposed_cosine. Unknown where either carrier carries no designated direction. Not denoted: the motion or heading of any road user on them, the carriers lying on the same way, or their entering the same intersection: the caller states those. |
| `rel.occupies` | a road user's footprint overlaps a lane / region (roadway, shoulder, sidewalk, intersection, crosswalk, stop line, safety zone, bicycle lane, median, alley, curb zone, controlled-access lane, structure) |
| `st.region_geometry` | the reference point and the boundary polygon of a structure region in the world frame, and the ground distance from a road user's body outline to it (zero when they overlap); a source that maps regions without their outline declares it absent, and every such distance is then unknown **Not a stand-in for:** occupancy — a footprint inside a boundary is `rel.occupies`, which a source may observe without geometry |


### Items

1. (holds_wrongly) With clearance set to zero metres, x enters r at the judged observation. Its distance is zero, hence at clearance rather than below it; the body nevertheless holds because it omits the distance test at the entry.
   the contract's words, per the reviewer: "at every observation from that entry up to the observation the ground distance from x's body outline to r (st.region_geometry, m, world frame; zero while the footprint overlaps r) has stayed below clearance"
   the reviewer's verdict for the contract: fails
   the body's executed verdict at t=1000 ms: holds

### The executed facts

What the harness ran, as the trace states it (numbers in Core units: metres, seconds, m/s, m/s², degrees and degrees per second). The reviewer's situation above is the reviewer's prose, unverified; these facts are what was executed.

- grounding: `x` = track 1
- regions: `r` = region 10 (intersection)
- the observation judged: t = 1000 ms
- parameters: `clearance` = 0 m

Scene t = 0 ms:
- track 1: kin.position [-2, 0]; kin.heading [1, 0]; kin.extent [0.5, 0.5, 0.5]
- structure 10: kind "intersection"; boundary [[0, -2], [4, -2], [4, 2], [0, 2]]
- occupancy_observed: [1]
- occupancy derived from the geometry before running: none
Scene t = 1000 ms (the observation judged):
- track 1: kin.position [1, 0]; kin.heading [1, 0]; kin.extent [0.5, 0.5, 0.5]
- structure 10: kind "intersection"; boundary [[0, -2], [4, -2], [4, 2], [0, 2]]
- occupancy_observed: [1]
- occupancy derived from the geometry before running: 1-10



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
