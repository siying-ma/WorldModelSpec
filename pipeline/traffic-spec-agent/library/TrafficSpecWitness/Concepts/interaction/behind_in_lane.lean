/-
  Witnesses for drv.interaction.behind_in_lane.

  The geometry. Every scene is a straight stretch of road running east (+x), laid out from x = −20 m
  to x = 200 m; three observations a second apart, both road users travelling east at 20 m/s. Track 1
  (the formal `a`) is a car, half-extents 2 m × 1 m × 0.75 m; track 2 (the formal `b`) is a van,
  half-extents 3 m × 1.2 m × 1.2 m. No measured relation is written in any scene: the order along the
  lane and the heading alignment are both computed by Core from the lanes, the occupancy and the
  kinematics.

  `holds`: one lane (region 10, 3.6 m wide, direction east). The car starts at the lane's centre line
  and the van is 30 m in front of it throughout (x = 0/20/40 against 30/50/70), so the van is ahead of
  the car along the lane's direction at every instant. The car's heading is 0.29° north of east
  (the vector (1, 1/200)) and it travels along that heading, 10 cm of lateral drift per second; the
  van heads due east. The cosine between the headings is above 0.99998 — inside the instance's
  tolerance of 0.9 — so the body holds at all three instants.

  `fails`: two lanes of the same direction, the right lane (region 10, y ∈ [−3.6, 0]) and the centre
  lane (region 11, y ∈ [0, 3.6]) beside it, each naming the other as its neighbour. The car runs
  1.8 m inside the right lane and the van 1.8 m inside the centre lane, both at the same x: they share
  no lane and neither is ahead of the other along one, so the in-lane order is false and the body
  fails. Their headings are aligned, so it is the shared-lane element that decides.

  `blind`: one road surface (region 10, 7.2 m wide) that the source maps as a roadway whose division
  into lanes it cannot tell (`unobservedKinds := [.lane]`), with `rel.ahead_behind_in_lane` declared
  absent in the manifest. The van runs 30 m in front of the car, both due east, both on that surface,
  so the headings are aligned; but whether the surface they share is a lane is unobserved and the
  source reports no in-lane order, so the atom is unknown and with it the body.

  Figures of this witness's own: the lane widths and lengths, the 30 m spacing, the 20 m/s speed, the
  bodies' extents, the car's 0.29° heading offset, and the value 0.9 the instance gives `cos_min`
  (about 25.8°, room for lane-keeping yaw and heading noise).
-/
import TrafficSpec.Concepts.interaction.behind_in_lane
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.behind_in_lane

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: no literal formal, and `cos_min` given the value 0.9
    (about 25.8°) through `Units.ratio`. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.behind_in_lane@w"
    concept := "drv.interaction.behind_in_lane"
    literals := []
    nats := []
    params := [("cos_min", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- 0.29° north of east: the car's heading in `holds`, inside the instance's tolerance. -/
def carHeading : Vec := (Units.ratio 1 1, Units.ratio 1 200)

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)
def vanExtent : Q × Q × Q := (m 3, cm 120, cm 120)
def cruise : Q := Units.metresPerSecond 20

/-- The single lane of `holds`: 3.6 m wide about y = 0, running east. -/
def oneLane : Structure :=
  Build.lane 10 [(m (-20), cm (-180)), (m 200, cm (-180)), (m 200, cm 180), (m (-20), cm 180)]
    Build.east

/-- The right lane of `fails`, with the centre lane on its left. -/
def rightLane : Structure :=
  Build.lane 10 [(m (-20), cm (-360)), (m 200, cm (-360)), (m 200, m 0), (m (-20), m 0)]
    Build.east (left := some 11)

/-- The centre lane of `fails`, with the right lane on its right. -/
def centreLane : Structure :=
  Build.lane 11 [(m (-20), m 0), (m 200, m 0), (m 200, cm 360), (m (-20), cm 360)]
    Build.east (right := some 10)

/-- The road surface of `blind`: a roadway whose division into lanes the source cannot tell. -/
def unresolvedRoadway : Structure :=
  { Build.rect 10 .roadway (m (-20)) (cm (-360)) (m 200) (cm 360) with
      unobservedKinds := [.lane] }

/-- `holds` (compliant): A car and the van 30 m in front of it occupy the same lane, the van recorded ahead of the car along the lane's direction, both headings east within a degree. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let i : Int := k
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * i), cm (10 * i)) carHeading cruise carExtent
      , Build.user 2 [.motorVehicle] (m (30 + 20 * i), m 0) Build.east cruise vanExtent ]
      [ oneLane ]
      []

/-- `fails` (violated): A car in the right lane and a van in the centre lane travel abreast: neither is recorded ahead of the other in a shared lane. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let i : Int := k
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * i), cm (-180)) Build.east cruise carExtent
      , Build.user 2 [.motorVehicle] (m (20 * i), cm 180) Build.east cruise vanExtent ]
      [ rightLane, centreLane ]
      []

/-- `blind` (unknown): A car and a van travel in the same direction on a laned road, but the source declares the in-lane order of road users absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let i : Int := k
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 * i), cm (-180)) Build.east cruise carExtent
      , Build.user 2 [.motorVehicle] (m (30 + 20 * i), cm (-180)) Build.east cruise vanExtent ]
      [ unresolvedRoadway ]
      []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.ahead_behind_in_lane"] ]

end TrafficSpecWitness.Concepts.interaction.behind_in_lane
