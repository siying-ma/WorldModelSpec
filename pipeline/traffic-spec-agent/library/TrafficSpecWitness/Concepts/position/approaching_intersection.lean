/-
  Witnesses for drv.position.approaching_intersection.

  The map, the same in every scene of every trace (metres, +x east, +y north): a straight eastbound
  street of two blocks, 8 m wide, with a junction at each end of the second block.

    lane A (200)        junction J (100)      lane B (201)        junction K (101)
    x ∈ [0, 20]         x ∈ [20, 30]          x ∈ [30, 50]        x ∈ [50, 60]
    enters J                                  enters K
    ───────────────────┼─────────────────────┼───────────────────┼──────────────────
                            y ∈ [0, 8] throughout

  Both lanes run east and the source records each one's entrance end: lane A enters J, lane B
  enters the next junction K. J is the formal `i`; K is there so that the witnesses tell the given
  junction from another one the road user is also on an approach to.

  The body: track 1, a car 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), heading east and at
  rest — the concept is entry topology, so a halted car is as good a subject as a rolling one, and
  no scene supplies a speed the verdict could lean on. Each trace is three scenes a second apart
  with the car at one place: nothing in the body looks back or ahead.

    holds: the car at (10 m, 4 m) — footprint x ∈ [8, 12], inside lane A alone. It occupies a
           travel region entering J and does not overlap J.
    fails: the car at (29 m, 4 m) — footprint x ∈ [27, 31], overlapping J and the first metre of
           lane B. It has reached J, so it is no longer approaching it; that it still overlaps a
           carrier entering a junction (lane B, entering K) is what the identification of the
           quantified junction with the formal `i` turns away.
    blind: the holds scene with st.lane_enters absent: which junction lane A runs into cannot be
           read, so whether the car is on an approach to J is unknown, not false.

  The instance has no literal formals and no parameters, so it carries no figure of its own.
-/
import TrafficSpec.Concepts.position.approaching_intersection
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.position.approaching_intersection

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: i ↦ 100 (junction J, a structure of every scene of every trace)

/-- The instance every scenario speaks about: no literal formal, no parameter, no bounds. -/
def inst : Concept.Instance :=
  { name := "drv.position.approaching_intersection@w"
    concept := "drv.position.approaching_intersection"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- Lane A, the approach: eastbound, its entrance end at junction J. -/
def laneA : Structure :=
  Build.lane 200 [(m 0, m 0), (m 20, m 0), (m 20, m 8), (m 0, m 8)] Build.east (enters := some 100)

/-- Junction J — the formal `i`. -/
def junctionJ : Structure := Build.rect 100 .intersection (m 20) (m 0) (m 30) (m 8)

/-- Lane B, the block beyond J: eastbound, its entrance end at the next junction K. -/
def laneB : Structure :=
  Build.lane 201 [(m 30, m 0), (m 50, m 0), (m 50, m 8), (m 30, m 8)] Build.east (enters := some 101)

/-- Junction K, the next one along. -/
def junctionK : Structure := Build.rect 101 .intersection (m 50) (m 0) (m 60) (m 8)

def map : List Structure := [laneA, junctionJ, laneB, junctionK]

/-- The car: 4 m by 2 m, heading east, at rest. -/
def car (x y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east (Units.metresPerSecond 0) (m 2, m 1, m 1)

def sceneAt (x y : Q) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [car x y] map []

/-- `holds` (compliant): A car's footprint overlaps a lane whose entrance end the source records as junction J, and its footprint does not overlap J. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => sceneAt (m 10) (m 4) t

/-- `fails` (violated): The same car has moved on and its footprint overlaps J, so it is no longer approaching it. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => sceneAt (m 29) (m 4) t

/-- `blind` (unknown): The source declares st.lane_enters absent, so which junction the lane the car occupies runs into cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => sceneAt (m 10) (m 4) t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("i", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"] ]

end TrafficSpecWitness.Concepts.position.approaching_intersection
