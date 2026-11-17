/-
  Witnesses for NRS_484B_307_7a_o3.

  Geometry (the witness's own figures; none appears in the rule):
  - intersection i (region 10): the square (0,0)–(20,20);
  - left-turn lane c (region 11): x 10–13 m, y −30–0 m, northbound, its entrance end at i;
  - signal head s (device 20) governs c;
  - the subject (track 1) is a passenger car (half-length 2 m, half-width 1 m) travelling north in
    c and into i; the other car (track 2) is an oncoming car travelling south through i at 11 m/s
    on the line x = 9.8 m, 1.2 m to the subject's left.
  Reading: p.conflict_horizon 3 s, p.conflict_centre_clearance 3 m, p.halt_speed_tolerance 0.1 m/s.
  forbid: at 0 s the closest approach of the centres lies 0.9 s ahead at 1.2 m, at 0.5 s 0.4 s ahead
  at 1.2 m, the subject at 6 m/s; the bodies never touch in the recorded instants.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_307_7a_o3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_307_7a_o3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, cm 75)

def intersectionI : Structure := Build.rect 10 .intersection (m 0) (m 0) (m 20) (m 20)

def laneC : Structure :=
  Build.lane 11 [(m 10, m (-30)), (m 13, m (-30)), (m 13, m 0), (m 10, m 0)] Build.north
    (enters := some 10)

def structures : List Structure := [intersectionI, laneC]

def headFya : Device := Build.signal 20 [11] [.circularGreen, .flashingYellowArrow .left]
def headGreenArrow : Device := Build.signal 20 [11] [.greenArrow .left]
def headRed : Device := Build.signal 20 [11] [.circularRed]

/-- The subject at (11 m, y cm), heading north. -/
def subjectAt (y : Int) (speed : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm 1100, cm y) Build.north speed carExtent

/-- The oncoming car at (9.8 m, y cm), heading south at 11 m/s. -/
def oncomingAt (y : Int) : RoadUser :=
  Build.user 2 [.motorVehicle] (cm 980, cm y) Build.south (Units.metresPerSecond 11) carExtent

/-- `forbid` (violated): Head s governing left-turn lane c displays circular_green with flashing_yellow_arrow(left); an oncoming car already inside i proceeds straight at 11 m/s; the car turns left across its path at 6 m/s, the closest approach of their centres 0.9 s ahead at 1.2 m. -/
def forbidTrace : Trace :=
  Build.trace 2 0 (Units.milliseconds 500) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-400 + 300 * (k : Int)) (Units.metresPerSecond 6)
      , oncomingAt (1130 - 550 * (k : Int)) ]
      structures
      [ headFya ]

/-- `permit` (compliant): Same signal; no other road user is in the scene; the car turns left through i. The duty binds the subject alone and is met. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ match k with
        | 0 => subjectAt (-400) (Units.metresPerSecond 6)
        | 1 => subjectAt 200 (Units.metresPerSecond 6)
        | _ => Build.user 1 [.motorVehicle] (m 8, m 8) Build.west (Units.metresPerSecond 6) carExtent ]
      structures
      [ headFya ]

/-- `idle` (not_applicable): s displays green_arrow(left) alone; the car turns left past an oncoming car. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ match k with
        | 0 => subjectAt (-400) (Units.metresPerSecond 6)
        | 1 => subjectAt 200 (Units.metresPerSecond 6)
        | _ => Build.user 1 [.motorVehicle] (m 8, m 8) Build.west (Units.metresPerSecond 6) carExtent
      , Build.user 2 [.motorVehicle] (m 7, m (18 - 11 * (k : Int))) Build.south
          (Units.metresPerSecond 11) carExtent ]
      structures
      [ headGreenArrow ]

/-- `blind` (unknown): As forbid, but the source supplies no velocity-derived speed for the turning car: whether it moved on toward the oncoming car is unknown. -/
def blindTrace : Trace := forbidTrace

/-- `branch_1` (violated): the subject enters i from c while s shows the flashing yellow arrow; one
    second later, inside i, s shows circular_red only and the oncoming car, now inside i, is 0.65 s
    from a closest approach at 1.2 m — the duty binds through the entry (the `since` limb). -/
def branch1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-300 + 600 * (k : Int)) (Units.metresPerSecond 6)
      , oncomingAt (2500 - 1100 * (k : Int)) ]
      structures
      [ if k == 0 then headFya else headRed ]

/-- `branch_2` (compliant): the subject waits at rest in c under the flashing yellow arrow while the
    oncoming car passes through i toward it: the centres approach within the horizon below the
    clearance, but the subject does not move on and the bodies do not touch. -/
def branch2Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt (-300) Q.zero
      , oncomingAt (1800 - 1100 * (k : Int)) ]
      structures
      [ headFya ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_307_7a_o3"
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
  , witness "branch_1" branch1Trace .violated
  , witness "branch_2" branch2Trace .compliant ]

end TrafficSpecWitness.NRS_484B_307_7a_o3
