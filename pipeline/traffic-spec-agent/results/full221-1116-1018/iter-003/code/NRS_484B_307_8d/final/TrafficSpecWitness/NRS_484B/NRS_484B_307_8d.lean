/-
  Witnesses for NRS_484B_307_8d.

  The map (static in every scene; metres, +x east, +y north):
    intersection i (10): x ∈ [0, 12], y ∈ [−6, 6].
    lane c (11): the rider's eastbound approach, x ∈ [−60, 0], y ∈ [−4, 0], direction east, enters i.
    stop line (12): x ∈ [−5, −4.5] across c, recorded as marking c's entrance.
    near crosswalk (17, branch_10 only, in place of the stop line): x ∈ [−3, 0], marking c's entrance.
    far approach (13): westbound, x ∈ [15, 75], y ∈ [0, 4], enters i; its crosswalk (14):
      x ∈ [12, 15], y ∈ [−6, 6], recorded as marking 13's entrance.
    cross approach (16): northbound, x ∈ [6, 10], y ∈ [−60, −6], enters i.
    head s (20) governs c; head h (21) governs the cross approach.
  The rider (track 1) is a moped, half-length 1 m, half-width 0.4 m, on y = −2.
  Straight timeline, one scene a second, t = 0 … 11 s: s shows circular_yellow at t = 0 and
  circular_red alone after; the moped approaches at 5 m/s, halts t = 4 … 8 s with its front 1 m
  short of the place, moves at t = 9 s (still on c, outside i), enters i at t = 10 s (centre x = 3)
  and is at x = 8 at t = 11 s. h shows circular_green at t = 5 s and t = 7 s (two rises after the
  halt's onset), circular_red otherwise (once only, at t = 5 s, in `idle`).
  The pedestrian (track 2) walks north at 1.3 m/s on x = 13.6 in the far crosswalk, at y = −4.6 at
  the entry: the centres' closest approach is about 2.1 s ahead at about 0.15 m (the reading's
  horizon is 3 s, the clearance 3 m).
  Turn branches: the same until t = 8 s, then scenes every 50 ms (the step bound): t = 9.00 s on c,
  the entry at 9.05 s, a 1 s passage with a yaw rate of ∓85 deg/s, the exit at 10.05 s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8d
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8d

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
def walkSpeed : Q := Units.micrometresPerSecond 1300000

-- Binders ↦ tracks: subject ↦ 1

-- ------------------------------------------------------------------------------------------
-- The map
-- ------------------------------------------------------------------------------------------
def iX : Structure := Build.rect 10 .intersection (m 0) (m (-6)) (m 12) (m 6)
def laneC : Structure :=
  Build.lane 11 [(m (-60), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-60), m 0)] Build.east (enters := some 10)
def stopLine : Structure :=
  { Build.rect 12 .stopLine (m (-5)) (m (-4)) (cm (-450)) (m 0) with entranceOf := [11], entranceObserved := true }
def laneFar : Structure :=
  Build.lane 13 [(m 15, m 0), (m 75, m 0), (m 75, m 4), (m 15, m 4)] Build.west (enters := some 10)
def crossFar : Structure :=
  { Build.rect 14 .crosswalk (m 12) (m (-6)) (m 15) (m 6) with
      entranceOf := [13], entranceObserved := true, marked := some true }
def laneCross : Structure :=
  Build.lane 16 [(m 6, m (-60)), (m 10, m (-60)), (m 10, m (-6)), (m 6, m (-6))] Build.north (enters := some 10)
def crossNear : Structure :=
  { Build.rect 17 .crosswalk (m (-3)) (m (-6)) (m 0) (m 6) with
      entranceOf := [11], entranceObserved := true, marked := some true }

def mapLine : List Structure := [iX, laneC, stopLine, laneFar, crossFar, laneCross]
def mapCrosswalk : List Structure := [iX, laneC, crossNear, laneFar, crossFar, laneCross]
def mapBare : List Structure := [iX, laneC, laneFar, crossFar, laneCross]

def red : List SignalIndication := [.circularRed]
def grn : List SignalIndication := [.circularGreen]

def headS (ind : List SignalIndication) : Device := Build.signal 20 [11] ind
def headH (ind : List SignalIndication) : Device := Build.signal 21 [16] ind

/-- s: yellow at the first scene, red alone after. -/
def sAt (k : Nat) : List SignalIndication := if k == 0 then [.circularYellow] else red
/-- h: green at t = 5 s and t = 7 s. -/
def hTwice (k : Nat) : List SignalIndication := if k == 5 || k == 7 then grn else red
/-- h: green at t = 5 s only. -/
def hOnce (k : Nat) : List SignalIndication := if k == 5 then grn else red
/-- h: green at t = 5, 7 and 10 s. -/
def hThrice (k : Nat) : List SignalIndication := if k == 5 || k == 7 || k == 10 then grn else red

def noRightTurnOnC : Device :=
  { Build.sign 30 .regulatorySign [11] with code := some .noRightTurn, conditions := some {} }
def noLeftTurnOnI : Device :=
  { Build.sign 31 .regulatorySign [10] with code := some .noLeftTurn, conditions := some {} }

-- ------------------------------------------------------------------------------------------
-- Bodies
-- ------------------------------------------------------------------------------------------
def mopedExt : Q × Q × Q := (m 1, cm 40, cm 70)
def pedExt : Q × Q × Q := (cm 25, cm 25, cm 90)
def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)

def moped (pos hd vel : Vec) (sp yaw : Q) : RoadUser :=
  { track := 1, classes := some [.moped]
    kin := { position := some pos, heading := some hd, velocity := some vel, speed := some sp,
             extent := some mopedExt, yawRate := some yaw } }

def mopedStraight (x sp : Q) : RoadUser :=
  moped (x, m (-2)) Build.east (Build.scale Build.east sp) sp Q.zero

/-- A road user walking north on x = 13.6 m in the far crosswalk, at y = −4.6 m at the entry
    instant `te` (ms), observed at `t` (ms). -/
def walkerAt (track : TrackId) (classes : List RoadUserClass) (te t : Int) : RoadUser :=
  Build.user track classes
    (cm 1360, Q.add (cm (-460)) (Q.mul walkSpeed (Q.mk' (t - te) 1000))) Build.north walkSpeed pedExt

-- ------------------------------------------------------------------------------------------
-- Scenes
-- ------------------------------------------------------------------------------------------
/-- Occupancy as footprint overlap with each region (touching counts). -/
def withOcc (s : Scene) : Scene :=
  { s with occupies := s.users.flatMap fun u =>
      match footprint s u.track with
      | none => []
      | some fp => s.structures.filterMap fun st =>
          match st.boundary with
          | some poly => if Geom.polygonsOverlap fp poly then some (u.track, st.id) else none
          | none => none }

def mk (t : Int) (structs : List Structure) (devs : List Device) (users : List RoadUser) : Scene :=
  withOcc (Build.scene t (some 1) users structs devs)

/-- Forbid's moped: approach, halt at x = −7 (front 1 m short of the stop line), move, enter. -/
def xsLine : List Int := [-27, -22, -17, -12, -7, -7, -7, -7, -7, -2, 3, 8]
def spStraight : List Int := [5, 5, 5, 5, 0, 0, 0, 0, 0, 5, 5, 5]

/-- A one-scene-a-second trace of `n` scenes: the moped at `xs` (cm) with speeds `sps` (cm/s), the
    heads, extra devices, and the other road users at scene k. -/
def straight (n : Nat) (xs sps : List Int) (structs : List Structure) (hSched : Nat → List SignalIndication)
    (extra : List Device) (others : Nat → List RoadUser) : Trace :=
  (List.range n).map fun k =>
    mk (Int.ofNat (1000 * k)) structs ([headS (sAt k), headH (hSched k)] ++ extra)
      (mopedStraight (cm (xs.getD k 0)) (cm (sps.getD k 0)) :: others k)

def cmList (xs : List Int) : List Int := xs.map (· * 100)

/-- The pedestrian of the forbid scene, present from t = 9 s, entry at t = 10 s. -/
def pedFrom9 (k : Nat) : List RoadUser :=
  if k ≥ 9 then [walkerAt 2 [.pedestrian] 10000 (Int.ofNat (1000 * k))] else []

/-- `forbid` (violated): A moped halts 1 m short of the stop line marking lane c's entrance while head s displays circular_red alone; while it waits, the head governing the cross street's lane begins circular_green twice and s stays circular_red alone; no turn-prohibiting sign governs c or i. The moped enters i straight through at 5 m/s while a pedestrian walks at 1.3 m/s in the crosswalk marking the entrance of the far approach, the closest approach of their centres 1.0 s ahead at 0.6 m. -/
def forbidTrace : Trace :=
  straight 12 (cmList xsLine) (cmList spStraight) mapLine hTwice [] pedFrom9

/-- `permit` (compliant): Same wait and entry with no other road user in the scene: the duty binds the rider alone and is met. -/
def permitTrace : Trace :=
  straight 12 (cmList xsLine) (cmList spStraight) mapLine hTwice [] (fun _ => [])

/-- `idle` (not_applicable): The moped halts at the line and enters i after the cross street's head has begun circular_green only once since its halt: the wait of two cycles is not met. -/
def idleTrace : Trace :=
  straight 12 (cmList xsLine) (cmList spStraight) mapLine hOnce [] pedFrom9

/-- `blind` (unknown): As forbid, but the source does not observe which travel regions the heads govern: which head is the rider's and whether the cross head belongs to this intersection are unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_2` (not_applicable): As forbid, but the moped halted 15 m short of the line behind a queue and, when the queue cleared, rolled to the line and into i without halting at the place: the halt the requirement to stop names did not occur, and the paragraph does not apply. -/
def branch_2Trace : Trace :=
  straight 12 (cmList [-41, -36, -31, -26, -21, -21, -21, -21, -21, -2, 3, 8]) (cmList spStraight)
    mapLine hTwice [] pedFrom9

/-- The turn branches: the forbid timeline to t = 8 s, then t = 9.00 s on c, the entry at 9.05 s
    and a 1 s passage sampled every 50 ms; `right` turns to the south, otherwise to the north. -/
def turnTrace (right : Bool) (sign : Device) : Trace :=
  let devs := fun (k : Nat) => [headS (sAt k), headH (hTwice k), sign]
  let te : Int := 9050
  let early := (List.range 9).map fun k =>
    let t := Int.ofNat (1000 * k)
    mk t mapLine (devs k) [mopedStraight (cm ((cmList xsLine).getD k 0)) (cm ((cmList spStraight).getD k 0))]
  let prev := mk 9000 mapLine (devs 9)
    [mopedStraight (cm (-125)) (mps 5), walkerAt 2 [.pedestrian] te 9000]
  let pass := (List.range 21).map fun k =>
    let t : Int := te + 50 * Int.ofNat k
    let ki : Int := Int.ofNat k
    let sgn : Int := if right then -1 else 1
    let mo : RoadUser :=
      if k == 0 then moped (cm 50, m (-2)) Build.east (Build.scale Build.east (mps 5)) (mps 5) Q.zero
      else
        let hd : Vec := (Q.ofInt (20 - ki), Q.ofInt (sgn * ki))
        let pos : Vec :=
          if k == 20 then (if right then (m 4, cm (-750)) else (m 6, cm 750))
          else if right then (cm (50 + 18 * ki), cm (-200 - 12 * ki))
          else (cm (50 + 15 * ki), cm (-200 + 20 * ki))
        moped pos hd (Build.scale hd (Q.mk' 1 4)) (mps 5) (Units.degrees (sgn * 85))
    mk t mapLine (devs 10) [mo, walkerAt 2 [.pedestrian] te t]
  early ++ [prev] ++ pass

/-- `branch_3` (not_applicable): As forbid, but a regulatory sign coded no_right_turn governs lane c and the moped's passage through i is recognized at its exit as a right turn (heading change -85 degrees): a device at the place prohibits the turn it made, and the permission with its yield does not arise. -/
def branch_3Trace : Trace := turnTrace true noRightTurnOnC

-- branch_4 (not_applicable): as branch_3, but the sign is coded no_left_turn and governs the
-- intersection i itself, and the passage is recognized at its exit as a left turn (+85 degrees).
def branch_4Trace : Trace := turnTrace false noLeftTurnOnI

-- branch_5 (violated): no pedestrian; a car approaches on the cross approach (not yet in i) under
-- h's third green as the moped enters, the centres' closest approach 1.2 s ahead at 1.4 m.
def branch_5Trace : Trace :=
  straight 11 (cmList xsLine) (cmList spStraight) mapLine hThrice [] fun k =>
    if k == 9 then [Build.user 3 [.motorVehicle] (m 8, m (-14)) Build.north (mps 5) carExt]
    else if k == 10 then [Build.user 3 [.motorVehicle] (m 8, m (-9)) Build.north (mps 5) carExt]
    else []

-- branch_6 (violated): no pedestrian; a car already inside i heading south crosses the moped's path
-- as it enters (closest approach 1 s ahead, centres meeting).
def branch_6Trace : Trace :=
  straight 11 (cmList xsLine) (cmList spStraight) mapLine hTwice [] fun k =>
    if k == 10 then [Build.user 3 [.motorVehicle] (m 8, m 3) Build.south (mps 5) carExt] else []

-- branch_7 (compliant): a pedestrian stands still in the far crosswalk on the moped's line: it is
-- not proceeding, so no precedence is owed to it under these words.
def branch_7Trace : Trace :=
  straight 12 (cmList xsLine) (cmList spStraight) mapLine hTwice [] fun k =>
    if k ≥ 9 then [Build.user 2 [.pedestrian] (cm 1360, m (-2)) Build.north Q.zero pedExt] else []

-- branch_8 (compliant): as forbid, but the moving body in the crosswalk is of no road-user class
-- (an object the source classifies as none): neither a pedestrian nor traffic.
def branch_8Trace : Trace :=
  straight 12 (cmList xsLine) (cmList spStraight) mapLine hTwice [] fun k =>
    if k ≥ 9 then [walkerAt 4 [] 10000 (Int.ofNat (1000 * k))] else []

-- branch_9 (compliant): the moped enters i and halts in it at t = 11 s while a pedestrian walking
-- south inside i passes 0.5 m from its centre: the halted rider grants precedence.
def branch_9Trace : Trace :=
  straight 12 (cmList [-27, -22, -17, -12, -7, -7, -7, -7, -7, -2, 3, 5]) (cmList [5, 5, 5, 5, 0, 0, 0, 0, 0, 5, 5, 0])
    mapLine hTwice [] fun k =>
    if k == 10 then [Build.user 2 [.pedestrian] (cm 550, cm 230) Build.south walkSpeed pedExt]
    else if k == 11 then [Build.user 2 [.pedestrian] (cm 550, cm 100) Build.south walkSpeed pedExt]
    else []

-- branch_10 (violated): as forbid, but c's entrance is marked by a crosswalk and no stop line; the
-- moped halts with its front 1 m short of that crosswalk.
def branch_10Trace : Trace :=
  straight 12 (cmList [-25, -20, -15, -10, -5, -5, -5, -5, -5, -2, 3, 8]) (cmList spStraight)
    mapCrosswalk hTwice [] pedFrom9

-- branch_11 (violated): as forbid, but c's entrance has no stop line and no crosswalk; the moped
-- halts with its front 1 m short of the intersection.
def branch_11Trace : Trace :=
  straight 12 [-2200, -1700, -1200, -700, -200, -200, -200, -200, -200, -150, 300, 800]
    [500, 500, 500, 500, 0, 0, 0, 0, 0, 200, 500, 500] mapBare hTwice [] pedFrom9

-- branch_12 (violated): the moped enters i and halts in it; a pedestrian standing in i at the entry
-- then walks into the halted moped's body (contact).
def branch_12Trace : Trace :=
  straight 12 (cmList [-27, -22, -17, -12, -7, -7, -7, -7, -7, -2, 3, 5]) (cmList [5, 5, 5, 5, 0, 0, 0, 0, 0, 5, 5, 0])
    mapLine hTwice [] fun k =>
    if k == 10 then [Build.user 2 [.pedestrian] (m 5, cm (-60)) Build.south Q.zero pedExt]
    else if k == 11 then [Build.user 2 [.pedestrian] (m 5, cm (-140)) Build.south walkSpeed pedExt]
    else []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_8d"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .violated
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_8d
