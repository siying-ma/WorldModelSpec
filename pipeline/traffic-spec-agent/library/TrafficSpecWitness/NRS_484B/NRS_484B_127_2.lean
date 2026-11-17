/-
  Witnesses for NRS_484B_127_2.

  Geometry: a straight two-lane two-way highway along +x. Lane 10 (eastbound, y ∈ [-4, 0],
  ordinal 1, one lane in its direction) and lane 11 (westbound, y ∈ [0, 4], one lane in its
  direction); a paved shoulder 20 at y ∈ [-6, -4] where a scene needs one. In `branch_1` lane 10
  counts two lanes in its direction, with lane 12 (y ∈ [-8, -4]) its right neighbour.
  Eastbound users run at y = -2, a user in the opposing lane at y = 2, a user on the shoulder at
  y = -5. Trucks are 12 m long and 2.6 m wide (half-extents 6 m, 1.3 m, 2 m); combinations 18 m long,
  2.6 m wide; a car 4 m × 1.8 m; a motorcycle 2 m × 0.8 m; a bicycle 2 m × 0.6 m.
  Scenes are 1 s apart from t = 0. The rule looks back p.truck_space_open_time (30 s) and ahead
  p.overtake_window (10 s), so the witnesses that need both name the instants they speak about
  (`window`) where both windows are covered by the trace.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- Eastbound lane (count in its direction given). -/
def laneEast (count : Nat) (right : Option RegionId := none) : Structure :=
  Build.lane 10 [(m (-200), m (-4)), (m 3000, m (-4)), (m 3000, m 0), (m (-200), m 0)] Build.east
    (right := right) (ordinal := some 1) (count := some count)
def laneWest : Structure :=
  Build.lane 11 [(m (-200), m 0), (m 3000, m 0), (m 3000, m 4), (m (-200), m 4)] Build.west
    (ordinal := some 1) (count := some 1)
def laneEast2 : Structure :=
  Build.lane 12 [(m (-200), m (-8)), (m 3000, m (-8)), (m 3000, m (-4)), (m (-200), m (-4))] Build.east
    (left := some 10) (ordinal := some 2) (count := some 2)
def shoulder : Structure := Build.rect 20 .shoulder (m (-200)) (m (-6)) (m 3000) (m (-4))

def twoWay : List Structure := [laneEast 1, laneWest]

def truckHalf : Q × Q × Q := (m 6, cm 130, m 2)
def comboHalf : Q × Q × Q := (m 9, cm 130, m 2)

def truck (id : TrackId) (x y v : Int) : RoadUser :=
  Build.user id [.truck] (m x, m y) Build.east (Units.metresPerSecond v) truckHalf
def combo (id : TrackId) (x y v : Int) : RoadUser :=
  Build.user id [.trailerOrCombination] (m x, m y) Build.east (Units.metresPerSecond v) comboHalf
def car (id : TrackId) (x y v : Int) : RoadUser :=
  Build.user id [.motorVehicle] (m x, m y) Build.east (Units.metresPerSecond v) (m 2, cm 90, cm 75)

def ki (k : Nat) : Int := (k : Int)

/-- `forbid` (violated): Two-lane two-way highway (one lane each direction); a 2.6 m wide truck follows another 2.6 m wide truck at 60 m, both at 25 m/s, for 60 s with no one between and no overtaking. -/
def forbidTrace : Trace :=
  Build.trace 61 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, truck 2 (25 * ki k + 72) (-2) 25 ]
      twoWay
      [ ]

/-- `permit` (compliant): Same road; the following wide truck keeps a body gap of 200 m to the wide truck ahead. -/
def permitTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, truck 2 (25 * ki k + 212) (-2) 25 ]
      twoWay
      [ ]

/-- `idle` (not_applicable): The subject is a motorcycle following a wide truck at 30 m. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorcycle] (m (25 * ki k), m (-2)) Build.east (Units.metresPerSecond 25)
          (m 1, cm 40, cm 70)
      , truck 2 (25 * ki k + 37) (-2) 25 ]
      twoWay
      [ ]

/-- `blind` (unknown): Two trucks follow each other at 60 m; the source declares kin.extent absent, so neither width is known. -/
def blindTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, truck 2 (25 * ki k + 72) (-2) 25 ]
      twoWay
      [ ]

/-- `branch_1` (not_applicable): The wide trucks travel on a highway whose lane counts two lanes in their direction. -/
def branch_1Trace : Trace :=
  Build.trace 61 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, truck 2 (25 * ki k + 72) (-2) 25 ]
      [ laneEast 2 (right := some 12), laneEast2, laneWest ]
      [ ]

/-- Subject in branch_2: follows at a 40 m body gap until t = 36 s, moves into the opposing lane
    and passes at 35 m/s (the leader behind it from t = 41 s), and returns at t = 43 s. -/
def branch_2Subject (k : Nat) : RoadUser :=
  if k ≤ 36 then truck 1 (20 * ki k) (-2) 20
  else if k ≤ 42 then truck 1 (20 * ki k + 15 * (ki k - 36)) 2 35
  else truck 1 (20 * ki k + 15 * (ki k - 36)) (-2) 35

/-- `branch_2` (compliant): The following wide truck closes to 40 m and, within 8 s, overtakes and passes the leading truck in the opposing lane. -/
def branch_2Trace : Trace :=
  Build.trace 51 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ branch_2Subject k, truck 2 (20 * ki k + 52) (-2) 20 ]
      twoWay
      [ ]

/-- `branch_3` (compliant): The wide truck drives alone: no road user is ahead of it in its lane. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25 ]
      twoWay
      [ ]

/-- `branch_4` (compliant): A wide truck pulled into the lane ahead of the subject 5 s ago and is 60 m ahead; the window to open the space has not elapsed. -/
def branch_4Trace : Trace :=
  Build.trace 41 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25
      , truck 2 (25 * ki k + 72) (if k < 35 then 2 else -2) 25 ]
      twoWay
      [ ]

/-- `branch_5` (violated): a 2.6 m wide combination of vehicles follows another wide combination at
    a 60 m body gap for 60 s on the two-way highway. -/
def branch_5Trace : Trace :=
  Build.trace 61 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ combo 1 (25 * ki k) (-2) 25, combo 2 (25 * ki k + 78) (-2) 25 ]
      twoWay
      [ ]

/-- `branch_6` (compliant): a car runs between the wide truck and the wide truck ahead of it
    (50 m body gaps, 104 m truck to truck): the subject follows the car, not the truck. -/
def branch_6Trace : Trace :=
  Build.trace 61 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, car 3 (25 * ki k + 58) (-2) 25, truck 2 (25 * ki k + 116) (-2) 25 ]
      twoWay
      [ ]

/-- `branch_7` (violated): following a wide truck at 60 m, the wide truck overtakes and passes a
    bicycle riding on the shoulder (behind it from t = 40 s): a bicycle is no vehicle or
    combination, so the pass does not excuse the space. -/
def branch_7Trace : Trace :=
  Build.trace 61 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, truck 2 (25 * ki k + 72) (-2) 25
      , Build.user 4 [.bicycle] (m (5 * ki k + 790), m (-5)) Build.east (Units.metresPerSecond 5)
          (m 1, cm 30, cm 90) ]
      [ laneEast 1, laneWest, shoulder ]
      [ ]

/-- `branch_8` (compliant): a car between the wide truck and the wide truck ahead pulled onto the
    shoulder 5 s ago; the truck has been the immediate leader only since then. -/
def branch_8Trace : Trace :=
  Build.trace 41 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ truck 1 (25 * ki k) (-2) 25, car 3 (25 * ki k + 58) (if k < 35 then -2 else -5) 25
      , truck 2 (25 * ki k + 116) (-2) 25 ]
      [ laneEast 1, laneWest, shoulder ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_127_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (35000, 50000))
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.extent"]
  , witness "branch_1" branch_1Trace .notApplicable (window := some (35000, 50000))
  , witness "branch_2" branch_2Trace .compliant (window := some (31000, 50000))
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant (window := some (35000, 40000))
  , witness "branch_5" branch_5Trace .violated (window := some (35000, 50000))
  , witness "branch_6" branch_6Trace .compliant (window := some (35000, 50000))
  , witness "branch_7" branch_7Trace .violated (window := some (30000, 39000))
  , witness "branch_8" branch_8Trace .compliant (window := some (35000, 40000)) ]

end TrafficSpecWitness.NRS_484B_127_2
