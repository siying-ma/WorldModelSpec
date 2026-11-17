/-
  Witnesses for NRS_484B_560_3_o2.

  Geometry (the witness's own figures, none of them in the rule):
  - a highway (region 10) x ∈ [-200, 50] m, y ∈ [-10, 10] m; the road runs east–west.
  - two-lane scenes: lane 11 (eastbound, y ∈ [-3.5, 0]) and lane 12 (westbound, y ∈ [0, 3.5]),
    both lying on highway 10; four-lane scene (`branch_1`): lanes 11 (y ∈ [-7, -3.5]) and
    12 (y ∈ [-3.5, 0]) eastbound, 13 (y ∈ [0, 3.5]) and 14 (y ∈ [3.5, 7]) westbound, all on 10.
  - a railway crossing (region 20) x ∈ [0, 6] m across the whole way.
  - cars: half-length 2 m, half-width 1 m, all heading east, halted (speed 0).
  - side-by-side scenes: the other car (2) centred at x = -12 m in lane 11 (front 10 m from the
    crossing), the subject (1) centred at x = -11 m in the lane to its left (front 9 m from the
    crossing): longitudinal overlap 3 m, both well within the 15.2 m reach.
  - `permit`: the other car centred at x = -2.5 m (front 0.5 m from the crossing), the subject
    centred at x = -14.5 m behind it in the same lane (front 12.5 m from the crossing, 8 m gap):
    overlap -8 m.
  - each trace has three instants one second apart, all alike.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_3_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_3_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 200, cm 100, cm 75)

def car (track : TrackId) (x y : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) Build.east Q.zero carExtent

def highway : Structure := Build.rect 10 .highway (m (-200)) (m (-10)) (m 50) (m 10)
def crossing : Structure := Build.rect 20 .railwayCrossing (m 0) (m (-10)) (m 6) (m 10)

def laneOn (id : RegionId) (y0 y1 : Q) (dir : Vec) : Structure :=
  { Build.lane id [(m (-200), y0), (m 50, y0), (m 50, y1), (m (-200), y1)] dir with ways := some [10] }

/-- Two-lane two-way highway: lane 11 eastbound (south half), lane 12 westbound (north half). -/
def twoLane : List Structure :=
  [ highway
  , laneOn 11 (cm (-350)) (m 0) Build.east
  , laneOn 12 (m 0) (cm 350) Build.west
  , crossing ]

/-- Four-lane highway: lanes 11, 12 eastbound, 13, 14 westbound. -/
def fourLane : List Structure :=
  [ highway
  , laneOn 11 (cm (-700)) (cm (-350)) Build.east
  , laneOn 12 (cm (-350)) (m 0) Build.east
  , laneOn 13 (m 0) (cm 350) Build.west
  , laneOn 14 (cm 350) (cm 700) Build.west
  , crossing ]

def railDevice (governs : List RegionId) (lights : RailLights) (gate : GateState) : Device :=
  { Build.device 30 .railwaySignalOrGate governs with railLights := some lights, gate := some gate }

def flashing2 : Device := railDevice [11, 12] .flashing GateState.none

/-- The other car (2) in lane 11 and the subject (1) beside it in lane 12, overlap 3 m. -/
def sideBySide : List RoadUser :=
  [ car 1 (m (-11)) (cm 175), car 2 (m (-12)) (cm (-175)) ]

def sideBySideScene (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1) sideBySide twoLane devices

/-- `forbid` (violated): Two-lane two-way highway (two lanes on the way); railway lights flashing govern the subject's lane; another car halts 10 m from the crossing in the right lane, and the subject car pulls up beside it in the opposing lane, same direction, longitudinal overlap 3 m. -/
def forbidTrace : Trace := sideBySideScene [flashing2]

/-- `permit` (compliant): Same two-lane highway and flashing lights; the subject car halts in the right lane 8 m behind the other car (longitudinal overlap negative); no road user beside it. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (cm (-1450)) (cm (-175)), car 2 (cm (-250)) (cm (-175)) ]
      twoLane
      [ flashing2 ]

/-- `idle` (not_applicable): Lights dark and gate up at the crossing, no stop sign, red signal or stop direction governs the subject's lane; two cars pass side by side. -/
def idleTrace : Trace := sideBySideScene [railDevice [11, 12] .dark .up]

/-- `blind` (unknown): Flashing lights govern the subject's lane on a two-lane highway; another car halts beside it at the crossing in the same direction, but the longitudinal overlap is unobserved. -/
def blindTrace : Trace :=
  -- As planned. Masking rel.longitudinal_overlap drops only a supplied value; Core computes the
  -- overlap from the two footprints, which admission requires of every occupancy-observed track,
  -- so this witness cannot be unknown (see task_result.md).
  sideBySideScene [flashing2]

/-- `branch_1` (not_applicable): Four-lane highway (four lanes lie on the way, two per direction); flashing lights; the subject car halts in the left same-direction lane beside a car in the right lane. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m (-11)) (cm (-175)), car 2 (m (-12)) (cm (-525)) ]
      fourLane
      [ railDevice [11, 12, 13, 14] .flashing GateState.none ]

/-- `branch_2` (compliant): Two-lane highway, flashing lights; the subject car halts alone at the crossing, no other road user in the scene. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m (-11)) (cm (-175)) ]
      twoLane
      [ flashing2 ]

/-- `branch_3` (violated): a stop sign governs both lanes (no railway device); the two cars side by side as in `forbid`. -/
def branch_3Trace : Trace := sideBySideScene [Build.sign 31 .stopSign [11, 12]]

/-- `branch_4` (violated): a traffic signal showing circular red governs both lanes; the two cars side by side. -/
def branch_4Trace : Trace := sideBySideScene [Build.signal 32 [11, 12] [.circularRed]]

/-- `branch_5` (violated): a police officer directing stop governs both lanes; the two cars side by side. -/
def branch_5Trace : Trace :=
  sideBySideScene
    [ { Build.device 33 .humanDirection [11, 12] with
          humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_6` (violated): railway lights dark but the gate down, governing both lanes; the two cars side by side. -/
def branch_6Trace : Trace := sideBySideScene [railDevice [11, 12] .dark .down]

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
  , witness "blind" blindTrace (.unknown []) ["rel.longitudinal_overlap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_560_3_o2
