/-
  Witnesses for drv.motion.travels_with_region_direction.

  The instance fills the two formal parameters with figures of this witness's own:
  `direction_cosine` 0.98, the cosine of about 11 degrees — the largest angle between the course and
  the region's designated direction at which the course still counts as the designated one, wide
  enough for the few degrees of course error a car running straight along a way carries and far
  inside the right angle of a course across the direction (the body compares the component strictly
  against this bound times the speed, so a value of exactly 1 would leave even a course exactly
  along the direction undecided: 0.98 leaves it decidedly agreeing); and `speed_tolerance` 0.5 m/s
  (written in micrometres per second, the only exact constructor for a half), the ground speed
  within which a sampled reading cannot be told from no movement, far under the twelve metres a
  second at which the car of every scene below travels.

  Every trace runs three observations a second apart (t = 0, 1000, 2000 ms) over one static map: a
  single region 100, a lane 210 m long and 4 m wide (x in [-10, 200] m, y in [-4, 0] m) carrying a
  designated direction of travel due east. It is the region formal (`r` ↦ 100); the concept reads
  its designated direction and nothing else about it — not its kind, not whether the car is on it.

  The car is track 1, the road user judged (`u` ↦ 1): a motor vehicle 4.5 m long, 1.8 m wide and
  1.5 m tall, travelling at 12 m/s, its body pointing the way it travels, so its velocity is twelve
  metres a second along its heading.

  `holdsTrace` — the car runs east along the lane at y = -2 m, from x = 0 m and twelve metres on at
  each later observation. Its velocity is (12, 0) m/s and the designated direction reads (1, 0), so
  the component of the velocity along the designated direction is its whole 12 m/s, above the
  0.98 × 12 = 11.76 m/s the instance's cosine bound requires, and its speed of 12 m/s is above the
  half metre a second tolerance. The body holds at every instant.

  `failsTrace` — the same lane, designated due east, and the same car travelling due north at
  12 m/s, from (20, -2) m and twelve metres further north at each later observation. Its velocity is
  (0, 12) m/s, so the component along the designated direction (1, 0) is 0 m/s, which is not above
  11.76 m/s: the course is a right angle off the designated direction. The car is in motion, so the
  first conjunct holds and the body is false at every instant.

  `blindTrace` is the running car of `holdsTrace`, judged with st.lane_direction absent: the car's
  velocity and ground speed are read as before, so it is decidedly in motion, but no region records
  a designated direction of travel, so both components of the direction are unknown, the component
  of the velocity along it is unknown, and the body is unknown — a course that agrees with the
  designated direction cannot be told from one that does not.
-/
import TrafficSpec.Concepts.motion.travels_with_region_direction
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.travels_with_region_direction

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall, as half-extents. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Twelve metres a second, the speed of the car in every scene. -/
def runSpeed : Q := Units.metresPerSecond 12
/-- The distance travelled in `k` seconds at `runSpeed`. -/
def advance (k : Nat) : Q := Q.mul runSpeed (Q.ofInt (Int.ofNat k))

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100

/-- The instance every scenario speaks about: every parameter given a value of the witness's own
    through a `Units` constructor. -/
def inst : Concept.Instance :=
  { name := "drv.motion.travels_with_region_direction@w"
    concept := "drv.motion.travels_with_region_direction"
    literals := []
    nats := []
    params :=
      [ ("direction_cosine", .lit (Units.ratio 98 100) .ratio)
      , ("speed_tolerance", .lit (Units.micrometresPerSecond 500000) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The map: one lane, 210 m long and 4 m wide, designated due east
-- ---------------------------------------------------------------------------------------------
/-- The region the caller names: a lane carrying a designated direction of travel due east. -/
def designatedLane : Structure :=
  Build.lane 100
    [(m (-10), m (-4)), (m 200, m (-4)), (m 200, m 0), (m (-10), m 0)]
    Build.east

def map : List Structure := [designatedLane]

/-- The car at position `pos`, travelling at `runSpeed` with its body pointing `heading`. -/
def car (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading runSpeed carExtent

/-- `holds` (compliant): A region carries a designated direction of travel due east. The road user travels due east at 12 m/s, its body pointing east, so the component of its velocity along the designated direction is its whole speed and the course is exactly the designated one. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (advance k, m (-2)) Build.east ]
      map
      [ ]  -- devices

/-- `fails` (violated): The same region designated due east. The road user travels due north at 12 m/s: the component of its velocity along the designated direction is zero, so its course is a right angle off the designated direction and agrees with it for no nonnegative cosine bound. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m 20, Q.add (m (-2)) (advance k)) Build.north ]
      map
      [ ]  -- devices

/-- `blind` (unknown): The same region and a road user travelling east at 12 m/s, but the source records no designated direction of travel for any region, so whether the course agrees with the region's designated direction cannot be decided. -/
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.Concepts.motion.travels_with_region_direction
