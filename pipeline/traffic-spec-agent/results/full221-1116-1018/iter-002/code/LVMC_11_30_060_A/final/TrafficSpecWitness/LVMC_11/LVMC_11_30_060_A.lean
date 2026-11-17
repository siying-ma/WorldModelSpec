/-
  Witnesses for LVMC_11_30_060_A.

  Geometry (the witnesses' own figures, none of them in the rule):
  - a roadway (region 10), x 0..100 m, y 0..7 m; laned scenes split it into lane 11 (y 0..3.5,
    eastbound) and lane 12 (y 3.5..7, westbound); the unlaned scene (`branch_2`) carries an east
    direction on the roadway itself, as do `idle`, `branch_1` and `branch_3`; in `forbid`, `permit`
    and `blind` the roadway carries none, so the lane alone decides the crossing;
  - the pedestrian (track 1), half-extents 0.3 × 0.3 m, walks north at x = 50 m at 1.4 m/s from
    y = 0.5 m (1.4 m per 1 s step): across the eastbound lane's direction (cosine 0);
  - the car (track 2), half-extents 2.4 × 0.9 m, eastbound at 12 m/s in lane 11 at y = 3 m from
    x = 26 m: at the first instant its centre passes within about 0.3 m of the pedestrian's in about
    2 s (well inside 3 s and 3 m), at the second within about 1 s;
  - `idle`: a marked crosswalk (region 20) x 48..52 m spans the roadway at the pedestrian's line;
  - `branch_1`: the pedestrian stands at (50, 1) for two instants while a westbound car in lane 12
    at y = 5 passes (x 62 → 50 → 38, 4 m ahead at the second), then walks north at 1.4 m/s while the
    car, 12 m past, recedes (relative motion diverging);
  - `branch_3`: as `forbid`, under a pedestrians_prohibited regulatory sign (device 30) governing
    the roadway;
  - `branch_4`: one instant: a car stands at (50, 1) heading east; the pedestrian, at (50, 2.1)
    walking north away from it, still touches its side (footprints overlap): contact with no
    projected approach.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_30_060_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_30_060_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The roadway, with or without a designated direction of its own. -/
def roadway (dir : Option Vec) : Structure :=
  { Build.rect 10 .roadway (m 0) (m 0) (m 100) (m 7) with
    lane := dir.map fun d => ({ direction := some d } : LaneInfo) }

def laneEast : Structure :=
  Build.lane 11 [(m 0, m 0), (m 100, m 0), (m 100, cm 350), (m 0, cm 350)] Build.east
def laneWest : Structure :=
  Build.lane 12 [(m 0, cm 350), (m 100, cm 350), (m 100, m 7), (m 0, m 7)] Build.west

def crosswalk : Structure :=
  { Build.rect 20 .crosswalk (m 48) (m 0) (m 52) (m 7) with marked := some true }

def prohibition : Device :=
  { Build.sign 30 .regulatorySign [10] with
    code := some .pedestriansProhibited
    conditions := some {} }

/-- The pedestrian walking north at 1.4 m/s from y = 0.5 m. -/
def walker (k : Nat) : RoadUser :=
  Build.user 1 [.pedestrian] (m 50, cm (50 + 140 * (k : Int))) Build.north (cm 140) (cm 30, cm 30, cm 90)

/-- The eastbound car in lane 11, 12 m/s, from x = 26 m. -/
def carEast (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (26 + 12 * (k : Int)), m 3) Build.east (Units.metresPerSecond 12)
    (cm 240, cm 90, cm 75)

/-- `forbid` (violated): A pedestrian crosses a laned roadway mid-block at 1.4 m/s; a car on that roadway at 12 m/s would come within 1 m of the pedestrian's centre in 2 s, and the pedestrian keeps walking. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ walker k, carEast k ]
      [ roadway none, laneEast, laneWest ]
      [ ]

/-- `permit` (compliant): A pedestrian crosses the roadway mid-block at 1.4 m/s; no vehicle is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ walker k ]
      [ roadway none, laneEast, laneWest ]
      [ ]

/-- `idle` (not_applicable): A pedestrian crosses the roadway within a marked crosswalk while a car approaches. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ walker k, carEast k ]
      [ roadway (some Build.east), laneEast, laneWest, crosswalk ]
      [ ]

/-- `blind` (unknown): A pedestrian occupies the roadway mid-block while a car approaches, but the pedestrian's velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ walker k, carEast k ]
      [ roadway none, laneEast, laneWest ]
      [ ]

/-- `branch_1` (compliant): A pedestrian crossing mid-block halts in the lane while a car on the roadway passes 4 m ahead of it, then walks on once the car has gone; no conflict is projected while the pedestrian moves. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (m 50, m 1) Build.north (if k < 2 then Q.zero else cm 140)
          (cm 30, cm 30, cm 90)
      , Build.user 2 [.motorVehicle] (m (62 - 12 * (k : Int)), m 5) Build.west (Units.metresPerSecond 12)
          (cm 240, cm 90, cm 75) ]
      [ roadway (some Build.east), laneEast, laneWest ]
      [ ]

/-- `branch_2` (violated): the pedestrian crosses an unlaned eastbound roadway mid-block into the
    path of a car on it: the roadway itself is the carrier crossed. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ walker k, carEast k ]
      [ roadway (some Build.east) ]
      [ ]

/-- `branch_3` (not_applicable): as `forbid`, but a pedestrians_prohibited sign governs the roadway. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ walker k, carEast k ]
      [ roadway (some Build.east), laneEast, laneWest ]
      [ prohibition ]

/-- `branch_4` (violated): the pedestrian, walking away from a car standing in the lane, still
    touches its side: contact with no projected approach. -/
def branch_4Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (m 50, cm 210) Build.north (cm 140) (cm 30, cm 30, cm 90)
      , Build.user 2 [.motorVehicle] (m 50, m 1) Build.east Q.zero (cm 240, cm 90, cm 75) ]
      [ roadway (some Build.east), laneEast, laneWest ]
      [ ]

/-- `branch_5` (compliant): the pedestrian, at (50, 2.5) walking north, is passed behind by an
    eastbound car at (26, 1): the centres approach within the horizon (about 2 s) but no closer than
    about 4.3 m. -/
def branch_5Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (m 50, cm 250) Build.north (cm 140) (cm 30, cm 30, cm 90)
      , Build.user 2 [.motorVehicle] (m 26, m 1) Build.east (Units.metresPerSecond 12)
          (cm 240, cm 90, cm 75) ]
      [ roadway (some Build.east), laneEast, laneWest ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_30_060_A"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.LVMC_11_30_060_A
