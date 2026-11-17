/-
  Witnesses for LVMC_11_52_136.

  Geometry (the witness's own figures, none of them in the rule): three marked parking spaces in
  a row, 6 m deep (y 0 … 6): an access aisle (region 10, x 0 … 3, designation access_aisle), the
  disabled bay beside it (region 11, x 3 … 6, designation disabled) and a general bay
  (region 12, x 20 … 23, designation general). A drive aisle runs east along y = −5, outside every
  bay. The subject (track 1) is a passenger car, half-extent 2.3 × 0.9 × 0.75 m, heading north
  when in a bay. Scenes every 10 s; the reading's p.parking_min_duration is 180 s and
  p.halt_speed_tolerance 0.1 m/s, so a halt of 300 s breaks the bound by 120 s and a halt of 60 s
  (preceded by driving at 5 m/s) keeps it by 120 s. Each witness names the instants from 200 s on,
  where the 180 s look-back of drv.motion.parked lies inside the trace.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_136
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_136

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 230, cm 90, cm 75)

def aisle : Structure :=
  { Build.rect 10 .parkingSpace (m 0) (m 0) (m 3) (m 6) with designation := some .accessAisle }
def disabledBay : Structure :=
  { Build.rect 11 .parkingSpace (m 3) (m 0) (m 6) (m 6) with designation := some .disabled }
def generalBay : Structure :=
  { Build.rect 12 .parkingSpace (m 20) (m 0) (m 23) (m 6) with designation := some .general }

def bays : List Structure := [aisle, disabledBay, generalBay]

/-- A car standing still at a point for the whole trace. -/
def standing (pos : Vec) : Nat → Timestamp → Scene := fun _k t =>
  Build.scene t (some 1)
    [ Build.user 1 [.motorVehicle] pos Build.north Q.zero carExtent ]
    bays
    [ ]

/-- `forbid` (violated): A passenger car (vehicle aggregate) comes to rest with its footprint overlapping a st.parking_space of designation access_aisle beside a disabled bay and stays at rest there (kin.speed at or below the tolerance) for longer than p.parking_min_duration. -/
def forbidTrace : Trace :=
  Build.trace 31 0 (Units.seconds 10) (standing (cm 150, m 3))

/-- `permit` (compliant): A passenger car halts briefly in an access-aisle parking space, shorter than p.parking_min_duration, to let a passenger out, then drives off; drv.motion.parked never holds while it occupies the aisle.
    Driving at 5 m/s along y = −5 until 190 s, at rest in the aisle from 200 s to 260 s, then
    driving off east along y = −5. -/
def permitTrace : Trace :=
  Build.trace 41 0 (Units.seconds 10) fun k t =>
    let car : RoadUser :=
      if k < 20 then
        Build.user 1 [.motorVehicle] (m (-950 + 50 * (k : Int)), m (-5)) Build.east
          (Units.metresPerSecond 5) carExtent
      else if k ≤ 26 then
        Build.user 1 [.motorVehicle] (cm 150, m 3) Build.north Q.zero carExtent
      else
        Build.user 1 [.motorVehicle] (m (50 * ((k : Int) - 26)), m (-5)) Build.east
          (Units.metresPerSecond 5) carExtent
    Build.scene t (some 1) [ car ] bays [ ]

/-- `idle` (not_applicable): A passenger car parks for a long time in a parking space of designation general; its footprint never overlaps an access_aisle region. -/
def idleTrace : Trace :=
  Build.trace 31 0 (Units.seconds 10) (standing (cm 2150, m 3))

/-- `blind` (unknown): A passenger car stands at rest next to an access-aisle region for longer than p.parking_min_duration; the source does not observe rel.occupies, so whether it is in the aisle is unknown.
    The car stands in the disabled bay beside the aisle for 300 s. -/
def blindTrace : Trace :=
  Build.trace 31 0 (Units.seconds 10) (standing (cm 450, m 3))

/-- `branch_1` (not_applicable): a pedestrian, no vehicle, stands in the access aisle for 300 s;
    the class leaf decides that the duty does not bind. -/
def branch1Trace : Trace :=
  Build.trace 31 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.pedestrian] (cm 150, m 3) Build.north Q.zero (cm 25, cm 25, cm 90) ]
      bays
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none)
    (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_52_136"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (200000, 300000))
  , witness "permit" permitTrace .compliant (window := some (200000, 400000))
  , witness "idle" idleTrace .notApplicable (window := some (200000, 300000))
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] (window := some (200000, 300000))
  , witness "branch_1" branch1Trace .notApplicable (window := some (200000, 300000)) ]

end TrafficSpecWitness.LVMC_11_52_136
