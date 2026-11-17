/-
  Witnesses for NRS_484B_220_1.

  Geometry: a straight roadway region 10 spanning x ∈ [0, 200] m, y ∈ [0, 8] m. In forbid, permit
  and blind it is a one-way roadway designated east (1,0); in idle it is a two-way roadway
  (kind `roadway`, not a one-way roadway). The subject (track 1, a motor vehicle, half-extent
  2.5 × 1 × 0.75 m) sits at y = 4 m and moves 8 m/s, per second of a 3-instant trace: in forbid
  westward (velocity (-8,0), far beyond the 0.1 m/s tolerance), in permit and blind eastward
  ((8,0), component along the direction +8 m/s), in idle westward. No look-back: no window.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_220_1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_220_1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

/-- The roadway, of the given kind, with a designated direction east. -/
def roadway (kind : StructureKind) : Structure :=
  { Build.rect 10 kind (m 0) (m 0) (m 200) (m 8) with
    lane := some { direction := some Build.east } }

/-- The subject at instant k, moving along `heading` at 8 m/s from x0. -/
def subjectAt (x0 : Int) (heading : Vec) (k : Nat) : RoadUser :=
  Build.user 1 [.motorVehicle]
    (Q.add (m x0) (Q.mul heading.1 (m (8 * (k : Int)))), m 4)
    heading (Units.metresPerSecond 8) (cm 250, m 1, cm 75)

/-- `forbid` (violated): The subject occupies a st.one_way_roadway whose st.lane_direction is (1,0) and moves with kin.velocity (-8,0) m/s. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt 150 Build.west k ]
      [ roadway .oneWayRoadway ]
      [ ]

/-- `permit` (compliant): The subject occupies the same one-way roadway and moves with kin.velocity (8,0) m/s. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt 50 Build.east k ]
      [ roadway .oneWayRoadway ]
      [ ]

/-- `idle` (not_applicable): The subject occupies a two-way st.roadway (not a one-way roadway) and moves in either direction. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt 150 Build.west k ]
      [ roadway .roadway ]
      [ ]

/-- `blind` (unknown): The subject occupies a one-way roadway whose st.lane_direction the source does not supply, moving at 8 m/s. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt 50 Build.east k ]
      [ roadway .oneWayRoadway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_220_1"
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
  , witness "blind" blindTrace (.unknown []) ["st.lane_direction"] ]

end TrafficSpecWitness.NRS_484B_220_1
