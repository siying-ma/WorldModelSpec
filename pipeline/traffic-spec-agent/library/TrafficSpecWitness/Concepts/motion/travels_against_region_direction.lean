/-
  Witnesses for drv.motion.travels_against_region_direction.

  The geometry is one straight one-way roadway, region 100: the rectangle from (0, -5) to
  (200, 5) metres, carrying a designated direction due east (+x). Every trace is three
  observations one second apart, from t = 0.

  The bodies are motor vehicles two metres half-length, one metre half-width, one metre
  half-height, driving along the roadway's centre line (y = 0):
    `holds`  — track 1 heads due west at six metres per second, from x = 100 m, so its velocity
               projects -6 m/s on the designated direction: cosine -1, below -0.8.
    `fails`  — track 1 heads due east at six metres per second from x = 100 m (cosine +1), and
               track 2 stands still at x = 40 m.
    `blind`  — the `holds` scene, with `st.lane_direction` absent from the manifest: the source
               declares no designated direction, so the projection is unknown while the speed
               still exceeds the floor.

  The instance's figures are this witness's own: the motion floor one metre per second (the six
  metres per second above it, the standing vehicle below it), the opposition tolerance 0.8 — an
  angle of about 37 degrees either side of exactly opposed.
-/
import TrafficSpec.Concepts.motion.travels_against_region_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.travels_against_region_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the one-way roadway, a structure of every trace below)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.travels_against_region_direction@w"
    concept := "drv.motion.travels_against_region_direction"
    literals := []
    nats := []
    params := [("motion_speed_floor", .lit (Units.metresPerSecond 1) .metrePerSecond),
               ("direction_opposition_cosine", .lit (Units.ratio 4 5) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The one-way roadway, region 100: its designated direction of travel is due east. -/
def roadway : Structure :=
  { Build.rect 100 .oneWayRoadway (m 0) (m (-5)) (m 200) (m 5) with
    lane := some { direction := some Build.east } }

/-- The vehicle's half-extents: two metres half-length, one metre half-width and half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The x of a body that starts at `x0` and travels `step` metres each observation. -/
def xAt (x0 step : Q) (k : Nat) : Q := Q.add x0 (Q.mul (Q.ofInt (Int.ofNat k)) step)

/-- `holds` (compliant): A one-way roadway carries a designated direction due east; a vehicle on it
    travels due west at six metres per second. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAt (m 100) (m (-6)) k, m 0) Build.west
          (Units.metresPerSecond 6) carExtent ]
      [ roadway ]
      [ ]

/-- `fails` (violated): On the same roadway the vehicle travels due east at six metres per second;
    and a second vehicle stands still on it. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAt (m 100) (m 6) k, m 0) Build.east
          (Units.metresPerSecond 6) carExtent
      , Build.user 2 [.motorVehicle] (m 40, m 0) Build.east Q.zero carExtent ]
      [ roadway ]
      [ ]

/-- `blind` (unknown): A vehicle travels along the roadway but the source declares no designated
    direction for its structures. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (xAt (m 100) (m (-6)) k, m 0) Build.west
          (Units.metresPerSecond 6) carExtent ]
      [ roadway ]
      [ ]

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

end TrafficSpecWitness.Concepts.motion.travels_against_region_direction
