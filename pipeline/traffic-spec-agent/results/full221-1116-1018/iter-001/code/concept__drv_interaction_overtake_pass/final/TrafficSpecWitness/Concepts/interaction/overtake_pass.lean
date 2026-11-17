/-
  Witnesses for drv.interaction.overtake_pass.

  Geometry (world frame, +x east, +y north; every figure is the witness's own). Both bodies are
  4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m). b (track 2) is halted at (0, 0) heading east,
  in its lane (centre line y = 0); the adjacent lane to its left has its centre at y = 3.5 m.
  a (track 1) is sampled once a second from t = 10 s; each trace is padded 6 s before with its
  first scene, so the 6 s window behind every judged instant is covered.

    t = 10 s  a (-19, 0)    east, 12 m/s   b ahead, gap 15 m, headings aligned
    t = 11 s  a (-11, 0)    east,  8 m/s   b ahead, gap 7 m, aligned: the onset (last such)
    t = 12 s  a (-8, 1)     heading (4/5, 3/5) (≈ 37° left), 6 m/s: moving to the adjacent lane;
                            b ahead (bearing 5.8 m ahead, projections 1.6 m apart) but headings
                            not aligned (cosine 4/5 below 9/10)
    holds / blind:
    t = 13 s  a (-1, 3.5)   east, 5 m/s    alongside: projections share 3 m, b's centre 1 m ahead
    t = 14 s  a (3, 3.5)    east, 4 m/s    alongside: projections share 1 m, b's centre 3 m behind
    t = 15 s  a (7, 3.5)    east, 4 m/s    b behind, 3 m between the bodies: recognized, 4 s after
                                           the onset
    fails:
    t = 13 s  a (-1, 3.5)   east, 4 m/s    alongside
    t = 14 s, 15 s  a (1, 3.5) halted      alongside: projections share 3 m; b never behind a

  Instance: window 6 s, same_dir_cos 9/10.
  `holds` is judged at t = 15 s only (the concept holds at the observation of recognition only);
  `fails` over the whole trace; `blind` at t = 15 s with `rel.bearing` unobserved.
-/
import TrafficSpec.Concepts.interaction.overtake_pass
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.overtake_pass

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1, b ↦ 2
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.overtake_pass@w"
    concept := "drv.interaction.overtake_pass"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 6) .second), ("same_dir_cos", .lit (Units.ratio 9 10) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Half-extents of both bodies: 2 m half-length, 1 m half-width, 1 m half-height. -/
def body : Q × Q × Q := (m 2, m 1, m 1)

/-- a's heading while moving to the adjacent lane: (4/5, 3/5), about 37° left of east. -/
def angled : Vec := (Units.ratio 4 5, Units.ratio 3 5)

/-- b, halted in its lane. -/
def userB : RoadUser := Build.user 2 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 0) body

/-- a in the holds (and blind) trace at sample k. -/
def passingA (k : Nat) : RoadUser :=
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m (-19), m 0) Build.east (Units.metresPerSecond 12) body
  | 1 => Build.user 1 [.motorVehicle] (m (-11), m 0) Build.east (Units.metresPerSecond 8) body
  | 2 => Build.user 1 [.motorVehicle] (m (-8), m 1) angled (Units.metresPerSecond 6) body
  | 3 => Build.user 1 [.motorVehicle] (m (-1), cm 350) Build.east (Units.metresPerSecond 5) body
  | 4 => Build.user 1 [.motorVehicle] (m 3, cm 350) Build.east (Units.metresPerSecond 4) body
  | _ => Build.user 1 [.motorVehicle] (m 7, cm 350) Build.east (Units.metresPerSecond 4) body

/-- a in the fails trace at sample k: it draws alongside b and halts there. -/
def stallingA (k : Nat) : RoadUser :=
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m (-19), m 0) Build.east (Units.metresPerSecond 12) body
  | 1 => Build.user 1 [.motorVehicle] (m (-11), m 0) Build.east (Units.metresPerSecond 8) body
  | 2 => Build.user 1 [.motorVehicle] (m (-8), m 1) angled (Units.metresPerSecond 6) body
  | 3 => Build.user 1 [.motorVehicle] (m (-1), cm 350) Build.east (Units.metresPerSecond 4) body
  | _ => Build.user 1 [.motorVehicle] (m 1, cm 350) Build.east (Units.metresPerSecond 0) body

/-- `holds` (compliant): a follows b in the same lane 15 m behind at 12 m/s while b is halted; a moves to the adjacent lane, draws alongside and, 4 s after b was last ahead of it, has b 3 m behind it: at that observation the concept holds. -/
def holdsTrace : Trace :=
  Build.pad
    (Build.trace 6 10000 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [passingA k, userB] [] [])
    (Units.seconds 6) (Units.seconds 0) (Units.seconds 1)

/-- `fails` (violated): a follows b, moves to the adjacent lane and draws alongside b, then halts with the two bodies still side by side; b never comes to be behind a within the window. -/
def failsTrace : Trace :=
  Build.pad
    (Build.trace 6 10000 (Units.seconds 1) fun k t =>
      Build.scene t (some 1) [stallingA k, userB] [] [])
    (Units.seconds 6) (Units.seconds 0) (Units.seconds 1)

/-- `blind` (unknown): a draws past b in the adjacent lane, but the bearing of b from a is not observed. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1), ("b", 2)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (15000, 15000))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.bearing"] (some (15000, 15000)) ]

end TrafficSpecWitness.Concepts.interaction.overtake_pass
