/-
  Witnesses for NRS_484B_127_3.

  A straight highway (region 10) runs east from x = 0 to x = 2000 m, 20 m wide; one eastbound lane
  (region 11) 4 m wide lies on it, centred on y = 0. Cars are 4 m long and 2 m wide. Every trace has
  three instants one second apart and every car moves east at 25 m/s, so its position advances
  25 m per instant. Against the reading's values the bound is 22.4 m + 2 × 1.0 s × 25 m/s = 72.4 m.
  - forbid: the follower x (track 1) starts at 100 m, the leader (track 2) at 109 m: the surface gap
    is 5 m, about one car length, far below the bound.
  - permit: the leader starts at 250 m: the surface gap is 146 m, well above the bound.
  - idle, branch_2: the forbid geometry, with the stated assumption false.
  - blind: the forbid geometry, but the source reports no extent for the leader (so no footprint
    and no occupancy for it) and measures the gap (5 m) and the leader's place ahead in x's lane
    itself; the manifest masks the gap measurement, so the gap is unknown and nothing else.
  - branch_1: x alone on the highway.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_127_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_127_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def cruise : Q := Units.metresPerSecond 25
def carHalf : Q × Q × Q := (m 2, m 1, cm 75)

def highway : Structure := Build.rect 10 .highway (m 0) (m (-10)) (m 2000) (m 10)
def lane : Structure :=
  Build.lane 11 [(m 0, m (-2)), (m 2000, m (-2)), (m 2000, m 2), (m 0, m 2)] Build.east
def road : List Structure := [highway, lane]

/-- A car on the lane's centre line at `x0` metres at instant 0, moving east at cruising speed. -/
def car (track : TrackId) (x0 : Int) (k : Nat) : RoadUser :=
  Build.user track [.motorVehicle] (m (x0 + 25 * (k : Int)), m 0) Build.east cruise carHalf

def assumptionsWith (outside caravan : Bool) : List (AsmId × Bool) :=
  [("asm.outside_business_district", outside), ("asm.caravan_or_motorcade", caravan)]

/-- Two cars, the leader starting `leadX0` metres along the highway, the follower x at 100 m. -/
def pairTrace (leadX0 : Int) (outside caravan : Bool) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 1 100 k, car 2 leadX0 k] road []
      (assumptions := assumptionsWith outside caravan)

/-- `forbid` (violated): Two cars travel one behind the other in the same lane of a highway at cruising speed; asm.caravan_or_motorcade and asm.outside_business_district are true; the follower's rel.surface_gap to the leader is about one car length, below the bound. -/
def forbidTrace : Trace := pairTrace 109 true true

/-- `permit` (compliant): As forbid, with the follower's surface gap well above the design length plus both headways at its speed. -/
def permitTrace : Trace := pairTrace 250 true true

/-- `idle` (not_applicable): As forbid, with asm.outside_business_district false (the stretch is in a business district). -/
def idleTrace : Trace := pairTrace 109 false true

/-- `blind` (unknown): As forbid, with rel.surface_gap declared absent by the source. The source
    reports no body extent for the leader, so Core can compute neither the gap nor the leader's
    occupancy from footprints; it measures the gap itself (5 m along x's heading) and that the
    leader is ahead of x in its lane, and the manifest masks the gap measurement only. -/
def blindScene (k : Nat) (t : Timestamp) : Scene :=
  let s := Build.scene t (some 1)
    [car 1 100 k, Build.withKin (car 2 109 k) fun kn => { kn with extent := none }] road []
    (assumptions := assumptionsWith true true)
  Build.withRelations { s with occupancyObserved := [1], occupies := [(1, 10), (1, 11)] }
    [ Build.relation 1 2 fun r => { r with surfaceGap := some (m 5, m 0) }
    , Build.relation 2 1 fun r => { r with aAheadOfB := some true } ]

def blindTrace : Trace := Build.trace 3 0 (Units.seconds 1) fun k t => blindScene k t

/-- `branch_1` (compliant): A single car moves on the highway with both assumptions true and no road user ahead of it in its lane: the duty binds it and is met. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) [car 1 100 k] road []
      (assumptions := assumptionsWith true true)

/-- `branch_2` (not_applicable): As forbid, with asm.caravan_or_motorcade false. -/
def branch_2Trace : Trace := pairTrace 109 true false

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_127_3"
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
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_127_3
