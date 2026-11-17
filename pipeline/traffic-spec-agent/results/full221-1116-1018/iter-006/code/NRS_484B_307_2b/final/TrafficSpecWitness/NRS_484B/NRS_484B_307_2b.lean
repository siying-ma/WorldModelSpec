/-
  Witnesses for NRS_484B_307_2b.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - roadway 100: x ∈ [-100, 100] m, y ∈ [0, 7] m; lane 101 (y ∈ [0, 3.5], eastbound) and lane 102
    (y ∈ [3.5, 7], westbound).
  - crosswalk 200 (marked), 4 m wide across the roadway: at x ∈ [-2, 2] where the pedestrian crosses
    in it (permit, branch_1), at x ∈ [28, 32] — 30 m away — where it does not.
  - pedestrian 1 (track 1, class pedestrian) at x = 0, walking north at 1.3 m/s, y = 1.0, 2.3, 3.6 m at
    t = 0, 1, 2 s: across the lanes' directions (cosine 0, bound 0.94; speed 1.3 > 0.1 m/s).
  - traffic signal head 300 at (0, 27) m: straight ahead, 23–26 m away (reach 60 m; cosine 1, bound
    0.87). It shows circular_green alone (forbid, permit, blind, branch_1), circular_red (idle), or
    circular_green with a green left arrow (branch_2).
  - branch_1 adds pedestrian signal 301 at (0, 9) m governing the crosswalk and the lanes, showing
    dont_walk_steady.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def pedestrian (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, Units.micrometres (1000000 + 1300000 * (k : Int))) Build.north
    (Units.micrometresPerSecond 1300000) (cm 30, cm 30, cm 90)

def roadway : Structure := Build.rect 100 .roadway (m (-100)) (m 0) (m 100) (m 7)
def lane1 : Structure :=
  Build.lane 101 [(m (-100), m 0), (m 100, m 0), (m 100, cm 350), (m (-100), cm 350)] Build.east
def lane2 : Structure :=
  Build.lane 102 [(m (-100), cm 350), (m 100, cm 350), (m 100, m 7), (m (-100), m 7)] Build.west

def crosswalkAt (x0 : Int) : Structure :=
  { Build.rect 200 .crosswalk (m x0) (m (-2)) (m (x0 + 4)) (m 9) with marked := some true }

def signalHead (shows : List SignalIndication) (positioned : Bool := true) : Device :=
  { Build.signal 300 [101, 102] shows with
    position := if positioned then some (m 0, m 27) else none }

def pedSignal : Device :=
  { Build.device 301 .pedestrianSignal [200, 100, 101, 102] (some (m 0, m 9)) with
    pedState := some .dontWalkSteady }

def crossing (crosswalkX : Int) (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ pedestrian k ]
      [ roadway, lane1, lane2, crosswalkAt crosswalkX ]
      devices

/-- `forbid` (violated): A pedestrian (ru.aggregate pedestrian) crosses a st.lane of a st.roadway at 1.3 m/s perpendicular to its designated direction (drv.motion.moving_across_carrier holds), 30 m from any st.crosswalk, facing a dev.traffic_signal head 25 m ahead (dev.position within the facing angle) that displays circular_green alone; no pedestrian signal governs; no other road user is in the scene. -/
def forbidTrace : Trace := crossing 28 [ signalHead [.circularGreen] ]

/-- `permit` (compliant): The same pedestrian makes the same crossing within a marked crosswalk (rel.occupies st.crosswalk). -/
def permitTrace : Trace := crossing (-2) [ signalHead [.circularGreen] ]

/-- `idle` (not_applicable): The signal the pedestrian faces displays circular_red. -/
def idleTrace : Trace := crossing 28 [ signalHead [.circularRed] ]

/-- `blind` (unknown): The pedestrian crosses outside a crosswalk while a signal displays circular_green alone, but the positions of the signal heads are not observed: whether it faces the signal cannot be read. -/
def blindTrace : Trace := crossing 28 [ signalHead [.circularGreen] (positioned := false) ]

/-- `branch_1` (not_applicable): A dev.pedestrian_signal governing the crossing displays dont_walk_steady, so NRS_484B_283_1d4_o1 applies to the pedestrian: another device directs it, and this rule does not apply. -/
def branch_1Trace : Trace := crossing (-2) [ signalHead [.circularGreen], pedSignal ]

/-- `branch_2` (not_applicable): the head shows circular green together with a green left arrow:
    the signal is not circular green alone. -/
def branch_2Trace : Trace := crossing 28 [ signalHead [.circularGreen, .greenArrow .left] ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_2b"
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
  , witness "blind" blindTrace (.unknown []) ["dev.position"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_2b
