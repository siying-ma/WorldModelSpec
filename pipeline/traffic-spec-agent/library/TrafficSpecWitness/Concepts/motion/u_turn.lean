/-
  Witnesses for drv.motion.u_turn.

  One road user, track 1, a bicycle (half-extents 90 cm × 30 cm × 60 cm); no region, no device.
  Every trace has 36 observations one second apart, t = 0 … 35 s. The instance's figures are this
  file's own: window 20 s, u_turn_min 150 deg, yaw_tol 2 deg/s.

  - Instants 0 … 20 s: the bicycle rides east along y = 0 at 3 m/s, yaw rate 0, reaching (0, 0) at
    20 s. They also cover the 20 s window behind every later instant (at 20 s the oldest
    observation is exactly 20 s behind).
  - `holds`: first movement 21 … 23 s, yaw rate +30 deg/s (left), on a circle of radius 5.70 m about
    (0, 5.70 m): 90 deg, ending at (5.70 m, 5.70 m) heading north. Halt 24 … 26 s: speed 0, yaw rate
    0. Second movement 27 … 29 s, +30 deg/s: another 90 deg, ending at (0, 11.40 m) heading west.
    From 30 s it rides west at 3 m/s, yaw rate 0. The integrated change over the window behind is
    90 deg from 23 to 26 s and 180 deg from 29 s on (it stays in [150, 210] up to 41 s, beyond the
    trace). At 29 s the yaw rate is still 30 deg/s; at 30 s it is 0: the condition rises there, and
    the concept holds at 30 s, the scenario's window.
  - `fails`: the first movement only (90 deg left by 23 s), then north at 3 m/s with yaw rate 0. The
    change over the window behind never exceeds 90 deg: the concept does not hold anywhere in the
    window 20 … 35 s.
  - `blind`: the `holds` trace with the yaw rate unobserved during the reversal (21 … 29 s) and
    `kin.yaw_rate` masked: at 30 s the heading change, and so the concept, is unknown.

  Headings during the turn are rational approximations of unit vectors (0.87 ≈ cos 30 deg); the
  body reads only the yaw rate.
-/
import TrafficSpec.Concepts.motion.u_turn
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.u_turn

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about. -/
def inst : Concept.Instance :=
  { name := "drv.motion.u_turn@w"
    concept := "drv.motion.u_turn"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 20) .second),
               ("u_turn_min", .lit (Units.degrees 150) .degree),
               ("yaw_tol", .lit (Units.degrees 2) .degreePerSecond)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

def halfExt : Q × Q × Q := (cm 90, cm 30, cm 60)
def rideSpeed : Q := Units.metresPerSecond 3
def turnRate : Q := Units.degrees 30   -- deg/s over one-second steps

/-- Rational approximations of the unit headings at 30 deg steps counter-clockwise from east. -/
def h30 : Vec := (Units.ratio 87 100, Units.ratio 1 2)
def h60 : Vec := (Units.ratio 1 2, Units.ratio 87 100)
def h120 : Vec := (Units.ratio (-1) 2, Units.ratio 87 100)
def h150 : Vec := (Units.ratio (-87) 100, Units.ratio 1 2)

/-- The bicycle with its position, heading, speed and yaw rate (`none`: unobserved). -/
def bike (pos : Vec) (h : Vec) (v : Q) (yaw : Option Q) : RoadUser :=
  Build.withKin (Build.user 1 [.bicycle] pos h v halfExt) fun k => { k with yawRate := yaw }

/-- Riding east along y = 0, reaching (0, 0) at k = 20. -/
def approach (k : Nat) : RoadUser :=
  bike (Q.mul rideSpeed (Q.sub (Q.ofInt (Int.ofNat k)) (Q.ofInt 20)), Q.zero) Build.east rideSpeed (some Q.zero)

/-- The reversal in two movements with a halt between them; `yaw` is the yaw rate while turning. -/
def reversal (k : Nat) (yaw : Option Q) : RoadUser :=
  if k ≤ 20 then approach k
  else if k = 21 then bike (cm 285, cm 76) h30 rideSpeed yaw
  else if k = 22 then bike (cm 494, cm 285) h60 rideSpeed yaw
  else if k = 23 then bike (cm 570, cm 570) Build.north rideSpeed yaw
  else if k ≤ 26 then bike (cm 570, cm 570) Build.north Q.zero (if yaw.isSome then some Q.zero else none)
  else if k = 27 then bike (cm 494, cm 855) h120 rideSpeed yaw
  else if k = 28 then bike (cm 285, cm 1064) h150 rideSpeed yaw
  else if k = 29 then bike (Q.zero, cm 1140) Build.west rideSpeed yaw
  else bike (Q.neg (Q.mul rideSpeed (Q.sub (Q.ofInt (Int.ofNat k)) (Q.ofInt 29))), cm 1140) Build.west rideSpeed (some Q.zero)

/-- `holds` (compliant): A bicycle reverses its heading by 180 degrees in two movements with a halt between them, within the window, then its yaw rate falls below yaw_tol; at that observation the concept holds. -/
def holdsTrace : Trace :=
  Build.trace 36 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reversal k (some turnRate)] [] []

/-- `fails` (violated): A bicycle turns 90 degrees to the left; the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 36 0 (Units.seconds 1) fun k t =>
    let u :=
      if k ≤ 23 then reversal k (some turnRate)
      else bike (cm 570, Q.add (cm 570) (Q.mul rideSpeed (Q.sub (Q.ofInt (Int.ofNat k)) (Q.ofInt 23))))
             Build.north rideSpeed (some Q.zero)
    Build.scene t (some 1) [u] [] []

/-- `blind` (unknown): The source does not observe the bicycle's yaw rate during its reversal. -/
def blindTrace : Trace :=
  Build.trace 36 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [reversal k none] [] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    expected := expected
    window := window }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant [] (some (30000, 30000))
  , witness "fails" failsTrace .violated [] (some (20000, 35000))
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] (some (30000, 30000)) ]

end TrafficSpecWitness.Concepts.motion.u_turn
