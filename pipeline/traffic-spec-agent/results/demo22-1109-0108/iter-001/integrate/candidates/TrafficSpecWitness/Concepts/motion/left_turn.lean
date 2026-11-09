/-
  Witnesses for drv.motion.left_turn.

  The geometry: one car (track 1, a motor vehicle, 10 m/s, half-extents 2 m long, 0.9 m wide,
  0.75 m high) on an open plane — no region and no device, because the concept states the turning
  of the body only. Ten observations half a second apart, t = 0 … 4500 ms. The rate of change of
  heading at an observation is held over the interval before it, so each heading below is the
  previous one turned by that rate over half a second; the positions advance 5 m an observation
  along the heading. The concept reads neither position nor heading, only `kin.yaw_rate`.

  The instance's figures: heading step 500 ms (the spacing of the observations, so every interval
  the integration crosses is within the bound), onset yaw rate 5 deg/s, turn angle 45 deg.

  `holds` (compliant): the car runs east with no yaw at t = 0 and 500; at t = 1000 its yaw rate
  rises to 30 deg/s and stays there through t = 2500, so the heading change accumulated since that
  onset is 15 deg at t = 1500, 30 deg at t = 2000 and 45 deg at t = 2500 — the turn angle, a
  second and a half after the onset, the heading having come round from east to 60 deg. The yaw
  rate then returns to zero and the accumulated change stays at 45 deg to the end of the trace.
  The window is t = 2500 … 4500, the observations the narrative speaks about: the angle first
  reached and still held. Before 2500 the concept is unknown (no onset yet, at t = 0 and 500) and
  then false (the angle not yet reached), which is what the contract says of those observations.

  `fails` (violated): the same car changes lane to the left. Its yaw rate rises to 12 deg/s at
  t = 1000 and holds it through t = 2000, then goes to −12 deg/s from t = 2500 to t = 3500 as the
  car straightens: the change accumulated since the onset at t = 1000 peaks at 12 deg and is back
  to zero at t = 3000, so the turn angle is never reached and the concept is false at every
  observation from the onset on.

  `blind` (unknown): the car is already yawing left at 30 deg/s at the first observation of the
  recording, and the manifest masks `kin.yaw_rate`. No onset is observed with the rate of change
  of heading known at every observation since, so the accumulated change cannot be counted and the
  concept is unknown — for the masked atom — at every observation, never false.
-/
import TrafficSpec.Concepts.motion.left_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- A rate of change of heading, in degrees per second (left positive). -/
def degPerSec (n : Int) : Q := Units.degrees n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: every parameter given a value through a `Units`
    constructor. -/
def inst : Concept.Instance :=
  { name := "drv.motion.left_turn@w"
    concept := "drv.motion.left_turn"
    literals := []
    nats := []
    params := [("heading_step", .lit (Units.milliseconds 500) .second),
               ("onset_yaw_rate", .lit (Units.degrees 5) .degreePerSecond),
               ("turn_angle", .lit (Units.degrees 45) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- What every trace below is built from
-- ---------------------------------------------------------------------------------------------
/-- Half a second between consecutive observations: the heading step of the instance. -/
def step : Q := Units.milliseconds 500
def speed : Q := Units.metresPerSecond 10
def halfExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- Unit headings, counter-clockwise from east. -/
def h6 : Vec := (Units.ratio 995 1000, Units.ratio 105 1000)
def h12 : Vec := (Units.ratio 978 1000, Units.ratio 208 1000)
def h15 : Vec := (Units.ratio 966 1000, Units.ratio 259 1000)
def h18 : Vec := (Units.ratio 951 1000, Units.ratio 309 1000)
def h30 : Vec := (Units.ratio 866 1000, Units.ratio 500 1000)
def h45 : Vec := (Units.ratio 707 1000, Units.ratio 707 1000)
def h60 : Vec := (Units.ratio 500 1000, Units.ratio 866 1000)
def h75 : Vec := (Units.ratio 259 1000, Units.ratio 966 1000)
def h105 : Vec := (Units.ratio (-259) 1000, Units.ratio 966 1000)
def h120 : Vec := (Units.ratio (-500) 1000, Units.ratio 866 1000)
def h135 : Vec := (Units.ratio (-707) 1000, Units.ratio 707 1000)
def h150 : Vec := (Units.ratio (-866) 1000, Units.ratio 500 1000)
def h165 : Vec := (Units.ratio (-966) 1000, Units.ratio 259 1000)

/-- The car: its position, heading and speed, with the rate of change of heading observed. -/
def car (pos hdg : Vec) (yaw : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] pos hdg speed halfExtent)
    fun k => { k with yawRate := some yaw }

/-- A scene with the car alone: no region, no device. -/
def plainScene (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] [] []

-- ---------------------------------------------------------------------------------------------
-- `holds`: the onset at t = 1000, the turn angle reached at t = 2500 and held to the end
-- ---------------------------------------------------------------------------------------------
def holdsYaw : Nat → Q
  | 2 | 3 | 4 | 5 => degPerSec 30
  | _ => Q.zero

def holdsHdg : Nat → Vec
  | 0 | 1 => Build.east
  | 2 => h15
  | 3 => h30
  | 4 => h45
  | _ => h60

def holdsPos : Nat → Vec
  | 0 => (m 0, m 0)
  | 1 => (m 5, m 0)
  | 2 => (cm 996, cm 65)
  | 3 => (cm 1458, cm 256)
  | 4 => (cm 1855, cm 560)
  | 5 => (cm 2159, cm 957)
  | 6 => (cm 2409, cm 1390)
  | 7 => (cm 2659, cm 1823)
  | 8 => (cm 2909, cm 2256)
  | _ => (cm 3159, cm 2689)

def holdsTrace : Trace :=
  Build.trace 10 0 step fun k t => plainScene t (car (holdsPos k) (holdsHdg k) (holdsYaw k))

-- ---------------------------------------------------------------------------------------------
-- `fails`: a lane change to the left — an onset at t = 1000, 12 deg accumulated at most
-- ---------------------------------------------------------------------------------------------
def failsYaw : Nat → Q
  | 2 | 3 | 4 => degPerSec 12
  | 5 | 6 | 7 => degPerSec (-12)
  | _ => Q.zero

def failsHdg : Nat → Vec
  | 0 | 1 => Build.east
  | 2 => h6
  | 3 => h12
  | 4 => h18
  | 5 => h12
  | 6 => h6
  | _ => Build.east

def failsPos : Nat → Vec
  | 0 => (m 0, m 0)
  | 1 => (m 5, m 0)
  | 2 => (cm 998, cm 26)
  | 3 => (cm 1495, cm 105)
  | 4 => (cm 1986, cm 236)
  | 5 => (cm 2478, cm 366)
  | 6 => (cm 2973, cm 446)
  | 7 => (cm 3471, cm 472)
  | 8 => (cm 3971, cm 472)
  | _ => (cm 4471, cm 472)

def failsTrace : Trace :=
  Build.trace 10 0 step fun k t => plainScene t (car (failsPos k) (failsHdg k) (failsYaw k))

-- ---------------------------------------------------------------------------------------------
-- `blind`: already turning at the first observation, with the rate of change of heading masked
-- ---------------------------------------------------------------------------------------------
def blindHdg : Nat → Vec
  | 0 => h45
  | 1 => h60
  | 2 => h75
  | 3 => Build.north
  | 4 => h105
  | 5 => h120
  | 6 => h135
  | 7 => h150
  | 8 => h165
  | _ => Build.west

def blindPos : Nat → Vec
  | 0 => (m 0, m 0)
  | 1 => (cm 304, cm 397)
  | 2 => (cm 495, cm 859)
  | 3 => (cm 560, cm 1355)
  | 4 => (cm 495, cm 1851)
  | 5 => (cm 304, cm 2313)
  | 6 => (cm 0, cm 2710)
  | 7 => (cm (-397), cm 3014)
  | 8 => (cm (-859), cm 3205)
  | _ => (cm (-1355), cm 3270)

def blindTrace : Trace :=
  Build.trace 10 0 step fun k t => plainScene t (car (blindPos k) (blindHdg k) (degPerSec 30))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (2500, 4500))
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn
