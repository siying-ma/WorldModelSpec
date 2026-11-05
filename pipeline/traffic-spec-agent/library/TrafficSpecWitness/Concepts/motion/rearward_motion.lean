/-
  Witnesses for drv.motion.rearward_motion.

  One body: track 1, a motor vehicle 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), pointing
  east (heading (1, 0), which the heading atom delivers exactly as the unit vector) at every
  instant of every trace. No region and no device: the concept reads kinematics alone. Each trace
  is three scenes a second apart, from t = 0; the body's position advances with its velocity, so
  the scenes are a consistent motion.

  The instance's own figure: `reverse_speed_tolerance` = 0.1 m/s (100000 micrometres per second),
  the magnitude below which a velocity component counts as no travel.

  - `holds`: the velocity is 1.4 m/s due west — (−1.4, 0) m/s, speed 1.4 m/s — while the body
    points east, so the component along the heading is −1.4 m/s: negative, and 1.4 m/s is above
    the 0.1 m/s tolerance. The body backs up 1.4 m a second: x = 0, −1.4, −2.8 m.
  - `fails`: the same body, velocity 8 m/s due east — (8, 0) m/s — so the component along the
    heading is +8 m/s, not negative: it is travelling forward, not rearward. x = 0, 8, 16 m.
  - `blind`: the `holds` scenes with kin.velocity declared absent by the manifest; the heading is
    still observed, but the component along it cannot be computed, so the concept is unknown.
-/
import TrafficSpec.Concepts.motion.rearward_motion
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.rearward_motion

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- 1.4 m/s, the rearward speed of the `holds` scenes. -/
def backSpeed : Q := Units.micrometresPerSecond 1400000
/-- 8 m/s, the forward speed of the `fails` scenes. -/
def fwdSpeed : Q := Units.metresPerSecond 8

/-- The half-extents of the car: 2 m half-length, 1 m half-width, 1 m half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The car at scene `k`: pointing east, displaced by `k` seconds of the velocity `v`, with that
    velocity and its magnitude `spd`. -/
def car (k : Nat) (v : Vec) (spd : Q) : RoadUser :=
  let step : Q := Q.ofInt (Int.ofNat k)
  let pos : Vec := (Q.mul v.1 step, Q.mul v.2 step)
  Build.withKin (Build.user 1 [.motorVehicle] pos Build.east spd carExtent)
    fun kin => { kin with velocity := some v }

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the one formal parameter given 0.1 m/s. -/
def inst : Concept.Instance :=
  { name := "drv.motion.rearward_motion@w"
    concept := "drv.motion.rearward_motion"
    literals := []
    nats := []
    params := [("reverse_speed_tolerance", .lit (Units.micrometresPerSecond 100000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The velocity of the `holds` (and `blind`) scenes: 1.4 m/s due west. -/
def backVelocity : Vec := Build.scale Build.west backSpeed
/-- The velocity of the `fails` scenes: 8 m/s due east. -/
def fwdVelocity : Vec := Build.scale Build.east fwdSpeed

/-- `holds` (compliant): A car points east and its velocity is 1.4 m/s to the west: the component along its heading is −1.4 m/s, whose magnitude is above the tolerance. -/
def holdsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ car k backVelocity backSpeed ] [ ] [ ]

/-- `fails` (violated): The same car's velocity is 8 m/s to the east: the component along its heading is positive, so it is not travelling rearward. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ car k fwdVelocity fwdSpeed ] [ ] [ ]

/-- `blind` (unknown): The source declares kin.velocity absent for the car, so the component along its heading cannot be computed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ car k backVelocity backSpeed ] [ ] [ ]

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

end TrafficSpecWitness.Concepts.motion.rearward_motion
