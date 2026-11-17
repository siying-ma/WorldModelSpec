/-
  Witnesses for LVMC_11_43_010_A.

  Geometry: a roundabout region 10, the square (-30,-30)–(30,30), its reference point (the centre
  of the central island) at (0,0). The car (track 1, motor vehicle, half-extent 2.3 × 0.9 × 0.8 m)
  runs at 8 m/s (well above the 0.1 m/s halt tolerance) on the 20 m circle about the centre,
  one quarter turn per instant, three instants 1 s apart. Its velocity is tangential, so the share
  of its motion turning about the centre is 1 (well above the 0.26 sin tolerance).
  - forbid: (20,0) south, (0,-20) west, (-20,0) north — clockwise (cross product −160).
  - permit: (20,0) north, (0,20) west, (-20,0) south — counter-clockwise (cross product +160).
  - idle: a straight roadway (0,-5)–(200,5) and no roundabout; the car heads east along it.
  - blind: the permit scene, with st.region_geometry absent from the manifest (the source maps
    the roundabout without reference point and outline; occupancy stays observed).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 80)
def carSpeed : Q := Units.metresPerSecond 8

def car (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading carSpeed carExtent

/-- The roundabout region with its reference point at the centre of the central island. -/
def roundabout : Structure :=
  { Build.rect 10 .roundabout (m (-30)) (m (-30)) (m 30) (m 30) with position := some (m 0, m 0) }

/-- Clockwise positions and headings about (0,0). -/
def cwPose : Nat → Vec × Vec
  | 0 => ((m 20, m 0), Build.south)
  | 1 => ((m 0, m (-20)), Build.west)
  | _ => ((m (-20), m 0), Build.north)

/-- Counter-clockwise positions and headings about (0,0). -/
def ccwPose : Nat → Vec × Vec
  | 0 => ((m 20, m 0), Build.north)
  | 1 => ((m 0, m 20), Build.west)
  | _ => ((m (-20), m 0), Build.south)

/-- `forbid` (violated): A car in a roundabout circulates keeping the central island on its right, clockwise about the roundabout's reference point. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (cwPose k).1 (cwPose k).2 ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): A car circulates keeping the central island on its left, counterclockwise. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (ccwPose k).1 (ccwPose k).2 ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car drives on a straight street with no roundabout. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (50 + 8 * (k : Int)), m 0) Build.east ]
      [ Build.rect 20 .roadway (m 0) (m (-5)) (m 200) (m 5) ]
      [ ]

/-- `blind` (unknown): A car circulates in a roundabout that the source maps without its reference point and outline.
    The scene is the permit scene; the manifest declares st.region_geometry absent, so the
    roundabout's reference point is unobserved while its occupancy stays observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (ccwPose k).1 (ccwPose k).2 ]
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
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"] ]

end TrafficSpecWitness.LVMC_11_43_010_A
