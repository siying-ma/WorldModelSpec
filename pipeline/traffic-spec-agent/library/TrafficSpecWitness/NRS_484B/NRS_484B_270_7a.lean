/-
  Witnesses for NRS_484B_270_7a.

  Geometry (every figure here is the witness's own and appears nowhere in the rule): an
  east-running carriageway along y = 0, a bicycle lane on its north edge (y from 2 m to 4 m).
  Three instants, 1 s apart; the scene is held at each instant, so each instant judges the same
  configuration.
  - The car (track 2, motor vehicle) runs east at 15 m/s, half-extent 2.3 m × 0.9 m.
  - The rider (track 1) has half-extent 0.9 m × 0.3 m.
  forbid: the bicycle is 8 m ahead of the car, 50 cm to its left, riding east at 3 m/s and slowing;
    the car brakes at 6 m/s² (beyond 4.0). Closing at 12 m/s, the centres reach their closest
    approach after about 0.67 s (inside 3 s) at 0.5 m (below 3 m).
  permit: the bicycle rides in the bicycle lane at y = 3 m, 4 m/s; the car has already passed and
    is 10 m ahead of it, not braking (0 m/s²), drawing away: the rider is behind the car, the
    centres do not approach, the car does not brake.
  idle: the subject is a moped (a motor vehicle carrying no class any of the three aggregates
    includes or leaves unresolved), so its class is decidedly false.
  blind: as forbid, with an electric bicycle as the rider; the car's longitudinal acceleration is
    masked, and it alone decides.
  branch_1: a bicycle rides alone on a bicycle path; no other road user is in the scene.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_7a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_7a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)
def riderExtent : Q × Q × Q := (cm 90, cm 30, cm 90)

def bikeLane : Structure := Build.rect 10 .bicycleLaneOrPath (m (-100)) (m 2) (m 100) (m 4)

/-- A car at `x` on the carriageway, running east at 15 m/s, with the given longitudinal acceleration. -/
def car (track : TrackId) (x : Q) (accel : Q) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] (x, m 0) Build.east (Units.metresPerSecond 15) carExtent)
    fun k => { k with accelLongitudinal := some accel }

/-- A rider of the given classes at `pos`, riding east at `speed`, with the given acceleration. -/
def rider (classes : List RoadUserClass) (pos : Vec) (speed : Q) (accel : Q) : RoadUser :=
  Build.withKin (Build.user 1 classes pos Build.east speed riderExtent)
    fun k => { k with accelLongitudinal := some accel }

/-- `forbid` (violated): A bicycle cuts in front of a moving car and slows; the car, with the bicycle ahead of it, brakes harder than p.vehicle_evasive_decel while their closest approach falls within p.conflict_horizon and below p.conflict_centre_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ rider [.bicycle] (m 8, cm 50) (Units.metresPerSecond 3) (Units.metresPerSecondSq (-1))
      , car 2 (m 0) (Units.metresPerSecondSq (-6)) ]
      [ bikeLane ]
      [ ]

/-- `permit` (compliant): A bicycle rides in a bicycle lane; a car passes it without braking and without a conflicting closest approach. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ rider [.bicycle] (m 0, m 3) (Units.metresPerSecond 4) (Units.metresPerSecondSq 0)
      , car 2 (m 10) (Units.metresPerSecondSq 0) ]
      [ bikeLane ]
      [ ]

/-- `idle` (not_applicable): The subject is a car (not a member of the bicycle, electric bicycle or electric scooter aggregates). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin (Build.user 1 [.moped] (m 8, cm 50) Build.east (Units.metresPerSecond 3) carExtent)
          (fun k => { k with accelLongitudinal := some (Units.metresPerSecondSq (-1)) })
      , car 2 (m 0) (Units.metresPerSecondSq (-6)) ]
      [ bikeLane ]
      [ ]

/-- `blind` (unknown): An electric scooter swerves in front of a moving car with a conflicting closest approach; the car's longitudinal acceleration is not observed on this source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ rider [.electricBicycle] (m 8, cm 50) (Units.metresPerSecond 3) (Units.metresPerSecondSq (-1))
      , car 2 (m 0) (Units.metresPerSecondSq (-6)) ]
      [ bikeLane ]
      [ ]

/-- `branch_1` (compliant): A bicycle rides on a path with no motor vehicle in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ rider [.bicycle] (m 0, m 3) (Units.metresPerSecond 4) (Units.metresPerSecondSq 0) ]
      [ bikeLane ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_7a"
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
  , witness "blind" blindTrace (.unknown []) ["kin.accel_longitudinal"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.NRS_484B_270_7a
