/-
  Witnesses for NRS_484B_307_9a_o1.

  Geometry: an eastbound approach lane c (region 10, x ∈ [-60, 0], y ∈ [-4, 0]) whose entrance end
  is the intersection i (region 20, x ∈ [0, 20], y ∈ [-10, 10]). Signal s (device 30) governs c
  (or, in branch_5, i). Road user x (track 1, half-length 6 m, half-width 1.25 m, 12.5 m/s) is
  observed every 40 ms for 78 scenes, 0.5 m of travel per scene. It drives east along y = -2 m,
  its reference point at x = -5.75 m in scene 9, where its front first overlaps i (it still
  overlaps c, up to scene 32). Straight through, it leaves i in scene 73 (heading change 0°). For a
  turn it then follows an arc of 36 scenes, 2.5° per scene (yaw rate ±62.5 deg/s, the rate at a
  scene covering the interval before it; headings by Taylor series of cos and sin), and leaves i
  in scene 59 northbound after a left turn (+90° since entry) or in scene 51 southbound after a
  right turn (-90°), against the 45° turn recognition angle. Occupancy is stated per scene, as the
  footprint lies across c and i at the entry. Scene 0 has no observation before it; the witnesses
  speak about scenes 1–77 (`window`).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- Approach lane c, eastbound, entering i. -/
def laneC : Structure :=
  Build.lane 10 [(m (-60), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-60), m 0)] Build.east
    (enters := some 20)

/-- Intersection i. -/
def junction : Structure := Build.rect 20 .intersection (m 0) (m (-10)) (m 20) (m 10)

/-- x's footprint (half-length 6 m, half-width 1.25 m) over c (up to scene `cEnd`) and i (from
    scene 9 to the scene before `iExit`), as the geometry of `pose` places it. -/
def occupancy (cEnd iExit : Nat) (k : Nat) : List (TrackId × RegionId) :=
  (if k ≤ cEnd then [(1, 10)] else []) ++ (if 9 ≤ k ∧ k < iExit then [(1, 20)] else [])

/-- π, to 3·10⁻⁷. -/
def piQ : Q := Units.ratio 355 113
def rad (deg : Q) : Q := Q.div (Q.mul deg piQ) (Q.ofInt 180)

/-- The Taylor sums of cos and sin: `fuel` more terms from the k-th, θ² = `t2`. -/
def trigGo (t2 : Q) : Nat → Nat → Q → Q → Q → Q → Q × Q
  | 0, _, c, s, _, _ => (c, s)
  | fuel + 1, k, c, s, tc, ts =>
    let kk : Int := Int.ofNat k
    let tc' := Q.neg (Q.div (Q.mul tc t2) (Q.ofInt ((2 * kk - 1) * (2 * kk))))
    let ts' := Q.neg (Q.div (Q.mul ts t2) (Q.ofInt ((2 * kk) * (2 * kk + 1))))
    trigGo t2 fuel (k + 1) (Q.add c tc') (Q.add s ts') tc' ts'

/-- (cos θ, sin θ) by their Taylor series to the θ¹⁷ term (θ in radians, |θ| ≤ π/2). -/
def trig (θ : Q) : Q × Q := trigGo (Q.mul θ θ) 8 1 (Q.ofInt 1) θ (Q.ofInt 1) θ

/-- The heading turns 2.5° per scene during a turn (62.5 deg/s at 40 ms), 0.5 m of arc per scene. -/
def stepDeg : Q := Units.ratio 5 2
def turnRate : Q := Units.ratio 125 2
def stepLength : Q := Units.ratio 1 2
def radius : Q := Q.div stepLength (rad stepDeg)

/-- Pose (position, heading) in scene k: east along y = -2 m with the reference point at
    x = -5.75 m in scene 9 (the entry), then `steps` scenes of arc turning to side `σ` (1 left,
    -1 right, 0 none), then straight along the final heading; 0.5 m per scene throughout. -/
def pose (σ : Int) (steps : Nat) (k : Nat) : Vec × Vec :=
  let j := min (k - 9) steps
  let (c, s) := trig (rad (Q.mul stepDeg (Q.ofInt j)))
  let d := Q.mul stepLength (Q.ofInt ((k : Int) - 9 - j))
  let x := Q.add (Q.add (Units.centimetres (-575)) (Q.mul radius s)) (Q.mul d c)
  let y := Q.add (Q.add (m (-2)) (Q.mul (Q.ofInt σ) (Q.mul radius (Q.sub (Q.ofInt 1) c))))
             (Q.mul d (Q.mul (Q.ofInt σ) s))
  ((x, y), (c, Q.mul (Q.ofInt σ) s))

/-- A manoeuvre: side, scenes of turning, last scene over c, first scene off i. -/
structure Manoeuvre where
  σ : Int
  steps : Nat
  cEnd : Nat
  iExit : Nat

/-- Straight through: leaves i in scene 73. -/
def straight : Manoeuvre := ⟨0, 0, 32, 73⟩
/-- A 90° left turn (heading change since entry 90°): leaves i northbound in scene 59. -/
def leftTurn : Manoeuvre := ⟨1, 36, 32, 59⟩
/-- A 90° right turn (heading change since entry -90°): leaves i southbound in scene 51. -/
def rightTurn : Manoeuvre := ⟨-1, 36, 32, 51⟩

/-- x's passage from c through i; the yaw rate at a scene is the turn over the interval before it. -/
def passage (cls : List RoadUserClass) (mv : Manoeuvre) (devs : List Device) : Trace :=
  Build.trace 78 0 (Units.milliseconds 40) fun k t =>
    let (p, h) := pose mv.σ mv.steps k
    let yaw : Q := if 10 ≤ k ∧ k ≤ 9 + mv.steps then Q.mul (Q.ofInt mv.σ) turnRate else Q.zero
    let u := Build.withKin
      (Build.user 1 cls p h (Units.ratio 25 2) (m 6, cm 125, cm 150))
      (fun kin => { kin with yawRate := some yaw })
    Build.scene t (some 1) [u] [laneC, junction] devs (occupies := some (occupancy mv.cEnd mv.iExit k))

/-- The planned subject: a ru.bus, a vehicle of no class paragraph (b) names. The run's reading
    leaves it (and every other vehicle class tried) unresolved under paragraph (b)'s aggregates, so
    NRS_484B_307_9b_o1's engagement, and with it this rule's applicability, is unknown for it; see
    task_result.md. -/
def subjectClass : List RoadUserClass := [.bus]

def redLeft (gov : List RegionId) : Device := Build.signal 30 gov [.circularRed, .greenArrow .left]
def redRight (gov : List RegionId) : Device := Build.signal 30 gov [.circularRed, .greenArrow .right]

/-- `forbid` (violated): x (ru.bus, a vehicle of no class paragraph (b) names), recorded from upstream, enters intersection i from lane c that a signal s governs; s displays circular_red with green_arrow(left) at the entry; x crosses i and leaves it with a heading change since entry well inside p.turn_recognition_angle (straight through). -/
def forbidTrace : Trace := passage subjectClass straight [redLeft [10]]

/-- `permit` (compliant): x (ru.bus) makes the same entry under circular_red with green_arrow(left); x leaves i with a heading change since entry above p.turn_recognition_angle to the left. -/
def permitTrace : Trace := passage subjectClass leftTurn [redLeft [10]]

/-- `idle` (not_applicable): x (ru.bus): s displays circular_green at x's entry into i; x crosses straight through. -/
def idleTrace : Trace := passage subjectClass straight [Build.signal 30 [10] [.circularGreen]]

/-- `blind` (unknown): x (ru.bus), recorded from upstream, enters i from lane c and crosses straight through, but the source does not observe s's state at the entry. -/
def blindTrace : Trace := passage subjectClass straight [{ redLeft [10] with indications := none }]

/-- `branch_1` (not_applicable): x is a ru.motorcycle (a vehicle, and a motorcycle under paragraph (b)); it enters i under circular_red with green_arrow(left) and leaves straight through: NRS_484B_307_9b_o1 is engaged, so this duty does not apply. Differs from forbid only in x's class. -/
def branch_1Trace : Trace := passage [.motorcycle] straight [redLeft [10]]

/-- `branch_2` (not_applicable): x is a ru.bicycle, a device moved by human power and so no vehicle: it is not vehicular traffic; it enters i under circular_red with green_arrow(left) and leaves after a left turn. -/
def branch_2Trace : Trace := passage [.bicycle] leftTurn [redLeft [10]]

/-- `branch_3` (violated): x (ru.bus) enters i from lane c under circular_red with green_arrow(right) on s governing c, and leaves i after a left turn (heading change above p.turn_recognition_angle to the left). -/
def branch_3Trace : Trace := passage subjectClass leftTurn [redRight [10]]

/-- `branch_4` (compliant): x (ru.bus) enters i under circular_red with green_arrow(right) and leaves i after a right turn (heading change at most minus p.turn_recognition_angle). -/
def branch_4Trace : Trace := passage subjectClass rightTurn [redRight [10]]

/-- `branch_5` (violated): s governs the intersection i itself, not the approach lane; it displays circular_red with green_arrow(left) at x's (ru.bus) entry; x crosses straight through. -/
def branch_5Trace : Trace := passage subjectClass straight [redLeft [20]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (40, 3080)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9a_o1
