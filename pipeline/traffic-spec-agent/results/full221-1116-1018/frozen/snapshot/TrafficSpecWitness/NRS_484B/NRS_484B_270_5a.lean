/-
  Witnesses for NRS_484B_270_5a.

  Every scene is an open street along +x (east); no structure is needed, since the rule reads only
  classes, speeds, positions, velocities and bodies. Three instants, one second apart (k = 0, 1, 2).
  Bodies: the car (track 1 unless stated) half-length 2.5 m, half-width 1 m; a bicycle, electric
  bicycle, electric scooter or moped (track 2) half-length 1 m, half-width 30 cm. Against the
  reading (halt tolerance 0.1 m/s, horizon 3 s, centre clearance 3 m):

  - forbid: car 10 m/s at x = 10k, y = 0; bicycle 4 m/s at x = 20 + 4k, y = −1. Gap closing at
    6 m/s: closest approach at 2.3 s (k = 1) and 1.3 s (k = 2), centre distance 1 m < 3 m. Bodies
    never touch (car front 22.5 m, bicycle rear 27 m at k = 2).
  - permit: car 12 m/s at x = 12k, y = 0; bicycle 4 m/s at x = 20 + 4k, y = −4. Closest approach at
    2.5, 1.5, 0.5 s, centre distance 4 m > 3 m; lateral body gap 2.7 m: it passes wide.
  - idle: the subject is an electric scooter (5 m/s, y = 0) beside a bicycle 4 m/s at y = −3.
  - blind: car and electric bicycle both 5 m/s side by side (y = 0, y = −3): equal velocities, no
    approach; rel.contact masked, and the rider's body extent unobserved, since Core computes
    rel.contact from the two footprints where no measured value is supplied.
  - branch_1: the car alone, 10 m/s.
  - branch_2: car and bicycle both 5 m/s, bicycle's centre at y = −1.2 m: the bodies overlap
    (contact) though the centres never approach → violated.
  - branch_3: the car halted at x = 10; a bicycle at 3 m/s rides toward its rear (x = 3k, y = 0),
    closest approach within 2.3 s and 1.3 s, 0 m — the subject is not moving → compliant.
  - branch_4: car 10 m/s at x = 10k; a bicycle at rest at x = 40, y = −1: approach within 2 s at
    1 m, but no one is riding → compliant.
  - branch_5: as forbid with an electric bicycle → violated.
  - branch_6: as forbid with a moped (no bicycle, electric bicycle or electric scooter) → compliant.

  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_270_5a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_270_5a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

def carExtent : Q × Q × Q := (cm 250, m 1, cm 75)
def bikeExtent : Q × Q × Q := (m 1, cm 30, cm 90)

/-- A road user heading east at `x` (cm), `y` (cm), speed `v` (cm/s). -/
def eastUser (track : TrackId) (cls : List RoadUserClass) (x y v : Int) (ext : Q × Q × Q) : RoadUser :=
  Build.user track cls (cm x, cm y) Build.east (Units.centimetres v) ext

def car (x y v : Int) : RoadUser := eastUser 1 [.motorVehicle] x y v carExtent
def rider (cls : RoadUserClass) (x y v : Int) : RoadUser := eastUser 2 [cls] x y v bikeExtent

def three (f : Int → List RoadUser) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (f (k : Int)) [] []

-- Binders ↦ tracks: subject ↦ 1

/-- `forbid` (violated): A moving car closes on a bicycle riding ahead in the same lane; their closest approach falls within p.conflict_horizon and below p.conflict_centre_clearance and the car does not slow. -/
def forbidTrace : Trace :=
  three fun k => [car (1000 * k) 0 1000, rider .bicycle (2000 + 400 * k) (-100) 400]

/-- `permit` (compliant): The car slows behind the moving bicycle and keeps a closest approach beyond p.conflict_centre_clearance, then passes with a wide berth; no contact. -/
def permitTrace : Trace :=
  three fun k => [car (1200 * k) 0 1200, rider .bicycle (2000 + 400 * k) (-400) 400]

/-- `idle` (not_applicable): The subject is an electric scooter (not a member of the motor vehicle aggregate) riding near a bicycle. -/
def idleTrace : Trace :=
  three fun k =>
    [eastUser 1 [.electricScooter] (500 * k) 0 500 bikeExtent, rider .bicycle (500 + 400 * k) (-300) 400]

/-- `blind` (unknown): A moving car passes alongside a riding electric bicycle with no conflicting closest approach; contact between bodies is not observed on this source. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ car (500 * (k : Int)) 0 500
      -- the source measures no contact and no body of the rider: rel.contact cannot be computed either
      , Build.withKin (rider .electricBicycle (500 * (k : Int)) (-300) 500) fun kn => { kn with extent := none } ]
      [] []
    -- without the rider's body, its occupancy is not observed either
    { s with occupancyObserved := [1] }

/-- `branch_1` (compliant): A moving car drives on an empty street: no bicycle, electric bicycle or electric scooter is in the scene. -/
def branch_1Trace : Trace :=
  three fun k => [car (1000 * k) 0 1000]

/-- `branch_2` (violated): car and bicycle ride side by side at one speed with their bodies overlapping (contact), centres never approaching. -/
def branch_2Trace : Trace :=
  three fun k => [car (500 * k) 0 500, rider .bicycle (500 * k) (-120) 500]

/-- `branch_3` (compliant): the car is halted; a riding bicycle closes on its rear — the subject is not moving. -/
def branch_3Trace : Trace :=
  three fun k => [car 1000 0 0, rider .bicycle (300 * k) 0 300]

/-- `branch_4` (compliant): a moving car closes on a bicycle at rest — no one is riding. -/
def branch_4Trace : Trace :=
  three fun k => [car (1000 * k) 0 1000, rider .bicycle 4000 (-100) 0]

/-- `branch_5` (violated): a moving car closes on a riding electric bicycle as in forbid. -/
def branch_5Trace : Trace :=
  three fun k => [car (1000 * k) 0 1000, rider .electricBicycle (2000 + 400 * k) (-100) 400]

/-- `branch_6` (compliant): a moving car closes on a moped as in forbid — not a bicycle, electric bicycle or electric scooter. -/
def branch_6Trace : Trace :=
  three fun k => [car (1000 * k) 0 1000, rider .moped (2000 + 400 * k) (-100) 400]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_270_5a"
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
  , witness "blind" blindTrace (.unknown []) ["rel.contact"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_270_5a
