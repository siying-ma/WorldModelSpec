/-
  Witnesses for drv.motion.left_turn_through_region.

  Geometry (every figure the witness's own): region r = 100, an intersection, the axis-aligned square
  (0,0)–(20,20) m. Road user a = track 1, a motor vehicle (half extents 2 × 1 × 1 m), observed every
  1 s for six scenes, t = 0 … 5000 ms. Occupancy is derived from geometry (position inside the polygon).

    k=0  t=0     (-6,10)  outside r, heading east              (the observation before the entry)
    k=1  t=1000  ( 2,10)  inside r: the entry
    k=2  t=2000  ( 8,12)  inside r
    k=3  t=3000  (10,18)  inside r
    k=4  t=4000  (10,26)  outside r: the exit — the judged observation (window 4000–4000)
    k=5  t=5000  (10,32)  outside r

  holds: yaw rate +30 deg/s at k=1…4 (0 elsewhere): the heading change from the entry (k=1) to the
         exit (k=4) is 3 intervals × 30 = +90 deg, whatever the integration rule; a leaves heading north.
  fails: the mirror image, yaw rate −30 deg/s, a leaves heading south (y decreasing): −90 deg < turn_min.
  blind: as holds, with no yaw rate supplied (kin.yaw_rate masked): unknown at the exit.

  Instance: step = 1 s (the sampling interval), turn_min = 45 deg, u_turn_min = 135 deg.
-/
import TrafficSpec.Concepts.motion.left_turn_through_region
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.left_turn_through_region

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: a ↦ 1
-- Formals ↦ regions: r ↦ 100  (the intersection square, a structure of every trace)

def inst : Concept.Instance :=
  { name := "drv.motion.left_turn_through_region@w"
    concept := "drv.motion.left_turn_through_region"
    literals := []
    nats := []
    params := [("step", .lit (Units.seconds 1) .second),
               ("turn_min", .lit (Units.degrees 45) .degree),
               ("u_turn_min", .lit (Units.degrees 135) .degree)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The intersection region r. -/
def regionR : Structure := Build.rect 100 .intersection (m 0) (m 0) (m 20) (m 20)

/-- Positions of a; `sgn` = 1 for the left turn (leaves northward), −1 for the right turn
    (leaves southward). -/
def posOf (sgn : Int) (k : Nat) : Vec :=
  match k with
  | 0 => (m (-6), m 10)
  | 1 => (m 2, m 10)
  | 2 => (m 8, m (10 + sgn * 2))
  | 3 => (m 10, m (10 + sgn * 8))
  | 4 => (m 10, m (10 + sgn * 16))
  | _ => (m 10, m (10 + sgn * 22))

def headingOf (sgn : Int) (k : Nat) : Vec :=
  if k ≤ 2 then Build.east else if sgn > 0 then Build.north else Build.south

/-- Yaw rate of a: `sgn`·30 deg/s from the entry (k=1) through the exit (k=4), 0 otherwise;
    `none` where the source supplies none. -/
def yawOf (sgn : Int) (observed : Bool) (k : Nat) : Option Q :=
  if !observed then none
  else if 1 ≤ k ∧ k ≤ 4 then some (Units.degrees (sgn * 30)) else some (Units.degrees 0)

def userA (sgn : Int) (observed : Bool) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (posOf sgn k) (headingOf sgn k) (Units.metresPerSecond 6)
      (m 2, m 1, m 1))
    (fun kn => { kn with yawRate := yawOf sgn observed k })

def passage (sgn : Int) (observed : Bool) : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [userA sgn observed k] [regionR] []

/-- `holds` (compliant): Region r is an intersection region. Road user a enters r heading east, its yaw rate observed at every scene at the sampling standard, turns a quarter turn to the left and leaves r heading north; at the exit observation its heading change since the entry lies in the band, so the concept holds there. -/
def holdsTrace : Trace := passage 1 true

/-- `fails` (violated): Same region; a enters r heading east, turns a quarter turn to the right and leaves r heading south: the heading change since the entry is negative, below turn_min, so the concept does not hold at the exit. -/
def failsTrace : Trace := passage (-1) true

/-- `blind` (unknown): As in holds, but the source supplies no yaw rate for a: the heading change since the entry cannot be integrated and the concept is unknown at the exit. -/
def blindTrace : Trace := passage 1 false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := inst.name
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("a", 1)]
    regions := [("r", 100)]
    expected := expected
    window := some (4000, 4000) }   -- the exit observation

def scenarios : List Scenario :=
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["kin.yaw_rate"] ]

end TrafficSpecWitness.Concepts.motion.left_turn_through_region
