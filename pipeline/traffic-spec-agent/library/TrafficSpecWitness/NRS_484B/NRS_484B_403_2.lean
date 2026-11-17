/-
  Witnesses for NRS_484B_403_2.

  Two layouts, x east, y north, metres.
  * Junction (forbid, permit, idle, blind, branch_1, branch_2, branch_3): intersection 200 is
    x ∈ [-20, 20], y ∈ [0, 30]. Lane 101 runs north, x ∈ [0, 4], y ∈ [-60, 0], and enters 200;
    lane 102 runs south, x ∈ [-4, 0], y ∈ [-60, 0], leaving 200. Lane 103 runs west, x ∈ [20, 60],
    y ∈ [2, 6], and enters 200 from the east.
  * Mid-block (occasion_s1, occasion_s1_outside): no intersection. Lane 111 runs north,
    x ∈ [0, 4], y ∈ [-60, -20], and leads into lane 117, x ∈ [0, 4], y ∈ [-20, 40]; lane 112 runs
    south, x ∈ [-4, 0], y ∈ [-60, 40].
  Device 10 is a regulatory sign of code no_u_turn (conditions empty unless stated).

  The subject (track 1, a motor vehicle, 5 m × 2 m) is sampled once a second for 12 to 13 s; the
  trace is padded 12 s before with its first scene so that the 10 s turn window behind every judged
  instant is covered, and each witness speaks about the unpadded instants only. The yaw rate at a
  scene is held over the second before it, so headings stay on the compass points: a U-turn is
  90 deg/s, a 0 deg/s pause, 90 deg/s again (180°, centre of the 135°–225° band), then 0 deg/s
  (≤ 3 deg/s tolerance), recognized at that last scene; a left turn is one 90 deg/s second (90°,
  far below 135°). The civil time is a Wednesday, 14:00.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_403_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_403_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def degs (n : Int) : Q := Units.degrees n
def pt (x y : Int) : Vec := (m x, m y)

/-- The subject: a motor vehicle at a position, heading and yaw rate. -/
def subj (classes : List RoadUserClass) (p : Vec) (h : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 classes p h (Units.metresPerSecond 6) (cm 250, cm 100, cm 75))
    fun k => { k with yawRate := some yaw }

def wednesdayAfternoon : Env :=
  { civilTime := some { year := 2026, month := 11, day := 18, weekday := 2, minuteOfDay := 840 } }

-- Junction layout.
def laneN : Structure := Build.lane 101 [pt 0 (-60), pt 4 (-60), pt 4 0, pt 0 0] Build.north (enters := some 200)
def laneS : Structure := Build.lane 102 [pt (-4) (-60), pt 0 (-60), pt 0 0, pt (-4) 0] Build.south
def laneE : Structure := Build.lane 103 [pt 20 2, pt 60 2, pt 60 6, pt 20 6] Build.west (enters := some 200)
def junction : Structure := Build.rect 200 .intersection (m (-20)) (m 0) (m 20) (m 30)
def junctionLayout : List Structure := [laneN, laneS, laneE, junction]

-- Mid-block layout.
def laneN1 : Structure :=
  Build.lane 111 [pt 0 (-60), pt 4 (-60), pt 4 (-20), pt 0 (-20)] Build.north (leadsTo := some [117])
def laneN2 : Structure := Build.lane 117 [pt 0 (-20), pt 4 (-20), pt 4 40, pt 0 40] Build.north
def laneS2 : Structure := Build.lane 112 [pt (-4) (-60), pt 0 (-60), pt 0 40, pt (-4) 40] Build.south
def midBlockLayout : List Structure := [laneN1, laneN2, laneS2]

/-- A no-U-turn sign governing the given regions, with the given legend conditions. -/
def noUTurn (governs : List RegionId) (cond : Conditions := {}) (code : SignCode := .noUTurn) : Device :=
  { Build.sign 10 .regulatorySign governs with code := some code, conditions := some cond }

/-- Morning-peak legend: Monday to Friday, 07:00–09:00 only. -/
def morningPeak : Conditions := { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 540 }] }

/-- A trace from per-second samples (position, heading, yaw rate), padded 12 s before. -/
def mkTrace (steps : List (Vec × Vec × Q)) (structs : List Structure) (devs : List Device)
    (classes : List RoadUserClass := [.motorVehicle]) : Trace :=
  Build.pad
    (Build.trace steps.length 0 (Units.seconds 1) fun k t =>
      let (p, h, y) := steps.getD k (pt 0 0, Build.north, degs 0)
      Build.scene t (some 1) [subj classes p h y] structs devs (env := wednesdayAfternoon))
    (Units.seconds 12) (Units.seconds 0) (Units.seconds 1)

/-- U-turn beginning in lane 101 (k = 3), through the junction, out on lane 102; recognized at k = 6. -/
def uTurnAtJunction : List (Vec × Vec × Q) :=
  [ (pt 2 (-20), Build.north, degs 0)
  , (pt 2 (-14), Build.north, degs 0)
  , (pt 2 (-8), Build.north, degs 0)
  , (pt 2 (-3), Build.west, degs 90)
  , (pt 0 4, Build.west, degs 0)
  , (pt (-2) 5, Build.south, degs 90)
  , (pt (-2) (-2), Build.south, degs 0)
  , (pt (-2) (-8), Build.south, degs 0)
  , (pt (-2) (-14), Build.south, degs 0)
  , (pt (-2) (-20), Build.south, degs 0)
  , (pt (-2) (-26), Build.south, degs 0)
  , (pt (-2) (-32), Build.south, degs 0) ]

/-- `forbid` (violated): A dev.regulatory_sign of code no_u_turn with empty conditions governs the subject's approach lane; the subject begins turning in that lane, enters the intersection and reverses its heading (heading change in the reversal band, then yaw below tolerance). -/
def forbidTrace : Trace := mkTrace uTurnAtJunction junctionLayout [noUTurn [101]]

/-- `permit` (compliant): Same sign and lane; the subject drives straight through the intersection: no U-turn is recognized. (Built as a left turn out of lane 101 — heading change 90°, short of the band — since a heading that never turns leaves the occasion unmet and the rule not applicable.) -/
def permitTrace : Trace :=
  mkTrace
    [ (pt 2 (-20), Build.north, degs 0)
    , (pt 2 (-14), Build.north, degs 0)
    , (pt 2 (-8), Build.north, degs 0)
    , (pt 2 (-3), Build.west, degs 90)
    , (pt (-3) 5, Build.west, degs 0)
    , (pt (-9) 5, Build.west, degs 0)
    , (pt (-15) 5, Build.west, degs 0)
    , (pt (-21) 5, Build.west, degs 0)
    , (pt (-27) 5, Build.west, degs 0)
    , (pt (-33) 5, Build.west, degs 0)
    , (pt (-39) 5, Build.west, degs 0)
    , (pt (-45) 5, Build.west, degs 0) ]
    junctionLayout [noUTurn [101]]

/-- `idle` (not_applicable): The subject makes a U-turn on a lane no no_u_turn sign governs; no sign governs the intersection or a lane entering it from which the subject came. (The sign governs lane 103, which enters the junction from the east; the subject comes from lane 101.) -/
def idleTrace : Trace := mkTrace uTurnAtJunction junctionLayout [noUTurn [103]]

/-- `blind` (unknown): Same as forbid, but the source declares kin.yaw_rate absent. -/
def blindTrace : Trace := mkTrace uTurnAtJunction junctionLayout [noUTurn [101]]

/-- `branch_1` (not_applicable): The no_u_turn sign's conditions state hours that do not include the time of the observation (prim.conditions_hold false throughout the U-turn); the subject makes the U-turn under it. -/
def branch_1Trace : Trace := mkTrace uTurnAtJunction junctionLayout [noUTurn [101] morningPeak]

/-- `branch_2` (violated): the sign governs approach lane 101; the subject drives straight out of it into the junction and makes the whole U-turn inside the junction, leaving on lane 102: only the entry from the governed lane places it under the sign. Recognized at k = 8. -/
def branch_2Trace : Trace :=
  mkTrace
    [ (pt 2 (-20), Build.north, degs 0)
    , (pt 2 (-14), Build.north, degs 0)
    , (pt 2 (-8), Build.north, degs 0)
    , (pt 2 (-2), Build.north, degs 0)
    , (pt 2 4, Build.north, degs 0)
    , (pt 0 8, Build.west, degs 90)
    , (pt (-2) 6, Build.west, degs 0)
    , (pt (-2) 3, Build.south, degs 90)
    , (pt (-2) (-3), Build.south, degs 0)
    , (pt (-2) (-9), Build.south, degs 0)
    , (pt (-2) (-15), Build.south, degs 0)
    , (pt (-2) (-21), Build.south, degs 0) ]
    junctionLayout [noUTurn [101]]

/-- `branch_3` (not_applicable): as forbid, but the sign on lane 101 is a no-left-turn sign: no device indicates that a U-turn is prohibited. -/
def branch_3Trace : Trace := mkTrace uTurnAtJunction junctionLayout [noUTurn [101] {} .noLeftTurn]

/-- `occasion_s1` (violated): The no_u_turn sign governs the lane the subject occupies as it begins turning; the subject completes the reversal on lanes the sign does not govern, so that the governed lane is overlapped only at the first observations while the U-turn is under way. -/
def occasion_s1Trace : Trace :=
  mkTrace
    [ (pt 2 (-40), Build.north, degs 0)
    , (pt 2 (-34), Build.north, degs 0)
    , (pt 2 (-28), Build.north, degs 0)
    , (pt 2 (-22), Build.west, degs 90)
    , (pt 1 (-18), Build.west, degs 0)
    , (pt (-2) (-19), Build.south, degs 90)
    , (pt (-2) (-25), Build.south, degs 0)
    , (pt (-2) (-31), Build.south, degs 0)
    , (pt (-2) (-37), Build.south, degs 0)
    , (pt (-2) (-43), Build.south, degs 0)
    , (pt (-2) (-49), Build.south, degs 0)
    , (pt (-2) (-55), Build.south, degs 0) ]
    midBlockLayout [noUTurn [111]]

/-- `occasion_s1_outside` (not_applicable): The subject occupies the governed lane only before it begins turning; it continues past the sign's governed stretch and makes the whole U-turn later on lanes and an intersection the sign does not govern and did not enter from a governed lane. (Lane 111 at k = 0, 1 with no yaw; the turn runs k = 5..7 on lanes 117 and 112; recognized at k = 8, whose window still reaches back to k = 0.) -/
def occasion_s1_outsideTrace : Trace :=
  mkTrace
    [ (pt 2 (-30), Build.north, degs 0)
    , (pt 2 (-24), Build.north, degs 0)
    , (pt 2 (-18), Build.north, degs 0)
    , (pt 2 (-12), Build.north, degs 0)
    , (pt 2 (-6), Build.north, degs 0)
    , (pt 2 0, Build.west, degs 90)
    , (pt 1 2, Build.west, degs 0)
    , (pt (-2) 1, Build.south, degs 90)
    , (pt (-2) (-5), Build.south, degs 0)
    , (pt (-2) (-11), Build.south, degs 0)
    , (pt (-2) (-17), Build.south, degs 0)
    , (pt (-2) (-23), Build.south, degs 0)
    , (pt (-2) (-29), Build.south, degs 0) ]
    midBlockLayout [noUTurn [111]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") (last : Int := 11000) : Scenario :=
  { name := name
    rule := "NRS_484B_403_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, last)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "occasion_s1" occasion_s1Trace .violated
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable (last := 12000) ]

end TrafficSpecWitness.NRS_484B_403_2
