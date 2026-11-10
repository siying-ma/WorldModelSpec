/-
  Witnesses for LVMC_11_38_030.

  Geometry: a straight roadway (region 11, y from -10 m to 0 m) running east, with a sidewalk
  (region 10, y from 0 m to 3 m) along its north edge, both 100 m long from x = 0. The subject
  (track 1) heads east; on the sidewalk its reference point is at y = 1.5 m, on the roadway at
  y = -3 m. A moving subject travels 5 m/s (4 m/s for the bicycle), far above the speed
  resolution; a parked one has speed zero. Three instants, one second apart. Occupancy follows
  from the polygons. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_38_030
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_38_030

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def sidewalk : Structure := Build.rect 10 .sidewalk (m 0) (m 0) (m 100) (m 3)
def roadway : Structure := Build.rect 11 .roadway (m 0) (m (-10)) (m 100) (m 0)

def onSidewalk : Q := cm 150
def onRoadway : Q := m (-3)

/-- A trace of track 1 of classes `cls` heading east at lateral position `y`, advancing `step`
    metres per second at `speed`, with `asm.within_city_limits` declared `city`. -/
def ride (cls : List RoadUserClass) (y : Q) (step : Int) (speed : Q) (city : Bool := true) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 cls (m (10 + step * Int.ofNat k), y) Build.east speed (m 1, cm 40, cm 70) ]
      [ sidewalk, roadway ]
      [ ]
      (assumptions := [("asm.within_city_limits", city)])

/-- `forbid` (violated): A motorcycle (ru.motorcycle, an included class of the aggregate) moves along a sidewalk: its footprint overlaps a st.sidewalk region and kin.speed is above the tolerance; asm.within_city_limits is declared true. -/
def forbidTrace : Trace := ride [.motorcycle] onSidewalk 5 (Units.metresPerSecond 5)

/-- `permit` (compliant): The same motorcycle moves along the roadway beside the sidewalk; rel.occupies holds for the st.roadway and for no st.sidewalk region; asm.within_city_limits true. -/
def permitTrace : Trace := ride [.motorcycle] onRoadway 5 (Units.metresPerSecond 5)

/-- `idle` (not_applicable): A bicycle (ru.bicycle: neither in the motorcycle aggregate nor a moped or electric scooter) is ridden along the sidewalk; asm.within_city_limits true. -/
def idleTrace : Trace := ride [.bicycle] onSidewalk 4 (Units.metresPerSecond 4)

/-- `blind` (unknown): A motorcycle moves beside a sidewalk; the source declares rel.occupies absent, so whether its footprint overlaps the sidewalk is unknown. -/
def blindTrace : Trace := ride [.motorcycle] onRoadway 5 (Units.metresPerSecond 5)

/-- `branch_1` (compliant): A motorcycle stands parked on the sidewalk: kin.speed is zero at every observation; asm.within_city_limits true. -/
def branch_1Trace : Trace := ride [.motorcycle] onSidewalk 0 Q.zero

/-- `branch_2` (violated): A moped (ru.moped) moves along the sidewalk; asm.within_city_limits true. -/
def branch_2Trace : Trace := ride [.moped] onSidewalk 5 (Units.metresPerSecond 5)

/-- `branch_3` (not_applicable): A motorcycle moves along a sidewalk; asm.within_city_limits is declared false. -/
def branch_3Trace : Trace := ride [.motorcycle] onSidewalk 5 (Units.metresPerSecond 5) (city := false)

/-- `branch_4` (violated): An electric scooter (ru.electric_scooter) moves along the sidewalk; asm.within_city_limits true. -/
def branch_4Trace : Trace := ride [.electricScooter] onSidewalk 5 (Units.metresPerSecond 5)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_38_030"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.LVMC_11_38_030
