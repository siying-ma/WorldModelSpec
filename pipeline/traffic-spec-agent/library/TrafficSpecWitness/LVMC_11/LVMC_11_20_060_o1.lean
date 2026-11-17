/-
  Witnesses for LVMC_11_20_060_o1.

  Geometry (the witness's own figures, nowhere in the rule):
    * sidewalk region 10: the strip x ∈ [-50, 50] m, y ∈ [0, 3] m, running east–west;
    * driveway region 20 (kind driveway_or_alley_entrance; kind alley in `branch_2`): the
      rectangle x ∈ [-3, 3] m, y ∈ [3, 40] m, meeting the sidewalk's north edge;
    * subject 1: a motor vehicle (a member of DEF-NRS-484A-320::vehicle), heading south down the
      driveway at x = 0, half-length 2 m, half-width 1 m. With its centre at y = c its front is at
      c − 2, so its ground distance to the sidewalk is c − 5 for c > 5, and it is on the sidewalk
      for c < 5. Occupancy is stated: always the driveway; the sidewalk from the entry on.
  Instants are 1 s apart from t = 0. Against the run's reading (stop zone 2.0 m, halt 0.1 m/s):
  c = 6 m is 1 m from the sidewalk (in the zone), c = 8 m is 3 m (upstream, outside the zone),
  c = 4 m is the entry; moving speeds are 2 m/s (or 0.5 m/s), a halt is 0 m/s.
  Each witness speaks about the instants from t = 1 s on (`window`), past the first observation,
  at which no rise of occupancy can be judged.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_20_060_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_20_060_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def sidewalk : Structure := Build.rect 10 .sidewalk (m (-50)) (m 0) (m 50) (m 3)
def access (k : StructureKind) : Structure := Build.rect 20 k (m (-3)) (m 3) (m 3) (m 40)

/-- One observation: the subject's centre y, its speed, whether its body is on the sidewalk. -/
structure Step where
  y : Q
  v : Q
  onWalk : Bool

def subjectAt (st : Step) : RoadUser :=
  Build.user 1 [.motorVehicle] (Q.zero, st.y) Build.south st.v (m 2, m 1, cm 75)

def sceneAt (k : StructureKind) (district : Bool) (t : Timestamp) (st : Step) : Scene :=
  Build.scene t (some 1)
    [ subjectAt st ]
    [ sidewalk, access k ]
    [ ]
    (occupies := some (if st.onWalk then [(1, 10), (1, 20)] else [(1, 20)]))
    (assumptions := [("asm.business_or_residence_district", district)])

def mk (k : StructureKind) (district : Bool) (steps : List Step) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun i t =>
    sceneAt k district t (steps.getD i { y := m 20, v := mps 2, onWalk := false })

/-- Approach from 3 m out (upstream), 1 m out (zone), entry; never halted. -/
def rollingSteps : List Step :=
  [ { y := m 12, v := mps 2, onWalk := false }
  , { y := m 10, v := mps 2, onWalk := false }
  , { y := m 8,  v := mps 2, onWalk := false }
  , { y := m 6,  v := mps 2, onWalk := false }
  , { y := m 4,  v := mps 2, onWalk := true } ]

/-- `forbid` (violated): District assumed; the subject leaves a driveway and rolls onto the sidewalk at walking pace without its speed ever falling to the halt tolerance in the stop zone, having approached from beyond the zone. -/
def forbidTrace : Trace := mk .drivewayOrAlleyEntrance true rollingSteps

/-- `permit` (compliant): Same, but the subject halts within p.stop_point_tolerance of the sidewalk edge before driving onto it. -/
def permitTrace : Trace :=
  mk .drivewayOrAlleyEntrance true
    [ { y := m 12, v := mps 3, onWalk := false }
    , { y := m 9,  v := mps 3, onWalk := false }
    , { y := m 6,  v := Q.zero, onWalk := false }
    , { y := m 6,  v := Q.zero, onWalk := false }
    , { y := m 4,  v := mps 2, onWalk := true } ]

/-- `idle` (not_applicable): The trace declares the area outside any business or residence district. -/
def idleTrace : Trace := mk .drivewayOrAlleyEntrance false rollingSteps

/-- `blind` (unknown): District assumed; the subject's speed is not observed in the stop zone; it then drives onto the sidewalk. -/
def blindTrace : Trace := mk .drivewayOrAlleyEntrance true rollingSteps

/-- `branch_1` (violated): The subject halts far up the driveway, outside the stop zone, then rolls through the zone onto the sidewalk without halting again. -/
def branch_1Trace : Trace :=
  mk .drivewayOrAlleyEntrance true
    [ { y := m 14, v := mps 2, onWalk := false }
    , { y := m 14, v := Q.zero, onWalk := false }
    , { y := m 10, v := mps 2, onWalk := false }
    , { y := m 6,  v := mps 2, onWalk := false }
    , { y := m 4,  v := mps 2, onWalk := true } ]

/-- `branch_2` (violated): as `forbid`, but the subject emerges from an alley (region of kind
    alley): the alley limb of e3 engages the duty, and the unhalted entry violates it. -/
def branch_2Trace : Trace := mk .alley true rollingSteps

/-- `history_boundary` (unknown): The recording begins with the subject already in the stop zone, moving slowly; no halt is recorded before it drives onto the sidewalk, and the run reaches the start of the recording. -/
def history_boundaryTrace : Trace :=
  mk .drivewayOrAlleyEntrance true
    [ { y := cm 650, v := cm 50, onWalk := false }
    , { y := m 6,    v := cm 50, onWalk := false }
    , { y := cm 550, v := cm 50, onWalk := false }
    , { y := cm 450, v := cm 50, onWalk := true } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (1000, 4000)) : Scenario :=
  { name := name
    rule := "LVMC_11_20_060_o1"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start: the last observation at which the subject was outside the stop zone upstream, which precedes the recording") (window := some (1000, 3000)) ]

end TrafficSpecWitness.LVMC_11_20_060_o1
