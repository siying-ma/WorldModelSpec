/-
  Witnesses for NRS_484B_283_1d2.

  Geometry (x east, y north, metres): a roadway (region 10) from y = 0 to y = 14 along x; a south
  sidewalk (11, y ∈ [−4, 0]) and a north sidewalk (12, y ∈ [14, 18]); a marked crosswalk (13,
  x ∈ [−2, 2] across the roadway). The pedestrian (track 1) walks north along x = 0 inside the
  crosswalk. The pedestrian head (device 20) stands on the far (north) side at (0, 19) and governs
  the roadway; from the entry point (0, 1) it lies 18 m dead ahead (within the 40 m reach and the
  ≈30° cone of the reading). Observations every second. The head shows dont_walk_flashing with
  countdown, then dont_walk_steady (countdown gone); during walk no countdown is shown.

  Branches: a lane-only street (branch_1); the subject facing away (branch_2), 45° off the head
  (branch_3), the head 59 m away (branch_4); the head governing another roadway (branch_5).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1d2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1d2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def W : PedSignalState := .walk
def F : PedSignalState := .dontWalkFlashing
def S : PedSignalState := .dontWalkSteady

def hasCountdown : PedSignalState → Bool
  | .dontWalkFlashing => true
  | _ => false

def ped (y : Q) (h : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.pedestrian] (m 0, y) h speed (cm 30, cm 30, cm 90)

def crosswalk (id : RegionId) (y0 y1 : Q) : Structure :=
  { Build.rect id .crosswalk (m (-2)) y0 (m 2) y1 with marked := some true }

/-- The two-way street: roadway, two sidewalks, the marked crosswalk. -/
def street : List Structure :=
  [ Build.rect 10 .roadway (m (-50)) (m 0) (m 50) (m 14)
  , Build.rect 11 .sidewalk (m (-50)) (m (-4)) (m 50) (m 0)
  , Build.rect 12 .sidewalk (m (-50)) (m 14) (m 50) (m 18)
  , crosswalk 13 (m 0) (m 14) ]

def head (gov : List RegionId) (pos : Vec) (st : PedSignalState) : Device :=
  { Build.device 20 .pedestrianSignal gov (some pos) with
      pedState := some st, countdown := some (hasCountdown st), inoperative := some false }

/-- A crossing: the pedestrian's y and the head's state per second. -/
def crossing (ys : List Q) (sts : List PedSignalState) (h : Vec := Build.north) (speed : Q := m 1)
    (structs : List Structure := street) (gov : List RegionId := [10]) (hpos : Vec := (m 0, m 19)) : Trace :=
  Build.trace ys.length 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ ped (ys.getD k (m 0)) h speed ]
      structs
      [ head gov hpos (sts.getD k .dark) ]

/-- `forbid` (violated): The head governing roadway r shows dont_walk_flashing with countdown; the pedestrian steps onto r facing it, walks slowly, and is still on r when the head turns dont_walk_steady. -/
def forbidTrace : Trace := crossing [m (-1), m 1, m 2, m 3, m 4] [F, F, F, F, S]

/-- `permit` (compliant): The pedestrian steps onto r during the flashing countdown and is on the far sidewalk, off r, when the head turns dont_walk_steady. -/
def permitTrace : Trace :=
  crossing [m (-1), m 1, m 3, m 5, m 7, m 9, m 11, m 13, m 15] [F, F, F, F, F, F, F, F, S] (speed := m 2)

/-- `idle` (not_applicable): The pedestrian entered r while the head showed walk; at the countdown's end it is still on r (the steady-indication duty governs it, not this one). -/
def idleTrace : Trace := crossing [m (-1), m 1, m 2, m 3, m 4] [W, W, F, F, S]

/-- `blind` (unknown): The pedestrian steps onto r and is on it later, but the head's state is not observed, so neither the countdown interval nor its end can be told. -/
def blindTrace : Trace := crossing [m (-1), m 1, m 2, m 3, m 4] [F, F, F, F, S]

/-- `history_boundary` (unknown): The recording begins with the pedestrian already on r while the head shows dont_walk_flashing with countdown; the head turns dont_walk_steady while it is still on r; its entry onto r is not recorded. -/
def history_boundaryTrace : Trace := crossing [m 2, m 3, m 4] [F, F, S]

/-- A one-lane street (lane 30, y ∈ [0, 4]) with no roadway region; head at (0, 9). -/
def laneStreet : List Structure :=
  [ Build.lane 30 [(m (-50), m 0), (m 50, m 0), (m 50, m 4), (m (-50), m 4)] Build.east
  , Build.rect 11 .sidewalk (m (-50)) (m (-4)) (m 50) (m 0)
  , Build.rect 12 .sidewalk (m (-50)) (m 4) (m 50) (m 8)
  , crosswalk 13 (m 0) (m 4) ]

/-- `branch_1` (violated): the head governs a lane; the pedestrian steps onto it facing the head
    under the flashing countdown and is still on it when the head turns steady. -/
def branch1Trace : Trace :=
  crossing [m (-1), m 1, m 2, m 3] [F, F, F, S] (structs := laneStreet) (gov := [30]) (hpos := (m 0, m 9))

/-- `branch_2` (not_applicable): the pedestrian backs onto the roadway, heading south, away from
    the head; it is on the roadway when the head turns steady. -/
def branch2Trace : Trace := crossing [m (-1), m 1, m 2, m 3, m 4] [F, F, F, F, S] (h := Build.south)

/-- `branch_3` (not_applicable): the pedestrian's heading points north-east, 45° off the head. -/
def branch3Trace : Trace := crossing [m (-1), m 1, m 2, m 3, m 4] [F, F, F, F, S] (h := (m 1, m 1))

/-- `branch_4` (not_applicable): the head stands 59 m beyond the entry point, out of reach. -/
def branch4Trace : Trace := crossing [m (-1), m 1, m 2, m 3, m 4] [F, F, F, F, S] (hpos := (m 0, m 60))

/-- A second roadway (15, y ∈ [30, 44]) north of the street. -/
def twoStreets : List Structure := street ++ [Build.rect 15 .roadway (m (-50)) (m 30) (m 50) (m 44)]

/-- `branch_5` (not_applicable): the head governs the other roadway, not the one crossed. -/
def branch5Trace : Trace :=
  crossing [m (-1), m 1, m 2, m 3, m 4] [W, F, F, F, S] (structs := twoStreets) (gov := [15])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_283_1d2"
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
  , witness "blind" blindTrace (.unknown []) ["dev.pedestrian_signal"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the pedestrian's entry onto r, which lies before the recording")
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .notApplicable
  , witness "branch_4" branch4Trace .notApplicable
  , witness "branch_5" branch5Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_283_1d2
