/-
  Witnesses for drv.road.undivided_opposed_directions.

  The instance fills opposed_direction_cosine with 0.996, the cosine of about 5.1 degrees: a pair of
  designated directions counts as opposite when it lies within some 5 degrees of exactly opposed,
  which is well inside the few degrees of bearing error a recorded centre line of a straight street
  carries and well outside the right angle of a cross street or the zero of a one-way street.

  Every trace runs three observations a second apart (t = 0, 1000, 2000 ms) over a static map: the
  concept reads the map alone, so nothing of the geometry changes between them. Each trace carries
  one car (track 1, 4.5 m long and 1.8 m wide) running east at 10 m/s, from x = -10 m to x = 10 m:
  the car is the trace's subject and plays no part in the body, which reads no road user — it is
  there because a recorded scene has a subject.

  In every trace region 100 is the way the concept is asked about, a `highway` region 100 m long,
  and the region formal `w` is grounded to it.

  `holdsTrace` — an ordinary residential street: the way (region 100, y in [-4, 4] m) with two lanes
  lying on it, the eastbound lane (region 101, y in [-4, 0] m) designated due east and the westbound
  lane (region 102, y in [0, 4] m) designated one degree north of due west, (-0.99985, 0.01745). No
  median or dividing section is recorded. The cosine of the angle between the two designated
  directions is -0.99985, below -0.996, so the way is laid out for travel in two opposed directions,
  and nothing divides them.

  `failsTrace` — a dual carriageway: the way (region 100, y in [-10, 10] m) with two roadways lying
  on it, the eastbound roadway (region 101, y in [-8, -2] m) designated due east and the westbound
  roadway (region 102, y in [2, 8] m) designated due west, and a dividing section (region 103,
  y in [-2, 2] m) lying on the way between them. The two designated directions are exactly opposed,
  cosine -1, so the second conjunct holds and the concept fails on the divider alone.

  `blindTrace` is the residential street of `holdsTrace`, judged with st.lane_direction masked: no
  travel region on the way carries a designated direction that can be read, so the cosine cannot be
  formed and whether the way is laid out for opposed directions is unknown, though the way is still
  recorded as undivided.
-/
import TrafficSpec.Concepts.road.undivided_opposed_directions
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.road.undivided_opposed_directions

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A designated direction, its components in hundred-thousandths; it is read normalised, so only
    the direction of the vector matters. `dir (-99985) 1745` is one degree north of due west. -/
def dir (x y : Int) : Vec := (Units.ratio x 100000, Units.ratio y 100000)
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Ten metres a second, the speed of the one car of every trace. -/
def speed : Q := Units.metresPerSecond 10

-- Formals ↦ tracks: (no track formal)
-- Formals ↦ regions: w ↦ 100

/-- The instance every scenario speaks about: two designated directions count as opposite within
    about 5.1 degrees of exactly opposed. -/
def inst : Concept.Instance :=
  { name := "drv.road.undivided_opposed_directions@w"
    concept := "drv.road.undivided_opposed_directions"
    literals := []
    nats := []
    params := [("opposed_direction_cosine", .lit (Units.ratio 996 1000) .ratio)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The map pieces: a way 100 m long, and the regions lying on it
-- ---------------------------------------------------------------------------------------------
/-- The way the concept is asked about, from `y0` to `y1` and 100 m long. -/
def way (y0 y1 : Q) : Structure := Build.rect 100 .highway (m (-50)) y0 (m 50) y1

/-- A lane lying on the way, from `y0` to `y1`, with its designated direction of travel. -/
def laneOnWay (id : RegionId) (y0 y1 : Q) (d : Vec) : Structure :=
  { Build.lane id [(m (-50), y0), (m 50, y0), (m 50, y1), (m (-50), y1)] d with ways := some [100] }

/-- A roadway lying on the way, from `y0` to `y1`, with its designated direction of travel. -/
def roadwayOnWay (id : RegionId) (y0 y1 : Q) (d : Vec) : Structure :=
  { Build.rect id .roadway (m (-50)) y0 (m 50) y1 with
      lane := some { direction := some d }, ways := some [100] }

/-- The dividing section of the dual carriageway, lying on the way between its two roadways. -/
def divider : Structure :=
  { Build.rect 103 .medianOrDivider (m (-50)) (m (-2)) (m 50) (m 2) with ways := some [100] }

/-- The car, eastward at 10 m/s from x = -10 m, at the lateral offset `y`. -/
def car (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (-10 + 10 * (k : Int)), y) Build.east speed carExtent

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): An ordinary residential street is recorded as one highway region with two
    lanes lying on it, their designated directions opposed to within a degree, and no median or
    dividing section lies on it. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k (m (-2)) ]
      [ way (m (-4)) (m 4)
      , laneOnWay 101 (m (-4)) (m 0) Build.east
      , laneOnWay 102 (m 0) (m 4) (dir (-99985) 1745) ]
      []

/-- `fails` (violated): A dual carriageway is recorded as one highway region with a dividing section
    lying on it between its two roadways; the concept fails on the divider alone, as it also fails
    for a one-way street whose every travel region carries the same designated direction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car k (m (-5)) ]
      [ way (m (-10)) (m 10)
      , roadwayOnWay 101 (m (-8)) (m (-2)) Build.east
      , roadwayOnWay 102 (m 2) (m 8) Build.west
      , divider ]
      []

/-- `blind` (unknown): A street is mapped with two lanes lying on it and no divider, but the source
    declares designated lane direction absent, so whether the way is laid out for travel in opposed
    directions cannot be read. -/
def blindTrace : Trace := holdsTrace

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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.road.undivided_opposed_directions
