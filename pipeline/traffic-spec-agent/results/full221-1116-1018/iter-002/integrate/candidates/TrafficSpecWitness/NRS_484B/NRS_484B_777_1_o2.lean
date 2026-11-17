/-
  Witnesses for NRS_484B_777_1_o2.

  Geometry (the witness's own figures; none appears in the rule). Everything heads east.
  - The bicycle (track 1): half-length 1 m, half-width 0.3 m.
  - The car (track 2, motor vehicle): half-length 2 m, half-width 1 m, centre on y = 0 (its
    left side at y = 1 m), at x = v·k at instant k (v = 0 parked, v = 1 m/s moving).
  - The bicycle at x = -20 + (2 + v)·k: the car is clear ahead up to k = 8, side by side for
    k = 9, 10, 11 (bicycle centre within 3 m of the car's along the heading), clear behind from
    k = 12, where the pass is recognized; the act starts at k = 8.
  - The bicycle's y while side by side fixes the lateral gap: y = 1.7 m → 0.4 m, 2.8 m → 1.5 m,
    2.5 m → 1.2 m, 1.8 m → 0.5 m, 1.2 m → bodies overlap by 0.1 m (contact).
  - 15 instants, 1 s apart; the witnesses speak about the instants 10 s … 14 s, where the
    overtake window (10 s) behind is covered by the trace.
  - blind: as forbid, but the car's body (extent) is not observed, so Core cannot compute the
    gap; the overlap along the bicycle's heading and the absence of contact are supplied as the
    source's measurements (Core cannot compute them either), and the masked gap stays unknown.
  - Roadway: y ∈ [-6, 6] m; in branch_3 the roadway ends at y = 2 m with a sidewalk (the
    separate path) beyond it, in branch_4 at y = 1.5 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_777_1_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_777_1_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def bike (x y : Q) (speed : Int) : RoadUser :=
  Build.user 1 [.bicycle] (x, y) Build.east (Units.metresPerSecond speed) (m 1, cm 30, cm 60)

def car (x : Q) (speed : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, Q.zero) Build.east (Units.metresPerSecond speed) (m 2, m 1, cm 75)

def openRoadway : List Structure :=
  [ Build.rect 10 .roadway (m (-100)) (m (-6)) (m 100) (m 6) ]

def roadwayWithPath (edge : Q) : List Structure :=
  [ Build.rect 10 .roadway (m (-100)) (m (-6)) (m 100) edge
  , Build.rect 11 .sidewalk (m (-100)) edge (m 100) (m 8) ]

/-- A pass: the car at speed `v` (m/s), the bicycle 2 m/s faster, its y at instant k by `y`. -/
def passTrace (v : Int) (y : Nat → Q) (structures : List Structure) : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ bike (m (-20 + (2 + v) * (k : Int))) (y k) (2 + v), car (m (v * (k : Int))) v ]
      structures
      [ ]

/-- `forbid` (violated): A bicycle on a roadway overtakes and passes a car of the vehicle aggregate parked at the curb (at rest throughout), keeping a lateral body gap of 0.4 m while alongside it. -/
def forbidTrace : Trace := passTrace 0 (fun _ => cm 170) openRoadway

/-- `permit` (compliant): As forbid, but the bicycle keeps a lateral body gap of 1.5 m while alongside the parked car. -/
def permitTrace : Trace := passTrace 0 (fun _ => cm 280) openRoadway

/-- `idle` (not_applicable): A bicycle rides alone along a roadway and passes no road user: no pass is recognized. -/
def idleTrace : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ bike (m (-20 + 2 * (k : Int))) (cm 170) 2 ]
      openRoadway
      [ ]

/-- `blind` (unknown): As forbid, but the source does not observe the gap between bodies. -/
def blindTrace : Trace :=
  Build.trace 15 0 (Units.seconds 1) fun k t =>
    let x : Int := -20 + 2 * (k : Int)
    -- the source measures the car's position and heading but not its body: the overlap along the
    -- bicycle's heading and the absence of contact are supplied as measured, the gap is not
    let ov : Int := min (x + 1) 2 - max (x - 1) (-2)
    -- without a body the car's occupancy is not observed; the bicycle's is
    let s := Build.scene t (some 1)
        [ bike (m x) (cm 170) 2, Build.withKin (car (m 0) 0) fun kn => { kn with extent := none } ]
        openRoadway
        [ ]
    Build.withRelations
      { s with occupancyObserved := [1], occupies := s.occupies.filter (·.1 == 1) }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (m ov), contact := some false } ]

/-- `branch_1` (compliant): A bicycle on a roadway passes a car moving slowly the same way, keeping a lateral body gap of 1.2 m while alongside it. -/
def branch_1Trace : Trace := passTrace 1 (fun _ => cm 250) openRoadway

/-- `branch_2` (violated): A bicycle on a roadway passes a car moving slowly the same way, touching its mirror while alongside it. -/
def branch_2Trace : Trace := passTrace 1 (fun k => if 9 ≤ k ∧ k ≤ 11 then cm 120 else cm 250) openRoadway

/-- `branch_3` (violated): A bicycle rides on a separate path beside the roadway as the pass of a parked car begins and moves onto the roadway part way through the pass, keeping a lateral body gap of 0.4 m while alongside the car: the subject was on the roadway at some observation of the pass. -/
def branch_3Trace : Trace :=
  passTrace 0 (fun k => if k ≤ 8 then m 3 else cm 170) (roadwayWithPath (m 2))

/-- `branch_4` (not_applicable): A bicycle rides on the roadway, then moves onto a separate path off the roadway before the parked car comes ahead of it, and passes the car from the path with a lateral body gap of 0.4 m: it was on the roadway only before the pass began. -/
def branch_4Trace : Trace :=
  passTrace 0 (fun k => if k ≤ 2 then m 1 else cm 170) (roadwayWithPath (cm 150))

/-- `branch_5` (violated): A bicycle on a roadway passes a car moving slowly the same way, keeping a lateral body gap of 0.5 m (no contact) while alongside it: the moving-vehicle clearance is broken. -/
def branch_5Trace : Trace := passTrace 1 (fun _ => cm 180) openRoadway

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_777_1_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (10000, 14000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_777_1_o2
