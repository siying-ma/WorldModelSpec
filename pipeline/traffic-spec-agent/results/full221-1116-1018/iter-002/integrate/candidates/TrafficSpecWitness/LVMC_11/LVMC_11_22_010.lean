/-
  Witnesses for LVMC_11_22_010.

  Geometry: one eastbound lane (region 1), x from −50 m to 200 m, y from −2 m to 2 m. Every body is a
  passenger car, half-extents 2.5 m × 1 m × 0.75 m, centred on y = 0. Scenes every 0.1 s, three
  instants (t = 0, 100, 200 ms).

  - forbid: the subject (track 1) at x = k m, 10 m/s east; a halted car (track 2) at x = 14 m.
    The centres meet in 1.2–1.4 s (inside 1.5 s) at a centre distance of 0 m (below 3 m); the
    bodies are 7 m or more apart, so nothing touches.
  - permit: the subject at x = k m and the car ahead at x = 30 + k m, both 10 m/s east: the centres
    never approach (no relative velocity), the gap stays 25 m.
  - idle: the subject halted (0 m/s) at x = 0 in a lane governed by a signal showing circular red.
  - blind: the forbid geometry with the subject's speed masked.
  - branch_1: the subject alone in the lane at 10 m/s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_22_010
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_22_010

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)

def laneEast : Structure :=
  Build.lane 1 [(m (-50), m (-2)), (m 200, m (-2)), (m 200, m 2), (m (-50), m 2)] Build.east

def dt : Q := Units.milliseconds 100

/-- `forbid` (violated): The subject closes on a halted vehicle ahead in its lane at constant speed; the closest approach falls below the clearance within p.attention_ttc_min. -/
def forbidTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m k, m 0) Build.east (Units.metresPerSecond 10) carExtent
      , Build.user 2 [.motorVehicle] (m 14, m 0) Build.east (Units.metresPerSecond 0) carExtent ]
      [ laneEast ]
      [ ]

/-- `permit` (compliant): The subject follows a vehicle ahead at a steady gap, never closing within the threshold, and touches nothing. -/
def permitTrace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m k, m 0) Build.east (Units.metresPerSecond 10) carExtent
      , Build.user 2 [.motorVehicle] (m (30 + k), m 0) Build.east (Units.metresPerSecond 10) carExtent ]
      [ laneEast ]
      [ ]

/-- `idle` (not_applicable): The subject is halted at a signal. -/
def idleTrace : Trace :=
  Build.trace 3 0 dt fun _k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 0, m 0) Build.east (Units.metresPerSecond 0) carExtent ]
      [ laneEast ]
      [ Build.signal 1 [1] [.circularRed] ]

/-- `blind` (unknown): The subject's speed is not observed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): The subject drives alone on an empty road, touching nothing. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 dt fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m k, m 0) Build.east (Units.metresPerSecond 10) carExtent ]
      [ laneEast ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_22_010"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant ]

end TrafficSpecWitness.LVMC_11_22_010
