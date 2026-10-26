/-
  Witnesses for drv.motion.ceased_movement.

  One car and nothing else carries all three scenarios: no region, no device, no second road user,
  since the concept reads the road user's own speed and nothing besides. The car is track 1, the
  formal `u`, 4 m long and 2 m wide (half-extents 2 m, 1 m, 1 m), and it heads due east in every
  scene with yaw rate zero, so nothing of a turning enters. Two observations one second apart,
  t = 0 ms and t = 1000 ms; the body is read at the instant and looks neither behind nor ahead, so
  no padding and no window are needed and every instant of each trace is judged.

  Every figure here is the witness's own, the instance's tolerance included: 0.05 m/s, written as
  50 000 µm/s, a small positive magnitude of the kind a source's noise floor gives, since the
  contract says a sampled speed is never exactly zero.

  holds:  the car stands at x = 0, y = 0 with speed zero, hence velocity zero, and yaw rate zero,
          its position unchanged between the two observations. Its speed, zero, is at or below the
          0.05 m/s tolerance at both instants, so it has ceased movement at both.
  fails:  the same car runs due east at 8 m/s with yaw rate zero, at x = 0 at t = 0 ms and at
          x = 8 m at t = 1000 ms, its position advancing by the 8 m its velocity carries it over
          the interval. Its speed, 8 m/s, is far above the tolerance, so it is moving at both
          instants.
  blind:  the holds scene on a source whose manifest declares kin.speed absent. The car stands
          exactly as there, but the magnitude the contract compares with the tolerance is not
          observed at any instant, so the comparison and with it the concept is unknown for that
          atom alone.
-/
import TrafficSpec.Concepts.motion.ceased_movement
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.ceased_movement

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The speed
    tolerance is 0.05 m/s - the witness's own figure for the magnitude below which a measured
    speed counts as no movement. -/
def inst : Concept.Instance :=
  { name := "drv.motion.ceased_movement@w"
    concept := "drv.motion.ceased_movement"
    literals := []
    nats := []
    params := [("halt_speed_tolerance", .lit (Units.micrometresPerSecond 50000) .metrePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car of the witness at a place on the way, at a speed, heading due east with yaw rate
    zero: velocity follows the heading, so a speed of zero is a velocity of zero. -/
def car (x : Q) (speed : Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (x, m 0) Build.east speed (m 2, m 1, m 1))
    (fun k => { k with yawRate := some Q.zero })

/-- `holds` (compliant): One car and nothing else: track 1 stands at x=0 with velocity zero and yaw rate zero at t=0 and at t=1000 ms, its position unchanged between the two observations. Its speed, zero, is at or below the tolerance, so it has ceased movement. -/
def holdsTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (m 0) Q.zero ]
      []  -- no structure: the concept reads nothing of where the body stands
      []  -- no device

/-- `fails` (violated): One car and nothing else: track 1 heads due east with yaw rate zero, at x=0 and 8 m/s at t=0 and at x=8 and 8 m/s at t=1000 ms, its position advancing by the 8 m its velocity carries it over the interval. Its speed, 8 m/s, is far above the tolerance, so it is moving. -/
def failsTrace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m (8 * Int.ofNat k)) (Units.metresPerSecond 8) ]
      []  -- no structure
      []  -- no device

/-- `blind` (unknown): One car and nothing else, standing as in the holds case, on a source whose capability manifest declares speed absent. The magnitude the contract compares with the tolerance is not observed, so whether the road user has ceased movement is unknown. -/
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

end TrafficSpecWitness.Concepts.motion.ceased_movement
