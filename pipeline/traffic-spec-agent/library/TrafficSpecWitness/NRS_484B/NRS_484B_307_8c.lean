/-
  Witnesses for NRS_484B_307_8c.

  Geometry (metres, +x east, +y north; every figure here is the witness's own):
  - intersection 10: x ∈ [−10, 10], y ∈ [0, 20], on highways 100 (main street, north–south) and
    101 (cross street, east–west); highway 102 lies far away and meets nothing.
  - main street, northbound lanes entering 10: lane 2 (ordinal 1 of 2) x ∈ [0, 5] and lane 1
    (ordinal 2 of 2, the extreme right) x ∈ [5, 10], y ∈ [−30, 0]; upstream lane 3 x ∈ [5, 10],
    y ∈ [−60, −30], leading to lane 1. Two-way maps add southbound lane 4 x ∈ [−10, −1] and a
    median 50 x ∈ [−1, 0] (on highway 100); the one-way map adds one-way roadway 30 x ∈ [0, 10].
  - cross street: lane 21 eastbound entering 10 from the west (y ∈ [0, 10]), lane 22 westbound
    entering from the east (y ∈ [10, 20]), exits 23 (eastbound, east) and 24 (westbound, west).
  - marks: stop line 5 y ∈ [−6, −5.5] across lanes 1 and 2 (marks their entrance); stop line 6 on
    lane 21 (marks 21 only); crosswalk 40 y ∈ [−4, 0] (marks lanes 1 and 2); crosswalk 41 east of
    the junction (marks lane 22).
  - heads: 1 governs lanes 1 and 2; 2 governs the cross street's entering lane, circular_green.
  - bodies: cars half-length 2.25, half-width 1; pedestrians half-size 0.3.
  Instants 1 s apart. Subject (track 1) in lane 1 at x = 7.5: halted at k = 0 (1 m short of the
  place of the stop), creeping at k = 1 (still short of the junction), entering at k = 2 at 4 m/s
  (centre y = −1, front 1.25 m into the junction). Cross car (track 2) in lane 21 at y = 5, 12 m/s
  east, at x = −13 when the subject enters: closest approach of the centres 1.69 s ahead at 0.79 m.
  Occupancy is each body's footprint against each boundary, as the admission derives it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_8c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_8c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mm (n : Int) : Q := Units.millimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def carExt : Q × Q × Q := (cm 225, m 1, cm 75)
def pedExt : Q × Q × Q := (cm 30, cm 30, cm 90)

-- ---------------------------------------------------------------------------------------------
-- The map
-- ---------------------------------------------------------------------------------------------
def hwMain : Structure := Build.rect 100 .highway (m (-12)) (m (-60)) (m 12) (m 80)
def hwCross : Structure := Build.rect 101 .highway (m (-60)) (m (-2)) (m 60) (m 22)
def hwFar : Structure := Build.rect 102 .highway (m 200) (m 200) (m 220) (m 220)
def junction : Structure :=
  { Build.rect 10 .intersection (m (-10)) (m 0) (m 10) (m 20) with ways := some [100, 101] }
def laneRight : Structure :=
  { Build.lane 1 (box (m 5) (m (-30)) (m 10) (m 0)) Build.north (some 2) none (some 2) (some 2) none (some 10)
    with ways := some [100] }
def laneLeft : Structure :=
  { Build.lane 2 (box (m 0) (m (-30)) (m 5) (m 0)) Build.north none (some 1) (some 1) (some 2) none (some 10)
    with ways := some [100] }
def laneUp : Structure :=
  { Build.lane 3 (box (m 5) (m (-60)) (m 10) (m (-30))) Build.north none none none none (some [1]) none
    with ways := some [100] }
def laneSouth : Structure :=
  { Build.lane 4 (box (m (-10)) (m (-60)) (m (-1)) (m 0)) Build.south none none (some 1) (some 1)
    with ways := some [100] }
def median : Structure :=
  { Build.rect 50 .medianOrDivider (m (-1)) (m (-60)) (m 0) (m 0) with ways := some [100] }
def oneWayMain : Structure :=
  { Build.rect 30 .oneWayRoadway (m 0) (m (-60)) (m 10) (m 0) with ways := some [100] }
def crossEastIn : Structure :=
  { Build.lane 21 (box (m (-60)) (m 0) (m (-10)) (m 10)) Build.east none none (some 1) (some 1) none (some 10)
    with ways := some [101] }
def crossWestIn : Structure :=
  { Build.lane 22 (box (m 10) (m 10) (m 60) (m 20)) Build.west none none (some 1) (some 1) none (some 10)
    with ways := some [101] }
def crossEastOut : Structure :=
  { Build.lane 23 (box (m 10) (m 0) (m 60) (m 10)) Build.east with ways := some [101] }
def crossWestOut : Structure :=
  { Build.lane 24 (box (m (-60)) (m 10) (m (-10)) (m 20)) Build.west with ways := some [101] }
def stopLineMain : Structure :=
  { Build.rect 5 .stopLine (m 0) (m (-6)) (m 10) (cm (-550))
    with entranceOf := [1, 2], entranceObserved := true, ways := some [100] }
def stopLineCross : Structure :=
  { Build.rect 6 .stopLine (m (-16)) (m 0) (cm (-1550)) (m 10)
    with entranceOf := [21], entranceObserved := true, ways := some [101] }
def crosswalkSouth : Structure :=
  { Build.rect 40 .crosswalk (m (-3)) (m (-4)) (m 10) (m 0)
    with entranceOf := [1, 2], entranceObserved := true, ways := some [100] }
def crosswalkEast : Structure :=
  { Build.rect 41 .crosswalk (m 10) (m 0) (m 14) (m 20)
    with entranceOf := [22], entranceObserved := true, ways := some [101] }

/-- Two-way main street (with a median) and two-way cross street. -/
def twoWayBase : List Structure :=
  [ hwMain, hwCross, hwFar, junction, laneRight, laneLeft, laneUp, laneSouth, median,
    crossEastIn, crossWestIn, crossEastOut, crossWestOut ]
/-- The stop line marks the subject's lanes. -/
def stopLineMap : List Structure := twoWayBase ++ [stopLineMain]
/-- No stop line marks the subject's lanes (the only one marks lane 21); the crosswalk does. -/
def crosswalkMap : List Structure := twoWayBase ++ [stopLineCross, crosswalkSouth]
/-- Neither a stop line nor a crosswalk marks the subject's lanes. -/
def bareMap : List Structure := twoWayBase ++ [stopLineCross, crosswalkEast]
/-- The cross street one-way eastbound: to the right of the northbound approach. -/
def oneWayRightMap : List Structure :=
  [ hwMain, hwCross, hwFar, junction, laneRight, laneLeft, laneUp, laneSouth, median,
    crossEastIn, crossEastOut, stopLineMain ]
/-- One-way northbound main street, one-way westbound cross street (to the left). -/
def leftMap : List Structure :=
  [ hwMain, hwCross, hwFar, junction, laneRight, laneLeft, laneUp, oneWayMain,
    crossWestIn, crossWestOut, stopLineMain, crosswalkSouth ]

-- ---------------------------------------------------------------------------------------------
-- Devices, bodies, scenes
-- ---------------------------------------------------------------------------------------------
def mainHead (shows : List SignalIndication) : Device := Build.signal 1 [1, 2] shows
def crossHead (gov : List RegionId) : Device := Build.signal 2 gov [.circularGreen]

def car (track : TrackId) (x y : Q) (h : Vec) (v : Q) : RoadUser :=
  Build.user track [.motorVehicle] (x, y) h v carExt
def walker (track : TrackId) (x y : Q) (v : Q) : RoadUser :=
  Build.user track [.pedestrian] (x, y) Build.east v pedExt

/-- Footprint occupancy: a body occupies every structure whose boundary its footprint meets. -/
def occupancyOf (users : List RoadUser) (structs : List Structure) : List (TrackId × RegionId) :=
  let s0 : Scene := { t := 0, users := users, structures := structs }
  users.flatMap fun u =>
    match footprint s0 u.track with
    | none => []
    | some fp => structs.filterMap fun st =>
        match st.boundary with
        | some poly => if Geom.polygonsOverlap fp poly then some (u.track, st.id) else none
        | none => none

def rightIntent : List (IntId × Bool) := [("int.right_turn", true), ("int.left_turn", false)]
def leftIntent : List (IntId × Bool) := [("int.right_turn", false), ("int.left_turn", true)]

def sceneOf (t : Timestamp) (users : List RoadUser) (structs : List Structure) (devs : List Device)
    (ints : List (IntId × Bool)) : Scene :=
  Build.scene t (some 1) users structs devs (occupies := some (occupancyOf users structs))
    (intents := [{ vehicle := 1, target := 10, values := ints }])

/-- The cross car in lane 21 under the green head: x = −37, −25, −13 at k = 0, 1, 2. -/
def crossCar (k : Nat) : RoadUser := car 2 (m (-37 + 12 * (Int.ofNat k))) (m 5) Build.east (mps 12)

def redOnly : Nat → List SignalIndication := fun _ => [.circularRed]

/-- A right turn on red from lane 1: halted with centre at `haltY` (k = 0), creeping with centre at
    `creepY` (k = 1), entering the junction at 4 m/s (k = 2). -/
def rightTurnTrace (structs : List Structure) (crossGov : List RegionId) (haltY creepY : Q)
    (shows : Nat → List SignalIndication) (others : Nat → List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let subj := match k with
      | 0 => car 1 (cm 750) haltY Build.north (mps 0)
      | 1 => car 1 (cm 750) creepY Build.north (mps 2)
      | _ => car 1 (cm 750) (m (-1)) Build.north (mps 4)
    sceneOf t (subj :: others k) structs [mainHead (shows k), crossHead crossGov] rightIntent

-- ---------------------------------------------------------------------------------------------
-- The scenarios
-- ---------------------------------------------------------------------------------------------
-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): halted 1 m short of stop line 5 (centre −9.25), enters under
    circular_red alone; the cross car under circular_green closes, closest approach 1.69 s ahead
    at 0.79 m. -/
def forbidTrace : Trace :=
  rightTurnTrace stopLineMap [21] (cm (-925)) (cm (-525)) redOnly fun k => [crossCar k]

/-- `permit` (compliant): the same right turn on red, no other road user. -/
def permitTrace : Trace :=
  rightTurnTrace stopLineMap [21] (cm (-925)) (cm (-525)) redOnly fun _ => []

/-- `idle` (not_applicable): head 1 turns circular_green alone before the subject enters. -/
def idleTrace : Trace :=
  rightTurnTrace stopLineMap [21] (cm (-925)) (cm (-525))
    (fun k => if k < 2 then [.circularRed] else [.circularGreen]) fun _ => []

/-- `blind` (unknown): as forbid; lane ordinals and counts masked. No one-way roadway, so the
    left branch is decided false. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (not_applicable): halted 15 m short of stop line 5 (front at −21) behind a queue,
    then rolled across the line into the junction without halting at the place. The subject
    starts in the upstream lane 3, so the approach through lane 1 is wholly recorded. -/
def branch_1Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    let subj := match k with
      | 0 => car 1 (cm 750) (m (-34)) Build.north (mps 8)
      | 1 => car 1 (cm 750) (cm (-2325)) Build.north (mps 0)
      | 2 => car 1 (cm 750) (m (-14)) Build.north (mps 6)
      | 3 => car 1 (cm 750) (cm (-525)) Build.north (mps 8)
      | _ => car 1 (cm 750) (cm 275) Build.north (mps 8)
    let other := car 2 (mm (-48375 + 12000 * (Int.ofNat k))) (m 8) Build.east (mps 12)
    sceneOf t [subj, other] stopLineMap [mainHead [.circularRed], crossHead [21]] rightIntent

/-- `branch_2` (violated): left turn on red from lane 2 (ordinal 1) of one-way roadway 30 onto a
    one-way westbound street; halted 0.5 m short of stop line 5; enters at 5 m/s while a
    pedestrian walks east at 1.3 m/s in crosswalk 40 (which marks lanes 1 and 2, entering the
    junction), closest approach 0.28 s ahead at 1.7 m. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let subj := match k with
      | 0 => car 1 (cm 250) (cm (-875)) Build.north (mps 0)
      | 1 => car 1 (cm 250) (m (-5)) Build.north (mps 3)
      | _ => car 1 (cm 250) (cm (-150)) Build.north (mps 5)
    let ped := walker 3 (cm (-210 + 130 * (Int.ofNat k))) (cm (-50)) (Units.micrometresPerSecond 1300000)
    sceneOf t [subj, ped] leftMap [mainHead [.circularRed], crossHead [22]] leftIntent

/-- `branch_3` (not_applicable): as forbid, but head 1 shows circular_red with a green right arrow:
    not a steady red alone. -/
def branch_3Trace : Trace :=
  rightTurnTrace stopLineMap [21] (cm (-925)) (cm (-525))
    (fun _ => [.circularRed, .greenArrow .right]) fun k => [crossCar k]

/-- `branch_4` (violated): no stop line marks lane 1 (stop line 6 marks lane 21 only); crosswalk 40
    does. Halted 1 m short of the crosswalk (centre −7.25), then as forbid. -/
def branch_4Trace : Trace :=
  rightTurnTrace crosswalkMap [21] (cm (-725)) (m (-4)) redOnly fun k => [crossCar k]

/-- `branch_5` (violated): neither a stop line nor a crosswalk marks lane 1 (stop line 6 marks
    lane 21, crosswalk 41 lane 22). Halted 1 m short of the junction (centre −3.25), then as forbid. -/
def branch_5Trace : Trace :=
  rightTurnTrace bareMap [21] (cm (-325)) (cm (-250)) redOnly fun k => [crossCar k]

/-- `branch_6` (violated): the cross street is one-way eastbound (to the right), not
    two-directional; as forbid otherwise. -/
def branch_6Trace : Trace :=
  rightTurnTrace oneWayRightMap [21] (cm (-925)) (cm (-525)) redOnly fun k => [crossCar k]

/-- `branch_7` (compliant): as forbid, but the closing body is of no class of pedestrian or
    traffic (its classes are observed and none applies): the duty is owed to no one there. -/
def branch_7Trace : Trace :=
  rightTurnTrace stopLineMap [21] (cm (-925)) (cm (-525)) redOnly
    fun k => [{ crossCar k with classes := some [] }]

/-- `branch_8` (violated): as permit; after entering, the subject stands in the junction
    (k = 3, speed 0) and a pedestrian walking in the junction at 1.3 m/s touches its body. -/
def branch_8Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let subj := match k with
      | 0 => car 1 (cm 750) (cm (-925)) Build.north (mps 0)
      | 1 => car 1 (cm 750) (cm (-525)) Build.north (mps 2)
      | 2 => car 1 (cm 750) (m (-1)) Build.north (mps 4)
      | _ => car 1 (cm 750) (m 2) Build.north (mps 0)
    let others := if k < 3 then [] else [walker 3 (cm 630) (m 2) (Units.micrometresPerSecond 1300000)]
    sceneOf t (subj :: others) stopLineMap [mainHead [.circularRed], crossHead [21]] rightIntent

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_8c"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_8c
