/-
  Witnesses for NRS_484B_400_2a.

  The geometry, the same in every scene that uses it (world frame: +x east, +y north; the subject
  heads east and approaches the junction from the west):

    · two highways meeting at the origin — `hwyA` east-west (x -60…60, y -12…12) and `hwyB`
      north-south (x -12…12, y -60…60) — and `junction`, the intersection region x,y ∈ -6…6, which
      lies on both ways;
    · the marked street: four lanes on `hwyA` west of the junction, the centreline at y = 0.
      Eastbound (the subject's direction): `laneInner` y -3.6…0, ordinal 1 of 2, the lane abutting
      the centreline, and `laneOuter` y -7.2…-3.6, ordinal 2 of 2; both enter the junction.
      Westbound: `laneOncomingInner` y 0…3.6, ordinal 1 of 2, and `laneOncomingOuter` y 3.6…7.2;
      these run away from the junction and enter none. On `hwyB`, one lane per direction south of
      the junction, so that way too has two opposed travel regions;
    · the unmarked street: no lane regions at all, one directed roadway segment per direction on
      `hwyA` (`roadwayEast` y -3.6…0, entering the junction, and `roadwayWest` y 0…3.6), the same
      on `hwyB`, and `centreLine`, the mapped centre mark, the strip y -0.1…0.1;
    · `wideRoadwayEast` y -7…0 is the same eastbound segment on a wide road, for the scene in
      which the subject keeps far from the centre mark;
    · `medianStrip` y -0.1…0.1 is a mapped divider lying on `hwyA`, for the divided-highway scene.

  The subject is a motor vehicle at x = -20 m, 14 m short of the junction, heading east at 30 km/h;
  only its lateral position changes between scenes. Every trace is three instants one second apart;
  nothing in the rule looks back, so no scenario names a window. Every figure here is the
  witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The corners of an axis-aligned rectangle, as a boundary polygon. -/
def rectPoly (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

-- Binders ↦ tracks: subject ↦ 1

-- The two ways and the junction.
def hwyA := Build.rect 10 .highway (m (-60)) (m (-12)) (m 60) (m 12)
def hwyB := Build.rect 11 .highway (m (-12)) (m (-60)) (m 12) (m 60)
def junction :=
  { Build.rect 12 .intersection (m (-6)) (m (-6)) (m 6) (m 6) with ways := some [10, 11] }

-- The marked street: two lanes each way on `hwyA`, one each way on `hwyB`.
def laneInner :=
  { Build.lane 20 (rectPoly (m (-60)) (cm (-360)) (m (-6)) Q.zero) Build.east
      (right := some 21) (ordinal := some 1) (count := some 2) (enters := some 12) with
    ways := some [10] }
def laneOuter :=
  { Build.lane 21 (rectPoly (m (-60)) (cm (-720)) (m (-6)) (cm (-360))) Build.east
      (left := some 20) (ordinal := some 2) (count := some 2) (enters := some 12) with
    ways := some [10] }
def laneOncomingInner :=
  { Build.lane 22 (rectPoly (m (-60)) Q.zero (m (-6)) (cm 360)) Build.west
      (right := some 23) (ordinal := some 1) (count := some 2) with
    ways := some [10] }
def laneOncomingOuter :=
  { Build.lane 23 (rectPoly (m (-60)) (cm 360) (m (-6)) (cm 720)) Build.west
      (left := some 22) (ordinal := some 2) (count := some 2) with
    ways := some [10] }
def laneNorthbound :=
  { Build.lane 24 (rectPoly Q.zero (m (-60)) (cm 360) (m (-6))) Build.north
      (ordinal := some 1) (count := some 1) (enters := some 12) with
    ways := some [11] }
def laneSouthbound :=
  { Build.lane 25 (rectPoly (cm (-360)) (m (-60)) Q.zero (m (-6))) Build.south
      (ordinal := some 1) (count := some 1) with
    ways := some [11] }

-- The unmarked street: one directed roadway segment per direction, and the centre mark.
def roadwayEast :=
  { Build.rect 30 .roadway (m (-60)) (cm (-360)) (m (-6)) Q.zero with
    lane := some { direction := some Build.east, entersIntersection := some 12 }
    ways := some [10] }
def roadwayWest :=
  { Build.rect 31 .roadway (m (-60)) Q.zero (m (-6)) (cm 360) with
    lane := some { direction := some Build.west }
    ways := some [10] }
def roadwayNorthbound :=
  { Build.rect 32 .roadway Q.zero (m (-60)) (cm 360) (m (-6)) with
    lane := some { direction := some Build.north, entersIntersection := some 12 }
    ways := some [11] }
def roadwaySouthbound :=
  { Build.rect 33 .roadway (cm (-360)) (m (-60)) Q.zero (m (-6)) with
    lane := some { direction := some Build.south }
    ways := some [11] }
def wideRoadwayEast :=
  { Build.rect 34 .roadway (m (-60)) (m (-7)) (m (-6)) Q.zero with
    lane := some { direction := some Build.east, entersIntersection := some 12 }
    ways := some [10] }
def centreLine :=
  { Build.rect 40 .centreLine (m (-60)) (cm (-10)) (m (-6)) (cm 10) with ways := some [10] }
def medianStrip :=
  { Build.rect 50 .medianOrDivider (m (-60)) (cm (-10)) (m (-6)) (cm 10) with ways := some [10] }

def markedStreet :=
  [hwyA, hwyB, junction, laneInner, laneOuter, laneOncomingInner, laneOncomingOuter,
    laneNorthbound, laneSouthbound]
def plainStreet :=
  [hwyA, hwyB, junction, roadwayEast, roadwayWest, centreLine, roadwayNorthbound,
    roadwaySouthbound]
def widePlainStreet :=
  [hwyA, hwyB, junction, wideRoadwayEast, roadwayWest, centreLine, roadwayNorthbound,
    roadwaySouthbound]
def dividedStreet :=
  [hwyA, hwyB, junction, roadwayEast, roadwayWest, medianStrip, roadwayNorthbound,
    roadwaySouthbound]
def halfMarkedStreet :=
  [hwyA, hwyB, junction, roadwayEast, laneOncomingInner, laneOncomingOuter, centreLine,
    roadwayNorthbound, roadwaySouthbound]

/-- The subject: a motor vehicle heading east, at the given place. -/
def subjectAtXY (x y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east (Units.kmh 30) (m 2, cm 90, cm 75)

/-- The subject approaching from the west, 14 m short of the junction, at the given lateral
    position. -/
def subjectAt (y : Q) : RoadUser := subjectAtXY (m (-20)) y

/-- The same body, a bicycle: no member of the admitted aggregate. -/
def bicycleAt (y : Q) : RoadUser :=
  Build.user 1 [.bicycle] (m (-20), y) Build.east (Units.kmh 20) (cm 90, cm 30, cm 90)

/-- The source's declaration current at the junction: a left turn there, or not. -/
def turningLeft : List DeclaredIntent := [{ vehicle := 1, target := 12, values := [("int.left_turn", true)] }]
def notTurningLeft : List DeclaredIntent := [{ vehicle := 1, target := 12, values := [("int.left_turn", false)] }]

/-- `forbid` (violated): An undivided street with two marked lanes in each direction, opposed designated directions and no median, meets another such street. The subject approaches the junction in the right-hand lane of its direction, ordinal 2 of 2, while the source declares an intention to turn left at that junction; no other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-540)) ]
      markedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 21)]) (intents := turningLeft)

/-- `permit` (compliant): The same street and declared left-turn intention, but the subject approaches in the left-hand lane of its direction, ordinal 1 of 2, which abuts the centreline. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-180)) ]
      markedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 20)]) (intents := turningLeft)

/-- `idle` (not_applicable): The subject approaches the same junction in the right-hand lane with no declaration at all for it at that junction, so the source's plan does not decide a left turn there and the duty does not arise. (Core reads an undeclared pair as unknown, not as false, so the scene carries the declaration current for the subject at that junction, which does not plan a left turn there.) -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-540)) ]
      markedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 21)]) (intents := notTurningLeft)

/-- `blind` (unknown): The same approach and declared intention, but the source does not observe lane ordinals or lane counts, and the roadway's lanes are mapped, so neither the leftmost-lane reading nor the no-lane reading can be decided and the rule reports unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-540)) ]
      markedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 21)]) (intents := turningLeft)

/-- `branch_1` (compliant): An undivided two-way road with no marked lanes meets another such road. The subject approaches with a declared left-turn intention, keeping 1.2 m to the right of the mapped centreline, which lies to its left within the proximity reach. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-120)) ]
      plainStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 30)]) (intents := turningLeft)

/-- `branch_2` (not_applicable): The subject approaches a junction with a declared left-turn intention on a highway divided by a mapped median lying on it, so that highway is not two-directional and the condition fails. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-120)) ]
      dividedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 30)]) (intents := turningLeft)

/-- `branch_3` (not_applicable): The same marked street and the same declared left turn, but the
    road user approaching in the left-hand lane is a bicycle, no member of the admitted aggregate,
    so the binder's class fails and the duty is not owed. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ bicycleAt (cm (-180)) ]
      markedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 20)]) (intents := turningLeft)

/-- `branch_4` (violated): A wide undivided road with no marked lanes. The subject approaches with
    a declared left-turn intention 5 m to the right of the mapped centreline, farther from it than
    the proximity reach, so it is not in the portion of its half nearest the centre. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m (-5)) ]
      widePlainStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 34)]) (intents := turningLeft)

/-- `branch_5` (not_applicable): The subject has reached the junction — its footprint overlaps the
    intersection itself — so it is no longer approaching it and the duty does not arise. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAtXY Q.zero (cm (-180)) ]
      markedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 11), (1, 12)]) (intents := turningLeft)

/-- `branch_6` (compliant): An undivided two-way road whose own side carries no lane region while
    the opposite side is marked into two lanes. The subject approaches with a declared left-turn
    intention 1.2 m to the right of the mapped centreline: no lane of its own direction lies on the
    way, so the centre mark decides, and it lies to its left within the reach. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (cm (-120)) ]
      halfMarkedStreet
      [ ]  -- devices
      (occupies := some [(1, 10), (1, 30)]) (intents := turningLeft)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_2a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_400_2a
