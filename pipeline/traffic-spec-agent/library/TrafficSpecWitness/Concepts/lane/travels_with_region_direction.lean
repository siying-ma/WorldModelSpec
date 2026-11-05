/-
  Witnesses for drv.lane.travels_with_region_direction.

  One body, track 1, a car 5 m long and 2 m wide, and one region, 100, a straight roadway rectangle
  180 m long and 12 m wide (x from −60 m to 120 m, y from −6 m to 6 m) whose designated direction
  points east. The car runs along the middle of it, on the line y = 0, so its 5 m × 2 m footprint
  lies inside the roadway; occupancy is derived from the geometry, though the concept does not read
  it. No device is built and no other region: the concept reads the body's velocity and the
  region's designated direction alone.

  Each trace is three instants a second apart (t = 0, 1000, 2000 ms) and every scenario speaks about
  all of them: the body reads the instant it judges only, with no window behind, so no instant of
  any trace is truncated and no `window` is set.

  The instance's own figure: a tolerance of 0.5 m/s, the magnitude below which a velocity component
  counts as no travel, so that a body at rest or drifting across the designated direction is not
  read as travelling against it. It is written through `Units.micrometresPerSecond` (500 000 µm/s),
  the constructor of a fractional speed.

    holds — the designated direction is east; the car travels at 15 m/s due east, so its velocity
            is (15, 0) m/s and the component along the direction is +15 m/s, far above −0.5 m/s, at
            each of the three instants.
    fails — the same roadway, designated east; the car travels at 7 m/s due west, so its velocity
            is (−7, 0) m/s and the component along the direction is −7 m/s, below −0.5 m/s, at each
            instant.
    blind — the westward car again, on the same roadway rectangle, for which the source records no
            designated direction: the carrier's `lane.direction` is `none` and the manifest declares
            st.lane_direction absent, so both components of the direction are unknown and the
            component of the velocity along it is unknown with them.
-/
import TrafficSpec.Concepts.lane.travels_with_region_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.travels_with_region_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100 (the roadway of every trace)

/-- The instance every scenario speaks about: the tolerance below which a velocity component counts
    as no travel, 0.5 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.lane.travels_with_region_direction@w"
    concept := "drv.lane.travels_with_region_direction"
    literals := []
    nats := []
    params := [("motion_speed_tolerance", .lit (Units.micrometresPerSecond 500000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roadway, 180 m by 12 m, carrying the designated direction given (`none` where the source
    records none). -/
def roadway (direction : Option Vec) : Structure :=
  { Build.rect 100 .roadway (m (-60)) (m (-6)) (m 120) (m 6) with
    lane := some { direction := direction } }

/-- The car at an instant: 5 m long, 2 m wide, on the line y = 0 at the given x, travelling with
    the heading and speed given (its velocity is that heading times that speed). -/
def car (x : Q) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) heading speed (cm 250, cm 100, cm 100)

/-- Three instants a second apart: the car at `x k`, travelling as given, on the roadway whose
    designated direction is `direction`. -/
def runTrace (direction : Option Vec) (x : Nat → Q) (heading : Vec) (speed : Q) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (x k) heading speed ]
      [ roadway direction ]
      [ ]  -- devices

/-- Eastward travel at 15 m/s: x = 0, 15, 30 m. -/
def eastX (k : Nat) : Q := m (15 * (k : Int))

/-- Westward travel at 7 m/s: x = 30, 23, 16 m. -/
def westX (k : Nat) : Q := m (30 - 7 * (k : Int))

/-- `holds` (compliant): A car on a roadway whose designated direction points east travels at 15 m/s due east: the component of its velocity along the designated direction is strongly positive. -/
def holdsTrace : Trace :=
  runTrace (some Build.east) eastX Build.east (Units.metresPerSecond 15)

/-- `fails` (violated): The same roadway, designated east; the car travels at 7 m/s due west, so the component along the designated direction is about -7 m/s, below the negative of the tolerance. -/
def failsTrace : Trace :=
  runTrace (some Build.east) westX Build.west (Units.metresPerSecond 7)

/-- `blind` (unknown): The car travels westward on a mapped roadway region for which the source records no designated direction: st.lane_direction is absent, so the sense of its travel along that region is unknown. -/
def blindTrace : Trace :=
  runTrace none westX Build.west (Units.metresPerSecond 7)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.lane.travels_with_region_direction
