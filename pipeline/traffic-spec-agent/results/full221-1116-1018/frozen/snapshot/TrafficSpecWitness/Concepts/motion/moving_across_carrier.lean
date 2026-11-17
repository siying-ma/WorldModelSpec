/-
  Witnesses for drv.motion.moving_across_carrier.

  Geometry (the witness's own figures): lane 100 is the rectangle x ∈ [0, 30] m, y ∈ [-2, 2] m,
  designated direction east. Pedestrian 1 (half-extent 0.3 × 0.3 × 0.9 m) stands on it at
  (10, 0) m at t = 0 and walks at 1.4 m/s for three observations 1 s apart:
    holds — heading north: velocity (0, 1.4), dot product with east 0 ≤ 0.5 · 1.4.
    fails — heading east: velocity (1.4, 0), |dot| = 1.4 > 0.5 · 1.4.
    blind — heading north as in holds, kin.velocity masked: the speed is above the tolerance, the
            dot product is unknown, so the conjunction is unknown.
  Instance: speed_tol = 0.1 m/s, cos_max = 1/2 (motion within 60° of the perpendicular).
-/
import TrafficSpec.Concepts.motion.moving_across_carrier
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.moving_across_carrier

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.moving_across_carrier@w"
    concept := "drv.motion.moving_across_carrier"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond),
               ("cos_max", .lit (Units.ratio 1 2) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The walking speed, 1.4 m/s. -/
def walk : Q := Units.micrometresPerSecond 1400000

/-- Lane 100: x ∈ [0, 30] m, y ∈ [-2, 2] m, designated direction east. -/
def lane100 : Structure :=
  Build.lane 100 [(m 0, m (-2)), (m 30, m (-2)), (m 30, m 2), (m 0, m 2)] Build.east

/-- The pedestrian at instant k, walking along `h` from (10, 0) m. -/
def ped (h : Vec) (k : Nat) : RoadUser :=
  let d := Build.scale h (Q.mul walk (Q.ofInt k))
  Build.user 1 [.pedestrian] (Q.add (m 10) d.1, Q.add (m 0) d.2) h walk (cm 30, cm 30, cm 90)

/-- `holds` (compliant): A pedestrian on a lane whose direction is east walks north at 1.4 m/s: the dot product is zero, at most cos_max times the speed. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped Build.north k ]
      [ lane100 ]
      [ ]

/-- `fails` (violated): A pedestrian on the same lane walks east along it at 1.4 m/s: the absolute cosine is 1, above cos_max. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped Build.east k ]
      [ lane100 ]
      [ ]

/-- `blind` (unknown): A pedestrian on the lane moves, but its velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped Build.north k ]
      [ lane100 ]
      [ ]

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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.moving_across_carrier
