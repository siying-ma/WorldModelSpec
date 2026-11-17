/-
  Witnesses for NRS_484B_283_1d3_o2.

  Geometry (the witness's own figures, nowhere in the rule): a roadway (or, in `branch_1`, a lane)
  r = region 10, the rectangle x ∈ [0, 20] m, y ∈ [0, 10] m; a south sidewalk (region 20,
  y ∈ [−4, 0]) and a north sidewalk (region 21, y ∈ [10, 14]). A pedestrian head d (device 1) at
  (10, 15) governs r and never displays a countdown. The pedestrian (track 1, half-extent
  0.3 × 0.3 × 0.9 m) walks north along x = 10 at one observation per second, so the head lies dead
  ahead (cosine 1 against 0.87) at most 17 m away (against 40 m): it faces d throughout. r's
  direction of travel is east, so the crossing is square to it, and a marked crosswalk (region 30,
  x ∈ [8, 12] m) spans r along the pedestrian's path: the exception rules read both.

  forbid: steps onto r at t = 1 s under walk; flashing at 2–3 s; steady at 4 s while at y = 7 m.
  permit: steps onto r at t = 1 s under walk; flashing at 2–4 s, reaching the north sidewalk at
          4 s; steady at 5 s with the pedestrian at y = 12.5 m, off r.
  idle:   steps onto r at t = 1 s while d already shows flashing; steady at 3 s.
  blind:  forbid, with the head's indications masked.
  history_boundary: the recording opens with the pedestrian at y = 3 m on r under flashing;
          steady at 2 s while still on r.
  branch_1: forbid, with r a lane instead of a roadway (the lane disjunct of the selection).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_283_1d3_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_283_1d3_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def W : PedSignalState := .walk
def F : PedSignalState := .dontWalkFlashing
def S : PedSignalState := .dontWalkSteady

/-- The crossing: the pedestrian's northing (cm) and the head's state per observation. -/
def crossing (kind : StructureKind) (ys : List Int) (states : List PedSignalState) : Trace :=
  Build.trace ys.length 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (m 10, cm (ys.getD k 0)) Build.north (Units.metresPerSecond 1)
          (cm 30, cm 30, cm 90) ]
      [ { Build.rect 10 kind (m 0) (m 0) (m 20) (m 10) with
          lane := some { direction := some Build.east } }
      , { Build.rect 30 .crosswalk (m 8) (m 0) (m 12) (m 10) with marked := some true }
      , Build.rect 20 .sidewalk (m 0) (m (-4)) (m 20) (m 0)
      , Build.rect 21 .sidewalk (m 0) (m 10) (m 20) (m 14) ]
      [ { Build.device 1 .pedestrianSignal [10] (some (m 10, m 15)) with
          pedState := some (states.getD k .dark), countdown := some false } ]

/-- `forbid` (violated): The pedestrian steps from the sidewalk onto r facing d while d shows walk; d turns dont_walk_flashing without countdown while it is mid-crossing, then dont_walk_steady while it is still on r. -/
def forbidTrace : Trace :=
  crossing .roadway [-200, 100, 300, 500, 700, 900] [W, W, F, F, S, S]

/-- `permit` (compliant): Same, but the pedestrian reaches the far sidewalk, off r, before d turns steady. -/
def permitTrace : Trace :=
  crossing .roadway [-200, 200, 500, 800, 1150, 1250] [W, W, F, F, F, S]

/-- `idle` (not_applicable): The pedestrian stepped onto r while d already showed dont_walk_flashing without countdown (no lawful entry under subparagraph (1)). -/
def idleTrace : Trace :=
  crossing .roadway [-200, 100, 300, 500, 700] [F, F, F, S, S]

/-- `blind` (unknown): Same as forbid but d's state is not observed. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["dev.pedestrian_signal"]) forbidTrace

/-- `history_boundary` (unknown): The recording begins with the pedestrian already on r while d shows dont_walk_flashing without countdown; d turns steady while it is still on r; its step onto r is not recorded. -/
def history_boundaryTrace : Trace :=
  crossing .roadway [300, 500, 700, 900] [F, F, S, S]

/-- `branch_1` (violated): forbid on a lane rather than a roadway — the lane limb of the selection. -/
def branch_1Trace : Trace :=
  crossing .lane [-200, 100, 300, 500, 700, 900] [W, W, F, F, S, S]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_283_1d3_o2"
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
  , witness "blind" blindTrace (.unknown []) ["dev.pedestrian_signal"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the pedestrian's step from the sidewalk onto r, which lies before the recording")
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_283_1d3_o2
