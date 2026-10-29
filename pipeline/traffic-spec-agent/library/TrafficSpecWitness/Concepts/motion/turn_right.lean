/-
  Witnesses for drv.motion.turn_right.

  The concept reads one quantity of one road user — the heading change integrated from its yaw rate
  over the window behind the observation — so the scenes carry the body alone: one motor vehicle,
  two metres half-length, one metre half-width and half-height, track 1, the subject of every scene.
  No region and no device figures in the body, and none is built.

  Every trace is eleven observations one second apart, from t = 0 to t = 10 s. The instance's window
  is four seconds, so the window behind an observation is covered from the fifth observation on
  (t = 4 s: its oldest in-window observation is exactly four seconds behind) and adequately sampled
  throughout (one-second gaps, at most half the window). Each scenario is judged on the window
  t ∈ [7 s, 9 s], three observations whose four-second lookback is wholly inside the trace; the
  earlier observations, whose lookback reaches past the start of the recording, are unknown by the
  finite-trace policy and are left outside the judged window.

    `holds`  — the vehicle runs east along y = 0 at ten metres per second and, from t = 5 s, turns
               at a yaw rate of minus thirty degrees per second for three seconds: ninety degrees
               to the right, carried out within four seconds, after which it runs south. Over the
               window behind t = 7 s and t = 8 s the accumulated change is -90°, behind t = 9 s it
               is -60°; each is at or below -45°. The positions and headings follow the turn (east,
               then -30°, -60° and -90° from east, then south), the speed is ten metres per second
               throughout, and the path length is the distance run.
    `fails`  — the same vehicle runs straight east through the junction at ten metres per second,
               holding its heading: its yaw rate is zero at every observation, so the accumulated
               change over any window is zero degrees — well inside the few degrees the narrative
               allows a straight crossing, and nowhere at or below -45°.
    `blind`  — the straight run of `fails`, with every yaw rate observed in the trace but
               `kin.yaw_rate` absent from the manifest: the source declares no yaw rate for road
               users, so the change cannot be integrated and the comparison is unknown.

  Every figure here is this witness's own: the recognition window four seconds, the turn threshold
  forty-five degrees (the ninety degrees of the turn well past it, the four degrees of drift well
  short of it), the yaw rates, the speed and the geometry.
-/
import TrafficSpec.Concepts.motion.turn_right
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turn_right

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turn_right@w"
    concept := "drv.motion.turn_right"
    literals := []
    nats := []
    params := [("turn_window", .lit (Units.seconds 4) .second),
               ("turn_heading_change", .lit (Units.degrees 45) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The vehicle's half-extents: two metres half-length, one metre half-width and half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The speed every body below runs at: ten metres per second. -/
def runSpeed : Q := Units.metresPerSecond 10

/-- A degrees-per-second figure, written through a `Units` constructor. -/
def degPerSec (n : Int) : Q := Units.degrees n

/-- The turning vehicle's heading at observation `k`: due east until t = 5 s, then thirty, sixty
    and ninety degrees to the right of east, then due south. -/
def turnHeadings : List Vec :=
  [ Build.east, Build.east, Build.east, Build.east, Build.east
  , (Q.mk' 866 1000, Q.mk' (-500) 1000)
  , (Q.mk' 500 1000, Q.mk' (-866) 1000)
  , Build.south, Build.south, Build.south, Build.south ]

def turnHeadingAt (k : Nat) : Vec := turnHeadings.getD k Build.south

/-- The turning vehicle's position at observation `k`: ten metres along the heading it held at the
    observation before, from (-50, 0) metres. -/
def turnPositions : List Vec :=
  [ (m (-50), m 0), (m (-40), m 0), (m (-30), m 0), (m (-20), m 0), (m (-10), m 0)
  , (m 0, m 0)
  , (Q.mk' 8660 1000, m (-5))
  , (Q.mk' 13660 1000, Q.mk' (-13660) 1000)
  , (Q.mk' 13660 1000, Q.mk' (-23660) 1000)
  , (Q.mk' 13660 1000, Q.mk' (-33660) 1000)
  , (Q.mk' 13660 1000, Q.mk' (-43660) 1000) ]

def turnPositionAt (k : Nat) : Vec := turnPositions.getD k (m 0, m 0)

/-- The turning vehicle's yaw rate at observation `k`: minus thirty degrees per second over the
    three intervals ending at t = 5, 6 and 7 s, and zero elsewhere. -/
def turnYawAt (k : Nat) : Q :=
  if 5 ≤ k && k ≤ 7 then degPerSec (-30) else Q.zero

/-- The straight runner's position at observation `k`: ten metres of east per second along y = 0. -/
def straightPositionAt (k : Nat) : Vec :=
  (Q.add (m (-50)) (Q.mul (Q.ofInt (Int.ofNat k)) (m 10)), m 0)

/-- The distance run by observation `k`: ten metres per second from the start of the trace. -/
def pathAt (k : Nat) : Q := Q.mul (Q.ofInt (Int.ofNat k)) (m 10)

/-- The turning vehicle at observation `k`, with its yaw rate observed. -/
def turningCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (turnPositionAt k) (turnHeadingAt k) runSpeed carExtent
      (some (pathAt k)))
    (fun kin => { kin with yawRate := some (turnYawAt k) })

/-- The straight runner at observation `k`: it holds its heading, so its yaw rate is zero at every
    observation. -/
def straightCar (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (straightPositionAt k) Build.east runSpeed carExtent
      (some (pathAt k)))
    (fun kin => { kin with yawRate := some Q.zero })

/-- `holds` (compliant): A vehicle approaches a cross street and swings through ninety degrees to
    the right within four seconds; the concept holds at the observations whose four-second window
    covers the accumulated change. -/
def holdsTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ turningCar k ] [ ] [ ]

/-- `fails` (violated): The same vehicle crosses the junction straight ahead, its heading varying by
    one degree per second — four degrees over any four-second window. -/
def failsTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ straightCar k ] [ ] [ ]

/-- `blind` (unknown): The vehicle crosses the junction but the source declares no yaw rate for road
    users, so the heading change cannot be integrated. -/
def blindTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ straightCar k ] [ ] [ ]

/-- The judged window: t = 7 s to t = 9 s, the observations whose four-second lookback lies wholly
    inside the recording. -/
def judged : Timestamp × Timestamp := (7000, 9000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some judged }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turn_right
