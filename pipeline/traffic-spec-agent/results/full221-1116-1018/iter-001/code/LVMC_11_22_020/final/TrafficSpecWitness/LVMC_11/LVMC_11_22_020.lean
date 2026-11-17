/-
  Witnesses for LVMC_11_22_020.

  Geometry: one highway region, a rectangle from (-50, -10) to (200, 10) m (region 10); travel is
  east along y = 0. Cars are 4.8 m by 1.8 m (half-extents 2.4, 0.9, 0.75 m). Instants are 1 s
  apart from t = 0. The subject is track 1, the other road user track 2.
  - forbid: subject at (15k, 0) moving east at 15 m/s; a halted car at (30, 1). At t = 0 the
    closest approach is 2 s ahead at a centre distance of 1 m; at t = 1, 1 s ahead, 1 m.
  - permit: the subject alone at (12k, 0), 12 m/s.
  - idle: the subject at 3 m/s in a lot at (0, 40), outside the highway region (y ≤ 10).
  - blind: subject at (15k, 0) at 15 m/s behind a car at (20 + 5k, 0) at 5 m/s: closest approach
    2 s, then 1 s ahead, centre distance 0; occupancy masked.
  - branch_1: a car abreast at (10k, 1.7) at the same 10 m/s, bodies overlapping by 0.1 m; no
    relative motion, so no closest approach: contact alone.
  - branch_2: a car halted in the next lane at (40, 5): the centres approach within 2.7 s / 1.7 s,
    but to 5 m, above the clearance.
  - branch_3: a car ahead at (20 + 20k, 0) pulling away at 20 m/s: no approach.
  - branch_4: the subject halted at (0, 0) while a car comes from behind at (-30 + 15k, 1).
  - branch_5: the forbid scene with asm.within_city_limits declared false.
  - branch_6: the forbid scene with the subject a bicycle at 6 m/s (no member of the aggregate).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_22_020
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_22_020

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def carExtent : Q × Q × Q := (cm 240, cm 90, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 90)

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-10)) (m 200) (m 10)

def inCity : List (AsmId × Bool) := [("asm.within_city_limits", true)]

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): The subject car moves at 15 m/s on a highway inside the city (asm.within_city_limits declared true) toward a car halted ahead in its lane; at 2 s from the closest approach the projected centre distance is 1 m, and it does not brake. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (mps 15) carExtent
      , Build.user 2 [.motorVehicle] (m 30, m 1) Build.east (mps 0) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `permit` (compliant): The subject car moves at 12 m/s alone on a city highway; no other road user is in the scene, so no contact and no conflict exist. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (12 * (k : Int)), m 0) Build.east (mps 12) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `idle` (not_applicable): The subject car moves in a private parking lot that is no highway region; it occupies no st.highway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (3 * (k : Int)), m 40) Build.east (mps 3) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `blind` (unknown): The subject car moves on a city street close behind a slower car with a projected conflict, but the source does not observe region occupancy, so whether it is on a highway is unknown. -/
def blindTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (mps 15) carExtent
      , Build.user 2 [.motorVehicle] (m (20 + 5 * (k : Int)), m 0) Build.east (mps 5) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `branch_1` (violated): a car abreast at the same speed, bodies overlapping: contact, no conflict. -/
def branch1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) Build.east (mps 10) carExtent
      , Build.user 2 [.motorVehicle] (m (10 * (k : Int)), cm 170) Build.east (mps 10) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `branch_2` (compliant): a halted car in the next lane; the centres approach within the horizon but to 5 m. -/
def branch2Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (mps 15) carExtent
      , Build.user 2 [.motorVehicle] (m 40, m 5) Build.east (mps 0) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `branch_3` (compliant): a faster car ahead pulling away; the centres do not approach. -/
def branch3Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (mps 15) carExtent
      , Build.user 2 [.motorVehicle] (m (20 + 20 * (k : Int)), m 0) Build.east (mps 20) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `branch_4` (not_applicable): the subject halted on the highway while a car closes from behind. -/
def branch4Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (mps 0) carExtent
      , Build.user 2 [.motorVehicle] (m (-30 + 15 * (k : Int)), m 1) Build.east (mps 15) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

/-- `branch_5` (not_applicable): the forbid scene outside the city limits. -/
def branch5Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (mps 15) carExtent
      , Build.user 2 [.motorVehicle] (m 30, m 1) Build.east (mps 0) carExtent ]
      [ highway ]
      [ ]
      (assumptions := [("asm.within_city_limits", false)])

/-- `branch_6` (not_applicable): a bicycle, no member of the vehicle aggregate, toward a halted car. -/
def branch6Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (m (6 * (k : Int)), m 0) Build.east (mps 6) bikeExtent
      , Build.user 2 [.motorVehicle] (m 12, m 1) Build.east (mps 0) carExtent ]
      [ highway ]
      [ ]
      (assumptions := inCity)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_22_020"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant
  , witness "branch_3" branch3Trace .compliant
  , witness "branch_4" branch4Trace .notApplicable
  , witness "branch_5" branch5Trace .notApplicable
  , witness "branch_6" branch6Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_22_020
