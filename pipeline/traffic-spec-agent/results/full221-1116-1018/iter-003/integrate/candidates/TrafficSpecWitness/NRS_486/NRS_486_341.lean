/-
  Witnesses for NRS_486_341.

  Geometry (the witness's own figures, none of them in the rule): a highway (region 10) spanning
  x 0…400 m, y −10…10 m; two eastbound lanes, lane 11 (y 0…4, the motorcycle's lane L) and lane 12
  (y −4…0, the adjacent lane). The subject (track 1) is a car of half-extent 2.3 × 1.0 m, the
  motorcycle (track 2) half-extent 1.0 × 0.4 m. Both move east at 10 m/s over three instants
  1 s apart; occupancy is derived from the reference points.
  - side by side: car centre x, motorcycle centre x + 1 m → longitudinal overlap 2 m;
  - behind: motorcycle 20 m ahead → overlap negative (−16.7 m).
-/
import TrafficSpec.Rules.NRS_486.NRS_486_341
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_486_341

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highway : Structure := Build.rect 10 .highway (m 0) (m (-10)) (m 400) (m 10)
def laneL : Structure :=
  Build.lane 11 [(m 0, m 0), (m 400, m 0), (m 400, m 4), (m 0, m 4)] Build.east none (some 12)
def laneAdj : Structure :=
  Build.lane 12 [(m 0, m (-4)), (m 400, m (-4)), (m 400, m 0), (m 0, m 0)] Build.east (some 11) none
def structures : List Structure := [highway, laneL, laneAdj]

def carExt : Q × Q × Q := (cm 230, m 1, cm 75)
def motoExt : Q × Q × Q := (m 1, cm 40, cm 70)

/-- The car (or, in `idle`, a bicycle) at x 50 + 10k, lateral `y`. -/
def subjectAt (cls : List RoadUserClass) (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 cls (Q.add (m 50) (m (10 * (k : Int))), y) Build.east (Units.metresPerSecond 10) carExt

/-- The motorcycle at x 50 + dx + 10k, in lane L (y 3). -/
def motoAt (k : Nat) (dx : Int) : RoadUser :=
  Build.user 2 [.motorcycle] (Q.add (m (50 + dx)) (m (10 * (k : Int))), m 3) Build.east
    (Units.metresPerSecond 10) motoExt

/-- `forbid` (violated): A car occupies lane L of a highway beside a motorcycle also occupying L; rel.longitudinal_overlap of car and motorcycle 2 m. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.motorVehicle] k (m 1), motoAt k 1 ]
      structures
      [ ]

/-- `permit` (compliant): The car occupies lane L 20 m behind the motorcycle in L; rel.longitudinal_overlap negative. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.motorVehicle] k (m 2), motoAt k 20 ]
      structures
      [ ]

/-- `idle` (not_applicable): The subject is a bicycle beside the motorcycle in L; a bicycle is not a motor vehicle. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.bicycle] k (m 1), motoAt k 1 ]
      structures
      [ ]

/-- `blind` (unknown): A car is side by side with a motorcycle on a highway (rel.longitudinal_overlap 2 m), both bodies within lane L; which lanes and which highway each footprint occupies is not observed, so whether the car shares the motorcycle's lane is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.motorVehicle] k (m 1), motoAt k 1 ]
      structures
      [ ]

/-- `branch_1` (compliant): The car drives on the highway; no motorcycle or moped is in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.motorVehicle] k (m 1) ]
      structures
      [ ]

/-- `branch_2` (compliant): The car occupies the adjacent lane only, side by side with the motorcycle in L. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt [.motorVehicle] k (m (-2)), motoAt k 1 ]
      structures
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_486_341"
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
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_486_341
