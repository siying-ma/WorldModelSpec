/-
  Witnesses for drv.motion.moving.

  Geometry: one eastbound lane (region 10), the rectangle x 0…200 m, y −2…2 m, direction east.
  Track 1 is a motor vehicle, half-extents 2.3 × 0.9 × 0.75 m, heading east on the lane's centre
  (y = 0). Three instants, 1 s apart (t = 0, 1000, 2000 ms).
  - holds: the car travels at 50 km/h (≈ 13.9 m/s), at x = 20, 34, 48 m.
  - fails: a stop line (region 11, x 60…60.3 m across the lane); the car stands just behind it,
    front at 59.8 m (centre x = 57.5 m), speed 0 at every instant.
  - blind: the holds scene with kin.speed masked by the source's manifest.
  The instance's speed floor is 0.1 m/s (100 000 µm/s), a source's speed resolution: far below
  50 km/h and above 0.
-/
import TrafficSpec.Concepts.motion.moving
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.moving

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: x ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the speed floor at 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.moving@w"
    concept := "drv.motion.moving"
    literals := []
    nats := []
    params := [("speed_floor", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The eastbound lane, x 0…200 m, y −2…2 m. -/
def lane : Structure :=
  Build.lane 10 [(m 0, m (-2)), (m 200, m (-2)), (m 200, m 2), (m 0, m 2)] Build.east

/-- A stop line across the lane at x 60…60.3 m. -/
def stopLine : Structure :=
  Build.rect 11 .stopLine (m 60) (m (-2)) (cm 6030) (m 2)

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

/-- `holds` (compliant): A car travels along a lane at ordinary urban speed, far above the floor. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (20 + 14 * (k : Int)), m 0) Build.east (Units.kmh 50) carExtent ]
      [ lane ]
      [ ]

/-- `fails` (violated): A car stands at a stop line with zero speed. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (cm 5750, m 0) Build.east Q.zero carExtent ]
      [ lane, stopLine ]
      [ ]

/-- `blind` (unknown): The source declares kin.speed absent. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["kin.speed"]) holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.moving
