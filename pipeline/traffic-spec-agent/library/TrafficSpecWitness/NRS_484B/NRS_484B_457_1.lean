/-
  Witnesses for NRS_484B_457_1.

  Geometry (world frame, +x east, +y north; every figure is the witness's own):
  - Highway 100: the rectangle x ∈ [-60, 60], y ∈ [-3, 16]; every lane, roadway and edge below lies
    on it (`ways := [100]`).
  - Two-way curbed street (`street`): right road edge 20 at y ∈ [-0.2, 0]; eastbound lane 10 at
    y ∈ [0, 3.5] (left double solid, right curb); westbound lane 11 at y ∈ [3.5, 7] (left double
    solid, right curb); far road edge 21 at y ∈ [7, 7.2].
  - The subject (track 1) is a motor vehicle 4.8 m × 1.8 m (half extents 2.4, 0.9, 0.75) at x = 0,
    heading east (its right is south, towards edge 20), at rest unless stated. With its centre at
    y = 2.1 its body is 1.2 m from edge 20 (forbid); at y = 1.15, 0.25 m (permit); at y = 2.4, 1.5 m
    (the branch scenes). 18 inches is 0.4572 m.
  - One-way street (branch_2): roadway 30 (one-way, designated east) at y ∈ [0, 8.1], lanes 10
    (y ∈ [0, 4], no curb) and 12 (y ∈ [4, 8.1], left side curb), right edge 20 at y ∈ [-0.2, 0],
    left edge 22 at y ∈ [8.1, 8.3]; the subject at y = 6.9 is 0.3 m from edge 22 and 6.0 m from 20.
  - Angle bays (branch_3): bay 40 (parking space, angle 60°) at x ∈ [-3, 3], y ∈ [0, 7], next to
    edge 20; lane 10 at y ∈ [7, 10.5] (no curb), lane 11 westbound at y ∈ [10.5, 14] (right side
    curb), edge 21 at y ∈ [14, 14.2]; the subject at (0, 4) heads 60° north of east.
  - Devices govern lane 10: a signal (branch_1), a stop sign, a yield sign, a railway gate, a person
    directing traffic (branch_5..8), an angle-parking sign with an unconditional legend (branch_9).
  - Instants: 3 scenes at 1 s; the rule reads no history.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_457_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_457_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 100 .highway (m (-60)) (m (-3)) (m 60) (m 16)

/-- A lane across the whole highway between `y0` and `y1`, lying on highway 100. -/
def laneAt (id : RegionId) (y0 y1 : Q) (dir : Vec) (left right : MarkingType) : Structure :=
  { Build.lane id [(m (-60), y0), (m 60, y0), (m 60, y1), (m (-60), y1)] dir with
    ways := some [100]
    lane := some { direction := some dir
                   markingLeft := some (left, .white)
                   markingRight := some (right, .white) } }

/-- A road edge strip across the whole highway between `y0` and `y1`, lying on highway 100. -/
def edgeAt (id : RegionId) (y0 y1 : Q) : Structure :=
  { Build.rect id .roadEdge (m (-60)) y0 (m 60) y1 with ways := some [100] }

def car (track : TrackId) (x y : Q) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) heading speed (cm 240, cm 90, cm 75)

/-- The two-way curbed street. -/
def street : List Structure :=
  [ highway
  , edgeAt 20 (cm (-20)) (m 0)
  , laneAt 10 (m 0) (cm 350) Build.east .doubleSolid .curb
  , laneAt 11 (cm 350) (m 7) Build.west .doubleSolid .curb
  , edgeAt 21 (m 7) (cm 720) ]

def onStreet (users : List RoadUser) (devices : List Device := []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) users street devices

/-- `forbid` (violated): A vehicle at rest (kin.speed 0) for 30 s in the curb lane of a two-way highway whose rightmost lane's right side is marked type curb; heading along the lane direction; the right road edge lies 1.2 m from its body; no device governs its lane, nobody is ahead of it, no angle sign or bay, no left-curb declaration. -/
def forbidTrace : Trace := onStreet [car 1 (m 0) (cm 210) Build.east (m 0)]

/-- `permit` (compliant): The same vehicle at rest with its heading along the lane direction and the right road edge 0.25 m from its body. -/
def permitTrace : Trace := onStreet [car 1 (m 0) (cm 115) Build.east (m 0)]

/-- `idle` (not_applicable): The vehicle moves at 10 m/s along the curbed highway (kin.speed 10). -/
def idleTrace : Trace := onStreet [car 1 (m 0) (cm 210) Build.east (Units.metresPerSecond 10)]

/-- `blind` (unknown): As in forbid, but the source declares region outlines absent, so the body-to-edge distance and the lateral offsets are unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): The vehicle is at rest 1.5 m from the right edge in a lane governed by a traffic signal showing circular_red: a halt in the stream of traffic. -/
def branch_1Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0)] [Build.signal 50 [10] [.circularRed]]

/-- `branch_2` (compliant): On a one-way roadway with asm.left_curb_parking_permitted declared true, the vehicle is at rest heading along the roadway direction with the left road edge 0.3 m from its body and the right edge 6 m away. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m 0) (cm 690) Build.east (m 0) ]
      [ highway
      , edgeAt 20 (cm (-20)) (m 0)
      , { Build.rect 30 .oneWayRoadway (m (-60)) (m 0) (m 60) (cm 810) with
          ways := some [100]
          lane := some { direction := some Build.east } }
      , laneAt 10 (m 0) (m 4) Build.east .broken .solid
      , laneAt 12 (m 4) (cm 810) Build.east .curb .broken
      , edgeAt 22 (cm 810) (cm 830) ]
      []
      (assumptions := [("asm.left_curb_parking_permitted", true)])

/-- `branch_3` (compliant): The vehicle is at rest in a parking space whose angle is 60 deg, heading 60 deg off the lane direction, far from the right edge. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m 0) (m 4) (Units.ratio 1 2, Units.ratio 866 1000) (m 0) ]
      [ highway
      , edgeAt 20 (cm (-20)) (m 0)
      , { Build.rect 40 .parkingSpace (m (-3)) (m 0) (m 3) (m 7) with
          ways := some [100]
          parkingAngle := some (Units.degrees 60) }
      , laneAt 10 (m 7) (cm 1050) Build.east .doubleSolid .solid
      , laneAt 11 (cm 1050) (m 14) Build.west .doubleSolid .curb
      , edgeAt 21 (m 14) (cm 1420) ]
      []

/-- `branch_4` (not_applicable): The vehicle is at rest 2 m behind another vehicle ahead of it in the same lane, 1.5 m from the right edge: a queue halt. -/
def branch_4Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0), car 2 (cm 680) (cm 240) Build.east (m 0)]

/-- `branch_5` (not_applicable): at rest 1.5 m from the right edge in a lane a stop sign governs. -/
def branch_5Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0)] [Build.sign 51 .stopSign [10]]

/-- `branch_6` (not_applicable): at rest 1.5 m from the right edge in a lane a yield sign governs. -/
def branch_6Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0)] [Build.sign 52 .yieldSign [10]]

/-- `branch_7` (not_applicable): at rest 1.5 m from the right edge in a lane a railway gate governs. -/
def branch_7Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0)]
    [{ Build.device 53 .railwaySignalOrGate [10] with railLights := some .flashing, gate := some .down }]

/-- `branch_8` (not_applicable): at rest 1.5 m from the right edge in a lane a flagger directs. -/
def branch_8Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0)]
    [{ Build.device 54 .humanDirection [10] with humanRole := some .flagger, humanIndication := some .stop }]

/-- `branch_9` (compliant): at rest 1.5 m from the right edge in a lane governed by an unconditional
    angle-parking sign: angle parking permitted there. -/
def branch_9Trace : Trace :=
  onStreet [car 1 (m 0) (cm 240) Build.east (m 0)]
    [{ Build.sign 55 .regulatorySign [10] with code := some .angleParking, conditions := some {} }]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_457_1"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .notApplicable
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_457_1
