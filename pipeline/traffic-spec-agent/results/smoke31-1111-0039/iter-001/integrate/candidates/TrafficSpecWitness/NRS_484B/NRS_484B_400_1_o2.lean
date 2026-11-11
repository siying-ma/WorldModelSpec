/-
  Witnesses for NRS_484B_400_1_o2.

  Geometry (metres, +x east, +y north). A highway h (x -8…12, y -60…0) carries northbound approach
  lanes of width 4 m that end at y = 0 and enter the intersection i (x -8…24, y 0…16), which lies
  on h. Two-lane approach: L1 (x 0…4, ordinal 1) and L2 (x 4…8, ordinal 2), count 2. The `idle`
  approach adds a right turn lane TL (x 8…12, ordinal 3, side right), count 3.

  The vehicle x (track 1, ru.motor_vehicle, half-length 2.5 m, half-width 1 m) is observed every
  50 ms (k = 0…99) at 10 m/s, its path length growing 0.5 m per step; its centre advances 0.49995 m
  per step along its heading (a chord never longer than the path). It starts heading north with its
  centre at y = -32.25. A turn step rotates the heading by the exact rational rotation
  (312/313, 25/313), about 4.5812°, and carries the yaw rate ±91.624 deg/s held over the 50 ms
  before the scene. The right turn is 20 right steps, k = 65…84 (about minus 91.6°), then straight.
  Occupancy is stated from the footprint: a lane (and h) while the rear is below y = 0 and the
  footprint's 2 m width overlaps the lane's strip; i once the front is past y = 0. On a straight
  approach the entry into i is k = 60 (path 30 m: the 15 m approach window behind it is covered),
  and the turn is recognized at k = 74, where the heading change since entry first reaches minus 45°.
  int.turn is declared for x at i in every scene.

  Every witness names the instants k = 66…99 (3300…4950 ms): after the entry, so that the heading
  change since entry exists, and before the recognition.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def hId : RegionId := 10
def iId : RegionId := 11
def l1Id : RegionId := 12
def l2Id : RegionId := 13
def tlId : RegionId := 14

def steps : Nat := 100

def box (x0 y0 x1 y1 : Q) : List Vec := [(x0, y0), (x1, y0), (x1, y1), (x0, y1)]

def highway : Structure := Build.rect hId .highway (m (-8)) (m (-60)) (m 12) (m 0)

def intersection : Structure :=
  { Build.rect iId .intersection (m (-8)) (m 0) (m 24) (m 16) with ways := some [hId] }

/-- A northbound approach lane of width 4 m from x0, entering i, on h. -/
def approachLane (id : RegionId) (x0 : Int) (left right : Option RegionId) (ordinal count : Nat) : Structure :=
  { Build.lane id (box (m x0) (m (-60)) (m (x0 + 4)) (m 0)) Build.north (left := left) (right := right)
      (ordinal := some ordinal) (count := some count) (enters := some iId)
    with ways := some [hId] }

/-- Two-lane approach, no right turn lane: (lane, west edge). -/
def twoLaneStrips : List (RegionId × Int) := [(l1Id, 0), (l2Id, 4)]
def twoLane : List Structure :=
  [ highway, intersection
  , approachLane l1Id 0 none (some l2Id) 1 2
  , approachLane l2Id 4 (some l1Id) none 2 2 ]

/-- Three-lane approach whose rightmost lane is a right turn lane. -/
def turnLaneStrips : List (RegionId × Int) := [(l1Id, 0), (l2Id, 4), (tlId, 8)]
def withTurnLane : List Structure :=
  [ highway, intersection
  , approachLane l1Id 0 none (some l2Id) 1 3
  , approachLane l2Id 4 (some l1Id) (some tlId) 2 3
  , { approachLane tlId 8 (some l2Id) none 3 3 with kind := .turnLane, turnSide := some .right } ]

-- Kinematics: an exact rational rotation per turn step.
def rotC : Q := Q.mk' 312 313
def rotS : Q := Q.mk' 25 313
def chord : Q := Units.micrometres 499950

/-- The heading after one step: right (clockwise) for a negative turn, left for a positive one. -/
def rotate (turn : Int) (h : Vec) : Vec :=
  if turn < 0 then (Q.add (Q.mul h.1 rotC) (Q.mul h.2 rotS), Q.sub (Q.mul h.2 rotC) (Q.mul h.1 rotS))
  else if 0 < turn then (Q.sub (Q.mul h.1 rotC) (Q.mul h.2 rotS), Q.add (Q.mul h.2 rotC) (Q.mul h.1 rotS))
  else h

/-- Centre and heading at step k under a turn schedule, from a start centre heading north. -/
def state (sched : Nat → Int) (start : Vec) : Nat → Vec × Vec
  | 0 => (start, Build.north)
  | k + 1 =>
    let (p, h) := state sched start k
    let h' := rotate (sched (k + 1)) h
    ((Q.add p.1 (Q.mul h'.1 chord), Q.add p.2 (Q.mul h'.2 chord)), h')

/-- The right turn through i. -/
def turnRight (k : Nat) : Int := if 64 < k ∧ k ≤ 84 then -1 else 0

def vehicle (p h : Vec) (turn : Int) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] p h (Units.metresPerSecond 10) (cm 250, cm 100, cm 75)
      (some (cm (50 * (k : Int)))))
    fun kin => { kin with yawRate := some (Units.millidegrees (91624 * turn)) }

/-- Stated occupancy from the footprint: lanes and h while the rear is south of y = 0, the lane
    strips the 2 m width overlaps; i once the front is north of y = 0. -/
def occ (strips : List (RegionId × Int)) (p : Vec) : List (TrackId × RegionId) :=
  let inApproach := Q.lt (Q.sub p.2 (cm 250)) Q.zero
  let lanes := strips.filter fun (_, x0) =>
    Q.lt (Q.sub p.1 (m 1)) (m (x0 + 4)) && Q.lt (m x0) (Q.add p.1 (m 1))
  (if inApproach then (1, hId) :: lanes.map fun (r, _) => (1, r) else []) ++
  (if Q.lt Q.zero (Q.add p.2 (cm 250)) then [(1, iId)] else [])

def turnIntent : DeclaredIntent := { vehicle := 1, target := iId, values := [("int.turn", true)] }

def drive (structures : List Structure) (strips : List (RegionId × Int)) (sched : Nat → Int) (x0Cm : Int) : Trace :=
  Build.trace steps 0 (Units.milliseconds 50) fun k t =>
    let (p, h) := state sched (cm x0Cm, cm (-3225)) k
    Build.scene t (some 1) [vehicle p h (sched k) k] structures []
      (occupies := some (occ strips p)) (intents := [turnIntent])

/-- The instants after the entry into i to the end of the trace. -/
def judged : Option (Timestamp × Timestamp) := some (3300, 4950)

/-- `forbid` (violated): x (ru.motor_vehicle) approaches i on a two-lane approach with no right turn lane, in the leftmost lane; int.turn is declared at i; x turns right from that lane. -/
def forbidTrace : Trace := drive twoLane twoLaneStrips turnRight 200

/-- `permit` (compliant): Same approach; x is in the lane whose ordinal equals the lane count for the whole approach length, enters i from it and turns right. -/
def permitTrace : Trace := drive twoLane twoLaneStrips turnRight 600

/-- `idle` (not_applicable): The approach has a right st.turn_lane entering i on the same highway in x's direction; x turns right (NRS_484B_400_1_o1 governs that case). -/
def idleTrace : Trace := drive withTurnLane turnLaneStrips turnRight 1000

/-- `blind` (unknown): x turns right from a two-lane approach with no right turn lane, with int.turn declared, but the source does not observe lane ordinals and counts. -/
def blindTrace : Trace := drive twoLane twoLaneStrips turnRight 600

/-- A lane change from L1 to L2 inside the approach window: 4 right steps (k = 31…34), 21 straight
    steps, 4 left steps (k = 56…59), ending about 5.93 m east, wholly in L2 before the entry. -/
def laneChangeThenTurn (k : Nat) : Int :=
  if 30 < k ∧ k ≤ 34 then -1 else if 55 < k ∧ k ≤ 59 then 1 else turnRight k

/-- `branch_1` (violated): two-lane approach, no right turn lane; x starts in L1 and moves to L2
    within the 15 m approach behind its entry, enters i from the extreme right lane and turns right:
    the approach was not made from that lane. -/
def branch1Trace : Trace := drive twoLane twoLaneStrips laneChangeThenTurn 200

-- Turn lanes that are not a right turn lane of x's approach, one failing each requirement.
def h2Id : RegionId := 15
def i2Id : RegionId := 16
def tlLeftId : RegionId := 17
def tlOppId : RegionId := 18
def tlCrossId : RegionId := 19
def tlOtherId : RegionId := 20

def turnLaneOf (id : RegionId) (bnd : List Vec) (dir : Vec) (ordinal count : Nat) (enters way : RegionId)
    (side : TurnSide) : Structure :=
  { Build.lane id bnd dir (ordinal := some ordinal) (count := some count) (enters := some enters)
    with kind := .turnLane, turnSide := some side, ways := some [way] }

/-- A left turn lane left of L1 (L1 ordinal 2, L2 ordinal 3 of 3); a southbound right turn lane
    entering i from the north on h (opposed); an eastbound right turn lane entering i on the cross
    highway h2 (x -60…-8); a northbound right turn lane on h entering i2, an intersection south of
    the stretch x drives. -/
def distractorLanes : List Structure :=
  [ highway, { intersection with ways := some [hId, h2Id] }
  , Build.rect h2Id .highway (m (-60)) (m 0) (m (-8)) (m 16)
  , { Build.rect i2Id .intersection (m (-8)) (m (-76)) (m 12) (m (-60)) with ways := some [hId] }
  , turnLaneOf tlLeftId (box (m (-4)) (m (-60)) (m 0) (m 0)) Build.north 1 3 iId hId .left
  , approachLane l1Id 0 (some tlLeftId) (some l2Id) 2 3
  , approachLane l2Id 4 (some l1Id) none 3 3
  , turnLaneOf tlOppId (box (m (-8)) (m 16) (m (-4)) (m 40)) Build.south 1 1 iId hId .right
  , turnLaneOf tlCrossId (box (m (-60)) (m 0) (m (-8)) (m 4)) Build.east 1 1 iId h2Id .right
  , turnLaneOf tlOtherId (box (m 8) (m (-100)) (m 12) (m (-76))) Build.north 3 3 i2Id hId .right ]
def distractorStrips : List (RegionId × Int) := [(tlLeftId, -4), (l1Id, 0), (l2Id, 4)]

/-- `branch_2` (violated): no right turn lane of x's approach (the turn lanes present are a left
    one, an opposed one, one on the cross highway and one entering another intersection); x turns
    right from L1, ordinal 2 of 3. -/
def branch2Trace : Trace := drive distractorLanes distractorStrips turnRight 200

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_adjacency"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .violated ]

end TrafficSpecWitness.NRS_484B_400_1_o2
