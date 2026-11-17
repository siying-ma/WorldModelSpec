/-
  Witnesses for NRS_484B_450_1h.

  Geometry (world frame, +x east, +y north; metres): one eastbound lane (region 10) from y = 0 to
  y = 3.5; the curb, a road edge (region 11), the strip y ∈ [−1, 0]; a safety zone (region 12) at
  x ∈ [−10, 10], y ∈ [3.5, 5.5], north of the lane. The subject (track 1), a motor vehicle 4 m long
  and 2 m wide, heads east with its reference point at y = 1.5: its body is 0.5 m from the curb and,
  when alongside the zone, 1 m from it (zone lateral offset +2, curb −1.5). Three instants 1 s apart.
  Alongside (x = 0) the subject is between the zone and the curb; at x = 17 its body is 5 m beyond
  the zone's east end (√(5² + 0.5²) ≈ 5.02 m < 30 ft ≈ 9.14 m); at x = 52 its body is 40 m beyond
  (≈ 40 m > 30 ft). The reading's p.halt_speed_tolerance (0.1 m/s) is broken by 8 m/s in permit and
  kept by 0 elsewhere; p.queue_halt_gap (5 m) is kept by the 2 m gap in branch_3.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1h
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1h

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneId : RegionId := 10

def structures : List Structure :=
  [ Build.lane laneId [(m (-100), m 0), (m 200, m 0), (m 200, cm 350), (m (-100), cm 350)] Build.east
  , Build.rect 11 .roadEdge (m (-100)) (m (-1)) (m 200) (m 0)
  , Build.rect 12 .safetyZone (m (-10)) (cm 350) (m 10) (cm 550) ]

def subjectAt (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, cm 150) Build.east speed (m 2, m 1, m 1)

/-- A scene with the subject at `x`, other users and devices as given. -/
def sceneWith (t : Timestamp) (x speed : Q) (others : List RoadUser) (devices : List Device) : Scene :=
  Build.scene t (some 1) (subjectAt x speed :: others) structures devices

/-- A three-instant trace of a standing subject at `x`. -/
def standing (x : Q) (others : List RoadUser := []) (devices : List Device := []) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => sceneWith t x Q.zero others devices

/-- `forbid` (violated): The subject, a ru.aggregate vehicle, is at rest (kin.speed zero) in the lane it occupies, with a st.safety_zone alongside 1 m to its left and the st.road_edge 0.5 m to its right; its footprint does not overlap the zone; no other road user, no human direction and no device is in the scene. -/
def forbidTrace : Trace := standing (m 0)

/-- `permit` (compliant): As in forbid, but the subject moves past the zone at kin.speed 8 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneWith t (m (-8 + 8 * (k : Int))) (Units.metresPerSecond 8) [] []

/-- `idle` (not_applicable): The subject is at rest 40 m beyond the end of the zone, between the zone's line and the curb, 0.5 m from the curb. -/
def idleTrace : Trace := standing (m 52)

/-- `blind` (unknown): As in forbid, but the source maps the regions without their outlines, so every distance and lateral offset to them is unknown. -/
def blindTrace : Trace := standing (m 0)

/-- `branch_1` (violated): The subject is at rest with its body 5 m beyond the end of the zone along its lane, between the zone's line and the curb, 0.5 m from the curb. -/
def branch_1Trace : Trace := standing (m 17)

/-- `branch_2` (compliant): As in forbid, but a dev.human_direction of role police_officer with indication stop governs the subject's lane. -/
def branch_2Trace : Trace :=
  standing (m 0) []
    [ { Build.device 20 .humanDirection [laneId] with
          humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_3` (compliant): As in forbid, but another vehicle stands ahead of the subject in the same lane (rel.ahead_behind_in_lane) with its body 2 m from the subject's (rel.surface_gap). -/
def branch_3Trace : Trace :=
  standing (m 0) [Build.user 2 [.motorVehicle] (m 6, cm 150) Build.east Q.zero (m 2, m 1, m 1)] []

/-- `branch_4` (compliant): As in forbid, but a stop sign governs the subject's lane. -/
def branch_4Trace : Trace := standing (m 0) [] [Build.sign 21 .stopSign [laneId]]

/-- `branch_5` (compliant): As in forbid, but a yield sign governs the subject's lane. -/
def branch_5Trace : Trace := standing (m 0) [] [Build.sign 22 .yieldSign [laneId]]

/-- `branch_6` (compliant): As in forbid, but a traffic signal showing circular red governs the subject's lane. -/
def branch_6Trace : Trace := standing (m 0) [] [Build.signal 23 [laneId] [.circularRed]]

/-- `branch_7` (compliant): As in forbid, but a level-crossing signal with lights flashing (gate up) governs the subject's lane. -/
def branch_7Trace : Trace :=
  standing (m 0) []
    [ { Build.device 24 .railwaySignalOrGate [laneId] with
          railLights := some .flashing, gate := some .up } ]

/-- `branch_8` (compliant): As in forbid, but a level-crossing gate down (lights dark) governs the subject's lane. -/
def branch_8Trace : Trace :=
  standing (m 0) []
    [ { Build.device 25 .railwaySignalOrGate [laneId] with
          railLights := some .dark, gate := some .down } ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1h"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant ]

end TrafficSpecWitness.NRS_484B_450_1h
