/-
  Witnesses for NRS_484B_400_2b.

  The map (metres, +x east, +y north; every figure here is the witness's own and appears nowhere in
  the rule):

  - way A (region 1, a highway, x in [-12, 12]) runs north-south, way B (region 2, a highway,
    y in [-12, 12]) runs east-west, and they meet at the junction (region 3, kind intersection, the
    square [-12, 12] x [-12, 12], lying on ways 1 and 2).
  - way A's south leg carries two lanes: 11, northbound (x in [0, 12], y in [-120, -12]), whose
    entrance end is the junction, and 12, southbound (x in [-12, 0]); its centreline is 13
    (x in [-0.1, 0.1], on way 1).
  - way B's west leg carries the roadway 21 (x in [-120, -12], y in [-12, 12], the improved part),
    the westbound lane 22 (y in [0, 12]) and the eastbound lane 23 (y in [-12, 0]), whose entrance
    end is the junction; its centreline is 24 (y in [-0.1, 0.1], on way 2). No median is mapped on
    either way, so both are two-directional.
  - way 5 is a far highway, 200 m east, carrying one directed lane (51, eastbound) and no opposed
    one: it is not two-directional, and the junction does not lie on it.
  - the subject is track 1, a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 0.75 m).
    Occupancy is declared scene by scene, as its footprint covers the regions: the ways it is on,
    the lane or roadway under it, and the junction from the observation at which its footprint
    first reaches over the junction's edge to the last at which it still does.

  Every trace is 1 s apart and padded by 15 s of the first and last scene at each end, so that the
  10 s window the act's course change is taken over, the window behind in which the entry and the
  approach carrier are read, and the window ahead in which the departure is read are covered
  rather than truncated; each witness names the instants it speaks about (`window`), which are the
  instants of the unpadded part.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def wayA : Structure := Build.rect 1 .highway (m (-12)) (m (-120)) (m 12) (m 120)
def wayB : Structure := Build.rect 2 .highway (m (-120)) (m (-12)) (m 120) (m 12)
def wayFar : Structure := Build.rect 5 .highway (m 200) (m (-6)) (m 260) (m 6)

def junction : Structure :=
  { Build.rect 3 .intersection (m (-12)) (m (-12)) (m 12) (m 12) with ways := some [1, 2] }

def northboundApproach : Structure :=
  { Build.lane 11 [(m 0, m (-120)), (m 12, m (-120)), (m 12, m (-12)), (m 0, m (-12))]
      Build.north (enters := some 3) with ways := some [1] }

def southboundLane : Structure :=
  { Build.lane 12 [(m (-12), m (-120)), (m 0, m (-120)), (m 0, m (-12)), (m (-12), m (-12))]
      Build.south with ways := some [1] }

def centreLineA : Structure :=
  { Build.rect 13 .centreLine (cm (-10)) (m (-120)) (cm 10) (m (-12)) with ways := some [1] }

def westLegRoadway : Structure :=
  { Build.rect 21 .roadway (m (-120)) (m (-12)) (m (-12)) (m 12) with ways := some [2] }

def westboundLane : Structure :=
  { Build.lane 22 [(m (-120), m 0), (m (-12), m 0), (m (-12), m 12), (m (-120), m 12)]
      Build.west with ways := some [2] }

def eastboundApproach : Structure :=
  { Build.lane 23 [(m (-120), m (-12)), (m (-12), m (-12)), (m (-12), m 0), (m (-120), m 0)]
      Build.east (enters := some 3) with ways := some [2] }

def centreLineB : Structure :=
  { Build.rect 24 .centreLine (m (-120)) (cm (-10)) (m (-12)) (cm 10) with ways := some [2] }

/-- The only directed carrier of the far way: no region on it carries an opposed direction. -/
def farLane : Structure :=
  { Build.lane 51 [(m 200, m (-6)), (m 260, m (-6)), (m 260, m 6), (m 200, m 6)]
      Build.east with ways := some [5] }

/-- For `branch_3`: a dividing section lying on way B, which divides that highway. -/
def medianB : Structure :=
  { Build.rect 25 .medianOrDivider (m (-120)) (cm (-10)) (m (-12)) (cm 10) with ways := some [2] }

def crossing : List Structure :=
  [ wayA, wayB, wayFar, junction, northboundApproach, southboundLane, centreLineA,
    westLegRoadway, westboundLane, eastboundApproach, centreLineB, farLane ]

def dividedCrossing : List Structure := crossing ++ [medianB]

-- ---------------------------------------------------------------------------------------------
-- Scenes and traces: a step is a position, a heading, a yaw rate, the regions the footprint
-- covers, and the declaration current for the subject at the junction (none where the source
-- declares nothing).
-- ---------------------------------------------------------------------------------------------
def sceneOf (t : Timestamp) (speed : Q) (structures : List Structure)
    (step : Vec × Vec × Q × List RegionId × Option Bool) : Scene :=
  let (p, h, yaw, occ, intent) := step
  Build.scene t (some 1)
    [ Build.withKin (Build.user 1 [.motorVehicle] p h speed (m 2, m 1, cm 75))
        fun k => { k with yawRate := some yaw } ]
    structures []
    (some (occ.map fun r => (1, r)))
    {} []
    (match intent with
     | some v => [{ vehicle := 1, target := 3, values := [("int.left_turn", v)] }]
     | none => [])

def traceOf (speed : Q) (structures : List Structure)
    (steps : List (Vec × Vec × Q × List RegionId × Option Bool)) : Trace :=
  Build.pad
    (Build.trace steps.length 0 (Units.seconds 1) fun k t =>
      sceneOf t speed structures (steps[k]?.getD ((m 0, m 0), Build.north, Q.zero, [], none)))
    (Units.seconds 15) (Units.seconds 15) (Units.seconds 1)

/-- The approach up way A's northbound lane, the junction entered at the fourth observation. -/
def approach (intent : Option Bool) : List (Vec × Vec × Q × List RegionId × Option Bool) :=
  [ ((m 6, m (-26)), Build.north, Q.zero, [1, 11], intent)
  , ((m 6, m (-21)), Build.north, Q.zero, [1, 11], intent)
  , ((m 6, m (-16)), Build.north, Q.zero, [1, 11], intent)
  , ((m 6, m (-11)), Build.north, Q.zero, [1, 2, 11, 3], intent) ]

/-- `forbid` (violated): Two undivided two-way streets with mapped centrelines and no medians cross. The subject enters the junction, declares an intention to turn left there and swings through a quarter turn to the left at 5 m/s; at the observation at which its footprint ceases to overlap the junction it is on the far side of the centreline of the street it is entering, which lies to its right - a negative lateral offset - having cut the corner. -/
def forbidSteps : List (Vec × Vec × Q × List RegionId × Option Bool) :=
  approach (some true) ++
  [ ((m 3, m (-8)), Build.west, Units.degrees 90, [1, 2, 3], some true)
  , ((m (-2), m (-8)), Build.west, Q.zero, [1, 2, 3], some true)
  , ((m (-7), m (-8)), Build.west, Q.zero, [1, 2, 3], some true)
  , ((m (-12), m (-8)), Build.west, Q.zero, [1, 2, 3, 21, 23], some true)
  , ((m (-17), m (-8)), Build.west, Q.zero, [2, 21, 23], some true)
  , ((m (-22), m (-8)), Build.west, Q.zero, [2, 21, 23], some true) ]

def forbidTrace : Trace := traceOf (Units.metresPerSecond 5) crossing forbidSteps

/-- `permit` (compliant): The same crossing, intention and turn, but the subject leaves the junction in the right-hand half of the street it enters, the centreline of that street lying to its left with a positive lateral offset. -/
def permitSteps : List (Vec × Vec × Q × List RegionId × Option Bool) :=
  approach (some true) ++
  [ ((m 6, m (-6)), Build.north, Q.zero, [1, 2, 3], some true)
  , ((m 6, m (-1)), Build.north, Q.zero, [1, 2, 3], some true)
  , ((m 6, m 4), Build.north, Q.zero, [1, 2, 3], some true)
  , ((m 3, m 7), Build.west, Units.degrees 90, [1, 2, 3], some true)
  , ((m (-2), m 7), Build.west, Q.zero, [1, 2, 3], some true)
  , ((m (-7), m 7), Build.west, Q.zero, [1, 2, 3], some true)
  , ((m (-12), m 7), Build.west, Q.zero, [1, 2, 3, 21, 22], some true)
  , ((m (-17), m 7), Build.west, Q.zero, [2, 21, 22], some true) ]

def permitTrace : Trace := traceOf (Units.metresPerSecond 5) crossing permitSteps

/-- `idle` (not_applicable): The subject crosses the same junction straight through at 8 m/s with no declaration for it at that junction and no change of course: no left turn is being made, so the duty does not arise, and no other road user is in the scene. -/
def idleSteps : List (Vec × Vec × Q × List RegionId × Option Bool) :=
  [ ((m 6, m (-40)), Build.north, Q.zero, [1, 11], none)
  , ((m 6, m (-32)), Build.north, Q.zero, [1, 11], none)
  , ((m 6, m (-24)), Build.north, Q.zero, [1, 11], none)
  , ((m 6, m (-16)), Build.north, Q.zero, [1, 11], none)
  , ((m 6, m (-8)), Build.north, Q.zero, [1, 2, 3], none)
  , ((m 6, m 0), Build.north, Q.zero, [1, 2, 3], none)
  , ((m 6, m 8), Build.north, Q.zero, [1, 2, 3], none)
  , ((m 6, m 16), Build.north, Q.zero, [1], none)
  , ((m 6, m 24), Build.north, Q.zero, [1], none) ]

def idleTrace : Trace := traceOf (Units.metresPerSecond 8) crossing idleSteps

/-- `blind` (unknown): The same crossing and turn, but the source declares no footprint overlap for any region, so neither the entry into the junction nor the departure from it can be decided and the rule reports unknown. -/
def blindTrace : Trace := traceOf (Units.metresPerSecond 5) crossing permitSteps

/-- `branch_1` (violated): The subject enters the junction with no declaration, and the source declares the left-turn intention at that junction midway through the quarter turn to the left, the declaration being current at the observations judged from there on; the subject leaves the junction to the left of the centreline of the street it enters. -/
def branch_1Steps : List (Vec × Vec × Q × List RegionId × Option Bool) :=
  approach none ++
  [ ((m 6, m (-6)), (Units.ratio (-643) 1000, Units.ratio 766 1000), Units.degrees 40, [1, 2, 3], none)
  , ((m 3, m (-3)), Build.west, Units.degrees 50, [1, 2, 3], some true)
  , ((m (-2), m (-3)), Build.west, Q.zero, [1, 2, 3], some true)
  , ((m (-7), m (-3)), Build.west, Q.zero, [1, 2, 3], some true)
  , ((m (-12), m (-3)), Build.west, Q.zero, [1, 2, 3, 21, 23], some true)
  , ((m (-17), m (-3)), Build.west, Q.zero, [2, 21, 23], some true) ]

def branch_1Trace : Trace := traceOf (Units.metresPerSecond 5) crossing branch_1Steps

/-- `branch_2` (not_applicable): The source declares the left-turn intention at that junction while the subject is still approaching, and withdraws it - declaring a straight passage instead - at the observation before the change of course to the left begins, so no left-turn declaration is current at the observations judged; the subject then swings left and leaves the junction to the left of the centreline, and the duty does not arise. -/
def branch_2Steps : List (Vec × Vec × Q × List RegionId × Option Bool) :=
  approach (some true) ++
  [ ((m 6, m (-6)), (Units.ratio (-643) 1000, Units.ratio 766 1000), Units.degrees 40, [1, 2, 3], some false)
  , ((m 3, m (-3)), Build.west, Units.degrees 50, [1, 2, 3], some false)
  , ((m (-2), m (-3)), Build.west, Q.zero, [1, 2, 3], some false)
  , ((m (-7), m (-3)), Build.west, Q.zero, [1, 2, 3], some false)
  , ((m (-12), m (-3)), Build.west, Q.zero, [1, 2, 3, 21, 23], some false)
  , ((m (-17), m (-3)), Build.west, Q.zero, [2, 21, 23], some false) ]

def branch_2Trace : Trace := traceOf (Units.metresPerSecond 5) crossing branch_2Steps

/-- `branch_3` (not_applicable): the same crossing, declaration and compliant turn, but a dividing
    section lies on the street being entered, so that street is not two-directional and this
    subsection's condition fails: the duty does not arise. -/
def branch_3Trace : Trace := traceOf (Units.metresPerSecond 5) dividedCrossing permitSteps

def witness (name : String) (τ : Trace) (expected : Verdict) (lastMs : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_2b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, lastMs)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 9000
  , witness "permit" permitTrace .compliant 11000
  , witness "idle" idleTrace .notApplicable 8000
  , witness "blind" blindTrace (.unknown []) 11000 ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated 9000
  , witness "branch_2" branch_2Trace .notApplicable 9000
  , witness "branch_3" branch_3Trace .notApplicable 11000 ]

end TrafficSpecWitness.NRS_484B_400_2b
