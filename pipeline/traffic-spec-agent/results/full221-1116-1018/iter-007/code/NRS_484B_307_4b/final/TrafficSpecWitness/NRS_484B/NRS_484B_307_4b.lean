/-
  Witnesses for NRS_484B_307_4b.

  Geometry (+x east, +y north, metres; every figure here is the witness's own):
    * highway A (10): x ∈ [−100, 100], y ∈ [−12, 12]; its roadway (20): y ∈ [−7, 7].
    * highway B (11): x ∈ [−12, 12], y ∈ [−100, 100]; its roadway (21): x ∈ [−7, 7].
    * intersection (30): x, y ∈ [−7, 7], on both A and B.
    * westbound approach lane (40) of A east of the junction: x ∈ [7, 100], y ∈ [0, 7], entering 30.
    * east-leg crosswalk (50): x ∈ [7, 11], y ∈ [−7, 7]; NE sidewalk (60): x ∈ [7, 40], y ∈ [7, 12].
    * highway C (12): x ∈ [13, 100], y ∈ [20, 33], not meeting at 30; its roadway (22): y ∈ [22, 28],
      its sidewalk (61): y ∈ [28, 33].
    * vehicular head (100) at (12, −16), governing lane 40 (branch_3: the intersection 30).
    * pedestrian head (101) at (11, −10) (branch_1: (10, −8)), governing roadway 20 (the adapter
      refuses a device governing a crosswalk).
    * the pedestrian (track 1) heads south; from (9, 9) on the sidewalk, 25.2 m from the head at
      about 7° off its heading (reading: 60 m, cos 0.87), it steps at t = 2 s to (9, 5) on roadway
      20. branch_2: from (20, 31) (47.7 m, about 10° off) to (20, 25) on roadway 22.
  Four instants 1 s apart; the window [1 s, 3 s] leaves out the first instant, at which the
  previous observation the rule reads does not exist.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_4b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_4b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def withWays (st : Structure) (ws : List RegionId) : Structure := { st with ways := some ws }

def structures : List Structure :=
  [ Build.rect 10 .highway (m (-100)) (m (-12)) (m 100) (m 12)
  , Build.rect 11 .highway (m (-12)) (m (-100)) (m 12) (m 100)
  , Build.rect 12 .highway (m 13) (m 20) (m 100) (m 33)
  , withWays (Build.rect 20 .roadway (m (-100)) (m (-7)) (m 100) (m 7)) [10]
  , withWays (Build.rect 21 .roadway (m (-7)) (m (-100)) (m 7) (m 100)) [11]
  , withWays (Build.rect 22 .roadway (m 13) (m 22) (m 100) (m 28)) [12]
  , withWays (Build.rect 30 .intersection (m (-7)) (m (-7)) (m 7) (m 7)) [10, 11]
  , withWays (Build.lane 40 [(m 7, m 0), (m 100, m 0), (m 100, m 7), (m 7, m 7)] Build.west
      (enters := some 30)) [10]
  , withWays (Build.rect 50 .crosswalk (m 7) (m (-7)) (m 11) (m 7)) [10]
  , withWays (Build.rect 60 .sidewalk (m 7) (m 7) (m 40) (m 12)) [10]
  , withWays (Build.rect 61 .sidewalk (m 13) (m 28) (m 100) (m 33)) [12] ]

def head (governs : List RegionId) (shows : List SignalIndication) : Device :=
  { Build.signal 100 governs shows with
      position := some (m 12, m (-16)), uncovered := some true, inoperative := some false }

def pedHead (st : PedSignalState) (pos : Vec := (m 11, m (-10))) (governs : List RegionId := [20]) : Device :=
  { Build.device 101 .pedestrianSignal governs (some pos) with
      pedState := some st, countdown := some false, inoperative := some false }

def pedestrian (pos : Vec) (moving : Bool) : RoadUser :=
  Build.user 1 [.pedestrian] pos Build.south
    (if moving then Units.metresPerSecond 1 else Units.metresPerSecond 0) (cm 30, cm 30, cm 90)

/-- A scene generator: the pedestrian at `before` for k ≤ 1 and at `after` from k = 2. -/
def sceneGen (governs : List RegionId) (shows : List SignalIndication) (ped : PedSignalState)
    (before after : Vec) (pedAt : Vec := (m 11, m (-10))) (pedGoverns : List RegionId := [20])
    (pedFirst : Option PedSignalState := none) (moving : Bool := false)
    (xs : List Structure := structures) :
    Nat → Timestamp → Scene :=
  fun k t =>
    Build.scene t (some 1)
      [ pedestrian (if k ≤ 1 then before else after) (k == 1 || (moving && k ≥ 1)) ]
      xs
      [ head governs shows,
        pedHead (if k == 0 then pedFirst.getD ped else ped) pedAt pedGoverns ]

def mk (g : Nat → Timestamp → Scene) : Trace := Build.trace 4 0 (Units.seconds 1) g

def corner : Vec := (m 9, m 9)
def onRoadA : Vec := (m 9, m 5)

/-- `forbid` (violated): A pedestrian stands on the corner sidewalk of a highway that meets another at a signalized intersection, 25 m from a vehicular head it faces (heading within 10 degrees of the line to the head) that governs a lane entering the intersection and displays green_arrow(left) alone; the pedestrian head it faces displays dont_walk_steady. At the next observation its footprint overlaps the roadway of a highway on which the intersection lies. -/
def forbidTrace : Trace :=
  mk (sceneGen [40] [.greenArrow .left] .dontWalkSteady corner onRoadA)

/-- `permit` (compliant): Same scene; the pedestrian stays on the sidewalk while the head displays green_arrow(left) alone; its footprint never overlaps the roadway. -/
def permitTrace : Trace :=
  mk (sceneGen [40] [.greenArrow .left] .dontWalkSteady corner corner)

/-- `idle` (not_applicable): The head the pedestrian faces displays circular_green alone; it steps onto the roadway. -/
def idleTrace : Trace :=
  mk (sceneGen [40] [.circularGreen] .dontWalkSteady corner onRoadA)

/-- `blind` (unknown): As forbid, but the source supplies no heading for the pedestrian: whether it faces the head is unknown. -/
def blindTrace : Trace :=
  mk (sceneGen [40] [.greenArrow .left] .dontWalkSteady corner onRoadA)

/-- `branch_1` (not_applicable): As forbid, but the pedestrian head it faces displays walk: NRS_484B_283_1d1 applies to it and the duty of this paragraph does not. -/
def branch_1Trace : Trace :=
  mk (sceneGen [40] [.greenArrow .left] .walk corner onRoadA (pedAt := (m 10, m (-8))))


/-- `branch_2` (compliant): As forbid, but the roadway the pedestrian steps onto lies on a way that does not meet at the intersection the head controls (no st.on_way to any highway on which that intersection lies); it never overlaps a roadway of the highway at the signal. -/
def branch_2Trace : Trace :=
  mk (sceneGen [40] [.greenArrow .left] .dontWalkSteady (m 20, m 31) (m 20, m 25))

/-- `branch_3` (violated): As forbid, but the head governs the intersection itself (dev.governs on the intersection) rather than an approach lane; the pedestrian steps onto the roadway of a highway on which that intersection lies. -/
def branch_3Trace : Trace :=
  mk (sceneGen [30] [.greenArrow .left] .dontWalkSteady corner onRoadA)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_4b"
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
  , witness "blind" blindTrace (.unknown []) ["kin.heading"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_4b
