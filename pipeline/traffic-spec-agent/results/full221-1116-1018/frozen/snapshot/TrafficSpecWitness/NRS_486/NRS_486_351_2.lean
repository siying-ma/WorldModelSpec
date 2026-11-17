/-
  Witnesses for NRS_486_351_2.

  Geometry: one lane L (region 100), a 200 m by 4 m rectangle running east from (0,0) to (200,4),
  direction east. Motorcycles are 2 m long, 0.8 m wide (half-extent 1 m, 0.4 m, 0.6 m); cars
  4 m long, 2 m wide (half-extent 2 m, 1 m, 0.75 m); the bicycle 1.8 m long. Three instants,
  1 s apart (t = 0, 1000, 2000 ms). Occupancy follows the reference points, all inside L.
  The subject (track 1) rides east at x = 40 + 5k m. Longitudinal overlap and heading alignment
  are computed by Core from the bodies; the reading's tolerance 0.9 is met by aligned headings
  (cosine 1) and broken by opposed ones (cosine -1).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_486.NRS_486_351_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_486_351_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def laneL : Structure :=
  Build.lane 100 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east

def motoExtent : Q × Q × Q := (m 1, cm 40, cm 60)
def carExtent : Q × Q × Q := (m 2, m 1, cm 75)
def bikeExtent : Q × Q × Q := (cm 90, cm 30, cm 60)

/-- The subject's x at instant k: 40 + 5k m. -/
def subjX (k : Nat) : Q := Q.add (m 40) (m (5 * k))

def subjectMoto (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorcycle] (subjX k, y) Build.east (Units.metresPerSecond 5) motoExtent

/-- `forbid` (violated): A motorcycle occupies lane L; a car travelling the opposite way also occupies L and comes abreast of it (rel.longitudinal_overlap 2 m at one observation): the car is of the vehicle aggregate, the headings are opposed so no consent shows (s5 fails) and the pair is not excused. -/
-- The car (track 2) runs west at x = 60 - 15k, y = 3: at k = 1 both centres are at x = 45, the
-- motorcycle's 2 m lies within the car's 4 m (overlap 2 m); at k = 0 and k = 2 they are apart.
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (m 1)
      , Build.user 2 [.motorVehicle] (Q.sub (m 60) (m (15 * k)), m 3) Build.west
          (Units.metresPerSecond 15) carExtent ]
      [ laneL ]
      [ ]

/-- `permit` (compliant): The motorcycle occupies L 15 m behind a car in L travelling the same way, overlap negative at every observation. -/
-- The car (track 2) runs east at x = 57 + 5k, y = 2: the gap between the projections is 14 m.
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (m 2)
      , Build.user 2 [.motorVehicle] (Q.add (m 57) (m (5 * k)), m 2) Build.east
          (Units.metresPerSecond 5) carExtent ]
      [ laneL ]
      [ ]

/-- `idle` (not_applicable): The subject is a bicycle (of none of the motorcycle, moped or trimobile aggregates) beside a car in L. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.bicycle] (subjX k, m 1) Build.east (Units.metresPerSecond 5) bikeExtent
      , Build.user 2 [.motorVehicle] (subjX k, m 3) Build.east (Units.metresPerSecond 5) carExtent ]
      [ laneL ]
      [ ]

/-- `blind` (unknown): A road user and a second road user both occupy L side by side, headings aligned, no third road user beside them; the road-user classes are not observed, so whether the subject is a motorcycle, moped or trimobile and whether the pair is a motorcycle-or-moped pair is unknown. -/
-- Two motorcycles side by side (y = 1 and y = 3, same x), ru.aggregate masked by the manifest.
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (m 1)
      , Build.user 2 [.motorcycle] (subjX k, m 3) Build.east (Units.metresPerSecond 5) motoExtent ]
      [ laneL ]
      [ ]

/-- `branch_1` (compliant): Two motorcycles ride side by side in L with headings aligned; no third vehicle beside them. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (m 1)
      , Build.user 2 [.motorcycle] (subjX k, m 3) Build.east (Units.metresPerSecond 5) motoExtent ]
      [ laneL ]
      [ ]

/-- `branch_2` (violated): Three motorcycles ride side by side in L with headings aligned. -/
-- At y = 0.7, 2 and 3.3 m, same x: three abreast.
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (cm 70)
      , Build.user 2 [.motorcycle] (subjX k, m 2) Build.east (Units.metresPerSecond 5) motoExtent
      , Build.user 3 [.motorcycle] (subjX k, cm 330) Build.east (Units.metresPerSecond 5) motoExtent ]
      [ laneL ]
      [ ]

/-- `branch_3` (compliant): The motorcycle rides alone in L; no other vehicle in the scene. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (m 2) ]
      [ laneL ]
      [ ]

/-- `branch_4` (violated): Two motorcycles are abreast in L with opposed headings (met head-on): no consent shows and the pair is not excused. -/
-- The other motorcycle (track 2) runs west at x = 50 - 5k, y = 3: abreast at k = 1 (x = 45).
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectMoto k (m 1)
      , Build.user 2 [.motorcycle] (Q.sub (m 50) (m (5 * k)), m 3) Build.west
          (Units.metresPerSecond 5) motoExtent ]
      [ laneL ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_486_351_2"
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
  , witness "blind" blindTrace (.unknown []) ["ru.aggregate"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .violated ]

end TrafficSpecWitness.NRS_486_351_2
