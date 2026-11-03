/-
  Witnesses for drv.motion.rightward_course_change.

  The instance: heading_change_min = 10°, window = 6 s.

  Every trace is sixteen scenes one second apart (t = 0 … 15 000 ms) in a world frame with +x east
  and +y north. Every road user is a motor vehicle 5 m long and 1.8 m wide travelling at 10 m/s, so
  each scene is ten metres along its heading from the one before, and every scene carries the
  vehicle's yaw rate (deg/s, left positive).

  The one-second spacing is half the window's half, so the primitive's window is adequately sampled
  everywhere; the back window of 6 s is covered from t = 6 000 ms on and reaches past the start of
  the trace before that, so each scenario's `window` names the instants it speaks about.

  `holds`: one vehicle (track 1) runs north up a lane and swings into a side road, yawing −10 °/s
  through the four seconds t = 7 … 10 s: 40° to the right. Over the window the accumulated change is
  0° at t = 6 s, then −10, −20, −30, −40, −40, −40, −30, −20, −10 at t = 7 … 15 s, so from t = 7 s on
  it is at or below −10° and the concept holds; the judged window is 7 000 … 15 000 ms, whose last
  instant (−10° exactly) sits on the bound.

  `fails`: track 1 holds a straight course up the same lane, yawing one degree a second now to the
  left and now to the right in a four-second cycle, so the accumulated change over the window is
  never more than 2° to either hand; track 2, on a lane thirty metres east, turns 40° to the LEFT
  over the same four seconds (+10 °/s), accumulating +40°. Neither is at or below −10°. The scenario
  judges track 1, the formal's grounding, over 6 000 … 15 000 ms, where the body is false at every
  instant.

  `blind`: the `holds` trace under a manifest that declares kin.yaw_rate absent, so the heading
  change cannot be integrated and the concept is unknown at every instant of 6 000 … 15 000 ms —
  for the masked atom alone, the window being covered there.
-/
import TrafficSpec.Concepts.motion.rightward_course_change
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.rightward_course_change

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A unit heading from its components in ten-thousandths. Every heading written below has a norm
    just under one, so the ten metres a vehicle travels between two scenes is never shorter than
    the straight line between the two positions it stands at. -/
def dir (x y : Int) : Vec := (Units.ratio x 10000, Units.ratio y 10000)

/-- The position after `k` one-second steps of ten metres along the headings of `h`, from `start`. -/
def path (start : Vec) (h : Nat → Vec) : Nat → Vec
  | 0 => start
  | k + 1 =>
    let p := path start h k
    let d := h (k + 1)
    (Q.add p.1 (Q.mul d.1 (m 10)), Q.add p.2 (Q.mul d.2 (m 10)))

/-- A vehicle of the witness: a motor vehicle 5 m by 1.8 m at ten metres a second, with the yaw
    rate (deg/s, left positive) and the path length its source observes. -/
def car (track : TrackId) (pos : Vec) (heading : Vec) (yaw : Q) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user track [.motorVehicle] pos heading (Units.metresPerSecond 10)
      (cm 250, cm 90, cm 75) (some (m (10 * Int.ofNat k))))
    fun kin => { kin with yawRate := some yaw }

/-- The lane track 1 approaches on: four metres wide, north-bound, ending where the side road
    leaves it. -/
def throughLane : Structure :=
  Build.lane 10 [(m (-2), m (-20)), (m 2, m (-20)), (m 2, m 70), (m (-2), m 70)] Build.north

/-- The side road: a corridor leaving the through lane at forty degrees east of north. -/
def sideRoad : Structure :=
  Build.lane 11
    [(cm 230, cm 6007), (cm 5100, cm 13197), (cm 4640, cm 13583), (cm (-230), cm 6393)]
    (dir 6428 7660)

/-- The lane track 2 runs on in `fails`, thirty metres east of the through lane. -/
def otherLane : Structure :=
  Build.lane 12 [(m 28, m (-20)), (m 32, m (-20)), (m 32, m 70), (m 28, m 70)] Build.north

/-- The right-turning vehicle's heading: north for the first six seconds, then ten degrees further
    to the right each second of the turn, and forty degrees east of north after it. -/
def rightHeading (k : Nat) : Vec :=
  if k ≤ 6 then dir 0 10000
  else if k = 7 then dir 1736 9848
  else if k = 8 then dir 3420 9396
  else if k = 9 then dir 5000 8660
  else dir 6428 7660

/-- Its yaw rate: ten degrees a second to the right — negative, the sign being left-positive —
    through the four seconds of the turn, zero elsewhere. -/
def rightYaw (k : Nat) : Q :=
  if 7 ≤ k && k ≤ 10 then Units.degrees (-10) else Q.zero

/-- The left-turning vehicle's heading, the mirror of `rightHeading`. -/
def leftHeading (k : Nat) : Vec :=
  if k ≤ 6 then dir 0 10000
  else if k = 7 then dir (-1736) 9848
  else if k = 8 then dir (-3420) 9396
  else if k = 9 then dir (-5000) 8660
  else dir (-6428) 7660

/-- Its yaw rate: ten degrees a second to the left, positive. -/
def leftYaw (k : Nat) : Q :=
  if 7 ≤ k && k ≤ 10 then Units.degrees 10 else Q.zero

/-- The straight-running vehicle's heading: a degree to the left, north, a degree to the right,
    north, in a four-second cycle. -/
def wobbleHeading (k : Nat) : Vec :=
  match k % 4 with
  | 1 => dir (-175) 9998
  | 3 => dir 175 9998
  | _ => dir 0 10000

/-- Its yaw rate: a degree a second, now to one hand and now to the other, the heading above being
    its integral. -/
def wobbleYaw (k : Nat) : Q :=
  match k % 4 with
  | 2 => Units.degrees (-1)
  | 3 => Units.degrees (-1)
  | _ => Units.degrees 1

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: ten degrees of accumulated change over a window of
    six seconds, the bound of a caller that recognizes a departure from a direct course. -/
def inst : Concept.Instance :=
  { name := "drv.motion.rightward_course_change@w"
    concept := "drv.motion.rightward_course_change"
    literals := []
    nats := []
    params := [("heading_change_min", .lit (Units.degrees 10) .degree),
               ("window", .lit (Units.seconds 6) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- `holds` (compliant): A vehicle travelling straight swings to the right into a side road; over the six seconds behind the observation its integrated yaw rate amounts to about forty degrees to the right, below the left-positive zero by more than the caller's bound of ten degrees, so the concept holds at that observation and at the later observations of the window over which the accumulated change still reaches the bound. -/
def holdsTrace : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (path (Q.zero, Q.zero) rightHeading k) (rightHeading k) (rightYaw k) k ]
      [ throughLane, sideRoad ]
      [ ]

/-- `fails` (violated): A vehicle holds a straight course along a lane, its integrated yaw rate over the window amounting to about two degrees, now to one hand and now to the other; and a second vehicle turns forty degrees to the left in the same window. In neither case is the accumulated change at or below the negative of the bound, so the concept does not hold. -/
def failsTrace : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (path (Q.zero, Q.zero) wobbleHeading k) (wobbleHeading k) (wobbleYaw k) k
      , car 2 (path (m 30, Q.zero) leftHeading k) (leftHeading k) (leftYaw k) k ]
      [ throughLane, otherLane ]
      [ ]

/-- `blind` (unknown): A vehicle turns to the right on a source whose capability manifest declares kin.yaw_rate absent, so the heading change over the window cannot be integrated and the concept is unknown. -/
def blindTrace : Trace :=
  Build.trace 16 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car 1 (path (Q.zero, Q.zero) rightHeading k) (rightHeading k) (rightYaw k) k ]
      [ throughLane, sideRoad ]
      [ ]

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
  [ { (witness "holds" holdsTrace .compliant) with window := some (7000, 15000) }
  , { (witness "fails" failsTrace .violated) with window := some (6000, 15000) }
  , { (witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"]) with
        window := some (6000, 15000) } ]

end TrafficSpecWitness.Concepts.motion.rightward_course_change
