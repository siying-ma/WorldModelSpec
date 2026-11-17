/-
  Witnesses for NRS_484B_307_9c.

  Geometry (x east, y north, metres). Intersection i (100): x 0..10, y 0..10. West leg, divided:
  roadway W1 (101) x -30..0, y 0..4; median (102) y 4..6; roadway W2 (103) y 6..10, westbound.
  W1's recorded direction is north: the composed NRS_484B_283_1d4_o1 reads st_lane_direction on
  the roadway the pedestrian head governs and engaged (branch_3) only with that direction along
  the pedestrian's heading; with east it was decided not engaged (see task_result.md). South leg
  roadway S (105) x 0..10, y -30..0, with its northbound lane g (106) x 5..10 entering i. Sidewalk
  (104) x -30..0, y -4..0, south of W1. Vehicular head h (200) at (1, 16) governs g; pedestrian head
  d (201, branches 1-3 only) at (-2, 13) governs W1. The pedestrian (track 1) walks north at x = -2:
  on the sidewalk at (-2, -2), on W1 at (-2, 1), on the median at (-2, 5), on W2 at (-2, 7). From
  every one of these points it faces h (cosine ≥ 0.94, distance ≤ 19 m against 0.87 and 60 m) and d
  (cosine 1, distance ≤ 15 m against 0.87 and 40 m), and lies within 3 m of i.
  Instants 0, 1, 2, 3 s; the step (where there is one) is between 1 s and 2 s. The judged window
  starts at 1 s, so the rise is read with its previous observation; branches 1-3 judge the step at
  2 s only.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def structures : List Structure :=
  [ Build.rect 100 .intersection (m 0) (m 0) (m 10) (m 10)
  , { Build.rect 101 .roadway (m (-30)) (m 0) (m 0) (m 4) with
        lane := some { direction := some Build.north } }
  , Build.rect 102 .medianOrDivider (m (-30)) (m 4) (m 0) (m 6)
  , { Build.rect 103 .roadway (m (-30)) (m 6) (m 0) (m 10) with
        lane := some { direction := some Build.west } }
  , Build.rect 104 .sidewalk (m (-30)) (m (-4)) (m 0) (m 0)
  , Build.rect 105 .roadway (m 0) (m (-30)) (m 10) (m 0)
  , Build.lane 106 [(m 5, m (-30)), (m 10, m (-30)), (m 10, m 0), (m 5, m 0)] Build.north
      (enters := some 100) ]

def head (shows : List SignalIndication) (governs : List RegionId := [106]) : Device :=
  { Build.signal 200 governs shows with position := some (m 1, m 16) }

def redLeftArrow : List SignalIndication := [.circularRed, .greenArrow .left]

def pedHead (st : PedSignalState) (countdown : Bool) : Device :=
  { Build.device 201 .pedestrianSignal [101] (some (m (-2), m 13)) with
      pedState := some st, countdown := some countdown }

def ped (y : Int) : RoadUser :=
  Build.user 1 [.pedestrian] (m (-2), m y) Build.north (Units.metresPerSecond 1) (cm 30, cm 30, cm 90)

/-- y position of a pedestrian on the sidewalk until 1 s, then on W1. -/
def stepY (k : Nat) : Int := if k ≤ 1 then -2 else 1

def mk (devices : List Device) (y : Nat → Int) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped (y k)] structures devices

/-- `forbid` (violated): A pedestrian stands on the corner sidewalk next to intersection i. Head h, across i, governs a lane g that enters i and displays circular_red with green_arrow(left), no circular_green; the pedestrian faces h within reach and within the facing angle. No pedestrian signal is present and no other road user. The pedestrian steps off the sidewalk: its footprint comes to overlap a roadway, having overlapped no roadway, lane, median or safety zone at the previous observation. -/
def forbidTrace : Trace := mk [head redLeftArrow] stepY

/-- `permit` (compliant): As in forbid, but the pedestrian stays on the sidewalk while h displays the red with the arrow. -/
def permitTrace : Trace := mk [head redLeftArrow] fun _ => -2

/-- `idle` (not_applicable): As in forbid, but h displays circular_green alone; the pedestrian steps into the roadway. -/
def idleTrace : Trace := mk [head [.circularGreen]] stepY

/-- `blind` (unknown): As in forbid, but the head's position is not observed (dev.position absent), so whether the pedestrian faces h is unknown. -/
def blindTrace : Trace := Build.masked (Build.manifest ["dev.position"]) forbidTrace

/-- `branch_1` (not_applicable): As in forbid, but a pedestrian signal head d governs the roadway the pedestrian steps onto, faces the pedestrian across the crossing within reach and angle, and shows walk. -/
def branch_1Trace : Trace := mk [head redLeftArrow, pedHead .walk false] stepY

/-- `branch_2` (not_applicable): As in branch_1, but d shows dont_walk_flashing with its countdown attribute. -/
def branch_2Trace : Trace := mk [head redLeftArrow, pedHead .dontWalkFlashing true] stepY

/-- `branch_3` (not_applicable): As in branch_1, but d shows dont_walk_steady: NRS_484B_283_1d4_o1 is engaged for the subject (it steps onto a roadway d governs, facing d, not having overlapped it before), so that rule, not this one, judges the step. -/
def branch_3Trace : Trace := mk [head redLeftArrow, pedHead .dontWalkSteady false] stepY

/-- `branch_4` (compliant): As in forbid, but at the previous observation the pedestrian stood on a median between two roadways (and on no roadway or lane); it steps onto the second roadway: a continuing crossing, no entry. -/
def branch_4Trace : Trace := mk [head redLeftArrow] fun k => if k ≤ 1 then 5 else 7

/-- `branch_5` (violated): As in forbid, but h governs the intersection i itself (control of the
    junction) rather than an approach lane to it. -/
def branch_5Trace : Trace := mk [head redLeftArrow [100]] stepY

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (1000, 3000)) : Scenario :=
  { name := name
    rule := "NRS_484B_307_9c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.position"]
  , witness "branch_1" branch_1Trace .notApplicable (window := some (2000, 2000))
  , witness "branch_2" branch_2Trace .notApplicable (window := some (2000, 2000))
  , witness "branch_3" branch_3Trace .notApplicable (window := some (2000, 2000))
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9c
