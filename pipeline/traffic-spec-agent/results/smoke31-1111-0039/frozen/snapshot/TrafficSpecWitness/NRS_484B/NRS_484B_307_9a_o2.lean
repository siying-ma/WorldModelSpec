/-
  Witnesses for NRS_484B_307_9a_o2.

  Geometry (metres, +x east, +y north): intersection 1 is the square (0,0)–(20,20). Lane 2 is the
  northbound approach of the south leg, x 10–20, y −40–0, entering 1. Lane 3 is the eastbound
  approach of the west leg, x −40–−4, y 0–10, entering 1. Crosswalk 4 spans the west leg at
  x −4–0, y 0–20, recorded as marking lane 3's entrance. Signal 1 governs lane 2 (intersection 1 in
  `branch_2`).

  Instants 0, 1, 2 s. x (track 1, a motor vehicle, 5 m × 2 m, 5 m/s) is at (15, −6) heading north
  in lane 2, then at (15, 1) heading north with its body across lane 2 and the intersection (the
  entry; both occupancies stated), then at (8, 12) heading west, turning left into the west leg.
  A pedestrian (track 2) stands at (−2, 12) in crosswalk 4: at 2 s x's centre closes on it in 2 s
  to a centre distance of 0, against a 4.1 s gap and a 3 m clearance; at 1 s the predicted closest
  approach is 17 m away. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_9a_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_9a_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

def intersection : Structure := Build.rect 1 .intersection (m 0) (m 0) (m 20) (m 20)
def southApproach : Structure :=
  Build.lane 2 [(m 10, m (-40)), (m 20, m (-40)), (m 20, m 0), (m 10, m 0)] Build.north (enters := some 1)
def westApproach : Structure :=
  Build.lane 3 [(m (-40), m 0), (m (-4), m 0), (m (-4), m 10), (m (-40), m 10)] Build.east (enters := some 1)
def westCrosswalk : Structure :=
  { Build.rect 4 .crosswalk (m (-4)) (m 0) (m 0) (m 20) with
    marked := some true, entranceOf := [3], entranceObserved := true }

def structures : List Structure := [intersection, southApproach, westApproach, westCrosswalk]

def redLeftArrow (governs : List RegionId) : Device :=
  Build.signal 1 governs [.circularRed, .greenArrow .left]
def green (governs : List RegionId) : Device :=
  Build.signal 1 governs [.circularGreen]

/-- x at instant k: approaching, entering, turning left. -/
def subjectAt (k : Nat) : RoadUser :=
  match k with
  | 0 => Build.user 1 [.motorVehicle] (m 15, m (-6)) Build.north (Units.metresPerSecond 5) carExtent
  | 1 => Build.user 1 [.motorVehicle] (m 15, m 1) Build.north (Units.metresPerSecond 5) carExtent
  | _ => Build.user 1 [.motorVehicle] (m 8, m 12) Build.west (Units.metresPerSecond 5) carExtent

/-- A scene at instant k with the signal and the other road users; at the entry x's body lies
    across lane 2 and the intersection, which is stated. -/
def sceneAt (k : Nat) (t : Timestamp) (sig : Device) (others : List RoadUser) : Scene :=
  let us := subjectAt k :: others
  let extra : List (TrackId × RegionId) := if k == 1 then [(1, 2)] else []
  Build.scene t (some 1) us structures [sig]
    (occupies := some (Build.occupancyFromGeometry us structures ++ extra))

def standingPedestrian : RoadUser :=
  Build.user 2 [.pedestrian] (m (-2), m 12) Build.north (Units.metresPerSecond 0) pedExtent

/-- `forbid` (violated): x (ru.motor_vehicle), recorded from upstream, entered i under circular_red with green_arrow(left) and is turning left, moving; a ru.pedestrian occupies the crosswalk that marks the entrance of the carrier on the leg x turns into, and prim.closest_approach_within holds over p.immediate_hazard_gap with a prim.closest_approach_distance below p.conflict_clearance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (redLeftArrow [2]) [standingPedestrian]

/-- `permit` (compliant): x (ru.motor_vehicle), recorded from upstream, enters i under circular_red with green_arrow(left) and turns left with no other road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (redLeftArrow [2]) []

/-- `idle` (not_applicable): x (ru.motor_vehicle) enters i while s displays circular_green. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (green [2]) []

/-- `blind` (unknown): x (ru.motor_vehicle), recorded from upstream, moves through i with a pedestrian approaching in a crosswalk at the entrance of the leg x turns into, but the source does not observe s's state at x's entry. The pedestrian walks north at 1 m/s from (−2, 8); at 2 s the centres meet in 2 s. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt k t (redLeftArrow [2])
      [Build.user 2 [.pedestrian] (m (-2), m (8 + k)) Build.north (Units.metresPerSecond 1) pedExtent]

/-- `branch_1` (violated): no pedestrian; a stopped motor vehicle (track 3) at (2, 12) inside the
    intersection, which x, turning left, closes on in 1.2 s to a centre distance of 0. -/
def branch1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt k t (redLeftArrow [2])
      [Build.user 3 [.motorVehicle] (m 2, m 12) Build.east (Units.metresPerSecond 0) carExtent]

/-- `branch_2` (violated): as `forbid`, but the signal is recorded as governing the intersection
    itself, not the approach lane. -/
def branch2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneAt k t (redLeftArrow [1]) [standingPedestrian]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_9a_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.traffic_signal"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .violated ]

end TrafficSpecWitness.NRS_484B_307_9a_o2
