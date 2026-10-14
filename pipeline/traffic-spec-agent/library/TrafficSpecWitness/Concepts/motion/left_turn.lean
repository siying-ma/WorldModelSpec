/-
  Witnesses for drv.motion.left_turn.

  The geometry, built once for all three scenes. One body, track 1, a car 4 m long, 1.8 m wide and
  1.5 m high (half-extents 2 m, 90 cm, 75 cm), classed motor vehicle, travelling at 8 m/s. It runs
  east along a street at y = 0 and, in the `holds` scene, turns left into the street that runs
  north: a quarter circle of radius 10 m about (16 m, 10 m), entered at (16 m, 0) heading east and
  left at (26 m, 10 m) heading north. At 8 m/s that quarter arc (15.7 m) takes about two seconds,
  which is the 45 deg/s the scene declares for its yaw rate.

  No structures and no devices: the body reads the heading-change primitive alone, and the
  primitive reads the yaw rate alone, so the two streets show only in where the car goes and
  nothing in the scenes would be read off a region.

  The instants. Each scene is seven observations one second apart, at 0 s … 6 s; the witnesses
  speak about 3 s to 5 s (the `window` field), so the two-second window behind every judged
  instant is covered by observations the trace carries rather than truncated at its start. One
  second between observations is exactly half the window, which is the adequacy the lookback asks
  for.

  The figures, all the witness's own: the window 2 s and the swing 30 deg (the instance's values
  for the formal parameters), the car's speed 8 m/s and its yaw rate through the turn 45 deg/s.
  The yaw rate is a rate, degrees per second, and `Units` carries no constructor for that unit, so
  it is written `Units.degrees 45` — the number of degrees per second. The headings are unit
  vectors of the world frame; the one at 45 deg has no exact rational unit vector, so it is
  written 408/577 in each component, the closest such approximation (408² · 2 = 332928 against
  577² = 332929). Nothing in the body reads the heading: it is there because a body that turns
  points somewhere.

  `holds`: the car runs east for the first two seconds (yaw rate zero), then turns left at
  45 deg/s for two seconds, ending pointed north, and runs north after. Over the window behind
  3 s the heading change is 45 deg, behind 4 s it is 90 deg, behind 5 s it is 45 deg — every one
  of them left-positive and above the 30 deg swing.
  `fails`: the car holds its heading east along the straight street at every observation, yaw rate
  zero throughout, so the integrated heading change is 0 deg over every window — below the swing.
  `blind`: the source reports the car's position and nothing else (`kin.yaw_rate` is `none` in
  every scene and absent from the manifest), so the primitive finds a missing yaw rate inside the
  window and forms no heading change.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: user ↦ 1

/-- Half-length, half-width, half-height of the car. -/
def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- The car's speed over the ground. -/
def carSpeed : Q := Units.metresPerSecond 8

/-- The heading halfway through the quarter turn: the closest rational unit vector at 45 deg. -/
def ne45 : Vec := (Units.ratio 408 577, Units.ratio 408 577)

/-- Yaw rates, in degrees per second: none while the car runs straight, 45 deg/s through the turn. -/
def noYaw : Q := Units.degrees 0
def turnYaw : Q := Units.degrees 45

/-- The first and the last observation the witnesses speak about (milliseconds). -/
def tFirst : Timestamp := 3000
def tLast : Timestamp := 5000

/-- One second between observations, seven of them from 0 s. -/
def dt : Q := Units.seconds 1
def nObs : Nat := 7

/-- The car at a position, with the heading it points and the yaw rate the source reports. -/
def car (pos : Vec) (hdg : Vec) (ω : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos hdg carSpeed carExtent)
    fun k => { k with yawRate := some ω }

/-- A scene of one car and nothing else. -/
def carScene (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] [] []

/-- The instance every scenario speaks about: the window 2 s, the swing 30 deg. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 2) .second),
               ("swing", .lit (Units.degrees 30) .degree)]
    bounds := none }

def instances : List Concept.Instance := [inst]

/-- The turning car, observation by observation: east along the street, then the quarter circle
    about (16 m, 10 m) at 45 deg/s, then north along the other street. -/
def holdsUser : Nat → RoadUser
  | 0 => car (m 0, m 0) Build.east noYaw
  | 1 => car (m 8, m 0) Build.east noYaw
  | 2 => car (m 16, m 0) Build.east noYaw
  | 3 => car (m 23, m 3) ne45 turnYaw
  | 4 => car (m 26, m 10) Build.north turnYaw
  | 5 => car (m 26, m 18) Build.north noYaw
  | _ => car (m 26, m 26) Build.north noYaw

/-- The car running straight east, observation by observation. -/
def straightUser (k : Nat) : RoadUser :=
  car (m (8 * Int.ofNat k), m 0) Build.east noYaw

/-- The same run, of which the source observed the position alone. -/
def sparseStraightUser (k : Nat) : RoadUser :=
  Build.sparseUser 1 [.motorVehicle] (m (8 * Int.ofNat k), m 0)

/-- `holds` (compliant): Over the window behind, the tracked vehicle swings through about a quarter turn to its left while turning from one street into another; the integrated heading change is left-positive and above the caller's swing. -/
def holdsTrace : Trace :=
  Build.trace nObs 0 dt fun k t => carScene t (holdsUser k)

/-- `fails` (violated): The vehicle holds its heading along a straight street for the whole window; the integrated heading change is about zero, below the caller's swing. -/
def failsTrace : Trace :=
  Build.trace nObs 0 dt fun k t => carScene t (straightUser k)

/-- `blind` (unknown): The source tracks the vehicle's position but declares no yaw rate, so the primitive forms no heading change over the window. -/
def blindTrace : Trace :=
  Build.trace nObs 0 dt fun k t => carScene t (sparseStraightUser k)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("user", 1)]
    expected := expected
    window := some (tFirst, tLast) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn
