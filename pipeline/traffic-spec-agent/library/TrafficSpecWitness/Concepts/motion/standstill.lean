/-
  Witnesses for drv.motion.standstill.

  The geometry. A straight one-lane roadway runs east along y = 0; a stop line sits at x = 0 as the
  "line" of the narratives (no formal of the concept reads it — it is scenery that places the
  bodies). The single road user is track 1, a motor vehicle of half-extents 2 m × 1 m × 1 m heading
  east, and it is the formal `u`. Each trace has three instants, at t = 0, 1000 and 2000 ms.

  The instance's own figure: the standstill tolerance is 0.2 m/s (written through
  `Units.micrometresPerSecond`), a sampling bound well under any creep a tracker would call motion.

  `holds`: the vehicle has come to rest with its front at the stop line and stays there — measured
  speed 0 m/s at all three instants, which is below 0.2 m/s, so the body holds throughout.
  `fails`: the vehicle creeps east across the same line at a measured 1.5 m/s at every instant
  (position advancing 1.5 m per second), never at or below the tolerance, so the body is false.
  `blind`: the same creep past the line, but the manifest declares `kin.speed` unobserved, so the
  one atom that decides the body reads nothing and the body is unknown.
-/
import TrafficSpec.Concepts.motion.standstill
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.standstill

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The standstill tolerance the witness chooses: 0.2 m/s. -/
def tolerance : Q := Units.micrometresPerSecond 200000

/-- The creep speed of `fails` and `blind`: 1.5 m/s. -/
def creep : Q := Units.micrometresPerSecond 1500000

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.standstill@w"
    concept := "drv.motion.standstill"
    literals := []
    nats := []
    params := [("standstill_speed_tolerance", .lit tolerance .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The roadway, its lane and the stop line at x = 0; the same scenery in every scenario. -/
def structures : List Structure :=
  [ Build.rect 10 .roadway (m (-60)) (m (-5)) (m 60) (m 5)
  , Build.lane 11 [(m (-60), m (-5)), (m 60, m (-5)), (m 60, m 5), (m (-60), m 5)] Build.east
  , Build.rect 12 .stopLine (m 0) (m (-5)) (cm 20) (m 5) ]

/-- `holds` (compliant): A vehicle rolls up to a line and its speed falls to zero; at the observation judged its measured speed is below the standstill tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-2), Q.zero) Build.east Q.zero (m 2, m 1, m 1)
          (some (m 30)) ]
      structures
      [ ]

/-- `fails` (violated): A vehicle creeps past the same line at one and a half metres per second without its speed ever falling to the tolerance. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle]
          (Q.add (m (-2)) (Q.mul creep (Q.ofInt (Int.ofNat k))), Q.zero)
          Build.east creep (m 2, m 1, m 1)
          (some (Q.add (m 30) (Q.mul creep (Q.ofInt (Int.ofNat k))))) ]
      structures
      [ ]

/-- `blind` (unknown): The vehicle is tracked past the line but the source declares no speed for road users. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle]
          (Q.add (m (-2)) (Q.mul creep (Q.ofInt (Int.ofNat k))), Q.zero)
          Build.east creep (m 2, m 1, m 1)
          (some (Q.add (m 30) (Q.mul creep (Q.ofInt (Int.ofNat k))))) ]
      structures
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.motion.standstill
