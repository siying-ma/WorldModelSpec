/-
  Witnesses for NRS_484B_250_4_o2.

  The map (static in every scene): intersection X (region 10) the square [-10, 10]²; lane c
  (region 11) northbound, x ∈ [0, 5], y ∈ [-40, -10], an approach entering X; lane c2 (region 12)
  westbound, x ∈ [10, 60], y ∈ [0, 5], an approach entering X from the subject's right; stop line
  (region 13) across c, y ∈ [-11.5, -10], marking c's entrance. Signal head 20 governs c (in
  branch_5, X), installed and uncovered; inoperative (dark) except in `idle` (circular green).

  Bodies: half-length 2.4 m, half-width 1 m. Occupancy is the footprints' overlap with the
  regions. The subject (track 1) starts upstream of c (y = -46, on no region), runs up c, and at
  rest at y = -13 its front overlaps the stop line, not X (instants k2, k3); it enters X at k4
  (centre y = -6 or, at rest just inside, y = -7.5). The other vehicle (track 2) starts east of c2
  (x = 75, on no region). Instants are 1 s apart from t = 20 s; each trace is padded 10 s before
  (the first scene repeated, nobody on c or c2) and 5 s after.

  Conflict figures (reading: horizon 3 s, clearance 3 m, halt tolerance 0.1 m/s):
  - forbid/blind/branch_3/branch_5 at k4: subject (2.5, -6) north 4 m/s, v (7.5, 2.5) in X west
    3 m/s: closest approach after ≈ 1.96 s at ≈ 1.1 m between centres.
  - branch_2/branch_4 at k4: subject (2, -6.5) heading (0.8, 0.6) at 6 m/s, v at rest at
    (14, 2.5) on c2: the centres meet after 2.5 s (distance 0).
  - permit: the subject at rest (speed 0) while v crosses; it moves at k8 once v has left X.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def half : Q × Q × Q := (cm 240, m 1, cm 80)
/-- Heading north-east, (0.8, 0.6). -/
def ne : Vec := (Units.ratio 4 5, Units.ratio 3 5)

def intersectionX : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def laneC : Structure :=
  Build.lane 11 [(m 0, m (-40)), (m 5, m (-40)), (m 5, m (-10)), (m 0, m (-10))] Build.north (enters := some 10)
def laneC2 : Structure :=
  Build.lane 12 [(m 10, m 0), (m 60, m 0), (m 60, m 5), (m 10, m 5)] Build.west (enters := some 10)
def stopLineC : Structure :=
  { Build.rect 13 .stopLine (m 0) (cm (-1150)) (m 5) (m (-10)) with entranceOf := [11], entranceObserved := true }
def structures : List Structure := [intersectionX, laneC, laneC2, stopLineC]

def darkSignal : Device :=
  { Build.signal 20 [11] [.dark] with uncovered := some true, inoperative := some true }
def greenSignal : Device :=
  { Build.signal 20 [11] [.circularGreen] with uncovered := some true, inoperative := some false }
def darkSignalOnX : Device :=
  { Build.signal 20 [10] [.dark] with uncovered := some true, inoperative := some true }

def subj (x y : Q) (h : Vec) (v : Q) : RoadUser := Build.user 1 [.motorVehicle] (x, y) h v half
def other (x y : Q) (h : Vec) (v : Q) : RoadUser := Build.user 2 [.motorVehicle] (x, y) h v half

/-- The subject's approach on c with a stop at the stop line (k0 upstream, k1 on c, k2–k3 at rest). -/
def approachStopping (k : Nat) : RoadUser :=
  if k = 0 then subj (cm 250) (m (-46)) Build.north (mps 4)
  else if k = 1 then subj (cm 250) (m (-25)) Build.north (mps 4)
  else subj (cm 250) (m (-13)) Build.north Q.zero

/-- The subject's approach on c without stopping. -/
def approachRolling (k : Nat) : RoadUser :=
  if k = 0 then subj (cm 250) (m (-46)) Build.north (mps 4)
  else if k = 1 then subj (cm 250) (m (-25)) Build.north (mps 4)
  else if k = 2 then subj (cm 250) (m (-18)) Build.north (mps 4)
  else subj (cm 250) (m (-13)) Build.north (mps 4)

/-- In X at k4, moving north into v's path. -/
def subjectInXNorth : RoadUser := subj (cm 250) (m (-6)) Build.north (mps 4)
/-- In X at k4, heading north-east towards the vehicle waiting on c2. -/
def subjectInXNE : RoadUser := subj (m 2) (cm (-650)) ne (mps 6)

/-- v crossing from the subject's right: east of c2, on c2, then in X at k4. -/
def crossing (k : Nat) : RoadUser :=
  let x := if k = 0 then m 75 else if k = 1 then m 40 else if k = 2 then m 25 else if k = 3 then m 15 else cm 750
  other x (cm 250) Build.west (mps 3)

def sceneAt (t : Timestamp) (users : List RoadUser) (sig : Device) : Scene :=
  Build.scene t (some 1) users structures [sig]

def padded (τ : Trace) : Trace := Build.pad τ (Units.seconds 10) (Units.seconds 5) (Units.seconds 1)

/-- The forbid scene with a given signal head. -/
def conflictTrace (sig : Device) : Trace :=
  padded <| Build.trace 5 20000 (Units.seconds 1) fun k t =>
    sceneAt t [if k < 4 then approachStopping k else subjectInXNorth, crossing k] sig

/-- `forbid` (violated): The subject halted at the stop line of c (inoperative dev.traffic_signal governing c) and entered X; vehicle v occupies X crossing from the subject's right; the subject moves on with kin.speed above p.halt_speed_tolerance and its closest approach to v lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace := conflictTrace darkSignal

/-- `permit` (compliant): Same scene; the subject stays at rest just inside X until v has cleared, then proceeds with no closest approach to v below p.conflict_centre_clearance within p.conflict_horizon. -/
def permitTrace : Trace :=
  padded <| Build.trace 11 20000 (Units.seconds 1) fun k t =>
    let s :=
      if k < 4 then approachStopping k
      else if k ≤ 7 then subj (cm 250) (cm (-750)) Build.north Q.zero
      else if k = 8 then subj (cm 250) (cm (-750)) Build.north (mps 3)
      else if k = 9 then subj (cm 250) (m (-3)) Build.north (mps 3)
      else subj (cm 250) (m 3) Build.north (mps 3)
    let vx :=
      if k = 0 then m 75 else if k = 1 then m 40 else if k = 2 then m 25 else if k = 3 then m 15
      else if k = 4 then cm 750 else if k = 5 then cm 250 else if k = 6 then cm (-250)
      else if k = 7 then cm (-750) else if k = 8 then m (-14) else if k = 9 then m (-20) else m (-26)
    sceneAt t [s, other vx (cm 250) Build.west (mps 5)] darkSignal

/-- `idle` (not_applicable): The signal governing c showed circular_green at the subject's entry: not inoperative. -/
def idleTrace : Trace := conflictTrace greenSignal

/-- `blind` (unknown): After its stop the subject is in X with v crossing on a conflicting path; kin.speed is absent, so whether the subject proceeds into the conflict is unknown. -/
def blindTrace : Trace := conflictTrace darkSignal

/-- `branch_1` (compliant): After its stop the subject crosses X with no other road user in the scene. -/
def branch_1Trace : Trace :=
  padded <| Build.trace 5 20000 (Units.seconds 1) fun k t =>
    sceneAt t [if k < 4 then approachStopping k else subjectInXNorth] darkSignal

/-- `branch_2` (compliant): Vehicle v halted on its own approach after the subject's halt and still waits there; the subject crosses X and its closest approach to v is predicted below p.conflict_centre_clearance: v is not a vehicle that previously completed a stop and is not within X. -/
def branch_2Trace : Trace :=
  padded <| Build.trace 5 20000 (Units.seconds 1) fun k t =>
    let v :=
      if k = 0 then other (m 75) (cm 250) Build.west (mps 3)
      else if k = 1 then other (m 40) (cm 250) Build.west (mps 3)
      else if k = 2 then other (m 25) (cm 250) Build.west (mps 2)
      else other (m 14) (cm 250) Build.west Q.zero
    sceneAt t [if k < 4 then approachStopping k else subjectInXNE, v] darkSignal

/-- `branch_3` (not_applicable): The subject entered X without halting at the stop line (NRS_484B_250_4_o1 violated at its entry), then crosses X in conflict with v: the yielding duty follows 'such a stop', which was not made; the omitted stop is judged by NRS_484B_250_4_o1. -/
def branch_3Trace : Trace :=
  padded <| Build.trace 5 20000 (Units.seconds 1) fun k t =>
    sceneAt t [if k < 4 then approachRolling k else subjectInXNorth, crossing k] darkSignal

/-- `branch_4` (violated): v halted on c2 (k1) before the subject's halt at the stop line (k2) and
    still waits there; the subject proceeds into X heading for it, closest approach within the
    horizon below the clearance: v previously completed a stop (p4). -/
def branch_4Trace : Trace :=
  padded <| Build.trace 5 20000 (Units.seconds 1) fun k t =>
    let v :=
      if k = 0 then other (m 75) (cm 250) Build.west (mps 3)
      else other (m 14) (cm 250) Build.west Q.zero
    sceneAt t [if k < 4 then approachStopping k else subjectInXNE, v] darkSignal

/-- `branch_5` (violated): the forbid scene with the inoperative signal governing the intersection
    X itself rather than the approach c (t2's "or X"). -/
def branch_5Trace : Trace := conflictTrace darkSignalOnX

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o2
