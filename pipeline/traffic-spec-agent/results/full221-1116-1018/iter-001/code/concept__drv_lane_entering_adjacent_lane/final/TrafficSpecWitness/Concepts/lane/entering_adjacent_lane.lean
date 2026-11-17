/-
  Witnesses for drv.lane.entering_adjacent_lane.

  Geometry (the witness's own figures): two northbound lanes, 4 m wide, from y = -50 to y = 150.
  Lane 101 (x from -4 to 0) is the left one, ordinal 1 of 2; lane 100 (x from 0 to 4) the right
  one, ordinal 2 of 2; 101 is 100's left neighbour, 100 is 101's right neighbour. Road user 1 is a
  motor vehicle heading north at 10 m/s, half-length 2 m, half-width 1 m; occupancy is derived from
  its footprint. Three scenes at t = 0, 1000, 2000 ms; every scenario is judged at t = 1000.
    holds/blind: x = 2 (footprint x 1..3, lane 100 only), then x = 0.5 (x -0.5..1.5, both lanes),
      then x = -2 (x -3..-1, lane 101 only).
    fails: x = 2 at every scene (lane 100 only).
  Instance: s = left.
-/
import TrafficSpec.Concepts.lane.entering_adjacent_lane
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.entering_adjacent_lane

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r1 ↦ 100, r2 ↦ 101

/-- The instance every scenario speaks about: s is left. -/
def inst : Concept.Instance :=
  { name := "drv.lane.entering_adjacent_lane@w"
    concept := "drv.lane.entering_adjacent_lane"
    literals := [("s", "left")]
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane 100 (r1): the right of two northbound lanes; its left neighbour is 101. -/
def laneR1 : Structure :=
  Build.lane 100 [(m 0, m (-50)), (m 4, m (-50)), (m 4, m 150), (m 0, m 150)] Build.north
    (some 101) none (some 2) (some 2)

/-- Lane 101 (r2): the left of two northbound lanes; its right neighbour is 100. -/
def laneR2 : Structure :=
  Build.lane 101 [(m (-4), m (-50)), (m 0, m (-50)), (m 0, m 150), (m (-4), m 150)] Build.north
    none (some 100) (some 1) (some 2)

def lanes : List Structure := [laneR1, laneR2]

/-- Road user 1 at lateral position x, k seconds in. -/
def car (x : Q) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, m (10 * Int.ofNat k)) Build.north (Units.metresPerSecond 10)
    (m 2, m 1, m 1)

/-- Lateral position of road user 1 when it moves from r1 into r2. -/
def enteringX (k : Nat) : Q :=
  match k with
  | 0 => m 2
  | 1 => cm 50
  | _ => m (-2)

/-- `holds` (compliant): r2 is r1's left neighbour; a overlapped r1 only at the previous observation and overlaps r1 and r2 now; s is left. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car (enteringX k) k] lanes []

/-- `fails` (violated): a overlaps r1 only at both observations. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car (m 2) k] lanes []

/-- `blind` (unknown): a overlaps r1 and r2 now, but its overlap with r2 at the previous observation is unobserved. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car (enteringX k) k] lanes []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r1", 100), ("r2", 101)]
    expected := expected
    window := some (1000, 1000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.lane.entering_adjacent_lane
