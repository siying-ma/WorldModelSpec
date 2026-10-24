/-
  Witnesses for drv.road.on_divided_highway.

  Two pieces of road, each straight and running east, carry the three scenarios. Every figure
  below is the witness's own; the concept has no formal parameter, so the instance fills nothing.

  The dual carriageway (`holds` and `blind`), four regions and one vehicle:

    - region 11, the highway: a rectangle from x = -20 m to x = 400 m, y = -12 m to y = 12 m;
    - region 12, a roadway inside it from y = 2 m to y = 10 m, lying on way 11;
    - region 13, the other roadway from y = -10 m to y = -2 m, lying on way 11;
    - region 14, a concrete median from y = -2 m to y = 2 m, between the two roadways and lying
      on way 11;
    - track 1 (u), a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m) on the
      centre line of roadway 12 (y = 6 m), heading east at 20 m/s;
    - three instants 1 s apart, the vehicle 20 m further along at each, so every scene is the
      same configuration carried forward.

  The vehicle's position lies inside the highway polygon and inside roadway 12's, so
  `Build.scene` derives the occupancy: track 1 occupies regions 11 and 12, and its occupancy is
  observed. Nothing ties the vehicle to the median or to the far roadway, and nothing needs to:
  the concept reads only that the vehicle is on the way.

  The undivided rural highway (`fails`), three regions and the same vehicle:

    - region 21, the highway, from y = -6 m to y = 6 m;
    - region 22, the single roadway, the whole of it, lying on way 21;
    - region 23, a painted centre line 20 cm wide at y = 0, lying on way 21;
    - track 1 at y = 3 m, heading east at 20 m/s, as before.

  holds: the way carries two distinct roadways (12 and 13) and a median (14) on it, and the
         vehicle occupies the way — every conjunct true at every instant.
  fails: only one roadway lies on the way, so no second, distinct roadway can be found, and no
         region of the scene is a median or dividing section at all; the painted centre line is
         a region of kind centre_line and no quantifier over dividers ranges over it. The body
         is false at every instant.
  blind: the dual carriageway of the holds scenario on a source whose manifest declares
         st.on_way absent, so no structure's ways are mapped. The highway, the roadways and the
         median are all still regions of their kinds, and the vehicle still occupies the way, but
         whether the roadways and the median lie on that way cannot be read: every `st_on_way`
         conjunct is unknown, no binding of the quantifiers is true, and the body is unknown.
-/
import TrafficSpec.Concepts.road.on_divided_highway
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.on_divided_highway

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The
    concept has no formal parameter and no literal formal, so there is nothing to fill. -/
def inst : Concept.Instance :=
  { name := "drv.road.on_divided_highway@w"
    concept := "drv.road.on_divided_highway"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The dual carriageway: the highway, its two roadways and the median between them, the last
    three mapped as lying on the highway. -/
def dividedWay : List Structure :=
  [ Build.rect 11 .highway (m (-20)) (m (-12)) (m 400) (m 12)
  , { Build.rect 12 .roadway (m (-20)) (m 2) (m 400) (m 10) with ways := some [11] }
  , { Build.rect 13 .roadway (m (-20)) (m (-10)) (m 400) (m (-2)) with ways := some [11] }
  , { Build.rect 14 .medianOrDivider (m (-20)) (m (-2)) (m 400) (m 2) with ways := some [11] } ]

/-- The undivided rural highway: one roadway over the whole way, and a painted centre line. -/
def undividedWay : List Structure :=
  [ Build.rect 21 .highway (m (-20)) (m (-6)) (m 400) (m 6)
  , { Build.rect 22 .roadway (m (-20)) (m (-6)) (m 400) (m 6) with ways := some [21] }
  , { Build.rect 23 .centreLine (m (-20)) (cm (-10)) (m 400) (cm 10) with ways := some [21] } ]

/-- The vehicle, `20 · k` metres along the way, on the centre line of the roadway at `y`. -/
def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (Units.metres (20 * (k : Int)), y) Build.east
    (Units.metresPerSecond 20) (m 2, m 1, m 1)

/-- `holds` (compliant): A car runs on one of the two roadways of a dual carriageway; both roadways and the concrete median between them are mapped as regions lying on the same highway, and the car's footprint overlaps that highway. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (m 6)] dividedWay []

/-- `fails` (violated): The same car on an undivided rural two-lane highway: one roadway lies on the way, the two directions are separated by a painted centre line, and no median or dividing structure is mapped anywhere on it. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (m 3)] undividedWay []

/-- `blind` (unknown): The dual carriageway as in the first scenario, on a source that maps the highway, the roadways and the median as regions but declares no relation saying which way a region lies on, so whether the roadways and the median belong to the highway the car is on cannot be read. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car k (m 6)] dividedWay []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["st.on_way"] ]

end TrafficSpecWitness.Concepts.road.on_divided_highway
