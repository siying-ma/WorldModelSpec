/-
  Witnesses for NRS_484B_250_1.

  Geometry: intersection i (region 10) is the square |x|, |y| ≤ 6 m. x (track 1) approaches it
  northbound on lane c (11, on highway 20, entering 10). In the crossing layout, y (track 2)
  approaches eastbound on lane c2 (12, on highway 21, entering 10): directions perpendicular. In the
  skewed layout, y approaches on lane c2 (12, on highway 21) whose designated direction is (1, -2):
  its cosine with c's north is about -0.89, well below minus the opposed cosine. The intersection
  lies on both highways.

  Instants: 27 scenes, 40 ms apart (finer than the 50 ms heading step). y occupies c2 at scene 0 and
  enters i at scene 1 (recorded, occupying c2 and i), then occupies i alone; x occupies c until
  scene 24, enters i at scene 25 (occupying c and i), and occupies i alone at 26. Where y turns
  (branch_4) it turns a quarter left over the interval ending at scene 10 (2250°/s for 40 ms), its
  heading rotated exactly to match. The window starts at scene 1, the first scene with an
  observation before it. Occupancy is stated, since a body at the entry overlaps two regions.
  Intentions are declared at every scene; yaw rates are observed (0 unless the scene turns y).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def nScenes : Nat := 27
def xEntry : Nat := 25
def yLeaveAt : Nat := 6

def hX : Structure := Build.rect 20 .highway (m (-6)) (m (-60)) (m 6) (m 60)
def hYCross : Structure := Build.rect 21 .highway (m (-60)) (m (-6)) (m 60) (m 6)
def hYSkew : Structure :=
  Build.region 21 .highway [(m (-36), m 66), (m (-24), m 66), (m 6, m 6), (m (-6), m 6)]
def inter : Structure :=
  { Build.rect 10 .intersection (m (-6)) (m (-6)) (m 6) (m 6) with ways := some [20, 21] }
def laneC : Structure :=
  { Build.lane 11 [(m 0, m (-60)), (m 6, m (-60)), (m 6, m (-6)), (m 0, m (-6))] Build.north
      (enters := some 10) with ways := some [20] }
def laneC2Cross : Structure :=
  { Build.lane 12 [(m (-60), m (-6)), (m (-6), m (-6)), (m (-6), m 0), (m (-60), m 0)] Build.east
      (enters := some 10) with ways := some [21] }
def laneC2Skew : Structure :=
  { Build.lane 12 [(m (-36), m 66), (m (-30), m 66), (m 0, m 6), (m (-6), m 6)] (m 1, m (-2))
      (enters := some 10) with ways := some [21] }

def structures (skew : Bool) : List Structure :=
  if skew then [hX, hYSkew, inter, laneC, laneC2Skew] else [hX, hYCross, inter, laneC, laneC2Cross]

def car (track : TrackId) (pos heading : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user track [.motorVehicle] pos heading (Units.metresPerSecond 5) (m 2, m 1, m 1))
    (fun k => { k with yawRate := some yaw })

def xPos (k : Nat) : Vec :=
  if k < xEntry then (m 3, m (-10)) else if k == xEntry then (m 3, m (-6)) else (m 3, m (-2))

def yPos (skew : Bool) (k : Nat) : Vec :=
  if skew then (if k == 0 then (m (-4), m 10) else (m (-1), m 2))
  else (if k == 0 then (m (-10), m (-3)) else (m (-2), m (-3)))

def occupancy (yPresent : Bool) (k : Nat) : List (TrackId × RegionId) :=
  let xo : List (TrackId × RegionId) :=
    if k < xEntry then [(1, 11)] else if k == xEntry then [(1, 11), (1, 10)] else [(1, 10)]
  let yo : List (TrackId × RegionId) :=
    if !yPresent then [] else if k == 0 then [(2, 12)] else if k == 1 then [(2, 12), (2, 10)]
    else [(2, 10)]
  xo ++ yo

/-- Where y turns: a quarter turn to the left over the interval ending at this scene, at a yaw rate
    of 90° per 40 ms, so that the heading change is exact. -/
def yTurnAt : Nat := 10

/-- One scene of a layout: `skew` the opposed layout, `yLeaves` y gone from scene `yLeaveAt` on,
    the declared left-turn intentions of x and y, whether y turns left inside i, the devices. -/
def sceneAt (skew yLeaves xLeft yLeft yTurns : Bool) (devs : List Device) (k : Nat)
    (t : Timestamp) : Scene :=
  let yPresent := !(yLeaves && k ≥ yLeaveAt)
  let x := car 1 (xPos k) Build.north Q.zero
  let yHeading : Vec :=
    if yTurns && k ≥ yTurnAt then (if skew then Build.east else Build.north)
    else (if skew then Build.south else Build.east)
  let yYaw : Q := if yTurns && k == yTurnAt then Units.degrees 2250 else Q.zero
  let y := car 2 (yPos skew k) yHeading yYaw
  let xi : DeclaredIntent := { vehicle := 1, target := 10, values := [("int.left_turn", xLeft)] }
  let yi : DeclaredIntent := { vehicle := 2, target := 10, values := [("int.left_turn", yLeft)] }
  Build.scene t (some 1) (if yPresent then [x, y] else [x]) (structures skew) devs
    (occupies := some (occupancy yPresent k))
    (intents := if yPresent then [xi, yi] else [xi])

def layout (skew : Bool) (yLeaves : Bool := false) (xLeft yLeft : Bool := false)
    (yTurns : Bool := false) (devs : List Device := []) : Trace :=
  Build.trace nScenes 0 (Units.milliseconds 40) fun k t => sceneAt skew yLeaves xLeft yLeft yTurns devs k t

def stopOnC : Device := Build.sign 30 .stopSign [11]
def stopOnI : Device := Build.sign 30 .stopSign [10]
def yieldOnI : Device := Build.sign 31 .yieldSign [10]
def yieldOnC : Device := Build.sign 31 .yieldSign [11]
def deadSignal : Device := { Build.signal 32 [10, 11] [.dark] with inoperative := some true }
def workingSignalOnC : Device :=
  { Build.signal 33 [11] [.circularGreen] with inoperative := some false, uncovered := some true }
def workingSignalOnI : Device :=
  { Build.signal 33 [10] [.circularGreen] with inoperative := some false, uncovered := some true }

/-- `forbid` (violated): No device governs i or its approaches. The recording begins with both vehicles on their approach carriers. Vehicle y enters i from carrier c2 on highway h2 (its entry is recorded); x, on carrier c on highway h (c not on h2, directions not opposed), enters i while y still occupies i. -/
def forbidTrace : Trace := layout false

/-- `permit` (compliant): As forbid, but x waits on c until y has left i and enters i as the only road user in the scene. -/
def permitTrace : Trace := layout false (yLeaves := true)

/-- `idle` (not_applicable): A dev.stop_sign governs c; signals are absent; x enters i while y occupies i. -/
def idleTrace : Trace := layout false (devs := [stopOnC])

/-- `blind` (unknown): As forbid, with both entries inside the recording, but rel.occupies is not observed, so neither x's entry nor y's presence in i is decided. -/
def blindTrace : Trace := layout false

/-- `branch_1` (violated): A dev.traffic_signal governing i is dev.inoperative (NRS_484B_250_4_o1 applies); y entered i (recorded) from a different highway; x enters i while y occupies it. -/
def branch_1Trace : Trace := layout false (devs := [deadSignal])

/-- `branch_2` (compliant): At a skewed junction, y entered i (recorded) through c2 on another highway whose designated direction is opposed to c's, and int.left_turn y i is declared; x enters while y is in i: the pair is excepted. -/
def branch_2Trace : Trace := layout true (yLeft := true)

/-- `branch_3` (violated): skewed, opposed approaches, no left turn declared or made by either. -/
def branch_3Trace : Trace := layout true

/-- `branch_4` (compliant): skewed, opposed; y declares no left turn but has turned left 90° since entering i. -/
def branch_4Trace : Trace := layout true (yTurns := true)

/-- `branch_5` (compliant): skewed, opposed; x declares a left turn at i. -/
def branch_5Trace : Trace := layout true (xLeft := true)

/-- `branch_6` (not_applicable): a yield sign governs i. -/
def branch_6Trace : Trace := layout false (devs := [yieldOnI])

/-- `branch_7` (not_applicable): a working traffic signal governs c. -/
def branch_7Trace : Trace := layout false (devs := [workingSignalOnC])

/-- `branch_8` (not_applicable): a working traffic signal governs i. -/
def branch_8Trace : Trace := layout false (devs := [workingSignalOnI])

/-- `branch_9` (not_applicable): a stop sign governs i. -/
def branch_9Trace : Trace := layout false (devs := [stopOnI])

/-- `branch_10` (not_applicable): a yield sign governs c. -/
def branch_10Trace : Trace := layout false (devs := [yieldOnC])

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (40, 1040)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .notApplicable
  , witness "branch_10" branch_10Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_250_1
