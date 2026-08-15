/-
  TrafficSpec.Core.Vocab
  The atomic-predicate vocabulary. Every formalized rule is built from these.

  Rules must NOT define their own `AtomicPred` with a raw `Scene → Bool` test:
  an ad-hoc test can reference scene-graph features CARLA never produces, and
  `tools/check_spec.py` rejects it. If a law needs something missing here, that
  is a gap for the plan agent to fill by extending this file, not something for
  a rule file to invent.
-/
import TrafficSpec.Core.Grounding
import TrafficSpec.Core.Decimal

namespace TrafficSpec.Pred

open TrafficSpec

----------------------------------------------------------------------
-- § 1. Presence, identity, classification
----------------------------------------------------------------------

/-- Entity `e` is present in the current frame. -/
def present (e : EntityId) : SFProp :=
  mkAtom s!"present({e})" (fun s => s.hasEntity e)

/-- Entity `e` has type `t`. -/
def hasType (e : EntityId) (t : EntityType) : SFProp :=
  mkAtom s!"hasType({e})" (fun s =>
    match s.typeOf e with
    | some t' => decide (t' = t)
    | none    => false)

/-- Entity `e` has one of the types `ts`. -/
def hasAnyType (e : EntityId) (ts : List EntityType) : SFProp :=
  mkAtom s!"hasAnyType({e})" (fun s =>
    match s.typeOf e with
    | some t' => ts.contains t'
    | none    => false)

/-- `e` is a motorised vehicle. -/
def isVehicle (e : EntityId) : SFProp := hasAnyType e vehicleTypes

/-- `e` is a road user (vehicle, bicycle, or pedestrian). -/
def isRoadUser (e : EntityId) : SFProp := hasAnyType e roadUserTypes

/-- Attribute `k` of `e` equals exactly `v`. Never use this for a numeric
    attribute — `"0.0"` and `"0.00"` are different strings. -/
def attrEq (e : EntityId) (k v : String) : SFProp :=
  mkAtom s!"attr({e},{k}={v})" (fun s => s.hasAttr e k v)

/-- A boolean attribute is set. The adapter renders CARLA's booleans as the
    strings `"true"` / `"false"`. -/
def attrTrue (e : EntityId) (k : String) : SFProp := attrEq e k "true"

----------------------------------------------------------------------
-- § 1a. Numeric attributes
--
-- Every numeric attribute arrives as a decimal string, so it is compared in
-- milli-units through `Core/Decimal.lean` — exact, decidable, no `Float`.
-- 1 m/s = 1000, and an integer-valued attribute such as an OpenDRIVE lane id
-- scales the same way (`"-1"` is -1000 milli).
----------------------------------------------------------------------

/-- Numeric attribute `k` of `e` is ≤ `bound` milli-units. Missing or
    unparseable values are `false`. -/
def attrMilliLe (e : EntityId) (k : String) (bound : Int) : SFProp :=
  mkAtom s!"attrLe({e},{k},{bound})" (fun s =>
    match s.getAttr e k with
    | some v => Decimal.leMilli v bound
    | none   => false)

/-- Numeric attribute `k` of `e` is ≥ `bound` milli-units. -/
def attrMilliGe (e : EntityId) (k : String) (bound : Int) : SFProp :=
  mkAtom s!"attrGe({e},{k},{bound})" (fun s =>
    match s.getAttr e k with
    | some v => Decimal.geMilli v bound
    | none   => false)

/-- `|attribute| ≤ bound` in milli-units, for signed channels like `steer`. -/
def attrMilliAbsLe (e : EntityId) (k : String) (bound : Int) : SFProp :=
  mkAtom s!"attrAbsLe({e},{k},{bound})" (fun s =>
    match s.getAttr e k with
    | some v => Decimal.absLeMilli v bound
    | none   => false)

/-- `|attribute| ≥ bound` in milli-units: the channel has moved off centre in
    either direction. -/
def attrMilliAbsGe (e : EntityId) (k : String) (bound : Int) : SFProp :=
  mkAtom s!"attrAbsGe({e},{k},{bound})" (fun s =>
    match s.getAttr e k with
    | some v => Decimal.absGeMilli v bound
    | none   => false)

/-- `e` carries the adapter's `name` attribute `n` (e.g. `"ego"`, `"car_0"`). -/
def named (e : EntityId) (n : String) : SFProp := attrEq e "name" n

/-- `e` carries semantic class `c`. -/
def semClass (e : EntityId) (c : String) : SFProp := attrEq e "sem_class" c

/-- `e` carries CARLA special class `c` (`"ego"`, `"emergency"`, `"taxi"`,
    `"electric"`). -/
def specialClass (e : EntityId) (c : String) : SFProp := attrEq e "special_class" c

/-- `e` is the ego vehicle. The generator marks ego with
    `special_class = "ego"` and `name = "ego"`; accept either. -/
def isEgo (e : EntityId) : SFProp :=
  mkAtom s!"isEgo({e})" (fun s =>
    s.hasAttr e "special_class" "ego" || s.hasAttr e "name" "ego")

/-- `e` carries the generator's SGG base class `c` (`"car"`, `"person"`,
    `"traffic_light"`, …). The entity type already encodes this; use it when a
    rule needs to talk about the class the *proximity* tables key on. -/
def baseClass (e : EntityId) (c : String) : SFProp := attrEq e "base_class" c

/-- `e` is an emergency vehicle (police, fire, ambulance).

    CARLA's ambulance has base type `van`, and no proximity or angular edge is
    ever emitted for a van, so a rule combining `isEmergency` with a distance
    can only ground on the police car and the firetruck. -/
def isEmergency (e : EntityId) : SFProp := specialClass e "emergency"

/-- `e` is a taxi (`special_class = "taxi"`). -/
def isTaxi (e : EntityId) : SFProp := specialClass e "taxi"

/-- `e` is an electric vehicle (`special_class = "electric"`). -/
def isElectric (e : EntityId) : SFProp := specialClass e "electric"

/-- `e` is a pedestrian (SGG base class `person`). -/
def isPedestrian (e : EntityId) : SFProp := hasType e .pedestrian

/-- `e` is a traffic light. -/
def isTrafficLight (e : EntityId) : SFProp := hasType e .trafficLight

/-- `e` is a stop sign. -/
def isStopSign (e : EntityId) : SFProp := hasType e .stopSign

/-- `e` is a posted speed-limit sign (`traffic.speed_limit.*`). -/
def isSpeedLimitSign (e : EntityId) : SFProp := hasType e .speedLimitSign

/-- `e` is an OpenDRIVE landmark — the map's own record of a regulatory sign. -/
def isLandmark (e : EntityId) : SFProp := hasType e .landmark

/-- `e` is a traffic-control device that carries `controls` edges, i.e. a
    traffic light or a stop sign. -/
def isControlDevice (e : EntityId) : SFProp := hasAnyType e controlDeviceTypes

----------------------------------------------------------------------
-- § 2. Raw relations
----------------------------------------------------------------------

/-- The scene-graph edge `a --lbl--> b` exists. -/
def rel (a : EntityId) (lbl : RelLabel) (b : EntityId) : SFProp :=
  mkAtom s!"rel({a},{b})" (fun s => s.hasRelation a lbl b)

/-- Any of the edges `a --lbl--> b` for `lbl ∈ lbls` exists. -/
def relAny (a : EntityId) (lbls : List RelLabel) (b : EntityId) : SFProp :=
  mkAtom s!"relAny({a},{b})" (fun s => lbls.any (fun l => s.hasRelation a l b))

----------------------------------------------------------------------
-- § 3. Road structure
----------------------------------------------------------------------

/-- `e` occupies lane `l` (`isIn`, restricted to lane targets). -/
def inLane (e l : EntityId) : SFProp :=
  mkAtom s!"inLane({e},{l})" (fun s =>
    (s.relatedToTyped e .isIn [.lane]).contains l)

/-- `e` occupies some lane. False when the adapter has placed `e` on the
    singleton `Off Road` node instead. -/
def onRoadway (e : EntityId) : SFProp :=
  mkAtom s!"onRoadway({e})" (fun s =>
    !(s.relatedToTyped e .isIn [.lane]).isEmpty)

/-- `e` is off the roadway (`isIn` an `offRoad` node). -/
def offRoadway (e : EntityId) : SFProp :=
  mkAtom s!"offRoadway({e})" (fun s =>
    !(s.relatedToTyped e .isIn [.offRoad]).isEmpty)

/-- `a` and `b` occupy a common lane. -/
def sameLane (a b : EntityId) : SFProp :=
  mkAtom s!"sameLane({a},{b})" (fun s =>
    let la := s.relatedToTyped a .isIn [.lane]
    let lb := s.relatedToTyped b .isIn [.lane]
    la.any (fun l => lb.contains l))

/-- `a` and `b` occupy lanes that oppose each other. -/
def opposingLanes (a b : EntityId) : SFProp :=
  mkAtom s!"opposingLanes({a},{b})" (fun s =>
    let la := s.relatedToTyped a .isIn [.lane]
    let lb := s.relatedToTyped b .isIn [.lane]
    la.any (fun l1 => lb.any (fun l2 => s.hasRelation l1 .opposes l2)))

/-- `e` is inside junction `j`, following the graph's two-hop
    entity → lane → road → junction structure. -/
def inJunction (e j : EntityId) : SFProp :=
  mkAtom s!"inJunction({e},{j})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    let roads := lanes.foldl (fun acc l => acc ++ s.relatedToTyped l .isIn [.road]) []
    roads.any (fun r => (s.relatedToTyped r .isIn [.junction]).contains j))

/-- `e` is inside some junction. -/
def inAnyJunction (e : EntityId) : SFProp :=
  mkAtom s!"inAnyJunction({e})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    let roads := lanes.foldl (fun acc l => acc ++ s.relatedToTyped l .isIn [.road]) []
    roads.any (fun r => !(s.relatedToTyped r .isIn [.junction]).isEmpty))

/-- `e` occupies a lane that leads into junction `j` — the "approaching"
    condition, using the generator's `travelsTo` lane connectivity. -/
def approachingJunction (e j : EntityId) : SFProp :=
  mkAtom s!"approachingJunction({e},{j})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    let nexts := lanes.foldl (fun acc l => acc ++ s.relatedToTyped l .travelsTo [.lane]) []
    nexts.any (fun l2 =>
      let roads := s.relatedToTyped l2 .isIn [.road]
      roads.any (fun r => (s.relatedToTyped r .isIn [.junction]).contains j)))

----------------------------------------------------------------------
-- § 3a. Lane identity and lane topology
--
-- A lane node's OpenDRIVE ids survive the abstraction only through its name,
-- which `Core/Builders.lean` re-reads into `road_id` and `lane_id`. The lane-id
-- **sign** is the side of the road's reference line: negative right, positive
-- left, with all lanes of one travel direction sharing a sign.
--
-- What that does and does not settle:
--   * it identifies which half of the roadway a lane belongs to;
--   * it does NOT say whether a vehicle in that lane is heading the lawful way,
--     because the abstraction drops the lane's direction vector. For that,
--     either compare two actors' relative heading (§ 5, `oncoming`) or use lane
--     connectivity over time: if `v` is in `l₁` now and in `l₂` next frame while
--     the graph says `l₂ travelsTo l₁`, `v` moved against the lane's direction.
--
-- `opposes`, `toLeftOf` and `toRightOf` between lanes are emitted only for
-- **adjacent lane ids of the same road**.
----------------------------------------------------------------------

/-- Lane `l` belongs to the road with OpenDRIVE id `r` (as written, e.g. `"9"`).
    Road nodes carry `road_id` too, so this also reads a road binder. -/
def laneOfRoad (l : EntityId) (r : String) : SFProp := attrEq l "road_id" r

/-- Junction `j` has OpenDRIVE junction id `n`. Junction nodes are otherwise
    interchangeable, so this is the only way to name a particular one. -/
def junctionIdIs (j : EntityId) (n : String) : SFProp := attrEq j "junction_id" n

/-- Lane `l` has OpenDRIVE lane id ≤ `n`. -/
def laneIdAtMost (l : EntityId) (n : Int) : SFProp :=
  attrMilliLe l "lane_id" (n * 1000)

/-- Lane `l` has OpenDRIVE lane id ≥ `n`. -/
def laneIdAtLeast (l : EntityId) (n : Int) : SFProp :=
  attrMilliGe l "lane_id" (n * 1000)

/-- Lane `l` lies right of its road's **OpenDRIVE reference line** (lane id ≤ -1).

    ⚠ This is a map-authoring convention, NOT a side of the road in the sense any
    traffic statute means. Both carriageways of a two-way road have their own
    sign, and *every* lane of one direction of travel shares it, so a lawful
    driver on the `+` carriageway of a divided road — or on any one-way street the
    map happens to number positively — is `laneLeftOfReference` for the whole
    journey.

    **Never use this, or `laneLeftOfReference`, to formalize "the right half of
    the roadway" or "the right-hand edge of the roadway".** Doing so reports a
    violation for every frame of lawful driving on such a road, and nothing in the
    graph distinguishes that from a genuine wrong-side excursion. Use
    `inRightmostLane` / `hasLaneToTheRight`, which are relative to the vehicle's
    own direction of travel and need no map convention.

    These two predicates are kept for what they actually answer: which side of the
    reference line a lane was authored on. -/
def laneRightOfReference (l : EntityId) : SFProp := laneIdAtMost l (-1)

/-- Lane `l` lies left of its road's OpenDRIVE reference line (lane id ≥ 1).
    See the warning on `laneRightOfReference`: this is not a legal side of the
    road, and must not be used to formalize keeping right. -/
def laneLeftOfReference (l : EntityId) : SFProp := laneIdAtLeast l 1

private def laneIdsOf (s : Scene) (e : EntityId) : List String :=
  (s.relatedToTyped e .isIn [.lane]).filterMap (fun l => s.getAttr l "lane_id")

/-- `e` occupies a lane right of the reference line. Carries the same warning as
    `laneRightOfReference` — not a legal side of the road. -/
def inLaneRightOfReference (e : EntityId) : SFProp :=
  mkAtom s!"inLaneRightOfReference({e})" (fun s =>
    (laneIdsOf s e).any (fun v => Decimal.leMilli v (-1000)))

/-- `e` occupies a lane left of the reference line. Carries the same warning as
    `laneRightOfReference` — not a legal side of the road. -/
def inLaneLeftOfReference (e : EntityId) : SFProp :=
  mkAtom s!"inLaneLeftOfReference({e})" (fun s =>
    (laneIdsOf s e).any (fun v => Decimal.geMilli v 1000))

----------------------------------------------------------------------
-- Keeping to your own side, without the map convention
--
-- The generator computes each lane-to-lane left/right edge in the **target**
-- lane's own forward frame (`sgg_abstractor.py`, using `graph.nodes[l1]['forward']`),
-- which makes the pattern of edges between two lanes tell you whether they carry
-- traffic the same way:
--
--   same direction   `a toLeftOf b` and `b toRightOf a` — asymmetric
--   opposite         `a toLeftOf b` and `b toLeftOf a`  — each is "left" of the
--                    other, because each is judged from its own heading
--
-- So "am I on the correct side" is decidable *relative to the vehicle's own
-- direction of travel*, needing no reference-line sign and no lane heading:
-- a driver keeping right has no same-direction lane to the right.
----------------------------------------------------------------------

/-- Lanes `a` and `b` carry traffic in opposite directions.

    `opposes` is emitted only between adjacent lane ids of one road, so the
    mutual-`toLeftOf` pattern is checked as well and is the general test. -/
private def opposedLanes (s : Scene) (a b : EntityId) : Bool :=
  s.hasRelation a .opposes b || s.hasRelation b .opposes a
  || (s.hasRelation a .toLeftOf b && s.hasRelation b .toLeftOf a)

/-- Lane `r` lies to the right of lane `l` and carries traffic the same way — the
    lane a driver in `l` ought to be using if the statute says keep right. -/
def laneRightOfSameDirection (r l : EntityId) : SFProp :=
  mkAtom s!"laneRightOfSameDirection({r},{l})" (fun s =>
    s.hasRelation r .toRightOf l && !opposedLanes s r l)

private def someLaneToTheRight (s : Scene) (e : EntityId) : Bool :=
  let mine := s.relatedToTyped e .isIn [.lane]
  mine.any (fun l =>
    (s.entitiesOfType .lane).any (fun r =>
      s.hasRelation r.id .toRightOf l && !opposedLanes s r.id l))

/-- `e` is in the rightmost lane of its own direction of travel: it occupies a
    lane, and no same-direction lane lies to the right of it.

    This is the sound reading of "shall be driven upon the right half of the
    roadway" and of "shall drive to the right-hand edge of the roadway". It is
    slightly **stricter** than "the right half": on a carriageway of three lanes
    it requires the rightmost rather than merely the right-hand half, so a rule
    using it should carry the statute's own overtaking or manoeuvring exception.

    False when `e` occupies no lane at all, so it is not the negation of
    `hasLaneToTheRight` — an off-road vehicle satisfies neither, and a rule must
    say which way it wants that case to fall. -/
def inRightmostLane (e : EntityId) : SFProp :=
  mkAtom s!"inRightmostLane({e})" (fun s =>
    !(s.relatedToTyped e .isIn [.lane]).isEmpty && !someLaneToTheRight s e)

/-- `e` occupies a lane with another same-direction lane to its right — the
    positive form of the offence, so a rule need not negate `inRightmostLane` and
    accidentally convict a vehicle that is off the roadway entirely. -/
def hasLaneToTheRight (e : EntityId) : SFProp :=
  mkAtom s!"hasLaneToTheRight({e})" (fun s => someLaneToTheRight s e)

/-- `a` and `b` occupy lanes of the same road, whether or not the same lane. -/
def sameRoad (a b : EntityId) : SFProp :=
  mkAtom s!"sameRoad({a},{b})" (fun s =>
    let roadsOf := fun (e : EntityId) =>
      (s.relatedToTyped e .isIn [.lane]).filterMap (fun l => s.getAttr l "road_id")
    (roadsOf a).any (fun r => (roadsOf b).contains r))

/-- Lane `l₁` leads into lane `l₂` following the direction of travel. -/
def laneTravelsTo (l₁ l₂ : EntityId) : SFProp := rel l₁ .travelsTo l₂

/-- A lane change is legal from lane `l₁` into lane `l₂`. -/
def canLaneChangeTo (l₁ l₂ : EntityId) : SFProp := rel l₁ .laneChange l₂

----------------------------------------------------------------------
-- § 4. Proximity
--
-- The generator emits exactly one distance band per ordered pair, so a rule
-- that means "closer than 7 m" must accept `safetyHazard`, `nearCollision`
-- and `superNear`. Writing `rel a .near b` instead is the single most common
-- specification bug: `near` is the 10–16 m band, the second *farthest*.
----------------------------------------------------------------------

/-- Distance bands with an upper bound at or below `m` metres. -/
def bandsWithin (m : Nat) : List RelLabel :=
  (distanceBands.filter (fun p => decide (p.2 ≤ m))).map (fun p => p.1)

/-- `a` and `b` are within `m` metres of each other, for `m` one of
    2, 4, 7, 10, 16, 25. Other values round down to the nearest band boundary.

    Distance is physically symmetric but the graph stores one directed edge per
    pair, so both orientations are checked. -/
def withinMetres (m : Nat) (a b : EntityId) : SFProp :=
  mkAtom s!"withinMetres({m},{a},{b})" (fun s =>
    (bandsWithin m).any (fun l => s.hasRelation a l b || s.hasRelation b l a))

/-- `a` and `b` are in *some* proximity band, i.e. within 25 m and therefore
    both present in the graph's relation set. -/
def inProximity (a b : EntityId) : SFProp := withinMetres 25 a b

/-- Dangerously close: under 4 m (`safetyHazard` or `nearCollision`). -/
def dangerouslyClose (a b : EntityId) : SFProp := withinMetres 4 a b

----------------------------------------------------------------------
-- § 5. Relative orientation
--
-- Reading convention, matching the generator's relation names and the
-- reference repository's usage: an edge `a --lbl--> b` means "**a** is `lbl`
-- **b**". So `rel v .atDRearOf w` says v is at the rear of w, i.e. v is the
-- follower. Every predicate below takes its arguments in that same order.
--
-- `inFrontOf` / `behind` are derived: the generator emits only the
-- direct/side split (`inDFrontOf`/`inSFrontOf`, `atDRearOf`/`atSRearOf`),
-- never a combined edge, so the disjunction has to be taken here.
----------------------------------------------------------------------

/-- `a` is ahead of `b`, directly or to the side. -/
def inFrontOf (a b : EntityId) : SFProp := relAny a [.inDFrontOf, .inSFrontOf] b

/-- `a` is directly ahead of `b`. -/
def directlyInFrontOf (a b : EntityId) : SFProp := rel a .inDFrontOf b

/-- `a` is behind `b`, directly or to the side. -/
def behind (a b : EntityId) : SFProp := relAny a [.atDRearOf, .atSRearOf] b

/-- `a` is directly behind `b`. -/
def directlyBehind (a b : EntityId) : SFProp := rel a .atDRearOf b

/-- `a` is to the left of `b`. The relation is not exclusive: two entities can
    each be to the left of the other (see the generator's documentation). -/
def toLeftOf (a b : EntityId) : SFProp := rel a .toLeftOf b

/-- `a` is to the right of `b`. -/
def toRightOf (a b : EntityId) : SFProp := rel a .toRightOf b

/-- `a` and `b` face each other — an oncoming pair.

    The generator computes each angular edge from the *source* actor's forward
    vector, splitting the circle into a front half-plane and a rear half-plane.
    Two actors are therefore each in the other's front half-plane only when their
    headings differ by more than 90°, i.e. they are approaching each other;
    same-direction traffic always yields one front edge and one rear edge.

    This is the only heading information the abstraction preserves, and it is
    **relative** — it says the pair is converging, not which one is in the wrong
    place. -/
def oncoming (a b : EntityId) : SFProp :=
  SFProp.conj (inFrontOf a b) (inFrontOf b a)

/-- `a` and `b` travel in the same direction, with `a` ahead of `b`. -/
def sameHeading (a b : EntityId) : SFProp :=
  SFProp.conj (inFrontOf a b) (behind b a)

/-- `a` is following `b`: same lane, with `a` behind `b`. -/
def following (a b : EntityId) : SFProp :=
  SFProp.conj (sameLane a b) (behind a b)

/-- `a` is following `b` within `m` metres — the antecedent of a
    following-distance rule. -/
def followingWithin (m : Nat) (a b : EntityId) : SFProp :=
  SFProp.conj (following a b) (withinMetres m a b)

----------------------------------------------------------------------
-- § 6. Ego dynamics
--
-- speed / accel / throttle / brake / steer / yaw_rate / hand_brake / reverse /
-- at_traffic_light exist on the ego vehicle ONLY: the generator calls
-- `copy_carla_actor_state` and `copy_carla_control` for the ego node alone.
-- Applying any of these to a non-ego binder yields a predicate that is always
-- false — a vacuity trap. For another vehicle, its **light states** (§ 7) are
-- the only dynamic evidence available.
--
-- Bounds are in milli-units: 1 m/s = 1000.
----------------------------------------------------------------------

/-- Speed ≤ `bound` milli-m/s. -/
def speedLe (e : EntityId) (bound : Int) : SFProp := attrMilliLe e "speed" bound

/-- Speed ≥ `bound` milli-m/s. -/
def speedGe (e : EntityId) (bound : Int) : SFProp := attrMilliGe e "speed" bound

/-- Speed ≤ `kph` kilometres per hour. Converted to milli-m/s as
    `kph * 1000000 / 3600`, truncating. -/
def speedLeKph (e : EntityId) (kph : Nat) : SFProp :=
  speedLe e (Int.ofNat (kph * 1000000 / 3600))

/-- Speed ≥ `kph` kilometres per hour. -/
def speedGeKph (e : EntityId) (kph : Nat) : SFProp :=
  speedGe e (Int.ofNat (kph * 1000000 / 3600))

/-- Stationary: speed ≤ 0.1 m/s. A "complete stop" in the sense of a statute. -/
def stopped (e : EntityId) : SFProp := speedLe e 100

/-- Moving: speed > 0.1 m/s. -/
def moving (e : EntityId) : SFProp := speedGe e 101

/-- Brake applied at least `bound` milli (brake ranges 0..1, so 1000 = full). -/
def brakingAtLeast (e : EntityId) (bound : Int) : SFProp :=
  attrMilliGe e "brake" bound

/-- Any brake application. -/
def braking (e : EntityId) : SFProp := brakingAtLeast e 1

/-- Throttle applied at least `bound` milli. -/
def throttleAtLeast (e : EntityId) (bound : Int) : SFProp :=
  attrMilliGe e "throttle" bound

/-- Decelerating: acceleration ≤ `-bound` milli-m/s². -/
def deceleratingAtLeast (e : EntityId) (bound : Int) : SFProp :=
  attrMilliLe e "accel" (-bound)

/-- Steering held near centre: |steer| ≤ `bound` milli (steer ranges -1..1). -/
def steeringStraight (e : EntityId) (bound : Int) : SFProp :=
  attrMilliAbsLe e "steer" bound

/-- Yaw rate at least `bound` milli-deg/s in either direction — the ego is
    turning. From `carla_ang_vel_z`; 1 deg/s = 1000. -/
def turningAtLeast (e : EntityId) (bound : Int) : SFProp :=
  attrMilliAbsGe e "yaw_rate" bound

/-- Yaw rate within `bound` milli-deg/s of zero — the ego is holding a course. -/
def notTurning (e : EntityId) (bound : Int) : SFProp :=
  attrMilliAbsLe e "yaw_rate" bound

/-- The parking brake is engaged (ego only). -/
def handBrakeOn (e : EntityId) : SFProp := attrTrue e "hand_brake"

/-- The transmission is in reverse (ego only). Distinct from `reverseLightOn`,
    which is observable on any vehicle. -/
def inReverse (e : EntityId) : SFProp := attrTrue e "reverse"

/-- CARLA reports the ego as being at a traffic light
    (`ego.is_at_traffic_light()`): it is inside the trigger volume of a signal
    that governs its lane. Cheaper than walking `controls` edges, but it says
    nothing about the signal's colour — combine with `facingRedSignal`. -/
def atTrafficLight (e : EntityId) : SFProp := attrTrue e "at_traffic_light"

----------------------------------------------------------------------
-- § 7. Vehicle light state
--
-- `sgg.py` records `actor.get_light_state()` for **every** `carla.Vehicle`, not
-- just the ego, as one boolean per light type. These are therefore the only
-- dynamic channels available for another vehicle: a brake light is the sole
-- evidence that a non-ego vehicle is slowing, and the blinkers are the sole
-- evidence of intent.
--
-- A light that the simulated traffic manager never actuates stays `false`, so a
-- rule whose antecedent requires a blinker may be vacuous on a given capture
-- even though the channel exists. Check the grounding count.
----------------------------------------------------------------------

/-- Vehicle light `k` is on, for `k` one of `light_brake`, `light_left_blinker`,
    `light_right_blinker`, `light_high_beam`, `light_low_beam`,
    `light_position`, `light_fog`, `light_reverse`. -/
def lightOn (e : EntityId) (k : String) : SFProp := attrTrue e k

/-- Brake lights lit. -/
def brakeLightOn (e : EntityId) : SFProp := lightOn e "light_brake"

/-- Left indicator lit. -/
def leftBlinkerOn (e : EntityId) : SFProp := lightOn e "light_left_blinker"

/-- Right indicator lit. -/
def rightBlinkerOn (e : EntityId) : SFProp := lightOn e "light_right_blinker"

/-- Both indicators lit — CARLA has no separate hazard channel. -/
def hazardLightsOn (e : EntityId) : SFProp :=
  SFProp.conj (leftBlinkerOn e) (rightBlinkerOn e)

/-- High beams lit. -/
def highBeamOn (e : EntityId) : SFProp := lightOn e "light_high_beam"

/-- Low beams lit. -/
def lowBeamOn (e : EntityId) : SFProp := lightOn e "light_low_beam"

/-- Sidelights / position lamps lit. -/
def positionLightOn (e : EntityId) : SFProp := lightOn e "light_position"

/-- Fog lights lit. -/
def fogLightOn (e : EntityId) : SFProp := lightOn e "light_fog"

/-- Reversing lights lit — observable on any vehicle, unlike `inReverse`. -/
def reverseLightOn (e : EntityId) : SFProp := lightOn e "light_reverse"

----------------------------------------------------------------------
-- § 8. Traffic-control devices
--
-- A traffic light or stop sign is linked to every lane it governs by a
-- `controls` edge (`controlsTrafficOf`, built from the light's affected
-- waypoints or the sign's trigger volume). That edge is the ONLY sound way to
-- say "the signal facing this vehicle": the generator emits no proximity edge to
-- any signal or sign, and a sign's `isIn` edges mean only that its bounding box
-- overlapped a lane — which is equally true of the sign facing the cross street.
--
-- Traffic-light colour is `light_state`, `str(carla.TrafficLightState)`: one of
-- `"Red"`, `"Yellow"`, `"Green"`, `"Off"`, `"Unknown"`. A signal *change* is a
-- change of this attribute between adjacent frames, so it needs no extra data —
-- express it temporally.
----------------------------------------------------------------------

/-- Device `d` governs lane `l`. -/
def controlsLane (d l : EntityId) : SFProp := rel d .controls l

/-- Device `d` governs a lane that `e` occupies. -/
def governs (d e : EntityId) : SFProp :=
  mkAtom s!"governs({d},{e})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    (s.relatedToTyped d .controls [.lane]).any (fun l => lanes.contains l))

/-- Traffic light `d` shows `v` (`"Red"`, `"Yellow"`, `"Green"`, `"Off"`,
    `"Unknown"`). -/
def signalState (d : EntityId) (v : String) : SFProp := attrEq d "light_state" v

/-- Traffic light `d` shows red. -/
def signalRed (d : EntityId) : SFProp := signalState d "Red"

/-- Traffic light `d` shows amber. -/
def signalYellow (d : EntityId) : SFProp := signalState d "Yellow"

/-- Traffic light `d` shows green. -/
def signalGreen (d : EntityId) : SFProp := signalState d "Green"

/-- Traffic light `d` is dark. -/
def signalOff (d : EntityId) : SFProp := signalState d "Off"

/-- Some traffic light governing a lane `e` occupies shows `state`. Use this
    when the rule does not need to name the signal; bind a
    `trafficLightBinder` and use `governs` + `signalState` when it does. -/
def facingSignal (e : EntityId) (state : String) : SFProp :=
  mkAtom s!"facingSignal({e},{state})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    (s.entitiesOfType .trafficLight).any (fun d =>
      s.hasAttr d.id "light_state" state
      && (s.relatedToTyped d.id .controls [.lane]).any (fun l => lanes.contains l)))

/-- `e` faces a steady red signal. -/
def facingRedSignal (e : EntityId) : SFProp := facingSignal e "Red"

/-- `e` faces an amber signal. -/
def facingYellowSignal (e : EntityId) : SFProp := facingSignal e "Yellow"

/-- `e` faces a green signal. -/
def facingGreenSignal (e : EntityId) : SFProp := facingSignal e "Green"

/-- A stop sign governs a lane `e` occupies. -/
def facingStopSign (e : EntityId) : SFProp :=
  mkAtom s!"facingStopSign({e})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    (s.entitiesOfType .stopSign).any (fun d =>
      (s.relatedToTyped d.id .controls [.lane]).any (fun l => lanes.contains l)))

----------------------------------------------------------------------
-- § 9. Landmarks and posted limits
--
-- OpenDRIVE landmarks are the map's own regulatory signs, linked to the lanes
-- they apply to by `mayAffect`. `landmark_type` is the OpenDRIVE type code:
-- `"274"` speed limit (value in km/h in `landmark_value`), `"206"` stop,
-- `"205"` give way. A landmark reaches the graph only if it is within the
-- capture's render distance of a driving node, so its absence is not evidence
-- that the restriction does not exist.
--
-- CARLA also spawns `traffic.speed_limit.<kph>` sign actors, whose value the
-- adapter lifts into `posted_limit_kph`; those carry no `controls` or
-- `mayAffect` edge, so prefer the landmark.
----------------------------------------------------------------------

/-- Landmark `lm` applies to lane `l`. -/
def mayAffectLane (lm l : EntityId) : SFProp := rel lm .mayAffect l

/-- Landmark `lm` applies to a lane that `e` occupies. -/
def landmarkApplies (lm e : EntityId) : SFProp :=
  mkAtom s!"landmarkApplies({lm},{e})" (fun s =>
    let lanes := s.relatedToTyped e .isIn [.lane]
    (s.relatedToTyped lm .mayAffect [.lane]).any (fun l => lanes.contains l))

/-- Landmark `lm` has OpenDRIVE type code `t`. -/
def landmarkType (lm : EntityId) (t : String) : SFProp :=
  attrEq lm "landmark_type" t

/-- Landmark `lm` has OpenDRIVE sub-type `t`. -/
def landmarkSubType (lm : EntityId) (t : String) : SFProp :=
  attrEq lm "landmark_sub_type" t

/-- Landmark `lm` belongs to sign catalogue `c` (usually `"OpenDRIVE"`). The
    type codes are only meaningful within a catalogue, so check this before
    reading `landmarkType` if the map may not be one of the shipped towns. -/
def landmarkCountry (lm : EntityId) (c : String) : SFProp :=
  attrEq lm "landmark_country" c

/-- Landmark `lm` states its value in unit `u` (`"km/h"`, `"m"`, …). -/
def landmarkUnit (lm : EntityId) (u : String) : SFProp :=
  attrEq lm "landmark_unit" u

/-- Landmark `lm` carries the legend `t`. -/
def landmarkText (lm : EntityId) (t : String) : SFProp :=
  attrEq lm "landmark_text" t

/-- Landmark `lm` carries a value of at most `bound` milli-units of its own
    unit. Read `landmark_unit` before relying on this. -/
def landmarkValueAtMost (lm : EntityId) (bound : Int) : SFProp :=
  attrMilliLe lm "landmark_value" bound

/-- Landmark `lm` carries a value of at least `bound` milli-units. -/
def landmarkValueAtLeast (lm : EntityId) (bound : Int) : SFProp :=
  attrMilliGe lm "landmark_value" bound

/-- A speed-limit sign actor posts at most `kph` (from `posted_limit_kph`). -/
def postedLimitSignAtMostKph (e : EntityId) (kph : Nat) : SFProp :=
  attrMilliLe e "posted_limit_kph" (Int.ofNat (kph * 1000))

/-- The km/h limit of a speed-limit landmark applying to `e`'s lane, in
    milli-m/s, if there is exactly one such landmark to be found. -/
private def postedLimitMps (s : Scene) (e : EntityId) : Option Int :=
  let lanes := s.relatedToTyped e .isIn [.lane]
  let hit := (s.entitiesOfType .landmark).find? (fun lm =>
    s.hasAttr lm.id "landmark_type" "274"
    && (s.relatedToTyped lm.id .mayAffect [.lane]).any (fun l => lanes.contains l))
  match hit with
  | some lm => (s.getAttr lm.id "landmark_value").bind Decimal.kphStringToMps
  | none    => none

/-- `e`'s speed is within the posted limit of a speed-limit landmark applying to
    its lane. **False when there is no such landmark**, so this is not the
    negation of `exceedsPostedSpeedLimit`: a rule must decide explicitly what an
    unsigned road means. Speed is ego-only, so `e` must be the ego vehicle. -/
def withinPostedSpeedLimit (e : EntityId) : SFProp :=
  mkAtom s!"withinPostedSpeedLimit({e})" (fun s =>
    match postedLimitMps s e, (s.getAttr e "speed").bind Decimal.parseMilli with
    | some lim, some v => decide (v ≤ lim)
    | _,        _      => false)

/-- `e`'s speed exceeds the posted limit of a speed-limit landmark applying to
    its lane. False when there is no such landmark. -/
def exceedsPostedSpeedLimit (e : EntityId) : SFProp :=
  mkAtom s!"exceedsPostedSpeedLimit({e})" (fun s =>
    match postedLimitMps s e, (s.getAttr e "speed").bind Decimal.parseMilli with
    | some lim, some v => decide (lim < v)
    | _,        _      => false)

end TrafficSpec.Pred
