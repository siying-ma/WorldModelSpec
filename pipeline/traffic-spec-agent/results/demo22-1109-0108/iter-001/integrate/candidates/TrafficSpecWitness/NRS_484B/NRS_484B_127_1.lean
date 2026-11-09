/-
  Witnesses for NRS_484B_127_1.

  The geometry. One straight east-west public way, region 10 (`hwy`), the highway strip from
  x = −300 m to x = 1200 m and y = −8 m to y = 8 m, carrying the slope and the bend each scene
  reads. Inside it one eastbound lane, region 11 (`laneRight`), y = −2 m to 2 m, direction east;
  where a scene needs a second lane it adds region 12 (`laneLeft`), y = 2 m to 6 m, also eastbound.
  Bodies ride on the centre line of their lane (y = 0 in the right lane, y = 4 in the left), so a
  car (half-width 1 m) or a van (1.1 m) lies wholly inside its own lane and wholly inside the
  highway.

  The subject is always track 1. Half-lengths: car 2.5 m, van 3 m, lorry 6 m, pedal cycle 0.9 m, so
  the longitudinal surface gap between two bodies in line is the distance between their centres less
  the two half-lengths — the figure each narrative names.

  Each trace is three observations one second apart (a fifth of a second for `branch_9`), every body
  advancing at its own recorded speed, so the geometry of the narrative holds at every instant.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n
/-- A horizontal curvature (1/m), written as the reciprocal of the bend's radius in metres. -/
def curvatureOfRadius (radius : Q) : Q := Q.div (Units.perMetre 1) radius
/-- Where a body of this speed stands at observation `k` of a trace of spacing `dtMs`. -/
def advance (k : Nat) (dtMs : Int) (speed : Q) (x : Q) : Q :=
  Q.add x (Q.mul speed (Units.milliseconds (dtMs * Int.ofNat k)))

-- Binders ↦ tracks: v ↦ 1

def hwy : RegionId := 10
def laneR : RegionId := 11
def laneL : RegionId := 12

/-- The public way, with the longitudinal slope and the horizontal curvature the scene records. -/
def highway (grade curvature : Q) : Structure :=
  { Build.rect hwy .highway (m (-300)) (m (-8)) (m 1200) (m 8) with
      grade := some grade
      curvature := some curvature }
/-- The eastbound lane the subject rides in. -/
def laneRight : Structure :=
  Build.lane laneR [(m (-300), m (-2)), (m 1200, m (-2)), (m 1200, m 2), (m (-300), m 2)] Build.east
/-- The eastbound lane beside it. -/
def laneLeft : Structure :=
  Build.lane laneL [(m (-300), m 2), (m 1200, m 2), (m 1200, m 6), (m (-300), m 6)] Build.east

def car (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos Build.east speed (cm 250, m 1, cm 75)
def van (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos Build.east speed (m 3, cm 110, cm 120)
def lorry (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.truck, .motorVehicle] pos Build.east speed (m 6, cm 125, cm 175)
/-- A pedal cycle propelled by human power: no class the vehicle definition includes. -/
def cycle (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.bicycle] pos Build.east speed (cm 90, cm 30, cm 90)

def dryEnv : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some false }
def wetEnv : Env := { precipitation := some false, wetRoad := some true, iceOrSnow := some false }
def iceEnv : Env := { precipitation := some false, wetRoad := some false, iceOrSnow := some true }
def rainEnv : Env := { precipitation := some true, wetRoad := some false, iceOrSnow := some false }

/-- A scene of the way: the bodies, the lanes beside the highway strip, no control device. -/
def sceneOf (t : Timestamp) (users : List RoadUser) (lanes : List Structure)
    (grade curvature : Q) (env : Env) : Scene :=
  Build.scene t (some 1) users (highway grade curvature :: lanes) [] (env := env)

/-- `forbid` (violated): On a wet single-carriageway highway a car runs at 25 m/s in the same lane as, and 20 m behind, a van travelling at the same speed, their headings aligned. The wet-surface headway bound requires about 75 m, so the longitudinal surface gap is far below the bound. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 2550), m 0) (mps 25) ]
      [ laneRight ] Q.zero Q.zero wetEnv

/-- `permit` (compliant): The same pair on a dry, level, straight highway with light traffic: the car runs at 25 m/s with a longitudinal surface gap of 90 m behind the van, which exceeds the dry-surface bound and the closing-speed term, the two speeds being equal. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 9550), m 0) (mps 25) ]
      [ laneRight ] Q.zero Q.zero dryEnv

/-- `idle` (not_applicable): A pedal cycle propelled by human power, which the vehicle definition leaves out, rides 2 m behind a car in the same lane at 6 m/s. No vehicle is bound and the rule does not engage. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ cycle 1 (advance k 1000 (mps 6) (m 0), m 0) (mps 6)
      , car 2 (advance k 1000 (mps 6) (cm 540), m 0) (mps 6) ]
      [ laneRight ] Q.zero Q.zero dryEnv

/-- The van as a source that measures no body size records it: a position, a heading and a speed,
    but no extent, so neither a footprint nor a gap computed from one. -/
def vanNoBody (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.withKin (van track pos speed) fun kin => { kin with extent := none }

/-- `blind` (unknown): The forbid scene with the source declaring the gap between bodies absent: the following relation, the speeds and the wet surface are recorded, but the quantity the bound is compared with cannot be read, so the duty is unknown.

    The same pair at the same speeds on the same wet surface, recorded by a source that measures no
    body size and maps no road: it reports the two vehicles' classes, places, headings and speeds,
    the weather, and that the van is ahead of the car in the lane, and it reports the gap between
    the bodies, which the manifest declares absent. Without the van's extent no gap is computed from
    the bodies either, so the one quantity the bound is compared with cannot be read; every
    selection the bound makes is decided (no way is mapped, so neither the slope and the bend nor
    the count of the traffic upon the way bears on it), and the duty is unknown for the gap alone. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s :=
      Build.scene t (some 1)
        [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
        , vanNoBody 2 (advance k 1000 (mps 25) (cm 2550), m 0) (mps 25) ]
        [] [] (env := wetEnv)
    -- the van's body is not measured, so its footprint is undefined: its occupancy is not observed
    -- and no gap is computed from the two bodies
    Build.withRelations { s with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with surfaceGap := some (m 20, m 0) }
      , Build.relation 2 1 fun r => { r with aAheadOfB := some true } ]

/-- `branch_1` (compliant): The car runs at 25 m/s on the same wet highway with no other road user anywhere in the scene. No road user is ahead of it in its lane, so the prohibition is complied with and the verdict is decided although the only party is the subject. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25) ]
      [ laneRight ] Q.zero Q.zero wetEnv

/-- `branch_2` (violated): A dry, level, straight highway, but the car at 25 m/s closes on a lorry ahead in its lane that is running at 10 m/s with a longitudinal surface gap of 55 m: the dry headway term alone would be met, and the closing-speed term raises the bound above the gap. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , lorry 2 (advance k 1000 (mps 10) (cm 6350), m 0) (mps 10) ]
      [ laneRight ] Q.zero Q.zero dryEnv

/-- `branch_3` (violated): An icy, level, straight highway: the car at 25 m/s keeps the 90 m gap
    behind the van that the dry and the wet bounds both allow, but ice calls for about 112 m. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 9550), m 0) (mps 25) ]
      [ laneRight ] Q.zero Q.zero iceEnv

/-- `branch_4` (violated): A dry, straight highway falling at six per hundred: the car at 25 m/s
    keeps 60 m behind the van, which the level bound allows and the adverse-geometry bound of about
    75 m does not. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 6550), m 0) (mps 25) ]
      [ laneRight ] (Units.ratio (-6) 100) Q.zero dryEnv

/-- `branch_5` (violated): The same 60 m on a dry, level but curving stretch, a bend of fifty
    metres' radius: the bend shortens the view of the van and the adverse-geometry bound applies. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 6550), m 0) (mps 25) ]
      [ laneRight ] Q.zero (curvatureOfRadius (m 50)) dryEnv

/-- `branch_6` (violated): A dry, level, straight highway carrying six road users: the car at
    25 m/s keeps 52 m behind the van, which the dry bound of 50 m allows, while the dense-traffic
    increment raises it to 55 m. The four others ride in the lane beside, so none is followed. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 5750), m 0) (mps 25)
      , car 3 (advance k 1000 (mps 25) (m 10), m 4) (mps 25)
      , car 4 (advance k 1000 (mps 25) (m 40), m 4) (mps 25)
      , van 5 (advance k 1000 (mps 25) (m 70), m 4) (mps 25)
      , car 6 (advance k 1000 (mps 25) (m 100), m 4) (mps 25) ]
      [ laneRight, laneLeft ] Q.zero Q.zero dryEnv

/-- `branch_7` (violated): Rain falling on a highway the source does not report wet, level and
    straight: the same 60 m gap that the dry bound allows is below the wet-surface bound. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (cm 6550), m 0) (mps 25) ]
      [ laneRight ] Q.zero Q.zero rainEnv

/-- `branch_8` (compliant): A dry, level, straight highway: the car at 6 m/s is 10 m behind a pedal
    cycle at the same speed, inside the 12 m the dry bound would set — but a pedal cycle propelled by
    human power is no vehicle of the definition, so there is no vehicle followed. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 6) (m 0), m 0) (mps 6)
      , cycle 2 (advance k 1000 (mps 6) (cm 1340), m 0) (mps 6) ]
      [ laneRight ] Q.zero Q.zero dryEnv

/-- A van halted across the lane at forty-five degrees to it, turning out of the way. -/
def vanTurningOff (track : TrackId) (pos : Vec) : RoadUser :=
  Build.user track [.motorVehicle] pos (m 1, m 1) Q.zero (m 3, cm 110, cm 120)

/-- `branch_9` (compliant): A van 20 m ahead in the car's lane stands at forty-five degrees to it,
    turning out of the way; the car at 25 m/s is far inside the bound the dry surface and the
    closing speed set, but the two headings are not aligned within the tolerance, so the car is
    following nothing. Three observations a fifth of a second apart. -/
def branch_9Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 200) fun k t =>
    sceneOf t
      [ car 1 (advance k 200 (mps 25) (m 0), m 0) (mps 25)
      , vanTurningOff 2 (cm 2550, m 0) ]
      [ laneRight ] Q.zero Q.zero dryEnv

/-- `branch_10` (compliant): A dry, level, straight highway with the van abreast of the car in the
    next lane, 1.9 m away across the way: the bodies' longitudinal gap is nil, well inside the dry
    bound, but the van is in no lane the car is in, so the car is not following it. -/
def branch_10Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneOf t
      [ car 1 (advance k 1000 (mps 25) (m 0), m 0) (mps 25)
      , van 2 (advance k 1000 (mps 25) (m 0), m 4) (mps 25) ]
      [ laneRight, laneLeft ] Q.zero Q.zero dryEnv

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_1"
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .violated
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant
  , witness "branch_10" branch_10Trace .compliant ]

end TrafficSpecWitness.NRS_484B_127_1
