/-
  Witnesses for NRS_484B_307_5a_o1.

  The map: approach lane c (region 10), x ∈ [-30, 0], y ∈ [-4, 0], direction east, recorded as
  entering intersection i (region 20), the square x ∈ [0, 20], y ∈ [-10, 10]. Head s (device 1)
  governs c. The subject (track 1) is a motor vehicle, half-length 2 m, half-width 1 m.

  Every trace has nine scenes 50 ms apart (t = 0 … 400 ms, the 20 Hz sampling of the acquisition
  standard). k0, k1: the car waits on c, its footprint clear of i. k2 (t = 100): its entry, the
  footprint across the line between c and i. k3 … k6: inside i, each with its yaw rate; the entry and
  every scene from the exit on carry a zero yaw rate, so the heading change since the entry is the sum
  of the four interior rates × 50 ms whichever end of an interval holds the rate. k7 (t = 350): the
  exit, the footprint clear of every region. k8: beyond the exit.

  Heading changes: a left turn of 4 × 440 °/s × 0.05 s = +88° (forbid, idle, blind, outside), +90°
  (occasion_s1: 450 °/s); straight through 4 × 10 °/s × 0.05 s = +2° (permit); a right turn −88°
  (branch_1); a reversal 4 × 900 °/s × 0.05 s = 180° (branch_2). Against turn_min 45°, u_turn_min 135°.

  The window opens at t = 50 ms: the first scene has no observation before it, so its exit edge is
  undecided there; every instant the witnesses speak about lies inside the window.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_5a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_5a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneC : Structure :=
  Build.lane 10 [(m (-30), m (-4)), (m 0, m (-4)), (m 0, m 0), (m (-30), m 0)] Build.east
    (enters := some 20)
def interI : Structure := Build.rect 20 .intersection (m 0) (m (-10)) (m 20) (m 10)

/-- One observation of the car: position, heading, yaw rate (°/s; `none` unobserved), regions occupied. -/
structure Pose where
  pos : Vec
  heading : Vec
  yaw : Option Q
  occ : List RegionId

def pose (x y : Int) (h : Vec) (w : Option Int) (occ : List RegionId) : Pose :=
  { pos := (m x, m y), heading := h, yaw := w.map Units.degrees, occ := occ }

def approach : List Pose :=
  [ pose (-8) (-2) Build.east (some 0) [10]
  , pose (-4) (-2) Build.east (some 0) [10]
  , pose 0 (-2) Build.east (some 0) [10, 20] ]

def leftTurn (w : Int) : List Pose :=
  approach ++
  [ pose 5 (-1) (m 5, m 2) (some w) [20]
  , pose 9 1 (m 1, m 1) (some w) [20]
  , pose 11 5 (m 2, m 5) (some w) [20]
  , pose 12 9 (m 1, m 28) (some w) [20]
  , pose 12 14 (m 1, m 28) (some 0) []
  , pose 12 18 (m 1, m 28) (some 0) [] ]

def straightThrough : List Pose :=
  approach ++
  [ pose 5 (-2) (m 100, m 1) (some 10) [20]
  , pose 10 (-2) (m 100, m 2) (some 10) [20]
  , pose 15 (-2) (m 100, m 3) (some 10) [20]
  , pose 20 (-2) (m 100, m 4) (some 10) [20]
  , pose 25 (-2) (m 100, m 4) (some 0) []
  , pose 29 (-2) (m 100, m 4) (some 0) [] ]

def rightTurn : List Pose :=
  approach ++
  [ pose 5 (-3) (m 5, m (-2)) (some (-440)) [20]
  , pose 9 (-5) (m 1, m (-1)) (some (-440)) [20]
  , pose 11 (-6) (m 2, m (-5)) (some (-440)) [20]
  , pose 12 (-9) (m 1, m (-28)) (some (-440)) [20]
  , pose 12 (-14) (m 1, m (-28)) (some 0) []
  , pose 12 (-18) (m 1, m (-28)) (some 0) [] ]

def reversal : List Pose :=
  approach ++
  [ pose 6 0 (m 1, m 1) (some 900) [20]
  , pose 8 4 (m 0, m 1) (some 900) [20]
  , pose 5 6 (m (-1), m 1) (some 900) [20]
  , pose 3 5 Build.west (some 900) [20]
  , pose (-4) 5 Build.west (some 0) []
  , pose (-8) 5 Build.west (some 0) [] ]

/-- The yaw rate unobserved while the car is inside i (k3 … k6). -/
def blindInside (ps : List Pose) : List Pose :=
  (List.range ps.length).zip ps |>.map fun (k, p) =>
    if 3 ≤ k ∧ k ≤ 6 then { p with yaw := none } else p

def arrow : List SignalIndication := [.greenArrow .straight]

def passage (ps : List Pose) (shows : Nat → List SignalIndication) : Trace :=
  Build.trace ps.length 0 (Units.milliseconds 50) fun k t =>
    let p := ps.getD k (pose 0 0 Build.east none [])
    let u := Build.withKin (Build.user 1 [.motorVehicle] p.pos p.heading (m 5) (m 2, m 1, cm 75))
      fun kn => { kn with yawRate := p.yaw }
    Build.scene t (some 1) [u] [laneC, interI] [Build.signal 1 [10] (shows k)]
      (occupies := some (p.occ.map fun r => (1, r)))

/-- `forbid` (violated): A car occupies lane c, recorded as entering intersection i and governed by head s displaying green_arrow(straight) alone; it enters i, its heading changes by +88 degrees inside i, and it leaves i while s still displays the arrow. -/
def forbidTrace : Trace := passage (leftTurn 440) fun _ => arrow

/-- `permit` (compliant): Same arrow; the car passes through i with a heading change of 2 degrees and leaves it. -/
def permitTrace : Trace := passage straightThrough fun _ => arrow

/-- `idle` (not_applicable): s displays circular_green alone from before the car's entry until after its exit; the car turns left through i. -/
def idleTrace : Trace := passage (leftTurn 440) fun _ => [.circularGreen]

/-- `blind` (unknown): As forbid, but the source supplies no yaw rate for the car while it is inside i: which movement it made is unknown. -/
def blindTrace : Trace := passage (blindInside (leftTurn 440)) fun _ => arrow

/-- `occasion_s1` (violated): s displays green_arrow(straight) alone at the car's entry into i and changes to circular_yellow alone while the car is turning left inside i; the car leaves i with a heading change of +90 degrees: the arrow was displayed for part of the passage only. -/
def occasion_s1Trace : Trace :=
  passage (leftTurn 450) fun k => if k ≤ 3 then arrow else [.circularYellow]

/-- `occasion_s1_outside` (not_applicable): s displays green_arrow(straight) alone only while the car waits on c before its entry; from the entry to the exit s displays circular_green alone; the car turns left through i. -/
def occasion_s1_outsideTrace : Trace :=
  passage (leftTurn 440) fun k => if k ≤ 1 then arrow else [.circularGreen]

/-- `branch_1` (violated): same arrow; the car turns right through i, −88 degrees. -/
def branch_1Trace : Trace := passage rightTurn fun _ => arrow

/-- `branch_2` (violated): same arrow; the car reverses its direction inside i, +180 degrees. -/
def branch_2Trace : Trace := passage reversal fun _ => arrow

/-- `branch_3` (not_applicable): s displays green_arrow(straight) together with circular_red
    throughout — not the arrow alone; the car turns left through i. -/
def branch_3Trace : Trace := passage (leftTurn 440) fun _ => [.greenArrow .straight, .circularRed]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_5a_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (50, 400)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]
  , witness "occasion_s1" occasion_s1Trace .violated
  , witness "occasion_s1_outside" occasion_s1_outsideTrace .notApplicable
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_307_5a_o1
