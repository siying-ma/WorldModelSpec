/-
  Witnesses for NRS_484B_223_1b.

  The geometry. The world frame is +x east, +y north; every lane runs east unless the scene says
  otherwise, every scene is one second apart and every trace is eight observations long
  (t = 0 … 7000 ms). Each witness names the instants it speaks about (`window` = 3000 … 7000 ms),
  because the rule looks back over `p.turn_signal_advance_window`: at those instants the window
  behind reaches a recorded observation, so no verdict here rests on a truncated history.

  The three-lane carriageway (`map3`): a highway region spanning y = −4 … 16, and three eastbound
  lanes four metres wide — `lnL` (y 8 … 12, ordinal 1), `lnM` (y 4 … 8, ordinal 2) and `lnR`
  (y 0 … 4, ordinal 3), each recording three lanes in its direction, its neighbours, and a marking
  on both sides (the outer edges solid, the lines between the lanes broken). The subject (track 1)
  is a motor vehicle 4 m long and 2 m wide travelling east: it rides the middle lane to the fourth
  observation, its footprint reaches the left-hand lane at the fifth (k = 4, both lanes occupied),
  and it rides the left-hand lane afterwards. Occupancy is stated scene by scene, since a body
  across two lanes has its reference point in one polygon only.

  The single-lane street (`mapIdle`): one eastbound lane recording one lane in its direction, and a
  shoulder south of it; the subject swings onto the shoulder at k = 4.

  The two-way street (`mapTwoWay`): two eastbound lanes (`lnE1` y 4 … 8, `lnE2` y 0 … 4) and two
  westbound lanes (`lnW1` y 8 … 12, `lnW2` y 12 … 16), the double solid centre line between
  `lnE1` and `lnW1`, neither recorded as the other's neighbour.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_223_1b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_223_1b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

-- ---------------------------------------------------------------------------------------------
-- The maps
-- ---------------------------------------------------------------------------------------------
def hwyId : RegionId := 10
def lnL : RegionId := 11
def lnM : RegionId := 12
def lnR : RegionId := 13
def lnS : RegionId := 14
def shId : RegionId := 15
def lnE1 : RegionId := 21
def lnE2 : RegionId := 22
def lnW1 : RegionId := 23
def lnW2 : RegionId := 24

def highway : Structure := Build.rect hwyId .highway (m (-600)) (m (-4)) (m 1600) (m 16)
def shoulder : Structure := Build.rect shId .shoulder (m (-600)) (m (-4)) (m 1600) Q.zero

def laneOf (id : RegionId) (y0 y1 : Q) (dir : Vec) (left right : Option RegionId)
    (ordinal count : Nat) (ml mr : MarkingType) : Structure :=
  { id := id
    kind := .lane
    boundary := some [(m (-600), y0), (m 1600, y0), (m 1600, y1), (m (-600), y1)]
    ways := some [hwyId]
    lane := some { direction := some dir
                   leftNeighbour := left
                   rightNeighbour := right
                   ordinalFromLeft := some ordinal
                   countInDirection := some count
                   markingLeft := some (ml, .white)
                   markingRight := some (mr, .white) } }

/-- Three marked eastbound lanes on one highway. -/
def map3 : List Structure :=
  [ highway
  , laneOf lnL (m 8) (m 12) Build.east none (some lnM) 1 3 .solid .broken
  , laneOf lnM (m 4) (m 8) Build.east (some lnL) (some lnR) 2 3 .broken .broken
  , laneOf lnR Q.zero (m 4) Build.east (some lnM) none 3 3 .broken .solid ]

/-- The same three lanes, the middle one carrying no marking on either side. -/
def map3MiddleUnmarked : List Structure :=
  [ highway
  , laneOf lnL (m 8) (m 12) Build.east none (some lnM) 1 3 .solid .broken
  , laneOf lnM (m 4) (m 8) Build.east (some lnL) (some lnR) 2 3 .none .none
  , laneOf lnR Q.zero (m 4) Build.east (some lnM) none 3 3 .broken .solid ]

/-- The same three lanes, none of them marked on any side. -/
def map3Unmarked : List Structure :=
  [ highway
  , laneOf lnL (m 8) (m 12) Build.east none (some lnM) 1 3 .none .none
  , laneOf lnM (m 4) (m 8) Build.east (some lnL) (some lnR) 2 3 .none .none
  , laneOf lnR Q.zero (m 4) Build.east (some lnM) none 3 3 .none .none ]

/-- One marked eastbound lane, and a shoulder. -/
def mapIdle : List Structure :=
  [ highway
  , laneOf lnS Q.zero (m 4) Build.east none none 1 1 .solid .solid
  , shoulder ]

/-- Two eastbound and two westbound lanes; neither side's lanes are the other's neighbours. -/
def mapTwoWay : List Structure :=
  [ highway
  , laneOf lnE1 (m 4) (m 8) Build.east none (some lnE2) 1 2 .doubleSolid .broken
  , laneOf lnE2 Q.zero (m 4) Build.east (some lnE1) none 2 2 .broken .solid
  , laneOf lnW1 (m 8) (m 12) Build.west none (some lnW2) 1 2 .doubleSolid .broken
  , laneOf lnW2 (m 12) (m 16) Build.west (some lnW1) none 2 2 .broken .solid ]

-- ---------------------------------------------------------------------------------------------
-- The bodies
-- ---------------------------------------------------------------------------------------------
def carHalf : Q × Q × Q := (m 2, m 1, cm 75)
def vanHalf : Q × Q × Q := (m 3, m 1, cm 150)

/-- Position along the carriageway at observation `k` for a body of this speed and offset. -/
def xAt (speed : Q) (k : Nat) (offset : Q) : Q :=
  Q.add (Q.mul speed (Q.ofInt (Int.ofNat k))) offset

/-- The subject's lateral place: the middle lane, straddling at k = 4, then the left-hand lane. -/
def yLeft (k : Nat) : Q := if k ≤ 3 then m 6 else if k = 4 then m 8 else m 10
/-- The subject's lateral place for a movement to the right-hand lane. -/
def yRight (k : Nat) : Q := if k ≤ 3 then m 6 else if k = 4 then m 4 else m 2
/-- The subject's lateral place for a swing onto the shoulder. -/
def yShoulder (k : Nat) : Q := if k ≤ 3 then m 2 else if k = 4 then Q.zero else m (-2)

def subjectAt (speed : Q) (y : Nat → Q) (sg : Nat → Signals → Signals) (k : Nat) : RoadUser :=
  Build.withSignals
    (Build.user 1 [.motorVehicle] (xAt speed k Q.zero, y k) Build.east speed carHalf) (sg k)

def companion (track : TrackId) (speed offset y : Q) (half : Q × Q × Q) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (xAt speed k offset, y) Build.east speed half

-- The signals the vehicle shows: both features are observed at every observation.
def sigNone (_ : Nat) (s : Signals) : Signals :=
  { s with turnIndicator := some .off, handSignal := some .noSignal }
def sigLeft (ks : List Nat) (k : Nat) (s : Signals) : Signals :=
  { s with turnIndicator := some (if ks.contains k then .left else .off), handSignal := some .noSignal }
def sigRight (ks : List Nat) (k : Nat) (s : Signals) : Signals :=
  { s with turnIndicator := some (if ks.contains k then .right else .off), handSignal := some .noSignal }
def sigArmLeft (ks : List Nat) (k : Nat) (s : Signals) : Signals :=
  { s with turnIndicator := some .off, handSignal := some (if ks.contains k then .left else .noSignal) }

-- Occupancy, stated per observation.
def occLeft (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 3 then [(1, hwyId), (1, lnM)]
  else if k = 4 then [(1, hwyId), (1, lnM), (1, lnL)]
  else [(1, hwyId), (1, lnL)]
def occRight (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 3 then [(1, hwyId), (1, lnM)]
  else if k = 4 then [(1, hwyId), (1, lnM), (1, lnR)]
  else [(1, hwyId), (1, lnR)]
def occIdle (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 3 then [(1, hwyId), (1, lnS)]
  else if k = 4 then [(1, hwyId), (1, lnS), (1, shId)]
  else [(1, hwyId), (1, shId)]
def occCross (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 3 then [(1, hwyId), (1, lnE1)]
  else if k = 4 then [(1, hwyId), (1, lnE1), (1, lnW1)]
  else [(1, hwyId), (1, lnW1)]

/-- Eight observations one second apart, with the occupancy of each stated. -/
def trace8 (map : List Structure) (subj : Nat → RoadUser) (others : Nat → List RoadUser)
    (occ : Nat → List (TrackId × RegionId)) : Trace :=
  Build.trace 8 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (subj k :: others k) map [] (some (occ k))

def noOthers (_ : Nat) : List RoadUser := []

-- ---------------------------------------------------------------------------------------------
-- The witnesses
-- ---------------------------------------------------------------------------------------------

/-- `forbid` (violated): On a three-lane carriageway, all lanes marked and running in one direction, a car occupying the middle lane moves at one observation into the left-hand lane, its footprint reaching that lane while its indicator has shown off at every observation of the window behind and no arm signal has been given. The left-hand lane is clear. -/
def forbidTrace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft sigNone) noOthers occLeft

/-- `permit` (compliant): The same carriageway: the car's left indicator has been lit for two seconds before it moves into the left-hand lane, and the nearest road user in that lane is 60 m behind it at the same speed, so the longitudinal clearance exceeds the bound and the centres do not close within the horizon. -/
def permitTrace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigLeft [2, 3]))
    (fun k => [companion 2 (m 20) (m (-60)) (m 10) carHalf k])
    (fun k => occLeft k ++ [(2, hwyId), (2, lnL)])

/-- `idle` (not_applicable): A car on a single-lane one-way street, the lane adjacency recording one lane in its direction, swings onto the shoulder with no signal. The highway has fewer than two lanes in that direction, so the trigger fails and the rule does not engage. -/
def idleTrace : Trace :=
  trace8 mapIdle (subjectAt (m 20) yShoulder sigNone) noOthers occIdle

/-- `blind` (unknown): The forbid scene with the source declaring the turn indicator absent and no arm signal observed: the lanes, the markings and the movement into the left-hand lane are recorded, but whether the appropriate signal was given cannot be read, so the duty is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): The car's left indicator has been lit for three seconds, but as it moves into the left-hand lane a van is 8 m behind it in that lane and closing at 10 m/s: the longitudinal clearance is below the bound and the centres close to less than the minimum clearance within the conflict horizon. -/
def branch_1Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigLeft [1, 2, 3]))
    (fun k => [companion 2 (m 30) (m (-53)) (m 9) vanHalf k])
    (fun k => occLeft k ++ [(2, hwyId), (2, lnL)])

/-- `branch_2` (compliant): The car, alone on the three-lane carriageway with no other road user anywhere in the scene, moves into the left-hand lane with its left indicator lit through the two observations before. The verdict is decided although the only party present is the subject. -/
def branch_2Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigLeft [2, 3])) noOthers occLeft

/-- `branch_3` (violated): The car in the middle lane lights its right indicator and then moves into the left-hand lane, which st.lane_adjacency records as the left neighbour of the lane it leaves. The indication given is not the appropriate one for the movement made. -/
def branch_3Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigRight [2, 3])) noOthers occLeft

/-- `branch_4` (compliant): A car in the left-hand eastbound lane of a two-way street crosses the
    double solid centre line into the westbound carriageway, which the map records as no neighbour
    of the lane it leaves, with its left indicator lit through the two observations before. No
    neighbour of the lane left is entered, so the indication given counts and the movement, made
    with no other road user in the scene, is one that can be made with safety. -/
def branch_4Trace : Trace :=
  trace8 mapTwoWay (subjectAt (m 20) yLeft (sigLeft [2, 3])) noOthers occCross

/-- `branch_5` (violated): The car moves into the clear left-hand lane with its left indicator
    lit, but a van in the right-hand lane lies exactly alongside it: the longitudinal component of
    the gap between the two bodies is zero, far below the clearance the entry must cover. -/
def branch_5Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigLeft [2, 3]))
    (fun k => [companion 2 (m 20) Q.zero (m 2) vanHalf k])
    (fun k => occLeft k ++ [(2, hwyId), (2, lnR)])

/-- `branch_6` (compliant): The car moves into the clear left-hand lane with its left indicator
    lit while a van follows 8 m behind it in the middle lane — the lane it leaves, not the lane it
    enters — so the clearance the standard reads is the clearance to the lane entered. -/
def branch_6Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigLeft [2, 3]))
    (fun k => [companion 2 (m 20) (m (-13)) (m 6) vanHalf k])
    (fun k => occLeft k ++ [(2, hwyId), (2, lnM)])

/-- `branch_7` (compliant): The car, alone on the carriageway, gives no indicator but its driver's
    arm signal means left through the two observations before it moves into the left-hand lane. -/
def branch_7Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigArmLeft [2, 3])) noOthers occLeft

/-- `branch_8` (violated): The car moves into the left-hand lane at 20 m/s with its left
    indicator lit, a lorry standing still in that lane 60 m ahead of it. The entry clearance is
    met at both observations of the movement (60 m, then 40 m, against a bound of 32 m), but at
    the second the centres, under constant velocities, close to within a metre inside the conflict
    horizon: the closest-approach test alone decides this witness. -/
def branch_8Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yLeft (sigLeft [2, 3]))
    (fun k => [companion 2 Q.zero (m 145) (m 9) vanHalf k])
    (fun k => occLeft k ++ [(2, hwyId), (2, lnL)])

/-- `branch_10` (compliant): The middle lane of the carriageway carries no marking on either
    side; the car moves out of it into the marked left-hand lane with no signal at all. The lane
    it leaves is no clearly marked lane, so the words impose no duty on the movement out of it. -/
def branch_10Trace : Trace :=
  trace8 map3MiddleUnmarked (subjectAt (m 20) yLeft sigNone) noOthers occLeft

/-- `branch_11` (not_applicable): A carriageway of three lanes in one direction whose map records
    no marking on any side of any of them. None of its lanes is a clearly marked lane, so the
    trigger fails and the rule does not engage, however the car moves out of the middle lane. -/
def branch_11Trace : Trace :=
  trace8 map3Unmarked (subjectAt (m 20) yLeft sigNone) noOthers occLeft

/-- `branch_9` (compliant): The car moves from the middle lane into the clear right-hand lane,
    which the map records as the right neighbour of the lane it leaves, with its right indicator
    lit through the two observations before. -/
def branch_9Trace : Trace :=
  trace8 map3 (subjectAt (m 20) yRight (sigRight [2, 3])) noOthers occRight

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_223_1b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := some (3000, 7000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.turn_indicator"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_223_1b
