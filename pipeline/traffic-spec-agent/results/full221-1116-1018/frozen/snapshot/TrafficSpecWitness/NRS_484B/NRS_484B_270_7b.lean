/-
  Witnesses for NRS_484B_270_7b.

  Geometry (every figure is the witness's own and appears nowhere in the rule): a straight street
  along +x (east). Track 1 is the subject (a bicycle, half-extent 0.9 × 0.3 × 0.6 m; a moped of the
  same body in `idle`), track 2 the car passed (half-extent 2.25 × 0.9 × 0.75 m) on the line y = 0,
  heading east; track 3 an oncoming car (same body) heading west in `branch_2`. Instants k = 0 … 7
  at one-second spacing from t = 10 s; each trace is padded by repeating its first scene for 10 s
  before (car still well ahead) and its last scene for 2 s after, and `window` names the eight
  instants the witness speaks about.

  Bodies' projections on the subject's heading are disjoint when the centres are more than
  3.15 m apart along x. In the passes the car is ahead without overlap at k = 4 (4 m), alongside at
  k = 5, and behind without overlap at k = 6 (−4 m): the pass begins at k = 4 and is recognized at
  k = 6 (inside p.overtake_window = 10 s). Lateral offsets: y = 1.6 m gives a lateral gap between
  bodies of 0.4 m (below p.bicycle_pass_safe_gap = 1 m), y = 3 m one of 1.8 m (above it).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_7b
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_7b

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def bikeExt : Q × Q × Q := (cm 90, cm 30, cm 60)
def carExt : Q × Q × Q := (cm 225, cm 90, cm 75)

def t0 : Timestamp := 10000
def win : Option (Timestamp × Timestamp) := some (10000, 17000)

/-- The subject at (x, y) in centimetres, heading east. -/
def rider (cls : RoadUserClass) (x y : Int) (v : Int) : RoadUser :=
  Build.user 1 [cls] (cm x, cm y) Build.east (Units.metresPerSecond v) bikeExt

/-- The car passed, at x centimetres on y = 0, heading east. -/
def car (x : Int) (v : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm x, cm 0) Build.east (Units.metresPerSecond v) carExt

def ki (k : Nat) : Int := Int.ofNat k

/-- A pass of a car moving east at 2 m/s by a rider at 6 m/s on the line `y k` (cm). -/
def passTrace (cls : RoadUserClass) (y : Nat → Int) : Trace :=
  Build.pad
    (Build.trace 8 t0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        [ rider cls (600 * ki k) (y k) 6
        , car (2000 + 200 * ki k) 2 ]
        [ ] [ ])
    (Units.seconds 10) (Units.seconds 2) (Units.seconds 1)

/-- `forbid` (violated): A bicycle overtakes and passes a car moving slowly in the same direction, keeping a gap between bodies smaller than p.bicycle_pass_safe_gap while alongside. -/
def forbidTrace : Trace := passTrace .bicycle (fun _ => 160)

/-- `permit` (compliant): A bicycle overtakes and passes a slow car with a gap of at least p.bicycle_pass_safe_gap throughout the pass, no contact and no conflicting closest approach with any other road user. -/
def permitTrace : Trace := passTrace .bicycle (fun _ => 300)

/-- `idle` (not_applicable): The subject is a moped (outside the bicycle, electric bicycle and electric scooter aggregates, each of which leaves a moped out) overtaking and passing a car. -/
def idleTrace : Trace := passTrace .moped (fun _ => 160)

/-- No body extent observed: the source gives positions and headings, and measures the
    longitudinal overlap and the contact itself; it gives no gap between the bodies, and no
    occupancy (no footprint). -/
def noExtent (u : RoadUser) : RoadUser := Build.withKin u fun k => { k with extent := none }

/-- The overlap of the bodies' projections (cm) in the pass geometry: 3.15 m less the distance
    between the centres along x. -/
def blindOverlap (k : Nat) : Int :=
  let d := 2000 - 400 * ki k
  315 - (if d < 0 then -d else d)

/-- `blind` (unknown): A bicycle overtakes and passes a car with no conflict with other road users; the gap between bodies is not observed on this source.
    The permit geometry (y = 3 m, lateral gap 1.8 m), with the extents unobserved and the overlap,
    contact and gap supplied as measured relations from the bicycle to the car. -/
def blindTrace : Trace :=
  Build.pad
    (Build.trace 8 t0 (Units.seconds 1) fun k t =>
      Build.withRelations
        { Build.scene t (some 1)
            [ noExtent (rider .bicycle (600 * ki k) 300 6)
            , noExtent (car (2000 + 200 * ki k) 2) ]
            [ ] [ ] with occupancyObserved := [] }
        [ Build.relation 1 2 fun r =>
            { r with longitudinalOverlap := some (cm (blindOverlap k))
                     contact := some false } ])
    (Units.seconds 10) (Units.seconds 2) (Units.seconds 1)

/-- `branch_3` (violated): A bicycle begins the pass of a car with a wide gap, then closes to a gap below p.bicycle_pass_safe_gap while still alongside before clearing the car: the pass is safe for part of the act only. -/
def branch_3Trace : Trace := passTrace .bicycle (fun k => if k ≤ 4 then 300 else 160)

/-- Branch 4: the rider's x (cm) per instant: close behind the car (0.5 m gap) at k = 0 … 2,
    then out to y = 3 m and past it. -/
def b4x (k : Nat) : Int :=
  match k with
  | 0 => 1635
  | 1 => 1835
  | 2 => 2035
  | 3 => 2100
  | 4 => 2600
  | 5 => 3100
  | 6 => 3600
  | _ => 4100

/-- `branch_4` (compliant): A bicycle follows close behind a car with a small gap before the pass begins, then moves out and keeps a gap of at least p.bicycle_pass_safe_gap at every observation from the pass's beginning to its recognition. -/
def branch_4Trace : Trace :=
  Build.pad
    (Build.trace 8 t0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        [ rider .bicycle (b4x k) (if k ≤ 2 then 0 else 300) 4
        , car (2000 + 200 * ki k) 2 ]
        [ ] [ ])
    (Units.seconds 10) (Units.seconds 2) (Units.seconds 1)

/-- `branch_1` (compliant): A bicycle rides on a street with no motor vehicle in the scene. -/
def branch_1Trace : Trace :=
  Build.pad
    (Build.trace 8 t0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        [ rider .bicycle (600 * ki k) 300 6 ]
        [ ] [ ])
    (Units.seconds 10) (Units.seconds 2) (Units.seconds 1)

/-- `branch_2` (violated): A bicycle overtakes and passes a standing car with a wide gap, but during the pass an oncoming car comes into a closest approach with the bicycle within p.conflict_horizon and below p.conflict_centre_clearance.
    The car stands at x = 20 m; the bicycle rides at 4 m/s on y = 3 m (1.8 m from the car's body);
    the oncoming car runs west at 10 m/s on y = 5.5 m, 2.5 m centre-to-centre laterally from the
    bicycle; at k = 4 they are 4 m apart along x and closing at 14 m/s. -/
def branch_2Trace : Trace :=
  Build.pad
    (Build.trace 8 t0 (Units.seconds 1) fun k t =>
      Build.scene t (some 1)
        [ rider .bicycle (400 * ki k) 300 4
        , car 2000 0
        , Build.user 3 [.motorVehicle] (cm (6000 - 1000 * ki k), cm 550) Build.west
            (Units.metresPerSecond 10) carExt ]
        [ ] [ ])
    (Units.seconds 10) (Units.seconds 2) (Units.seconds 1)

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_7b"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := win
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_3" branch_3Trace .violated
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.NRS_484B_270_7b
