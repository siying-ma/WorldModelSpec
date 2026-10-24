/-
  Witnesses for drv.control.intersection_controlled.

  Every figure below is the witness's own; the concept has no formal parameter and no literal
  formal, so the instance fills nothing. All three scenarios are built on one straight street that
  runs east along `y = 0 … 4 m`, with junctions cut out of it; the car is 4 m long and 2 m wide
  (half-extents 2 m, 1 m, 1 m) and drives or stands on the centre line of its lane at `y = 2 m`,
  so `Build.scene` derives its occupancy from the geometry: it occupies exactly the region whose
  polygon contains its position, and its occupancy is observed.

  `holds` — a drive of five observations 6 s apart at 20 m/s (120 m a step), past five junctions.
  Each junction is a 12 m square intersection region, and each approach lane is mapped as running
  into it (`enters`):

    - junction A, region 10, centred at x = 0; approach lane 11 from x = -100 m to x = -6 m;
      a yield sign (device 101) faces lane 11;
    - junction B, region 20, centred at x = 100 m; approach lane 21 from 6 m to 94 m;
      a signal head (device 102) faces the junction region 20 itself;
    - junction C, region 30, centred at x = 260 m; approach lane 31 from 106 m to 254 m;
      a point regulatory sign (device 103) faces lane 31;
    - junction D, region 40, centred at x = 400 m; approach lane 41 from 266 m to 394 m;
      a second signal head (device 104) faces the junction region 40 itself;
    - junction E, region 42, centred at x = 660 m; approach lane 43 from 406 m to 654 m;
      a stop sign (device 106) faces lane 43.

    The car is at x = -20 m, 100 m, 220 m, 340 m, 460 m at the five observations: in lane 11,
    inside the junction region of B (the lanes stop at the junction's edge, so it is in no lane
    there), in lane 31, in lane 41, in lane 43. The observations exercise the four device kinds of
    the contract's disjunction one at a time, and the two regions a device may govern:

      - at x = -20 m the car is on an approach and only the yield sign governs that approach;
      - at x = 100 m the car's footprint overlaps the junction region and only the signal head
        governs that region;
      - at x = 220 m the car is on an approach and only the regulatory sign governs it;
      - at x = 340 m the car is on an approach and the signal head governs the junction region
        the approach runs into, not the approach itself;
      - at x = 460 m the car is on an approach and only the stop sign governs that approach.

    No device governs anything else: at each observation exactly one device decides, so the
    scenario would not be compliant if any one of the four kinds, either region of the
    disjunction, the lane membership, the approach relation or the junction's kind were read
    otherwise. One junction is the narrative's four-way junction with a signal head facing the
    car's approach; the drive carries the others because one standing car at one junction cannot
    exercise the four device kinds the contract names.

  `fails` — the residential junction, three observations 1 s apart of a standing car:
    junction region 50 centred at x = 0, the car's approach lane 51 from -100 m to -6 m running
    into it, and the crossing street's approach lane 52 from the north (x = 0 … 4 m,
    y = 6 … 100 m) running into it as well. The car stands at x = -20 m in lane 51. The scene
    carries no device at all, so no signal head, stop sign, yield sign or regulatory sign faces
    the car's approach, the crossing approach or the junction region: every disjunct is decided
    false and the body is false at every observation.

  `blind` — the junction region 60 centred at x = 0 with the car's approach lane 61 from -100 m
    to -6 m running into it, the car standing at x = -20 m in lane 61, and a stop sign (device
    105) beside the lane at (-7 m, 5 m) mapped as facing lane 61. The manifest declares
    `dev.governs` absent, so which traffic any device faces cannot be read: the junction, the
    lane, the approach relation and the device's kind are all still decided, the stop sign's
    disjunct is unknown and no other device is present to decide the disjunction, so the body is
    unknown at every observation - for the masked atom and nothing else.
-/
import TrafficSpec.Concepts.control.intersection_controlled
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.Concepts.control.intersection_controlled

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Formals ↦ tracks: u ↦ 1

/-- The instance every scenario speaks about: the literal formals chosen, every parameter given a
    value through a `Units` constructor, a quantity concept given its expected bounds. The concept
    has no literal formal and no formal parameter, so there is nothing to fill. -/
def inst : Concept.Instance :=
  { name := "drv.control.intersection_controlled@w"
    concept := "drv.control.intersection_controlled"
    literals := []
    nats := []
    params := []
    bounds := none
  }

def instances : List Concept.Instance := [inst]

/-- A 12 m square intersection region centred on the street at `cx`. -/
def junction (id : RegionId) (cx : Int) : Structure :=
  Build.rect id .intersection (m (cx - 6)) (m (-6)) (m (cx + 6)) (m 6)

/-- An eastbound approach lane from `x0` to `x1`, 4 m wide, running into the junction `ix`. -/
def eastboundApproach (id : RegionId) (x0 x1 : Int) (ix : RegionId) : Structure :=
  Build.lane id [(m x0, m 0), (m x1, m 0), (m x1, m 4), (m x0, m 4)] Build.east (enters := some ix)

/-- The four junctions of the drive and their approaches. -/
def drive : List Structure :=
  [ junction 10 0
  , eastboundApproach 11 (-100) (-6) 10
  , junction 20 100
  , eastboundApproach 21 6 94 20
  , junction 30 260
  , eastboundApproach 31 106 254 30
  , junction 40 400
  , eastboundApproach 41 266 394 40
  , junction 42 660
  , eastboundApproach 43 406 654 42 ]

/-- The devices of the drive: one per junction, each facing one region and nothing else. -/
def driveDevices : List Device :=
  [ Build.device 101 .yieldSign [11] (some (m (-7), m 5))
  , Build.device 102 .trafficSignal [20] (some (m 106, m 7))
  , Build.device 103 .regulatorySign [31] (some (m 105, m 5))
  , Build.device 104 .trafficSignal [40] (some (m 406, m 7))
  , Build.device 106 .stopSign [43] (some (m 405, m 5)) ]

/-- The residential junction of `fails`: two streets meeting, both approaches mapped. -/
def residentialJunction : List Structure :=
  [ junction 50 0
  , eastboundApproach 51 (-100) (-6) 50
  , Build.lane 52 [(m 0, m 6), (m 4, m 6), (m 4, m 100), (m 0, m 100)] Build.south (enters := some 50) ]

/-- The junction of `blind` and the car's approach to it. -/
def signedJunction : List Structure :=
  [ junction 60 0
  , eastboundApproach 61 (-100) (-6) 60 ]

/-- The stop sign standing beside the approach lane of `blind`, facing that lane. -/
def stopSignBeside : List Device :=
  [ Build.device 105 .stopSign [61] (some (m (-7), m 5)) ]

/-- The car driving east at 20 m/s, `x` metres along the street, on the centre line of its lane. -/
def car (x : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 2) Build.east (Units.metresPerSecond 20) (m 2, m 1, m 1)

/-- The car standing, heading east, at `x` metres. -/
def standingCar (x : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m x, m 2) Build.east (Units.metresPerSecond 0) (m 2, m 1, m 1)

/-- `holds` (compliant): A car stands in a lane that runs into a four-way junction; a signal head mounted over that junction faces the lane the car is in. Written as a drive past five
    junctions, each controlled by one device, so that the body is true at every observation and
    each of the contract's four device kinds decides one of them. -/
def holdsTrace : Trace :=
  Build.trace 5 0 (Units.seconds 6) fun k t =>
    Build.scene t (some 1)
      [ car (-20 + 120 * (k : Int)) ]
      drive
      driveDevices

/-- `fails` (violated): A car stands in a lane that runs into a junction of two residential streets; no signal head, stop sign, yield sign or regulatory sign faces that lane or any other approach of the junction. -/
def failsTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ standingCar (-20) ]
      residentialJunction
      []

/-- `blind` (unknown): A car stands in a lane that runs into a junction and a stop sign stands beside it, but the source does not report which traffic any device faces. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ standingCar (-20) ]
      signedJunction
      stopSignBeside

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
  [ witness "holds" holdsTrace .compliant
  , witness "fails" failsTrace .violated
  , witness "blind" blindTrace (.unknown []) ["dev.governs"] ]

end TrafficSpecWitness.Concepts.control.intersection_controlled
