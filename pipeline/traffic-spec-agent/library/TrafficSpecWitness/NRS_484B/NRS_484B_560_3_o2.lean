/-
  Witnesses for NRS_484B_560_3_o2.

  Geometry (the witness's own figures; none appears in the rule). A highway (region 10) runs
  east along x from 0 to 200 m. Two-lane scenes: lane 11 (eastbound, the right lane) covers
  y ∈ [-4, 0], lane 12 (westbound, the opposing lane) y ∈ [0, 4]; the highway y ∈ [-6, 6]. Both
  lanes lie on the highway. The railroad crossing (region 20) covers x ∈ [100, 106] across the whole
  way. Four-lane scene: lanes 11 (y ∈ [-7, -3.5]) and 13 (y ∈ [-3.5, 0]) eastbound, 12
  (y ∈ [0, 3.5]) and 14 (y ∈ [3.5, 7]) westbound, the highway y ∈ [-9, 9].

  Cars are 4 m long and 1.8 m wide, all heading east. Against the reading
  (p.railroad_crossing_approach_reach = 15.2 m, p.side_by_side_same_direction_cos = 0.9):
  - side by side: car 2 at x = 88 (body [86, 90], 10 m from the crossing) in lane 11; the subject at
    x = 89 (body [87, 91], 9 m from the crossing) beside it; overlap 3 m, headings equal;
  - permit: car 2 at x = 97 (body [95, 99], 1 m from the crossing), the subject at x = 85 (body
    [83, 87], 13 m from the crossing, 2.2 m inside the reach) 8 m behind it: overlap -8 m.
  The railway device (30) governs the lanes; a stop sign (32), a signal (31) and a railroad flagger
  (33) replace it in the branch scenes that exercise the other halt devices. Three instants, 1 s
  apart; no operator looks back.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_3_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_3_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- A car heading east, 4 m long and 1.8 m wide. -/
def car (track : TrackId) (x y : Q) (speed : Q := Q.zero) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east speed (cm 200, cm 90, cm 75)

def highway2 : Structure := Build.rect 10 .highway (m 0) (m (-6)) (m 200) (m 6)
def highway4 : Structure := Build.rect 10 .highway (m 0) (m (-9)) (m 200) (m 9)

/-- A lane between `y0` and `y1`, lying on the highway. -/
def laneOn (id : RegionId) (y0 y1 : Q) (dir : Vec) : Structure :=
  { Build.lane id [(m 0, y0), (m 200, y0), (m 200, y1), (m 0, y1)] dir with ways := some [10] }

def crossing2 : Structure := Build.rect 20 .railwayCrossing (m 100) (m (-6)) (m 106) (m 6)
def crossing4 : Structure := Build.rect 20 .railwayCrossing (m 100) (m (-9)) (m 106) (m 9)

def twoLane : List Structure :=
  [ highway2
  , laneOn 11 (m (-4)) (m 0) Build.east
  , laneOn 12 (m 0) (m 4) Build.west
  , crossing2 ]

def fourLane : List Structure :=
  [ highway4
  , laneOn 11 (m (-7)) (cm (-350)) Build.east
  , laneOn 13 (cm (-350)) (m 0) Build.east
  , laneOn 12 (m 0) (cm 350) Build.west
  , laneOn 14 (cm 350) (m 7) Build.west
  , crossing4 ]

/-- The crossing's lights and gate, governing the given lanes. -/
def railDev (governs : List RegionId) (lights : RailLights) (gate : GateState) : Device :=
  { Build.device 30 .railwaySignalOrGate governs (some (m 99, m (-5))) with
      railLights := some lights, gate := some gate }

/-- The subject beside car 2 (opposing lane), overlap 3 m, both within the reach. -/
def sideBySide : List RoadUser := [car 1 (m 89) (m 2), car 2 (m 88) (m (-2))]

def staticTrace (users : List RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => Build.scene t (some 1) users structures devices

/-- `forbid` (violated): Two-lane two-way highway (two lanes on the way); railway lights flashing govern the subject's lane; another car halts 10 m from the crossing in the right lane, and the subject car pulls up beside it in the opposing lane, same direction, longitudinal overlap 3 m. -/
def forbidTrace : Trace :=
  staticTrace sideBySide twoLane [railDev [11, 12] .flashing GateState.none]

/-- `permit` (compliant): Same two-lane highway and flashing lights; the subject car halts in the right lane 8 m behind the other car (longitudinal overlap negative); no road user beside it. -/
def permitTrace : Trace :=
  staticTrace [car 1 (m 85) (m (-2)), car 2 (m 97) (m (-2))] twoLane
    [railDev [11, 12] .flashing GateState.none]

/-- `idle` (not_applicable): Lights dark and gate up at the crossing, no stop sign, red signal or stop direction governs the subject's lane; two cars pass side by side. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let dx : Q := m (5 * (k : Int))
    Build.scene t (some 1)
      [ car 1 (Q.add (m 84) dx) (m 2) (Units.metresPerSecond 5)
      , car 2 (Q.add (m 83) dx) (m (-2)) (Units.metresPerSecond 5) ]
      twoLane
      [railDev [11, 12] .dark .up]

/-- `blind` (unknown): Two-lane highway; railway lights flashing at the crossing, but which travel regions the device governs is unobserved; no stop sign, signal or human direction; another car halts beside the subject at the crossing in the same direction, longitudinal overlap 3 m. Whether stopping is required of the subject's lane cannot be decided, so the duty's applicability, and the verdict, is unknown. -/
def blindTrace : Trace :=
  staticTrace sideBySide twoLane
    [{ railDev [] .flashing GateState.none with governsObserved := false }]

/-- `branch_1` (not_applicable): Four-lane highway (four lanes lie on the way, two per direction); flashing lights; the subject car halts in the left same-direction lane beside a car in the right lane. -/
def branch_1Trace : Trace :=
  staticTrace [car 1 (m 89) (cm (-175)), car 2 (m 88) (cm (-525))] fourLane
    [railDev [11, 12, 13, 14] .flashing GateState.none]

/-- `branch_2` (compliant): Two-lane highway, flashing lights; the subject car halts alone at the crossing, no other road user in the scene. -/
def branch_2Trace : Trace :=
  staticTrace [car 1 (m 89) (m (-2))] twoLane [railDev [11, 12] .flashing GateState.none]

/-- `branch_3` (violated): lights dark but the gate down governs the lanes; the subject halts beside
    car 2 as in `forbid` (exercises the gate leaf). -/
def branch_3Trace : Trace :=
  staticTrace sideBySide twoLane [railDev [11, 12] .dark .down]

/-- `branch_4` (violated): no railway device; a stop sign governs the lanes; side by side as in
    `forbid` (exercises the stop-sign limb). -/
def branch_4Trace : Trace :=
  staticTrace sideBySide twoLane [Build.sign 32 .stopSign [11, 12]]

/-- `branch_5` (violated): no railway device; a signal showing circular red governs the lanes; side
    by side as in `forbid` (exercises the traffic-signal limb). -/
def branch_5Trace : Trace :=
  staticTrace sideBySide twoLane [Build.signal 31 [11, 12] [.circularRed]]

/-- `branch_6` (violated): no railway device; a railroad flagger directs stop for the lanes; side
    by side as in `forbid` (exercises the human-direction limb). -/
def branch_6Trace : Trace :=
  staticTrace sideBySide twoLane
    [{ Build.device 33 .humanDirection [11, 12] (some (m 98, m (-5))) with
        humanRole := some .railroadFlagger, humanIndication := some .stop }]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_560_3_o2"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_560_3_o2
