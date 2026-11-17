/-
  Witnesses for NRS_486_351_1.

  Geometry (the witness's own figures; none appears in the rule). Everything heads east (+x) at
  10 m/s; three instants 1 s apart, every body advancing 10 m per instant.
  - Same-direction carriageway: lane 10 (L1, the left lane, y 4..8 m, ordinal 1 of 2, right
    neighbour 11) and lane 11 (L2, the right lane, y 0..4 m, ordinal 2 of 2, left neighbour 10),
    x −100..400 m.
  - Opposite-direction carriageway (branch_4): lane 12 (westbound, y 4..8 m) and lane 13
    (eastbound, y 0..4 m), each the only lane of its direction (ordinal 1 of 1, no neighbour).
  - The subject (track 1): half-length 1 m, half-width 40 cm. Cars (tracks 2, 3): half-length 2 m,
    half-width 90 cm, centred 2 m ahead of the subject, so each shares 1 m of the subject's
    longitudinal projection.
  - blind: the forbid scene, the subject's heading (hence its footprint and occupancy)
    unobserved and the overlaps measured (1 m); the lanes are adjacent by neighbour.
  - Straddling (forbid, idle, branch_1, branch_3, branch_4, branch_6): the subject on the
    lane line y = 4 m, its footprint in both lanes (occupancy stated); car 2 at y = 6 m (left, in
    L1), car 3 at y = 2 m (right, in L2).
  - permit: the subject at y = 6 m in L1, car 2 in L1 12 m ahead (centre to centre, a 9 m gap
    between projections), car 3 in L2 2 m ahead (overlap 1 m, to the right); nothing on its left.
  - branch_5: the subject wholly within L2 near its left edge (y = 3.4 m), car 3 in L2 at
    y = 1.5 m on its right, car 2 in L1 on its left; the lanes adjacent by neighbour only.
-/
import TrafficSpec.Rules.NRS_486.NRS_486_351_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_486_351_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def speed : Q := Units.metresPerSecond 10
def motoExtent : Q × Q × Q := (m 1, cm 40, cm 70)
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- x of the subject at instant k. -/
def xAt (k : Nat) (base : Int) : Q := m (base + 10 * (Int.ofNat k))

/-- Same-direction lanes: L1 (10) left, L2 (11) right. -/
def laneL1 : Structure :=
  Build.lane 10 [(m (-100), m 4), (m 400, m 4), (m 400, m 8), (m (-100), m 8)] Build.east
    none (some 11) (some 1) (some 2)
def laneL2 : Structure :=
  Build.lane 11 [(m (-100), m 0), (m 400, m 0), (m 400, m 4), (m (-100), m 4)] Build.east
    (some 10) none (some 2) (some 2)
def sameDirLanes : List Structure := [laneL1, laneL2]

/-- Opposite-direction lanes: 12 westbound (north half), 13 eastbound (south half). -/
def laneWest : Structure :=
  Build.lane 12 [(m (-100), m 4), (m 400, m 4), (m 400, m 8), (m (-100), m 8)] Build.west
    none none (some 1) (some 1)
def laneEast : Structure :=
  Build.lane 13 [(m (-100), m 0), (m 400, m 0), (m 400, m 4), (m (-100), m 4)] Build.east
    none none (some 1) (some 1)
def oppDirLanes : List Structure := [laneWest, laneEast]

/-- No warning lamp lit. -/
def dark (u : RoadUser) : RoadUser := Build.withSignals u fun s => { s with warningLamps := some [] }

def motorcycleAt (p : Vec) : RoadUser :=
  dark (Build.user 1 [.motorcycle] p Build.east speed motoExtent)
def mopedAt (p : Vec) : RoadUser :=
  dark (Build.user 1 [.moped] p Build.east speed motoExtent)
def bicycleAt (p : Vec) : RoadUser :=
  dark (Build.user 1 [.bicycle] p Build.east speed motoExtent)
def policeMotorcycleAt (p : Vec) (lamps : List WarningLamp) : RoadUser :=
  let u := Build.user 1 [.motorcycle, .emergencyVehicle] p Build.east speed motoExtent
  Build.withSignals { u with emergencyKind := some .police } fun s => { s with warningLamps := some lamps }
def carAt (track : TrackId) (p : Vec) (h : Vec := Build.east) : RoadUser :=
  dark (Build.user track [.motorVehicle] p h speed carExtent)

/-- The straddling scene: the subject on the lane line, car 2 on its left in the upper lane, car 3
    on its right in the lower lane; occupancy stated, since the subject's reference point lies on
    the line. -/
def straddleTrace (subjectAt : Vec → RoadUser) (lanes : List Structure) (upper lower : RegionId)
    (upperHeading : Vec := Build.east) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (xAt k 50, m 4)
      , carAt 2 (xAt k 52, m 6) upperHeading
      , carAt 3 (xAt k 52, m 2) ]
      lanes
      [ ]
      (some [(1, upper), (1, lower), (2, upper), (3, lower)])

/-- `forbid` (violated): A motorcycle straddles the line between same-direction lanes L1 and L2; a car in L1 lies to its left and a car in L2 to its right, each with longitudinal overlap 1 m with the motorcycle. -/
def forbidTrace : Trace := straddleTrace motorcycleAt sameDirLanes 10 11

/-- `permit` (compliant): The motorcycle occupies L1 10 m behind a car in L1; a car in L2 lies to its right with overlap 1 m; nothing lies to its left. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ motorcycleAt (xAt k 40, m 6)
      , carAt 2 (xAt k 52, m 6)
      , carAt 3 (xAt k 42, m 2) ]
      sameDirLanes
      [ ]

/-- `idle` (not_applicable): The subject is not of the motorcycle or moped aggregates, between two
    cars in adjacent lanes. A bicycle is used: a passenger car's class (motor_vehicle) is unresolved
    in both aggregates under the run's reading, so its membership is unknown, never decided false. -/
def idleTrace : Trace := straddleTrace bicycleAt sameDirLanes 10 11

/-- `blind` (unknown): As in forbid, but rel.bearing is not observed. The manifest's mask drops a
    measured bearing only, and Core computes one from the subject's heading, so the source here
    observes no heading for the subject: the bearing cannot be computed, and the longitudinal
    overlap, which Core then cannot compute either, is supplied as the source measured it (1 m with
    each car). -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let moto := Build.withKin (motorcycleAt (xAt k 50, m 4)) fun kn => { kn with heading := none }
    let s := Build.scene t (some 1)
        [ moto
        , carAt 2 (xAt k 52, m 6)
        , carAt 3 (xAt k 52, m 2) ]
        sameDirLanes
        [ ]
        (some [(2, 10), (3, 11)])
    -- without a heading the subject has no footprint, so its occupancy is not observed
    Build.withRelations { s with occupancyObserved := [2, 3] }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (m 1) }
      , Build.relation 1 3 fun r => { r with longitudinalOverlap := some (m 1) } ]

/-- `branch_1` (not_applicable): A police motorcycle (ru.emergency_vehicle kind police) with blue sig.warning_lamp flashing rides between the two cars as in forbid. -/
def branch_1Trace : Trace :=
  straddleTrace (fun p => policeMotorcycleAt p [{ colour := .blue, mode := .flashing, facing := .front }])
    sameDirLanes 10 11

/-- `branch_3` (violated): A police motorcycle with no warning lamp lit rides between the two cars as in forbid. -/
def branch_3Trace : Trace :=
  straddleTrace (fun p => policeMotorcycleAt p []) sameDirLanes 10 11

/-- `branch_2` (compliant): The motorcycle rides alone on the highway; no other vehicle is in the scene. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ motorcycleAt (xAt k 50, m 6) ]
      sameDirLanes
      [ ]

/-- `branch_4` (violated): the motorcycle straddles the centre between a westbound lane and an
    eastbound lane (no neighbours by st.lane_adjacency), an oncoming car on its left and a car on its
    right: adjacent only through the subject's footprint overlapping both. -/
def branch_4Trace : Trace := straddleTrace motorcycleAt oppDirLanes 12 13 Build.west

/-- `branch_5` (violated): the motorcycle is wholly within L2, splitting between a car in L1 on its
    left and a car in L2 on its right: adjacent only through st.lane_adjacency. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ motorcycleAt (xAt k 50, cm 340)
      , carAt 2 (xAt k 52, m 6)
      , carAt 3 (xAt k 52, cm 150) ]
      sameDirLanes
      [ ]

/-- `branch_6` (violated): a moped straddles the lane line between the two cars as in forbid. -/
def branch_6Trace : Trace := straddleTrace mopedAt sameDirLanes 10 11

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_486_351_1"
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
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_486_351_1
