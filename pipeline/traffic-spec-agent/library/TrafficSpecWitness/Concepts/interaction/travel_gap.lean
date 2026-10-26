/-
  Witnesses for drv.interaction.travel_gap.

  One straight road running east and west carries the three scenarios. Every figure below is the
  witness's own, including the two values the instance gives the formal parameters: a travel gap of
  5 m and a travel-speed tolerance of 0.5 m/s.

  The road: a roadway region (id 10), its boundary polygon carried, from x = -200 m to x = 200 m
  and y = -5 m to y = 5 m, with no lane regions and no direction of its own — the body reads no
  region, no marking and no device, so the road is scenery that shows the relation is decided on a
  roadway a scene carries without lanes.

  The bodies are two cars 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m): track 1 is the formal
  `f`, the subject, and track 2 the formal `l`. Three observations one second apart from t = 0 s,
  both cars travelling, so each scene's positions advance 10 m along the course. Nothing of the
  body looks before or after the observation, so no padding and no window are needed, and the
  verdict is the same at each of the three instants.

  holds:  both cars go due east at 10 m/s and point due east, f's reference point at x = 0 m and
          l's at x = 12 m at t = 0 s, both advancing 10 m a second. The offset of l from f is
          (12, 0) m; f's velocity is (10, 0) m/s and its speed 10 m/s, so the offset along f's
          course is 12 m, and each body reaches 2 m from its own reference point to its own end,
          leaving 12 - 2 - 2 = 8 m of clear space between the two outlines along the course, at
          least the 5 m asked. In the written form: the inner product of the offset with f's
          velocity is 120 m²/s, against (5 + 2 + 2) × 10 = 90 m²/s. f's speed, 10 m/s, stands well
          clear of the tolerance of 0.5 m/s, so the body is defined.
  fails:  the same two 4 m cars going due east at 10 m/s, l's reference point only 4 m east of f's
          at t = 0 s, so the two bodies have come together: the offset along the course is 4 m and
          the two reaches take 4 m out of it, leaving nil clear space, less than the 5 m asked.
          In the written form: 40 m²/s against 90 m²/s.
  blind:  the holds scene on a source whose manifest declares kin.extent absent. Both positions,
          both velocities and both speeds are observed, so f's course and the offset along it are
          decided and the precondition holds, but how far each body reaches beyond its reference
          point is unobserved, so how much clear space is left between the two outlines is
          undecided and the concept is unknown for that atom alone.
-/
import TrafficSpec.Concepts.interaction.travel_gap
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.travel_gap

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: f ↦ 1, l ↦ 2

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. A travel gap of 5 m is this witness's own figure for the clear space the caller
    asks l to leave f along f's course, and carries no judgement that 5 m is reasonable, prudent or
    safe; a travel-speed tolerance of 0.5 m/s is the speed below which this source's measured
    velocity is taken to fix no direction of travel. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.travel_gap@w"
    concept := "drv.interaction.travel_gap"
    literals := []
    nats := []
    params :=
      [ ("travel_gap", .lit (Units.metres 5) .metre)
      , ("travel_speed_tolerance", .lit (Units.micrometresPerSecond 500000) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The road: one roadway without lanes, scenery the body never reads
-- ---------------------------------------------------------------------------------------------
/-- The roadway the two cars are on: its boundary polygon carried, no lane information. -/
def roadway : Structure := Build.rect 10 .roadway (m (-200)) (m (-5)) (m 200) (m 5)

def structures : List Structure := [roadway]

/-- Ten metres a second, the speed both cars travel at. -/
def travelSpeed : Q := Units.metresPerSecond 10

/-- Due east at 10 m/s, the velocity both cars carry. -/
def eastbound : Vec := Build.scale Build.east travelSpeed

/-- A car of the witness: 4 m long and 2 m wide, on the centre line of the road at easting `x`,
    pointing due east and travelling due east at 10 m/s. -/
def car (track : TrackId) (x : Q) : RoadUser :=
  Build.withKin
    (Build.user track [.motorVehicle] (x, m 0) Build.east travelSpeed (m 2, m 1, m 1))
    fun k => { k with velocity := some eastbound, yawRate := some Q.zero }

/-- The easting of a car at the observation at second `k`: `x0` metres at t = 0 s, 10 m of travel
    each second. -/
def easting (x0 : Int) (k : Nat) : Q := m (x0 + 10 * Int.ofNat k)

/-- `holds` (compliant): The caller asks for a travel gap of 5 m with a travel-speed tolerance of 0.5 m/s. Two cars 4 m long go due east at 10 m/s, the leader's reference point 12 m due east of the subject's. The offset along the subject's course is 12 m and each body reaches 2 m beyond its reference point, so the space left between the two outlines along the course is 8 m, which is at least the 5 m asked, and the subject's speed stands well clear of the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting 0 k)
      , car 2 (easting 12 k) ]
      structures
      []

/-- `fails` (violated): The same caller's figures and the same two 4 m cars going east at 10 m/s, the leader's reference point only 4 m east of the subject's, so the two bodies have come together and the space left along the subject's course is nil, less than the 5 m asked. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (easting 0 k)
      , car 2 (easting 4 k) ]
      structures
      []

/-- `blind` (unknown): The same two cars 12 m apart going east, on a source that reports positions, velocities and speeds but declares the bodies' extent absent. How far each body reaches beyond its reference point is unobserved, so how much space is left between the two outlines is undecided and the concept is unknown. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("f", 1), ("l", 2)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.extent"] ]

end TrafficSpecWitness.Concepts.interaction.travel_gap
