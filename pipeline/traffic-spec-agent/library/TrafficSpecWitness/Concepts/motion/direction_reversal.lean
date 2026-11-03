/-
  Witnesses for drv.motion.direction_reversal.

  The instance. `heading_change_min` is 150 degrees — a bound near a half turn, set below 180 as
  the parameter's meaning asks; `window` is 9 seconds, the length of the window behind over which
  the heading change is accumulated. Both figures are this witness's own.

  The geometry. One car (track 1, a motor vehicle, half-extents 2 m × 1 m × 0.75 m) at 5 m/s, on
  a trace of 21 observations one second apart, t = 0 … 20000 ms. In every scenario it runs east
  along y = 0 with no yaw for the first six observations, turns over the next nine, and runs
  straight afterwards; the headings are written as thousandths of a unit vector and turn by exactly
  the angle the yaw rate integrates to over each second, so the heading and the yaw rate tell the
  same story.

  - `holds`: the yaw rate is +19 deg/s at the observations k = 6 … 14 (left, so positive), the
    heading turning 0° → 19° → … → 171°. At t = 14000 the window behind of 9 s carries
    19 × 9 = 171 degrees of heading change, at or above the 150-degree bound, and the car heads
    the way it came from.
  - `fails`: the yaw rate is −10 deg/s at k = 6 … 13 and −9 deg/s at k = 14 (right, so negative),
    the heading turning 0° → −10° → … → −89°. At t = 14000 the window carries −89 degrees, of
    magnitude 89: an ordinary corner, below the reversal bound.
  - `blind`: the reversal of `holds`, with `kin.yaw_rate` masked, so the heading change cannot be
    integrated and the primitive is unknown for the absent atom.

  Each scenario is judged at t = 14000, the observation its narrative speaks about: the window
  behind it is covered (nine seconds of observations precede it) and sampled one second apart, so
  the primitive is truncated nowhere in the judged window and the masked yaw rate alone leaves
  `blind` unknown.
-/
import TrafficSpec.Concepts.motion.direction_reversal
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.motion.direction_reversal

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

/-- A heading, as thousandths of a unit vector (a direction, not a length). -/
def dir (x y : Int) : Vec := (Units.millimetres x, Units.millimetres y)
/-- A yaw rate in degrees per second, left positive. -/
def dps (n : Int) : Q := Units.degrees n

-- Formals ↦ tracks: u ↦ 1
-- Formals ↦ regions: (no region formal)

/-- The instance every scenario speaks about: the bound near a half turn and the window behind,
    each a figure of this witness. -/
def inst : Concept.Instance :=
  { name := "drv.motion.direction_reversal@w"
    concept := "drv.motion.direction_reversal"
    literals := []
    nats := []
    params := [("heading_change_min", .lit (Units.degrees 150) .degree),
               ("window", .lit (Units.seconds 9) .second)]
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- The car at observation `k`: its position, heading and yaw rate from the scenario's lists. -/
def car (poss : List Vec) (hds : List Vec) (yaws : List Q) (k : Nat) : RoadUser :=
  Build.withKin
    (Build.user 1 [.motorVehicle] (poss.getD k (m 0, m 0)) (hds.getD k (dir 1000 0))
      (Units.metresPerSecond 5) (m 2, m 1, cm 75))
    fun kn => { kn with yawRate := some (yaws.getD k Q.zero) }

-- ---------------------------------------------------------------------------------------------
-- `holds`: a left reversal, 19 deg/s over nine seconds
-- ---------------------------------------------------------------------------------------------
def holdsPos : List Vec :=
  [ (cm (-4000), cm 0), (cm (-3500), cm 0), (cm (-3000), cm 0), (cm (-2500), cm 0)
  , (cm (-2000), cm 0), (cm (-1500), cm 0)
  , (cm (-1030), cm 160), (cm (-630), cm 470), (cm (-360), cm 890), (cm (-240), cm 1370)
  , (cm (-280), cm 1870), (cm (-490), cm 2330), (cm (-830), cm 2690), (cm (-1270), cm 2930)
  , (cm (-1760), cm 3000)
  , (cm (-2250), cm 3080), (cm (-2750), cm 3160), (cm (-3240), cm 3240), (cm (-3730), cm 3320)
  , (cm (-4230), cm 3390), (cm (-4720), cm 3470) ]

def holdsHd : List Vec :=
  [ dir 1000 0, dir 1000 0, dir 1000 0, dir 1000 0, dir 1000 0, dir 1000 0
  , dir 945 326, dir 788 616, dir 545 839, dir 242 970, dir (-87) 996, dir (-407) 914
  , dir (-682) 731, dir (-883) 469, dir (-988) 156
  , dir (-988) 156, dir (-988) 156, dir (-988) 156, dir (-988) 156, dir (-988) 156
  , dir (-988) 156 ]

def holdsYaw : List Q :=
  [ dps 0, dps 0, dps 0, dps 0, dps 0, dps 0
  , dps 19, dps 19, dps 19, dps 19, dps 19, dps 19, dps 19, dps 19, dps 19
  , dps 0, dps 0, dps 0, dps 0, dps 0, dps 0 ]

/-- `holds` (compliant): A car turns left out of its lane and back across the road, accumulating 171 degrees of heading change over the window, and now heads the way it came from. -/
def holdsTrace : Trace :=
  Build.trace 21 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ car holdsPos holdsHd holdsYaw k ] [ ] [ ]

-- ---------------------------------------------------------------------------------------------
-- `fails`: a right turn, 89 degrees over the window
-- ---------------------------------------------------------------------------------------------
def failsPos : List Vec :=
  [ (cm (-4000), cm 0), (cm (-3500), cm 0), (cm (-3000), cm 0), (cm (-2500), cm 0)
  , (cm (-2000), cm 0), (cm (-1500), cm 0)
  , (cm (-1007), cm (-87)), (cm (-537), cm (-258)), (cm (-104), cm (-508)), (cm 279, cm (-829))
  , (cm 600, cm (-1212)), (cm 850, cm (-1645)), (cm 1021, cm (-2115)), (cm 1108, cm (-2608))
  , (cm 1117, cm (-3108))
  , (cm 1126, cm (-3608)), (cm 1135, cm (-4108)), (cm 1144, cm (-4608)), (cm 1153, cm (-5108))
  , (cm 1162, cm (-5608)), (cm 1171, cm (-6108)) ]

def failsHd : List Vec :=
  [ dir 1000 0, dir 1000 0, dir 1000 0, dir 1000 0, dir 1000 0, dir 1000 0
  , dir 985 (-174), dir 940 (-342), dir 866 (-500), dir 766 (-643), dir 643 (-766)
  , dir 500 (-866), dir 342 (-940), dir 174 (-985), dir 17 (-1000)
  , dir 17 (-1000), dir 17 (-1000), dir 17 (-1000), dir 17 (-1000), dir 17 (-1000)
  , dir 17 (-1000) ]

def failsYaw : List Q :=
  [ dps 0, dps 0, dps 0, dps 0, dps 0, dps 0
  , dps (-10), dps (-10), dps (-10), dps (-10), dps (-10), dps (-10), dps (-10), dps (-10)
  , dps (-9)
  , dps 0, dps 0, dps 0, dps 0, dps 0, dps 0 ]

/-- `fails` (violated): A car turns right at a junction, accumulating 89 degrees of heading change over the window: below the reversal bound. -/
def failsTrace : Trace :=
  Build.trace 21 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [ car failsPos failsHd failsYaw k ] [ ] [ ]

/-- `blind` (unknown): A car reverses its direction at a junction in a scene whose source declares the yaw rate absent, so the heading change cannot be integrated. -/
def blindTrace : Trace := holdsTrace

/-- Every scenario is judged at t = 14000 ms, the observation whose window behind carries the
    heading change its narrative states. -/
def judged : Timestamp × Timestamp := (14000, 14000)

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

end TrafficSpecWitness.Concepts.motion.direction_reversal
