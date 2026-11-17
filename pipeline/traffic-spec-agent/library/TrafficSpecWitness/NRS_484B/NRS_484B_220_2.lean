/-
  Witnesses for NRS_484B_220_2.

  Geometry: a roundabout region `10`, the square (-30,-30)–(30,30), its reference point (the centre
  of its central island) at (0,0). The subject, track 1, a motor vehicle of half-extent
  2.5 × 1 × 0.75 m, stands at (0,-15), 15 m south of the centre, inside the roundabout, for three
  observations 1 s apart (held at the same place: the rule reads one observation at a time).
  - forbid: heading west at 6 m/s, velocity (-6,0): d = (0,-15), d × v = -90 < 0 and
    90² = 8100 > 0.26²·225·36 ≈ 547.6: clockwise, centre on its right. Speed 6 ≫ 0.1 m/s.
  - permit: heading east at 6 m/s, velocity (6,0): d × v = +90, counter-clockwise.
  - idle: the subject drives east on a straight roadway `20`, (-100,-200)–(100,-190), at (0,-195);
    the roundabout `10` exists but the subject's footprint is 160 m away from it.
  - blind: as forbid, with the subject's velocity unobserved (masked, and the field left `none`).
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_220_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_220_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def halfExtent : Q × Q × Q := (cm 250, m 1, cm 75)

/-- The roundabout, its reference point at the centre of its central island. -/
def roundabout : Structure :=
  { Build.rect 10 .roundabout (m (-30)) (m (-30)) (m 30) (m 30) with position := some (m 0, m 0) }

/-- A straight roadway well away from the roundabout. -/
def straightRoadway : Structure :=
  Build.rect 20 .roadway (m (-100)) (m (-200)) (m 100) (m (-190))

def subjectAt (pos : Vec) (heading : Vec) : RoadUser :=
  Build.user 1 [.motorVehicle] pos heading (Units.metresPerSecond 6) halfExtent

/-- `forbid` (violated): The subject occupies a st.roundabout whose reference point is at (0,0); at kin.position (0,-15) it moves with kin.velocity (-6,0) m/s: the centre is on its right and it turns clockwise. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m 0, m (-15)) Build.west ]
      [ roundabout ]
      [ ]

/-- `permit` (compliant): At kin.position (0,-15) in the roundabout the subject moves with kin.velocity (6,0) m/s: counter-clockwise, island on its left. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m 0, m (-15)) Build.east ]
      [ roundabout ]
      [ ]

/-- `idle` (not_applicable): The subject occupies no roundabout; it drives on a straight roadway. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ subjectAt (m 0, m (-195)) Build.east ]
      [ roundabout, straightRoadway ]
      [ ]

/-- `blind` (unknown): The subject occupies the roundabout but its kin.velocity is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ Build.withKin (subjectAt (m 0, m (-15)) Build.west) (fun k => { k with velocity := none }) ]
      [ roundabout ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_220_2"
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
  , witness "blind" blindTrace (.unknown []) ["kin.velocity"] ]

end TrafficSpecWitness.NRS_484B_220_2
