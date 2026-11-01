/-
  Witnesses for NRS_484B_600_1e.

  The geometry. A straight rural highway running east: a highway region 1000 m long and 20 m wide
  about the origin (region 10), with one eastbound travel lane 4 m wide on its north half
  (region 11). The subject is track 1, a body 4 m long and 1.8 m wide carried at y = 2 m, inside
  the lane; in `idle` the same place carries a bicycle (1.8 m by 0.6 m). Each trace is three
  instants a second apart and the body advances by its own speed between them, its path length
  counted from the first instant. No device is posted anywhere: this paragraph's cap is the
  statute's own and no witness reads a sign. `branch_2` drops the structures too, so the subject
  is the only thing in the scene.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: veh ↦ 1

/-- Half-extents: a passenger car, 4 m by 1.8 m by 1.5 m. -/
def carHalf : Q × Q × Q := (m 2, cm 90, cm 75)

/-- Half-extents: a bicycle, 1.8 m by 0.6 m by 1.2 m. -/
def bikeHalf : Q × Q × Q := (cm 90, cm 30, cm 60)

/-- The highway region: 1000 m of rural way, 20 m wide. -/
def highway : Structure := Build.rect 10 .highway (m (-500)) (m (-10)) (m 500) (m 10)

/-- The eastbound travel lane, 4 m wide on the north half of the way. -/
def travelLane : Structure :=
  Build.lane 11
    [ (m (-500), Q.zero), (m 500, Q.zero), (m 500, m 4), (m (-500), m 4) ]
    Build.east (ordinal := some 1) (count := some 1)

def ways : List Structure := [highway, travelLane]

/-- How far the body has run from the first instant, at its own speed, a second apart. -/
def along (k : Nat) (v : Q) : Q := Q.mul (Q.ofInt (Int.ofNat k)) v

/-- The subject at the `k`-th instant: a body of `classes` in the lane, running east at `v`. -/
def subjectAt (classes : List RoadUserClass) (halfExtent : Q × Q × Q) (v : Q) (k : Nat) : RoadUser :=
  Build.user 1 classes (along k v, m 2) Build.east v halfExtent (pathLength := some (along k v))

/-- A three-instant trace of the subject alone on the way, at speed `v`. -/
def wayTrace (classes : List RoadUserClass) (halfExtent : Q × Q × Q) (v : Q) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ subjectAt classes halfExtent v k ] ways [ ]

/-- `forbid` (violated): A passenger car, a class included in DEF-NRS-484A-320::vehicle, travels on a rural highway at kin.speed 40 m/s, about 90 miles per hour: above the statute's cap, so violated, whatever is posted for that stretch. -/
def forbidTrace : Trace :=
  wayTrace [.motorVehicle] carHalf (Units.metresPerSecond 40)

/-- `permit` (compliant): The same car travels at kin.speed 33 m/s, about 74 miles per hour: at or below the cap, so compliant under this paragraph. -/
def permitTrace : Trace :=
  wayTrace [.motorVehicle] carHalf (Units.metresPerSecond 33)

/-- `idle` (not_applicable): The subject is a bicycle, a device moved by human power, which NRS 484A.320 excludes and the reading classes as excluded from DEF-NRS-484A-320::vehicle; it runs downhill at kin.speed 14 m/s. ru.aggregate is false for the subject, so the cap does not engage: not_applicable. -/
def idleTrace : Trace :=
  wayTrace [.bicycle] bikeHalf (Units.metresPerSecond 14)

/-- `blind` (unknown): A passenger car is present on the highway but the source's capability manifest declares kin.speed absent, so no speed is observed for it. The cap cannot be compared with anything, and the rule reports unknown rather than compliance. -/
def blindTrace : Trace :=
  wayTrace [.motorVehicle] carHalf (Units.metresPerSecond 40)

/-- `branch_1` (compliant): The car travels at kin.speed 35.76 m/s, exactly 80 miles per hour, on an unposted rural highway: the law forbids a rate 'greater than' the figure, so equalling it complies. -/
def branch_1Trace : Trace :=
  wayTrace [.motorVehicle] carHalf (Units.mph 80)

/-- `branch_2` (violated): The subject is the only road user in the scene, on an unposted highway with no device and no other party anywhere, at kin.speed 40 m/s: violated, so the cap is shown to bind the subject alone. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.motorVehicle] carHalf (Units.metresPerSecond 40) k ] [ ] [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("veh", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1e
