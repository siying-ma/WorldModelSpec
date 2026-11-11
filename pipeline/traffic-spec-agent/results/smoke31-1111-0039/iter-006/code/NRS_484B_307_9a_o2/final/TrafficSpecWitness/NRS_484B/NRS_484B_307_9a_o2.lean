/-
  Witnesses for NRS_484B_307_9a_o2.

  A four-leg junction: intersection 10 is the square (-10,-10)–(10,10). Lane 11, x ∈ [0,4],
  y ∈ [-40,-10], runs north and enters 10; lane 12, x ∈ [-40,-10], y ∈ [-4,0], runs east and enters
  10 from the west. Crosswalk 13, x ∈ [-14,-10], y ∈ [-10,10], marks the entrance of lane 12. Signal
  20 governs lane 11 (branch_2: the intersection 10 instead).

  x (track 1, a motor vehicle, 4 m × 2 m) comes north up lane 11 at 5 m/s, is in lane 11 at 0 s,
  straddles lane 11 and the intersection at 1 s (its entry), then turns left and heads west through
  the intersection at y = 2 (at 2 s at (-2,2), at 3 s at (-7,2)). Occupancy is stated per scene, the
  body straddling two regions at the entry.

  A pedestrian (track 2) stands in crosswalk 13 at (-12,2), on x's path: at 2 s the predicted
  closest approach is 2 s ahead at 0 m, inside the 4.1 s gap and the 3.0 m radius. In branch_1 a
  second motor vehicle (track 3) stands in the intersection at (-8,2) instead.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def iId : RegionId := 10
def northIn : RegionId := 11
def eastIn : RegionId := 12
def westCrosswalk : RegionId := 13
def sigId : DeviceId := 20

def structures : List Structure :=
  [ Build.rect iId .intersection (m (-10)) (m (-10)) (m 10) (m 10)
  , Build.lane northIn [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north
      (enters := some iId)
  , Build.lane eastIn [(m (-40), m (-4)), (m (-10), m (-4)), (m (-10), m 0), (m (-40), m 0)] Build.east
      (enters := some iId)
  , { Build.rect westCrosswalk .crosswalk (m (-14)) (m (-10)) (m (-10)) (m 10) with
        marked := some true, entranceOf := [eastIn], entranceObserved := true } ]

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

/-- x at instant k: approaching, entering, then turning left and heading west. -/
def xAt (k : Nat) : RoadUser :=
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m 2, m (-16)) Build.north (Units.metresPerSecond 5) carExtent
  | 1 => Build.user 1 [.motorVehicle] (m 2, m (-9)) Build.north (Units.metresPerSecond 5) carExtent
  | 2 => Build.user 1 [.motorVehicle] (m (-2), m 2) Build.west (Units.metresPerSecond 5) carExtent
  | _ => Build.user 1 [.motorVehicle] (m (-7), m 2) Build.west (Units.metresPerSecond 5) carExtent

def xOccupies (k : Nat) : List (TrackId × RegionId) :=
  match k with
  | 0 => [(1, northIn)]
  | 1 => [(1, northIn), (1, iId)]
  | _ => [(1, iId)]

def pedestrian : RoadUser :=
  Build.user 2 [.pedestrian] (m (-12), m 2) Build.south (Units.metresPerSecond 0) pedExtent

def otherCar : RoadUser :=
  Build.user 3 [.motorVehicle] (m (-8), m 2) Build.north (Units.metresPerSecond 0) carExtent

def arrowLeft : List SignalIndication := [.circularRed, .greenArrow .left]

/-- A four-instant left turn with the given others (and their occupancy) and signal. -/
def turnTrace (others : List RoadUser) (othersOcc : List (TrackId × RegionId)) (sig : Device) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (xAt k :: others) structures [sig]
      (occupies := some (xOccupies k ++ othersOcc))

/-- `forbid` (violated): x (ru.motor_vehicle), recorded from upstream, entered i under circular_red with green_arrow(left) and is turning left, moving; a ru.pedestrian occupies the crosswalk that marks the entrance of the carrier on the leg x turns into, and prim.closest_approach_within holds over p.immediate_hazard_gap with a prim.closest_approach_distance below p.conflict_clearance. -/
def forbidTrace : Trace :=
  turnTrace [pedestrian] [(2, westCrosswalk)] (Build.signal sigId [northIn] arrowLeft)

/-- `permit` (compliant): x, recorded from upstream, enters i under circular_red with green_arrow(left) and turns left with no other road user in the scene. -/
def permitTrace : Trace :=
  turnTrace [] [] (Build.signal sigId [northIn] arrowLeft)

/-- `idle` (not_applicable): x enters i while s displays circular_green. -/
def idleTrace : Trace :=
  turnTrace [] [] (Build.signal sigId [northIn] [.circularGreen])

/-- `blind` (unknown): x, recorded from upstream, moves through i with a pedestrian approaching in a crosswalk at the entrance of the leg x turns into, but the source does not observe s's state at x's entry. -/
def blindTrace : Trace :=
  turnTrace [pedestrian] [(2, westCrosswalk)] (Build.signal sigId [northIn] arrowLeft)

/-- `branch_1` (violated): as `forbid`, but the party in danger is another motor vehicle standing
    in the intersection on x's path, and no pedestrian is present. -/
def branch1Trace : Trace :=
  turnTrace [otherCar] [(3, iId)] (Build.signal sigId [northIn] arrowLeft)

/-- `branch_2` (violated): as `forbid`, but the signal is recorded as governing the intersection
    itself, not x's approach lane. -/
def branch2Trace : Trace :=
  turnTrace [pedestrian] [(2, westCrosswalk)] (Build.signal sigId [iId] arrowLeft)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9a_o2
