/-
  Witnesses for NRS_484B_250_4_o2.

  Geometry (metres, +x east, +y north), the witness's own figures:
  - intersection `i` (10): x ∈ [0, 20], y ∈ [-10, 10];
  - ego's approach `c` (11): an eastbound lane x ∈ [-60, 0], y ∈ [-4, 0], entering `i`;
  - b's approach `cb` (12): a northbound lane x ∈ [10, 14], y ∈ [-60, -10], entering `i`, marked
    by its stop line (14) at y ∈ [-16, -15] and its crosswalk (15) at y ∈ [-14, -11];
  - a lane `far` (13) away from the junction, x ∈ [-60, -40], y ∈ [30, 34], governed by an
    operating signal head (2) showing circular green;
  - where the scene has one, the stop line marking `c` (16) at x ∈ [-2, -1], or the crosswalk
    marking `c` (17) at x ∈ [-5, -1].
  Ego (track 1) drives east along y = -2; b (track 2) drives north along x = 12. Both are motor
  vehicles of half-length 2 m and half-width 1 m. Observations every second from t = 0.
  The ego stop at the line is at x = -5 (body 1 m short of the line), before the crosswalk at
  x = -8 (body 1 m short of it), and before the intersection at x = -4 (body 2 m short of it), all
  within the 3 m stop-point tolerance; the far halt of `branch_3` is at x = -35 (31 m short of the
  line). In the violated scenes b's projected path meets ego's centre exactly (closest approach
  0 m within 2 s, against a 3 m clearance and a 3 s horizon) while ego moves at 5 m/s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: ego ↦ 1

def iId : RegionId := 10
def cId : RegionId := 11
def cbId : RegionId := 12
def farId : RegionId := 13
def sbId : RegionId := 14
def xwbId : RegionId := 15
def slId : RegionId := 16
def xwId : RegionId := 17

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def inter : Structure := Build.rect iId .intersection (m 0) (m (-10)) (m 20) (m 10)
def laneC : Structure := Build.lane cId (box (-60) (-4) 0 0) Build.east (enters := some iId)
def laneCb : Structure := Build.lane cbId (box 10 (-60) 14 (-10)) Build.north (enters := some iId)
def laneFar : Structure := Build.lane farId (box (-60) 30 (-40) 34) Build.west
def lineCb : Structure :=
  { Build.rect sbId .stopLine (m 10) (m (-16)) (m 14) (m (-15)) with
    entranceOf := [cbId], entranceObserved := true }
def walkCb : Structure :=
  { Build.rect xwbId .crosswalk (m 10) (m (-14)) (m 14) (m (-11)) with
    entranceOf := [cbId], entranceObserved := true, marked := some true }
def lineC : Structure :=
  { Build.rect slId .stopLine (m (-2)) (m (-4)) (m (-1)) (m 0) with
    entranceOf := [cId], entranceObserved := true }
def walkC : Structure :=
  { Build.rect xwId .crosswalk (m (-5)) (m (-4)) (m (-1)) (m 0) with
    entranceOf := [cId], entranceObserved := true, marked := some true }

def base : List Structure := [inter, laneC, laneCb, laneFar, lineCb, walkCb]
def withLine : List Structure := base ++ [lineC]
def withCrosswalk : List Structure := base ++ [walkC]

/-- The head governing `gov`, installed and uncovered, dark. -/
def darkSignal (gov : List RegionId) : Device :=
  { Build.signal 1 gov [.dark] with uncovered := some true, inoperative := some true }
/-- The head governing `gov`, operating. -/
def liveSignal (gov : List RegionId) (shows : List SignalIndication) : Device :=
  { Build.signal 1 gov shows with uncovered := some true, inoperative := some false }
/-- The operating head of the far lane. -/
def farSignal : Device :=
  { Build.signal 2 [farId] [.circularGreen] with uncovered := some true, inoperative := some false }

def egoAt (x v : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m (-2)) Build.east (mps v) (m 2, m 1, m 1)
def otherAt (y v : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (m 12, m y) Build.north (mps v) (m 2, m 1, m 1)

/-- A trace from ego's (x, speed) per second, b's (y, speed) per second when present, the
    structures, and the devices per instant. -/
def mkTrace (ego : List (Int × Int)) (other : List (Int × Int)) (structures : List Structure)
    (devices : Nat → List Device) : Trace :=
  Build.trace ego.length 0 (Units.seconds 1) fun k t =>
    let (ex, ev) := ego.getD k (0, 0)
    let users := [egoAt ex ev] ++
      (if other.isEmpty then [] else
        let (oy, ov) := other.getD k (0, 0)
        [otherAt oy ov])
    Build.scene t (some 1) users structures (devices k)

/-- Ego halts at the line at 2–3 s, moves off at 4 s, enters `i` at 5 s. -/
def egoStopsAtLine : List (Int × Int) := [(-20, 5), (-12, 5), (-5, 0), (-5, 0), (-3, 2), (2, 5), (7, 5)]
/-- b crosses `i` northbound at 3 m/s, inside it from 5 s. -/
def otherCrossing : List (Int × Int) := [(-23, 3), (-20, 3), (-17, 3), (-14, 3), (-11, 3), (-8, 3), (-5, 3)]

/-- `forbid` (violated): The signal governing ego's approach c is inoperative. Ego comes to rest at the stop line marking c, then enters the intersection while a vehicle b that is already within the intersection crosses ego's path; projected at constant velocities their centres approach within p.conflict_horizon below p.conflict_clearance while ego moves. -/
def forbidTrace : Trace :=
  mkTrace egoStopsAtLine otherCrossing withLine fun _ => [darkSignal [cId], farSignal]

/-- Ego waits at the line from 2 s to 4 s, moves off at 5 s, enters `i` at 6 s. -/
def egoWaits : List (Int × Int) := [(-20, 5), (-12, 5), (-5, 0), (-5, 0), (-5, 0), (-3, 2), (2, 5), (7, 5)]

/-- `permit` (compliant): Same scene; ego stays at rest at the line until b has cleared the intersection, then proceeds with no projected conflict. -/
def permitTrace : Trace :=
  mkTrace egoWaits [(-28, 8), (-20, 8), (-12, 8), (-4, 8), (4, 8), (12, 8), (20, 8), (28, 8)]
    withLine fun _ => [darkSignal [cId], farSignal]

/-- `idle` (not_applicable): The signal governing c shows circular_red then circular_green; it is not inoperative when ego enters. -/
def idleTrace : Trace :=
  mkTrace egoWaits [] withLine fun k =>
    [liveSignal [cId] (if k < 5 then [.circularRed] else [.circularGreen]), farSignal]

/-- `blind` (unknown): Scene of forbid, but the source declares dev.inoperative absent. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): Signal inoperative. Vehicle b came to rest at its own stop line before ego came to rest at ego's line; b then moves toward the intersection while ego enters, and their projected closest approach falls below the clearance within the horizon.
    b rests at its line from 1 s (ego from 2 s); at 5 s ego enters with b still at rest (no
    conflict); at 6 s b moves off at 9 m/s, still on `cb`, onto ego's path. -/
def branch_1Trace : Trace :=
  mkTrace egoStopsAtLine [(-30, 5), (-19, 0), (-19, 0), (-19, 0), (-19, 0), (-19, 0), (-11, 9)]
    withLine fun _ => [darkSignal [cId], farSignal]

/-- `branch_2` (compliant): Signal inoperative; ego stops at the line and crosses with no other road user in the scene. -/
def branch_2Trace : Trace :=
  mkTrace egoWaits [] withLine fun _ => [darkSignal [cId], farSignal]

/-- `branch_3` (not_applicable): As forbid, except that ego's only halt was far upstream of the stop line, outside its stopping zone, and ego did not halt at the line: no such stop was made, so this duty does not arise (NRS_484B_250_4_o1 judges the missing halt).
    Ego starts before `c`, halts at x = -35 at 2–3 s and enters `i` at 5 s without halting again. -/
def branch_3Trace : Trace :=
  mkTrace [(-70, 5), (-40, 5), (-35, 0), (-35, 0), (-12, 8), (2, 5), (7, 5)] otherCrossing
    withLine fun _ => [darkSignal [cId], farSignal]

/-- `branch_4` (violated): no stop line marks c; ego halts short of the crosswalk marking c, the
    inoperative head governs the intersection only, and ego enters while b crosses its path. -/
def branch_4Trace : Trace :=
  mkTrace [(-20, 5), (-8, 0), (-8, 0), (-3, 3), (2, 5), (7, 5)]
    [(-20, 3), (-17, 3), (-14, 3), (-11, 3), (-8, 3), (-5, 3)]
    withCrosswalk fun _ => [darkSignal [iId], farSignal]

/-- `branch_5` (violated): neither a stop line nor a crosswalk marks c; ego halts outside the
    intersection at c's entrance end, then enters while b crosses its path. -/
def branch_5Trace : Trace :=
  mkTrace [(-20, 5), (-4, 0), (-4, 0), (2, 5), (7, 5)]
    [(-17, 3), (-14, 3), (-11, 3), (-8, 3), (-5, 3)]
    base fun _ => [darkSignal [cId], farSignal]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("ego", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.inoperative"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o2
