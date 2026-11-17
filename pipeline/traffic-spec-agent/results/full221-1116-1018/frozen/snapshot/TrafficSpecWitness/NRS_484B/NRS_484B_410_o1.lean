/-
  Witnesses for NRS_484B_410_o1.

  Geometry (the witness's own figures; none appears in the rule):
  - a highway region 100, x ∈ [-100, 200], y ∈ [-10, 10]; an east-bound lane 50, x ∈ [-100, 200],
    y ∈ [-10, 0], in the branches that need a travel region; a curb zone 60, x ∈ [-10, 10],
    y ∈ [-10, -3], in the curb branches.
  - the subject (track 1), a car (half extents 2 × 1 × 1 m), stands at (0, -5) heading east:
    speed 0 at t = 0 s and 1 s (at rest under the 0.1 m/s tolerance), 1 m/s at t = 2 s (the start).
  - the closing car (track 2), in the subject's lane, east at 12 m/s, at x = -36, -24, -12 m:
    at the start its centre is 12 m behind, closing at 11 m/s, closest approach after ≈ 1.1 s
    (within the 3 s horizon) at centre distance 0 m (≤ 3 m).
  - three observations 1 s apart; every witness judges t = 1 s and 2 s (`window`), since the start
    is read against the previous observation.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_410_o1
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_410_o1

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (m 2, m 1, m 1)

/-- The subject: at rest at (0, -5) for k < 2, moving off east at 1 m/s at k = 2. -/
def subjectAt (k : Nat) : RoadUser :=
  if k < 2 then Build.user 1 [.motorVehicle] (m 0, m (-5)) Build.east (Units.metresPerSecond 0) carExtent
  else Build.user 1 [.motorVehicle] (m 0, m (-5)) Build.east (Units.metresPerSecond 1) carExtent

/-- A car in the subject's lane closing from behind at 12 m/s: 12 m behind at k = 2. -/
def closerAt (k : Nat) : RoadUser :=
  Build.user 2 [.motorVehicle] (m (12 * (k : Int) - 36), m (-5)) Build.east (Units.metresPerSecond 12) carExtent

def highway : Structure := Build.rect 100 .highway (m (-100)) (m (-10)) (m 200) (m 10)
def laneEast : Structure := Build.rect 50 .lane (m (-100)) (m (-10)) (m 200) (m 0)
def curbZone (kind : CurbZoneKind) (colour : CurbColour) : Structure :=
  { Build.rect 60 .curbZone (m (-10)) (m (-10)) (m 10) (m (-3)) with
    curbKind := some kind, curbColour := some colour }

/-- A no-parking regulatory sign governing the lane, with the given legend conditions. -/
def noParkingSign (conds : Conditions) : Device :=
  { Build.sign 10 .regulatorySign [50] with code := some .noParking, conditions := some conds }

/-- Sunday, 15 November 2026, 12:00. -/
def sundayNoon : Env :=
  { civilTime := some { year := 2026, month := 11, day := 15, weekday := 6, minuteOfDay := 720 } }

/-- `forbid` (violated): The subject car stands at the curb on a highway for 20 s, outside any no-parking zone, then starts (speed rises above the tolerance) while another car 12 m behind it in the same lane closes at 12 m/s, so their centres are predicted to meet within the horizon. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, closerAt k ]
      [ highway ]
      [ ]

/-- `permit` (compliant): The subject car stands at the curb on a highway and starts; no other road user is in the scene. -/
def permitTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k ]
      [ highway ]
      [ ]

/-- `idle` (not_applicable): The subject car drives along the highway at 12 m/s throughout and never halts. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m (12 * (k : Int) - 50), m (-5)) Build.east (Units.metresPerSecond 12) carExtent ]
      [ highway ]
      [ ]

/-- `blind` (unknown): The subject car stands at the curb and then moves off, but kin.speed is not observed on this source, so whether it was halted and started cannot be decided. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (subjectAt k) (fun kn => { kn with speed := none }), closerAt k ]
      [ highway ]
      [ ]

/-- `branch_1` (not_applicable): The subject car halted in a curb zone of kind no_parking painted red starts while another car 12 m behind closes at 12 m/s: the exception holds. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, closerAt k ]
      [ highway, curbZone .noParking .red ]
      [ ]

/-- `branch_2` (not_applicable): halted at a red-painted curb of kind restricted_parking (the colour alone marks no parking), starts with a car closing behind: the exception holds. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, closerAt k ]
      [ highway, curbZone .restrictedParking .red ]
      [ ]

/-- `branch_3` (not_applicable): halted in an unpainted curb zone of kind no_parking (the kind alone), starts with a car closing behind: the exception holds. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, closerAt k ]
      [ highway, curbZone .noParking CurbColour.none ]
      [ ]

/-- `branch_4` (not_applicable): halted in a lane governed by an unconditional no-parking sign, starts with a car closing behind: the exception holds. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, closerAt k ]
      [ highway, laneEast ]
      [ noParkingSign {} ]

/-- `branch_5` (violated): halted in a lane whose no-parking sign applies on weekdays 08:00–18:00 only, on a Sunday at noon, starts with a car closing behind: the sign's conditions do not hold, so the duty applies and is broken. -/
def branch_5Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k, closerAt k ]
      [ highway, laneEast ]
      [ noParkingSign { windows := [{ weekdays := [0, 1, 2, 3, 4], startMinute := 480, endMinute := 1080 }] } ]
      (env := sundayNoon)

/-- `branch_6` (compliant): halted on the highway, starts while a car passes east at 12 m/s in the next lane 5 m to its left: their centres approach within the horizon but stay 5 m apart, beyond the clearance. -/
def branch_6Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ subjectAt k
      , Build.user 2 [.motorVehicle] (m (12 * (k : Int) - 36), m 0) Build.east (Units.metresPerSecond 12) carExtent ]
      [ highway ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_410_o1"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (1000, 2000)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .notApplicable
  , witness "branch_2" branch_2Trace .notApplicable
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .compliant ]

end TrafficSpecWitness.NRS_484B_410_o1
