/-
  Witnesses for NRS_484B_127_3.

  The carriageway is the same in every scene: a highway region (10) between y = -1 m and
  y = 8.2 m, carrying two eastbound lanes, lane 11 (y 0 … 3.6 m, the right-hand lane) and lane 12
  (y 3.6 … 7.2 m); both run from x = -300 m to x = 400 m. Every file runs eastbound in lane 11 at
  y = 1.8 m, the subject (track 1) in the middle of it, and the bodies are placed by their centres
  so that the space between the nearest points of two consecutive bodies is the figure each
  narrative names: a car is 4.4 m long (half-extents 2.2 / 0.9 / 0.75 m), so a centre spacing of
  10.4 m is a 6 m space, 18.4 m a 14 m space, 29.4 m a 25 m space, 34.4 m a 30 m space and 44.4 m
  a 40 m space. Each scene declares asm.outside_business_district (false in `branch_4` only).

  Every figure here is the witness's own and appears nowhere in the rule. The reading this run
  evaluates against sets the standstill tolerance at 0.1 m/s, the file's minimum at 3 members and
  its reach at 50 m, the design vehicle at 6 m and the entry headway at 1.5 s, so the space a
  moving file owes is 6 m + 2 × 1.5 s × its speed: 66 m at 20 m/s, 30 m at 8 m/s, 21 m at 5 m/s
  and 9 m at 1 m/s. The geometry below breaks or keeps that bound by a clear margin.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- Half-extents: length, width, height. -/
def carExtent : Q × Q × Q := (cm 220, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 60)
/-- A 24 m combination and a 12 m bus: the entering bodies whose own length is read. -/
def truckExtent : Q × Q × Q := (m 12, cm 130, m 2)
def busExtent : Q × Q × Q := (m 6, cm 130, cm 160)

def highway : Structure := Build.rect 10 .highway (m (-300)) (m (-1)) (m 400) (cm 820)
def laneRight : Structure :=
  Build.lane 11 [(m (-300), m 0), (m 400, m 0), (m 400, cm 360), (m (-300), cm 360)]
    Build.east (some 12) none (some 2) (some 2)
def laneLeft : Structure :=
  Build.lane 12 [(m (-300), cm 360), (m 400, cm 360), (m 400, cm 720), (m (-300), cm 720)]
    Build.east none (some 11) (some 1) (some 2)
def carriageway : List Structure := [highway, laneRight, laneLeft]

def outsideBusinessDistrict : AsmId × Bool := ("asm.outside_business_district", true)
def insideBusinessDistrict : AsmId × Bool := ("asm.outside_business_district", false)

/-- A body in the right-hand lane, eastbound, its centre at `xCm` centimetres. -/
def inRightLane (track : TrackId) (classes : List RoadUserClass) (xCm : Int) (speed : Q)
    (half : Q × Q × Q := carExtent) : RoadUser :=
  Build.user track classes (cm xCm, cm 180) Build.east speed half

/-- A body in the left-hand lane, eastbound, its centre at `xCm` centimetres. -/
def inLeftLane (track : TrackId) (classes : List RoadUserClass) (xCm : Int) (speed : Q)
    (half : Q × Q × Q := carExtent) : RoadUser :=
  Build.user track classes (cm xCm, cm 540) Build.east speed half

/-- Five bodies one behind another in the right-hand lane at `spacing` centimetres centre to
    centre, the subject (track 1) in the middle: tracks 2 and 3 ahead of it, 4 and 5 behind. -/
def fiveInFile (classes : List RoadUserClass) (spacing : Int) (speed : Q)
    (half : Q × Q × Q := carExtent) : List RoadUser :=
  [ inRightLane 1 classes 0 speed half
  , inRightLane 2 classes spacing speed half
  , inRightLane 3 classes (2 * spacing) speed half
  , inRightLane 4 classes (-spacing) speed half
  , inRightLane 5 classes (-2 * spacing) speed half ]

/-- Three bodies one behind another, the subject in the middle. -/
def threeInFile (classes : List RoadUserClass) (spacing : Int) (speed : Q) : List RoadUser :=
  [ inRightLane 1 classes 0 speed
  , inRightLane 2 classes spacing speed
  , inRightLane 3 classes (-spacing) speed ]

/-- `forbid` (violated): Five cars of a motorcade run in file in the same lane of a two-lane highway outside a business district, declared as such by the map, at 20 m/s with longitudinal gaps of about 6 m between consecutive bodies. The space holds no entering vehicle's length plus a clear headway at that speed. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      (fiveInFile [.motorVehicle] 1040 (mps 20))
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

/-- `permit` (compliant): five cars of the motorcade on the same highway, each holding about 40 m
    of space to its neighbours at 8 m/s: every space exceeds the 30 m an entering vehicle's length
    plus the clearance headway fore and aft comes to at that speed, by a clear 10 m. (A file at
    20 m/s cannot comply and remain a file: 66 m of space is beyond the 50 m reach within which
    this reading counts a road user as travelling in the subject's file, so the compliant scene is
    built at the lower speed.) -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      (fiveInFile [.motorVehicle] 4440 (mps 8))
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

/-- `idle` (not_applicable): A pedal cycle propelled by human power, which the motor-vehicle definition leaves out, rides in close file with four others on the same highway. No motor vehicle is bound and the rule does not engage. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      (fiveInFile [.bicycle] 280 (mps 5) bikeExtent)
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

def noExtent (u : RoadUser) : RoadUser := Build.withKin u fun k => { k with extent := none }

/-- The `forbid` bodies as a source that measures the subject's own vehicle and the places and
    headings of the others, but no body but the subject's: the spaces between the bodies and which
    body is ahead of which are measurements it supplies, and nothing in the scene lets either be
    computed, so the manifest's mask on rel.surface_gap takes the spaces away. -/
def blindUsers : List RoadUser :=
  [ inRightLane 1 [.motorVehicle] 0 (mps 20)
  , noExtent (inRightLane 2 [.motorVehicle] 1040 (mps 20))
  , noExtent (inRightLane 3 [.motorVehicle] 2080 (mps 20))
  , noExtent (inRightLane 4 [.motorVehicle] (-1040) (mps 20))
  , noExtent (inRightLane 5 [.motorVehicle] (-2080) (mps 20)) ]

def supplied (a b : TrackId) (aAhead : Bool) (longitudinal : Q) : MeasuredRelation :=
  Build.relation a b fun r =>
    { r with aAheadOfB := some aAhead, surfaceGap := some (longitudinal, Q.zero) }

/-- The measured relations of the `forbid` geometry: tracks 2 and 3 ahead of the subject, 4 and 5
    behind it, 6 m of space to each neighbour and 16.4 m to the next body on either side. -/
def blindRelations : List MeasuredRelation :=
  [ supplied 1 2 false (m 6), supplied 2 1 true (m 6)
  , supplied 1 4 true (m 6), supplied 4 1 false (m 6)
  , supplied 1 3 false (cm 1640), supplied 3 1 true (cm 1640)
  , supplied 1 5 true (cm 1640), supplied 5 1 false (cm 1640) ]

/-- `blind` (unknown): The forbid scene with the source declaring the gap between bodies absent: the file, the speeds and the declared district class are recorded, but the spaces the bound is compared with cannot be read, so the duty is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    { Build.scene t (some 1)
        blindUsers
        carriageway
        []
        (occupies := some [(1, 10), (1, 11)])
        (assumptions := [outsideBusinessDistrict]) with
      occupancyObserved := [1]
      relations := blindRelations }

/-- `branch_1` (not_applicable): A single car runs at 20 m/s on the same highway outside a business district with no other road user anywhere in the scene. The minimum member count of the file is not reached, so the subject is in no caravan and the rule does not apply, the verdict being decided although the only party is the subject. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ inRightLane 1 [.motorVehicle] 0 (mps 20) ]
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

/-- `branch_2` (compliant): the five cars of the motorcade roll to a halt in a queue. At the first
    instant they are still being driven, at 1 m/s with 14 m of space, which keeps the 9 m the bound
    comes to at that speed; at the two later instants they stand still, 6 m apart, below the
    standstill tolerance, so the rule does not reach them and no instant is violated. The verdict
    is decided on the words of the subject span. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 10) fun k t =>
    Build.scene t (some 1)
      (if k == 0 then fiveInFile [.motorVehicle] 1840 (mps 1)
       else fiveInFile [.motorVehicle] 1040 (mps 0))
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

/-- `branch_3` (violated): three cars in file at 5 m/s with 30 m of space, which keeps the 21 m the
    design vehicle's length and the headways come to; abreast of the subject in the left-hand lane
    stands a 24 m combination, no member of the file, whose own read length makes the space owed
    39 m. The space is 30 m, so the read length of the body in the scene decides the verdict. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      (threeInFile [.motorVehicle] 3440 (mps 5) ++
        [ inLeftLane 4 [.truck] 0 (mps 5) truckExtent ])
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

/-- `branch_4` (not_applicable): the forbid scene, with the map declaring the stretch of highway to
    lie inside a business district. The condition of s2 fails and the rule does not engage. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      (fiveInFile [.motorVehicle] 1040 (mps 20))
      carriageway
      []
      (assumptions := [insideBusinessDistrict])

/-- `branch_5` (violated): three cars in file at 5 m/s with 25 m of space, which keeps the 21 m the
    design vehicle needs; 60 m ahead of the subject in the same lane runs a 12 m bus, beyond the
    50 m reach of the file, so it is no member of it but a body in the scene whose length is read:
    the space owed is 27 m and the space held is 25 m. The reach that separates a member of the
    file from a road user that could enter the space decides the verdict. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      (threeInFile [.motorVehicle] 2940 (mps 5) ++
        [ inRightLane 4 [.bus] 6820 (mps 5) busExtent ])
      carriageway
      []
      (assumptions := [outsideBusinessDistrict])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_127_3
