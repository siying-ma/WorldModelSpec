/-
  Witnesses for drv.motion.circulating_clockwise_about.

  Geometry (every figure here is the witness's own):
    - region r = 100, a roundabout central island: the square (-5,-5)–(5,5) m, reference point
      (0,0), every scene's structure carrying both.
    - road user a = track 1, a motor vehicle of half-extent 2 m × 1 m × 1 m, speed 10 m/s,
      on a circle of radius 15 m about the reference point, outside the island.
    - three scenes, one per second (t = 0, 1000, 2000 ms).
      holds/blind (clockwise): k0 (0,15) east; k1 (15,0) south; k2 (0,-15) west.
        d × v = −150 m²/s at each scene; (d × v)² = 22500 > (1/2)² · 225 · 100 = 5625.
      fails (counter-clockwise): k0 (0,15) west; k1 (-15,0) south; k2 (0,-15) east.
        d × v = +150 m²/s at each scene: not negative.
  Instance: speed_tol = 1 m/s, sin_tol = 1/2.
  blind masks kin.velocity and kin.speed: the cross product and the speed bound are unknown.
-/
import TrafficSpec.Concepts.motion.circulating_clockwise_about
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.circulating_clockwise_about

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (a roundabout central island, in every scene)

def inst : Concept.Instance :=
  { name := "drv.motion.circulating_clockwise_about@w"
    concept := "drv.motion.circulating_clockwise_about"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.metresPerSecond 1) .metrePerSecond),
               ("sin_tol", .lit (Units.ratio 1 2) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The central island r: boundary polygon and reference point. -/
def island : Structure :=
  { Build.rect 100 .roundabout (m (-5)) (m (-5)) (m 5) (m 5) with position := some (m 0, m 0) }

/-- Road user a at a position with a heading, 10 m/s. -/
def userA (pos : Vec) (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos h (Units.metresPerSecond 10) (m 2, m 1, m 1)

/-- Clockwise about (0,0): the point on a's right. -/
def clockwise (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m 0, m 15) Build.east
  | 1 => userA (m 15, m 0) Build.south
  | _ => userA (m 0, m (-15)) Build.west

/-- Counter-clockwise about (0,0): the point on a's left. -/
def counterClockwise (k : Nat) : RoadUser :=
  match k with
  | 0 => userA (m 0, m 15) Build.west
  | 1 => userA (m (-15), m 0) Build.south
  | _ => userA (m 0, m (-15)) Build.east

/-- `holds` (compliant): The region is mapped with its reference point and a boundary polygon around that point (a small central island, every scene's structure carrying both). A car moves around the region outside its boundary, keeping the reference point on its right, its velocity mostly across the line to the point and its speed well above speed_tol. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [clockwise k] [island] []

/-- `fails` (violated): The region is mapped as in holds, with its reference point and a boundary polygon. A car moves around the region outside its boundary keeping the reference point on its left (counter-clockwise). -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [counterClockwise k] [island] []

/-- `blind` (unknown): The region is mapped as in holds, with its reference point and a boundary polygon, and the car moves as in holds, but the source does not observe the car's motion: its velocity and its speed are declared absent, while its position and the region's geometry are observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [clockwise k] [island] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.velocity", "kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.circulating_clockwise_about
