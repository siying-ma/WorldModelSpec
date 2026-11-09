/-
  Witnesses for NRS_484B_220_1.

  The geometry: a straight city street running east–west, 200 m of it recorded, as a highway region
  (id 1) 16 m wide between its boundary lines, with a one-way roadway (id 2) 8 m wide on it whose
  designated direction of travel runs east, and a regulatory sign (id 1) of code `one_way`
  governing that roadway, its legend stating no restriction. The car (track 1, a motor vehicle,
  4 m × 2 m) is at the middle of the roadway and drives along it; each trace is three observations
  one second apart (0, 1000, 2000 ms).

  `forbid` drives it west at 8 m/s against the designated direction (component about −8 m/s);
  `permit` drives it east at 8 m/s with the designation (about +8 m/s); `branch_1` has it standing
  still, pointed west, while it loads (component 0, within the tolerance); `blind` is the forbid
  scene with the designated direction of travel of structures declared absent. `idle` is another
  street: a two-way roadway (id 12) with an east lane (13) and a west lane (14), no one-way sign
  anywhere, the car driving east at 8 m/s in the west lane. `branch_2` is the forbid scene with the
  sign's legend restricting it to 07:00–09:00 on weekdays and the observation on a Wednesday at
  14:00, so the posted conditions do not hold.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_220_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_220_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

/-- The highway: the entire width between the boundary lines of the city street. -/
def highway : Structure := Build.rect 1 .highway (m 0) (m (-8)) (m 200) (m 8)

/-- The roadway on it, restricted to one direction, its designated direction of travel to the east. -/
def oneWayRoadway : Structure :=
  { Build.rect 2 .oneWayRoadway (m 0) (m (-4)) (m 200) (m 4) with
      lane := some { direction := some Build.east }
      ways := some [1] }

/-- The sign that governs that roadway: code `one_way`, a legend stating no restriction. -/
def oneWaySign : Device :=
  { Build.sign 1 .regulatorySign [2] with
      code := some .oneWay
      conditions := some {} }

/-- The car at `x` metres along the middle of the one-way roadway, pointed `heading` at `speed`. -/
def car (heading : Vec) (speed : Q) (x : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 0) heading speed (m 2, m 1, cm 75)

/-- `forbid` (violated): A car travels at 8 m/s along a one-way roadway of a city street whose designated direction of travel runs the other way, a one-way regulatory sign with no posted conditions governing that roadway. The component of its velocity along the designated direction is about minus 8 m/s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car Build.west (mps 8) (100 - 8 * Int.ofNat k) ]
      [ highway, oneWayRoadway ]
      [ oneWaySign ]

/-- `permit` (compliant): The same car on the same signposted one-way roadway travelling at 8 m/s with the designated direction: the component of its velocity along that direction is about plus 8 m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car Build.east (mps 8) (100 + 8 * Int.ofNat k) ]
      [ highway, oneWayRoadway ]
      [ oneWaySign ]

/-- The other street: a two-way roadway with an east and a west lane, and no sign at all. -/
def twoWayHighway : Structure := Build.rect 11 .highway (m 0) (m (-8)) (m 200) (m 8)

def twoWayRoadway : Structure :=
  { Build.rect 12 .roadway (m 0) (m (-4)) (m 200) (m 4) with ways := some [11] }

def eastLane : Structure :=
  { Build.lane 13 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east with
      ways := some [11] }

def westLane : Structure :=
  { Build.lane 14 [(m 0, m (-4)), (m 200, m (-4)), (m 200, m 0), (m 0, m 0)] Build.west with
      ways := some [11] }

/-- `idle` (not_applicable): A car travels along a two-way roadway against the flow in the oncoming lane. No one-way regulatory sign governs the region it occupies, so the trigger of this subsection fails and the rule does not engage. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (100 + 8 * Int.ofNat k), m (-2)) Build.east (mps 8)
          (m 2, m 1, cm 75) ]
      [ twoWayHighway, twoWayRoadway, eastLane, westLane ]
      [ ]

/-- `blind` (unknown): The forbid scene with the source declaring the designated direction of travel of structures absent: the one-way sign and its governance of the roadway are recorded and the car's velocity is recorded, but the direction the words compare it with cannot be read, so the duty is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car Build.west (mps 8) (100 - 8 * Int.ofNat k) ]
      [ highway, oneWayRoadway ]
      [ oneWaySign ]

/-- `branch_1` (compliant): The car stands still, loading, on the signposted one-way roadway with its body pointing against the designated direction. The component of its velocity along that direction is zero, within the tolerance, so it is not being driven against the designation and nothing in the scene but the subject decides the verdict. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car Build.west Q.zero 100 ]
      [ highway, oneWayRoadway ]
      [ oneWaySign ]

/-- The same sign, its legend restricting it to 07:00–09:00 on weekdays. -/
def peakHourSign : Device :=
  { Build.sign 1 .regulatorySign [2] with
      code := some .oneWay
      conditions := some { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 420, endMinute := 540 }] } }

/-- Wednesday the 11th of November 2026, 14:00: outside the sign's posted window. -/
def afternoon : Env :=
  { civilTime := some { year := 2026, month := 11, day := 11, weekday := 2, minuteOfDay := 840 } }

/-- `branch_2` (not_applicable): the forbid scene, but the one-way sign's legend restricts it to the
    weekday morning peak and the observation is a Wednesday afternoon, so the posted conditions do
    not hold and the subsection does not engage. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car Build.west (mps 8) (100 - 8 * Int.ofNat k) ]
      [ highway, oneWayRoadway ]
      [ peakHourSign ]
      (env := afternoon)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_220_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_220_1
