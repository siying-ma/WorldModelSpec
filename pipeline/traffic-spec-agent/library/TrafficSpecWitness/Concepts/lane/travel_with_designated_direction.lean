/-
  Witnesses for drv.lane.travel_with_designated_direction.

  The geometry, one straight single-lane one-way street, is the same in all three scenarios. The
  street runs north-east on a 3-4-5 bearing, so that both components of the designation and both
  components of the velocity carry weight in the along-lane component, and every figure stays an
  exact rational:

    - the designated direction of travel is d = (3/5, 4/5), a vector of unit length;
    - region 10, the lane: the 4 m wide strip about the centre line through the origin along d,
      from 100 m behind the origin to 300 m ahead of it. Its four corners are the ends of that
      centre line shifted 2 m to the left (-1.6 m, +1.2 m) and 2 m to the right (+1.6 m, -1.2 m)
      of it, so the strip is a straight corridor of constant width;
    - track 1 (u), a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), on the
      lane's centre line, heading and running at 8 m/s either with d or against it;
    - three instants 1 s apart, the vehicle advancing 8 m along the centre line per instant, so
      each scene is the same configuration carried forward.

  The vehicle's velocity is its heading (a unit vector) times its speed, so with the designation
  it is 8·(3/5, 4/5) = (4.8, 6.4) m/s and against it (-4.8, -6.4) m/s; the inner product with
  d is +8 m/s and -8 m/s exactly.

  The source maps the lane region and the vehicle's membership of it, which the scenes state
  directly (`occupies`); the vehicle's position lies on the centre line, well inside the strip,
  so the stated membership is the one the geometry gives.

  The witness's own figure, the one the instance gives the formal parameter:
    along_lane_speed_tolerance = 0.5 m/s (written in micrometres per second, exactly).

  holds: the vehicle runs at 8 m/s with the designation, so the along-lane component is +8 m/s,
         above the 0.5 m/s tolerance — the lane, the occupancy and the comparison all true at
         every instant.
  fails: the same vehicle in the same lane driven up the street the other way at 8 m/s: its
         heading and its velocity are reversed, the along-lane component is -8 m/s, below the
         tolerance, so the comparison is false at every instant while the lane and the occupancy
         stay true.
  blind: the holds configuration, with st.lane_direction absent from the manifest. The source
         maps the lane region and the membership of it, but declares no designated direction for
         any lane, so both components of the designation are unobserved, the inner product has no
         value and the comparison is unknown; the lane's kind and the occupancy stay decided.
-/
import TrafficSpec.Concepts.lane.travel_with_designated_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.lane.travel_with_designated_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.lane.travel_with_designated_direction@w"
    concept := "drv.lane.travel_with_designated_direction"
    literals := []
    nats := []
    params := [("along_lane_speed_tolerance", .lit (Units.micrometresPerSecond 500000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The direction of travel the lane is designated for: the 3-4-5 bearing, of unit length. -/
def designated : Vec := (Units.ratio 3 5, Units.ratio 4 5)

/-- The same bearing reversed: up the street the other way. -/
def against : Vec := (Units.ratio (-3) 5, Units.ratio (-4) 5)

/-- A point of the lane's centre line, `s` along the designation from the origin. -/
def alongLane (s : Q) : Vec := Build.scale designated s

/-- Vector addition, for the corners of the lane. -/
def shift (p q : Vec) : Vec := (Q.add p.1 q.1, Q.add p.2 q.2)

/-- Half the lane's width (2 m) to the left of the centre line. -/
def toLeft : Vec := (cm (-160), cm 120)
/-- Half the lane's width (2 m) to the right of the centre line. -/
def toRight : Vec := (cm 160, cm (-120))

/-- Region 10: the 4 m wide corridor about the centre line, from 100 m behind the origin to
    300 m ahead of it, designated for travel along `designated`. -/
def street : Structure :=
  Build.lane 10
    [ shift (alongLane (m (-100))) toLeft
    , shift (alongLane (m 300)) toLeft
    , shift (alongLane (m 300)) toRight
    , shift (alongLane (m (-100))) toRight ]
    designated

/-- The car, `s` metres along the centre line, pointing and running at 8 m/s along `h`. -/
def car (s : Q) (h : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] (alongLane s) h (Units.metresPerSecond 8) (m 2, m 1, m 1)

/-- One instant: the car on the lane's centre line, its membership of the lane mapped. -/
def sceneAt (s : Q) (h : Vec) (t : Timestamp) : Scene :=
  Build.scene t (some 1) [car s h] [street] [] (occupies := some [(1, 10)])

/-- `holds` (compliant): A car runs at 8 m/s along a single-lane one-way street, its footprint in the lane and its velocity along the lane's designated direction. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt (Units.metres (8 * (k : Int))) designated t

/-- `fails` (violated): The same car in the same lane, driven up the street the other way at 8 m/s: its velocity points against the lane's designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt (Units.metres (16 - 8 * (k : Int))) against t

/-- `blind` (unknown): The same car in the same lane on a source that maps lane regions and road users' membership of them but declares no designated direction for any lane. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    sceneAt (Units.metres (8 * (k : Int))) designated t

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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.lane.travel_with_designated_direction
