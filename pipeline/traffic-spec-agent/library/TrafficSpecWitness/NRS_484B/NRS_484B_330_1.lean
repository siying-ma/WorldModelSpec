/-
  Witnesses for NRS_484B_330_1.

  Geometry (every figure is the witness's own): a highway region 100 (x 0…200 m, y −10…10 m) and on
  it a lane 101 (x 0…200 m, y −2…2 m, `ways = [100]`), traffic eastbound. The car (track 1, a motor
  vehicle) drives east along y = 0. The flagger (device 200, human direction, role flagger) stands at
  (100 m, 3 m) and governs the lane; cones (device 201, temporary traffic control) at (120 m, 2 m)
  govern the lane; a temporary traffic control zone sign (device 202, not an end sign) governs it in
  branch_4. The flagger is ahead of the car while the car's x is below 100 m.
  Instants are 1 s apart, except branch_2 (50 ms, the heading integration's sampling standard).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_330_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_330_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The car at `x` on the lane's centre, eastbound. -/
def car (x : Q) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (x, Q.zero) Build.east speed (cm 225, cm 90, cm 75)

def highway : Structure := Build.rect 100 .highway (m 0) (m (-10)) (m 200) (m 10)
def lane : Structure := { Build.rect 101 .lane (m 0) (m (-2)) (m 200) (m 2) with ways := some [100] }
def structures : List Structure := [highway, lane]

def flagger (ind : HumanIndication) : Device :=
  { Build.device 200 .humanDirection [101] (some (m 100, m 3)) with
    humanRole := some .flagger, humanIndication := some ind }
def cones : Device := Build.device 201 .temporaryTrafficControl [101] (some (m 120, m 2))
def zoneSign : Device :=
  { Build.zoneSign 202 [101] .temporaryTrafficControl false with position := some (m 50, m 3) }

/-- The car passing the flagger showing stop: x = 90, 98, 106 m. -/
def passingStop (devices : List Device) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m ([90, 98, 106].getD k 0)) (Units.metresPerSecond 8) ]
      structures
      devices

/-- `forbid` (violated): A car occupies a lane governed by a dev.temporary_traffic_control device and by a flagger (dev.human_direction, role flagger) indicating stop; the flagger is ahead of the car, and the car drives past the flagger's position while the indication stays stop. -/
def forbidTrace : Trace := passingStop [flagger .stop, cones]

/-- `permit` (compliant): As in forbid, but the car halts short of the flagger and moves past only after the indication has changed to proceed. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (m ([90, 96, 96, 96, 104].getD k 0)) (Units.metresPerSecond ([6, 0, 0, 0, 8].getD k 0)) ]
      structures
      [ flagger (if k < 3 then .stop else .proceed), cones ]

/-- `idle` (not_applicable): No flagger governs the car's lane; cones mark a work area. -/
def idleTrace : Trace := passingStop [cones]

/-- `blind` (unknown): As in forbid, but the flagger's indication is not observed (dev.human_direction absent). -/
def blindTrace : Trace := passingStop [flagger .stop, cones]

/-- `branch_1` (violated): The flagger ahead indicates slow; the car's longitudinal acceleration stays above the threshold as it approaches the flagger. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (car (m ([60, 70, 80].getD k 0)) (Units.metresPerSecond 10))
          fun kn => { kn with accelLongitudinal := some (Units.metresPerSecondSq 2) } ]
      structures
      [ flagger .slow, cones ]

/-- `branch_2` (violated): The flagger indicates turn(left); the car drives straight past the flagger's position with almost no heading change since the indication began. -/
def branch_2Trace : Trace :=
  Build.trace 5 0 (Units.milliseconds 50) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (car (cm (9860 + 50 * (Int.ofNat k))) (Units.metresPerSecond 10))
          fun kn => { kn with yawRate := some (Units.degrees 0) } ]
      structures
      [ flagger (if k = 0 then .proceed else .turn .left), cones ]

/-- `branch_3` (not_applicable): A person directing traffic with role flagger governs the car's lane but no temporary traffic control device or temporary traffic control zone sign governs it. -/
def branch_3Trace : Trace := passingStop [flagger .stop]

/-- `branch_4` (violated): no cones; a temporary traffic control zone sign (not an end sign) governs the
    lane, and the car passes the flagger showing stop. -/
def branch_4Trace : Trace := passingStop [flagger .stop, zoneSign]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_330_1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["dev.human_direction"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_484B_330_1
