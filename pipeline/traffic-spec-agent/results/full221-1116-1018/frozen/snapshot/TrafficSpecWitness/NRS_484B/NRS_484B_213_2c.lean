/-
  Witnesses for NRS_484B_213_2c.

  Geometry (the witness's own figures, nowhere in the rule):
  - highway 10: x ∈ [-100, 200] m, y ∈ [-8, 8] m, carrying the sight distance of the place
    (100 m where the view is obstructed, 1000 m where it is not; the bound at 20 m/s and the
    reading's 11 s is 220 m).
  - centre line 11: x ∈ [-100, 200] m, y ∈ [-0.1, 0.1] m, lying on highway 10.
  - bridge 12 (elevated structure): x ∈ [20, 60] m, y ∈ [-8, 8] m, reference point (40, 0).
  - one-way roadway 13 (branch_1 only): covers the highway.
  - subject 1: a motor vehicle heading east at 20 m/s, half-extents 2.5 × 1 × 0.75 m, at
    x = 0, 5, 10 m over three instants 250 ms apart; its front stays at least 7.5 m from the
    bridge (well under 100 ft = 30.48 m) and its velocity points at the bridge's reference point.
    Left of the centre line (heading east) is y = +2 m; right is y = -2 m.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_213_2c
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_213_2c

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def subjectAt (k : Nat) (y : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m (5 * (Int.ofNat k)), y) Build.east (Units.metresPerSecond 20)
    (cm 250, m 1, cm 75)

def highway (sight : Option Q) : Structure :=
  { Build.rect 10 .highway (m (-100)) (m (-8)) (m 200) (m 8) with sightDistance := sight }

def centreLine : Structure :=
  { Build.rect 11 .centreLine (m (-100)) (cm (-10)) (m 200) (cm 10) with ways := some [10] }

def bridge : Structure :=
  { Build.rect 12 .elevatedStructure (m 20) (m (-8)) (m 60) (m 8) with position := some (m 40, m 0) }

def oneWay : Structure :=
  Build.rect 13 .oneWayRoadway (m (-100)) (m (-8)) (m 200) (m 8)

def approach (y : Q) (sight : Option Q) (extra : List Structure := []) : Trace :=
  Build.trace 3 0 (Units.milliseconds 250) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k y ]
      ([ highway sight, centreLine, bridge ] ++ extra)
      [ ]

/-- `forbid` (violated): The subject moves toward an st.elevated_structure within the stated 100 feet, st.sight_distance at its point below its speed times p.passing_sight_time, its reference point left of the centre line. -/
def forbidTrace : Trace := approach (m 2) (some (m 100))

/-- `permit` (compliant): The same approach with the subject right of the centre line. -/
def permitTrace : Trace := approach (m (-2)) (some (m 100))

/-- `idle` (not_applicable): The subject approaches a bridge within the stated distance with st.sight_distance far above the bound, left of the centre line. -/
def idleTrace : Trace := approach (m 2) (some (m 1000))

/-- `blind` (unknown): The subject approaches a bridge within the stated distance left of the centre line; st.sight_distance is not observed. -/
def blindTrace : Trace := approach (m 2) none

/-- `branch_1` (not_applicable): The same approach with short sight distance on an st.one_way_roadway. -/
def branch_1Trace : Trace := approach (m 2) (some (m 100)) [oneWay]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_213_2c"
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
  , witness "blind" blindTrace (.unknown []) ["st.sight_distance"]
  , witness "branch_1" branch_1Trace .notApplicable ]

end TrafficSpecWitness.NRS_484B_213_2c
