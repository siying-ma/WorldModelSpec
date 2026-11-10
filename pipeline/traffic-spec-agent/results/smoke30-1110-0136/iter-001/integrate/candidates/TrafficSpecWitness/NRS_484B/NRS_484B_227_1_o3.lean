/-
  Witnesses for NRS_484B_227_1_o3.

  The divided highway (region 1) runs east–west, x ∈ [-500, 500] m, y ∈ [-30, 30] m. Its median
  lies along y ∈ [-2, 2] m in pieces: closed (opening false) for x ∈ [-500, -5] (2), [25, 200] (4)
  and [230, 500] (6), an opening (opening true) for x ∈ [-5, 25] (3); an intersection (5) spans
  x ∈ [200, 230] across the whole highway. Every median piece and the intersection lie on 1.
  Eastbound traffic keeps to the south roadway (y < -2), westbound to the north one.

  The car (track 1, a motor vehicle, half-extent 2 m × 1.1 m) is observed every second for 30 s.
  It drives straight (yaw rate 0) for the first 20 s or so, so that the 15 s recognition window
  is covered; a turn is four (or two) observations at 45 deg/s, a U-turn 180°, a left turn 90°.
  Each witness speaks about the observations from 16 s on (19 s on for `occasion_s2_outside`,
  once the car has left the divided highway), and every trace ends before the turn leaves the
  window. Against the reading (left turn ≥ 60°, reversal 150°–210°, yaw-rate floor 2 deg/s) a
  left turn is recognized at its 90° observation, a U-turn at its 180° one.

  `idle` uses an undivided highway (7) where the car is, with a divided one (1, median 2) 100 m
  north; `occasion_s2_outside` a divided highway (1, median 2) up to x = 100 m and an undivided
  one (7) beyond. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_227_1_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_227_1_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- A heading in fifths: (a/5, b/5). -/
def hd (a b : Int) : Vec := (Units.ratio a 5, Units.ratio b 5)
def hE : Vec := hd 5 0
def hNE : Vec := hd 3 4
def hN : Vec := hd 0 5
def hNW : Vec := hd (-3) 4
def hW : Vec := hd (-5) 0
def hSE : Vec := hd 3 (-4)
def hS : Vec := hd 0 (-5)
def hSW : Vec := hd (-3) (-4)

/-- One observation of the car: position (m), heading, yaw rate (deg/s). -/
structure Pose where
  x : Int
  y : Int
  h : Vec
  yaw : Int

def car (p : Pose) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (m p.x, m p.y) p.h (Units.metresPerSecond 8) (m 2, cm 110, cm 75))
    fun k => { k with yawRate := some (Units.degrees p.yaw) }

/-- `n` straight observations from (x0, y0), stepping (dx, dy) each second. -/
def line (n : Nat) (x0 y0 dx dy : Int) (h : Vec) : List Pose :=
  (List.range n).map fun k => ⟨x0 + dx * Int.ofNat k, y0 + dy * Int.ofNat k, h, 0⟩

/-- A left U-turn within the south roadway, starting eastbound at (x, -26), ending westbound at (x, -6). -/
def uTurnAt (x : Int) : List Pose :=
  [⟨x + 6, -24, hNE, 45⟩, ⟨x + 8, -16, hN, 45⟩, ⟨x + 6, -8, hNW, 45⟩, ⟨x, -6, hW, 45⟩]

def run (map : List Structure) (ps : List Pose) : Trace :=
  Build.trace ps.length 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car (ps.getD k ⟨0, 0, hE, 0⟩)] map []

def median (id : RegionId) (x0 y0 x1 y1 : Int) (opening : Bool) : Structure :=
  { Build.rect id .medianOrDivider (m x0) (m y0) (m x1) (m y1) with
      opening := some opening, ways := some [1] }

/-- The divided highway with its median pieces, opening and intersection. -/
def dividedMap : List Structure :=
  [ Build.rect 1 .highway (m (-500)) (m (-30)) (m 500) (m 30)
  , median 2 (-500) (-2) (-5) 2 false
  , median 3 (-5) (-2) 25 2 true
  , median 4 25 (-2) 200 2 false
  , { Build.rect 5 .intersection (m 200) (m (-30)) (m 230) (m 30) with ways := some [1] }
  , median 6 230 (-2) 500 2 false ]

/-- `forbid` (violated): On a divided highway a car makes a U-turn within its right-hand roadway between intersections, nowhere near a median opening: heading reverses within the window; no intersection or opening is overlapped while it turns. -/
def forbidPoses : List Pose :=
  line 21 (-100) (-26) 10 0 hE ++ uTurnAt 100 ++ line 5 90 (-6) (-10) 0 hW
def forbidTrace : Trace := run dividedMap forbidPoses

/-- `permit` (compliant): A car drives straight along the right-hand roadway of the divided highway; no turn rises. -/
def permitTrace : Trace := run dividedMap (line 30 (-100) (-6) 10 0 hE)

/-- `idle` (not_applicable): A car makes a U-turn on an undivided highway; it was on no divided highway in the window. -/
def idleMap : List Structure :=
  [ Build.rect 7 .highway (m (-500)) (m (-30)) (m 500) (m 30)
  , Build.rect 1 .highway (m (-500)) (m 100) (m 500) (m 160)
  , median 2 (-500) 128 500 132 false ]
def idleTrace : Trace := run idleMap forbidPoses

/-- `blind` (unknown): As forbid, with kin.yaw_rate declared absent, so the heading change over the window is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `occasion_s2` (violated): A car begins a left turn on the divided highway mid-block, crossing toward a side driveway without an opening, and completes the turn off the divided highway; it was on the divided highway at turning observations of the window. -/
def occasion_s2Trace : Trace :=
  run (dividedMap ++ [Build.rect 8 .drivewayOrAlleyEntrance (m 138) (m 32) (m 158) (m 100)])
    (line 21 (-60) (-6) 10 0 hE ++ [⟨146, 0, hNE, 45⟩, ⟨148, 40, hN, 45⟩] ++ line 7 148 48 0 8 hN)

/-- `occasion_s2_outside` (not_applicable): A car leaves the divided highway onto an undivided road, drives straight on it, then turns left there; at no turning observation of the window was it on the divided highway. -/
def occasion_s2_outsideTrace : Trace :=
  run [ Build.rect 1 .highway (m (-500)) (m (-30)) (m 100) (m 30)
      , median 2 (-500) (-2) 100 2 false
      , Build.rect 7 .highway (m 100) (m (-30)) (m 600) (m 30) ]
    (line 25 (-80) (-6) 10 0 hE ++ [⟨166, -2, hNE, 45⟩, ⟨168, 6, hN, 45⟩] ++ line 3 168 14 0 8 hN)

/-- `occasion_s6` (compliant): A car makes a U-turn through a median opening: at some turning observations its footprint overlaps the median region whose opening attribute holds. -/
def occasion_s6Trace : Trace :=
  run dividedMap
    (line 21 (-210) (-6) 10 0 hE ++
      [⟨5, -1, hNE, 45⟩, ⟨10, 0, hN, 45⟩, ⟨8, 1, hNW, 45⟩, ⟨3, 1, hW, 45⟩] ++
      line 5 (-7) 6 (-10) 0 hW)

/-- `occasion_s6_outside` (violated): A car drives straight past and over a median opening region, then later, mid-block, reverses its heading within the roadway; while it turns it overlaps no opening and no intersection. -/
def occasion_s6_outsideTrace : Trace :=
  run dividedMap
    (line 15 (-100) (-3) 10 0 hE ++ line 6 50 (-26) 10 0 hE ++ uTurnAt 100 ++ line 5 90 (-6) (-10) 0 hW)

/-- `occasion_s7` (compliant): A car turns left at an intersection of the divided highway: its footprint overlaps the st.intersection region at turning observations. -/
def occasion_s7Trace : Trace :=
  run dividedMap
    (line 21 5 (-6) 10 0 hE ++ [⟨212, -2, hNE, 45⟩, ⟨215, 6, hN, 45⟩] ++ line 7 215 16 0 10 hN)

/-- `occasion_s7_outside` (violated): A car drives straight through an intersection, then mid-block makes a U-turn within the roadway; while it turns it overlaps no intersection and no opening. -/
def occasion_s7_outsideTrace : Trace :=
  run dividedMap (line 21 100 (-26) 10 0 hE ++ uTurnAt 300 ++ line 5 290 (-6) (-10) 0 hW)

/-- `branch_1` (violated): mid-block on the divided highway a car reverses its heading turning to
    the right, within its roadway: a U-turn that is never a left turn. -/
def branch_1Trace : Trace :=
  run dividedMap
    (line 21 (-100) (-6) 10 0 hE ++
      [⟨106, -8, hSE, -45⟩, ⟨108, -16, hS, -45⟩, ⟨106, -24, hSW, -45⟩, ⟨100, -26, hW, -45⟩] ++
      line 5 90 (-26) (-10) 0 hW)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (16000, 29000)) : Scenario :=
  { name := name
    rule := "NRS_484B_227_1_o3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s2" occasion_s2Trace .violated
  , witness "occasion_s2_outside" occasion_s2_outsideTrace .notApplicable (window := some (19000, 29000))
  , witness "occasion_s6" occasion_s6Trace .compliant
  , witness "occasion_s6_outside" occasion_s6_outsideTrace .violated
  , witness "occasion_s7" occasion_s7Trace .compliant
  , witness "occasion_s7_outside" occasion_s7_outsideTrace .violated
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_227_1_o3
