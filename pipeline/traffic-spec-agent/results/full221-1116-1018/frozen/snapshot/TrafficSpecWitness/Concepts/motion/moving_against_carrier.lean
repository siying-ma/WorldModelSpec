/-
  Witnesses for drv.motion.moving_against_carrier.

  Geometry: lane 100 is the rectangle x ∈ [0, 100] m, y ∈ [−2, 2] m, its designated direction east
  (1, 0). Road user 1 (a motor vehicle, half-extents 2.5 × 1 × 0.75 m) stands at (50, 0) inside it.
  Three scenes at 0, 1, 2 s; the body is a state at one observation, so no padding is needed.
  - holds: a's velocity is (−5, 0) m/s (heading west, 5 m/s): component −5 m/s < −0.1 m/s.
  - fails: a's velocity is (5, 0.2) m/s (heading east): component +5 m/s, not below −0.1 m/s.
  - blind: a's velocity is unobserved (masked in the manifest and absent from the scene).
  The instance gives speed_tol = 0.1 m/s (100 000 µm/s), a figure of the witness's own.
-/
import TrafficSpec.Concepts.motion.moving_against_carrier
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.moving_against_carrier

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100 (the lane, a structure of every trace)

/-- The instance every scenario speaks about: speed_tol = 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.moving_against_carrier@w"
    concept := "drv.motion.moving_against_carrier"
    literals := []
    nats := []
    params := [("speed_tol", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane 100, designated direction east. -/
def lane100 : Structure :=
  Build.lane 100 [(m 0, m (-2)), (m 100, m (-2)), (m 100, m 2), (m 0, m 2)] Build.east

def halfExt : Q × Q × Q := (cm 250, cm 100, cm 75)

/-- `holds` (compliant): r's st.lane_direction is (1,0); a's kin.velocity is (-5,0) m/s; the component -5 m/s is below minus speed_tol. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 50, m 0) Build.west (Units.metresPerSecond 5) halfExt ]
      [ lane100 ]
      [ ]

/-- `fails` (violated): r's st.lane_direction is (1,0); a's kin.velocity is (5,0.2) m/s; the component is positive. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m 50, m 0) Build.east (Units.metresPerSecond 5) halfExt)
          fun k => { k with velocity := some (Units.metresPerSecond 5, cm 20) } ]
      [ lane100 ]
      [ ]

/-- `blind` (unknown): a's kin.velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin
          (Build.user 1 [.motorVehicle] (m 50, m 0) Build.west (Units.metresPerSecond 5) halfExt)
          fun k => { k with velocity := none } ]
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

end TrafficSpecWitness.Concepts.motion.moving_against_carrier
