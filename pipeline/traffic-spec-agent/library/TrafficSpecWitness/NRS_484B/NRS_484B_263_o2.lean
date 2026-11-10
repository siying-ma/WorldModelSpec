/-
  Witnesses for NRS_484B_263_o2.

  Geometry (metres, +x east, +y north): the controlled-access carriageway `a` (region 10) is the
  rectangle x ∈ [-100, 300], y ∈ [0, 8]; south of it lies a highway region (region 11, x ∈ [-100,
  300], y ∈ [-8, 0]) — the approach road in the entry witnesses, the road `h` x exits onto in
  `branch_2`. Every body is a car (motor vehicle) 4 m long and 2 m wide heading east; x is track 1,
  y track 2. Observations are 1 s apart; occupancy follows the reference point. Each witness is
  judged from its second observation on (`window`): at the first one an exit or an entry
  (`rises`) cannot be told from the unrecorded observation before it.

  Reading values the scenes are built against: critical gap 4 s (y at 25 m/s is a hazard within a
  100 m body gap), conflict horizon 3 s, centre clearance 4 m, speed tolerance 0.2 m/s.

  - forbid: x on the approach road (y = -3) at 10 m/s, y on `a` (y = 3.5) at 25 m/s 41 m then 26 m
    of body gap behind it; at 2 s x is on `a` at (100, 2) with y at (85, 3.5): closest approach in
    1 s at 1.5 m.
  - permit: x waits (0 m/s) at (90, -3) while y passes; at 6 s y is 91 m of body gap ahead (still
    a hazard), at 7 s 116 m (no longer); x enters at 8 s at (92, 2) at 5 m/s with y 143 m ahead and
    pulling away: no approach predicted.
  - idle: y on `a` 116 m then 131 m of body gap ahead of x, then out of the recorded scene; x
    enters at 2 s with no other road user present. A road user still present at the entry would
    leave the run before it reaching back past the recording's start, which the rule reads as
    unknown, so the far vehicle is gone by the entry.
  - blind: forbid with rel.occupies unobserved.
  - branch_1: x alone enters `a`.
  - branch_2: x on `a` (y = 2) at 10 m/s; y on `h` (y = -4.5) at 20 m/s 36 m behind (a hazard),
    then at 5 m/s 26 m behind (not one: 20 m at that speed); x exits onto `h` at (100, -3) with y at
    (85, -4.5) at 25 m/s: closest approach in 1 s at 1.5 m.
  - branch_3: the entry with the hazard earlier in the run but not at its last observation: x waits
    at (90, -3); y on `a` at 20 m/s 46 m behind (a hazard), then slowed to 5 m/s 26 m behind (not
    one); x enters at (92, 2) at 5 m/s as y, at (80, 3.5) at 20 m/s, closes in: approach in 0.8 s
    at 1.5 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

/-- The controlled-access carriageway `a` and the highway region beside it. -/
def carriageway : Structure := Build.rect 10 .controlledAccess (m (-100)) (m 0) (m 300) (m 8)
def sideRoad : Structure := Build.rect 11 .highway (m (-100)) (m (-8)) (m 300) (m 0)
def structures : List Structure := [carriageway, sideRoad]

def car (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos Build.east speed (m 2, m 1, cm 75)

def sceneOf (users : List RoadUser) (t : Timestamp) : Scene :=
  Build.scene t (some 1) users structures []

def forbidUsers : Nat → List RoadUser
  | 0 => [car 1 (m 80, m (-3)) (mps 10), car 2 (m 35, cm 350) (mps 25)]
  | 1 => [car 1 (m 90, m (-3)) (mps 10), car 2 (m 60, cm 350) (mps 25)]
  | _ => [car 1 (m 100, m 2) (mps 10), car 2 (m 85, cm 350) (mps 25)]

/-- `forbid` (violated): x waits on the ramp off a while y on a, 20 m away at 25 m/s, is an immediate hazard; x then enters a while y is still in predicted conflict (1.5 m in 1 s). -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOf (forbidUsers k) t

def permitUsers (k : Nat) : List RoadUser :=
  let y := car 2 (m (35 + 25 * (k : Int)), cm 350) (mps 25)
  if k < 8 then [car 1 (m 90, m (-3)) (mps 0), y] else [car 1 (m 92, m 2) (mps 5), y]

/-- `permit` (compliant): Same hazard while x waits; x enters only after y has passed and no conflict with y is predicted. -/
def permitTrace : Trace :=
  Build.trace 9 0 (Units.seconds 1) fun k t => sceneOf (permitUsers k) t

def idleUsers : Nat → List RoadUser
  | 0 => [car 1 (m 80, m (-3)) (mps 10), car 2 (m 200, cm 350) (mps 25)]
  | 1 => [car 1 (m 90, m (-3)) (mps 10), car 2 (m 225, cm 350) (mps 25)]
  | _ => [car 1 (m 100, m 2) (mps 10)]

/-- `idle` (not_applicable): x enters a with no vehicle on a ever within speed times the critical gap during its approach. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOf (idleUsers k) t

/-- `blind` (unknown): As forbid, but rel.occupies is not observed: whether x entered or exited the controlled-access region, and whether y was on the highway being entered, are unknown, so whether the duty arose is unknown while the predicted conflict is still decided. -/
def blindTrace : Trace :=
  Build.masked (Build.manifest ["rel.occupies"]) forbidTrace

def aloneUsers : Nat → List RoadUser
  | 0 => [car 1 (m 80, m (-3)) (mps 10)]
  | 1 => [car 1 (m 90, m (-3)) (mps 10)]
  | _ => [car 1 (m 100, m 2) (mps 10)]

/-- `branch_1` (not_applicable): x enters a with no other road user in the scene: no hazard arose, so no continued yield is owed. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOf (aloneUsers k) t

def exitUsers : Nat → List RoadUser
  | 0 => [car 1 (m 80, m 2) (mps 10), car 2 (m 40, cm (-450)) (mps 20)]
  | 1 => [car 1 (m 90, m 2) (mps 10), car 2 (m 60, cm (-450)) (mps 5)]
  | _ => [car 1 (m 100, m (-3)) (mps 10), car 2 (m 85, cm (-450)) (mps 25)]

/-- `branch_2` (violated): The exit limb: x travels on a while y, moving on the highway region h beside a, is within its speed times the critical gap of x; x exits a onto h while y is in predicted conflict with it. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOf (exitUsers k) t

def queueUsers : Nat → List RoadUser
  | 0 => [car 1 (m 90, m (-3)) (mps 0), car 2 (m 40, cm 350) (mps 20)]
  | 1 => [car 1 (m 90, m (-3)) (mps 0), car 2 (m 60, cm 350) (mps 5)]
  | _ => [car 1 (m 92, m 2) (mps 5), car 2 (m 80, cm 350) (mps 20)]

/-- `branch_3` (violated): y on a is an immediate hazard while x waits, then slows so that it is
    not one at the last observation before the entry; x enters while y, speeding up again, is in
    predicted conflict: the run before the entry, not only its last observation, decides. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOf (queueUsers k) t

def witness (name : String) (τ : Trace) (expected : Verdict) (last : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_263_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, last)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 2000
  , witness "permit" permitTrace .compliant 8000
  , witness "idle" idleTrace .notApplicable 2000
  , witness "blind" blindTrace (.unknown []) 2000 ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable 2000
  , witness "branch_2" branch_2Trace .violated 2000
  , witness "branch_3" branch_3Trace .violated 2000 ]

end TrafficSpecWitness.NRS_484B_263_o2
