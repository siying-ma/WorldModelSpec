/-
  Witnesses for NRS_484B_600_1e.

  The geometry is the same rural carriageway in every scene: a straight highway region 12 m wide
  running east along y = 0 (from x = -100 m to x = 2000 m) and, inside it, one eastbound lane 4 m
  wide south of the centre. Bodies are built at three instants one second apart, each at the
  position its speed carries it to; a passenger car is 4 m long, 1.8 m wide, 1.5 m high.

    forbid   — a car (motor vehicle) running east at 40 m/s, above 80 mph (35.7632 m/s) by 4.2 m/s.
    permit   — the same car at 31 m/s, below the bound by 4.7 m/s.
    idle     — the subject is a pedal bicycle, a device moved by human power that
               DEF-NRS-484A-320 leaves out of the vehicle aggregate, rolling east at 8 m/s; a rail
               vehicle runs at 42 m/s on rails 20 m south of the highway. No vehicle of the
               aggregate is in the scene, so the rule is not engaged.
    blind    — the car of `forbid`, with kin.speed declared absent: it is decidedly in motion and
               decidedly a vehicle, and whether its rate of speed exceeds the bound cannot be read.
    branch_1 — a car standing at the roadside with zero velocity: it is a vehicle, but it is not
               being driven or operated, so the duty does not bind it.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The carriageway: a highway region and the eastbound lane inside it. -/
def highway : Structure := Build.rect 10 .highway (m (-100)) (m (-6)) (m 2000) (m 6)

def eastboundLane : Structure :=
  Build.lane 11 [(m (-100), m (-4)), (m 2000, m (-4)), (m 2000, m 0), (m (-100), m 0)] Build.east

def road : List Structure := [highway, eastboundLane]

/-- Half-extents of a passenger car: 4 m long, 1.8 m wide, 1.5 m high. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- Half-extents of a bicycle. -/
def bicycleExtent : Q × Q × Q := (cm 90, cm 30, cm 90)

/-- Half-extents of a rail car. -/
def railExtent : Q × Q × Q := (m 12, cm 150, m 2)

/-- A car running east along the lane at `v` m/s, at the `k`-th second. -/
def runningCar (k : Nat) (v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (v * (k : Int)), m (-2)) Build.east (m v) carExtent

/-- `forbid` (violated): A passenger car on a rural highway travels at 40 m/s (about 89 miles per hour) for several seconds; no other road user is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runningCar k 40 ]
      road
      [ ]  -- devices

/-- `permit` (compliant): The same car never exceeds 31 m/s (about 69 miles per hour) at any observation of the trace. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runningCar k 31 ]
      road
      [ ]  -- devices

/-- `idle` (not_applicable): A device DEF-NRS-484A-320 excludes from the vehicle aggregate — a pedal
    bicycle, moved by human power — rolls east on the highway at 8 m/s while a rail vehicle runs at
    42 m/s on rails beside it; no vehicle is in the scene. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (8 * (k : Int)), m (-2)) Build.east (m 8) bicycleExtent
      , Build.user 2 [.railVehicle] (m (42 * (k : Int)), m (-20)) Build.east (m 42) railExtent ]
      road
      [ ]  -- devices

/-- `blind` (unknown): A car is in motion on the highway and the source declares kin.speed absent, so whether its rate of speed exceeds the bound cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ runningCar k 40 ]
      road
      [ ]  -- devices

/-- `branch_1` (not_applicable): a car of the aggregate stands at the roadside, its velocity zero —
    it is not being driven or operated, so the duty does not bind it. -/
def standingTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 120, m (-2)) Build.east Q.zero carExtent ]
      road
      [ ]  -- devices

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" standingTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_600_1e
