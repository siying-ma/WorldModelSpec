/-
  Witnesses for NRS_484B_263_o2.

  The carriageway: the controlled-access mainline `a` (region 10) is the strip 0 ≤ y ≤ 8 m, traffic
  eastbound; the approach / exit road `h` (region 20, a highway, not controlled-access) is the
  strip −8 ≤ y < 0 m beside it. Every body is a car 4 m × 2 m heading east; occupancy follows the
  reference points. Scenes are 1 s apart; each witness judges the instants from the second scene
  on (`window`), since the hazard search looks back to the start of x's run on the near side.

  Against the reading (critical gap 4 s, horizon 3 s, clearance 4 m, motion tolerance 0.2 m/s):
  - the hazards have body gaps of about 21–66 m against speed × gap of 60–100 m;
  - the conflicts are closest approaches at 1–2 s and 0–1.5 m;
  - the idle vehicle stays about 290 m or more away; the permit vehicle has passed and draws away.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- A car heading east at `(px, py)` with speed `v`. -/
def car (id : TrackId) (px py : Q) (v : Q) : RoadUser :=
  Build.user id [.motorVehicle] (px, py) Build.east v carExtent

/-- The controlled-access mainline `a`. -/
def mainline : Structure := Build.rect 10 .controlledAccess (m (-400)) (m 0) (m 600) (m 8)
/-- The approach / exit road `h`, a highway region beside it. -/
def sideRoad : Structure := Build.rect 20 .highway (m (-400)) (m (-8)) (m 600) (m 0)

def sceneOf (t : Timestamp) (us : List RoadUser) : Scene :=
  Build.scene t (some 1) us [mainline, sideRoad] []

/-- `forbid` (violated): x waits on the ramp off a while y on a, 20 m away at 25 m/s, is an immediate hazard; x then enters a while y is still in predicted conflict (1.5 m in 1 s). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero, car 2 (m (-70)) (m 4) (mps 25)]
    | 1 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero, car 2 (m (-45)) (m 4) (mps 25)]
    | _ => sceneOf t [car 1 (m 0) (cm 250) (mps 5), car 2 (m (-20)) (m 4) (mps 25)]

/-- `permit` (compliant): Same hazard while x waits; x enters only after y has passed and no conflict with y is predicted. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero, car 2 (m (-45)) (m 4) (mps 25)]
    | 1 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero, car 2 (m (-20)) (m 4) (mps 25)]
    | _ => sceneOf t [car 1 (m 0) (cm 250) (mps 5), car 2 (m 30) (m 4) (mps 25)]

/-- `idle` (not_applicable): x enters a with no vehicle on a ever within speed times the critical gap during its approach.
    x is first seen on a, drops onto h for two observations and re-enters a; y stays ≥ 290 m ahead.
    The judged instants start at x's second observation on h, after the exit. -/
def idleTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [car 1 (m 0) (cm 250) (mps 10), car 2 (m 300) (m 4) (mps 25)]
    | 1 => sceneOf t [car 1 (m 10) (m (-4)) (mps 10), car 2 (m 325) (m 4) (mps 25)]
    | 2 => sceneOf t [car 1 (m 20) (m (-4)) (mps 10), car 2 (m 350) (m 4) (mps 25)]
    | _ => sceneOf t [car 1 (m 30) (cm 250) (mps 10), car 2 (m 375) (m 4) (mps 25)]

/-- `blind` (unknown): As forbid, but rel.surface_gap is not observed, so whether y was an immediate hazard is unknown.
    NOT REACHABLE (see task_result.md): masking rel.surface_gap drops only a measured gap; Core
    computes the gap from the footprints that admission requires of every track whose occupancy is
    observed, and the rule reads the occupancy of both x and y. The trace is forbid's. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): x enters a with no other road user in the scene: no hazard arose, so no continued yield is owed. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero]
    | 1 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero]
    | _ => sceneOf t [car 1 (m 0) (cm 250) (mps 5)]

/-- `branch_2` (violated): the exit limb. x travels on a while y on h, 15 m/s and about 21 m from
    x, is an immediate hazard; x exits onto h with y predicted to close to 0 m in 2 s. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [car 1 (m 0) (m 2) (mps 10), car 2 (m (-30)) (m (-3)) (mps 15)]
    | 1 => sceneOf t [car 1 (m 10) (m 2) (mps 10), car 2 (m (-15)) (m (-3)) (mps 15)]
    | _ => sceneOf t [car 1 (m 20) (m (-3)) (mps 10), car 2 (m 10) (m (-3)) (mps 15)]

/-- `branch_3` (compliant): as forbid, but at the entry x's body is on a at a crawl below the
    speed resolution (0.1 m/s), read as standing: x does not proceed, so the yield is kept. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    match k with
    | 0 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero, car 2 (m (-70)) (m 4) (mps 25)]
    | 1 => sceneOf t [car 1 (m 0) (m (-4)) Q.zero, car 2 (m (-45)) (m 4) (mps 25)]
    | _ => sceneOf t [car 1 (m 0) (cm 250) (Units.micrometresPerSecond 100000), car 2 (m (-20)) (m 4) (mps 25)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (1000, 2000)) : Scenario :=
  { name := name
    rule := "NRS_484B_263_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable (window := some (2000, 3000))
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant ]

end TrafficSpecWitness.NRS_484B_263_o2
