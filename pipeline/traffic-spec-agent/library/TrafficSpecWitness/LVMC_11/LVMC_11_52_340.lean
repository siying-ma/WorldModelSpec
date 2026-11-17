/-
  Witnesses for LVMC_11_52_340.

  Geometry: a parking bay (region 10) is the rectangle x ∈ [0, 6] m, y ∈ [0, 3] m, of designation
  municipal (region 11, the same rectangle of designation general, in `branch_1`). A street runs
  east along y = -5 m, outside the bay. The subject (track 1) is a passenger car, half-extent
  2.25 × 0.90 × 0.75 m, heading east; in the bay its reference point is (3, 1.5) m.
  Speeds are 1 m/s while driving and 0 at rest; the reading's halt tolerance is 0.1 m/s and its
  parking duration 180 s, so a stay of 600 s or an hour is parked by a wide margin and a 30 s stop
  is not. Samples are 10 s apart (60 s in the hour-long scenes), well under half the 180 s window.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_340
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_340

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

/-- The bay, of a designation. -/
def bay (id : RegionId) (d : ParkingDesignation) : Structure :=
  { Build.rect id .parkingSpace (m 0) (m 0) (m 6) (m 3) with designation := some d }

def municipalBay : Structure := bay 10 .municipal

/-- In the bay. -/
def inBay : Vec := (m 3, cm 150)

/-- A private passenger car. -/
def privateCar (pos : Vec) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] pos Build.east speed carExtent

/-- An official vehicle of a kind. -/
def officialCar (k : OfficialKind) (pos : Vec) (speed : Q) : RoadUser :=
  { Build.user 1 [.motorVehicle, .officialVehicle] pos Build.east speed carExtent with
      officialKind := some k }

/-- On the street, `x` metres east of the bay's west edge. -/
def onStreet (x : Int) : Vec := (m x, m (-5))

/-- `forbid` (violated): A private passenger car (vehicle aggregate, not ru.official_vehicle municipal) comes to rest in a st.parking_space of designation municipal and stays at rest there for ten minutes. -/
def forbidTrace : Trace :=
  Build.trace 67 0 (Units.seconds 10) fun k t =>
    let car :=
      if k < 6 then privateCar (onStreet (10 * (Int.ofNat k) - 60)) (Units.metresPerSecond 1)
      else privateCar inBay Q.zero
    Build.scene t (some 1) [car] [municipalBay] []

/-- `permit` (compliant): A private passenger car halts for thirty seconds in a municipal parking space to let a passenger out and then drives off; it is never parked there. -/
def permitTrace : Trace :=
  Build.trace 30 0 (Units.seconds 10) fun k t =>
    let car :=
      if k < 20 then privateCar (onStreet (10 * (Int.ofNat k) - 200)) (Units.metresPerSecond 1)
      else if k < 24 then privateCar inBay Q.zero
      else privateCar (onStreet (10 * (Int.ofNat k) - 230)) (Units.metresPerSecond 1)
    Build.scene t (some 1) [car] [municipalBay] []

/-- `idle` (not_applicable): A ru.official_vehicle of kind municipal stays at rest for an hour in a municipal parking space. -/
def idleTrace : Trace :=
  Build.trace 61 0 (Units.seconds 60) fun _k t =>
    Build.scene t (some 1) [officialCar .municipal inBay Q.zero] [municipalBay] []

/-- `blind` (unknown): A private passenger car stands at rest for ten minutes beside a municipal parking space; the source does not observe rel.occupies, so whether it is in the space is unknown. -/
def blindTrace : Trace :=
  Build.trace 61 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [privateCar (m 3, m (-2)) Q.zero] [municipalBay] []

/-- `branch_1` (not_applicable): A private passenger car stays at rest for an hour in a parking space of designation general; it occupies no municipal space. -/
def branch_1Trace : Trace :=
  Build.trace 61 0 (Units.seconds 60) fun _k t =>
    Build.scene t (some 1) [privateCar inBay Q.zero] [bay 11 .general] []

/-- `branch_2` (violated): a tow truck (official vehicle of kind tow, not a City vehicle) comes to
    rest in the municipal bay and stays there for ten minutes. -/
def branch_2Trace : Trace :=
  Build.trace 67 0 (Units.seconds 10) fun k t =>
    let car :=
      if k < 6 then officialCar .tow (onStreet (10 * (Int.ofNat k) - 60)) (Units.metresPerSecond 1)
      else officialCar .tow inBay Q.zero
    Build.scene t (some 1) [car] [municipalBay] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_52_340"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (240000, 660000))
  , witness "permit" permitTrace .compliant (window := some (200000, 290000))
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (window := some (180000, 600000))
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .violated (window := some (240000, 660000)) ]

end TrafficSpecWitness.LVMC_11_52_340
