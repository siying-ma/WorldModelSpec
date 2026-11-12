/-
  Witnesses for NRS_484B_113_3.

  Geometry: a parking-lot aisle along the x axis, ego (track 1, motor vehicle, half-extent
  2.4 × 0.9 × 0.75 m) leaving a space at the origin, its body pointing north. Three instants
  0.5 s apart (t = 0, 500, 1000 ms); positions advance with the velocities.
  - Backing: heading north, velocity 2 m/s south (component along heading −2 m/s, far below
    −p.rest_speed_tolerance); forward driving in `idle`: velocity 2 m/s north.
  - forbid: motor vehicle 2 at (−10, −4) driving east at 5 m/s. Relative position (−10, −4) is
    −2 × the relative velocity (5, 2): a head-on projected meeting of the centres at 2 s, 1.5 s,
    1 s (within the 3 s horizon) at centre distance 0 (below the 3 m clearance).
  - branch_1: pedestrian 3 standing (speed 0) at (0, −4) on ego's path: meeting at 2 s, 1.5 s, 1 s,
    centre distance 0.
  - branch_2: parked motor vehicle 4 at rest (speed 0) at (−2, −4), body beside ego's path:
    closest approach at centre distance 2 m within the horizon, but it is neither moving traffic
    nor a pedestrian.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_113_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_113_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 25, cm 25, cm 90)

/-- Ego at instant k, body pointing north. Backing: moving 2 m/s south (1 m per 0.5 s step). -/
def egoBacking (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m 0, m (-(k : Int))) Build.north (Units.metresPerSecond 2)
      carExtent)
    (fun kn => { kn with velocity := some (Build.scale Build.south (Units.metresPerSecond 2)) })

/-- Ego at instant k driving forward, north at 2 m/s. -/
def egoForward (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, m (k : Int)) Build.north (Units.metresPerSecond 2) carExtent

-- Binders ↦ tracks: ego ↦ 1

/-- `forbid` (violated): Ego backs out of a parking space while a motor vehicle t drives along the aisle behind it; projected at constant velocities their centres approach within p.conflict_horizon to a distance below p.conflict_clearance while ego keeps backing. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ egoBacking k
      , Build.user 2 [.motorVehicle] (cm (-1000 + 250 * (k : Int)), m (-4)) Build.east
          (Units.metresPerSecond 5) carExtent ]
      [ ]
      [ ]

/-- `permit` (compliant): Ego backs out of a parking space with no other road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ egoBacking k ]
      [ ]
      [ ]

/-- `idle` (not_applicable): Ego drives forward along the aisle; it is not backing. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ egoForward k ]
      [ ]
      [ ]

/-- `blind` (unknown): Scene of forbid, but the source declares kin.velocity absent: whether ego is backing cannot be read. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.velocity"]) forbidTrace

/-- `branch_1` (violated): Ego backs toward a pedestrian standing still on its path; projected at ego's velocity the closest approach falls within the horizon below the clearance. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ egoBacking k
      , Build.user 3 [.pedestrian] (m 0, m (-4)) Build.north Q.zero pedExtent ]
      [ ]
      [ ]

/-- `branch_2` (compliant): Ego backs past a parked vehicle at rest whose body lies close to ego's path; no moving traffic and no pedestrian is present. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ egoBacking k
      , Build.user 4 [.motorVehicle] (m (-2), m (-4)) Build.north Q.zero carExtent ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_113_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_113_3
