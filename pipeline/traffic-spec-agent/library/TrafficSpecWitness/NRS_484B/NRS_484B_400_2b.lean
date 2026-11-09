/-
  Witnesses for NRS_484B_400_2b.

  THE GEOMETRY (every figure here is the witness's own and appears nowhere in the rule).

  One junction of two undivided ways, in the world frame (+x east, +y north), metres:
    1  hwA   highway, x ∈ [-6, 6],   y ∈ [-60, 60]   (the north-south way)
    2  hwB   highway, x ∈ [-60, 60], y ∈ [-6, 6]     (the east-west way)
    3  J     intersection, [-6, 6] × [-6, 6], lying on both ways
    4  nbS   roadway, x ∈ [0, 6],    y ∈ [-60, -6]   direction north, entrance end J, on hwA
    5  sbS   roadway, x ∈ [-6, 0],   y ∈ [-60, -6]   direction south, entrance end unobserved
    6  ebW   roadway, x ∈ [-60, -6], y ∈ [-6, 0]     direction east, entrance end J, on hwB
    7  wbW   roadway, x ∈ [-60, -6], y ∈ [0, 6]      direction west, entrance end unobserved
    8  clA   centre line of hwA, x ∈ [-0.2, 0.2], y ∈ [-60, -6]
    9  clB   centre line of hwB, x ∈ [-60, -6], y ∈ [-0.2, 0.2]
   10  median (divided world only) median or divider on hwB, x ∈ [-60, -6], y ∈ [-0.5, 0.5]
  Each way carries two carriers of opposed designated directions, so each way is two-directional;
  no centre line runs through the junction itself.

  The subject (track 1, a motor vehicle, 4.5 m × 1.8 m) approaches northbound at x = 3 m and is
  sampled every 50 ms, the sampling period of the carla_scene_graph profile, so that no interval
  exceeds the step bound of the heading change. Every turn below is an exact circular arc of
  radius v/ω sampled at 5° of heading per observation, so the position, the heading, the velocity
  and the reported rate of change of heading (100 deg/s, far above the onset rate of 3 deg/s) are
  one motion: the rate at an observation is the one held over the interval ending there. The
  heading change the rule accumulates is counted from the onset observation, so it is 5 deg per
  observation after it: it reaches the turn angle of 45 deg nine observations later and stands at
  85 deg where the turn ends. The declared intention to turn at the junction is false before the
  onset and true from it on, so no observation before the manoeuvre is judged on an unobserved
  turn.

  `forbid` (v = 10 m/s, arc radius 5.73 m) begins its turn 2.7 m short of the junction and cuts
  the corner: it runs out west at y = -3 m, south of hwB's centre line, and its footprint leaves
  the junction at k = 27 (x = -6.23 m) with the centre line 2.8 m to its right — far outside the
  0.5 m lateral-offset resolution. `permit` (v = 15 m/s, arc radius 8.59 m) keeps right: its turn
  starts inside the junction and it leaves at k = 21 (x = -6.34 m) at y = +3 m with the centre
  line 2.8 m to its left. `blind` is the `permit` world with the yaw rate masked. `idle` runs
  straight north through the junction with no declared intention and no yaw. `branch_1` is the
  `permit` world with a median on the way entered, `branch_2` the `permit` world with both
  carriers of that way pointing east, and `branch_3` weaves 10 deg left and back while running
  straight through, with the intention declared: the heading change since its onset never leaves
  ±5 deg, so no left turn is made.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_2b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_2b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A length written in micrometres: the arcs below are sampled to the micrometre. -/
def um (n : Int) : Q := Units.micrometres n
/-- A component of a unit heading, written to the ten-millionth. -/
def uc (n : Int) : Q := Units.ratio n 10000000

/-- The sampling period of the trace: 50 ms, the carla_scene_graph profile. -/
def dt : Q := Units.milliseconds 50

/-- Rates of change of heading the source reports (deg/s). -/
def yawLeft : Q := Units.degrees 100
def yawRight : Q := Units.degrees (-100)
def yawNone : Q := Q.zero

/-- Unit headings at 5° of left turn from north. -/
def h05 : Vec := (uc (-871557), uc 9961947)
def h10 : Vec := (uc (-1736482), uc 9848078)
def h15 : Vec := (uc (-2588190), uc 9659258)
def h20 : Vec := (uc (-3420201), uc 9396926)
def h25 : Vec := (uc (-4226183), uc 9063078)
def h30 : Vec := (uc (-5000000), uc 8660254)
def h35 : Vec := (uc (-5735764), uc 8191520)
def h40 : Vec := (uc (-6427876), uc 7660444)
def h45 : Vec := (uc (-7071068), uc 7071068)
def h50 : Vec := (uc (-7660444), uc 6427876)
def h55 : Vec := (uc (-8191520), uc 5735764)
def h60 : Vec := (uc (-8660254), uc 5000000)
def h65 : Vec := (uc (-9063078), uc 4226183)
def h70 : Vec := (uc (-9396926), uc 3420201)
def h75 : Vec := (uc (-9659258), uc 2588190)
def h80 : Vec := (uc (-9848078), uc 1736482)
def h85 : Vec := (uc (-9961947), uc 871557)

-- Binders ↦ tracks: v ↦ 1

def hwA : Structure := Build.rect 1 .highway (m (-6)) (m (-60)) (m 6) (m 60)
def hwB : Structure := Build.rect 2 .highway (m (-60)) (m (-6)) (m 60) (m 6)
def junction : Structure :=
  { Build.rect 3 .intersection (m (-6)) (m (-6)) (m 6) (m 6) with ways := some [1, 2] }
def nbS : Structure :=
  { Build.rect 4 .roadway (m 0) (m (-60)) (m 6) (m (-6)) with
    lane := some { direction := some Build.north, entersIntersection := some 3 }
    ways := some [1] }
def sbS : Structure :=
  { Build.rect 5 .roadway (m (-6)) (m (-60)) (m 0) (m (-6)) with
    lane := some { direction := some Build.south }
    ways := some [1] }
def ebW : Structure :=
  { Build.rect 6 .roadway (m (-60)) (m (-6)) (m (-6)) (m 0) with
    lane := some { direction := some Build.east, entersIntersection := some 3 }
    ways := some [2] }
def wbW (dir : Vec) : Structure :=
  { Build.rect 7 .roadway (m (-60)) (m 0) (m (-6)) (m 6) with
    lane := some { direction := some dir }
    ways := some [2] }
def clA : Structure :=
  { Build.rect 8 .centreLine (cm (-20)) (m (-60)) (cm 20) (m (-6)) with ways := some [1] }
def clB : Structure :=
  { Build.rect 9 .centreLine (m (-60)) (cm (-20)) (m (-6)) (cm 20) with ways := some [2] }
def median : Structure :=
  { Build.rect 10 .medianOrDivider (m (-60)) (cm (-50)) (m (-6)) (cm 50) with ways := some [2] }

/-- Two undivided two-directional ways meeting at one junction. -/
def junctionWorld : List Structure := [hwA, hwB, junction, nbS, sbS, ebW, wbW Build.west, clA, clB]
/-- The same, with a median dividing the directions of the way entered. -/
def dividedWorld : List Structure := junctionWorld ++ [median]
/-- The same, with both carriers of the way entered pointing east. -/
def oneWayWorld : List Structure := [hwA, hwB, junction, nbS, sbS, ebW, wbW Build.east, clA, clB]

/-- Position, heading and reported yaw rate at an observation. -/
def frameAt (fs : List (Vec × Vec × Q)) (k : Nat) : Vec × Vec × Q :=
  fs.getD k ((Q.zero, Q.zero), (Q.zero, Q.zero), Q.zero)

/-- One scene: the subject alone, the world, and the declaration current at the junction. -/
def sceneOf (fs : List (Vec × Vec × Q)) (structs : List Structure) (speed : Q) (intentFrom : Nat)
    (k : Nat) (t : Timestamp) : Scene :=
  let f := frameAt fs k
  Build.scene t (some 1)
    [ Build.withKin (Build.user 1 [.motorVehicle] f.1 f.2.1 speed (cm 225, cm 90, cm 75))
        (fun kin => { kin with yawRate := some f.2.2 }) ]
    structs []
    (intents := [ { vehicle := 1, target := 3, values := [("int.turn", decide (intentFrom ≤ k))] } ])

/-- `forbid`: the corner cut — a left arc of radius 5.73 m begun 2.7 m short of the junction, out
    west at y = -3 m, the wrong side of hwB's centre line. -/
def forbidFrames : List (Vec × Vec × Q) :=
  [ ((um 3000000, um (-9729578)), Build.north, yawNone)
  , ((um 3000000, um (-9229578)), Build.north, yawNone)
  , ((um 3000000, um (-8729578)), Build.north, yawNone)
  , ((um 2978197, um (-8230213)), h05, yawLeft)
  , ((um 2912956, um (-7734647)), h10, yawLeft)
  , ((um 2804766, um (-7246654)), h15, yawLeft)
  , ((um 2654556, um (-6769947)), h20, yawLeft)
  , ((um 2463180, um (-6308152)), h25, yawLeft)
  , ((um 2232382, um (-5864789)), h30, yawLeft)
  , ((um 1963819, um (-5443227)), h35, yawLeft)
  , ((um 1659533, um (-5046677)), h40, yawLeft)
  , ((um 1321846, um (-4678154)), h45, yawLeft)
  , ((um 953323, um (-4340467)), h50, yawLeft)
  , ((um 556773, um (-4036181)), h55, yawLeft)
  , ((um 135211, um (-3767618)), h60, yawLeft)
  , ((um (-308152), um (-3536820)), h65, yawLeft)
  , ((um (-769947), um (-3345444)), h70, yawLeft)
  , ((um (-1246654), um (-3195234)), h75, yawLeft)
  , ((um (-1734647), um (-3087044)), h80, yawLeft)
  , ((um (-2230213), um (-3021803)), h85, yawLeft)
  , ((um (-2729578), um (-3000000)), Build.west, yawLeft)
  , ((um (-3229578), um (-3000000)), Build.west, yawNone)
  , ((um (-3729578), um (-3000000)), Build.west, yawNone)
  , ((um (-4229578), um (-3000000)), Build.west, yawNone)
  , ((um (-4729578), um (-3000000)), Build.west, yawNone)
  , ((um (-5229578), um (-3000000)), Build.west, yawNone)
  , ((um (-5729578), um (-3000000)), Build.west, yawNone)
  , ((um (-6229578), um (-3000000)), Build.west, yawNone)
  , ((um (-6729578), um (-3000000)), Build.west, yawNone)
  , ((um (-7229578), um (-3000000)), Build.west, yawNone) ]

/-- `permit`: the wide turn — a left arc of radius 8.59 m begun just inside the junction, out west
    at y = +3 m, the centre line to the left. -/
def permitFrames : List (Vec × Vec × Q) :=
  [ ((um 3000000, um (-7094367)), Build.north, yawNone)
  , ((um 3000000, um (-6344367)), Build.north, yawNone)
  , ((um 3000000, um (-5594367)), Build.north, yawNone)
  , ((um 2967298, um (-4845319)), h05, yawLeft)
  , ((um 2869433, um (-4101971)), h10, yawLeft)
  , ((um 2707153, um (-3369982)), h15, yawLeft)
  , ((um 2481697, um (-2654920)), h20, yawLeft)
  , ((um 2194774, um (-1962230)), h25, yawLeft)
  , ((um 1848573, um (-1297183)), h30, yawLeft)
  , ((um 1445724, um (-664841)), h35, yawLeft)
  , ((um 989300, um (-70018)), h40, yawLeft)
  , ((um 482748, um 482748), h45, yawLeft)
  , ((um (-70018), um 989300), h50, yawLeft)
  , ((um (-664841), um 1445724), h55, yawLeft)
  , ((um (-1297183), um 1848573), h60, yawLeft)
  , ((um (-1962230), um 2194774), h65, yawLeft)
  , ((um (-2654920), um 2481697), h70, yawLeft)
  , ((um (-3369982), um 2707153), h75, yawLeft)
  , ((um (-4101971), um 2869433), h80, yawLeft)
  , ((um (-4845319), um 2967298), h85, yawLeft)
  , ((um (-5594367), um 3000000), Build.west, yawLeft)
  , ((um (-6344367), um 3000000), Build.west, yawNone)
  , ((um (-7094367), um 3000000), Build.west, yawNone)
  , ((um (-7844367), um 3000000), Build.west, yawNone) ]

/-- `idle`: straight north through the junction, no yaw. -/
def straightFrames : List (Vec × Vec × Q) :=
  [ ((um 3000000, um (-8200000)), Build.north, yawNone)
  , ((um 3000000, um (-7700000)), Build.north, yawNone)
  , ((um 3000000, um (-7200000)), Build.north, yawNone)
  , ((um 3000000, um (-6700000)), Build.north, yawNone)
  , ((um 3000000, um (-6200000)), Build.north, yawNone)
  , ((um 3000000, um (-5700000)), Build.north, yawNone)
  , ((um 3000000, um (-5200000)), Build.north, yawNone)
  , ((um 3000000, um (-4700000)), Build.north, yawNone)
  , ((um 3000000, um (-4200000)), Build.north, yawNone)
  , ((um 3000000, um (-3700000)), Build.north, yawNone)
  , ((um 3000000, um (-3200000)), Build.north, yawNone)
  , ((um 3000000, um (-2700000)), Build.north, yawNone)
  , ((um 3000000, um (-2200000)), Build.north, yawNone)
  , ((um 3000000, um (-1700000)), Build.north, yawNone)
  , ((um 3000000, um (-1200000)), Build.north, yawNone)
  , ((um 3000000, um (-700000)), Build.north, yawNone)
  , ((um 3000000, um (-200000)), Build.north, yawNone)
  , ((um 3000000, um 300000), Build.north, yawNone)
  , ((um 3000000, um 800000), Build.north, yawNone)
  , ((um 3000000, um 1300000), Build.north, yawNone)
  , ((um 3000000, um 1800000), Build.north, yawNone)
  , ((um 3000000, um 2300000), Build.north, yawNone)
  , ((um 3000000, um 2800000), Build.north, yawNone)
  , ((um 3000000, um 3300000), Build.north, yawNone)
  , ((um 3000000, um 3800000), Build.north, yawNone)
  , ((um 3000000, um 4300000), Build.north, yawNone)
  , ((um 3000000, um 4800000), Build.north, yawNone)
  , ((um 3000000, um 5300000), Build.north, yawNone)
  , ((um 3000000, um 5800000), Build.north, yawNone)
  , ((um 3000000, um 6300000), Build.north, yawNone) ]

/-- `branch_3`: a 10 deg weave to the left and back (two 5° steps of a left arc of radius 5.73 m,
    then two of a right arc), then straight north through the junction. -/
def wiggleFrames : List (Vec × Vec × Q) :=
  [ ((um 3000000, um (-9000000)), Build.north, yawNone)
  , ((um 3000000, um (-8500000)), Build.north, yawNone)
  , ((um 3000000, um (-8000000)), Build.north, yawNone)
  , ((um 2978197, um (-7500635)), h05, yawLeft)
  , ((um 2912956, um (-7005069)), h10, yawLeft)
  , ((um 2847715, um (-6509503)), h05, yawRight)
  , ((um 2825912, um (-6010138)), Build.north, yawRight)
  , ((um 2825912, um (-5510138)), Build.north, yawNone)
  , ((um 2825912, um (-5010138)), Build.north, yawNone)
  , ((um 2825912, um (-4510138)), Build.north, yawNone)
  , ((um 2825912, um (-4010138)), Build.north, yawNone)
  , ((um 2825912, um (-3510138)), Build.north, yawNone)
  , ((um 2825912, um (-3010138)), Build.north, yawNone)
  , ((um 2825912, um (-2510138)), Build.north, yawNone)
  , ((um 2825912, um (-2010138)), Build.north, yawNone)
  , ((um 2825912, um (-1510138)), Build.north, yawNone)
  , ((um 2825912, um (-1010138)), Build.north, yawNone)
  , ((um 2825912, um (-510138)), Build.north, yawNone)
  , ((um 2825912, um (-10138)), Build.north, yawNone)
  , ((um 2825912, um 489862), Build.north, yawNone) ]

/-- `forbid` (violated): Two undivided ways, each with carriers of opposed designated directions, cross; the trace declares the subject's intention to turn at that junction; the subject enters the junction and its accumulated heading change to the left passes the turn angle, so a left turn is made. At the observation at which its footprint ceases to overlap the junction it is on the far side of the entered way's centre line, the centre line lying to its right. -/
def forbidTrace : Trace :=
  Build.trace 30 0 dt (sceneOf forbidFrames junctionWorld (Units.metresPerSecond 10) 3)

/-- `permit` (compliant): The same two two-directional ways, the same declared intention, the same entry and left turn; at the observation at which the subject's footprint ceases to overlap the junction the centre line of the way it then occupies lies to its left by more than the lateral-offset resolution. No other road user is present in the scene. -/
def permitTrace : Trace :=
  Build.trace 24 0 dt (sceneOf permitFrames junctionWorld (Units.metresPerSecond 15) 3)

/-- `idle` (not_applicable): The subject runs straight through the same junction: the trace declares no intention to turn for it at that junction and its accumulated heading change never reaches the turn angle, so no left turn is made. -/
def idleTrace : Trace :=
  Build.trace 30 0 dt (sceneOf straightFrames junctionWorld (Units.metresPerSecond 10) 99)

/-- `blind` (unknown): Every other condition holds -- two two-directional ways, the declared intention, the entry, and a departure from the junction on the left of the entered way's centre line -- but the source supplies no rate of change of heading for the subject, so whether it has turned to the left cannot be told. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (not_applicable): The way being entered carries a median dividing its two directions, so the intersecting ways are not both two-directional; the subject, with a declared intention to turn, enters the junction, turns left and leaves it on the left of that way's centre line. -/
def branch_1Trace : Trace :=
  Build.trace 24 0 dt (sceneOf permitFrames dividedWorld (Units.metresPerSecond 15) 3)

/-- `branch_2` (not_applicable): both carriers of the way being entered carry the same designated
    direction, so that way is not two-directional; everything else is the `permit` scene. -/
def branch_2Trace : Trace :=
  Build.trace 24 0 dt (sceneOf permitFrames oneWayWorld (Units.metresPerSecond 15) 3)

/-- `branch_3` (not_applicable): the intention to turn is declared and the subject enters the
    junction, but the heading change accumulated since the onset of its weave never leaves ±5 deg,
    so no left turn is made. -/
def branch_3Trace : Trace :=
  Build.trace 20 0 dt (sceneOf wiggleFrames junctionWorld (Units.metresPerSecond 10) 3)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_2b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_400_2b
