/-
  Witnesses for LVMC_11_22_020.

  Geometry (the witness's own figures; none appears in the rule). A highway region `hw` (id 10) is an
  axis-aligned rectangle x ∈ [-50, 300] m, y ∈ [-10, 10] m; traffic runs east (+x). Every car is a
  body of half-length 2.4 m, half-width 1.0 m, half-height 0.75 m. Scenes are 1 s apart.

  Against the reading (halt tolerance 0.1 m/s, horizon 3 s, clearance 3 m):
  - forbid: subject at (15k, 0) at 15 m/s; car 2 halted at (30, 1). At k = 0 the closest approach is
    2 s ahead at a centre distance of 1 m (< 3 m, 2 s < 3 s); at k = 1, 1 s ahead, 1 m. Bodies 30 m and
    15 m apart: no contact. City assumption true.
  - permit: subject alone at (12k, 0), 12 m/s, city assumption true.
  - idle: the subject moves at 5 m/s at (5k, 60), in a lot outside the highway rectangle (which is
    built, and decidedly not occupied).
  - blind: subject at (10k, 0) at 10 m/s behind car 2 at (12 + 5k, 0) at 5 m/s: closest approach
    2.4 s then 1.4 s ahead at centre distance 0; occupancy not observed (`occupancyObserved := []`)
    and `rel.occupies` masked.
  - branch_1 (violated, collision limb alone): subject at (0, 0) at 10 m/s, car 2 at (3, 0) at 15 m/s;
    the bodies overlap (3 m < 4.8 m) while the centres separate, so no approach within the horizon.
  - branch_2 (compliant, approach with clearance kept): subject at (0, 0) at 15 m/s, car 2 halted at
    (30, 5): closest approach 2 s ahead at a centre distance of 5 m (≥ 3 m); no contact.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_22_020
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_22_020

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def carExtent : Q × Q × Q := (cm 240, cm 100, cm 75)

def highway : Structure := Build.rect 10 .highway (m (-50)) (m (-10)) (m 300) (m 10)

def city : List (AsmId × Bool) := [("asm.within_city_limits", true)]

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): The subject car moves at 15 m/s on a highway inside the city (asm.within_city_limits declared true) toward a car halted ahead in its lane; at 2 s from the closest approach the projected centre distance is 1 m, and it does not brake. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m 0) Build.east (Units.metresPerSecond 15) carExtent
      , Build.user 2 [.motorVehicle] (m 30, m 1) Build.east (Units.metresPerSecond 0) carExtent ]
      [ highway ]
      [ ]
      (assumptions := city)

/-- `permit` (compliant): The subject car moves at 12 m/s alone on a city highway; no other road user is in the scene, so no contact and no conflict exist. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (12 * (k : Int)), m 0) Build.east (Units.metresPerSecond 12) carExtent ]
      [ highway ]
      [ ]
      (assumptions := city)

/-- `idle` (not_applicable): The subject car moves in a private parking lot that is no highway region; it occupies no st.highway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (5 * (k : Int)), m 60) Build.east (Units.metresPerSecond 5) carExtent ]
      [ highway ]
      [ ]
      (assumptions := city)

/-- `blind` (unknown): The subject car moves on a city street close behind a slower car with a projected conflict, but the source does not observe region occupancy, so whether it is on a highway is unknown. -/
def blindTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    { Build.scene t (some 1)
        [ Build.user 1 [.motorVehicle] (m (10 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10) carExtent
        , Build.user 2 [.motorVehicle] (m (12 + 5 * (k : Int)), m 0) Build.east (Units.metresPerSecond 5) carExtent ]
        [ highway ]
        [ ]
        (occupies := some [])
        (assumptions := city)
      with occupancyObserved := [] }

/-- `branch_1` (violated): the subject's body overlaps a faster car pulling away ahead; the centres separate
    (no conflict), so the collision limb alone decides. -/
def branch1Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 10) carExtent
      , Build.user 2 [.motorVehicle] (m 3, m 0) Build.east (Units.metresPerSecond 15) carExtent ]
      [ highway ]
      [ ]
      (assumptions := city)

/-- `branch_2` (compliant): the subject approaches a car halted in the next lane within the horizon, but the
    closest-approach centre distance (5 m) keeps the clearance; no contact. -/
def branch2Trace : Trace :=
  Build.trace 1 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 15) carExtent
      , Build.user 2 [.motorVehicle] (m 30, m 5) Build.east (Units.metresPerSecond 0) carExtent ]
      [ highway ]
      [ ]
      (assumptions := city)

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
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.LVMC_11_22_020
