/-
  Witnesses for NRS_484D_165_4.

  Geometry: a straight eastbound roadway (x 0 … 400 m, y −4 … 4 m); track 1 is a car (half
  extents 2 m × 1 m × 75 cm) standing at the curb side at (300 m, −2 m), heading east.
  Instants: every 10 s from 0 s to 300 s (31 scenes). The parked window (180 s in the reading)
  reaches before the trace start until 180 s, so each witness judges the instants 200 s … 300 s:
  there the car has stood for 200 s or more (parked, by a margin of 20 s over the bound), with
  speed 0 (well under the 0.1 m/s tolerance).
  branch_1: the car drives east at 10 m/s until 270 s and stands for 20 s and more from 280 s
  (280, 290, 300 s): the window behind every judged instant holds a speed of 10 m/s, so it is
  not parked. branch_2: the stationary road user is a bicycle, which the vehicle aggregate
  does not include.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484D.NRS_484D_165_4
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484D_165_4

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def roadway : Structure := Build.rect 100 .roadway (m 0) (m (-4)) (m 400) (m 4)

/-- The parked car, its headlamps in the given state (`none`: not observed). -/
def parkedCar (classes : List RoadUserClass) (lamp : Option HeadlampState) : RoadUser :=
  Build.withSignals (Build.user 1 classes (m 300, m (-2)) Build.east Q.zero (m 2, m 1, cm 75))
    fun s => { s with headlamp := lamp }

def standingTrace (classes : List RoadUserClass) (lamp : Option HeadlampState) : Trace :=
  Build.trace 31 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [ parkedCar classes lamp ] [ roadway ] [ ]

/-- `forbid` (violated): A car of the vehicle aggregate has stood at rest at the curb for five minutes with its headlamps on high beam. -/
def forbidTrace : Trace := standingTrace [.motorVehicle] (some .highBeam)

/-- `permit` (compliant): As forbid, but the headlamps are on low beam. -/
def permitTrace : Trace := standingTrace [.motorVehicle] (some .lowBeam)

/-- `idle` (not_applicable): A car has stood at rest at the curb for five minutes with its headlamps off. -/
def idleTrace : Trace := standingTrace [.motorVehicle] (some .off)

/-- `blind` (unknown): A car has stood at rest at the curb for five minutes; the source does not observe headlamps. -/
def blindTrace : Trace := standingTrace [.motorVehicle] none

/-- `branch_1` (not_applicable): A car halts for twenty seconds in traffic with high beams on: a halt shorter than the parking duration is not parked. -/
def branch_1Trace : Trace :=
  Build.trace 31 0 (Units.seconds 10) fun k t =>
    let moving := decide (k < 28)
    let x : Q := if moving then m (10 * (k : Int)) else m 280
    let v : Q := if moving then Units.metresPerSecond 10 else Q.zero
    Build.scene t (some 1)
      [ Build.withSignals (Build.user 1 [.motorVehicle] (x, m 2) Build.east v (m 2, m 1, cm 75))
          fun s => { s with headlamp := some .highBeam } ]
      [ roadway ]
      [ ]

/-- `branch_2` (not_applicable): A bicycle, not of the vehicle aggregate, has stood at rest for
    five minutes with its headlamp on high beam. -/
def branch_2Trace : Trace := standingTrace [.bicycle] (some .highBeam)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484D_165_4"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (200000, 300000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["sig.headlamp"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484D_165_4
