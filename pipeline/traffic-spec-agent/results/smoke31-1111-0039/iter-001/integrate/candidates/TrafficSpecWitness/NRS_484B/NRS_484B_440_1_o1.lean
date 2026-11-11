/-
  Witnesses for NRS_484B_440_1_o1.

  A rural highway (region 10) runs east–west, 200 m long and 20 m wide; its roadway (11) is the
  band 4 m either side of the centre, the eastbound lane (13) its southern half. A shoulder (12)
  lies along the south edge of the roadway, 3 m wide, except in `permit`, where the roadway is a
  bridge without one and the nearest shoulder begins 60 m east of x. x (track 1, a motor vehicle,
  4.5 m × 1.8 m) stands at (0, -2) heading east, speed 0, engine running, no hazard lamps: its body
  reaches to 1.1 m of the shoulder, well inside the 5 m reach, and in `permit` about 58 m from it.
  In `branch_2` a halted truck (track 2) stands ahead of x in the lane, 1.75 m from x's front.
  Every scene repeats for three instants, one second apart; the rule does not look back.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_440_1_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_440_1_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- x halted in the eastbound lane, with its engine and hazard lamps as given. -/
def vehicleX (engine hazard : Bool) : RoadUser :=
  Build.withSignals
    (Build.withKin
      (Build.user 1 [.motorVehicle] (m 0, m (-2)) Build.east Q.zero (cm 225, cm 90, cm 75))
      (fun k => { k with engineRunning := some engine }))
    (fun s => { s with hazard := some hazard })

def highway : Structure := Build.rect 10 .highway (m (-100)) (m (-10)) (m 100) (m 10)
def roadway : Structure := Build.rect 11 .roadway (m (-100)) (m (-4)) (m 100) (m 4)
def eastLane : Structure :=
  Build.lane 13 [(m (-100), m (-4)), (m 100, m (-4)), (m 100, m 0), (m (-100), m 0)] Build.east
def shoulderBeside : Structure := Build.rect 12 .shoulder (m (-100)) (m (-7)) (m 100) (m (-4))
/-- The shoulder beyond the bridge: it begins 60 m east of x. -/
def shoulderBeyond : Structure := Build.rect 12 .shoulder (m 60) (m (-7)) (m 100) (m (-4))

def ruralStructures : List Structure := [highway, roadway, eastLane, shoulderBeside]

def ruralScene (t : Timestamp) (users : List RoadUser) (structures : List Structure)
    (devices : List Device) (inDistrict : Bool := false) : Scene :=
  Build.scene t (some 1) users structures devices
    (assumptions := [("asm.within_business_or_residence_district", inDistrict)])

/-- `forbid` (violated): x (ru.motor_vehicle) on a rural highway (asm.within_business_or_residence_district declared false) halts with its footprint on the st.roadway, engine running, no hazard lamps, nothing ahead and no device governing; a st.shoulder lies within p.offroad_stop_reach of its body. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] ruralStructures []

/-- `permit` (compliant): x halts on the roadway of a rural bridge with no shoulder within p.offroad_stop_reach; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] [highway, roadway, eastLane, shoulderBeyond] []

/-- `idle` (not_applicable): x halts on the roadway in a declared residence district (asm.within_business_or_residence_district true). -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] ruralStructures [] (inDistrict := true)

/-- `blind` (unknown): x halts on the rural roadway beside a mapped shoulder, but the source maps regions without their outline, so the distance to the shoulder is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] ruralStructures []

/-- `branch_1` (not_applicable): x halts on the rural roadway with its engine not running and its hazard lamps flashing: the disabled-vehicle exception applies. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX false true] ruralStructures []

/-- The halted truck ahead of x in its lane: its rear 1.75 m from x's front. -/
def truckAhead : RoadUser :=
  Build.user 2 [.truck] (m 8, m (-2)) Build.east Q.zero (cm 400, cm 125, cm 150)

/-- `branch_2` (compliant): x halts on the rural roadway behind a halted truck ahead in its lane at a surface gap below p.stopping_conflict_gap, a shoulder within reach: the halt avoids a conflict and is no prohibited stop. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false, truckAhead] ruralStructures []

/-- `branch_3` (compliant): as `forbid`, but a police officer directing stop governs x's lane. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] ruralStructures
      [ { Build.device 20 .humanDirection [13] with
          humanRole := some .policeOfficer, humanIndication := some .stop } ]

/-- `branch_4` (compliant): as `forbid`, but a traffic signal showing circular red governs the roadway. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] ruralStructures [Build.signal 21 [11] [.circularRed]]

/-- `branch_5` (compliant): as `forbid`, but a stop sign governs the roadway. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    ruralScene t [vehicleX true false] ruralStructures [Build.sign 22 .stopSign [11]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_440_1_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .compliant ]

end TrafficSpecWitness.NRS_484B_440_1_o1
