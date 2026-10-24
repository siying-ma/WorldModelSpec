/-
  Witnesses for NRS_484B_250_4_o1.

  The geometry, once and for all. The carriageway runs north (+y); the subject (track 1) is a
  motor vehicle 5 m long and 1.8 m wide (half-extents 2.5 m, 0.9 m, 0.75 m) whose reference point
  rides the middle of the approach lane at x = 1.8 m, heading north. The approach lane (region 11)
  is the strip x ∈ [0, 3.6] running up to y = 0; the intersection (region 10) is the square
  x ∈ [-6, 6], y ∈ [0, 12]. Where a witness needs them: the marked stop line (region 12) is the
  transverse strip y ∈ [-0.4, -0.2] across the approach, the crossing (region 14) is the band
  y ∈ [-9, -6] across the road, the vehicle's own way (region 30) is the north-south strip and the
  intersecting through highway (region 31) the east-west strip y ∈ [0, 12]. The dead head
  (device 50) is a signal head, uncovered, inoperative, showing a dark face.

  Instants are one second apart. The subject travels 5 m between observations, so the body never
  straddles a region boundary: at y = -3 it lies wholly in the approach lane (its outline spans
  y ∈ [-5.5, -0.5], a tenth of a metre short of the stop line), at y = 3 wholly inside the
  intersection. Each trace runs about 95 m of path before the entry, so the stretch the rule
  searches behind the entry (and the crossing look-back inside it) is covered by observations and
  never truncated. Each witness speaks about the instants from the second observation on (the
  first has no predecessor, so no entry can be told there); that is its `window`.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_250_4_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_250_4_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- The subject at (1.8, y), heading north, at `sp` m/s, having travelled `p` m. -/
def carAt (y sp p : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm 180, m y) Build.north (Units.metresPerSecond sp)
    (cm 250, cm 90, cm 75) (some (m p))

/-- A vehicle standing on the through highway, 40 m east of the junction. -/
def onThroughWay : RoadUser :=
  Build.user 2 [.motorVehicle] (m 40, m 6) Build.west (Units.metresPerSecond 0)
    (cm 250, cm 90, cm 75)

-- The map.
def intersection10 : Structure := Build.rect 10 .intersection (m (-6)) (m 0) (m 6) (m 12)
def approachLane : Structure :=
  Build.lane 11 [(m 0, m (-120)), (cm 360, m (-120)), (cm 360, m 0), (m 0, m 0)] Build.north
    (enters := some 10)
def stopLine : Structure := Build.rect 12 .stopLine (m 0) (cm (-40)) (cm 360) (cm (-20))
def crossing : Structure :=
  { Build.rect 14 .crosswalk (m (-6)) (m (-9)) (m 6) (m (-6)) with marked := some true }

-- The two-junction map of `branch_5`.
def shortApproachLane : Structure :=
  Build.lane 11 [(m 0, m (-60)), (cm 360, m (-60)), (cm 360, m 0), (m 0, m 0)] Build.north
    (enters := some 10)
def intersection20 : Structure := Build.rect 20 .intersection (m (-6)) (m 30) (m 6) (m 42)
def laneBetween : Structure :=
  Build.lane 21 [(m 0, m 12), (cm 360, m 12), (cm 360, m 30), (m 0, m 30)] Build.north
    (enters := some 20)
def stopLine2 : Structure := Build.rect 23 .stopLine (m 0) (cm 2960) (cm 360) (cm 2980)

-- The ways, for the witnesses that read the view along the through highway.
def wayNS : Structure := Build.rect 30 .highway (m (-6)) (m (-120)) (m 6) (m 120)
def wayEW : Structure := Build.rect 31 .highway (m (-120)) (m 0) (m 120) (m 12)
def intersectionOnWays : Structure := { intersection10 with ways := some [30, 31] }
def approachLaneOnWay : Structure := { approachLane with ways := some [30] }

-- The devices.
def deadHeadOverLane : Device :=
  { Build.signal 50 [11] [.dark] with uncovered := some true, inoperative := some true }
def deadHeadOverIntersection : Device :=
  { Build.signal 50 [10] [.dark] with uncovered := some true, inoperative := some true }
def liveHeadOverLane : Device :=
  { Build.signal 50 [11] [.circularGreen] with uncovered := some true, inoperative := some false }
def deadHeadOverSecondLane : Device :=
  { Build.signal 50 [21] [.dark] with uncovered := some true, inoperative := some true }

-- The worlds.
def lineWorld : List Structure := [intersection10, approachLane, stopLine]
def crossingWorld : List Structure := [intersection10, approachLane, crossing]
def sightWorld : List Structure := [intersectionOnWays, approachLaneOnWay, wayNS, wayEW]
def twoJunctionWorld : List Structure :=
  [intersection10, shortApproachLane, stopLine, intersection20, laneBetween, stopLine2]

/-- (y, speed, path travelled) at each observation. -/
def frame (xs : List (Int × Int × Int)) (k : Nat) : Int × Int × Int := xs[k]?.getD (0, 0, 0)

/-- The approach at 5 m per second, from 93 m back to 8 m short of the intersection. -/
def runUp : List (Int × Int × Int) :=
  [(-93, 5, 0), (-88, 5, 5), (-83, 5, 10), (-78, 5, 15), (-73, 5, 20), (-68, 5, 25),
   (-63, 5, 30), (-58, 5, 35), (-53, 5, 40), (-48, 5, 45), (-43, 5, 50), (-38, 5, 55),
   (-33, 5, 60), (-28, 5, 65), (-23, 5, 70), (-18, 5, 75), (-13, 5, 80), (-8, 5, 85)]

def mkTrace (xs : List (Int × Int × Int)) (structs : List Structure) (devs : List Device) : Trace :=
  Build.trace xs.length 0 (Units.seconds 1) fun k t =>
    let (y, sp, p) := frame xs k
    Build.scene t (some 1) [carAt y sp p] structs devs

/-- A trace whose subject carries the view it has along the through highway (region 31), with
    whatever other road users and measured relations the scene needs. -/
def mkSightTrace (xs : List (Int × Int × Int)) (sight : Nat → Int) (structs : List Structure)
    (devs : List Device) (others : List RoadUser) (rels : List MeasuredRelation) : Trace :=
  Build.trace xs.length 0 (Units.seconds 1) fun k t =>
    let (y, sp, p) := frame xs k
    Build.withRelations
      (Build.scene t (some 1)
        ({ carAt y sp p with sightAlongWay := some [(31, m (sight k))] } :: others) structs devs)
      rels

-- The runs: rolling through, halting at the line, halting short of a crossing, halting late.
def rollThrough : List (Int × Int × Int) := runUp ++ [(-3, 5, 90), (3, 5, 96)]
def haltAtLine : List (Int × Int × Int) := runUp ++ [(-3, 0, 90), (-3, 0, 90), (3, 5, 96)]
def haltShortOfLine : List (Int × Int × Int) := runUp ++ [(-4, 0, 89), (-4, 0, 89), (3, 5, 96)]
def haltBeforeCrossing : List (Int × Int × Int) :=
  runUp.take 15 ++ [(-18, 0, 75), (-18, 0, 75), (-13, 5, 80), (-8, 5, 85), (-3, 5, 90), (3, 5, 96)]
def twoJunctionRun : List (Int × Int × Int) :=
  [(-53, 5, 0), (-48, 5, 5), (-43, 5, 10), (-38, 5, 15), (-33, 5, 20), (-28, 5, 25),
   (-23, 5, 30), (-18, 5, 35), (-13, 5, 40), (-8, 5, 45), (-3, 0, 50), (-3, 0, 50),
   (3, 5, 56), (9, 5, 62), (15, 5, 68), (20, 5, 73), (25, 5, 78), (27, 5, 80), (33, 5, 86)]

/-- `forbid` (violated): A car approaches a four-way junction whose signal head is installed over its lane with the faces uncovered and showing no indication at all. A clearly marked stop line crosses the approach. The car rolls over the line without its speed ever falling to rest anywhere on the approach and its footprint enters the intersection region. -/
def forbidTrace : Trace := mkTrace rollThrough lineWorld [deadHeadOverLane]

/-- `permit` (compliant): The same car at the same dead signal comes to rest with its body within the placement tolerance of the marked stop line while it is on the approach lane that runs into the intersection, stands there, and then moves off into the intersection. No other road user of any kind is in the scene. -/
def permitTrace : Trace := mkTrace haltAtLine lineWorld [deadHeadOverLane]

/-- `idle` (not_applicable): The car enters the same intersection while the signal head governing its lane displays a circular green: the head is operative and shows a valid indication, so it is not inoperative at the time of entry. -/
def idleTrace : Trace := mkTrace rollThrough lineWorld [liveHeadOverLane]

/-- `blind` (unknown): The car enters the intersection under the dead signal head with a marked stop line on the approach, but the source reports no speed for it anywhere on the approach, so whether it was ever at rest cannot be told. -/
def blindTrace : Trace := mkTrace rollThrough lineWorld [deadHeadOverLane]

/-- `branch_1` (compliant): The approach to the dead signal carries neither a stop line nor a crosswalk. Buildings close to the corner cut the view along the intersecting through highway until the last few metres; the car comes to rest at the last place on its approach from which the along-way view reaches the required distance, with no road user approaching on that way, and then moves off. -/
def branch_1Trace : Trace :=
  mkSightTrace haltAtLine (fun k => if k ≥ 18 then 70 else 20) sightWorld [deadHeadOverLane] [] []

/-- `branch_2` (violated): The approach to the dead signal carries a crosswalk but no stop line. The car comes to rest only after its footprint has overlapped the crossing, so its halt was made after it entered the crosswalk rather than before. -/
def branch_2Trace : Trace := mkTrace haltAtLine crossingWorld [deadHeadOverLane]

/-- `branch_3` (violated): The installed uncovered head is dead and governs the intersection region itself rather than any lane. The car drives through at a steady speed without ever coming to rest on the approach, and at the observation at which its footprint first overlaps the intersection its body has already cleared the approach lane behind it. The duty engages on that entry all the same, and the halt at the marked stop line crossing the approach is missing. -/
def branch_3Trace : Trace := mkTrace rollThrough lineWorld [deadHeadOverIntersection]

/-- `branch_4` (compliant): The same dead head, governing only the lane that runs into the intersection: the car comes to rest with its body within the placement tolerance of the marked stop line while its footprint overlaps that lane, then moves off, and at the observation at which it first overlaps the intersection its body has already cleared the lane. The halt on the approach satisfies the first limb although the vehicle is clear of the lane at the instant of entry. -/
def branch_4Trace : Trace := mkTrace haltShortOfLine lineWorld [deadHeadOverLane]

/-- `branch_5` (violated): Two junctions stand one after the other on the same way, each with its own clearly marked stop line on the approach. The car comes to rest at the stop line of the first junction, drives on through that junction, and enters the second - whose installed uncovered head is dead - without coming to rest anywhere on the approach that runs into it. The earlier halt was at another junction's line and is not the stop this intersection requires. -/
def branch_5Trace : Trace := mkTrace twoJunctionRun twoJunctionWorld [deadHeadOverSecondLane]

/-- `branch_6` (compliant): The approach to the dead signal carries a crosswalk but no stop line. The car comes to rest well short of the crossing, having overlapped no crosswalk over the look-back behind that halt, and only then drives over the crossing and into the intersection: the halt was made before entering the crosswalk. -/
def branch_6Trace : Trace := mkTrace haltBeforeCrossing crossingWorld [deadHeadOverLane]

/-- `branch_7` (violated): Neither a stop line nor a crosswalk on the approach, and the view along the intersecting through highway reaches the required distance everywhere; but a vehicle standing on that through highway is not in the car's line of sight at any observation, so no place on the approach is one at which the driver has a view of the traffic on that highway, and the halt the car makes is not at such a place. -/
def branch_7Trace : Trace :=
  mkSightTrace haltAtLine (fun _ => 70) sightWorld [deadHeadOverLane] [onThroughWay]
    [Build.relation 1 2 (fun r => { r with visible := some false })]

/-- The instants a witness speaks about: from the second observation (the first has no
    predecessor, so no entry into a region can be told there) to the last. -/
def spokenWindow (τ : Trace) : Option (Timestamp × Timestamp) :=
  match τ.tail.head?, τ.getLast? with
  | some a, some b => some (a.t, b.t)
  | _, _ => none

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_250_4_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    window := spokenWindow τ }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .violated ]

end TrafficSpecWitness.NRS_484B_250_4_o1
