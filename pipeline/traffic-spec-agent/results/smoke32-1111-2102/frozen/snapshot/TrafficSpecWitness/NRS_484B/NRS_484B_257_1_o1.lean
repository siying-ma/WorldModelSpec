/-
  Witnesses for NRS_484B_257_1_o1.

  Geometry (x east, y north, metres). Ego (track 1, a motor vehicle, half-length 2 m, half-width
  1 m) drives east along y = 0 on lane c (region 10, x ∈ [-100, 0], y ∈ [-2, 2], direction east,
  entering intersection 20). The intersection i (region 20) is x ∈ [0, 20], y ∈ [-10, 10]. A
  crossing lane (region 12, x ∈ [8, 12], y ∈ [-60, -10], direction north) also enters i.
  - Stop line of c (30): x ∈ [-6, -5.5]. Ego's body is within 3 m of it (the reading's
    p.stop_point_tolerance) for reference points x ∈ [-11, -5.5]; a halt at x = -9 leaves 1 m.
  - Crosswalk of c (31): x ∈ [-4, -1]; a halt at x = -7 leaves 1 m, the footprint off it.
  - Without either, the place is i's edge x = 0; a halt at x = -4 leaves 2 m.
  - The crossing lane's stop line (32) and crosswalk (33) mark lane 12 only: they make "no stop line
    / no crosswalk marks c" decided, not vacuous.
  Observations are 1 s apart; each scene lists ego's x (m), speed (m/s) and longitudinal
  acceleration (m/s²); the path length is the distance between successive positions, summed.
  Ego occupies the regions containing its reference point. Every figure here is the witness's own
  and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: ego ↦ 1

/-- One observation of ego: position x (m), speed (m/s), acceleration along its heading (m/s²),
    and whether it is moving backwards (velocity west while it points east). -/
structure Obs where
  x : Int
  v : Int
  a : Int := 0
  back : Bool := false

def rest : Obs := { x := 0, v := 0 }

/-- Distance travelled from the first observation to observation `k`. -/
def pathAt (obs : List Obs) (k : Nat) : Int :=
  ((List.range k).map fun j => Int.ofNat ((obs.getD (j + 1) rest).x - (obs.getD j rest).x).natAbs).foldl (· + ·) 0

def egoAt (o : Obs) (path : Int) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m o.x, Q.zero) Build.east (Units.metresPerSecond o.v) (m 2, m 1, m 1)
      (some (m path)))
    fun k => { k with
      accelLongitudinal := some (Units.metresPerSecondSq o.a)
      velocity := if o.back then some (Build.scale Build.west (Units.metresPerSecond o.v)) else k.velocity }

def run (obs : List Obs) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace obs.length 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [egoAt (obs.getD k rest) (pathAt obs k)] structures devices

-- Structures
def laneC : Structure :=
  Build.lane 10 [(m (-100), m (-2)), (m 0, m (-2)), (m 0, m 2), (m (-100), m 2)] Build.east (enters := some 20)
def laneX : Structure :=
  Build.lane 12 [(m 8, m (-60)), (m 12, m (-60)), (m 12, m (-10)), (m 8, m (-10))] Build.north (enters := some 20)
def isect : Structure := Build.rect 20 .intersection (m 0) (m (-10)) (m 20) (m 10)
def lineC : Structure :=
  { Build.rect 30 .stopLine (m (-6)) (m (-2)) (cm (-550)) (m 2) with entranceOf := [10], entranceObserved := true }
def walkC : Structure :=
  { Build.rect 31 .crosswalk (m (-4)) (m (-2)) (m (-1)) (m 2) with
      entranceOf := [10], entranceObserved := true, marked := some true }
def lineX : Structure :=
  { Build.rect 32 .stopLine (m 8) (m (-13)) (m 12) (cm (-1250)) with entranceOf := [12], entranceObserved := true }
def walkX : Structure :=
  { Build.rect 33 .crosswalk (m 8) (m (-12)) (m 12) (m (-11)) with
      entranceOf := [12], entranceObserved := true, marked := some true }

def withLine : List Structure := [laneC, laneX, isect, lineC]
def withWalk : List Structure := [laneC, laneX, isect, walkC, lineX]
def bare : List Structure := [laneC, laneX, isect, lineX, walkX]

-- Devices
def stopC : Device := Build.sign 40 .stopSign [10]
def yieldC : Device := Build.sign 41 .yieldSign [10]
def officerAtI : Device :=
  { Build.device 50 .humanDirection [20] with humanRole := some .policeOfficer, humanIndication := some .proceed }
def officerAtX : Device :=
  { Build.device 51 .humanDirection [12] with humanRole := some .policeOfficer, humanIndication := some .proceed }
def signalAtX : Device :=
  { Build.signal 60 [12] [.circularGreen] with uncovered := some true, inoperative := some false }
def darkSignalAtI : Device :=
  { Build.signal 61 [20] [.dark] with uncovered := some true, inoperative := some true }

-- Motions
/-- Through at 10 m/s from beyond the stopping zone into i. -/
def runThrough : List Obs :=
  [ { x := -50, v := 10 }, { x := -30, v := 10 }, { x := -15, v := 10 }, { x := -3, v := 10 },
    { x := 3, v := 10 }, { x := 12, v := 10 } ]
/-- Halt at the stop line (x = -9), then into i. -/
def haltAtLine : List Obs :=
  [ { x := -50, v := 10 }, { x := -30, v := 10 }, { x := -15, v := 6, a := -2 }, { x := -9, v := 0 },
    { x := -9, v := 0 }, { x := -3, v := 4 }, { x := 3, v := 6 }, { x := 12, v := 6 } ]

/-- `forbid` (violated): A stop sign governs ego's approach lane c and a stop line marks c; no officer and no signal. Ego approaches from beyond the stopping zone and enters the intersection without being at rest at any observation since the approach start. -/
def forbidTrace : Trace := run runThrough withLine [stopC]

/-- `permit` (compliant): Same scene; ego comes to rest within p.stop_point_tolerance of the line, short of it, then enters. -/
def permitTrace : Trace := run haltAtLine withLine [stopC]

/-- `idle` (not_applicable): No stop sign or yield sign governs ego's approach; ego enters an intersection whose approaches carry no signs. -/
def idleTrace : Trace := run runThrough withLine []

/-- `blind` (unknown): Scene of forbid, but the source declares dev.governs absent: whether the stop sign governs ego's approach cannot be read. -/
def blindTrace : Trace := run runThrough withLine [stopC]

/-- `history_boundary` (unknown): Stop sign governs c, stop line marks c. The recording begins with ego already within the stopping zone of the line moving slowly; ego enters without being at rest at any recorded observation; the approach start precedes the recording and no previous entry is recorded. -/
def history_boundaryTrace : Trace :=
  run [ { x := -10, v := 3 }, { x := -7, v := 3 }, { x := -4, v := 3 }, { x := 3, v := 4 } ] withLine [stopC]

/-- `branch_1` (compliant): Only a yield sign governs c. Ego decelerates on the approach within p.yield_slowing_distance before the stopping zone of the line and enters without stopping. -/
def branch_1Trace : Trace :=
  run [ { x := -60, v := 12 }, { x := -48, v := 12 }, { x := -36, v := 12 }, { x := -26, v := 9, a := -3 },
        { x := -18, v := 7, a := -2 }, { x := -10, v := 6 }, { x := -3, v := 6 }, { x := 3, v := 6 } ]
    withLine [yieldC]

/-- `branch_2` (not_applicable): A stop sign governs c, but at ego's entry a police officer (dev.human_direction role police_officer) directs traffic at the intersection. -/
def branch_2Trace : Trace := run runThrough withLine [stopC, officerAtI]

/-- `branch_3` (violated): Only a yield sign governs c. Ego keeps a constant speed from beyond the stopping zone into the intersection, never decelerating and never at rest. -/
def branch_3Trace : Trace :=
  run [ { x := -70, v := 12 }, { x := -58, v := 12 }, { x := -46, v := 12 }, { x := -34, v := 12 },
        { x := -22, v := 12 }, { x := -10, v := 12 }, { x := -3, v := 12 }, { x := 3, v := 12 } ]
    withLine [yieldC]

/-- `branch_4` (violated): stop sign on c; a dark (inoperative) signal head governs i, and an
    operating signal head and a police officer govern only the crossing lane; ego runs the stop. -/
def branch_4Trace : Trace := run runThrough withLine [stopC, darkSignalAtI, signalAtX, officerAtX]

/-- `branch_5` (compliant): no stop line marks c (the only one marks the crossing lane); ego halts
    short of the crosswalk of c, within the tolerance and off it, then enters. -/
def branch_5Trace : Trace :=
  run [ { x := -50, v := 10 }, { x := -30, v := 10 }, { x := -15, v := 6, a := -2 }, { x := -7, v := 0 },
        { x := -7, v := 0 }, { x := -3, v := 4 }, { x := 3, v := 6 } ]
    withWalk [stopC]

/-- `branch_6` (violated): the crosswalk scene of branch_5; ego runs the stop. -/
def branch_6Trace : Trace := run runThrough withWalk [stopC]

/-- `branch_7` (compliant): neither a stop line nor a crosswalk marks c (those present mark the
    crossing lane); ego halts 2 m short of i, then enters. -/
def branch_7Trace : Trace :=
  run [ { x := -50, v := 10 }, { x := -30, v := 10 }, { x := -15, v := 6, a := -2 }, { x := -4, v := 0 },
        { x := -4, v := 0 }, { x := 3, v := 6 } ]
    bare [stopC]

/-- `branch_8` (violated): the scene of branch_7; ego runs the stop. -/
def branch_8Trace : Trace := run runThrough bare [stopC]

/-- `branch_9` (violated): ego halts at the line and enters (complied), backs out onto c within the
    stopping zone, and enters again without halting: the search for the second entry ends at the
    first entry. -/
def branch_9Trace : Trace :=
  run [ { x := -50, v := 10 }, { x := -30, v := 10 }, { x := -15, v := 6, a := -2 }, { x := -9, v := 0 },
        { x := -3, v := 4 }, { x := 3, v := 5 }, { x := -3, v := 3, back := true }, { x := 3, v := 4 } ]
    withLine [stopC]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_1_o1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "history_boundary" history_boundaryTrace (.unknown []) (boundary := "the approach start: the observation at which ego, on c, was last outside the stop line's stopping zone upstream, which precedes the recording")
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .violated
  , witness "branch_9" branch_9Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_1_o1
