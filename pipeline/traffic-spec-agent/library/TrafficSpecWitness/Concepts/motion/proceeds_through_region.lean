/-
  Witnesses for drv.motion.proceeds_through_region.

  The instance fills `window` with 4 seconds and `max_heading_change` with 15 degrees. Four seconds
  is longer than the 1.8 s a body at 9 m/s spends inside the 16 m junction region below, so the
  window behind the observation at which the body clears the junction covers the whole passage;
  15 degrees is well above the yaw a body puts into such a window while holding its course across a
  junction and well below the quarter circle of a turn out of it.

  Every trace runs 25 observations at 2 Hz (0.5 s apart, so no 4-second window is sparsely
  sampled), and every witness is judged at the single instant t = 8.0 s (k = 16), whose 4-second
  window behind runs from t = 4.0 s (k = 8) and therefore lies inside the trace: the primitive
  looks back, and the first observations of any finite trace have a truncated window. One instant
  is the right window because the concept is the leaving and not a state: the rise of the end of
  the overlap is true at exactly one observation of a passage.

  The junction region (id 100) is the square x, y ∈ [−8, 8] m in both narratives; the car is
  4.5 m × 1.8 m (half-length 2.25 m, half-width 0.9 m) and runs at 9 m/s, so 4.5 m an observation.
  Both narratives place the car at y = 7 m at k = 15 and 4.5 m further on at k = 16, which clears
  the region by the footprint (the body's near end is more than a metre past the boundary) and by
  the reference point alike, so the observation at which the overlap ceases is k = 16 however the
  occupancy of the footprint is derived; at k = 11 the body is wholly south of the region and at
  k = 12 … 15 it overlaps it.

  `holdsTrace` — a car (track 1) runs north up the south leg (region 11, x ∈ [−2, 2] m,
  y ∈ [−70, −8] m) at 9 m/s, enters the junction at k = 12 (y = −6.5 m), and leaves it on the north
  leg (region 12, y ∈ [8, 70] m), clearing the region at k = 16 (y = 11.5 m). Its yaw rate is zero
  throughout but for k = 13, where it yaws 6 deg/s to the left over the half second before, carrying
  its heading 3 degrees west of north and holding it there. The integrated change over the window
  behind k = 16 is therefore 3 degrees: a magnitude of 3, at or below 15, so the course across the
  junction was held.

  `failsTrace` — a car enters the same junction from the same south leg and leaves it on the east
  leg (region 13, x ∈ [8, 70] m, y ∈ [1, 5] m): from k = 13 to k = 15 it yaws at −58 deg/s, three
  observations that carry its heading 29 degrees further right each (29, 58 and 87 degrees right of
  north), along an arc through the junction, and clears the region at k = 16 at (11.5, 3.0) m
  running east. The integrated change over the window behind k = 16 is −87 degrees, a magnitude of
  87 and above 15, so the body turned out of the region rather than crossing it and the body is
  false at the instant judged.

  `blindTrace` is the crossing trace, judged with rel.occupies masked: the occupancy of the
  footprint is unobserved, so whether the overlap ceased at this observation cannot be told and the
  rise is unknown, while the heading-change comparison is true — the conjunction is unknown.
-/
import TrafficSpec.Concepts.motion.proceeds_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.proceeds_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
/-- Millimetres, the precision the positions and the heading components are written to. -/
def mm (n : Int) : Q := Units.millimetres n
/-- A position in millimetres, world frame (+x east, +y north). -/
def pos (x y : Int) : Vec := (mm x, mm y)
/-- A heading, its components in thousandths: `hdg 485 875` is 29 degrees right of north. -/
def hdg (x y : Int) : Vec := (mm x, mm y)
/-- A yaw rate, degrees per second, left positive. -/
def dps (n : Int) : Q := Units.degrees n
/-- The car: 4.5 m long, 1.8 m wide, 1.5 m tall. -/
def carExtent : Q × Q × Q := (cm 225, cm 90, cm 75)
/-- Nine metres a second, the speed of both narratives: 4.5 m an observation. -/
def speed : Q := Units.metresPerSecond 9

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: r ↦ 100  (the junction region of every trace)

/-- The instance every scenario speaks about: a 4-second window and a 15-degree bound. -/
def inst : Concept.Instance :=
  { name := "drv.motion.proceeds_through_region@w"
    concept := "drv.motion.proceeds_through_region"
    literals := []
    nats := []
    params := [("window", .lit (Units.seconds 4) .second),
               ("max_heading_change", .lit (Units.degrees 15) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

-- ---------------------------------------------------------------------------------------------
-- The junction and its legs
-- ---------------------------------------------------------------------------------------------
/-- The junction the car passes through: the region formal `r`. -/
def junction : Structure := Build.rect 100 .intersection (m (-8)) (m (-8)) (m 8) (m 8)
/-- The northbound lane of the south leg, by which the car enters. -/
def southLeg : Structure :=
  Build.lane 11 [(m (-2), m (-70)), (m 2, m (-70)), (m 2, m (-8)), (m (-2), m (-8))] Build.north
/-- The northbound lane of the north leg, by which the crossing car leaves. -/
def northLeg : Structure :=
  Build.lane 12 [(m (-2), m 8), (m 2, m 8), (m 2, m 70), (m (-2), m 70)] Build.north
/-- The eastbound lane of the east leg, by which the turning car leaves. -/
def eastLeg : Structure :=
  Build.lane 13 [(m 8, m 1), (m 70, m 1), (m 70, m 5), (m 8, m 5)] Build.east

-- ---------------------------------------------------------------------------------------------
-- The crossing narrative
-- ---------------------------------------------------------------------------------------------
/-- Due north at 4.5 m an observation: y = −60.5 m at k = 0, −6.5 m at k = 12 (inside the
    junction), 7 m at k = 15 and 11.5 m at k = 16 (clear of it). -/
def crossPos (k : Nat) : Vec := pos 0 (4500 * (k : Int) - 60500)

/-- North, then 3 degrees west of north from k = 13 on. -/
def crossHeading (k : Nat) : Vec := if k ≤ 12 then hdg 0 1000 else hdg (-52) 999

/-- Zero but for k = 13, where the car yaws 6 deg/s to the left over the half second before it:
    3 degrees, the whole heading change of the passage. -/
def crossYaw (k : Nat) : Q := if k == 13 then dps 6 else Q.zero

/-- `holds` (compliant): A car crosses the junction from the south leg to the north leg at 9 m/s;
    at the observation at which its footprint clears the junction the integrated heading change
    over the window behind is 3 degrees. -/
def holdsTrace : Trace :=
  Build.trace 25 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (Build.user 1 [.motorVehicle] (crossPos k) (crossHeading k) speed carExtent)
          fun kin => { kin with yawRate := some (crossYaw k) } ]
      [ junction, southLeg, northLeg ]
      []

-- ---------------------------------------------------------------------------------------------
-- The turning narrative
-- ---------------------------------------------------------------------------------------------
/-- North up the south leg to k = 12, then the arc through the junction, then east along the east
    leg from k = 16, where the body is clear of the junction. -/
def turnPos (k : Nat) : Vec :=
  if k ≤ 12 then pos 0 (4500 * (k : Int) - 60500)
  else if k == 13 then pos 500 (-2100)
  else if k == 14 then pos 3000 1600
  else if k == 15 then pos 7000 2800
  else pos (11500 + 4500 * ((k : Int) - 16)) 3000

/-- North, then 29, 58 and 87 degrees right of north at the three turning observations, then held. -/
def turnHeading (k : Nat) : Vec :=
  if k ≤ 12 then hdg 0 1000
  else if k == 13 then hdg 485 875
  else if k == 14 then hdg 848 530
  else hdg 999 52

/-- Zero but for the three turning observations, where the car yaws to the right at 58 deg/s:
    −87 degrees over the window behind the observation judged. -/
def turnYaw (k : Nat) : Q := if 13 ≤ k && k ≤ 15 then dps (-58) else Q.zero

/-- `fails` (violated): A car enters the same junction from the south leg and leaves it on the east
    leg; at the observation at which it clears the junction the integrated heading change over the
    window behind is 87 degrees to the right, above the bound, so it turned out of the region. -/
def failsTrace : Trace :=
  Build.trace 25 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (Build.user 1 [.motorVehicle] (turnPos k) (turnHeading k) speed carExtent)
          fun kin => { kin with yawRate := some (turnYaw k) } ]
      [ junction, southLeg, eastLeg ]
      []

/-- `blind` (unknown): A car crosses the junction, but the trace carries no footprint occupancy for
    the junction region, so whether the overlap ceased at this observation cannot be told. -/
def blindTrace : Trace := holdsTrace

/-- The instant every witness is judged at: its 4-second window behind lies inside the trace, and
    it is the observation at which the footprint clears the junction. -/
def judged : Timestamp × Timestamp := (8000, 8000)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("u", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some judged }

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"] ]

end TrafficSpecWitness.Concepts.motion.proceeds_through_region
