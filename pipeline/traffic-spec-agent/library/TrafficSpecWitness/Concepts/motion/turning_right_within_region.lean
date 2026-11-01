/-
  Witnesses for drv.motion.turning_right_within_region.

  The instance fills min_yaw_rate with 10 degrees a second: above the heading wander of a car held
  on a line down a street, which stays within a couple of degrees a second, and well below the
  twenty-odd degrees a second a car sweeps turning right through a junction at walking pace, so the
  figure separates a body turning from a body holding its course.

  Every trace runs three observations a second apart (t = 0, 1000, 2000 ms) over one static map: a
  junction, region 100, an `intersection` region 20 m square from (-10, -10) m to (10, 10) m, to
  which the region formal `r` is grounded. The body is track 1, a motor vehicle 4.5 m long, 1.8 m
  wide and 1.5 m tall, the trace's subject, to which the track formal `u` is grounded; it is the
  only road user of every scene, since the concept reads no second body. At every observation of
  every trace its position lies inside the junction's polygon, so its footprint overlaps region 100
  throughout and the first conjunct is decided true in each. The concept reads a rate at an
  observation and no window, so the three observations of a trace are alike judged and nothing is
  padded.

  `holdsTrace` — the car swings right through the junction at 5 m/s: it runs from (-5, 2) m to
  (-2, 1) m to (1, -1) m, its heading turning from due east through twenty degrees right of east to
  forty degrees right of east, and its rate of change of heading is -20 degrees a second at each
  observation, left being positive. -20 is at most -10, so the body is turning to the right within
  the region at every observation.

  `failsTrace` — the car crosses the same junction in a straight course at 10 m/s, from (-5, 0) m
  to (5, 0) m by way of (0, 0) m, heading due east throughout, its rate of change of heading zero
  at each observation. Its footprint overlaps the junction all the same, but 0 is not at most -10,
  so the second conjunct is false and the concept fails.

  `blindTrace` is the swing to the right of `holdsTrace`, judged with kin.yaw_rate masked: the
  footprint still decidedly overlaps the junction, but the rate of change of heading cannot be
  read, so whether the body is turning is unknown.
-/
import TrafficSpec.Concepts.motion.turning_right_within_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turning_right_within_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A heading, its components in hundred-thousandths; it is a unit vector.
    `dir 93969 (-34202)` is twenty degrees right of due east. -/
def dir (x y : Int) : Vec := (Units.ratio x 100000, Units.ratio y 100000)
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: a body counts as turning rather than holding its
    course at ten degrees a second. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turning_right_within_region@w"
    concept := "drv.motion.turning_right_within_region"
    literals := []
    nats := []
    params := [("min_yaw_rate", .lit (Units.degrees 10) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The map: one junction, 20 m square
-- ---------------------------------------------------------------------------------------------
/-- The junction the concept is asked about, from (-10, -10) m to (10, 10) m. -/
def junction : Structure := Build.rect 100 .intersection (m (-10)) (m (-10)) (m 10) (m 10)

/-- The car, at a position and heading of the caller's, at `speed` m/s, with its rate of change of
    heading in degrees a second (left positive). -/
def car (pos : Vec) (heading : Vec) (speed : Q) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos heading speed carExtent)
    (fun k => { k with yawRate := some yaw })

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): The car's footprint overlaps the junction it is crossing and its heading
    turns to the right at twenty degrees a second at every observation, the bound being ten. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let (pos, heading) :=
      match k with
      | 0 => ((m (-5), m 2), Build.east)
      | 1 => ((m (-2), m 1), dir 93969 (-34202))
      | _ => ((m 1, m (-1)), dir 76604 (-64279))
    Build.scene t (some 1)
      [ car pos heading (Units.metresPerSecond 5) (Units.degrees (-20)) ]
      [ junction ]
      []

/-- `fails` (violated): The car's footprint overlaps the same junction but it crosses in a straight
    course, its rate of change of heading zero at every observation. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (-5 + 5 * (k : Int)), m 0) Build.east (Units.metresPerSecond 10)
          (Units.degrees 0) ]
      [ junction ]
      []

/-- `blind` (unknown): The car swings to the right within the junction it overlaps, but the source
    declares the rate of change of heading absent, so whether it is turning cannot be read. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turning_right_within_region
