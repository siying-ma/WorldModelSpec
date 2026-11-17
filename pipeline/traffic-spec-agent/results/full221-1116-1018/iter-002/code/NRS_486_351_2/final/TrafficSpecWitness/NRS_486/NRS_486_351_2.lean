/-
  Witnesses for NRS_486_351_2.

  The carriageway: one lane, region 10, the rectangle x ∈ [0, 300], y ∈ [0, 5] m, direction east.
  Every road user moves east at 10 m/s (except the head-on rider of branch_5, westbound), three
  instants one second apart; positions advance 10 m per instant so that all bodies keep the same
  relative geometry. A motorcycle or moped is 2 m long, 0.8 m wide (half-extents 1, 0.4, 0.7); a
  car is 4 m long, 2 m wide (2, 1, 0.8); a bicycle 1.8 m long (0.9, 0.3, 0.6).

  forbid:   motorcycle (1) eastbound at y 3.8, car (2) westbound in the same lane at y 1.5; at
            instant 1 the centres are 1 m apart along x and the projections on the heading share
            2 m (motorcycle [59, 61], car [59, 63]); at instants 0 and 2 they are apart. The car
            is oncoming because a car's class (motor_vehicle) is unresolved under the motorcycle
            and moped aggregates of the run's reading, so only s5 can decide its pair unexcused.
  blind:    as forbid, rel.longitudinal_overlap masked. NOT REALISABLE as planned: masking blanks
            only a measured overlap; Core recomputes it from the two footprints, and the admission
            requires a footprint (position, heading, extent) of every track whose occupancy is
            observed, which rel.occupies needs here. Overlap is therefore always known wherever
            both occupancies are, and this witness evaluates violated (reported in task_result.md).
  permit:   motorcycle 16 m behind the car, gap between projections 13 m (overlap -13 m).
  idle:     the subject is a bicycle (the passenger car of the narrative is of the motor_vehicle
            class, which the motorcycle and trimobile aggregates leave unresolved, so its class
            would be unknown, not false): beside a car in the lane.
  branch_1: two motorcycles side by side, headings aligned, no third.
  branch_2: three motorcycles side by side, headings aligned.
  branch_3: the motorcycle alone in the lane.
  branch_4: two mopeds side by side, headings aligned (the moped limb of s4): compliant.
  branch_5: two motorcycles abreast in the lane head-on (no consent shown): violated.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_486.NRS_486_351_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_486_351_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure :=
  Build.lane 10 [(m 0, m 0), (m 300, m 0), (m 300, m 5), (m 0, m 5)] Build.east

def twoWheelExt : Q × Q × Q := (m 1, cm 40, cm 70)
def carExt : Q × Q × Q := (m 2, m 1, cm 80)
def bikeExt : Q × Q × Q := (cm 90, cm 30, cm 60)

def speed : Q := Units.metresPerSecond 10

/-- x position of a body starting at `x0`, at instant `k` (10 m per instant). -/
def xAt (x0 : Int) (k : Nat) : Q := m (x0 + 10 * (k : Int))

def mc (track : TrackId) (x0 : Int) (y : Q) (k : Nat) : RoadUser :=
  Build.user track [.motorcycle] (xAt x0 k, y) Build.east speed twoWheelExt

def car (track : TrackId) (x0 : Int) (y : Q) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (xAt x0 k, y) Build.east speed carExt

/-- The car of forbid/blind: westbound in L, 10 m per instant, abreast of the eastbound motorcycle
    at instant 1 only (motorcycle centre x 60, car centre x 61). -/
def oncomingCar (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (71 - 10 * (k : Int)), cm 150) Build.west speed carExt

/-- `forbid` (violated): A motorcycle occupies lane L beside a car also in L, rel.longitudinal_overlap 2 m
    (at instant 1). The car travels the other way in L: a car is of the motor_vehicle class, which
    the run's reading leaves unresolved under the motorcycle and moped definitions, so the s4 limb
    on a car stays unknown and only s5 (no consent shown) or s6 can decide the exception false. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mc 1 50 (cm 380) k, oncomingCar k ]
      [ laneL ]
      [ ]

/-- `permit` (compliant): The motorcycle occupies L 15 m behind the car in L, overlap negative. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mc 1 34 (cm 250) k, car 2 50 (cm 250) k ]
      [ laneL ]
      [ ]

/-- `idle` (not_applicable): The subject is a bicycle (none of the three aggregates) beside a car in L. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (xAt 50 k, cm 400) Build.east speed bikeExt, car 2 51 (cm 150) k ]
      [ laneL ]
      [ ]

/-- `blind` (unknown): The motorcycle and the car both occupy L; rel.longitudinal_overlap is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mc 1 50 (cm 380) k, oncomingCar k ]
      [ laneL ]
      [ ]

/-- `branch_1` (compliant): Two motorcycles ride side by side in L with headings aligned; no third vehicle beside them. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mc 1 50 (cm 120) k, mc 2 50 (cm 360) k ]
      [ laneL ]
      [ ]

/-- `branch_2` (violated): Three motorcycles ride side by side in L with headings aligned. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mc 1 50 (cm 80) k, mc 2 50 (cm 250) k, mc 3 50 (cm 420) k ]
      [ laneL ]
      [ ]

/-- `branch_3` (compliant): The motorcycle rides alone in L; no other vehicle in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ mc 1 50 (cm 250) k ]
      [ laneL ]
      [ ]

/-- `branch_4` (compliant): Two mopeds ride side by side in L with headings aligned (the moped limb of s4). -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.moped] (xAt 50 k, cm 120) Build.east speed twoWheelExt
      , Build.user 2 [.moped] (xAt 50 k, cm 360) Build.east speed twoWheelExt ]
      [ laneL ]
      [ ]

/-- `branch_5` (violated): Two motorcycles abreast in L, one westbound: no consent shown (s5). -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorcycle] (m 100, cm 120) Build.east (m 0) twoWheelExt
      , Build.user 2 [.motorcycle] (m 100, cm 360) Build.west (m 0) twoWheelExt ]
      [ laneL ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_486_351_2"
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
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_486_351_2
