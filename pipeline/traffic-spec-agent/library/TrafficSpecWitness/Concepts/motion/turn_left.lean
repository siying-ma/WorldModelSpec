/-
  Witnesses for drv.motion.turn_left.

  The map is one crossroads, the same in every trace: region 10 the east–west roadway, the
  rectangle from (-80, -8) to (80, 8) metres; region 11 the cross street, the rectangle from
  (-8, -80) to (8, 80); region 12 the junction itself, the rectangle from (-8, -8) to (8, 8).
  No region carries a designated direction and no device stands at the junction: the body reads
  neither.

  Every trace is eleven observations one second apart, from t = 0 to t = 10000 ms. The body is
  track 1, a motor vehicle two metres half-length, one metre half-width and one metre
  half-height, travelling at eight metres per second, and every scene declares its yaw rate — the
  only measurement the body reads, through `prim.heading_change`.

    `holds`  — the vehicle approaches the junction from the west along y = -2 m with a yaw rate of
               zero through t = 4000, then turns left at a constant 22.5 degrees per second over
               the four seconds t = 4000…8000 (its heading swinging east → 22.5° → 45° → 67.5° →
               north, its position following the arc of about twenty metres' radius), and runs on
               due north with a yaw rate of zero again. Over the four-second window the signed
               change is then 90° at t = 8000, 67.5° at t = 9000 and exactly 45° at t = 10000 —
               at or above the threshold at each of the three instants the witness judges, the
               last of them the boundary case of "at or above".
    `fails`  — the same vehicle crosses the junction straight ahead, due east along y = -2 m at
               eight metres per second, its yaw rate zero at every observation: the heading does
               not vary at all, so the signed change over any window is 0°, below the threshold.
    `blind`  — the `holds` trace with `kin.yaw_rate` absent from the manifest: the source declares
               no yaw rate for road users, so the heading change cannot be integrated and the
               comparison is unknown rather than false.

  Each witness judges t = 8000…10000 (the `window`), the instants whose four-second lookback lies
  inside the trace: earlier instants have a truncated window, which is unknown for a reason no
  manifest masks.

  The instance's figures are this witness's own: the recognition window four seconds (the span the
  manoeuvre is carried out in) and the threshold 45 degrees, half the ninety degrees the turning
  vehicle swings through, so that the window reaching only the second half of the manoeuvre still
  recognizes it and the window reaching less than half of it does not.
-/
import TrafficSpec.Concepts.motion.turn_left
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.turn_left

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A yaw rate in degrees per second, written as thousandths of a degree so that 22.5 is exact. -/
def degPerSec (milli : Int) : Q := Units.millidegrees milli

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. -/
def inst : Concept.Instance :=
  { name := "drv.motion.turn_left@w"
    concept := "drv.motion.turn_left"
    literals := []
    nats := []
    params := [("turn_window", .lit (Units.seconds 4) .second),
               ("turn_heading_change", .lit (Units.degrees 45) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The east–west roadway the vehicle arrives on. -/
def ewRoadway : Structure := Build.rect 10 .roadway (m (-80)) (m (-8)) (m 80) (m 8)

/-- The cross street it turns into. -/
def nsRoadway : Structure := Build.rect 11 .roadway (m (-8)) (m (-80)) (m 8) (m 80)

/-- The junction of the two. -/
def junction : Structure := Build.rect 12 .intersection (m (-8)) (m (-8)) (m 8) (m 8)

def crossroads : List Structure := [ewRoadway, nsRoadway, junction]

/-- The vehicle's half-extents: two metres half-length, one metre half-width and half-height. -/
def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- Eight metres per second, the speed of every body below. -/
def speed : Q := Units.metresPerSecond 8

/-- The rate the turning vehicle holds over the four seconds of its manoeuvre: 22.5 degrees per
    second to the left, ninety degrees in four seconds. -/
def turnRate : Q := degPerSec 22500

/-- Headings on the way round: east, 22.5°, 45°, 67.5°, north, each a unit vector to four
    decimal places. -/
def h22 : Vec := (Units.ratio 9239 10000, Units.ratio 3827 10000)
def h45 : Vec := (Units.ratio 7071 10000, Units.ratio 7071 10000)
def h67 : Vec := (Units.ratio 3827 10000, Units.ratio 9239 10000)

/-- The turning vehicle's heading at observation `k`: due east up to t = 4000, swinging through
    the arc over the next four seconds, due north afterwards. -/
def turnHeading (k : Nat) : Vec :=
  match k with
  | 5 => h22
  | 6 => h45
  | 7 => h67
  | 8 => Build.north
  | 9 => Build.north
  | 10 => Build.north
  | _ => Build.east

/-- Its position at observation `k`: eight metres per second along y = -2 m, then the arc of the
    left turn, then eight metres per second due north along x = 0.4 m. -/
def turnPos (k : Nat) : Vec :=
  match k with
  | 0 => (cm (-5200), cm (-200))
  | 1 => (cm (-4400), cm (-200))
  | 2 => (cm (-3600), cm (-200))
  | 3 => (cm (-2800), cm (-200))
  | 4 => (cm (-2000), cm (-200))
  | 5 => (cm (-1219), cm (-45))
  | 6 => (cm (-558), cm 398)
  | 7 => (cm (-115), cm 1059)
  | 8 => (cm 40, cm 1840)
  | 9 => (cm 40, cm 2640)
  | _ => (cm 40, cm 3440)

/-- Its yaw rate at observation `k`: the turn rate over the four intervals of the manoeuvre (the
    rate at a scene is held over the interval before it), zero before and after. -/
def turnYaw (k : Nat) : Q := if 5 ≤ k && k ≤ 8 then turnRate else Q.zero

/-- The turning vehicle at observation `k`. -/
def turningUser (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (turnPos k) (turnHeading k) speed carExtent)
    fun kin => { kin with yawRate := some (turnYaw k) }

/-- The vehicle crossing straight ahead at observation `k`: due east along y = -2 m, yaw rate
    zero. -/
def straightUser (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle]
      (cm (-5200 + 800 * (Int.ofNat k)), cm (-200)) Build.east speed carExtent)
    fun kin => { kin with yawRate := some Q.zero }

/-- `holds` (compliant): A vehicle approaches the cross street and swings through ninety degrees to
    the left within four seconds; at t = 8000 the accumulated change over the window reaches the
    threshold, and it still holds at the two later observations whose window covers the manoeuvre. -/
def holdsTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ turningUser k ] crossroads [ ]

/-- `fails` (violated): The same vehicle crosses the junction straight ahead, its heading not
    varying at all over any window. -/
def failsTrace : Trace :=
  Build.trace 11 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ straightUser k ] crossroads [ ]

/-- `blind` (unknown): The vehicle turns across the junction as in `holds`, but the source declares
    no yaw rate for road users, so the heading change cannot be integrated. -/
def blindTrace : Trace := holdsTrace

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (8000, 10000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.turn_left
