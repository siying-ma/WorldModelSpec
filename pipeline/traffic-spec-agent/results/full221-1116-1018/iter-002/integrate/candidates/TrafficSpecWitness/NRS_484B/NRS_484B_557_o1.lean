/-
  Witnesses for NRS_484B_557_o1.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - highway 1: the rectangle x ∈ [-200, 200], y ∈ [-20, 20];
  - lane 10 (eastbound): x ∈ [-100, 40], y ∈ [0, 4], on highway 1;
  - lane 11 (westbound): x ∈ [-100, 40], y ∈ [-4, 0], on highway 1;
  - railway crossing 20: x ∈ [0, 10], y ∈ [-6, 6], on highway 1 (its west edge is the nearest rail
    for an eastbound car);
  - stop sign 30: governs lane 10 (or, in `idle`, lane 11 only).
  The car (track 1, a motor vehicle) drives east along y = 2 with half-extents 2 m × 1 m, so the
  ground distance from its body to the crossing is −x − 2 m while its centre x is below −2 m.
  The reading's figures: 50 ft = 15.24 m, 15 ft = 4.572 m, halt tolerance 0.1 m/s. One observation
  per second; each trace ends at the entry into the crossing (centre x in [0, 10]).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_557_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_557_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 1 .highway (m (-200)) (m (-20)) (m 200) (m 20)

def eastLane : Structure :=
  { Build.lane 10 [(m (-100), m 0), (m 40, m 0), (m 40, m 4), (m (-100), m 4)] Build.east
      with ways := some [1] }

def westLane : Structure :=
  { Build.lane 11 [(m (-100), m (-4)), (m 40, m (-4)), (m 40, m 0), (m (-100), m 0)] Build.west
      with ways := some [1] }

def crossing : Structure :=
  { Build.rect 20 .railwayCrossing (m 0) (m (-6)) (m 10) (m 6) with ways := some [1] }

def structures : List Structure := [highway, eastLane, westLane, crossing]

/-- A trace of the car at the listed (centre x in m, speed in m/s), one per second, with the stop
    sign governing the listed lanes. -/
def drive (path : List (Int × Int)) (governed : List RegionId) : Trace :=
  Build.trace path.length 0 (Units.seconds 1) fun k t =>
    let (x, v) := path.getD k (0, 0)
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m x, m 2) Build.east (Units.metresPerSecond v) (m 2, m 1, m 1) ]
      structures
      [ Build.sign 30 .stopSign governed ]

/-- `forbid` (violated): A car on a lane governed by a stop sign approaches a railway crossing on the same highway from beyond the upper figure and drives into it without halting. -/
def forbidTrace : Trace :=
  drive [(-40, 10), (-28, 12), (-16, 12), (-4, 12), (5, 12)] [10]

/-- `permit` (compliant): The car halts at a distance from the crossing between the two figures, then drives into it. -/
def permitTrace : Trace :=
  drive [(-40, 10), (-25, 10), (-12, 0), (-12, 0), (-6, 5), (3, 5)] [10]

/-- `idle` (not_applicable): The car drives into a railway crossing from a lane that no stop sign governs. -/
def idleTrace : Trace :=
  drive [(-40, 10), (-28, 12), (-16, 12), (-4, 12), (5, 12)] [11]

/-- `blind` (unknown): The car halts somewhere on its approach and then enters the crossing, but the source maps no region outlines, so its distance to the crossing is unknown at every observation. -/
def blindTrace : Trace :=
  drive [(-40, 10), (-25, 10), (-12, 0), (-12, 0), (-6, 5), (3, 5)] [10]

/-- `history_boundary` (unknown): The recording begins with the car already moving inside the stopping zone, between the two figures from the crossing; it enters the crossing without a recorded halt; a halt before the recording cannot be excluded. -/
def history_boundaryTrace : Trace :=
  drive [(-14, 6), (-8, 6), (3, 6)] [10]

/-- `branch_1` (violated): The car halts only closer to the crossing than the lower figure, then enters it. -/
def branch_1Trace : Trace :=
  drive [(-40, 10), (-28, 12), (-16, 8), (-5, 0), (-5, 0), (5, 5)] [10]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_557_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the car's approach from the observation at which it was last farther than the upper figure from the crossing up to the start of the recording")
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_557_o1
