/-
  Witnesses for NRS_484B_253_o1.

  The scene is one crossroads, 16 m by 16 m, at the origin: region 10 is the junction
  (−8 … 8 in x and y); region 11 is the northbound approach of the north-south highway
  (x 0 … 8, y −148 … −8, designated direction north) and region 12 the southbound approach of the
  same highway (x −8 … 0, y 8 … 148, designated direction south), so 11 and 12 carry reversed
  designated directions; region 13 is the westbound approach of the crossing highway
  (x 8 … 148, y 0 … 8, designated direction west), at right angles to 11. Each of the three
  carriers records the junction as its entrance end.

  Every trace runs 14 observations at 1 s spacing (0 … 13 s). Over the first ten the subject
  (track 1, a motor vehicle 4 m by 2 m) travels north on carrier 11, 45 m short of the junction and
  closing at 4 m/s; from 10 s on it is inside the junction, and the source declares at every
  observation that it intends to turn left there. Each witness names 10 … 13 s as the instants it
  speaks about, so that the window behind every judged observation reaches back over the
  approach — ten seconds of history, covered and sampled at 1 s.

  The other vehicle (track 2, a motor vehicle of the same size) is placed per witness on carrier 12
  (opposing), inside the junction, or on carrier 13 (crossing). Every figure here is the witness's
  own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_253_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_253_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

def junctionId : RegionId := 10
def northApproach : RegionId := 11
def southApproach : RegionId := 12
def crossingApproach : RegionId := 13

/-- The junction and the three approach carriers that run into it. -/
def roadRegions : List Structure :=
  [ Build.rect junctionId .intersection (m (-8)) (m (-8)) (m 8) (m 8)
  , Build.lane northApproach
      [(m 0, m (-148)), (m 8, m (-148)), (m 8, m (-8)), (m 0, m (-8))]
      Build.north (enters := some junctionId)
  , Build.lane southApproach
      [(m (-8), m 8), (m 0, m 8), (m 0, m 148), (m (-8), m 148)]
      Build.south (enters := some junctionId)
  , Build.lane crossingApproach
      [(m 8, m 0), (m 148, m 0), (m 148, m 8), (m 8, m 8)]
      Build.west (enters := some junctionId) ]

/-- The source's declaration about the subject at the junction. -/
def leftTurnDeclared : DeclaredIntent :=
  { vehicle := 1, target := junctionId, values := [("int.left_turn", true)] }

/-- A passenger car, 4 m by 2 m. -/
def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (m 2, m 1, cm 75)

/-- The subject on carrier 11, `45 − 4k` m short of the junction, closing at 4 m/s. -/
def subjectOnApproach (k : Nat) : RoadUser :=
  car 1 (m 3, m (-45 + 4 * Int.ofNat k)) Build.north (mps 4)

def sceneOf (t : Timestamp) (users : List RoadUser)
    (occupies : Option (List (TrackId × RegionId)) := none) : Scene :=
  Build.scene t (some 1) users roadRegions [] occupies (intents := [leftTurnDeclared])

/-- Ten observations of the approach, then four with the subject inside the junction; the other
    vehicle, where there is one, stands where the witness puts it throughout. -/
def episode (inJunction : RoadUser) (other : Option RoadUser)
    (onApproach inside : Option (List (TrackId × RegionId)) := none) : Trace :=
  Build.trace 14 0 (Units.seconds 1) fun k t =>
    if k < 10 then sceneOf t (subjectOnApproach k :: other.toList) onApproach
    else sceneOf t (inJunction :: other.toList) inside

/-- The instants each witness speaks about: the subject inside the junction, with ten seconds of
    recorded history behind every one of them. -/
def judged : Option (Timestamp × Timestamp) := some (10000, 13000)

/-- `forbid` (violated): The subject's footprint overlaps a crossroads and the source declares an intention to turn left there. An oncoming car is on the opposing approach segment, whose designated direction is the reverse of the segment the subject came in on, 20 m from the junction at 12 m/s, so it would reach the junction well within the arrival time. The subject keeps rolling across the opposing lane at 4 m/s, and under the two velocities the centres approach within the horizon to a distance below the minimum clearance. -/
def forbidTrace : Trace :=
  episode (car 1 (m 2, m 0) Build.west (mps 4))
          (some (car 2 (m (-4), m 20) Build.south (mps 12)))

/-- `permit` (compliant): The same junction, intention and oncoming car, but the subject stands still in the junction with the oncoming car passing to its right: under the velocities observed the centres' closest approach within the horizon stays above the minimum clearance throughout. -/
def permitTrace : Trace :=
  episode (car 1 (m 3, m 0) Build.west (mps 0))
          (some (car 2 (m (-4), m 24) Build.south (mps 12)))

/-- `idle` (not_applicable): The subject overlaps the junction with a declared left-turn intention and no other road user is anywhere in the scene, so no vehicle approaches from the opposite direction and the duty does not arise; the verdict is decided with the subject alone in the scene. -/
def idleTrace : Trace :=
  episode (car 1 (m 2, m 0) Build.west (mps 4)) none

/-- `blind` (unknown): The junction, the declared intention and an oncoming car on the opposing approach as in the forbid scenario, but the source declares no footprint overlap for any region, so neither the subject's presence within the junction nor the other car's carrier can be decided and the rule reports unknown.

    The car stands 40 m up the opposing approach at 5 m/s, further from the junction than its own
    speed carries it in the arrival time: the immediate-hazard limb of the condition is decided
    false whatever the mask hides, so the only facts the source leaves undecided here are the
    footprint overlaps it masks — the subject's within the junction, and the car's on its carrier.
    (A car as close as the forbid scenario's would leave that limb undecided too, and for a second
    reason: the junction region is itself a travel region, and no source records an entrance end
    for it, so which carrier a masked body is on could not be read off the junction either.) -/
def blindTrace : Trace :=
  episode (car 1 (m 2, m 0) Build.west (mps 4))
          (some (car 2 (m (-4), m 50) Build.south (mps 5)))

/-- `branch_1` (violated): The subject overlaps the junction with a declared left-turn intention and the oncoming car is itself already within the junction region (the other branch of the condition, rather than approaching so closely); the subject turns across it at 4 m/s and the predicted closest approach of the centres within the horizon falls below the minimum clearance. -/
def branch_1Trace : Trace :=
  episode (car 1 (m 2, m 0) Build.west (mps 4))
          (some (car 2 (m (-4), m 7) Build.south (mps 12)))
          (some [(1, northApproach), (2, junctionId), (2, southApproach)])
          (some [(1, junctionId), (2, junctionId), (2, southApproach)])

/-- `branch_2` (not_applicable): The subject overlaps the junction with a declared left-turn intention, and a car approaches 20 m away at 12 m/s on the segment of the crossing highway, whose designated direction is at right angles to the subject's approach rather than opposed; no vehicle approaches from the opposite direction, so this section lays no duty on the subject. -/
def branch_2Trace : Trace :=
  episode (car 1 (m 2, m 0) Build.west (mps 4))
          (some (car 2 (m 28, m 4) Build.west (mps 12)))

/-- `branch_3` (compliant): the oncoming car is on the opposing approach, near enough to the
    junction to be an immediate hazard (30 m at 8 m/s), but the subject stands still, so under the
    velocities observed the two centres do not approach each other at all within the horizon. -/
def branch_3Trace : Trace :=
  episode (car 1 (m 3, m 0) Build.west (mps 0))
          (some (car 2 (m (-4), m 40) Build.south (mps 8)))

/-- `branch_4` (not_applicable): a vehicle is on the opposing approach, and its designated
    direction is opposed, but 90 m of road lie between its body and the junction at 5 m/s: it is
    neither within the junction nor so close thereto as to constitute an immediate hazard, so no
    duty arises. -/
def branch_4Trace : Trace :=
  episode (car 1 (m 3, m 0) Build.west (mps 0))
          (some (car 2 (m (-4), m 100) Build.south (mps 5)))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_253_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := judged
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_253_o1
