/-
  Witnesses for NRS_484B_560_7a.

  Geometry (the witness's own figures, none of them in the rule): a roadway (region 10) along
  y = 0 from x = −100 m to 100 m, 10 m wide; a railway level crossing (region 20) across it from
  x = 0 to x = 6 m. The car (track 1, a motor vehicle) drives east along y = 0; its body is 4.5 m
  long (half-length 2.25 m), so its outline overlaps the crossing while its centre lies strictly
  between −2.25 m and 8.25 m, and its trailing end stands (centre − 2.25 − 6) m past the crossing
  once it has left it. 15 ft is 4.572 m: a trailing end 2 m past keeps the car crossing, 6 m or
  more past has completely crossed. Every trace starts with the car more than 12 m short of the
  crossing, so the first observation decides that it has not entered. Instants are 1 s apart.
  Occupancy is stated from the outline, so a body across the roadway and the crossing is on both.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_7a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_7a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def roadId : RegionId := 10
def crossingId : RegionId := 20
def stopLineId : RegionId := 30

def road : Structure := Build.rect roadId .roadway (m (-100)) (m (-5)) (m 100) (m 5)
def crossing : Structure := Build.rect crossingId .railwayCrossing (m 0) (m (-5)) (m 6) (m 5)
def stopLine : Structure := Build.rect stopLineId .stopLine (m 10) (m (-5)) (cm 1030) (m 5)

def halfCar : Q × Q × Q := (cm 225, m 1, cm 75)

/-- The car with its centre at `centreCm` (cm along y = 0) and speed `speedCm` (cm/s). -/
def car (centreCm speedCm : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm centreCm, Q.zero) Build.east (cm speedCm) halfCar

/-- A truck standing in the queue beyond the crossing, centre 12 m (rear end 9.75 m). -/
def truck : RoadUser :=
  Build.user 2 [.truck] (m 12, Q.zero) Build.east Q.zero halfCar

/-- A truck standing in the queue 2.5 m ahead of the car halted just past the crossing. -/
def truckFar : RoadUser :=
  Build.user 2 [.truck] (m 17, Q.zero) Build.east Q.zero halfCar

/-- A police officer directing traffic on the roadway to stop. -/
def officer : Device :=
  { Build.device 40 .humanDirection [roadId] with
    humanRole := some .policeOfficer, humanIndication := some .stop }

/-- Whether the car's outline overlaps the crossing (strictly, no touching case is built). -/
def onCrossing (centreCm : Int) : Bool := centreCm + 225 > 0 && centreCm - 225 < 600

/-- Occupancy from the outlines: the car on the roadway and on the crossing while it overlaps
    it; every other track on the roadway. -/
def occ (centreCm : Int) (others : List TrackId) : List (TrackId × RegionId) :=
  ((1, roadId) :: (if onCrossing centreCm then [(1, crossingId)] else [])) ++
    others.map fun o => (o, roadId)

/-- A trace from the car's (centre cm, speed cm/s) per instant, with the other users, the
    structures and the devices fixed. -/
def carTrace (frames : List (Int × Int)) (others : List RoadUser) (structures : List Structure)
    (devices : List Device) : Trace :=
  Build.trace frames.length 0 (Units.seconds 1) fun k t =>
    let (c, v) := frames.getD k (0, 0)
    Build.scene t (some 1) (car c v :: others) structures devices
      (some (occ c (others.map (·.track))))

/-- The car approaches, enters the crossing and halts on it, outline still overlapping it. -/
def forbidFrames : List (Int × Int) :=
  [(-1500, 500), (-1000, 500), (-500, 500), (100, 200), (200, 0), (200, 0), (200, 0)]

/-- `forbid` (violated): A passenger car (a class the reading includes under DEF-NRS-484A-320::vehicle) drives along a roadway, enters a railway crossing r (st.railway_crossing with its outline) and, with a truck queued just beyond the crossing, halts with its footprint still overlapping r for several observations. No human direction is in the scene. -/
def forbidTrace : Trace :=
  carTrace forbidFrames [truck] [road, crossing] []

/-- `permit` (compliant): The car enters the crossing, travels across it at a steady speed without halting, and halts only well after its body outline has stood more than 15 ft past the crossing region. -/
def permitTrace : Trace :=
  carTrace
    [(-1500, 500), (-1000, 500), (-500, 500), (0, 500), (500, 500), (1000, 500), (1500, 500),
     (2000, 500), (2500, 500), (2500, 0), (2500, 0)]
    [] [road, crossing] []

/-- `idle` (not_applicable): The car drives on a roadway with no railway crossing in the scene and halts at a stop line. -/
def idleTrace : Trace :=
  carTrace [(-1500, 500), (-1000, 500), (-500, 500), (0, 500), (500, 300), (775, 0), (775, 0)]
    [] [road, stopLine] []

/-- `blind` (unknown): As forbid, but the source does not observe speed, so whether the car is halted on the crossing is unknown. -/
def blindTrace : Trace :=
  carTrace forbidFrames [truck] [road, crossing] []

/-- `branch_1` (violated): The car crosses the rails, leaves the crossing region, and halts behind a queue with its trailing end a short distance past the crossing, less than 15 ft from it. -/
def branch_1Trace : Trace :=
  carTrace
    [(-1500, 500), (-1000, 500), (-500, 500), (0, 500), (500, 500), (1025, 0), (1025, 0), (1025, 0)]
    [truckFar] [road, crossing] []

/-- `branch_2` (compliant): The car halts on the crossing while a police officer (dev.human_direction, role police_officer, indication stop) governing the roadway the car occupies directs it to stop. -/
def branch_2Trace : Trace :=
  carTrace forbidFrames [] [road, crossing] [officer]

/-- `branch_3` (compliant): No other road user is in the scene: the car crosses alone, its body outline reaches more than 15 ft past the crossing, and it halts there. -/
def branch_3Trace : Trace :=
  carTrace
    [(-1500, 500), (-1000, 500), (-500, 500), (0, 500), (500, 500), (1000, 500), (1425, 0), (1425, 0),
     (1425, 0)]
    [] [road, crossing] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_560_7a"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_560_7a
