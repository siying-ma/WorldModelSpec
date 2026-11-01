/-
  Witnesses for drv.interaction.caravan.

  The instance fills the four formal parameters with figures of this witness's own: `max_gap` 10 m,
  the longitudinal body-to-body gap within which a road user counts as travelling close behind the
  one ahead — wider than the 7.5 m between the bodies of cars running twelve metres apart centre to
  centre, narrower than the 19.5 m to the car beyond that, so each car of a line counts as
  travelling behind exactly the one immediately ahead of it; `same_direction_cosine` 0.98, the
  cosine of about 11 degrees, well inside the few degrees of heading error a line of cars on a
  straight way carries and well outside a cross street (drv.interaction.following compares the
  cosine strictly against this bound, so a value of exactly 1 would decide nothing: 0.98 leaves
  identical headings decidedly agreeing); `min_followers` 5, so a line counts as this configuration
  at five road users following another besides the one at the head — six vehicles; and
  `speed_tolerance` 0.5 m/s (written in micrometres per second, the only exact constructor for a
  half), the ground speed at or below which a sampled reading counts as no movement, under the
  metre a second at which the rearmost car of the halted queue creeps and far under the
  twenty-five metres a second of the running line.

  Every trace runs three observations a second apart (t = 0, 1000, 2000 ms) over a static map: a
  rural highway (region 100, a `highway` region 210 m long and 16 m wide, x in [-10, 200] m,
  y in [-8, 8] m) with one eastbound lane lying inside it (region 101, y in [-4, 0] m, designated
  due east). Occupancy follows the geometry, so every car on the lane occupies both the lane — the
  common lane drv.interaction.following reads — and the way, the highway region the body reads.

  Seven cars (tracks 1 to 7, each 4.5 m long, 1.8 m wide, 1.5 m tall) run on the lane at y = -2 m,
  twelve metres apart centre to centre, track 1 the rearmost and the road user judged (`u` ↦ 1),
  track 7 at the head. The cars read no class in this concept; they are built as motor vehicles
  because a recorded body carries its classes.

  `holdsTrace` — the line runs east at 25 m/s, every car moving, each 7.5 m of body-to-body gap
  behind the one ahead: track 1 travels directly behind track 2, which is in motion; six of the
  seven cars (tracks 1 to 6) are in motion and follow another car in motion on the way, which is at
  least the five the instance requires; and track 1 is in motion. The body holds at every instant.

  `failsTrace` — the same seven cars stand in the lane at the same spacing, halted in a queue: all
  speeds are zero but track 1's, which creeps east at 1 m/s. Track 1 is in motion, but the car it
  travels behind is at a standstill and so is every other car, so no road user in motion follows a
  road user in motion: the first conjunct is false and the count is zero, below five. The body is
  false at every instant.

  `blindTrace` is the running line of `holdsTrace`, judged with kin.speed absent: every body is
  mapped, so the following relation is decided throughout, but whether any car is in motion cannot
  be read, so each conjunct that reads motion is unknown and the body is unknown — a moving line
  and a halted queue cannot be told apart.
-/
import TrafficSpec.Concepts.interaction.caravan
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.interaction.caravan

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- The cars: 4.5 m long, 1.8 m wide, 1.5 m tall, as half-extents. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Twenty-five metres a second, the speed of the running line. -/
def runSpeed : Q := Units.metresPerSecond 25
/-- A metre a second, the creep of the rearmost car of the halted queue. -/
def creepSpeed : Q := Units.metresPerSecond 1
/-- Centre-to-centre spacing of the line, in metres: 12 m, leaving 7.5 m between the bodies. -/
def spacing : Int := 12

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: every parameter given a value of the witness's own
    through a `Units` constructor. -/
def inst : Concept.Instance :=
  { name := "drv.interaction.caravan@w"
    concept := "drv.interaction.caravan"
    literals := []
    nats := []
    params :=
      [ ("max_gap", .lit (Units.metres 10) .metre)
      , ("same_direction_cosine", .lit (Units.ratio 98 100) .ratio)
      , ("min_followers", .lit (Q.ofInt 5) .count)
      , ("speed_tolerance", .lit (Units.micrometresPerSecond 500000) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The map: a rural highway with one eastbound lane lying inside it
-- ---------------------------------------------------------------------------------------------
/-- The way the line travels on: a highway region 210 m long and 16 m wide. -/
def way : Structure := Build.rect 100 .highway (m (-10)) (m (-8)) (m 200) (m 8)

/-- The eastbound lane of that way. -/
def travelLane : Structure :=
  Build.lane 101
    [(m (-10), m (-4)), (m 200, m (-4)), (m 200, m 0), (m (-10), m 0)]
    Build.east

def map : List Structure := [way, travelLane]

/-- The `i`-th car of the line (i = 1 the rearmost, i = 7 at the head), at longitudinal offset `x`
    from the rearmost car's start, running east at `speed`. -/
def car (i : Nat) (x : Q) (speed : Q) : RoadUser :=
  Build.user i [.motorVehicle] (x, m (-2)) Build.east speed carExtent

/-- The distance travelled in `k` seconds at `speed`. -/
def advance (speed : Q) (k : Nat) : Q := Q.mul speed (Q.ofInt (Int.ofNat k))

/-- The seven cars of the line at step `k`, the whole line advanced by `speed` each second. -/
def runningLine (k : Nat) (speed : Q) : List RoadUser :=
  (List.range 7).map fun j =>
    car (j + 1) (Q.add (m (spacing * Int.ofNat j)) (advance speed k)) speed

/-- The seven cars of the halted queue at step `k`: every car stands where it stood, but the
    rearmost creeps east at `creepSpeed`. -/
def haltedQueue (k : Nat) : List RoadUser :=
  car 1 (advance creepSpeed k) creepSpeed
    :: ((List.range 6).map fun j => car (j + 2) (m (spacing * (Int.ofNat j + 1))) Q.zero)

-- ---------------------------------------------------------------------------------------------
-- The traces
-- ---------------------------------------------------------------------------------------------
/-- `holds` (compliant): Seven cars run along a rural highway at twenty-five metres per second,
    each some eight metres behind the one ahead, all headed the same way and all moving. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (runningLine k runSpeed) map []

/-- `fails` (violated): Seven cars stand halted one close behind another in the lane of a highway,
    waiting out a queue; the rearmost, the road user judged, still creeps forward at a metre a
    second behind the stationary car ahead of it, and nothing else on the road moves. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (haltedQueue k) map []

/-- `blind` (unknown): A line of seven cars runs along the highway as in the first scenario, but the
    source maps their bodies without ground speeds, declaring speed absent, so whether any of them
    is in motion - and so whether this is a moving line or a halted queue - cannot be decided. -/
def blindTrace : Trace := holdsTrace

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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"] ]

end TrafficSpecWitness.Concepts.interaction.caravan
