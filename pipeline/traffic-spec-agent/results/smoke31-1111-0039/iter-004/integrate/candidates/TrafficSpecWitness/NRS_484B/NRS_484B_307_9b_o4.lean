/-
  Witnesses for NRS_484B_307_9b_o4.

  Geometry (+x east, +y north, metres). Intersection i (region 1) is the box x ∈ [−5, 5],
  y ∈ [0, 10]. The northbound approach lane (2, x ∈ [0, 5], y ∈ [−30, 0]) and the southbound
  approach lane (4, x ∈ [−5, 0], y ∈ [10, 40]) both enter i. Crosswalk 5 lies across the north
  leg (x ∈ [−5, 5], y ∈ [10, 14]) and is recorded as marking the entrance of lane 4. Signal 10
  shows circular_red with a green arrow and governs lane 2 (or, in `branch_1`, i itself).

  Scenes every 50 ms (the acquisition standard's step). x (track 1) rides north along x = 2.5 at
  10 m/s from y = −4.25, 0.5 m per scene; its footprint (half-length 1, half-width 0.4) first
  overlaps i at scene 7 (overlapping lane 2 too) and leaves it at scene 31. Occupancy is stated
  from the footprint box, not from the reference point. Every figure here is the witness's own.

  The judged instants start at the second scene: the entry and the leaving read the observation
  before.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9b_o4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9b_o4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- The regions as boxes (id, x0, y0, x1, y1). -/
def boxes : List (RegionId × Q × Q × Q × Q) :=
  [ (1, m (-5), m 0, m 5, m 10)
  , (2, m 0, m (-30), m 5, m 0)
  , (4, m (-5), m 10, m 0, m 40)
  , (5, m (-5), m 10, m 5, m 14) ]

def structures : List Structure :=
  [ Build.rect 1 .intersection (m (-5)) (m 0) (m 5) (m 10)
  , Build.lane 2 [(m 0, m (-30)), (m 5, m (-30)), (m 5, m 0), (m 0, m 0)] Build.north (enters := some 1)
  , Build.lane 4 [(m (-5), m 10), (m 0, m 10), (m 0, m 40), (m (-5), m 40)] Build.south (enters := some 1)
  , { Build.rect 5 .crosswalk (m (-5)) (m 10) (m 5) (m 14) with
      marked := some true, entranceOf := [4], entranceObserved := true } ]

/-- The regions overlapped by a footprint box of half-sizes (hx, hy) about p. -/
def footprintIn (track : TrackId) (p : Vec) (hx hy : Q) : List (TrackId × RegionId) :=
  boxes.filterMap fun (r, x0, y0, x1, y1) =>
    if Q.lt x0 (Q.add p.1 hx) && Q.lt (Q.sub p.1 hx) x1 && Q.lt y0 (Q.add p.2 hy) && Q.lt (Q.sub p.2 hy) y1
    then some (track, r) else none

def leftArrowOnLane : Device := Build.signal 10 [2] [.circularRed, .greenArrow .left]
def rightArrowOnIntersection : Device := Build.signal 10 [1] [.circularRed, .greenArrow .right]

/-- x heading north along x = 2.5 at scene k, with yaw rate `yaw` (deg/s). -/
def northPos (k : Nat) : Vec := (cm 250, cm (-425 + 50 * (k : Int)))
def xNorth (cls : RoadUserClass) (k : Nat) : RoadUser :=
  Build.withKin (Build.user 1 [cls] (northPos k) Build.north (Units.metresPerSecond 10) (cm 100, cm 40, cm 70))
    fun kn => { kn with yawRate := some (Units.degrees 0) }
def xNorthOcc (k : Nat) : List (TrackId × RegionId) := footprintIn 1 (northPos k) (cm 40) (cm 100)

/-- A pedestrian walking west at 1 m/s inside crosswalk 5, at y = 13. -/
def pedPos (k : Nat) : Vec := (cm (450 - 5 * (k : Int)), m 13)
def pedestrian (k : Nat) : RoadUser :=
  Build.user 2 [.pedestrian] (pedPos k) Build.west (Units.metresPerSecond 1) (cm 30, cm 30, cm 90)
def pedOcc (k : Nat) : List (TrackId × RegionId) := footprintIn 2 (pedPos k) (cm 30) (cm 30)

/-- A car crossing i eastbound at 4 m/s along y = 6, onto x's path. -/
def carPos (k : Nat) : Vec := (cm (-150 + 20 * (k : Int)), m 6)
def car (k : Nat) : RoadUser :=
  Build.user 3 [.motorVehicle] (carPos k) Build.east (Units.metresPerSecond 4) (cm 200, cm 90, cm 75)
def carOcc (k : Nat) : List (TrackId × RegionId) := footprintIn 3 (carPos k) (cm 200) (cm 90)

def step : Q := Units.milliseconds 50

/-- `forbid` (violated): x (ru.motorcycle), recorded from upstream, goes straight through i under circular_red with green_arrow(left); while it moves inside i a ru.pedestrian occupies the crosswalk at the far side, marking the entrance of the opposing carrier, and prim.closest_approach_within holds over p.immediate_hazard_gap with a prim.closest_approach_distance below p.conflict_clearance. -/
def forbidTrace : Trace :=
  Build.trace 33 0 step fun k t =>
    Build.scene t (some 1)
      [ xNorth .motorcycle k, pedestrian k ]
      structures
      [ leftArrowOnLane ]
      (occupies := some (xNorthOcc k ++ pedOcc k))

/-- `permit` (compliant): x (ru.bicycle), recorded from upstream, goes straight through i under circular_red with green_arrow(left) with no other road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 33 0 step fun k t =>
    Build.scene t (some 1)
      [ xNorth .bicycle k ]
      structures
      [ leftArrowOnLane ]
      (occupies := some (xNorthOcc k))

/-- x's heading in the left turn: north to scene 14, then through the rational unit headings
    16.26°, 36.87°, 53.13°, 73.74° left of north at scenes 15–18, west from scene 19. -/
def turnHeading (k : Nat) : Vec :=
  if k ≤ 14 then Build.north
  else if k = 15 then (Units.ratio (-7) 25, Units.ratio 24 25)
  else if k = 16 then (Units.ratio (-3) 5, Units.ratio 4 5)
  else if k = 17 then (Units.ratio (-4) 5, Units.ratio 3 5)
  else if k = 18 then (Units.ratio (-24) 25, Units.ratio 7 25)
  else Build.west
/-- The yaw rate (deg/s) held over the interval before scene k: 16.2602° or 20.6097° per 50 ms. -/
def turnYaw (k : Nat) : Q :=
  if k = 15 || k = 17 || k = 19 then Units.millidegrees 325204
  else if k = 16 || k = 18 then Units.millidegrees 412194
  else Units.degrees 0
/-- Positions integrated from the velocity held over the interval before each scene (0.5 m). -/
def turnPos : Nat → Vec
  | 0 => northPos 0
  | k + 1 =>
    let p := turnPos k
    let h := turnHeading (k + 1)
    (Q.add p.1 (Q.mul h.1 (cm 50)), Q.add p.2 (Q.mul h.2 (cm 50)))
/-- x turns left inside i (about 90° in total); its footprint leaves i westward at scene 33. -/
def xTurning (k : Nat) : RoadUser :=
  Build.withKin (Build.user 1 [.motorcycle] (turnPos k) (turnHeading k) (Units.metresPerSecond 10) (cm 100, cm 40, cm 70))
    fun kn => { kn with yawRate := some (turnYaw k) }
def xTurningOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 14 then footprintIn 1 (turnPos k) (cm 40) (cm 100)
  else if k ≤ 18 then footprintIn 1 (turnPos k) (cm 100) (cm 100)
  else footprintIn 1 (turnPos k) (cm 100) (cm 40)

/-- `idle` (not_applicable): x (ru.motorcycle) enters i under circular_red with green_arrow(left) and turns left, the movement the arrow indicates. -/
def idleTrace : Trace :=
  Build.trace 35 0 step fun k t =>
    Build.scene t (some 1)
      [ xTurning k ]
      structures
      [ leftArrowOnLane ]
      (occupies := some (xTurningOcc k))

/-- `blind` (unknown): x, recorded from upstream, goes straight through i under circular_red with green_arrow(left) near a crossing pedestrian, but the source does not observe footprint overlap (rel.occupies), so neither x's passage through i nor the pedestrian's presence in the crosswalk is decided. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): x (ru.moped) goes straight through i under circular_red with
    green_arrow(right), the signal governing i itself; a car crossing inside i is on a collision
    course with it (other traffic using the intersection). -/
def branch1Trace : Trace :=
  Build.trace 33 0 step fun k t =>
    Build.scene t (some 1)
      [ xNorth .moped k, car k ]
      structures
      [ rightArrowOnIntersection ]
      (occupies := some (xNorthOcc k ++ carOcc k))

def witness (name : String) (τ : Trace) (expected : Verdict) (last : Nat)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9b_o4"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (50, 50 * (last : Int))
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 32
  , witness "permit" permitTrace .compliant 32
  , witness "idle" idleTrace .notApplicable 34
  , witness "blind" blindTrace (.unknown []) 32 ["rel.occupies"]
  , witness "branch_1" branch1Trace .violated 32 ]

end TrafficSpecWitness.NRS_484B_307_9b_o4
