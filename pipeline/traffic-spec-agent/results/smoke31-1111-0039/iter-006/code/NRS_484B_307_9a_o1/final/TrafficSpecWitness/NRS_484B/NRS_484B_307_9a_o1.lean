/-
  Witnesses for NRS_484B_307_9a_o1.

  Geometry (metres, +x east, +y north): an eastbound approach lane 1 (x −50…0, y 0…4) that enters
  intersection 10 (x 0…20, y −16…20); exit lanes 2 (eastbound, x 20…70, y 0…4), 3 (northbound,
  x 8…12, y 20…70) and 4 (southbound, x 8…12, y −66…−16). A traffic signal 100 governs lane 1
  (branch_2: the intersection 10 instead).

  Instants every 50 ms (the profile's sampling), 36 of them (0 … 1750 ms). x (track 1) runs at
  20 m/s, 1 m per interval along its heading: on lane 1 until 200 ms; at 250 ms (instant 5) its
  front crosses into the intersection (the entry; its rear stays on lane 1 to 450 ms); a straight
  passage clears the intersection at 1500 ms, a turn at 1600 ms (the leaving, the instant judged).
  A straight passage keeps a zero yaw rate; a turn yaws at ±100 °/s over the intervals ending at
  instants 6 … 23, its heading turning 5° per interval (90° through the intersection, against a
  45° recognition angle), left positive. The windows start at 50 ms, the first instant with an
  observation before it. Every figure here is the witness's own.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def approach : RegionId := 1
def exitEast : RegionId := 2
def exitNorth : RegionId := 3
def exitSouth : RegionId := 4
def junction : RegionId := 10
def signalId : DeviceId := 100

def nSteps : Nat := 36
def kEntry : Nat := 5

def box (x0 y0 x1 y1 : Int) : List Vec := [(m x0, m y0), (m x1, m y0), (m x1, m y1), (m x0, m y1)]

def structures : List Structure :=
  [ Build.lane approach (box (-50) 0 0 4) Build.east (enters := some junction)
  , Build.rect junction .intersection (m 0) (m (-16)) (m 20) (m 20)
  , Build.lane exitEast (box 20 0 70 4) Build.east
  , Build.lane exitNorth (box 8 20 12 70) Build.north
  , Build.lane exitSouth (box 8 (-66) 12 (-16)) Build.south ]

/-- The movement through the intersection. -/
inductive Move
  | straight
  | left
  | right

def exitOf : Move → RegionId
  | .straight => exitEast
  | .left => exitNorth
  | .right => exitSouth

/-- The first instant at which x's footprint no longer overlaps the intersection. -/
def kLeave : Move → Nat
  | .straight => 30
  | .left => 32
  | .right => 32

/-- cos (5°·j) for j = 0 … 18, in millionths; sin (5°·j) is entry 18 − j. -/
def cosTab : List Int :=
  [1000000, 996195, 984808, 965926, 939693, 906308, 866025, 819152, 766044, 707107,
   642788, 573576, 500000, 422618, 342020, 258819, 173648, 87156, 0]

/-- A turn yaws at 100 °/s over the 18 intervals ending at instants 6 … 23 (5° each, the rate at
    an instant held over the interval before it): 90° in all. -/
def turning (k : Nat) : Bool := 6 ≤ k && k ≤ 23

def yawOf (mv : Move) (k : Nat) : Q :=
  if turning k then
    match mv with
    | .straight => Q.zero
    | .left => Units.degrees 100
    | .right => Units.degrees (-100)
  else Q.zero

/-- The heading at instant k: east, turned 5° per turning interval to the side of the move. -/
def headingAt (mv : Move) (k : Nat) : Vec :=
  let j := Nat.min (k - kEntry) 18
  let c := Units.ratio (cosTab.getD j 0) 1000000
  let s := Units.ratio (cosTab.getD (18 - j) 0) 1000000
  match mv with
  | .straight => Build.east
  | .left => (c, s)
  | .right => (c, Q.neg s)

/-- The position at instant k: 1 m per interval (20 m/s) along the heading held over it, from
    (−1.8, 2) at the entry. -/
def posAt (mv : Move) (k : Nat) : Vec :=
  if k ≤ kEntry then (cm (100 * (Int.ofNat k - 5) - 180), m 2)
  else
    (List.range (k - kEntry)).foldl
      (fun p i => let h := headingAt mv (i + kEntry + 1); (Q.add p.1 h.1, Q.add p.2 h.2))
      (cm (-180), m 2)

/-- The regions x's footprint overlaps at instant k: the approach until its rear clears it. -/
def occupiedAt (mv : Move) (k : Nat) : List RegionId :=
  if k < kEntry then [approach]
  else if k ≤ 9 then [approach, junction]
  else if k < kLeave mv then [junction]
  else [exitOf mv]

def subjectAt (cls : List RoadUserClass) (ext : Q × Q × Q) (mv : Move) (k : Nat) : RoadUser :=
  Build.withKin (Build.user 1 cls (posAt mv k) (headingAt mv k) (Units.metresPerSecond 20) ext)
    (fun kn => { kn with yawRate := some (yawOf mv k) })

def carExt : Q × Q × Q := (cm 250, cm 90, cm 75)
def bikeExt : Q × Q × Q := (cm 90, cm 30, cm 60)

def passage (cls : List RoadUserClass) (ext : Q × Q × Q) (mv : Move) (sig : Device) : Trace :=
  Build.trace nSteps 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1)
      [ subjectAt cls ext mv k ]
      structures
      [ sig ]
      (occupies := some ((occupiedAt mv k).map fun r => (1, r)))

def redLeft : Device := Build.signal signalId [approach] [.circularRed, .greenArrow .left]
def redRight : Device := Build.signal signalId [approach] [.circularRed, .greenArrow .right]
def green : Device := Build.signal signalId [approach] [.circularGreen]

/-- `forbid` (violated): x (ru.motor_vehicle), recorded from upstream, enters intersection i from lane c that a signal s governs; s displays circular_red with green_arrow(left) at the entry; x crosses i and leaves it with a heading change since entry well inside p.turn_recognition_angle (straight through). -/
def forbidTrace : Trace := passage [.motorVehicle] carExt .straight redLeft

/-- `permit` (compliant): The same entry under circular_red with green_arrow(left); x leaves i with a heading change since entry above p.turn_recognition_angle to the left. -/
def permitTrace : Trace := passage [.motorVehicle] carExt .left redLeft

/-- `idle` (not_applicable): s displays circular_green at x's entry into i; x crosses straight through. -/
def idleTrace : Trace := passage [.motorVehicle] carExt .straight green

/-- `blind` (unknown): x, recorded from upstream, enters i from lane c and crosses straight through, but the source does not observe s's state at the entry. -/
def blindTrace : Trace := passage [.motorVehicle] carExt .straight redLeft

/-- `branch_1` (not_applicable): x is a ru.bicycle; it enters i under circular_red with green_arrow(left) and leaves straight through: paragraph (b) applies (NRS_484B_307_9b_o1 engaged), so this duty does not. -/
def branch_1Trace : Trace := passage [.bicycle] bikeExt .straight redLeft

/-- `branch_2` (violated): the signal governs the intersection itself, not the approach lane; red
    with green_arrow(left) at the entry; x crosses straight through. -/
def branch_2Trace : Trace :=
  passage [.motorVehicle] carExt .straight (Build.signal signalId [junction] [.circularRed, .greenArrow .left])

/-- `branch_3` (violated): red with green_arrow(right) at the entry; x turns left. -/
def branch_3Trace : Trace := passage [.motorVehicle] carExt .left redRight

/-- `branch_4` (compliant): red with green_arrow(right) at the entry; x turns right. -/
def branch_4Trace : Trace := passage [.motorVehicle] carExt .right redRight

def window : Option (Timestamp × Timestamp) := some (50, 1750)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o1"
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
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_9a_o1
