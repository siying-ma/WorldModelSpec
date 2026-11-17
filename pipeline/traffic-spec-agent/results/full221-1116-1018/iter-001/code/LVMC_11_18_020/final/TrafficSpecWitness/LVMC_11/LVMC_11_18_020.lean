/-
  Witnesses for LVMC_11_18_020.

  Geometry (the witness's own figures; none appears in the rule). +x east, +y north.
  - highway 100: x ∈ [-10, 10], y ∈ [-30, 40].
  - lane 1 (northbound, east half): x ∈ [0, 4], y ∈ [-30, 0], enters intersection 3.
  - lane 2 (northbound, west half; branch_3 only): x ∈ [-4, 0], y ∈ [-30, 0], enters intersection 3.
  - crosswalk 4: x ∈ [-8, 8], y ∈ [0, 4], marking the entrance of the lane the subject drives in.
  - intersection 3: x ∈ [-8, 8], y ∈ [4, 20].
  - centre line 5: x ∈ [-0.1, 0.1], y ∈ [-30, 40].
  - one-way roadway 6 (branch_2 only, no centre line): x ∈ [-4, 4], y ∈ [-30, 0].
  - zone sign 10: kind school_crossing, governing the subject's lane.
  - subject 1: a motor vehicle heading north, half-extents 2.25 × 0.9 × 0.75 m; instants 1 s apart:
    at y = -8 (in its lane only), at y = -1 (body across lane and crosswalk), at y = 6 (crosswalk and
    intersection). Occupancy is stated, since a body lies across two regions.
  - person 2: half-extents 0.3 m, in the crosswalk at (3, 2) — 1 m right of the subject's track, the
    centre line 1.9 m to its left — or at (-3, 2) beyond the centre line.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_18_020
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_18_020

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 100 .highway (m (-10)) (m (-30)) (m 10) (m 40)

def laneEast : Structure :=
  { Build.lane 1 [(m 0, m (-30)), (m 4, m (-30)), (m 4, m 0), (m 0, m 0)] Build.north (enters := some 3)
    with ways := some [100] }

def laneWest : Structure :=
  { Build.lane 2 [(m (-4), m (-30)), (m 0, m (-30)), (m 0, m 0), (m (-4), m 0)] Build.north (enters := some 3)
    with ways := some [100] }

def junction : Structure :=
  { Build.rect 3 .intersection (m (-8)) (m 4) (m 8) (m 20) with ways := some [100] }

def crosswalk (carrier : RegionId) : Structure :=
  { Build.rect 4 .crosswalk (m (-8)) (m 0) (m 8) (m 4) with
    ways := some [100], marked := some true, entranceOf := [carrier], entranceObserved := true }

def centreLine : Structure :=
  { Build.rect 5 .centreLine (cm (-10)) (m (-30)) (cm 10) (m 40) with ways := some [100] }

def oneWay : Structure :=
  { Build.rect 6 .oneWayRoadway (m (-4)) (m (-30)) (m 4) (m 0) with ways := some [100] }

def schoolXing (carrier : RegionId) : Device :=
  Build.zoneSign 10 [carrier] .schoolCrossing false (some {})

def car (x y v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, y) Build.north v (cm 225, cm 90, cm 75)

def person (cls : RoadUserClass) (x y : Q) : RoadUser :=
  Build.user 2 [cls] (x, y) Build.west (Units.metresPerSecond 1) (cm 30, cm 30, cm 90)

/-- One instant: the subject's position (x, y), speed and occupied regions, and the other road user
    with its occupied regions. -/
abbrev Step := Q × Q × Q × List RegionId × Option (RoadUser × List RegionId)

def mkTrace (steps : List Step) (structs : List Structure) (devs : List Device) : Trace :=
  Build.trace steps.length 0 (Units.seconds 1) fun k t =>
    match steps[k]? with
    | none => Build.scene t (some 1) [] structs devs
    | some (x, y, v, occS, other) =>
      let subj := car x y v
      let us : List RoadUser := match other with
        | some (u, _) => [u]
        | none => []
      let occO : List (TrackId × RegionId) := match other with
        | some (u, rs) => rs.map fun r => (u.track, r)
        | none => []
      Build.scene t (some 1) (subj :: us) structs devs
        (occupies := some ((occS.map fun r => ((1 : TrackId), r)) ++ occO))

def std : List Structure := [highway, laneEast, junction, crosswalk 1, centreLine]

/-- The subject drives from its lane (east half) into the crosswalk while `o` stays in it. -/
def drivesIn (o : RoadUser) : List Step :=
  [ (m 2, m (-8), Units.metresPerSecond 5, [100, 1], some (o, [100, 4]))
  , (m 2, m (-1), Units.metresPerSecond 5, [100, 1, 4], some (o, [100, 4]))
  , (m 2, m 6, Units.metresPerSecond 5, [100, 4, 3], some (o, [100, 4])) ]

/-- `forbid` (violated): A school_crossing sign governs the subject's lane; a child walks in the crosswalk on the subject's half of the roadway; the subject drives into the crosswalk. -/
def forbidTrace : Trace :=
  mkTrace (drivesIn (person .pedestrian (m 3) (m 2))) std [schoolXing 1]

/-- `permit` (compliant): Same, but the subject halts short of the crosswalk until the child has left it. -/
def permitTrace : Trace :=
  let child := person .pedestrian (m 3) (m 2)
  let gone := person .pedestrian (m 12) (m 2)
  mkTrace
    [ (m 2, m (-8), Units.metresPerSecond 5, [100, 1], some (child, [100, 4]))
    , (m 2, m (-3), Units.metresPerSecond 0, [100, 1], some (child, [100, 4]))
    , (m 2, m (-3), Units.metresPerSecond 0, [100, 1], some (gone, []))
    , (m 2, m (-1), Units.metresPerSecond 2, [100, 1, 4], some (gone, [])) ]
    std [schoolXing 1]

/-- `idle` (not_applicable): No school_crossing sign governs the subject's lane; a pedestrian is in the crosswalk. -/
def idleTrace : Trace :=
  mkTrace (drivesIn (person .pedestrian (m 3) (m 2))) std
    [Build.zoneSign 10 [1] .school false (some {})]

/-- `blind` (unknown): The sign is present but the source does not observe which carriers it governs; the subject drives into an occupied crosswalk. -/
def blindTrace : Trace :=
  mkTrace (drivesIn (person .pedestrian (m 3) (m 2))) std
    [{ schoolXing 1 with governs := [], governsObserved := false }]

/-- `branch_1` (not_applicable): The pedestrian is in the crosswalk on the far side of the centre line when the subject drives in. -/
def branch_1Trace : Trace :=
  mkTrace (drivesIn (person .pedestrian (m (-3)) (m 2))) std [schoolXing 1]

/-- `branch_2` (violated): the subject's roadway is one-way (no centre line); a pedestrian at the
    crosswalk's far left is on its side, and the subject drives in. -/
def branch_2Trace : Trace :=
  mkTrace
    [ (m 2, m (-8), Units.metresPerSecond 5, [100, 6, 1], some (person .pedestrian (m (-3)) (m 2), [100, 4]))
    , (m 2, m (-1), Units.metresPerSecond 5, [100, 6, 1, 4], some (person .pedestrian (m (-3)) (m 2), [100, 4]))
    , (m 2, m 6, Units.metresPerSecond 5, [100, 4, 3], some (person .pedestrian (m (-3)) (m 2), [100, 4])) ]
    [highway, oneWay, laneEast, junction, crosswalk 1] [schoolXing 1]

/-- `branch_3` (violated): the subject comes in the west half, the centre line on its right (L < 0);
    a pedestrian in the west half of the crosswalk is on its side, and the subject drives in. -/
def branch_3Trace : Trace :=
  let o := person .pedestrian (m (-3)) (m 2)
  mkTrace
    [ (m (-2), m (-8), Units.metresPerSecond 5, [100, 2], some (o, [100, 4]))
    , (m (-2), m (-1), Units.metresPerSecond 5, [100, 2, 4], some (o, [100, 4]))
    , (m (-2), m 6, Units.metresPerSecond 5, [100, 4, 3], some (o, [100, 4])) ]
    [highway, laneWest, junction, crosswalk 2, centreLine] [schoolXing 2]

/-- `branch_4` (violated): a person riding a bicycle across the crosswalk on the subject's side; the subject drives in. -/
def branch_4Trace : Trace :=
  mkTrace (drivesIn (person .bicycle (m 3) (m 2))) std [schoolXing 1]

/-- `branch_5` (violated): a person riding an electric bicycle across the crosswalk on the subject's side; the subject drives in. -/
def branch_5Trace : Trace :=
  mkTrace (drivesIn (person .electricBicycle (m 3) (m 2))) std [schoolXing 1]

/-- `branch_6` (violated): a person riding an electric scooter across the crosswalk on the subject's side; the subject drives in. -/
def branch_6Trace : Trace :=
  mkTrace (drivesIn (person .electricScooter (m 3) (m 2))) std [schoolXing 1]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_18_020"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated ]

end TrafficSpecWitness.LVMC_11_18_020
