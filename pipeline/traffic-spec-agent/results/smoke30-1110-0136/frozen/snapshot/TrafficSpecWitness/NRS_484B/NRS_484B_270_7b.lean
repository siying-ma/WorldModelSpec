/-
  Witnesses for NRS_484B_270_7b.

  Geometry: a straight road along +x (east), no structures (the rule reads none). Three instants
  one second apart. The rider (track 1, half-extent 1 m × 0.3 m) starts at (0, 0) heading east at
  7 m/s; the car (track 2, half-extent 2 m × 1 m) starts at (2, ·) heading east at 5 m/s, so the
  rider's centre is 2 m behind, level with, then 2 m ahead of the car's: the footprints overlap
  along the rider's heading at every instant and the rider gains 2 m/s on the car.
  - close pass: car centre 1.5 m to the left, its right side at 0.5 m, the rider's left at 0.3 m —
    a lateral gap of 0.2 m;
  - ample pass: car centre 3.3 m to the left — a lateral gap of 2.0 m;
  - branch_1: a truck (track 3) at y = −2.5 m heading west at 10 m/s, starting 40 m ahead: the
    rider and the truck close at 17 m/s, the predicted closest approach lies 2.4 s, 1.4 s and
    0.4 s ahead at a centre distance of 2.5 m.
  - blind: the close pass, but the source gives no extent for the car, so no gap can be computed
    from footprints; it supplies the overlap along the rider's heading (1 m, 2 m, 1 m) measured.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_7b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_7b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: x ↦ 1

/-- The rider at instant `k`, of the given class. -/
def rider (cls : RoadUserClass) (k : Nat) : RoadUser :=
  Build.user 1 [cls] (m (7 * (k : Int)), Q.zero) Build.east (mps 7) (m 1, cm 30, m 1)

/-- The car at instant `k`, its centre `lat` to the left of the rider's line. -/
def car (lat : Q) (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (2 + 5 * (k : Int)), lat) Build.east (mps 5) (m 2, m 1, cm 75)

/-- The truck coming head-on at instant `k`. -/
def truck (k : Nat) : RoadUser :=
  Build.user 3 [.truck] (m (40 - 10 * (k : Int)), cm (-250)) Build.west (mps 10) (m 5, cm 125, cm 200)

/-- `forbid` (violated): A bicycle travels beside a car in the same direction, footprints overlapping along its heading, 2 m/s faster than the car, with the lateral surface gap between them well below the lateral clearance; no other road user is present. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .bicycle k, car (cm 150) k ]
      [ ]
      [ ]

/-- `permit` (compliant): The same pass with a lateral surface gap above the lateral clearance and no other road user in predicted conflict. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .bicycle k, car (cm 330) k ]
      [ ]
      [ ]

/-- `idle` (not_applicable): An electric scooter rides alone on the road; no motor vehicle is present, so nothing is overtaken. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .electricScooter k ]
      [ ]
      [ ]

/-- The measured overlap along the rider's heading at instant `k` of the close pass (1 m, 2 m, 1 m). -/
def blindOverlap (k : Nat) : Q := if k == 1 then m 2 else m 1

/-- `blind` (unknown): An electric bicycle overtakes a car side by side; the source does not supply surface gaps. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ rider .electricBicycle k
      , Build.withKin (car (cm 150) k) fun kin => { kin with extent := none } ]
      [ ]
      [ ]
    -- without a footprint the car's occupancy is not observed
    Build.withRelations { s with occupancyObserved := [1] }
      [ Build.relation 1 2 fun r => { r with longitudinalOverlap := some (blindOverlap k) } ]

/-- `branch_1` (violated): A bicycle overtakes a car with an ample lateral gap while a truck approaching head-on is predicted to come within the conflict clearance of the bicycle within the horizon. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ rider .bicycle k, car (cm 330) k, truck k ]
      [ ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_7b"
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
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_7b
