/-
  Witnesses for NRS_484B_533.

  Geometry (the witness's own figures, nowhere in the rule): a highway (region 10) is the rectangle
  x ∈ [-50, 50] m, y ∈ [-8, 8] m, its grade 5 % (idle: 0.1 %). Its right road edge (region 11) is the
  strip y ∈ [-8, -7.9] m, its left road edge (region 12) the strip y ∈ [7.9, 8] m; both lie on the
  highway. A car (track 1, half-extents 2.3 × 0.9 × 0.75 m) stands at (0, -5) heading east at speed
  0, so the right edge is nearest (lateral offset -2.9 m against +12.9 m for the left one); in
  branch_3 it stands at (0, 5), the left edge nearest (+2.9 m). Wheels turned right read -15°, left
  +15°, straight 0°. Three observations, 1 s apart.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_533
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_533

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def slope : Q := Units.percent 5
def level : Q := Units.ratio 1 1000

def structures (grade : Q) : List Structure :=
  [ { Build.rect 10 .highway (m (-50)) (m (-8)) (m 50) (m 8) with grade := some grade }
  , { Build.rect 11 .roadEdge (m (-50)) (m (-8)) (m 50) (cm (-790)) with ways := some [10] }
  , { Build.rect 12 .roadEdge (m (-50)) (cm 790) (m 50) (m 8) with ways := some [10] } ]

def car (y : Q) (occupants : Nat) (engine brake : Bool) (steer : Q) : RoadUser :=
  let u := Build.user 1 [.motorVehicle] (m 0, y) Build.east Q.zero (cm 230, cm 90, cm 75)
  let u := Build.withKin u fun k =>
    { k with engineRunning := some engine, parkingBrake := some brake, steerAngle := some steer }
  { u with occupants := some occupants }

def standingTrace (y : Q) (grade : Q) (occupants : Nat) (engine brake : Bool) (steer : Q) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car y occupants engine brake steer ]
      (structures grade)
      [ ]

/-- `forbid` (violated): A car stands with no one in it on a clearly sloped street, its engine running, parking brake set, wheels turned toward the nearest curb. -/
def forbidTrace : Trace := standingTrace (m (-5)) slope 0 true true (Units.degrees (-15))

/-- `permit` (compliant): A car stands with no one in it on the same slope, engine off, parking brake set, front wheels turned toward the right-hand curb, which is the nearest road edge. -/
def permitTrace : Trace := standingTrace (m (-5)) slope 0 false true (Units.degrees (-15))

/-- `idle` (not_applicable): A car stands with no one in it on a level street, its grade within the resolution. -/
def idleTrace : Trace := standingTrace (m (-5)) level 0 true false (Units.degrees 0)

/-- `blind` (unknown): As in permit, but the source does not observe the parking brake. -/
def blindTrace : Trace := Build.masked (Build.manifest ["kin.parking_brake"]) permitTrace

/-- `branch_1` (violated): A car stands unattended on the slope, engine off, parking brake set, front wheels straight. -/
def branch_1Trace : Trace := standingTrace (m (-5)) slope 0 false true (Units.degrees 0)

/-- `branch_2` (not_applicable): A car stands on the slope with its driver inside. -/
def branch_2Trace : Trace := standingTrace (m (-5)) slope 1 true false (Units.degrees 0)

/-- `branch_3` (compliant): A car stands unattended on the slope near the left-hand curb, engine
    off, parking brake set, front wheels turned left toward that curb. -/
def branch_3Trace : Trace := standingTrace (m 5) slope 0 false true (Units.degrees 15)

/-- `branch_4` (compliant): A car stands unattended on the slope at (0, 5); the nearest road edge
    (region 13, y ∈ [8, 8.1] m, offset +3.0 m) is the curb of a parallel way (region 20,
    y ∈ [8, 30] m) and not of its own highway, whose only mapped edge is the right one (offset
    -12.9 m); engine off, parking brake set, wheels turned right toward its own highway's edge. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 5) 0 false true (Units.degrees (-15)) ]
      [ { Build.rect 10 .highway (m (-50)) (m (-8)) (m 50) (m 8) with grade := some slope }
      , { Build.rect 11 .roadEdge (m (-50)) (m (-8)) (m 50) (cm (-790)) with ways := some [10] }
      , { Build.rect 20 .highway (m (-50)) (m 8) (m 50) (m 30) with grade := some slope }
      , { Build.rect 13 .roadEdge (m (-50)) (m 8) (m 50) (cm 810) with ways := some [20] } ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_533"
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
  , witness "blind" blindTrace (.unknown []) ["kin.parking_brake"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_533
