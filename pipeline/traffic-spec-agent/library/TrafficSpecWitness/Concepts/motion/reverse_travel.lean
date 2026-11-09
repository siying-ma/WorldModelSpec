/-
  Witnesses for drv.motion.reverse_travel.

  The geometry. A parking bay beside a flat street, as one parking space region (`bay`, region 10,
  the rectangle (−1.50, 0.00)–(1.50, 5.00)); the bay is read by nothing — the concept reads no
  region — and stands in the scenes only because the narratives speak of it. The road user the
  formal `u` is grounded to is track 1, a motor vehicle 4.8 m long and 1.8 m wide (half-extents
  2.40 m, 0.90 m, 0.75 m), parked nose-in and so pointing north (the heading (0, 1), an
  axis-aligned direction, which a formula reads as exactly the unit vector). Every trace is
  sampled at 1 s over three observations, and every scene carries the car's position, heading,
  speed and velocity.

  The instance's figure is the witness's own: reverse_speed_tolerance 0.30 m/s, a resolution a
  standing body's measurement noise stays below and the 1.5 m/s of the narratives clears.

  Since the concept speaks about the observation only, each witness is judged over the whole of
  its trace and needs no window.

  `holds`: the car reverses out of the bay at 1.5 m/s. Its heading stays north while its velocity
  is (0, −1.5) m/s, so the component along the heading is −1.5 m/s at every observation, at most
  the negative of the tolerance (−0.30 m/s); the positions walk south out of the bay, 1.5 m per
  second: (0, 3.00), (0, 1.50), (0, 0).

  `fails`: the same car drives forward out of the bay at 1.5 m/s, nose first — the velocity
  follows the heading, so the component along it is +1.5 m/s at every observation, above the
  negative of the tolerance; the positions walk north, (0, 0), (0, 1.50), (0, 3.00).

  `blind` (`kin.velocity` absent): the reversing manoeuvre of `holds`, with the source declaring
  road-user velocity absent. The heading is read, the velocity is not, so the component along the
  heading is unknown and the body with it, never false.
-/
import TrafficSpec.Concepts.motion.reverse_travel
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.reverse_travel

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A speed in m/s, written to the micrometre per second. -/
def mps (n : Int) : Q := Units.micrometresPerSecond n

/-- 1.5 m/s: the speed of the manoeuvre in every narrative. -/
def manoeuvreSpeed : Q := mps 1500000
/-- 0.30 m/s: the tolerance the instance gives the formal parameter. -/
def tolerance : Q := mps 300000

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the one formal parameter given the witness's own
    resolution, below the speed of the manoeuvre. -/
def inst : Concept.Instance :=
  { name := "drv.motion.reverse_travel@w"
    concept := "drv.motion.reverse_travel"
    literals := []
    nats := []
    params := [("reverse_speed_tolerance", .lit tolerance .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The parking bay, as one parking space region; no formula of the concept reads it. -/
def bay : Structure := Build.rect 10 .parkingSpace (cm (-150)) (m 0) (cm 150) (m 5)

/-- Track 1, parked nose-in and so pointing north, with the velocity the source measured (which
    need not follow the heading: a body in motion rearward has it opposed to the heading). -/
def car (pos : Vec) (velocity : Vec) (speed : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos Build.north speed (cm 240, cm 90, cm 75))
    fun k => { k with velocity := some velocity }

/-- The car's velocity while it reverses: 1.5 m/s opposite the heading it keeps. -/
def rearward : Vec := Build.scale Build.north (Q.neg manoeuvreSpeed)
/-- The car's velocity while it drives forward: 1.5 m/s along the heading. -/
def forward : Vec := Build.scale Build.north manoeuvreSpeed

/-- The reversing manoeuvre: the heading stays north, the velocity points south, and the car walks
    south out of the bay at 1.5 m/s. -/
def reversingTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => car (m 0, cm 300) rearward manoeuvreSpeed
         | 1 => car (m 0, cm 150) rearward manoeuvreSpeed
         | _ => car (m 0, m 0) rearward manoeuvreSpeed) ]
      [ bay ]
      [ ]

/-- `holds` (compliant): A car reverses out of a parking bay at about 1.5 m/s: its velocity points opposite to its heading, so the component along the heading is about minus 1.5 m/s. -/
def holdsTrace : Trace := reversingTrace

/-- `fails` (violated): The same car drives forward out of the bay at 1.5 m/s: the component along its heading is about plus 1.5 m/s. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (match k with
         | 0 => car (m 0, m 0) forward manoeuvreSpeed
         | 1 => car (m 0, cm 150) forward manoeuvreSpeed
         | _ => car (m 0, cm 300) forward manoeuvreSpeed) ]
      [ bay ]
      [ ]

/-- `blind` (unknown): The same manoeuvre with the source declaring road-user velocity absent: the direction of the motion relative to the body cannot be read. -/
def blindTrace : Trace := reversingTrace

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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.Concepts.motion.reverse_travel
