/-
  Witnesses for NRS_484B_263_o1.

  Geometry (+x east, +y north): the controlled-access carriageway `a` (region 10) is the strip
  y ∈ [0, 8], x ∈ [-1000, 1000]; a ramp (region 11, a roadway) runs alongside it at y ∈ [-8, 0].
  Every body travels east; instants are 0, 1 and 2 s. Occupancy follows the reference points.

  An entry or exit is read against the observation before, so the instant at t = 0 has none and is
  unknown there; every witness speaks about t ∈ [1000, 2000] ms (`window`).

  - forbid: x (track 1, 15 m/s) is on the ramp at t = 0 and in `a` at t = 1 s (entry), at (115, 1);
    y (track 2, 25 m/s) is in `a` at (100, 2): the centres close at 10 m/s, closest approach at
    1.5 s (≤ 4.1 s) and 1 m apart (< 3 m).
  - permit: x alone makes the same entry.
  - idle: x stays on an arterial roadway (region 12, y ∈ [-40, -30]); `a` exists but is never
    entered or left.
  - blind: forbid with kin.speed unobserved: y's motion is undecided.
  - branch_1: as forbid, y 300 m behind x at the entry: closest approach at 30 s, past the horizon.
  - branch_2: x leaves `a` for the ramp at t = 1 s, at (115, -1), while y in `a` at (100, 1) closes
    at 10 m/s: closest approach at 1.5 s, 2 m apart (< 3 m): violated through the exit.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def car : Q × Q × Q := (m 2, m 1, m 1)

def carriageway : Structure := Build.rect 10 .controlledAccess (m (-1000)) (m 0) (m 1000) (m 8)
def ramp : Structure := Build.rect 11 .roadway (m (-1000)) (m (-8)) (m 1000) (m 0)
def arterial : Structure := Build.rect 12 .roadway (m (-1000)) (m (-40)) (m 1000) (m (-30))

/-- x joining `a` from the ramp: on the ramp at k = 0, in `a` from k = 1. -/
def xEntering (k : Nat) : RoadUser :=
  let pos : Vec := if k = 0 then (m 100, m (-2)) else (m (100 + 15 * k), m 1)
  Build.user 1 [.motorVehicle] pos Build.east (Units.metresPerSecond 15) car

/-- y in `a`, at 25 m/s east, `behind` metres behind x's position at k = 1. -/
def yOnHighway (behind : Int) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (115 - behind + 25 * ((k : Int) - 1)), m 2) Build.east
    (Units.metresPerSecond 25) car

/-- `forbid` (violated): x moves from an on-ramp into controlled-access region a (entering) at 15 m/s while vehicle y in a, 15 m behind and moving at 25 m/s on a converging path, is predicted to come within 1 m of x in 1.5 s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k, yOnHighway 15 k ]
      [ carriageway, ramp ]
      [ ]

/-- `permit` (compliant): x enters a as the only road user in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k ]
      [ carriageway, ramp ]
      [ ]

/-- `idle` (not_applicable): x drives on an arterial roadway; no st.controlled_access region is entered or left. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (100 + 15 * k), m (-35)) Build.east
          (Units.metresPerSecond 15) car ]
      [ carriageway, arterial ]
      [ ]

/-- `blind` (unknown): As forbid, but kin.speed of y is not observed. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (compliant): x enters a while y in a is 300 m behind at 25 m/s: no predicted conflict within the horizon. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k, yOnHighway 300 k ]
      [ carriageway, ramp ]
      [ ]

/-- `branch_2` (violated): x exits a onto the ramp while y in a, 15 m behind at 25 m/s, is predicted to come within 2 m of x in 1.5 s. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let xPos : Vec := if k = 0 then (m 100, m 1) else (m (100 + 15 * k), m (-1))
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] xPos Build.east (Units.metresPerSecond 15) car
      , Build.user 2 [.motorVehicle] (m (100 + 25 * ((k : Int) - 1)), m 1) Build.east
          (Units.metresPerSecond 25) car ]
      [ carriageway, ramp ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_263_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_263_o1
