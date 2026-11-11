/-
  Witnesses for LVMC_11_43_010_A.

  The roundabout is region 10: a 60 m square outline (-30, -30)…(30, 30) whose reference point,
  the centre of the central island, is the origin. The car (track 1, a motor vehicle, 2.5 m by
  1 m half-extents) is sampled three times one second apart at 10 m/s.

  forbid: on the circulatory roadway at 15 m from the centre, going round clockwise — east side
    heading south, south side heading west, west side heading north. The radius × velocity cross
    product is −150 m²/s against a tolerance of 0.2 · 15 · 10 = 30.
  permit: the same radius, counter-clockwise — east side heading north, north side heading west,
    west side heading south (cross product +150).
  idle: a block of ordinary roadway (region 20, x 170…230) far from the roundabout; the car is on
    it heading south, occupying no roundabout region.
  blind: as forbid, with kin.velocity masked: moving is decided (speed), the sense is not.
  branch_1: on an entry approach inside the outline at 25 m east of the centre, heading west
    straight toward the island at 5 m/s: the cross product is zero, neither sense.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_43_010_A
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_43_010_A

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def carExtent : Q × Q × Q := (cm 250, cm 100, cm 75)

def car (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading speed carExtent

/-- The roundabout: its outline and the centre of its central island as reference point. -/
def roundabout : Structure :=
  { Build.rect 10 .roundabout (m (-30)) (m (-30)) (m 30) (m 30) with position := some (m 0, m 0) }

/-- An ordinary block of roadway far from the roundabout. -/
def block : Structure := Build.rect 20 .roadway (m 170) (m (-50)) (m 230) (m 50)

/-- Clockwise round the island at 15 m: east heading south, south heading west, west heading north. -/
def clockwisePose (k : Nat) : Vec × Vec :=
  match k with
  | 0 => ((m 15, m 0), Build.south)
  | 1 => ((m 0, m (-15)), Build.west)
  | _ => ((m (-15), m 0), Build.north)

/-- Counter-clockwise round the island at 15 m: east heading north, north heading west, west heading south. -/
def counterClockwisePose (k : Nat) : Vec × Vec :=
  match k with
  | 0 => ((m 15, m 0), Build.north)
  | 1 => ((m 0, m 15), Build.west)
  | _ => ((m (-15), m 0), Build.south)

/-- `forbid` (violated): A car on the circulatory roadway of a roundabout drives around the central island clockwise, its velocity tangential to the island. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (clockwisePose k).1 (clockwisePose k).2 (Units.metresPerSecond 10) ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): A car on the circulatory roadway drives around the central island counter-clockwise. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (counterClockwisePose k).1 (counterClockwisePose k).2 (Units.metresPerSecond 10) ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): A car drives clockwise around a block on ordinary streets; it occupies no roundabout region. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 200, m (20 - 10 * (k : Int))) Build.south (Units.metresPerSecond 10) ]
      [ roundabout, block ]
      [ ]

/-- `blind` (unknown): A car is on the circulatory roadway of a roundabout and moving; the source declares kin.velocity absent, so the sense of its motion is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (clockwisePose k).1 (clockwisePose k).2 (Units.metresPerSecond 10) ]
      [ roundabout ]
      [ ]

/-- `branch_1` (compliant): A car on an entry approach inside the roundabout's outline drives straight toward the central island before yielding: its motion is radial, neither sense. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (27 - 5 * (k : Int)), m 0) Build.west (Units.metresPerSecond 5) ]
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.LVMC_11_43_010_A
