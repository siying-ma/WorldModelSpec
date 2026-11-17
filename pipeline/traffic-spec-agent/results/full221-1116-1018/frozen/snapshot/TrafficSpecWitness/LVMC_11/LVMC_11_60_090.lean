/-
  Witnesses for LVMC_11_60_090.

  Geometry (x east, y north, centimetres): an eastbound lane L (102) from x = 0 to 2000,
  y = 0 to 400, whose first 500 cm are a taxicab_stand curb zone K (101); intersection R (103)
  x = 2000 to 3000, y = −600 to 1000; past it an eastbound lane E (104) and a southbound lane S
  (105, y = −2000 to −600), a second intersection R2 (106, y = −3000 to −2000) and a lane S2
  (107) beyond it (only branch_1's cab reaches R2; elsewhere it is an unvisited intersection of
  the scene, so "no intersection other than r" is decided against a second one); in idle an
  intersection Q (108, x = −1000 to 0) the cab starts in.
  A right_turn_only regulatory sign D (201) with an unrestricted legend governs L (in idle it
  governs S instead, a lane the cab never enters).

  The cab (track 1, half-extents 225 × 90 × 75 cm) moves 50 cm per 50 ms scene (10 m/s), at the
  carla_scene_graph step, so the heading integration never crosses a gap longer than the step.
  Straight passages (forbid, idle, blind) keep a yaw rate of 0: heading change 0°, well above
  −45°. The right turn (permit, branch_1) yaws at −100°/s for 18 scenes (0.9 s) inside R, the
  heading vector following the yaw 5° per scene and the position following the heading: −90°,
  inside the band (−135°, −45°] by 45° on both sides.

  The first scene is outside each witness's window: at it `rises` and `since` cannot see the
  previous observation. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_60_090
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_60_090

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def dt : Q := Units.milliseconds 50

def standK : Structure :=
  { Build.rect 101 .curbZone (cm 0) (cm 0) (cm 500) (cm 400) with curbKind := some .taxicabStand }
def laneL : Structure := Build.rect 102 .lane (cm 0) (cm 0) (cm 2000) (cm 400)
def interR : Structure := Build.rect 103 .intersection (cm 2000) (cm (-600)) (cm 3000) (cm 1000)
def laneE : Structure := Build.rect 104 .lane (cm 3000) (cm 0) (cm 6000) (cm 400)
def laneS : Structure := Build.rect 105 .lane (cm 2000) (cm (-2000)) (cm 3000) (cm (-600))
def interR2 : Structure := Build.rect 106 .intersection (cm 2000) (cm (-3000)) (cm 3000) (cm (-2000))
def laneS2 : Structure := Build.rect 107 .lane (cm 2000) (cm (-6000)) (cm 3000) (cm (-3000))
def interQ : Structure := Build.rect 108 .intersection (cm (-1000)) (cm (-600)) (cm 0) (cm 1000)

/-- The right_turn_only sign, its legend read with no restriction. -/
def signOn (governed : List RegionId) : Device :=
  { Build.sign 201 .regulatorySign governed with code := some .rightTurnOnly, conditions := some {} }

def env0 : Env :=
  { civilTime := some { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := 600 } }

def cab (pos heading : Vec) (yaw : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.taxicab] pos heading (Units.metresPerSecond 10) (cm 225, cm 90, cm 75))
    (fun k => { k with yawRate := yaw })

/-- Straight eastbound along y = 225 cm, from x = x0 at scene 0, 50 cm per scene. -/
def straightPos (x0 : Int) (k : Nat) : Vec := (cm (x0 + 50 * (k : Int)), cm 225)

/-- cos and sin of 5·j degrees, j = 0 … 18, to seven decimals (×10⁷). -/
def cosTab : List Int :=
  [10000000, 9961947, 9848078, 9659258, 9396926, 9063078, 8660254, 8191520, 7660444, 7071068,
   6427876, 5735764, 5000000, 4226183, 3420201, 2588190, 1736482, 871557, 0]
def sinTab : List Int :=
  [0, 871557, 1736482, 2588190, 3420201, 4226183, 5000000, 5735764, 6427876, 7071068,
   7660444, 8191520, 8660254, 9063078, 9396926, 9659258, 9848078, 9961947, 10000000]

/-- The turning cab's heading: east to scene 40, then 5° clockwise per scene over scenes 41–58
    (the yaw rate of −100°/s held over the 50 ms before each), south from scene 58 on. -/
def turnHeading (k : Nat) : Vec :=
  let j := if k ≤ 40 then 0 else if k ≤ 58 then k - 40 else 18
  (Units.ratio (cosTab.getD j 0) 10000000, Units.ratio (-(sinTab.getD j 0)) 10000000)

def turnYaw (k : Nat) : Option Q :=
  if 41 ≤ k ∧ k ≤ 58 then some (Units.degrees (-100)) else some Q.zero

/-- Position from (225, 225) cm, each scene 50 cm along its own heading: eastbound to x = 2225 at
    scene 40, the turn inside R to about (2773, −373) at scene 58, then southbound. -/
def turnPos (k : Nat) : Vec :=
  (List.range k).foldl (fun (p : Vec) i =>
    let h := turnHeading (i + 1)
    (Q.add p.1 (Q.mul h.1 (cm 50)), Q.add p.2 (Q.mul h.2 (cm 50)))) (cm 225, cm 225)

/-- `forbid` (violated): A taxicab leaves a taxicab_stand curb zone into a lane governed by a right_turn_only sign, reaches the first intersection and goes straight through it: at its exit the heading change since entry is about 0 degrees.
    Leaves K at scene 6, enters R at 36, exits it at 56 with a heading change of 0°. -/
def forbidTrace : Trace :=
  Build.trace 62 0 dt fun k t =>
    Build.scene t (some 1)
      [ cab (straightPos 225 k) Build.east (some Q.zero) ]
      [ standK, laneL, interR, laneE, laneS, interR2, laneS2 ]
      [ signOn [102] ]
      (env := env0)

/-- `permit` (compliant): The same taxicab turns right through the first intersection: at its exit the heading change since entry is about -90 degrees.
    Leaves K at scene 6, enters R at 36, turns over 41–58, exits R southward at 63: −90°. -/
def permitTrace : Trace :=
  Build.trace 68 0 dt fun k t =>
    Build.scene t (some 1)
      [ cab (turnPos k) (turnHeading k) (turnYaw k) ]
      [ standK, laneL, interR, laneE, laneS, interR2, laneS2 ]
      [ signOn [102] ]
      (env := env0)

/-- `idle` (not_applicable): A taxicab leaves the stand into a lane no right_turn_only sign governs and goes straight through the first intersection.
    The cab starts in intersection Q, enters K at scene 1, leaves it into L at 11 (the sign governs
    S, not L), crosses R over 41–60 and exits it at 61. -/
def idleTrace : Trace :=
  Build.trace 66 0 dt fun k t =>
    Build.scene t (some 1)
      [ cab (straightPos (-25) k) Build.east (some Q.zero) ]
      [ interQ, standK, laneL, interR, laneE, laneS ]
      [ signOn [105] ]
      (env := env0)

/-- `blind` (unknown): As in forbid, but the source supplies no yaw rate while the cab is in the intersection, so the heading change through it is unknown. -/
def blindTrace : Trace :=
  Build.trace 62 0 dt fun k t =>
    Build.scene t (some 1)
      [ cab (straightPos 225 k) Build.east (if 36 ≤ k ∧ k ≤ 56 then none else some Q.zero) ]
      [ standK, laneL, interR, laneE, laneS, interR2, laneS2 ]
      [ signOn [102] ]
      (env := env0)

/-- `branch_1` (not_applicable): The taxicab turns right through the first intersection after the signed stand, then goes straight through a second intersection: at the exit of the second, an intersection other than it was occupied since the departure, so it is not the first.
    As permit, then south through S into R2 at scene 91 and out of it at 111; the window is the
    stretch after the exit from R (scene 64 on). -/
def branch_1Trace : Trace :=
  Build.trace 120 0 dt fun k t =>
    Build.scene t (some 1)
      [ cab (turnPos k) (turnHeading k) (turnYaw k) ]
      [ standK, laneL, interR, laneE, laneS, interR2, laneS2 ]
      [ signOn [102] ]
      (env := env0)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_60_090"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (50, 3050))
  , witness "permit" permitTrace .compliant (window := some (50, 3350))
  , witness "idle" idleTrace .notApplicable (window := some (100, 3250))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (window := some (50, 3050))
  , witness "branch_1" branch_1Trace .notApplicable (window := some (3200, 5950)) ]

end TrafficSpecWitness.LVMC_11_60_090
