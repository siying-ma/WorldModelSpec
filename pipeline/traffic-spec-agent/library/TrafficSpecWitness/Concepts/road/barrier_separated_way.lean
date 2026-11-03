/-
  Witnesses for drv.road.barrier_separated_way.

  The instance has no literal formal, no nat and no parameter: the concept reads one region, the
  way, and measures nothing, so every figure below is geometry of the scene alone.

  Every trace is three scenes one second apart (t = 0, 1 000, 2 000 ms) in a world frame with +x
  east and +y north, and the map is the same in all three, as a map is. The concept has no
  temporal operator, so no scenario needs a window: the body is read at each of the three
  instants on its own.

  The way every scenario speaks about is region 100, a highway a hundred metres long and
  twenty-four wide, from (−50, −12) to (50, 12); the formal `w` is grounded to it. One motor
  vehicle (track 1, 5 m by 1.8 m) runs east along the southern half at ten metres a second, from
  (0, −6) through (10, −6) to (20, −6); it is the scene's subject and nothing of it is read — the
  concept speaks of the way's structures, not of a road user.

  `holds`: the highway carries a concrete median (region 103, the four metres from y = −2 to
  y = 2) and two roadway regions apart from it (101, from y = 2 to y = 10, and 102, from y = −10
  to y = −2), and all three record region 100 as the way they lie on. So a dividing region lies on
  the way and two distinct roadway regions lie on it as well, at each of the three instants.

  `fails`: the same highway carries one roadway region only (110, the whole of y = −10 to y = 10,
  lying on region 100) with a painted centre line (region 111, the twenty centimetres about
  y = 0, lying on region 100 too) and no dividing structure of any kind: no region of the scene is
  a median or divider, and no second roadway region exists to be held apart from the first, so
  both halves of the body are false. A marked division is no physical barrier.

  `blind`: the `holds` map under a manifest that declares st.on_way absent, so no structure
  records the way it lies on. The median region and the two roadway regions are all still there
  and still of their kinds, but whether any of them lies on region 100 cannot be read, so the body
  is unknown at every instant — for the masked atom alone, every kind being observed.
-/
import TrafficSpec.Concepts.road.barrier_separated_way
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.barrier_separated_way

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The public way of every scenario: a highway region a hundred metres long and twenty-four wide. -/
def way : Structure := Build.rect 100 .highway (m (-50)) (m (-12)) (m 50) (m 12)

/-- A structure of the way: the region with region 100 recorded as the way it lies on. -/
def onWay (st : Structure) : Structure := { st with ways := some [100] }

/-- The northern roadway of the divided highway, eight metres wide. -/
def northRoadway : Structure := onWay (Build.rect 101 .roadway (m (-50)) (m 2) (m 50) (m 10))

/-- The southern roadway, a separate region of the same way. -/
def southRoadway : Structure := onWay (Build.rect 102 .roadway (m (-50)) (m (-10)) (m 50) (m (-2)))

/-- The dividing structure between them: a concrete median four metres wide. -/
def median : Structure :=
  onWay (Build.rect 103 .medianOrDivider (m (-50)) (m (-2)) (m 50) (m 2))

/-- The single undivided roadway of `fails`, the whole width of the way between its edges. -/
def wholeRoadway : Structure := onWay (Build.rect 110 .roadway (m (-50)) (m (-10)) (m 50) (m 10))

/-- The painted centre line of `fails`: twenty centimetres of marking, no physical barrier. -/
def paintedCentreLine : Structure :=
  onWay (Build.rect 111 .centreLine (m (-50)) (cm (-10)) (m 50) (cm 10))

/-- The vehicle running east along the southern half of the way at ten metres a second: the
    scene's subject, of which the concept reads nothing. -/
def car (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (10 * Int.ofNat k), m (-6)) Build.east
    (Units.metresPerSecond 10) (cm 250, cm 90, cm 75)

-- Formals ↦ tracks: (no track formal)
-- Formals ↦ regions: w ↦ 100  (the highway region of every trace)

/-- The instance every scenario speaks about: the concept takes one region and no literal, nat or
    parameter, so there is nothing here to choose. -/
def inst : Concept.Instance :=
  { name := "drv.road.barrier_separated_way@w"
    concept := "drv.road.barrier_separated_way"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A highway region carries a concrete median region and two separate roadway regions, all three recorded as lying on it. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k ]
      [ way, northRoadway, southRoadway, median ]
      [ ]

/-- `fails` (violated): A highway region carries one roadway region with a painted centre line and no dividing structure of any kind. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k ]
      [ way, wholeRoadway, paintedCentreLine ]
      [ ]

/-- `blind` (unknown): A highway carries two roadway regions, but the source does not record which way its structure regions lie on, so whether a dividing structure lies on this way cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k ]
      [ way, northRoadway, southRoadway, median ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := []
    regions := [("w", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.on_way"] ]

end TrafficSpecWitness.Concepts.road.barrier_separated_way
