/-
  Witnesses for drv.motion.rightward_course_change.

  One body, track 1, a car 5 m long and 2 m wide (half-extents 2.5 m, 1 m, 1 m), travelling at
  6 m/s at every instant of every trace. No region and no device is built: the concept reads the
  heading change the primitive integrates from the body's rate of change of heading, and the body's
  speed, and nothing of the place the manoeuvre is made in.

  Each trace is thirteen instants a second apart (t = 0 … 12000 ms). The concept looks back over a
  window of 6 s — the primitive integrates over it and the speed is required at every observation
  of it — so the instants before t = 6000 have a truncated window; every scenario therefore speaks
  about the last instant alone (`window := some (12000, 12000)`), at which the 6 s window behind is
  covered (t = 6000 … 12000) and sampled a second apart, well inside the half-window adequacy
  bound.

  The instance's own figures, each written through a `Units` constructor:
    turn_window 6 s — the time within which a change of course is completed;
    min_course_change 10° — below that a change of course is lane-keeping or a bend taken;
    max_course_change 150° — above that the body has turned about, a reversal of direction;
    motion_speed_tolerance 0.5 m/s — below that a reading counts as no travel.

  The geometry of the two turning traces (`holds`, `blind`): the car runs due east at 6 m/s from
  the origin to (36 m, 0) over the first six seconds, then turns clockwise at 15°/s for the last
  six, following a 22.92 m arc (the radius 6 m/s ÷ 15°/s) through a quarter turn, so that at
  t = 12000 it heads due south from (58.92 m, −22.92 m). Its heading at each instant is the unit
  vector of its course to four decimals, written as a ratio; its positions are given to the
  centimetre. Path length is not observed (the concept does not read it, and no window here is
  measured in path).

    holds — the turning car, its rate of change of heading recorded as −15°/s over each of the last
            six intervals: the signed heading change over the window behind t = 12000 is
            6 × (−15°) = −90°, to the right and between 10° and 150°, while the speed is 6 m/s at
            every observation of that window.
    fails — the same car holding a straight course due east for all thirteen instants, its recorded
            rate of change of heading zero throughout: the signed heading change over the window
            behind t = 12000 is 0°, under a degree and so below the smaller bound, though the body
            travels at 6 m/s throughout.
    blind — the turning car of `holds`, with no rate of change of heading recorded at any instant
            (kin.yaw_rate is masked): the primitive cannot integrate the signed heading change over
            the window behind, so whether a change of course to the right is being made is unknown,
            even though the speed is observed at every observation of the window.
-/
import TrafficSpec.Concepts.motion.rightward_course_change
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.rightward_course_change

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: a 6 s window, a turn read as a change of course
    between 10° and 150° of heading change, and 0.5 m/s below which a reading counts as no
    travel. -/
def inst : Concept.Instance :=
  { name := "drv.motion.rightward_course_change@w"
    concept := "drv.motion.rightward_course_change"
    literals := []
    nats := []
    params :=
      [ ("turn_window", .lit (Units.seconds 6) .second)
      , ("min_course_change", .lit (Units.degrees 10) .degree)
      , ("max_course_change", .lit (Units.degrees 150) .degree)
      , ("motion_speed_tolerance", .lit (Units.micrometresPerSecond 500000) .metrePerSecond) ]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A unit heading written to four decimals, as a ratio of whole numbers. -/
def hdg (x y : Int) : Vec := (Units.ratio x 10000, Units.ratio y 10000)

/-- The car at an instant: 5 m long and 2 m wide, at the given position and heading, travelling at
    6 m/s, with the rate of change of heading the source records (degrees per second; `none` where
    it records none). -/
def car (pos : Vec) (heading : Vec) (yaw : Option Q) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 6) (cm 250, cm 100, cm 100))
    (fun k => { k with yawRate := yaw })

/-- The straight run east at 6 m/s: the position at the kth second. -/
def straightPos (k : Nat) : Vec := (m (6 * Int.ofNat k), Q.zero)

/-- The turning run: due east for the first six seconds, then clockwise at 15°/s along a 22.92 m
    arc through a quarter turn. -/
def turnPos (k : Nat) : Vec :=
  match k with
  | 7 => (cm 4193, cm (-78))
  | 8 => (cm 4746, cm (-307))
  | 9 => (cm 5221, cm (-671))
  | 10 => (cm 5585, cm (-1146))
  | 11 => (cm 5814, cm (-1699))
  | 12 => (cm 5892, cm (-2292))
  | _ => straightPos k

/-- The heading of the turning run: due east, then turned 15° clockwise at each of the last six
    instants, to a quarter turn (due south) at the last. -/
def turnHeading (k : Nat) : Vec :=
  match k with
  | 7 => hdg 9659 (-2588)
  | 8 => hdg 8660 (-5000)
  | 9 => hdg 7071 (-7071)
  | 10 => hdg 5000 (-8660)
  | 11 => hdg 2588 (-9659)
  | 12 => hdg 0 (-10000)
  | _ => Build.east

/-- The rate of change of heading of the turning run: none over the straight stretch, −15°/s (to
    the right) over each of the last six intervals. -/
def turnYaw (k : Nat) : Q :=
  if 7 ≤ k then Units.degrees (-15) else Units.degrees 0

/-- Thirteen instants a second apart, the car as given at each. -/
def runTrace (f : Nat → RoadUser) : Trace :=
  Build.trace 13 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ f k ]
      [ ]  -- structures
      [ ]  -- devices

/-- `holds` (compliant): A vehicle travelling at 6 m/s throughout the window behind turns clockwise through about a quarter turn over that window, a signed heading change to the right between the smaller and the larger bound. -/
def holdsTrace : Trace :=
  runTrace fun k => car (turnPos k) (turnHeading k) (some (turnYaw k))

/-- `fails` (violated): A vehicle travelling at 6 m/s throughout the window behind holds a straight course, its signed heading change over the window being under a degree, below the smaller bound. -/
def failsTrace : Trace :=
  runTrace fun k => car (straightPos k) Build.east (some (Units.degrees 0))

/-- `blind` (unknown): A vehicle travels at 6 m/s but the source declares no rate of change of heading, so the signed heading change over the window behind cannot be taken and whether a course change to the right is being made is unknown. -/
def blindTrace : Trace :=
  runTrace fun k => car (turnPos k) (turnHeading k) none

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    expected := expected
    window := some (12000, 12000) }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.rightward_course_change
