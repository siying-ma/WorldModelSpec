/-
  Witnesses for NRS_484B_153_2.

  Geometry: the subject (track 1) is a car parked at (0, 0) heading east, half-extents
  2.25 m × 0.90 m × 0.75 m, speed 0; its traffic side is north (+y). The other road user (track 2)
  heads east at 1 m/s, its reference point at x = -1, 0, 1 m over the three instants (dt 1 s), so
  its body overlaps the subject's along the subject's heading at every instant unless stated.
  A car of the same half-extents at y = 2.30 m leaves a lateral body gap of 0.50 m (inside the
  reading's door reach of 1.0 m by 0.5 m); at y = 4.30 m a gap of 2.50 m (outside it by 1.5 m).
  The reading's halt tolerance is 0.1 m/s: the moving users go 1 m/s, the halted one 0.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_153_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_153_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 75)

/-- The parked subject with the doors open on the listed sides. -/
def subjectCar (doors : List DoorSide) : RoadUser :=
  Build.withSignals (Build.user 1 [.motorVehicle] (m 0, m 0) Build.east Q.zero carExtent)
    fun s => { s with doorsOpen := some doors }

/-- A car of the traffic at (x, y), heading east at `v`. -/
def otherCar (x y : Q) (v : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, y) Build.east v carExtent

def xAt (k : Nat) : Q := m ((Int.ofNat k) - 1)

/-- `forbid` (violated): A car parked at the curb opens its traffic-side door; a moving car passes alongside it with a lateral body gap of 0.5 m. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic], otherCar (xAt k) (cm 230) (Units.metresPerSecond 1) ]
      [ ]
      [ ]

/-- `permit` (compliant): A car parked at the curb opens its traffic-side door; a moving car passes alongside with a lateral body gap of 2.5 m. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic], otherCar (xAt k) (cm 430) (Units.metresPerSecond 1) ]
      [ ]
      [ ]

/-- `idle` (not_applicable): A car parked at the curb with all doors closed while traffic passes close by. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar [], otherCar (xAt k) (cm 230) (Units.metresPerSecond 1) ]
      [ ]
      [ ]

/-- `blind` (unknown): A car parked at the curb with traffic passing close by; the source declares sig.door_open absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic], otherCar (xAt k) (cm 230) (Units.metresPerSecond 1) ]
      [ ]
      [ ]

/-- `branch_1` (compliant): A car parked at the curb opens its traffic-side door with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic] ]
      [ ]
      [ ]

/-- `branch_2` (compliant): traffic-side door open; a car at rest stands alongside 0.5 m away (not moving). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic], otherCar (m 0) (cm 230) Q.zero ]
      [ ]
      [ ]

/-- `branch_3` (compliant): traffic-side door open; a moving bicycle (traffic, not a vehicle) passes 0.5 m away. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic],
        Build.user 2 [.bicycle] (xAt k, cm 170) Build.east (Units.metresPerSecond 1) bikeExtent ]
      [ ]
      [ ]

/-- `branch_4` (compliant): traffic-side door open; a moving car 0.5 m to the side is wholly ahead
    (its rear 2 m beyond the subject's front): no shared length along the subject's heading. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic], otherCar (Q.add (cm 650) (m (Int.ofNat k))) (cm 230) (Units.metresPerSecond 1) ]
      [ ]
      [ ]

/-- `branch_5` (violated): traffic-side door open; a moving car touches the subject's rear bumper
    end to end (contact; the projections share no length). -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectCar [.traffic], otherCar (cm (-450)) (m 0) (Units.metresPerSecond 1) ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_153_2"
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
  , witness "blind" blindTrace (.unknown []) ["sig.door_open"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_153_2
