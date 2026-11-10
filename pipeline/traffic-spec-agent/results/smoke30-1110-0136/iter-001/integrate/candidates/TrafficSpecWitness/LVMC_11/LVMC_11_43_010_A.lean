/-
  Witnesses for LVMC_11_43_010_A.

  The roundabout is region 10, a 60 m square from (-30, -30) to (30, 30) whose reference point,
  the centre of its central island, is the origin. The car (track 1, a motor vehicle: an included
  class of the vehicle aggregate) is 4 m long and 2 m wide. Three instants one second apart.
    forbid / blind: the car runs south at 8 m/s on the east side of the island (x = 15 m):
      offset (15, y) × velocity (0, -8) = -120 m²/s, clockwise, tangential speed 8 m/s.
    permit: the same car runs north at 8 m/s there: +120 m²/s, counterclockwise.
    idle: the car runs east at 10 m/s along a straight roadway (region 20); no roundabout.
    branch_1: the car comes up the south approach on x = 0 northwards at 4 m/s, straight at the
      island: the offset is parallel to the velocity, so the cross product is zero.
    branch_2: the car stands at (15, 0) inside the roundabout, speed zero, yielding.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

/-- The roundabout, with its outline and the island's centre as reference point. -/
def roundabout : Structure :=
  { Build.rect 10 .roundabout (m (-30)) (m (-30)) (m 30) (m 30) with position := some (m 0, m 0) }

/-- `forbid` (violated): A car (an included class of the vehicle aggregate) occupies a st.roundabout region and moves around the central island clockwise: the cross product of its offset from the region's reference point and its kin.velocity is negative with a tangential speed above the tolerance. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 15, m (-8 * k)) Build.south (Units.metresPerSecond 8) carExtent ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): The same car moves around the island counterclockwise within the roundabout region. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 15, m (8 * k)) Build.north (Units.metresPerSecond 8) carExtent ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car moves along a straight roadway; no st.roundabout region is in the scene. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-20 + 10 * k), m 0) Build.east (Units.metresPerSecond 10) carExtent ]
      [ Build.rect 20 .roadway (m (-50)) (m (-5)) (m 50) (m 5) ]
      [ ]

/-- `blind` (unknown): A car occupies a roundabout region and moves clockwise around the island; the source maps the region without its outline and reference point (st.region_geometry absent), so the sense of rotation is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 15, m (-8 * k)) Build.south (Units.metresPerSecond 8) carExtent ]
      [ roundabout ]
      [ ]

/-- `branch_1` (compliant): A car on the right-hand entry approach inside the roundabout region moves straight toward the island; its tangential component about the reference point is counterclockwise or below the tolerance. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m (-28 + 4 * k)) Build.north (Units.metresPerSecond 4) carExtent ]
      [ roundabout ]
      [ ]

/-- `branch_2` (not_applicable): A car stands still inside the roundabout region, yielding: kin.speed is zero. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 15, m 0) Build.south (Units.metresPerSecond 0) carExtent ]
      [ roundabout ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_43_010_A"
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_43_010_A
