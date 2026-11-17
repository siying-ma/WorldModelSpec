/-
  Witnesses for NRS_484B_153_3.

  Geometry: one east-bound roadway, the rectangle x ∈ [-50, 50] m, y ∈ [0, 7] m, its curb along
  y = 0. A passenger car (track 1, motor vehicle; half-extents 2.3 m × 0.9 m × 0.75 m) stands at
  (0, 1) m, heading east, speed zero, against the curb; its left (north) side faces passing
  traffic. Every trace is sampled at 1 s.

  - forbid: the traffic-side door is open from 0 s to 300 s (five minutes); the judged instants are
    61 s … 300 s, where the 60 s window behind is covered and the door was open throughout it,
    by a margin of up to 240 s over the reading's bound.
  - permit: over 0 s … 150 s, the traffic-side door is open only from 80 s to 94 s (15 s); at every
    open instant the window behind holds closed instants, the open stretch 45 s short of the bound.
    Judged instants 61 s … 150 s.
  - idle: the traffic-side door closed, the curb-side door open, over 0 s … 2 s.
  - blind: as forbid's car, the source declaring sig.door_open absent.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_153_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_153_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The roadway the car stands on, its curb along y = 0. -/
def roadway : Structure := Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 7)

/-- The car at the curb, with the doors open as given. -/
def car (doors : List DoorSide) : RoadUser :=
  Build.withSignals
    (Build.user 1 [.motorVehicle] (m 0, m 1) Build.east Q.zero (cm 230, cm 90, cm 75))
    (fun s => { s with doorsOpen := some doors })

/-- `forbid` (violated): A car stopped at the curb keeps its traffic-side door open for five minutes. -/
def forbidTrace : Trace :=
  Build.trace 301 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car [.traffic] ]
      [ roadway ]
      [ ]

/-- `permit` (compliant): A car stopped at the curb opens its traffic-side door for 15 s while a passenger gets out, then closes it. -/
def permitTrace : Trace :=
  Build.trace 151 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (if 80 ≤ k ∧ k < 95 then [.traffic] else []) ]
      [ roadway ]
      [ ]

/-- `idle` (not_applicable): A car stopped at the curb with its traffic-side door closed and its curb-side door open. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car [.curb] ]
      [ roadway ]
      [ ]

/-- `blind` (unknown): A car stopped at the curb; the source declares sig.door_open absent. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car [.traffic] ]
      [ roadway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_153_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (61000, 300000))
  , witness "permit" permitTrace .compliant (window := some (61000, 150000))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.door_open"] ]

end TrafficSpecWitness.NRS_484B_153_3
