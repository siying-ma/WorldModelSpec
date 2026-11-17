/-
  Witnesses for NRS_484B_307_9c.

  Geometry (the witness's own figures; none appears in the rule):
  - near sidewalk `10`: x ∈ [-20, 20], y ∈ [-5, 0]; roadway `11`: x ∈ [-20, 20], y ∈ [0, 12];
    far sidewalk `12`: x ∈ [-20, 20], y ∈ [12, 17]; crosswalk `13`: x ∈ [-3, 3], y ∈ [0, 12].
  - the pedestrian (track 1) heads north at x = 0: at y = -2 (on the sidewalk) at t = 0 s and
    1 s, at y = 2 (on the roadway, in the crosswalk) from t = 2 s (forbid, idle, blind, branch_1);
    in permit it stays at y = -2.
  - the vehicular signal head `100` stands at (0, 16), straight ahead of the pedestrian, 18 m away
    (well within a 60 m reach; cosine 1 against a 0.87 bound).
  - branch_1 adds a pedestrian signal `101` at (0, 13) on the far curb, across the crosswalk,
    governing the crosswalk and showing walk.
  - instants 0, 1, 2, 3 s; the rule's `rises` needs the observation before, so every witness
    speaks about t ∈ [1 s, 3 s].
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def crosswalk : Structure :=
  let c : Structure := Build.rect 13 .crosswalk (m (-3)) (m 0) (m 3) (m 12)
  { c with marked := some true }

def structures : List Structure :=
  [ Build.rect 10 .sidewalk (m (-20)) (m (-5)) (m 20) (m 0)
  , Build.rect 11 .roadway (m (-20)) (m 0) (m 20) (m 12)
  , Build.rect 12 .sidewalk (m (-20)) (m 12) (m 20) (m 17)
  , crosswalk ]

/-- The pedestrian at instant `k`; `steps` says whether it steps into the roadway at k ≥ 2. -/
def ped (steps : Bool) (k : Nat) : RoadUser :=
  let y := if steps && k ≥ 2 then m 2 else m (-2)
  Build.user 1 [.pedestrian] (m 0, y) Build.north (if steps then m 1 else m 0) (cm 30, cm 30, cm 90)

def head (inds : List SignalIndication) : Device :=
  let d : Device := Build.signal 100 [11] inds
  { d with position := some (m 0, m 16), uncovered := some true, inoperative := some false }

def redArrow : List SignalIndication := [.circularRed, .greenArrow .left]

def pedSignal : Device :=
  let d : Device := Build.device 101 .pedestrianSignal [13] (some (m 0, m 13))
  { d with pedState := some .walk, countdown := some false, inoperative := some false }

def mkTrace (steps : Bool) (devices : List Device) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ped steps k] structures devices

/-- `forbid` (violated): A pedestrian stands on the sidewalk facing, within reach and within the facing angle, a head displaying circular_red with green_arrow(left); no pedestrian signal is present. The pedestrian steps into the roadway: its footprint comes to overlap a st.roadway region. -/
def forbidTrace : Trace := mkTrace true [head redArrow]

/-- `permit` (compliant): As in forbid, but the pedestrian remains on the sidewalk while the head displays the red with the arrow. -/
def permitTrace : Trace := mkTrace false [head redArrow]

/-- `idle` (not_applicable): The head the pedestrian faces displays circular_green alone; it steps into the roadway. -/
def idleTrace : Trace := mkTrace true [head [.circularGreen]]

/-- `blind` (unknown): As in forbid, but the head's position is not observed (dev.position absent), so whether the pedestrian faces it is unknown. -/
def blindTrace : Trace := mkTrace true [head redArrow]

/-- `branch_1` (not_applicable): As in forbid, but a pedestrian signal across the crossing the pedestrian faces displays walk: NRS_484B_283_1d1 is engaged, so the exception holds. -/
def branch_1Trace : Trace := mkTrace true [head redArrow, pedSignal]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9c"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 3000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.position"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_9c
