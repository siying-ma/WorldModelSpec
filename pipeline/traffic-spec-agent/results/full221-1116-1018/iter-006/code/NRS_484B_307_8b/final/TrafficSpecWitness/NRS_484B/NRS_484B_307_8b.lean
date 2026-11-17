/-
  Witnesses for NRS_484B_307_8b.

  Geometry (the witness's own figures, nowhere in the rule): an east–west roadway (region 10)
  between y = 0 and y = 20 m, a marked crosswalk (11) across it for x ∈ [−3, 3], a near sidewalk
  (12, y ∈ [−5, 0]) and a far sidewalk (13, y ∈ [20, 25]). A vehicular signal head (device 20)
  governing the roadway stands on the far sidewalk at (4, 24); a pedestrian signal head (21)
  governing the crosswalk at (−4, 24). The pedestrian (track 1) heads north along x = 0.
  From (0, −1) the vehicular head is 25.3 m away at 9.1° off the heading; from (0, 1) 23.3 m at
  9.9°: both well inside the reading's 60 m and ≈ 30° (cos 0.87).
  Instants 0, 1, 2 s; the rule compares each observation with the previous one, so every witness
  speaks about instants 1 and 2 (`window`).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def roadway : Structure := Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 20)
def crosswalk : Structure := { Build.rect 11 .crosswalk (m (-3)) (m 0) (m 3) (m 20) with marked := some true }
def nearSidewalk : Structure := Build.rect 12 .sidewalk (m (-50)) (m (-5)) (m 50) (m 0)
def farSidewalk : Structure := Build.rect 13 .sidewalk (m (-50)) (m 20) (m 50) (m 25)
def structures : List Structure := [roadway, crosswalk, nearSidewalk, farSidewalk]

def vehicularHead (shows : List SignalIndication) : Device :=
  { Build.signal 20 [10] shows with position := some (m 4, m 24) }
def pedestrianHead (st : PedSignalState) : Device :=
  { Build.device 21 .pedestrianSignal [11] (some (m (-4), m 24)) with pedState := some st }

def pedestrian (y : Int) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, m y) Build.north (Units.metresPerSecond 1) (cm 30, cm 30, cm 90)

/-- Three instants; the pedestrian at `ys[k]` (north coordinate, m) at instant k. -/
def mk (ys : List Int) (shows : List SignalIndication) (st : PedSignalState) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [pedestrian (ys.getD k 0)] structures
      [vehicularHead shows, pedestrianHead st]

/-- `forbid` (violated): A pedestrian stands on the sidewalk at a corner, 25 m from a vehicular head it faces (heading within 10 degrees of the line to the head) that displays circular_red alone; the pedestrian head it faces displays dont_walk_steady. At the next observation its footprint overlaps the roadway. -/
def forbidTrace : Trace := mk [-3, -1, 1] [.circularRed] .dontWalkSteady

/-- `permit` (compliant): Same scene; the pedestrian stays on the sidewalk while the head displays circular_red alone. -/
def permitTrace : Trace := mk [-3, -1, -1] [.circularRed] .dontWalkSteady

/-- `idle` (not_applicable): The head the pedestrian faces displays circular_green alone; it steps onto the roadway. -/
def idleTrace : Trace := mk [-3, -1, 1] [.circularGreen] .dontWalkSteady

/-- `blind` (unknown): As forbid, but the source supplies no heading for the pedestrian: whether it faces the head is unknown. -/
def blindTrace : Trace := mk [-3, -1, 1] [.circularRed] .dontWalkSteady

/-- `branch_1` (not_applicable): As forbid, but the pedestrian head it faces displays walk: NRS_484B_283_1d1 applies to it and the duty of this paragraph does not. -/
def branch_1Trace : Trace := mk [-3, -1, 1] [.circularRed] .walk

/-- `branch_2` (not_applicable): As forbid, but the head shows a green left arrow beside the
    circular red: not a steady red alone. -/
def branch_2Trace : Trace := mk [-3, -1, 1] [.circularRed, .greenArrow .left] .dontWalkSteady

/-- `branch_3` (not_applicable): Facing the steady red alone, a pedestrian already on the roadway
    steps back onto the sidewalk: it was on the roadway at the previous observation, so it does not
    enter. -/
def branch_3Trace : Trace := mk [3, 1, -1] [.circularRed] .dontWalkSteady

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_8b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_8b
