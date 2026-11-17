/-
  Witnesses for NRS_484B_560_3_o1.

  Geometry (the witness's own figures; none appears in the rule). A straight road runs east along
  +x. The highway (region 31) is the rectangle x ∈ [-50, 60], y ∈ [-3, 10]. Two lanes: the right
  lane 11 (y ∈ [0, 3.5]) and the left lane 12 (y ∈ [3.5, 7]); eastbound both in the one-way scenes,
  12 westbound in branch_1. The right road edge 21 is the strip y ∈ [-0.2, 0], the left road edge
  22 the strip y ∈ [7, 7.2]; both lie on highway 31. The railway crossing 41 spans the road ahead.
  The subject (track 1) is a car, half-extents 2.25 × 0.9 × 0.75 m, heading east and halted at
  x = 10, so its front is at x = 12.25; the crossing begins at x = 20.25 (8 m ahead) or, in
  branch_1, at x = 22.25 (10 m ahead): inside the 15.2 m approach reach either way.
  The body's distance to the right edge is the car's centre y less 0.9 m: 4.5 m (y = 5.4, left
  lane), 0.4 m (y = 1.3, right lane), 2.5 m (y = 3.4, straddling the lane line); against the
  1.0 m edge gap. Three instants, one second apart; the rule reads one observation, no window.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_3_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_3_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneRight : RegionId := 11
def laneLeft : RegionId := 12
def edgeRight : RegionId := 21
def edgeLeft : RegionId := 22
def highway : RegionId := 31
def crossing : RegionId := 41

/-- The subject car, halted, heading east, its centre at (10, y). -/
def car (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 10, y) Build.east Q.zero (cm 225, cm 90, cm 75)

/-- The road: highway, two lanes, both road edges on the highway, and the crossing beginning at `x0`. -/
def road (x0 : Q) : List Structure :=
  [ Build.rect highway .highway (m (-50)) (m (-3)) (m 60) (m 10)
  , Build.rect laneRight .lane (m (-50)) (m 0) (m 60) (cm 350)
  , Build.rect laneLeft .lane (m (-50)) (cm 350) (m 60) (m 7)
  , { Build.rect edgeRight .roadEdge (m (-50)) (cm (-20)) (m 60) (m 0) with ways := some [highway] }
  , { Build.rect edgeLeft .roadEdge (m (-50)) (m 7) (m 60) (cm 720) with ways := some [highway] }
  , Build.rect crossing .railwayCrossing x0 (m (-3)) (Q.add x0 (m 6)) (m 10) ]

/-- The railway lights and gate, governing both lanes. -/
def railway (lights : RailLights) (gate : GateState) : Device :=
  { Build.device 51 .railwaySignalOrGate [laneRight, laneLeft] with
      railLights := some lights, gate := some gate }

def sceneOf (y x0 : Q) (devs : List Device) : Timestamp → Scene := fun t =>
  Build.scene t (some 1) [car y] (road x0) devs

/-- `forbid` (violated): Railway signal lights flashing and gate down govern the two-lane approach of a one-way roadway; the subject car halts 8 m from the railway crossing in the left lane, its body 4.5 m from the right-hand road edge (prim.region_lateral_offset negative), farther than p.pullover_edge_gap. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 540) (cm 2025) [railway .flashing .down] t

/-- `permit` (compliant): Same crossing and flashing lights; the subject car halts 8 m from the crossing in the rightmost lane, its body 0.4 m from the right-hand road edge. (Gate up: the lights alone require the halt.) -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 130) (cm 2025) [railway .flashing .up] t

/-- `idle` (not_applicable): The subject car is 8 m from a railway crossing whose lights are dark and gate up; no stop sign, red signal or stop direction governs its lane. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 540) (cm 2025) [railway .dark .up] t

/-- `blind` (unknown): Lights flashing govern the subject's lane near a crossing; the source maps regions without their outline, so the distance to the crossing and to the road edge is unobserved. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 130) (cm 2025) [railway .flashing .down] t

/-- `branch_1` (violated): A stop sign governs the subject's lane 10 m from a railway crossing on a two-lane two-way highway; the subject car halts straddling the centre line, its body 2.5 m from the right-hand road edge. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) [car (cm 340)]
      [ Build.rect highway .highway (m (-50)) (m (-3)) (m 60) (m 10)
      , Build.lane laneRight [(m (-50), m 0), (m 60, m 0), (m 60, cm 350), (m (-50), cm 350)] Build.east
      , Build.lane laneLeft [(m (-50), cm 350), (m 60, cm 350), (m 60, m 7), (m (-50), m 7)] Build.west
      , { Build.rect edgeRight .roadEdge (m (-50)) (cm (-20)) (m 60) (m 0) with ways := some [highway] }
      , { Build.rect edgeLeft .roadEdge (m (-50)) (m 7) (m 60) (cm 720) with ways := some [highway] }
      , Build.rect crossing .railwayCrossing (cm 2225) (m (-3)) (cm 2825) (m 10) ]
      [ Build.sign 54 .stopSign [laneRight] ]
      (occupies := some [(1, laneRight), (1, laneLeft), (1, highway)])

-- branch_2 (violated): gate lowering with the lights dark governs the left lane; the car halts there, 4.5 m from the right edge.
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 540) (cm 2025) [railway .dark .lowering] t

-- branch_3 (violated): a traffic signal showing circular red governs both lanes; the car halts in the left lane, 4.5 m from the right edge.
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 540) (cm 2025) [Build.signal 52 [laneRight, laneLeft] [.circularRed]] t

-- branch_4 (violated): a police officer directs both lanes to stop; the car halts in the left lane, 4.5 m from the right edge.
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 540) (cm 2025)
      [{ Build.device 53 .humanDirection [laneRight, laneLeft] with
          humanRole := some .policeOfficer, humanIndication := some .stop }] t

-- branch_5 (violated): lights flashing; the car hugs the left road edge (0.4 m from it, on its left), 4.8 m from the right edge.
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    sceneOf (cm 570) (cm 2025) [railway .flashing .down] t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_560_3_o1"
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
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_560_3_o1
