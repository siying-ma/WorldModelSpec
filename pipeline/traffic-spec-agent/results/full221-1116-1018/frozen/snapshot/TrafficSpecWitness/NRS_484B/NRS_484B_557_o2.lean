/-
  Witnesses for NRS_484B_557_o2.

  Geometry (metres, +y north). A highway (region 10, x ∈ [-10, 10]) carries a northbound
  approach lane (11, y ≤ 0), a railway crossing (12, y ∈ [0, 5], x ∈ [-2, 2]) and a departure
  lane (13, y ≥ 5); all three lie on the highway. A stop sign (20) governs the approach lane
  (absent in `idle`).

  The car (track 1, half-length 2 m, half-width 1 m) drives north at 1 s spacing:
    k0 y=-40 (10 m/s, 38 m from the crossing), k1 y=-30, k2 y=-20 (5 m/s),
    k3–k4 y=-12, speed 0 — halted, body 10 m from the crossing (the band is 4.572–15.24 m),
    k5 y=-5 (3 m/s, 3 m from it), k6 y=1 (enters: across lane 11 and the crossing, 2 m/s),
    k7 y=2.5 (on the crossing), k8 y=5 (across the crossing and lane 13), k9 y=8, k10 y=12 (clear).
  Occupancy is stated per instant from the footprint.

  forbid: a train (track 2, rail vehicle) runs west along y=3 at 10 m/s, at x=14 when the car
  enters (car at (0, 1), 2 m/s north): closest approach after about 1.4 s (horizon 3 s) at a
  centre distance of about 0.8 m (clearance 3 m); it then brakes to a stand at x=11, its body
  never touching the car's, so only the conflict decides.
  permit: the car alone. idle: no stop sign. blind: a pedestrian on the crossing at (1.8, 2.5),
  near the car's side, observed by position only (no outline, so Core cannot compute contact);
  the source's measured contact (false) is what the manifest masks.
  branch_1: a pedestrian at (1.2, 3) overlaps the car's body on the crossing (contact) → violated.
  branch_2: a train runs west along y=12: it approaches within the horizon, but its closest
  centre distance is about 8.8 m → compliant.
  branch_3: a train comes into view only at k7, after the entry, at (10, 4.5) running west at
  10 m/s: it meets the car 1 s later; the duty runs while the car stays on the crossing → violated.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_557_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_557_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwy : RegionId := 10
def laneIn : RegionId := 11
def xing : RegionId := 12
def laneOut : RegionId := 13

def onHwy (s : Structure) : Structure := { s with ways := some [hwy] }

def structures : List Structure :=
  [ Build.rect hwy .highway (m (-10)) (m (-80)) (m 10) (m 80)
  , onHwy (Build.lane laneIn [(m (-2), m (-80)), (m 2, m (-80)), (m 2, m 0), (m (-2), m 0)] Build.north)
  , onHwy (Build.rect xing .railwayCrossing (m (-2)) (m 0) (m 2) (m 5))
  , onHwy (Build.lane laneOut [(m (-2), m 5), (m 2, m 5), (m 2, m 80), (m (-2), m 80)] Build.north) ]

def stopSign : Device := Build.sign 20 .stopSign [laneIn]

def carYs : List Q := [m (-40), m (-30), m (-20), m (-12), m (-12), m (-5), m 1, cm 250, m 5, m 8, m 12]
def carSpeeds : List Q := [m 10, m 10, m 5, m 0, m 0, m 3, m 2, m 2, m 2, m 2, m 2]

def car (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 0, carYs.getD k (m 12)) Build.north (carSpeeds.getD k (m 2)) (m 2, m 1, m 1)

def carOcc (k : Nat) : List (TrackId × RegionId) :=
  if k ≤ 5 then [(1, laneIn), (1, hwy)]
  else if k == 6 then [(1, laneIn), (1, xing), (1, hwy)]
  else if k == 7 then [(1, xing), (1, hwy)]
  else if k == 8 then [(1, xing), (1, laneOut), (1, hwy)]
  else [(1, laneOut), (1, hwy)]

def sceneAt (k : Nat) (t : Timestamp) (others : List RoadUser) (devs : List Device)
    (otherOcc : List (TrackId × RegionId) := []) : Scene :=
  Build.scene t (some 1) (car k :: others) structures devs (occupies := some (carOcc k ++ otherOcc))

/-- A train running west at 10 m/s along `y`, at x = `x6` at k6. -/
def train (k : Nat) (y : Q) : RoadUser :=
  Build.user 2 [.railVehicle] (Q.sub (m 70) (m (10 * (k : Int))), y) Build.west (m 10) (m 8, cm 150, m 2)

/-- The forbid train: running west at 10 m/s along y=3, at x=14 at k6 (closing on the car), then
    braked to a stand at x=11, its body clear of the car's. -/
def nearMissTrain (k : Nat) : RoadUser :=
  if k ≤ 6 then
    Build.user 2 [.railVehicle] (Q.sub (m 74) (m (10 * (k : Int))), m 3) Build.west (m 10) (m 8, cm 150, m 2)
  else
    Build.user 2 [.railVehicle] (m 11, m 3) Build.west (m 0) (m 8, cm 150, m 2)

def nSteps : Nat := 11

/-- `forbid` (violated): A car on a lane governed by a stop sign halts between the two figures from the crossing, then enters it while a train closes on it so that their closest approach within the conflict horizon lies below the clearance. -/
def forbidTrace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    sceneAt k t [nearMissTrain k] [stopSign]

/-- `permit` (compliant): The car halts between the two figures, then enters and clears the crossing; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    sceneAt k t [] [stopSign]

/-- `idle` (not_applicable): The car enters a railway crossing from a lane that no stop sign governs. -/
def idleTrace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    sceneAt k t [] []

def pedestrian (x y : Q) : RoadUser :=
  Build.user 3 [.pedestrian] (x, y) Build.west (m 0) (cm 30, cm 30, cm 90)

/-- `blind` (unknown): The car halts between the two figures and enters the crossing; no train is present, a pedestrian stands on the crossing near its path, and the source does not observe contact. -/
def blindTrace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    Build.withRelations
      { sceneAt k t [Build.sparseUser 3 [.pedestrian] (cm 180, cm 250)] [stopSign] with
          occupancyObserved := [1] }
      [Build.relation 1 3 fun r => { r with contact := some false }]

/-- `branch_1` (violated): the car halts, enters, and its body overlaps a pedestrian standing on the crossing. -/
def branch1Trace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    sceneAt k t [pedestrian (cm 120) (m 3)] [stopSign] [(3, xing), (3, hwy)]

/-- `branch_2` (compliant): a train approaches within the horizon but its closest centre distance stays well above the clearance. -/
def branch2Trace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    sceneAt k t [train k (m 12)] [stopSign]

/-- `branch_3` (violated): the train comes into view only after the entry, while the car is still on the crossing, and closes on it. -/
def branch3Trace : Trace :=
  Build.trace nSteps 0 (Units.seconds 1) fun k t =>
    sceneAt k t (if k ≥ 7 then [train (k - 1) (cm 450)] else []) [stopSign]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_557_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant
  , witness "branch_3" branch3Trace .violated ]

end TrafficSpecWitness.NRS_484B_557_o2
