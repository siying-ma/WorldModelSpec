/-
  Witnesses for NRS_484B_270_3_o1.

  Geometry (world frame, +x east, +y north), the same in every scene:
    h  (10) highway, x −50…50, y 0…9, spanning everything below;
    L  (11) travel lane, y 0…4;   b (12) bicycle lane, y 4…6;   w (13) sidewalk, y 6…9;
    L, b and w lie on h (`ways`). branch_1 adds a crosswalk c (14) across L and b at x −8…−5;
    branch_2 adds an obstruction o (15, sidewalk fixture) on w at x −4.4…−2, y 6.5…9.
  Bodies: x (track 1) is a passenger car, half-extents 2.4 × 0.9 m, crossing b northward at
  x-coordinate 0 toward a driveway; y (track 2) is a bicycle (0.9 × 0.3 m), an electric bicycle or a
  pedestrian (0.25 × 0.25 m). Occupancy is stated from the footprints, since a body spans regions.
  Closest approaches (constant velocities, centre to centre):
    forbid / blind / branch_6: x 1 m/s north from (0, 5); y 6 m/s east from (−9, 5): 1.48 m at 1.46 s.
    permit: x 3 m/s north from (0, 5); bicycle 5 m/s east from (−15, 5): 7.72 m at 2.21 s.
    branch_5: x 1 m/s north; bicycle 5 m/s east from (−40, 5): closest approach at 7.7 s, past any
      horizon of a few seconds.
    branch_1: pedestrian steps from w (−6.5, 7.5) onto the crosswalk in b (−6.5, 5.5), then walks
      1.5 m/s east in b from (−4.5, 5), x at (0, 5): 2.50 m at 2.08 s. Starting on w, away from any
      obstruction and with the assumption false, decides NRS_484B_297_6_o2's look-back.
    branch_2 / branch_4: pedestrian 1.5 m/s east in b from (−3, 5), x at (0, 5): 1.66 m at 1.38 s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_3_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_3_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def xId : TrackId := 1
def yId : TrackId := 2

def hId : RegionId := 10
def lId : RegionId := 11
def bId : RegionId := 12
def wId : RegionId := 13
def cId : RegionId := 14
def oId : RegionId := 15

def asmMissing : AsmId := "asm.sidewalk_section_missing_or_impassable"

def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 90)
def pedExtent : Q × Q × Q := (cm 25, cm 25, cm 90)

def walk : Q := Units.micrometresPerSecond 1500000

def onH (s : Structure) : Structure := { s with ways := some [hId] }

def layout : List Structure :=
  [ Build.rect hId .highway (m (-50)) (m 0) (m 50) (m 9)
  , onH (Build.rect lId .lane (m (-50)) (m 0) (m 50) (m 4))
  , onH (Build.rect bId .bicycleLaneOrPath (m (-50)) (m 4) (m 50) (m 6))
  , onH (Build.rect wId .sidewalk (m (-50)) (m 6) (m 50) (m 9)) ]

def crosswalk : Structure := onH (Build.rect cId .crosswalk (m (-8)) (m 0) (m (-5)) (m 6))

def obstruction : Structure :=
  { Build.rect oId .obstruction (cm (-440)) (cm 650) (m (-2)) (m 9) with
    obstructionKind := some .sidewalkFixture
    ways := some [wId, hId] }

def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user xId [.motorVehicle] pos heading speed carExtent

def scene (t : Timestamp) (users : List RoadUser) (structures : List Structure)
    (occ : List (TrackId × RegionId)) (assumptions : List (AsmId × Bool) := []) : Scene :=
  Build.scene t (some xId) users structures [] (some occ) {} assumptions

/-- x's footprint across the travel lane, the bicycle lane and the sidewalk. -/
def xAcross : List (TrackId × RegionId) := [(xId, lId), (xId, bId), (xId, wId), (xId, hId)]
/-- y's footprint on the bicycle lane only. -/
def yInB : List (TrackId × RegionId) := [(yId, bId), (yId, hId)]

/-- x crossing b at 1 m/s from (0, 5), 0.5 s apart; a rider of class `cls` 6 m/s east from (−9, 5). -/
def crossingTrace (cls : RoadUserClass) : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let xp : Vec := (m 0, Q.add (m 5) (Q.mul (cm 50) (Q.ofInt k)))
    let yp : Vec := (Q.add (m (-9)) (Q.mul (m 3) (Q.ofInt k)), m 5)
    scene t
      [ car xp Build.north (Units.metresPerSecond 1)
      , Build.user yId [cls] yp Build.east (Units.metresPerSecond 6) bikeExtent ]
      layout (xAcross ++ yInB)

/-- `forbid` (violated): x (passenger car) turns right across bicycle lane b and moves onto it while a bicycle y rides in b behind it at 6 m/s; predicted closest approach 1 m in 1.5 s. -/
def forbidTrace : Trace := crossingTrace .bicycle

/-- `permit` (compliant): x crosses b while bicycle y in b is 40 m away at 5 m/s and predicted to pass 15 m from x.
    Built so that the closest approach falls inside the horizon but well clear of the clearance:
    bicycle 15 m away, predicted to pass 7.7 m from x. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let xp : Vec := (m 0, Q.add (m 5) (Q.mul (cm 150) (Q.ofInt k)))
    let yp : Vec := (Q.add (m (-15)) (Q.mul (cm 250) (Q.ofInt k)), m 5)
    let xOcc : List (TrackId × RegionId) :=
      if k == 0 then xAcross else [(xId, bId), (xId, wId), (xId, hId)]
    scene t
      [ car xp Build.north (Units.metresPerSecond 3)
      , Build.user yId [.bicycle] yp Build.east (Units.metresPerSecond 5) bikeExtent ]
      layout (xOcc ++ yInB)

/-- `idle` (not_applicable): x never occupies a bicycle lane or path. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let xp : Vec := (Q.add (m (-10)) (Q.mul (cm 250) (Q.ofInt k)), m 2)
    let yp : Vec := (Q.add (m (-9)) (Q.mul (m 3) (Q.ofInt k)), m 5)
    scene t
      [ car xp Build.east (Units.metresPerSecond 5)
      , Build.user yId [.bicycle] yp Build.east (Units.metresPerSecond 6) bikeExtent ]
      layout ([(xId, lId), (xId, hId)] ++ yInB)

/-- `blind` (unknown): As forbid, but rel.occupies is not observed, so whether x and y are on b is unknown. -/
def blindTrace : Trace := crossingTrace .bicycle

/-- x crossing b at 1 m/s from (0, 3), 1 s apart, in the pedestrian scenes. -/
def xSlow (k : Nat) : RoadUser :=
  car (m 0, Q.add (m 3) (Q.ofInt k)) Build.north (Units.metresPerSecond 1)

def xSlowOcc (k : Nat) : List (TrackId × RegionId) :=
  if k == 0 then [(xId, lId), (xId, bId), (xId, hId)] else xAcross

def ped (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user yId [.pedestrian] pos heading walk pedExtent

/-- `branch_1` (not_applicable): x crosses b while a pedestrian who walked into b from a crosswalk (no sidewalk detour, NRS_484B_297_6_o2 not applying) is in predicted conflict: that pedestrian is not one the duty protects. -/
def branch_1Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let (y, yOcc) : RoadUser × List (TrackId × RegionId) :=
      match k with
      | 0 => (ped (cm (-650), cm 750) Build.south, [(yId, wId), (yId, hId)])
      | 1 => (ped (cm (-650), cm 550) Build.south, [(yId, cId), (yId, bId), (yId, hId)])
      | 2 => (ped (cm (-450), m 5) Build.east, yInB)
      | _ => (ped (m (-3), m 5) Build.east, yInB)
    scene t [xSlow k, y] (layout ++ [crosswalk]) (xSlowOcc k ++ yOcc) [(asmMissing, false)]

/-- The detouring pedestrian: on w at 7.5 m north, then (from k = 2) in b, walking east. -/
def detourPed (k : Nat) : RoadUser :=
  match k with
  | 0 => ped (m (-6), cm 750) Build.east
  | 1 => ped (cm (-450), cm 750) Build.east
  | 2 => ped (m (-3), m 5) Build.east
  | _ => ped (cm (-150), m 5) Build.east

/-- `branch_2` (violated): x crosses b while a pedestrian y detouring around a sidewalk obstruction walks in b, predicted closest approach about 1 m within 1 s. The scene states every fact NRS_484B_297_6_o2's applicability reads: a highway region h (st.highway) spanning the whole way, travel lane, b and sidewalk w included, with w recorded as lying on h (st.on_way w h) and b lying on h; an obstruction (st.obstruction, kind sidewalk_fixture) on w with its outline (st.region_geometry) observed. y first walks on w at walking speed (moving above p.motion_speed_tolerance) and at one such observation its body touches the obstruction (distance zero, within p.obstruction_encounter_reach); from the next observation on y's footprint overlaps b and h and overlaps no sidewalk at all (its body clear of w's edge), continuously to the end of the trace, walking on in b beside the obstruction toward x. The conflict observations come after the step off the sidewalk, inside the detour. -/
def branch_2Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let yOcc : List (TrackId × RegionId) :=
      match k with
      | 0 => [(yId, wId), (yId, hId)]
      | 1 => [(yId, wId), (yId, oId), (yId, hId)]
      | _ => yInB
    scene t [xSlow k, detourPed k] (layout ++ [obstruction]) (xSlowOcc k ++ yOcc)
      [(asmMissing, false)]

/-- `branch_3` (not_applicable): x crosses b with no other road user in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let xp : Vec := (m 0, Q.add (m 5) (Q.mul (cm 50) (Q.ofInt k)))
    scene t [car xp Build.north (Units.metresPerSecond 1)] layout xAcross

/-- `branch_4` (not_applicable): As branch_2 in every fact but one: no obstruction is anywhere in the scene and asm.sidewalk_section_missing_or_impassable is declared false at every observation, so y steps from w into b without a detour and NRS_484B_297_6_o2 does not apply to it; the same predicted conflict leaves the duty unengaged. -/
def branch_4Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let yOcc : List (TrackId × RegionId) :=
      match k with
      | 0 => [(yId, wId), (yId, hId)]
      | 1 => [(yId, wId), (yId, hId)]
      | _ => yInB
    scene t [xSlow k, detourPed k] layout (xSlowOcc k ++ yOcc) [(asmMissing, false)]

/-- `branch_5` (compliant): x crosses b while a bicycle in b is 40 m away at 5 m/s; the centres reach
    their closest approach only after the horizon, so no conflict is predicted. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    let xp : Vec := (m 0, Q.add (m 5) (Q.mul (cm 50) (Q.ofInt k)))
    let yp : Vec := (Q.add (m (-40)) (Q.mul (cm 250) (Q.ofInt k)), m 5)
    scene t
      [ car xp Build.north (Units.metresPerSecond 1)
      , Build.user yId [.bicycle] yp Build.east (Units.metresPerSecond 5) bikeExtent ]
      layout (xAcross ++ yInB)

/-- `branch_6` (violated): as forbid, the rider in b on an electric bicycle. -/
def branch_6Trace : Trace := crossingTrace .electricBicycle

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_3_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_3_o1
