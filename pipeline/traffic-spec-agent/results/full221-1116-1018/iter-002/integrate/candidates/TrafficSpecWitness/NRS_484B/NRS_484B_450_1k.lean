/-
  Witnesses for NRS_484B_450_1k.

  Geometry (every figure is the witness's own and appears nowhere in the rule). A straight
  roadway runs east (+x); its right road edge is a 30 cm strip below y = 0, its left road edge a
  30 cm strip above the left edge line; the highway (region 10) is the rectangle
  x ∈ [-100, 100] m, y ∈ [-5, 20] m that contains them. An excavation (region 16, kind
  excavation, on highway 10) spans x ∈ [-5, 5] m. The subject (track 1, motor vehicle, half
  length 2.5 m) heads east with its reference point at x = 0 unless it moves.

  - forbid/permit/blind and the device and queue branches: lanes y ∈ [0, 3.5] (11) and
    [3.5, 7] (12); left edge at y = 7. Excavation y ∈ [1, 3.5]. Subject half width 1.35 m at
    y = 5.15: body y ∈ [3.8, 6.5], 0.3 m from the excavation, 0.5 m from the left edge
    (passage width 3 m: neither gap leaves it). The excavation's offset is -1.65 m, the left
    edge's +1.85 m, the right edge's -5.15 m (same side as the excavation, 3.8 m away).
  - idle: as forbid, but lanes [0, 3.5], [3.5, 7.25], [7.25, 11] and the left edge at y = 11:
    4.5 m of roadway beside the body on the side away from the excavation.
  - branch_1: lanes [0, 3.05], [3.05, 6.1], left edge at y = 6.1; the excavation y ∈ [0, 2]
    against the right curb; subject half width 0.9 m at y = 4.9: body y ∈ [4, 5.8], 2 m from
    the excavation (offset -2.9 m) and 0.3 m from the left edge.
  Halted is speed 0 (tolerance 0.1 m/s); permit moves at 6 m/s. Three scenes, 1 s apart.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1k
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1k

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def hwyId : Nat := 10
def laneRId : Nat := 11
def laneLId : Nat := 12
def laneL2Id : Nat := 13
def edgeRId : Nat := 14
def edgeLId : Nat := 15
def excId : Nat := 16

/-- The highway, both road edges (the left one starting at `leftY`), the given lanes and the
    excavation spanning `excY0 … excY1` across the way. -/
def road (leftY : Q) (lanes : List Structure) (excY0 excY1 : Q) : List Structure :=
  [ Build.rect hwyId .highway (m (-100)) (m (-5)) (m 100) (m 20)
  , Build.rect edgeRId .roadEdge (m (-100)) (cm (-30)) (m 100) (m 0)
  , Build.rect edgeLId .roadEdge (m (-100)) leftY (m 100) (Q.add leftY (cm 30)) ]
  ++ lanes ++
  [ { Build.rect excId .obstruction (m (-5)) excY0 (m 5) excY1 with
        obstructionKind := some .excavation, ways := some [hwyId] } ]

/-- Two lanes, the left edge at 7 m, the excavation in the right lane. -/
def roadForbid : List Structure :=
  road (m 7)
    [ Build.rect laneRId .lane (m (-100)) (m 0) (m 100) (cm 350)
    , Build.rect laneLId .lane (m (-100)) (cm 350) (m 100) (m 7) ]
    (m 1) (cm 350)

/-- The subject at `x`, `y`, with half width `hw`, at `speed`. -/
def subjectAt (x y hw speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.east speed (cm 250, hw, cm 75)

def haltedSubject : RoadUser := subjectAt (m 0) (cm 515) (cm 135) Q.zero

/-- The forbid scene with the given devices and other road users. -/
def forbidWith (t : Timestamp) (others : List RoadUser) (devices : List Device) : Scene :=
  Build.scene t (some 1) (haltedSubject :: others) roadForbid devices

/-- `forbid` (violated): A st.obstruction of kind excavation lies on the highway in the right lane; the subject, a ru.aggregate vehicle, is at rest (kin.speed zero) in the left lane alongside it, its body 0.3 m from the excavation and 0.5 m from the left st.road_edge; no other road user, no human direction and no device is in the scene. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => forbidWith t [] []

/-- `permit` (compliant): As in forbid, but the subject moves past the excavation at kin.speed 6 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (m (-6 + 6 * Int.ofNat k)) (cm 515) (cm 135) (Units.metresPerSecond 6) ]
      roadForbid
      [ ]

/-- `idle` (not_applicable): The subject is at rest beside the excavation with its body 0.3 m from it and 4.5 m of roadway between its body and the road edge on its other side, so the halt leaves a passage. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ haltedSubject ]
      (road (m 11)
        [ Build.rect laneRId .lane (m (-100)) (m 0) (m 100) (cm 350)
        , Build.rect laneLId .lane (m (-100)) (cm 350) (m 100) (cm 725)
        , Build.rect laneL2Id .lane (m (-100)) (cm 725) (m 100) (m 11) ]
        (m 1) (cm 350))
      [ ]

/-- `blind` (unknown): As in forbid, but the source maps the regions without their outlines, so every distance and lateral offset to them is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => forbidWith t [] []

/-- `branch_1` (violated): The excavation lies against the right curb; the subject is at rest against the left road edge directly across from it, its body 2 m from the excavation and 0.3 m from the left edge. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m 0) (cm 490) (cm 90) Q.zero ]
      (road (cm 610)
        [ Build.rect laneRId .lane (m (-100)) (m 0) (m 100) (cm 305)
        , Build.rect laneLId .lane (m (-100)) (cm 305) (m 100) (cm 610) ]
        (m 0) (m 2))
      [ ]

/-- `branch_2` (compliant): As in forbid, but a dev.human_direction of role police_officer with indication stop governs the subject's lane. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t []
      [ { Build.device 20 .humanDirection [laneLId] with
            humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_3` (compliant): As in forbid, but a stop sign governs the subject's lane. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t [] [ Build.sign 20 .stopSign [laneLId] ]

/-- `branch_4` (compliant): As in forbid, but a yield sign governs the subject's lane. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t [] [ Build.sign 20 .yieldSign [laneLId] ]

/-- `branch_5` (compliant): As in forbid, but a traffic signal showing circular red governs the subject's lane. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t [] [ Build.signal 20 [laneLId] [.circularRed] ]

/-- `branch_6` (compliant): As in forbid, but a level-crossing signal with flashing lights (gate up) governs the subject's lane. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t []
      [ { Build.device 20 .railwaySignalOrGate [laneLId] with
            railLights := some .flashing, gate := some .up } ]

/-- `branch_7` (compliant): As in forbid, but a level-crossing gate that is down (lights dark) governs the subject's lane. -/
def branch_7Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t []
      [ { Build.device 20 .railwaySignalOrGate [laneLId] with
            railLights := some .dark, gate := some .down } ]

/-- `branch_8` (compliant): As in forbid, but a halted motor vehicle stands 2 m ahead of the subject in its lane. -/
def branch_8Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    forbidWith t
      [ Build.user 2 [.motorVehicle] (m 7, cm 515) Build.east Q.zero (cm 250, cm 90, cm 75) ]
      []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1k"
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

end TrafficSpecWitness.NRS_484B_450_1k
