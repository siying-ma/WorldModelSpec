/-
  Witnesses for NRS_484B_450_1j.

  Geometry (the witness's own figures, nowhere in the rule). The subject (track 1) is a motor
  vehicle heading east, body 5 m × 2 m (half-extents 2.5 m, 1 m). Three instants, 1 s apart.

  Near-entrance scenes (forbid, permit, blind, branch_2, branch_4 … branch_9): the subject's
  reference point at (0, 0), body y ∈ [−1, 1]; a fire station entrance (region 10) x ∈ [−5, 5],
  y ∈ [4, 14], 3 m from the body (20 ft = 6.096 m). Where a device or a queue is shown, a lane
  (region 11) x ∈ [−50, 50], y ∈ [−2, 2] holds the subject.

  Highway scenes (idle, branch_1, branch_3): a highway (region 20) x ∈ [−50, 50], y ∈ [−2, 14];
  road edges (regions 21 south, y ∈ [−0.2, 0], and 22 north, y ∈ [12, 12.2]) lying on it, the
  roadway 12 m between them; the entrance north of the highway, on the subject's left.
    idle:     subject at y = 10 (2 m from the north edge on the entrance's side, 10 m from the
              south edge); entrance y ∈ [29, 39], 18 m from the body: not opposite, not within 20 ft.
    branch_1: subject at y = 1 (1 m from the south edge, 11 m from the north edge between it and
              the entrance); entrance y ∈ [20, 30], 18 m from the body (75 ft = 22.86 m).
    branch_3: as branch_1 but the entrance y ∈ [32, 42], 30 m from the body.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_450_1j
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_450_1j

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def ext : Q × Q × Q := (cm 250, m 1, cm 75)

/-- The subject at a position, heading east, at a speed. -/
def subj (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east speed ext

/-- The entrance near the road, 3 m north of the body at the origin. -/
def entranceNear : Structure := Build.rect 10 .fireStationEntrance (m (-5)) (m 4) (m 5) (m 14)

/-- The lane the subject stands in. -/
def laneR : Structure := Build.rect 11 .lane (m (-50)) (m (-2)) (m 50) (m 2)

/-- The highway and its two road edges. -/
def highway : Structure := Build.rect 20 .highway (m (-50)) (m (-2)) (m 50) (m 14)
def edgeSouth : Structure := { Build.rect 21 .roadEdge (m (-50)) (cm (-20)) (m 50) (m 0) with ways := some [20] }
def edgeNorth : Structure := { Build.rect 22 .roadEdge (m (-50)) (m 12) (m 50) (cm 1220) with ways := some [20] }

/-- An entrance north of the highway from `y0` to `y0 + 10`. -/
def entranceAt (y0 : Int) : Structure := Build.rect 10 .fireStationEntrance (m (-5)) (m y0) (m 5) (m (y0 + 10))

/-- A near-entrance scene with the subject at rest at the origin, with extra users, structures and devices. -/
def nearScene (t : Timestamp) (others : List RoadUser) (structs : List Structure) (devs : List Device) : Scene :=
  Build.scene t (some 1) (subj (m 0, m 0) Q.zero :: others) (entranceNear :: structs) devs

def nearTrace (others : List RoadUser) (structs : List Structure) (devs : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t => nearScene t others structs devs

/-- `forbid` (violated): The subject, a ru.aggregate vehicle, is at rest (kin.speed zero) with its body 3 m from a st.fire_station_entrance (st.region_geometry); no other road user, no human direction and no device is in the scene. -/
def forbidTrace : Trace := nearTrace [] [] []

/-- `permit` (compliant): As in forbid, but the subject moves past the entrance at kin.speed 8 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subj (m (8 * (Int.ofNat k) - 8), m 0) (Units.metresPerSecond 8) ]
      [ entranceNear ]
      [ ]

/-- `idle` (not_applicable): On a two-way highway 12 m wide between its st.road_edge regions, the subject is at rest 2 m from the edge on the entrance's side, with its body 18 m from the entrance. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subj (m 0, m 10) Q.zero ]
      [ highway, edgeSouth, edgeNorth, entranceAt 29 ]
      [ ]

/-- `blind` (unknown): As in forbid, but the source maps the regions without their outlines, so every distance and lateral offset to them is unknown. -/
def blindTrace : Trace := nearTrace [] [] []   -- the forbid scene; st.region_geometry is absent in its manifest

/-- `branch_1` (violated): On the same highway, the subject is at rest 1 m from the road edge on the side away from the entrance (the edge on the entrance's side 10 m from it, between it and the entrance), with its body 18 m from the entrance. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subj (m 0, m 1) Q.zero ]
      [ highway, edgeSouth, edgeNorth, entranceAt 20 ]
      [ ]

/-- `branch_2` (compliant): As in forbid, but a dev.human_direction of role police_officer with indication stop governs the subject's lane. -/
def branch_2Trace : Trace :=
  nearTrace [] [laneR]
    [ { Build.device 30 .humanDirection [11] with
          humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_3` (not_applicable): The subject is at rest on the side of the highway away from the entrance, 1 m from the far road edge, with its body 30 m from the entrance. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subj (m 0, m 1) Q.zero ]
      [ highway, edgeSouth, edgeNorth, entranceAt 32 ]
      [ ]

/-- `branch_4` (compliant): As in forbid, but a stop sign governs the subject's lane. -/
def branch_4Trace : Trace := nearTrace [] [laneR] [ Build.sign 31 .stopSign [11] ]

/-- `branch_5` (compliant): As in forbid, but a yield sign governs the subject's lane. -/
def branch_5Trace : Trace := nearTrace [] [laneR] [ Build.sign 32 .yieldSign [11] ]

/-- `branch_6` (compliant): As in forbid, but a traffic signal showing circular red governs the subject's lane. -/
def branch_6Trace : Trace := nearTrace [] [laneR] [ Build.signal 33 [11] [.circularRed] ]

/-- `branch_7` (compliant): As in forbid, but a level-crossing signal with lights flashing (gate up) governs the subject's lane. -/
def branch_7Trace : Trace :=
  nearTrace [] [laneR]
    [ { Build.device 34 .railwaySignalOrGate [11] with railLights := some .flashing, gate := some .up } ]

/-- `branch_8` (compliant): As in forbid, but a level-crossing gate down (lights dark) governs the subject's lane. -/
def branch_8Trace : Trace :=
  nearTrace [] [laneR]
    [ { Build.device 35 .railwaySignalOrGate [11] with railLights := some .dark, gate := some .down } ]

/-- `branch_9` (compliant): As in forbid, but a motor vehicle at rest 2 m ahead of the subject in the same lane. -/
def branch_9Trace : Trace :=
  nearTrace [ Build.user 2 [.motorVehicle] (m 7, m 0) Build.east Q.zero ext ] [laneR] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_450_1j"
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
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .compliant
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.NRS_484B_450_1j
