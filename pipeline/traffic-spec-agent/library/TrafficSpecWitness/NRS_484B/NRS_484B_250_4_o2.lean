/-
  Witnesses for NRS_484B_250_4_o2.

  A four-way intersection i (100), the square (-4, -4)–(4, 4) m. Approach carrier c (101): a
  northbound lane x ∈ [0, 4], y ∈ [-80, -4], entering i; its stop line (102) spans y ∈ [-6, -5.5].
  Crossing carrier c2 (103): a westbound lane x ∈ [4, 80], y ∈ [0, 4], entering i; its stop line
  (104) spans x ∈ [5.5, 6]. Signal d (200) governs i (c, in branch_1 and blind); it is uncovered
  and inoperative (dark), except in idle, where it shows circular green. In blind it governs c
  rather than i: the intersection is itself a travel region, and for it as a candidate carrier
  `st_lane_enters i i` is unknown (it carries no approach record); a signal governing i would leave
  that candidate undecided, so the verdict would not turn on the masked rel.occupies alone.

  Cars are 4 m × 2 m (half-extents 2, 1). Scenes every second, t = 0 … 12 s; each witness judges
  t = 1 … 12 s (the first scene has no observation before it for the entry).
  x (track 1) runs north along x = 2 m, halts at t = 5 … 7 s with its front 0.3 m short of the
  stop line (centre y = -8.3 m), and enters i at t = 9 s (centre y = -5 m, front -3 m, 3 m/s).
  forbid: vehicle y (2) drives east at 8 m/s along y = -1.5 m and is inside i at t = 9 s, 4.6 m
    from x's centre and receding (no predicted conflict).
  branch_1: vehicle y halts on c2 at t = 3 s, front 0.3 m short of its stop line (centre
    x = 8.3 m, y = 2 m), and waits there; x enters first. y's centre stays 6.3 m or more from x's
    predicted path (no conflict).
  branch_2: x halts with its front 30.3 m short of the stop line (t = 4, 5 s), then rolls through
    the line at 5–7 m/s and enters i at t = 11 s.
  branch_3: a pedestrian z (3) walks west at 1 m/s along y = 1.5 m, at x = 3.5 m when x enters:
    predicted closest approach about 0.6 m within about 2.1 s.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

def intersection : Structure := Build.rect 100 .intersection (m (-4)) (m (-4)) (m 4) (m 4)
def laneC : Structure :=
  Build.lane 101 [(m 0, m (-80)), (m 4, m (-80)), (m 4, m (-4)), (m 0, m (-4))] Build.north
    (enters := some 100)
def stopLineC : Structure :=
  { Build.rect 102 .stopLine (m 0) (cm (-600)) (m 4) (cm (-550)) with
    entranceOf := [101], entranceObserved := true }
def laneC2 : Structure :=
  Build.lane 103 [(m 4, m 0), (m 80, m 0), (m 80, m 4), (m 4, m 4)] Build.west
    (enters := some 100)
def stopLineC2 : Structure :=
  { Build.rect 104 .stopLine (cm 550) (m 0) (m 6) (m 4) with
    entranceOf := [103], entranceObserved := true }
def structures : List Structure := [intersection, laneC, stopLineC, laneC2, stopLineC2]

def darkSignal (governs : List RegionId) : Device :=
  { Build.signal 200 governs [.dark] with uncovered := some true, inoperative := some true }
def greenSignal : Device :=
  { Build.signal 200 [100] [.circularGreen] with uncovered := some true, inoperative := some false }

/-- Occupancy from the bodies, not the reference points: each user occupies every structure its
    footprint overlaps (a car entering i straddles c and i). -/
def bodyOccupancy (s : Scene) : Scene :=
  { s with occupies := s.users.flatMap fun u => match footprint s u.track with
      | none => []
      | some fp => s.structures.filterMap fun st => match st.boundary with
        | some poly => if Geom.polygonsOverlap fp poly then some (u.track, st.id) else none
        | none => none }

def scene (t : Timestamp) (users : List RoadUser) (devices : List Device) : Scene :=
  bodyOccupancy (Build.scene t (some 1) users structures devices)

def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (m 2, m 1, m 1)

/-- x's centre y (cm) and speed (m/s) per scene: halts short of the stop line, enters i at k = 9. -/
def xStops : List (Int × Int) :=
  [(-4000, 8), (-3200, 8), (-2400, 7), (-1700, 6), (-1200, 4), (-830, 0), (-830, 0), (-830, 0),
   (-700, 2), (-500, 3), (-200, 3), (200, 4), (700, 5)]

/-- x halts 30 m upstream of the stop line, rolls through it, enters i at k = 11. -/
def xRolls : List (Int × Int) :=
  [(-6000, 8), (-5200, 7), (-4500, 5), (-4000, 3), (-3830, 0), (-3830, 0), (-3600, 3), (-3000, 6),
   (-2300, 7), (-1600, 7), (-1000, 6), (-500, 5), (0, 5)]

def xCar (plan : List (Int × Int)) (k : Nat) : RoadUser :=
  let (y, v) := plan.getD k (0, 0)
  car 1 (m 2, cm y) Build.north (mps v)

/-- A vehicle crossing i eastbound at 8 m/s, at x = 5 m in scene `kIn`. -/
def yCrossing (kIn k : Nat) : RoadUser :=
  car 2 (cm (500 + 800 * ((k : Int) - kIn)), cm (-150)) Build.east (mps 8)

/-- y's centre x (cm) and speed on c2: halted short of c2's stop line from k = 3. -/
def yWaits : List (Int × Int) :=
  [(3000, 8), (2200, 7), (1500, 5), (830, 0), (830, 0), (830, 0), (830, 0), (830, 0), (830, 0),
   (830, 0), (830, 0), (830, 0), (830, 0)]

def yWaiting (k : Nat) : RoadUser :=
  let (x, v) := yWaits.getD k (0, 0)
  car 2 (cm x, m 2) Build.west (mps v)

/-- A pedestrian walking west at 1 m/s along y = 1.5 m, at x = 3.5 m in scene 9. -/
def zWalking (k : Nat) : RoadUser :=
  Build.user 3 [.pedestrian] (cm (1250 - 100 * (k : Int)), cm 150) Build.west (mps 1)
    (cm 30, cm 30, cm 90)

/-- `forbid` (violated): Signal d governing i is dev.inoperative; x halts within 0.5 m of the stop line marking its lane c, then enters i while vehicle y occupies i. -/
def forbidTrace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xStops k, yCrossing 9 k] [darkSignal [100]]

/-- `permit` (compliant): As forbid, but x is the only road user in the scene when it enters i after its halt. -/
def permitTrace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xStops k] [darkSignal [100]]

/-- `idle` (not_applicable): Signal d shows circular_green (not dev.inoperative) when x enters i. -/
def idleTrace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xStops k, yCrossing 9 k] [greenSignal]

/-- `blind` (unknown): As forbid, but rel.occupies of y and i is not observed at x's entry. -/
def blindTrace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xStops k, yCrossing 9 k] [darkSignal [101]]

/-- `branch_1` (violated): x halts at its stop line; vehicle y had halted at the stop line of crossing carrier c2 two seconds before x's halt began and still waits there, outside i; x enters i first. -/
def branch_1Trace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xStops k, yWaiting k] [darkSignal [101]]

/-- `branch_2` (not_applicable): As forbid, but x halted 30 m upstream of the stop line marking c (outside the stopping zone) and rolled through the line: the halt was not such a stop, NRS_484B_250_4_o1 is not complied with, and this duty does not arise. -/
def branch_2Trace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xRolls k, yCrossing 11 k] [darkSignal [100]]

/-- `branch_3` (violated): As permit, but a pedestrian walks across x's path inside i, predicted
    to come within the conflict clearance of x shortly after its entry: x does not proceed cautiously. -/
def branch_3Trace : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    scene t [xCar xStops k, zWalking k] [darkSignal [100]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, 12000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o2
