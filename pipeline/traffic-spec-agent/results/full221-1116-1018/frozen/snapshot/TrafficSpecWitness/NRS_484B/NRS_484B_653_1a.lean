/-
  Witnesses for NRS_484B_653_1a.

  Geometry: a highway is a rectangle from (-100, -10) to (200, 10) m; the subject (track 1) is a
  motor vehicle of half-extent 2 m × 0.9 m × 0.75 m at (0, 0) heading east. Three scenes 1 s apart;
  the scene is held still across them (the rule reads no history).
    forbid:   50 m/s on the highway (reading bound 44.7 m/s), no acceleration.
    permit:   15 m/s, 1 m/s² on the highway; a pedestrian (track 2) 20 m behind it, the subject
              driving away from it, so no closest approach within 3 m.
    idle:     a farm way off any highway: the highway rectangle lies 500 m away, the subject is not
              in it, and the reading declares the place not public-access premises.
    blind:    alone on the highway, speed unobserved (kin.speed masked), no acceleration.
    branch_1: a public parking lot (assumption true, no highway): 5 m/s, accelerating at 5 m/s²
              (bound 4), a standing pedestrian 10 m dead ahead: centres meet in 2 s (horizon 3 s)
              at 0 m (clearance 3 m).
    branch_2: alone on the highway at 25 m/s, no acceleration.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_653_1a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_653_1a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, cm 90, cm 75)
def pedExtent : Q × Q × Q := (cm 30, cm 30, cm 90)

def highway : Structure := Build.rect 10 .highway (m (-100)) (m (-10)) (m 200) (m 10)
def farHighway : Structure := Build.rect 10 .highway (m (-100)) (m 490) (m 200) (m 510)

/-- The subject at (0, 0) heading east at `speed`, with longitudinal acceleration `accel`. -/
def car (speed accel : Q) : RoadUser :=
  Build.withKin (Build.user 1 [.motorVehicle] (m 0, m 0) Build.east speed carExtent)
    (fun k => { k with accelLongitudinal := some accel })

def pedestrian (x : Int) : RoadUser :=
  Build.user 2 [.pedestrian] (m x, m 0) Build.west (Units.metresPerSecond 0) pedExtent

/-- `forbid` (violated): A car on a highway travels at 50 m/s, above the exhibition speed. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 50) (Units.metresPerSecondSq 0) ]
      [ highway ]
      [ ]

/-- `permit` (compliant): A car on a highway travels at 15 m/s with gentle acceleration; no road user is in predicted conflict with it. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 15) (Units.metresPerSecondSq 1), pedestrian (-20) ]
      [ highway ]
      [ ]

/-- `idle` (not_applicable): A car on a private farm way, off any highway, with the reading declaring the place not premises to which the public has access. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 15) (Units.metresPerSecondSq 0) ]
      [ farHighway ]
      [ ]
      (assumptions := [("asm.public_access_premises", false)])

/-- `blind` (unknown): A car on a highway with no other road user in the scene, but the source does not supply its speed. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 15) (Units.metresPerSecondSq 0) ]
      [ highway ]
      [ ]

/-- `branch_1` (violated): A car in a public parking lot (asm.public_access_premises true) accelerates at 5 m/s^2 toward a pedestrian whose centre is predicted to come within the conflict clearance within the conflict horizon. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 5) (Units.metresPerSecondSq 5), pedestrian 10 ]
      [ ]
      [ ]
      (assumptions := [("asm.public_access_premises", true)])

/-- `branch_2` (compliant): A car alone on a highway at 25 m/s: no other road user in the scene, speed below the exhibition speed. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun _k t =>
    Build.scene t (some 1)
      [ car (Units.metresPerSecond 25) (Units.metresPerSecondSq 0) ]
      [ highway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_653_1a"
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
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated
  , witness "branch_2" branch_2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_653_1a
