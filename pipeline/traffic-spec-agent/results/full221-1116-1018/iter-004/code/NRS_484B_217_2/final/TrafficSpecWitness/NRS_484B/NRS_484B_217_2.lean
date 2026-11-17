/-
  Witnesses for NRS_484B_217_2.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - highway 10: x −400…400 m, y −8…8 m; centre line 11: a 0.2 m strip along y = 0 (on way 10);
    eastbound lane 12: y −3.7…−0.1; westbound lane 13: y 0.1…3.7; both with the given left marking.
  - the subject (track 1) is a motor vehicle 5.0 m long and 1.8 m wide (half-width 0.9 m), so the
    crossing bound is an offset of the centre line below 0.9 − 0.3 = 0.6 m.
  - short scenes (forbid, idle, blind, branch_6): three instants 1 s apart; the subject moves from
    y = −1.85 (centre line 1.75 m to its left) through y = −0.5 (offset 0.4 m: crossing) to y = 1.1
    (offset −1.0 m). Permit keeps y = −1.0 (offset 0.9 m).
  - branch scenes: 20 instants 1 s apart, then the last scene repeated for 11 s so that the turn
    window ahead of the crossing is covered. The subject drives east at 10 m/s along y = −1.85 from
    x = −120 (k = 0…16, x = 40 at k = 16), crosses at k = 17 (x = 48, y = −0.5, heading east:
    offset 0.4 m) and k = 18 (x = 51, y = 6, heading north: offset 0; its body, y 3.5…8.5, is
    across lane 13 and already entering the exit region), and at k = 19 is at (51, 12) in region
    20 (a driveway entrance or an intersection, x 46…56, y 8…20) or region 40 (a side highway,
    x 46…56, y 8…200), and on highway 10 no longer.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_217_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_217_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def solidYellow : MarkingType × MarkingColour := (.solid, .yellow)
def brokenWhite : MarkingType × MarkingColour := (.broken, .white)

def hwy : Structure := Build.rect 10 .highway (m (-400)) (m (-8)) (m 400) (m 8)
def centre : Structure :=
  { Build.rect 11 .centreLine (m (-400)) (cm (-10)) (m 400) (cm 10) with ways := some [10] }
def laneE (mk : MarkingType × MarkingColour) : Structure :=
  { Build.rect 12 .lane (m (-400)) (cm (-370)) (m 400) (cm (-10)) with
    ways := some [10]
    lane := some { direction := some Build.east, markingLeft := some mk } }
def laneW (mk : MarkingType × MarkingColour) : Structure :=
  { Build.rect 13 .lane (m (-400)) (cm 10) (m 400) (cm 370) with
    ways := some [10]
    lane := some { direction := some Build.west, markingLeft := some mk } }
def road (mk : MarkingType × MarkingColour) : List Structure := [hwy, centre, laneE mk, laneW mk]

def driveway : Structure :=
  { Build.rect 20 .drivewayOrAlleyEntrance (m 46) (m 8) (m 56) (m 20) with ways := some [10] }
def junction : Structure :=
  { Build.rect 20 .intersection (m 46) (m 8) (m 56) (m 20) with ways := some [10] }
def sideHighway : Structure := Build.rect 40 .highway (m 46) (m 8) (m 56) (m 200)

def carExtent : Q × Q × Q := (cm 250, cm 90, cm 75)

def subj (p : Vec) (h : Vec) (v : Q) (path : Q) (ind : TurnIndicatorState) (hand : HandSignal) : RoadUser :=
  Build.withSignals (Build.user 1 [.motorVehicle] p h v carExtent (some path))
    (fun s => { s with turnIndicator := some ind, handSignal := some hand })

-- ---------------------------------------------------------------------------------------------
-- Short crossing scenes
-- ---------------------------------------------------------------------------------------------
def crossY : Nat → Q
  | 0 => cm (-185)
  | 1 => cm (-50)
  | _ => cm 110

def crossOcc : Nat → List (TrackId × RegionId)
  | 0 => [(1, 10), (1, 12)]
  | 1 => [(1, 10), (1, 11), (1, 12), (1, 13)]
  | _ => [(1, 10), (1, 13)]

def crossingTrace (mk : MarkingType × MarkingColour) (devices : List Device)
    (others : Nat → List RoadUser) (othersOcc : Nat → List (TrackId × RegionId)) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      (subj (m (10 * (k : Int)), crossY k) Build.east (mps 10) (m (11 * (k : Int))) .off .noSignal :: others k)
      (road mk) devices
      (occupies := some (crossOcc k ++ othersOcc k))

/-- The slower vehicle being overtaken (track 2), ahead in lane 12 at 5 m/s. -/
def slowCar (k : Nat) : List RoadUser :=
  [Build.user 2 [.motorVehicle] (m (15 + 5 * (k : Int)), cm (-185)) Build.east (mps 5) carExtent]

/-- `forbid` (violated): The subject vehicle occupies a lane whose left st.lane_marking is solid yellow; it moves left until prim.region_lateral_offset of the centre line is -1.0 m to overtake a slower vehicle; int.left_turn is declared false at every region and it stays on the same highway. -/
def forbidTrace : Trace :=
  crossingTrace solidYellow [] slowCar (fun _ => [(2, 10), (2, 12)])

/-- `permit` (compliant): The subject occupies the same no-passing lane (left marking solid yellow) and keeps the centre line 0.9 m to its left with a body width of 1.8 m plus margin: the offset stays above half its width minus the tolerance. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [subj (m (10 * (k : Int)), cm (-100)) Build.east (mps 10) (m (10 * (k : Int))) .off .noSignal]
      (road solidYellow) []
      (occupies := some [(1, 10), (1, 12)])

/-- `idle` (not_applicable): The subject's lane has a broken white left marking and no no_passing dev.zone_sign governs any region it occupies; it crosses the centre line to overtake. -/
def idleTrace : Trace :=
  crossingTrace brokenWhite [] slowCar (fun _ => [(2, 10), (2, 12)])

/-- `blind` (unknown): The source does not observe st.lane_marking and no zone sign is in the scene; the subject's body reaches past the centre line. -/
def blindTrace : Trace :=
  crossingTrace solidYellow [] (fun _ => []) (fun _ => [])

/-- `branch_6` (violated): the lane markings are broken white, but a no_passing zone sign (not an
    end sign) governs the subject's lane 12; the subject crosses the centre line without signal. -/
def branch_6Trace : Trace :=
  crossingTrace brokenWhite
    [Build.zoneSign 30 [12] .noPassing false (some {})] (fun _ => []) (fun _ => [])

-- ---------------------------------------------------------------------------------------------
-- Turning scenes
-- ---------------------------------------------------------------------------------------------
structure Cfg where
  exit : Structure := driveway
  intends : Bool := true
  indicatorFrom : Nat := 4
  hand : HandSignal := .noSignal
  others : Nat → List RoadUser := fun _ => []
  othersOcc : Nat → List (TrackId × RegionId) := fun _ => []

def branchSubject (cfg : Cfg) (k : Nat) : RoadUser :=
  let ind : TurnIndicatorState := if k ≥ cfg.indicatorFrom then .left else .off
  if k ≤ 16 then
    subj (m (-120 + 10 * (k : Int)), cm (-185)) Build.east (mps 10) (m (10 * (k : Int))) ind cfg.hand
  else if k = 17 then
    subj (m 48, cm (-50)) Build.east (mps 10) (m 169) ind cfg.hand
  else if k = 18 then
    subj (m 51, m 6) Build.north (mps 5) (m 177) ind cfg.hand
  else
    subj (m 51, m 12) Build.north (mps 5) (m 183) ind cfg.hand

def branchOcc (exitId : RegionId) (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 16 then [(1, 10), (1, 12)]
  else if k = 17 then [(1, 10), (1, 11), (1, 12), (1, 13)]
  else if k = 18 then [(1, 10), (1, 13), (1, exitId)]
  else [(1, exitId)]

def branchTrace (cfg : Cfg) : Trace :=
  Build.pad
    (Build.trace 20 0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        (branchSubject cfg k :: cfg.others k)
        (road solidYellow ++ [cfg.exit]) []
        (occupies := some (branchOcc cfg.exit.id k ++ cfg.othersOcc k))
        (intents := if cfg.intends then [{ vehicle := 1, target := 20, values := [("int.left_turn", true)] }] else []))
    Q.zero (Units.seconds 11) (Units.seconds 1)

/-- An oncoming car (track 2) in lane 13 at 10 m/s west; at k = 17 it is 40 m ahead and 1.0 m to the
    left of the subject: closest approach in 2 s at a centre distance of 1.0 m. -/
def oncomingCar (k : Nat) : List RoadUser :=
  [Build.user 2 [.motorVehicle] (m (88 - 10 * ((k : Int) - 17)), cm 50) Build.west (mps 10) carExtent]
def oncomingOcc (_k : Nat) : List (TrackId × RegionId) := [(2, 10), (2, 13)]

/-- A following car (track 3) in lane 12 at 18 m/s east; at k = 17 it is 20 m behind and 1.35 m to
    the right: closest approach in 2.5 s at a centre distance of 1.35 m. -/
def followingCar (k : Nat) : List RoadUser :=
  [Build.user 3 [.motorVehicle] (m (28 + 18 * ((k : Int) - 17)), cm (-185)) Build.east (mps 18) carExtent]
def followingOcc (_k : Nat) : List (TrackId × RegionId) := [(3, 10), (3, 12)]

/-- A pedestrian (track 4) standing in lane 13 at (66, 0.5), facing north: at k = 17 the subject's
    centre passes it in 1.8 s at 1.0 m; it is neither oncoming nor following. -/
def standingPedestrian (_k : Nat) : List RoadUser :=
  [Build.user 4 [.pedestrian] (m 66, cm 50) Build.north Q.zero (cm 30, cm 30, cm 85)]
def pedestrianOcc (_k : Nat) : List (TrackId × RegionId) := [(4, 10), (4, 13)]

/-- A car (track 5) alongside on the left at the subject's speed: at k = 17 its body (y 0.4…2.0)
    touches the subject's (y −1.4…0.4); no closest approach (equal velocities), not behind. -/
def alongsideCar (k : Nat) : List RoadUser :=
  [Build.user 5 [.motorVehicle] (m (48 + 10 * ((k : Int) - 17)), cm 120) Build.east (mps 10) (cm 250, cm 80, cm 75)]
def alongsideOcc (_k : Nat) : List (TrackId × RegionId) := [(5, 10), (5, 13)]

/-- `branch_1` (compliant): In the no-passing zone the subject's int.left_turn is declared true at a driveway_or_alley_entrance; its left indicator has been on for the last 120 m and NRS_484B_413_2 is complied with; it crosses the centre line; no other road user is in the scene. -/
def branch_1Trace : Trace := branchTrace {}

/-- `branch_2` (violated): As branch_1 but sig.turn_indicator is off and sig.hand_signal no_signal at the observation before the crossing. -/
def branch_2Trace : Trace := branchTrace { indicatorFrom := 100 }

/-- `branch_3` (violated): As branch_1 but an oncoming vehicle (rel.oncoming) has a closest approach to the subject in 2 s at a centre distance of 1 m. -/
def branch_3Trace : Trace := branchTrace { others := oncomingCar, othersOcc := oncomingOcc }

/-- `branch_4` (violated): As branch_1 but the left indicator came on only 10 m before the crossing, so NRS_484B_413_2 is violated although a signal was given at the observation before the crossing. -/
def branch_4Trace : Trace := branchTrace { indicatorFrom := 16 }

/-- `branch_5` (compliant): In the zone the subject signals left, crosses the centre line and within the turn window occupies another highway and no longer the zone's highway; no oncoming or following road user has a conflicting closest approach. -/
def branch_5Trace : Trace := branchTrace { exit := sideHighway, intends := false }

/-- `branch_7` (compliant): as branch_5, but the left signal is an arm signal; the indicator stays off. -/
def branch_7Trace : Trace :=
  branchTrace { exit := sideHighway, intends := false, indicatorFrom := 100, hand := .left }

/-- `branch_8` (violated): as branch_5, with the oncoming car of branch_3 (impediment to oncoming traffic). -/
def branch_8Trace : Trace :=
  branchTrace { exit := sideHighway, intends := false, others := oncomingCar, othersOcc := oncomingOcc }

/-- `branch_9` (violated): as branch_5, with a faster car following in the subject's lane (impediment to following traffic). -/
def branch_9Trace : Trace :=
  branchTrace { exit := sideHighway, intends := false, others := followingCar, othersOcc := followingOcc }

/-- `branch_10` (compliant): as branch_1, but the left turn is declared at an intersection. -/
def branch_10Trace : Trace := branchTrace { exit := junction }

/-- `branch_11` (violated): as branch_1, with a pedestrian standing in the opposing lane whom the
    subject's centre approaches within the horizon: not safe, though no oncoming or following traffic is impeded. -/
def branch_11Trace : Trace := branchTrace { others := standingPedestrian, othersOcc := pedestrianOcc }

/-- `branch_12` (violated): as branch_1, with a car alongside whose body touches the subject's at the crossing: not safe. -/
def branch_12Trace : Trace := branchTrace { others := alongsideCar, othersOcc := alongsideOcc }

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_217_2"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_marking"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated
  , witness "branch_10" branch_10Trace .compliant
  , witness "branch_11" branch_11Trace .violated
  , witness "branch_12" branch_12Trace .violated ]

end TrafficSpecWitness.NRS_484B_217_2
