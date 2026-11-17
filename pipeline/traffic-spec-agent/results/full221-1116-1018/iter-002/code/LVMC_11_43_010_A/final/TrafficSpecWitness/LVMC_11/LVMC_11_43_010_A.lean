/-
  Witnesses for LVMC_11_43_010_A.

  Geometry: a roundabout region (id 10), a 60 m × 60 m square centred on the origin, with its
  reference point (the centre of the central island) at (0, 0). The subject (track 1) stands at
  (20, 0), 20 m east of the centre, at 10 m/s (far above the 0.1 m/s halt tolerance):
    - heading north: d = (20, 0), v = (0, 10), d × v = +200 > 0 — counterclockwise (permit);
    - heading south: d × v = −200 < 0, purely tangential (share 1 ≫ 0.26) — clockwise (forbid).
  The idle street is a roadway rectangle (id 20) with no roundabout in the scene. Three instants,
  one second apart; every figure is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The roundabout, with its outline and its reference point at the centre of the island. -/
def roundabout : Structure :=
  { Build.region 10 .roundabout
      [(m (-30), m (-30)), (m 30, m (-30)), (m 30, m 30), (m (-30), m 30)]
    with position := some (m 0, m 0) }

/-- A car 20 m east of the centre, at 10 m/s with the given heading. -/
def carAt (classes : List RoadUserClass) (heading : Vec) : RoadUser :=
  Build.user 1 classes (m 20, m 0) heading (Units.metresPerSecond 10) carExtent

/-- `forbid` (violated): A car in a roundabout circulates keeping the central island on its right, clockwise about the roundabout's reference point. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carAt [.motorVehicle] Build.south ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): A car circulates keeping the central island on its left, counterclockwise. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carAt [.motorVehicle] Build.north ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car drives on a straight street with no roundabout. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 20, m 0) Build.east (Units.metresPerSecond 10) carExtent ]
      [ Build.rect 20 .roadway (m (-100)) (m (-5)) (m 100) (m 5) ]
      [ ]

/-- `blind` (unknown): A car circulates in a roundabout that the source maps without its reference point and outline. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ carAt [.motorVehicle] Build.south ]
      [ roundabout ]
      [ ]
      (occupies := some [(1, 10)])

/-- `branch_1` (not_applicable): An electric scooter circulates clockwise in the roundabout: electric scooters are excluded from the vehicle definition. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.electricScooter] (m 20, m 0) Build.south (Units.metresPerSecond 5)
          (cm 60, cm 30, cm 90) ]
      [ roundabout ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_A"
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
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_43_010_A
