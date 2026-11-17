/-
  Witnesses for NRS_484B_493.

  Geometry (the witness's own figures; none appears in the rule):
    · highway 1: x 0…2000 m, y −5…15 m.
    · one-way roadway 2 on highway 1: x 0…2000, y 0…10, designated direction east.
    · road edge 3 (left of east): y 10…10.2; road edge 4 (right of east): y −0.2…0; both on highway 1.
    · lanes 5 (y 5…10) and 6 (y 0…5), direction east, on highway 1.
    · regulatory sign 10, code no_parking, conditions read and empty, governing lanes 5 and 6.
    · (branch_2 only) curb zone 7 of kind no_parking, y 8…10, and no sign.
  The vehicle (track 1) is 5 m long, 2 m wide (half-extents 2.5, 1, 0.9 m). At the left edge its
  centre is at y = 8.7 (body 0.3 m from edge 3, 7.7 m from edge 4); at the right edge y = 1.3.
  Samples every 5 s, 34 of them (0…165 s). It drives at 5 m/s (25 m per sample) until sample 14
  (70 s), and then stands (speed 0) to the end (95 s ≥ the 60 s standing bound, violated from
  130 s), or, in `permit`, stands samples 14…18 (20 s < 60 s) and drives on from sample 19.
  Every witness speaks of 65…165 s, where the 60 s look-back of drv.motion.parked is covered.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_493
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_493

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 1 .highway (m 0) (m (-5)) (m 2000) (m 15)
def roadway : Structure :=
  { Build.rect 2 .oneWayRoadway (m 0) (m 0) (m 2000) (m 10) with
    lane := some { direction := some Build.east }, ways := some [1] }
def leftEdge : Structure := { Build.rect 3 .roadEdge (m 0) (m 10) (m 2000) (cm 1020) with ways := some [1] }
def rightEdge : Structure := { Build.rect 4 .roadEdge (m 0) (cm (-20)) (m 2000) (m 0) with ways := some [1] }
def laneLeft : Structure :=
  { Build.lane 5 [(m 0, m 5), (m 2000, m 5), (m 2000, m 10), (m 0, m 10)] Build.east with ways := some [1] }
def laneRight : Structure :=
  { Build.lane 6 [(m 0, m 0), (m 2000, m 0), (m 2000, m 5), (m 0, m 5)] Build.east with ways := some [1] }
def curbZone : Structure :=
  { Build.rect 7 .curbZone (m 0) (m 8) (m 2000) (m 10) with curbKind := some .noParking }

def structuresWithLanes : List Structure := [highway, roadway, leftEdge, rightEdge, laneLeft, laneRight]
def structuresWithCurb : List Structure := [highway, roadway, leftEdge, rightEdge, laneLeft, laneRight, curbZone]

def noParkingSign : Device :=
  { Build.sign 10 .regulatorySign [5, 6] with code := some .noParking, conditions := some {} }

def env : Env :=
  { civilTime := some { year := 2026, month := 3, day := 10, weekday := 1, minuteOfDay := 600 } }

def leftY : Q := cm 870
def rightY : Q := cm 130

/-- The vehicle at sample k: moving 5 m/s before `halt`, at rest for halt ≤ k < resume, moving
    again from `resume`; `dir` is +1 heading east from x = 20, −1 heading west from x = 1900. -/
def vehicleAt (classes : List RoadUserClass) (dir : Int) (y : Q) (halt resume k : Nat) : RoadUser :=
  let steps : Nat := min k halt + (k - resume)
  let moving : Bool := k < halt || resume ≤ k
  let x0 : Int := if dir > 0 then 20 else 1900
  let heading : Vec := if dir > 0 then Build.east else Build.west
  Build.user 1 classes (m (x0 + dir * 25 * Int.ofNat steps), y) heading
    (if moving then Units.metresPerSecond 5 else Q.zero) (cm 250, m 1, cm 90)

def mkTrace (classes : List RoadUserClass) (dir : Int) (y : Q) (halt resume : Nat)
    (structs : List Structure) (devs : List Device) (city : Bool) : Trace :=
  Build.trace 34 0 (Units.seconds 5) fun k t =>
    Build.scene t (some 1) [vehicleAt classes dir y halt resume k] structs devs
      (env := env) (assumptions := [("asm.within_incorporated_city", city)])

def never : Nat := 1000

/-- `forbid` (violated): Inside an incorporated city (asm.within_incorporated_city true), a vehicle stands (kin.speed 0) for 90 s after driving in, heading along a one-way roadway's direction, its body 0.3 m from the left road edge and 8 m from the right, in a lane governed by a no_parking regulatory sign with empty conditions. -/
def forbidTrace : Trace :=
  mkTrace [.motorVehicle] 1 leftY 14 never structuresWithLanes [noParkingSign] true

/-- `permit` (compliant): The same vehicle halts 20 s at the left edge and drives on. -/
def permitTrace : Trace :=
  mkTrace [.motorVehicle] 1 leftY 14 19 structuresWithLanes [noParkingSign] true

/-- `idle` (not_applicable): The vehicle stands 90 s at the right edge of the one-way roadway (0.3 m from the right edge, 8 m from the left). -/
def idleTrace : Trace :=
  mkTrace [.motorVehicle] 1 rightY 14 never structuresWithLanes [noParkingSign] true

/-- `blind` (unknown): As in forbid, but the source does not observe which regions the devices govern. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): As in forbid but asm.within_incorporated_city is false: a one-way highway outside any city. -/
def branch_1Trace : Trace :=
  mkTrace [.motorVehicle] 1 leftY 14 never structuresWithLanes [noParkingSign] false

/-- `branch_2` (violated): no sign; the vehicle stands at the left edge inside a no_parking curb zone. -/
def branch_2Trace : Trace :=
  mkTrace [.motorVehicle] 1 leftY 14 never structuresWithCurb [] true

/-- `branch_3` (violated): the vehicle stands facing west, against the roadway's direction, at the
    north edge, which is still the left-hand side of the eastbound one-way roadway. -/
def branch_3Trace : Trace :=
  mkTrace [.motorVehicle] (-1) leftY 14 never structuresWithLanes [noParkingSign] true

/-- `branch_4` (not_applicable): as in forbid, but the road user is a pedestrian, no vehicle. -/
def branch_4Trace : Trace :=
  mkTrace [.pedestrian] 1 leftY 14 never structuresWithLanes [noParkingSign] true

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_493"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (65000, 165000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_493
