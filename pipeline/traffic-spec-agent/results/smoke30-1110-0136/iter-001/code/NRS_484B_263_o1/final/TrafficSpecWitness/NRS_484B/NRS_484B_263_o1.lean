/-
  Witnesses for NRS_484B_263_o1.

  The map, the same in every scene: a controlled-access region a (id 10, x ∈ [-300, 300],
  y ∈ [0, 10], traffic eastbound) and below it an ordinary highway (id 11, x ∈ [-300, 300],
  y ∈ [-30, -2]): the adjoining way x enters from, and the crossroad x exits onto. Bodies are
  4 m × 2 m (half-extents 2 m, 1 m, 0.75 m), each wholly inside one region, so occupancy read from
  the reference point and from the footprint agree.

  Three observations at 0 s, 1 s and 2 s; the entry or exit is at 1 s. The rule reads `rises`, which
  looks one observation back, so each witness speaks about the instants 1 s and 2 s (`window`).

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_263_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_263_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

/-- Half-length, half-width, half-height of a car. -/
def car : Q × Q × Q := (m 2, m 1, cm 75)

/-- The controlled-access region a. -/
def controlledAccess : Structure := Build.rect 10 .controlledAccess (m (-300)) (m 0) (m 300) (m 10)
/-- The ordinary highway beside it: the adjoining way and the crossroad. -/
def way : Structure := Build.rect 11 .highway (m (-300)) (m (-30)) (m 300) (m (-2))
def map : List Structure := [controlledAccess, way]

/-- `forbid` (violated): x enters controlled-access region a from an adjoining way at 15 m/s while y on a is 12 m away at 28 m/s (12 m below 28 m/s times the critical gap); predicted closest approach 1.5 m in 0.8 s.
    At 1 s x is at (15, 2) and y at (-1, 3.5), both eastbound: body gap 12 m ≤ 28 × 4 = 112 m;
    centres closest in 16/13 ≈ 1.2 s at 1.5 m, below 4 m. -/
def forbidX (k : Nat) : Vec := match k with | 0 => (m 0, m (-5)) | 1 => (m 15, m 2) | _ => (m 30, m 2)
def forbidY (k : Nat) : Vec := match k with | 0 => (m (-29), cm 350) | 1 => (m (-1), cm 350) | _ => (m 60, cm 350)

def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (forbidX k) Build.east (Units.metresPerSecond 15) car
      , Build.user 2 [.motorVehicle] (forbidY k) Build.east (Units.metresPerSecond 28) car ]
      map
      [ ]

/-- `permit` (compliant): x enters a while y on a, 60 m behind at 25 m/s (within speed times the critical gap), is predicted to pass in the next lane 6 m from x at its closest.
    At 1 s x is at (15, 2) at 3 m/s and y at (-45, 8) at 25 m/s: body gap about 56 m ≤ 100 m; the
    centres close at 22 m/s and are nearest in 60/22 ≈ 2.7 s at 6 m, not below 4 m. -/
def permitX (k : Nat) : Vec := match k with | 0 => (m 12, m (-5)) | 1 => (m 15, m 2) | _ => (m 18, m 2)
def permitY (k : Nat) : Vec := match k with | 0 => (m (-70), m 8) | 1 => (m (-45), m 8) | _ => (m (-20), m 8)

def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (permitX k) Build.east (Units.metresPerSecond 3) car
      , Build.user 2 [.motorVehicle] (permitY k) Build.east (Units.metresPerSecond 25) car ]
      map
      [ ]

/-- `idle` (not_applicable): x drives on an ordinary roadway and never enters or leaves a controlled-access region.
    x stays on the highway below a; y drives on a. -/
def idleX (k : Nat) : Vec := match k with | 0 => (m 0, m (-5)) | 1 => (m 15, m (-5)) | _ => (m 30, m (-5))

def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (idleX k) Build.east (Units.metresPerSecond 15) car
      , Build.user 2 [.motorVehicle] (forbidY k) Build.east (Units.metresPerSecond 28) car ]
      map
      [ ]

/-- `blind` (unknown): As forbid, but rel.surface_gap is not supplied and cannot be computed (kin.extent absent), so whether y's proximity is an immediate hazard is unknown.
    y's extent is not observed, so neither its footprint, its body gap to x nor its occupancy
    can be read; x is as in forbid. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    { Build.scene t (some 1)
        [ Build.user 1 [.motorVehicle] (forbidX k) Build.east (Units.metresPerSecond 15) car
        , Build.withKin (Build.user 2 [.motorVehicle] (forbidY k) Build.east (Units.metresPerSecond 28) car)
            (fun kin => { kin with extent := none }) ]
        map
        [ ]
      with occupancyObserved := [1] }

/-- `branch_1` (violated): x leaves a onto a crossroad (st.highway) and moves across it while y on the crossroad, 10 m away at 13 m/s, is in predicted conflict (1 m in 0.9 s).
    x southbound at 10 m/s leaves a between 0 s and 1 s; at 1 s x is at (0, -5) on the crossroad
    and y at (13, -15) westbound at 13 m/s: body gap about 12 m ≤ 52 m; centres meet in 1 s. -/
def branch1X (k : Nat) : Vec := match k with | 0 => (m 0, m 3) | 1 => (m 0, m (-5)) | _ => (m 0, m (-15))
def branch1Y (k : Nat) : Vec := match k with | 0 => (m 26, m (-15)) | 1 => (m 13, m (-15)) | _ => (m (-13), m (-15))

def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (branch1X k) Build.south (Units.metresPerSecond 10) car
      , Build.user 2 [.motorVehicle] (branch1Y k) Build.west (Units.metresPerSecond 13) car ]
      map
      [ ]

/-- `branch_2` (not_applicable): x enters a with no other road user in the scene. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (forbidX k) Build.east (Units.metresPerSecond 15) car ]
      map
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_263_o1
