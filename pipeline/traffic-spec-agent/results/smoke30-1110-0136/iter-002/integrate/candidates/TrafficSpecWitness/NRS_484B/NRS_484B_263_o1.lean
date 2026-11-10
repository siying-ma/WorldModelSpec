/-
  Witnesses for NRS_484B_263_o1.

  Three observations 1 s apart (t = 0, 1000, 2000 ms); every witness speaks about t = 1000 and
  2000 (`window`), since entry and exit are read as a change from the observation before.
  Vehicles are 4 m long and 2 m wide (half-extents 2 m, 1 m).

  Entry scenes (forbid, permit, blind, branch_2): controlled-access region a (10) spans
  x ∈ [-200, 200], y ∈ [0, 12]; an adjoining roadway (11) lies south of it, y ∈ [-8, 0]. x heads
  east at 15 m/s from (0, -3) on the roadway to (15, 2) on a at t = 1000.
  - forbid: y on a at (-1, 3.5), 28 m/s east: body gap 12 m (below 28 × 4 = 112 m); centres
    approach in 16/13 ≈ 1.2 s to 1.5 m.
  - permit: y on a at (-45, 8), 25 m/s east: gap ≈ 56 m (below 25 × 4 = 100 m); closest approach
    in 6 s, past the 3 s horizon.
  Exit scene (branch_1): a spans x ∈ [-200, 0], y ∈ [0, 8]; a crossroad h (12, highway) spans
  x ∈ [0, 20], y ∈ [-100, 100]. x heads east at 10 m/s from (-5, 4) on a to (5, 4) on h; y heads
  south at 13 m/s on h at (15, 15): gap ≈ 10.6 m (below 52 m), closest approach ≈ 1.2 m in 0.9 s.
  Idle: x drives east at 15 m/s along y = -4 on the roadway; a lies at y ∈ [20, 32] and is
  never entered.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

def car : Q × Q × Q := (m 2, m 1, cm 75)

-- Binders ↦ tracks: x ↦ 1

/-- The entry layout: controlled-access region a north of an adjoining roadway. -/
def entryStructures : List Structure :=
  [ Build.rect 10 .controlledAccess (m (-200)) (m 0) (m 200) (m 12)
  , Build.rect 11 .roadway (m (-200)) (m (-8)) (m 200) (m 0) ]

/-- x entering a: on the roadway at k = 0, on a from k = 1. -/
def xEntering (k : Nat) : RoadUser :=
  let px : Q := m (15 * (k : Int))
  let py : Q := if k == 0 then m (-3) else m 2
  Build.user 1 [.motorVehicle] (px, py) Build.east (mps 15) car

/-- `forbid` (violated): x enters controlled-access region a from an adjoining way at 15 m/s while y on a is 12 m away at 28 m/s (12 m below 28 m/s times the critical gap); predicted closest approach 1.5 m in 0.8 s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k
      , Build.user 2 [.motorVehicle] (m (-1 + 28 * ((k : Int) - 1)), cm 350) Build.east (mps 28) car ]
      entryStructures
      [ ]

/-- `permit` (compliant): x enters a while y on a, 60 m behind at 25 m/s (within speed times the critical gap), is predicted to pass in the next lane 6 m from x at its closest. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k
      , Build.user 2 [.motorVehicle] (m (-45 + 25 * ((k : Int) - 1)), m 8) Build.east (mps 25) car ]
      entryStructures
      [ ]

/-- `idle` (not_applicable): x drives on an ordinary roadway and never enters or leaves a controlled-access region. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (15 * (k : Int)), m (-4)) Build.east (mps 15) car ]
      [ Build.rect 10 .controlledAccess (m (-200)) (m 20) (m 200) (m 32)
      , Build.rect 11 .roadway (m (-200)) (m (-8)) (m 200) (m 0) ]
      [ ]

/-- `blind` (unknown): As forbid, with every footprint (position, heading, extent) observed, but the source observes neither the speeds nor the velocities of the road users, so whether y is moving and whether its proximity is an immediate hazard (its body gap against its speed times the critical gap) is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): x leaves a onto a crossroad (st.highway) and moves across it while y on the crossroad, 10 m away at 13 m/s, is in predicted conflict (1 m in 0.9 s). -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (-5 + 10 * (k : Int)), m 4) Build.east (mps 10) car
      , Build.user 2 [.motorVehicle] (m 15, m (28 - 13 * (k : Int))) Build.south (mps 13) car ]
      [ Build.rect 10 .controlledAccess (m (-200)) (m 0) (m 0) (m 8)
      , Build.rect 12 .highway (m 0) (m (-100)) (m 20) (m 100) ]
      [ ]

/-- `branch_2` (not_applicable): x enters a with no other road user in the scene. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ xEntering k ]
      entryStructures
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed", "kin.velocity"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_263_o1
