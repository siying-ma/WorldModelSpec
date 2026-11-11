/-
  Witnesses for NRS_484B_400_1_o1.

  Geometry (metres, +x east, +y north). Highway h (20) spans x ∈ [-100, 20], y ∈ [-10, 10]; the
  cross highway h2 (21) spans x ∈ [0, 20], y ∈ [-100, 10]; intersection i (10) is x ∈ [0, 20],
  y ∈ [-10, 10], on both. Two eastbound approach carriers of h end at x = 0 and enter i: the
  through lane c (11), y ∈ [-4, 0], and on its right the right turn lane R (12, `turn_lane`, side
  right), y ∈ [-8, -4]; both carry direction east. The northbound approach of h2 is the lane c2
  (13), x ∈ [10, 14], y ∈ [-100, -10], direction north, entering i; it has no turn lane.

  x (track 1, a motor vehicle, 4 m × 2 m) is sampled every 50 ms (90 scenes, 0 … 4450 ms). In
  its approach frame (along, lateral; lateral positive to its left) it starts 30 m before the
  entrance end and advances 0.45 m per scene (its path length grows 0.5 m per scene, never less
  than its displacement); its centre is at lateral -2 on c (or c2), -6 on R, and a lane change
  moves it 0.2 m sideways per scene. Its front crosses the entrance end at scene 63 (3150 ms): the
  entry into i, at which its body overlaps i and the approach carrier. From the entry it turns at
  90 deg/s (right: yaw -90, heading rotating clockwise; left: +90) for 20 scenes, 4.5 deg per
  scene, its heading written to six decimals of the cosine and sine, its position following its
  heading, and then holds the new heading. The heading change since the entry reaches 45 deg at
  scene 73 (the recognition instant) and 90 deg at scene 83. The path window of 15 m behind the
  entry spans scenes 33 … 63. int.turn is declared for x at i in every scene.

  Occupancy is stated per scene (the body straddles regions): the approach's highway throughout;
  a carrier by the centre's lateral place (c where lateral > -5, R where lateral < -3) until the
  rear has left it, eight scenes after the entry; i from the entry on. The scenarios name the
  instants from the entry onwards (`window`): before it, no entry into i has been seen, so the
  heading change since it and the read-back to it are unknown.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_400_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_400_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def iId : RegionId := 10
def cId : RegionId := 11
def rId : RegionId := 12
def c2Id : RegionId := 13
def hId : RegionId := 20
def h2Id : RegionId := 21

/-- The scene of the entry into i. -/
def entryScene : Nat := 63
def sceneCount : Nat := 90

def structures : List Structure :=
  [ Build.rect hId .highway (m (-100)) (m (-10)) (m 20) (m 10)
  , Build.rect h2Id .highway (m 0) (m (-100)) (m 20) (m 10)
  , { Build.rect iId .intersection (m 0) (m (-10)) (m 20) (m 10) with ways := some [hId, h2Id] }
  , { Build.lane cId [(m (-100), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-100), m 0)] Build.east
        (right := some rId) (enters := some iId) with ways := some [hId] }
  , { Build.lane rId [(m (-100), m (-8)), (m 0, m (-8)), (m 0, m (-4)), (m (-100), m (-4))] Build.east
        (left := some cId) (enters := some iId) with
        kind := .turnLane, turnSide := some .right, ways := some [hId] }
  , { Build.lane c2Id [(m 10, m (-100)), (m 14, m (-100)), (m 14, m (-10)), (m 10, m (-10))] Build.north
        (enters := some iId) with ways := some [h2Id] } ]

def intents : List DeclaredIntent :=
  [ { vehicle := 1, target := iId, values := [("int.turn", true)] } ]

/-- An approach: the world point of along 0, lateral 0 (on the entrance end), the forward and
    leftward unit vectors, x's highway, and the carriers a centre at a lateral place overlaps. -/
structure Approach where
  origin : Vec
  fwd : Vec
  left : Vec
  way : RegionId
  carriers : Q → List RegionId

def vadd (a b : Vec) : Vec := (Q.add a.1 b.1, Q.add a.2 b.2)

/-- A vector given in the approach frame, in the world frame. -/
def Approach.dir (ap : Approach) (v : Vec) : Vec := vadd (Build.scale ap.fwd v.1) (Build.scale ap.left v.2)
def Approach.point (ap : Approach) (v : Vec) : Vec := vadd ap.origin (ap.dir v)

/-- The approach on h: east along c and R (a body at lateral y overlaps c where y > -5, R where
    y < -3, with half-width 1 m). -/
def onH : Approach :=
  { origin := (m 0, m 0), fwd := Build.east, left := Build.north, way := hId
    carriers := fun y => (if Q.lt (m (-5)) y then [cId] else []) ++ (if Q.lt y (m (-3)) then [rId] else []) }

/-- The approach on h2: north along c2 (lateral -2 is x = 12). -/
def onH2 : Approach :=
  { origin := (m 10, m (-10)), fwd := Build.north, left := Build.west, way := h2Id
    carriers := fun _ => [c2Id] }

/-- Cosine and sine of 4.5·j degrees, j = 0 … 10, in millionths. -/
def trig : List (Int × Int) :=
  [ (1000000, 0), (996917, 78459), (987688, 156434), (972370, 233445), (951057, 309017)
  , (923880, 382683), (891007, 453990), (852640, 522499), (809017, 587785), (760406, 649448)
  , (707107, 707107) ]

/-- Cosine and sine of the turn angle after j scenes of turning (4.5 deg each, at most 90 deg). -/
def turnAngle (j : Nat) : Int × Int :=
  if j ≤ 10 then trig.getD j (1000000, 0)
  else if j ≤ 20 then (fun (c, s) => (s, c)) (trig.getD (20 - j) (1000000, 0))
  else (0, 1000000)

/-- The heading of x at scene k in the approach frame; `σ` is -1 for a right turn, +1 for a left. -/
def headingAt (σ : Int) (k : Nat) : Vec :=
  if k ≤ entryScene then (Units.ratio 1 1, Q.zero)
  else
    let (c, s) := turnAngle (k - entryScene)
    (Units.ratio c 1000000, Units.ratio (σ * s) 1000000)

/-- The yaw rate at scene k, held over the interval before it. -/
def yawAt (σ : Int) (k : Nat) : Q :=
  if entryScene < k && k ≤ entryScene + 20 then Units.degrees (σ * 90) else Q.zero

/-- The centre of x at scene k in the approach frame: along the approach at the lateral place
    `lat k`, then along its heading. -/
def posAt (lat : Nat → Q) (σ : Int) : Nat → Vec
  | 0 => (m (-30), lat 0)
  | k + 1 =>
    let p := posAt lat σ k
    if k + 1 ≤ entryScene then (Q.add p.1 (cm 45), lat (k + 1))
    else vadd p (Build.scale (headingAt σ (k + 1)) (cm 45))

/-- A drive through i along approach `ap`: `lat k` is x's lateral place on the approach at
    scene k, `σ` the hand of the turn. -/
def drive (ap : Approach) (lat : Nat → Q) (σ : Int) : Trace :=
  Build.trace sceneCount 0 (Units.milliseconds 50) fun k t =>
    let u := Build.withKin
      (Build.user 1 [.motorVehicle] (ap.point (posAt lat σ k)) (ap.dir (headingAt σ k))
        (Units.metresPerSecond 10) (m 2, m 1, m 1) (some (cm (50 * k))))
      fun kn => { kn with yawRate := some (yawAt σ k) }
    let onCarrier := if k ≤ entryScene + 8 then (ap.carriers (lat (min k entryScene))).map fun r => (1, r) else []
    let inI := if k ≥ entryScene then [(1, iId)] else []
    Build.scene t (some 1) [u] structures []
      (occupies := some ([(1, ap.way)] ++ onCarrier ++ inI)) (intents := intents)

def onC : Nat → Q := fun _ => m (-2)
def onR : Nat → Q := fun _ => m (-6)
/-- A lane change from c to R starting at scene `k0`, 0.2 m per scene, over 20 scenes. -/
def changeAt (k0 : Nat) : Nat → Q := fun k =>
  if k ≤ k0 then m (-2)
  else if k ≥ k0 + 20 then m (-6)
  else Q.sub (m (-2)) (cm (20 * ((k : Int) - k0)))

/-- `forbid` (violated): x (ru.motor_vehicle) approaches i on a through lane c of highway h whose approach also has a right st.turn_lane R entering i; int.turn is declared for x at i; x enters i from c and turns right beyond p.turn_recognition_angle. -/
def forbidTrace : Trace := drive onH onC (-1)

/-- `permit` (compliant): Same highway; x, with int.turn declared at i, is on R for the whole approach length before its entry, enters i from R and turns right. -/
def permitTrace : Trace := drive onH onR (-1)

/-- `idle` (not_applicable): x, with int.turn declared at i, turns left in i (heading change positive beyond p.turn_recognition_angle). -/
def idleTrace : Trace := drive onH onC 1

/-- `blind` (unknown): x turns right in i from a through lane with int.turn declared, but the source does not record which intersection the turn lane beside it enters, so whether the highway has a right turn lane for this approach is unknown. -/
def blindTrace : Trace := drive onH onC (-1)

/-- `branch_1` (violated): x moves from c into R late, inside the approach length (on c alone up
    to scene 41, astride 42 … 50, on R alone from 51), and enters i from R turning right: the
    approach was not made from the turn lane. -/
def branch1Trace : Trace := drive onH (changeAt 36) (-1)

/-- `branch_2` (compliant): x moves from c into R early, before the approach length (on R alone
    from scene 19, while the window behind the entry starts at scene 33), and turns right from R. -/
def branch2Trace : Trace := drive onH (changeAt 4) (-1)

/-- `branch_3` (not_applicable): x approaches i on the cross highway h2, whose approach has no
    right turn lane, and turns right; the turn lane R lies on h, not on x's highway. -/
def branch3Trace : Trace := drive onH2 onC (-1)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_400_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (3150, 4450)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_enters"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant
  , witness "branch_3" branch3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_400_1_o1
