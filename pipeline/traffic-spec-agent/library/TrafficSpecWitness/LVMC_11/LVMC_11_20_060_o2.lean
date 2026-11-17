/-
  Witnesses for LVMC_11_20_060_o2.

  Geometry (+x east, +y north; every figure is the witness's own and appears nowhere in the rule):
  - roadway 12: x ∈ [-30, 30], y ∈ [2, 12];
  - sidewalk 11: x ∈ [-30, 30], y ∈ [-1, 2], the strip between the roadway and the property line;
  - driveway 10 (or alley 13 in branch_2): x ∈ [-3, 3], y ∈ [-12, 2], running north across the
    sidewalk strip to the roadway, so a reference point in y ∈ [-1, 2], |x| < 3 lies in both.
  - subject (track 1): a car heading north, half-extents 2.2 m × 0.9 m × 0.75 m.
  - pedestrian (track 2): half-extents 0.25 m × 0.25 m × 0.9 m.
  Reading: conflict horizon 3 s, centre clearance 3 m, halt tolerance 0.1 m/s.
  - forbid: the car at (0, 0.5k) moving north at 1 m/s, the pedestrian at (3 − 0.75k, 1) walking
    west at 1.5 m/s, instants 0.5 s apart: closest approach about 1.7 s ahead at about 0.83 m.
  - permit: the car halted at (0, -0.9), its front 0.2 m short of the pedestrian's path at y = 1.75;
    the pedestrian walks west from x = 3 to x = -3 past it at 1.5 m/s.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_20_060_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_20_060_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def district (b : Bool) : List (AsmId × Bool) := [("asm.business_or_residence_district", b)]

def roadway : Structure := Build.rect 12 .roadway (m (-30)) (m 2) (m 30) (m 12)
def sidewalk : Structure := Build.rect 11 .sidewalk (m (-30)) (m (-1)) (m 30) (m 2)
def driveway : Structure := Build.rect 10 .drivewayOrAlleyEntrance (m (-3)) (m (-12)) (m 3) (m 2)
def alley : Structure := Build.rect 13 .alley (m (-3)) (m (-12)) (m 3) (m 2)

def drivewayMap : List Structure := [roadway, sidewalk, driveway]
def alleyMap : List Structure := [roadway, sidewalk, alley]

def carExtent : Q × Q × Q := (cm 220, cm 90, cm 75)
def walkerExtent : Q × Q × Q := (cm 25, cm 25, cm 90)

/-- The subject, a car heading north. -/
def car (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.north speed carExtent

/-- Another road user, by default a pedestrian. -/
def walker (pos : Vec) (heading : Vec) (speed : Q) (cls : List RoadUserClass := [.pedestrian]) : RoadUser :=
  Build.user 2 cls pos heading speed walkerExtent

/-- The forbid scene at step k (instants 0.5 s apart). -/
def crossingScene (k : Nat) (t : Timestamp) (structures : List Structure := drivewayMap) : Scene :=
  Build.scene t (some 1)
    [ car (m 0, cm (50 * (k : Int))) (Units.metresPerSecond 1)
    , walker (cm (300 - 75 * (k : Int)), m 1) Build.west (cm 150) ]
    structures [] (assumptions := district true)

/-- `forbid` (violated): District assumed; the subject crosses the sidewalk out of a driveway while a pedestrian walks toward its path; the closest approach falls below the clearance within the horizon and the subject keeps moving. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t => crossingScene k t

/-- `permit` (compliant): Same, but the subject waits halted at the sidewalk edge until the pedestrian has passed. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, cm (-90)) Q.zero
      , walker (cm (300 - 150 * (k : Int)), cm 175) Build.west (cm 150) ]
      drivewayMap [] (assumptions := district true)

/-- `idle` (not_applicable): The subject travels on the roadway, nowhere near a driveway or sidewalk. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (5 * (k : Int)), m 7) Build.east (Units.metresPerSecond 5) carExtent ]
      drivewayMap [] (assumptions := district true)

/-- `blind` (unknown): District assumed; the subject crosses the sidewalk with a pedestrian approaching, but the subject's speed is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t => crossingScene k t

/-- `branch_1` (compliant): District assumed; the subject crosses the sidewalk out of a driveway with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ car (m 0, cm (50 * (k : Int))) (Units.metresPerSecond 1) ]
      drivewayMap [] (assumptions := district true)

/-- `branch_2` (violated): as forbid, but the subject comes out of an alley. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.milliseconds 500) fun k t => crossingScene k t alleyMap

/-- `branch_3` (violated): the subject creeps at 5 cm/s (within the halt tolerance) on the sidewalk
    with its front against a pedestrian standing in its path: contact. -/
def branch_3Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, cm (-90)) (cm 5)
      , walker (m 0, cm 150) Build.west Q.zero ]
      drivewayMap [] (assumptions := district true)

/-- `branch_4` (compliant): the subject crosses the sidewalk while a pedestrian beside its path walks
    away from it: the centres do not approach. -/
def branch_4Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, m 0) (Units.metresPerSecond 1)
      , walker (m 3, m 1) Build.east (cm 150) ]
      drivewayMap [] (assumptions := district true)

/-- `branch_5` (compliant): the subject crosses the sidewalk well ahead of a pedestrian walking toward
    its path: the closest approach (about 4.5 m) stays above the clearance. -/
def branch_5Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, m 0) (Units.metresPerSecond 3)
      , walker (m 5, m 0) Build.west (cm 150) ]
      drivewayMap [] (assumptions := district true)

/-- `branch_6` (not_applicable): as forbid, but the place is known not to be a business or residence
    district. -/
def branch_6Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, m 0) (Units.metresPerSecond 1)
      , walker (m 3, m 1) Build.west (cm 150) ]
      drivewayMap [] (assumptions := district false)

/-- `branch_7` (not_applicable): the subject is still in the driveway short of the sidewalk, moving,
    with a pedestrian approaching its path. -/
def branch_7Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, m (-5)) (Units.metresPerSecond 1)
      , walker (m 3, m (-4)) Build.west (cm 150) ]
      drivewayMap [] (assumptions := district true)

/-- `branch_8` (not_applicable): as forbid, but the subject is a bicycle, no vehicle under the
    definition. -/
def branch_8Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m 0, m 0) Build.north (Units.metresPerSecond 1) carExtent
      , walker (m 3, m 1) Build.west (cm 150) ]
      drivewayMap [] (assumptions := district true)

/-- `branch_9` (compliant): as forbid, but the other road user is a motor vehicle, not a pedestrian. -/
def branch_9Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0, m 0) (Units.metresPerSecond 1)
      , walker (m 3, m 1) Build.west (cm 150) [.motorVehicle] ]
      drivewayMap [] (assumptions := district true)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_20_060_o2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant
  , witness "branch_6" branch_6Trace .notApplicable
  , witness "branch_7" branch_7Trace .notApplicable
  , witness "branch_8" branch_8Trace .notApplicable
  , witness "branch_9" branch_9Trace .compliant ]

end TrafficSpecWitness.LVMC_11_20_060_o2
