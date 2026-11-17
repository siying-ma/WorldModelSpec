/-
  Witnesses for NRS_484B_223_3a.

  Geometry (every figure is the witness's own): an east–west highway h (region 10) between
  y = −8 m and y = 8 m, x from −100 m to 500 m. Inside it an eastbound through lane L1 (11,
  y ∈ [−5.5, −2]), the centre turn lane c (12, y ∈ [−2, 2]) and a westbound lane L2 (13,
  y ∈ [2, 5.5]); the strip y ∈ [−8, −5.5] is the highway's southern shoulder area (in h, in no
  lane). Every lane lies on h (`ways := [10]`). A driveway/alley entrance (14) meets the highway
  from the south; an intersection (15) is used by `branch_2`. The subject (track 1) is a motor
  vehicle, half-extents 2.3 × 0.9 × 0.75 m; occupancy comes from its reference point.

  Instants are 1 s apart. The left-turn window of the reading is 10 s, so every trace whose verdict
  rests on the turn concept carries at least 12 s of history before the instants it speaks about
  (`window`), keeping that window covered. Turns are integrated from the yaw rate: 30 + 30 + 25 =
  85 deg over three seconds, then a yaw rate of 0 (below the 3 deg/s tolerance), inside the
  45–135 deg band.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_3a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_3a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : Structure := Build.rect 10 .highway (m (-100)) (m (-8)) (m 500) (m 8)
def laneL1 : Structure := { Build.rect 11 .lane (m (-100)) (cm (-550)) (m 500) (m (-2)) with ways := some [10] }
def ctl : Structure := { Build.rect 12 .centreTurnLane (m (-100)) (m (-2)) (m 500) (m 2) with ways := some [10] }
def laneL2 : Structure := { Build.rect 13 .lane (m (-100)) (m 2) (m 500) (cm 550) with ways := some [10] }
/-- A middle lane the source labels a lane but cannot tell whether it is a centre turn lane. -/
def middleLane : Structure :=
  { Build.rect 12 .lane (m (-100)) (m (-2)) (m 500) (m 2) with
      ways := some [10], unobservedKinds := [.centreTurnLane] }
/-- A driveway/alley entrance on the south side, centred at x = cx. -/
def drive (cx : Int) : Structure :=
  { Build.rect 14 .drivewayOrAlleyEntrance (m (cx - 4)) (m (-12)) (m (cx + 4)) (m (-8)) with ways := some [10] }
def isect : Structure := { Build.rect 15 .intersection (m 36) (m (-8)) (m 52) (m 8) with ways := some [10] }

def withCtl (d : Int) : List Structure := [hwy, laneL1, ctl, laneL2, drive d]

def subj (p : Vec) (h : Vec) (v : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] p h v (cm 230, cm 90, cm 75)) fun k => { k with yawRate := some yaw }

def leftIntent (r : RegionId) (b : Bool) : DeclaredIntent :=
  { vehicle := 1, target := r, values := [("int.left_turn", b)] }

/-- Headings 120°, 150° and 175° from east (north turned left by 30°, 60°, 85°), to 4 decimals. -/
def h120 : Vec := (Q.mk' (-5000) 10000, Q.mk' 8660 10000)
def h150 : Vec := (Q.mk' (-8660) 10000, Q.mk' 5000 10000)
def h175 : Vec := (Q.mk' (-9962) 10000, Q.mk' 872 10000)

/-- `forbid` (violated): The subject moves from a through lane into the st.centre_turn_lane without turning and travels 150 m in it; int.left_turn is declared false at every intersection and driveway_or_alley_entrance.
    Eastbound at 15 m/s in L1 for 12 s, then in c from 12 s to 25 s (195 m), yaw rate 0 throughout. -/
def forbidTrace : Trace :=
  Build.trace 26 0 (Units.seconds 1) fun k t =>
    let x : Q := m (15 * (k : Int) - 80)
    let y : Q := if k < 12 then cm (-375) else Q.zero
    Build.scene t (some 1)
      [ subj (x, y) Build.east (Units.metresPerSecond 15) Q.zero ]
      (withCtl 200)
      [ ]
      (intents := [leftIntent 14 false])

/-- `permit` (compliant): The subject occupies the centre turn lane and int.left_turn is declared true at a driveway_or_alley_entrance 40 m ahead. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subj (m (2 * (k : Int)), Q.zero) Build.east (Units.metresPerSecond 2) Q.zero ]
      (withCtl 40)
      [ ]
      (intents := [leftIntent 14 true])

/-- `idle` (not_applicable): The subject occupies a through lane on a road without a centre turn lane. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subj (m (15 * (k : Int)), cm (-375)) Build.east (Units.metresPerSecond 15) Q.zero ]
      [ hwy, laneL1, laneL2 ]
      [ ]

/-- `blind` (unknown): The source labels lanes but cannot tell a centre turn lane; the subject occupies the middle lane with int.left_turn declared false and no prior turn. -/
def blindTrace : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subj (m (10 * (k : Int) - 80), Q.zero) Build.east (Units.metresPerSecond 10) Q.zero ]
      [ hwy, laneL1, middleLane, laneL2, drive 200 ]
      [ ]
      (intents := [leftIntent 14 false])

/-- The off-road (or shoulder) wait, the 85 deg left turn across L1 and the run west in c:
    start position `(0, y0)` heading north, turning at 12–14 s, in c from 15 s on a heading of
    175° at 3 m/s (drifting 0.26 m/s north, still inside c at 22 s). -/
def turnIntoCtl (y0 : Int) (k : Nat) : RoadUser :=
  if k < 12 then subj (Q.zero, m y0) Build.north Q.zero Q.zero
  else if k = 12 then subj (Q.zero, m (-7)) h120 (Units.metresPerSecond 3) (Units.degrees 30)
  else if k = 13 then subj (m (-1), m (-4)) h150 (Units.metresPerSecond 3) (Units.degrees 30)
  else if k = 14 then subj (m (-3), cm (-300)) h175 (Units.metresPerSecond 3) (Units.degrees 25)
  else
    let j : Q := Q.ofInt ((k : Int) - 15)
    subj (Q.sub (m (-6)) (Q.mul j (Q.mk' 29886 10000)), Q.add (cm (-120)) (Q.mul j (Q.mk' 2616 10000)))
      h175 (Units.metresPerSecond 3) Q.zero

/-- `branch_1` (compliant): The subject leaves a private driveway (occupying no part of the highway), turns left by 85 degrees into the centre turn lane, and stays in it; int.left_turn is declared false.
    Waits at (0, −15) off the highway for 12 s, turns into c, then runs west in c to 22 s. -/
def branch_1Trace : Trace :=
  Build.trace 23 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turnIntoCtl (-15) k ]
      (withCtl 0)
      [ ]
      (intents := [leftIntent 14 false])

/-- `branch_2` (compliant): the subject occupies the centre turn lane with int.left_turn declared
    true at an intersection ahead (the "from" limb through an intersection). -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subj (m (2 * (k : Int)), Q.zero) Build.east (Units.metresPerSecond 2) Q.zero ]
      (withCtl 200 ++ [isect])
      [ ]
      (intents := [leftIntent 15 true, leftIntent 14 false])

/-- `branch_3` (violated): the same 85 deg left turn into the centre turn lane, but made from the
    highway's own shoulder area (on h throughout the turn window); int.left_turn declared false. -/
def branch_3Trace : Trace :=
  Build.trace 23 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ turnIntoCtl (-7) k ]
      (withCtl 200)
      [ ]
      (intents := [leftIntent 14 false])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "NRS_484B_223_3a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (12000, 25000))
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.centre_turn_lane"] (window := some (12000, 15000))
  , witness "branch_1" branch_1Trace .compliant (window := some (12000, 22000))
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated (window := some (12000, 22000)) ]

end TrafficSpecWitness.NRS_484B_223_3a
