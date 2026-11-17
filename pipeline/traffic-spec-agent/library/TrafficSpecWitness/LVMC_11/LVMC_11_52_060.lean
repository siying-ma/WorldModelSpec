/-
  Witnesses for LVMC_11_52_060.

  The street (every scene, static): highway 10 spans x ∈ [-100, 100], y ∈ [-5, 20]. Its near curb,
  road edge 20, is the strip y ∈ [-0.2, 0]; its far curb, road edge 21, the strip y ∈ [14, 14.2];
  both lie on highway 10. Two lanes lie on it: lane 31, y ∈ [0, 7], designated east; lane 32,
  y ∈ [7, 14], designated west.

  Each trace has 61 scenes, 10 s apart (0 … 600 s); the witness speaks about 200 … 600 s, so the
  parking window (p.parking_min_duration, 180 s) behind every judged instant lies in the trace.
  Fifteen feet is 4.572 m.

  forbid: truck 1, 10 m long and 2.5 m wide, at rest, heading north, centred at (0, 5.2): its body
    spans y ∈ [0.2, 10.2], 0.2 m from curb 20 and across both lanes; projection 0.2 + 10 = 10.2 m.
  permit: car 1, 4.8 m long and 1.8 m wide, at rest, heading east, centred at (0, 1.2): body
    y ∈ [0.3, 2.1] in lane 31; projection 0.3 + 1.8 = 2.1 m.
  idle: car 1 at 12 m/s, heading west in lane 32, centred at (0, 9): not parked.
  blind: as forbid, with st.region_geometry masked: every body-to-curb distance is unknown.
  branch_1: trailer 1 (trailer_or_combination), 8 m long, at rest, heading north, centred at
    (0, 4.1): body y ∈ [0.1, 8.1]; projection 8.1 m.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_060
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_060

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The street: highway, two curbs, two lanes. -/
def street : List Structure :=
  [ Build.rect 10 .highway (m (-100)) (m (-5)) (m 100) (m 20)
  , { Build.rect 20 .roadEdge (m (-100)) (cm (-20)) (m 100) Q.zero with ways := some [10] }
  , { Build.rect 21 .roadEdge (m (-100)) (m 14) (m 100) (cm 1420) with ways := some [10] }
  , { Build.lane 31 [(m (-100), Q.zero), (m 100, Q.zero), (m 100, m 7), (m (-100), m 7)] Build.east
      with ways := some [10] }
  , { Build.lane 32 [(m (-100), m 7), (m 100, m 7), (m 100, m 14), (m (-100), m 14)] Build.west
      with ways := some [10] } ]

/-- A static scene of one road user on the street, 61 instants 10 s apart. -/
def onStreet (u : RoadUser) : Trace :=
  Build.trace 61 0 (Units.seconds 10) fun _k t =>
    Build.scene t (some 1) [u] street []

/-- `forbid` (violated): A truck 10 m long is parked for 10 minutes at right angles to the curb of a two-lane street, 0.2 m from the curb; its heading is perpendicular to the roadway's direction, so its body reaches about 10.2 m into the street, beyond fifteen feet. -/
def truck : RoadUser :=
  Build.user 1 [.truck] (Q.zero, cm 520) Build.north Q.zero (m 5, cm 125, cm 200)

def forbidTrace : Trace := onStreet truck

/-- `permit` (compliant): A passenger car 1.8 m wide is parked for 10 minutes parallel to the curb, 0.3 m from it, heading along the roadway's direction: its body reaches about 2.1 m into the street. -/
def permitTrace : Trace :=
  onStreet (Build.user 1 [.motorVehicle] (Q.zero, cm 120) Build.east Q.zero (cm 240, cm 90, cm 75))

/-- `idle` (not_applicable): A car travels at 12 m/s along the far lane of the street, 8 m from the curb: it is not parked, so the rule does not apply. -/
def idleTrace : Trace :=
  onStreet (Build.user 1 [.motorVehicle] (Q.zero, m 9) Build.west (Units.metresPerSecond 12)
    (cm 240, cm 90, cm 75))

/-- `blind` (unknown): A truck is parked at right angles to the curb, but the source maps regions without their outline (st.region_geometry absent): the distance from the body to the curb is unknown. -/
def blindTrace : Trace := onStreet truck

/-- `branch_1` (violated): A detached trailer 8 m long is parked for 10 minutes at right angles to the curb, 0.1 m from it: as a vehicle in its own right its body reaches about 8.1 m into the street. -/
def branch_1Trace : Trace :=
  onStreet (Build.user 1 [.trailerOrCombination] (Q.zero, cm 410) Build.north Q.zero (m 4, cm 125, cm 200))

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_52_060"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (200000, 600000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["st.region_geometry"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.LVMC_11_52_060
