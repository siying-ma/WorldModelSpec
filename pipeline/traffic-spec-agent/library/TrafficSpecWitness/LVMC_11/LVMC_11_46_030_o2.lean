/-
  Witnesses for LVMC_11_46_030_o2.

  Geometry (the witness's own figures, none in the rule):
  - highway w (region 10): x 0..200 m, y -6..10 m;
  - lane g (region 20): x 0..200 m, y 0..4 m, direction east, on w;
  - crosswalk c (region 30): x 100..104 m, y -6..10 m, on w, marked;
  - in branch_4 only, a nearer crosswalk c1 (region 31): x 70..74 m, on w.
  - The subject (track 1) is a passenger car (motor_vehicle), half extents 2.25 × 0.9 × 0.75 m,
    heading east at y = 2 m. Halted at x = 60 m its front is at 62.25 m: 37.75 m from c (well over
    fifty feet = 15.24 m), 7.75 m from c1 (well under).
  - Devices: a school crossing guard (device 100, human_direction) or a crossing warning signal
    (device 101), each governing g.
  - Instants 1 s apart; "halted" is speed 0, "moving" at least 1.4 m/s (tolerance 0.1 m/s).
  - Every trace that should apply starts with the subject already halted under the warning, so the
    `since` is decided at the first instant (no truncated past).
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_46_030_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_46_030_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def highwayW : Structure := Build.rect 10 .highway (m 0) (m (-6)) (m 200) (m 10)

def laneG : Structure :=
  { Build.lane 20 [(m 0, m 0), (m 200, m 0), (m 200, m 4), (m 0, m 4)] Build.east with
      ways := some [10] }

def crosswalkAt (id : Nat) (x : Int) : Structure :=
  { Build.rect id .crosswalk (m x) (m (-6)) (m (x + 4)) (m 10) with
      ways := some [10], marked := some true }

def street : List Structure := [highwayW, laneG, crosswalkAt 30 100]

/-- The subject at x (cm) along the lane, speed in cm/s. -/
def car (xcm speedCm : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (cm xcm, m 2) Build.east (cm speedCm) (cm 225, cm 90, cm 75)

def guard (ind : HumanIndication) : Device :=
  { Build.device 100 .humanDirection [20] with
      humanRole := some .schoolCrossingGuard, humanIndication := some ind }

def warningSignal (on : Bool) : Device :=
  { Build.device 101 .crossingWarningSignal [20] with active := some on }

/-- The subject's (x cm, speed cm/s) at instant k: halted at 60 m, then moving on. -/
def haltThenGo (k : Nat) : Int × Int :=
  match k with
  | 0 => (6000, 0)
  | 1 => (6140, 140)
  | _ => (6280, 140)

/-- Halted for two instants, then moving on. -/
def haltTwiceThenGo (k : Nat) : Int × Int :=
  match k with
  | 0 => (6000, 0)
  | 1 => (6000, 0)
  | 2 => (6140, 140)
  | _ => (6280, 140)

/-- `forbid` (violated): Street w with lane g (direction east) and crosswalk c ahead; a school crossing guard (dev.human_direction, role school_crossing_guard, indication stop) governs g. The subject, a passenger car (ru.motor_vehicle), halts with its body farther than fifty feet from c while the guard indicates stop, then moves on at walking pace towards c while the guard still indicates stop. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let p := haltThenGo k
    Build.scene t (some 1) [car p.1 p.2] street [guard .stop]

/-- `permit` (compliant): As in forbid, but the subject stays at rest while the guard indicates stop and moves on only after the guard's indication becomes proceed. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let p := haltTwiceThenGo k
    Build.scene t (some 1) [car p.1 p.2] street [guard (if k < 2 then .stop else .proceed)]

/-- `idle` (not_applicable): Same street, no warning device and no person directing traffic; the subject halts briefly short of c and drives on. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let p := haltThenGo k
    Build.scene t (some 1) [car p.1 p.2] street []

/-- `blind` (unknown): As in forbid, but the source does not observe what devices govern (dev.governs absent): whether the guard's warning applies to the subject's lane is unknown. -/
def blindTrace : Trace :=
  -- The guard indicates proceed at the first instant (so the past the `since` reads is decided),
  -- then stop; the subject halts under it, then moves on. What the guard governs is in the scene
  -- but masked by the manifest: only that atom leaves the verdict open.
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let p : Int × Int :=
      match k with
      | 0 => (6000, 0)
      | 1 => (6000, 0)
      | 2 => (6140, 140)
      | _ => (6280, 140)
    Build.scene t (some 1) [car p.1 p.2] street [guard (if k == 0 then .proceed else .stop)]

/-- `branch_1` (compliant): As in forbid's first part, then the guard leaves the scene (no dev.human_direction any more) and the subject drives on through c. -/
def branch_1Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let p : Int × Int :=
      match k with
      | 0 => (6000, 0)
      | 1 => (6000, 0)
      | 2 => (8000, 1000)
      | _ => (10100, 1000)
    Build.scene t (some 1) [car p.1 p.2] street (if k < 2 then [guard .stop] else [])

/-- `branch_2` (violated): A dev.crossing_warning_signal governing g is active; the subject halts farther than fifty feet from c, then moves on while the signal is still active. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let p := haltThenGo k
    Build.scene t (some 1) [car p.1 p.2] street [warningSignal true]

/-- `branch_3` (compliant): As in branch_2, but the subject moves on only after the signal's active attribute becomes false. -/
def branch_3Trace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    let p := haltTwiceThenGo k
    Build.scene t (some 1) [car p.1 p.2] street [warningSignal (k < 2)]

/-- `branch_4` (not_applicable): a nearer crosswalk c1 lies ahead before c; the guard turns to stop,
    the subject halts less than fifty feet from c1 (though more than fifty feet from c) and moves on
    while the guard still indicates stop: the halt is not the one this duty follows, since the
    nearest crosswalk ahead is c1. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let p : Int × Int :=
      match k with
      | 0 => (5500, 200)
      | 1 => (6000, 0)
      | _ => (6140, 140)
    Build.scene t (some 1) [car p.1 p.2] (street ++ [crosswalkAt 31 70])
      [guard (if k == 0 then .proceed else .stop)]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_46_030_o2"
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
  , witness "blind" blindTrace (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .notApplicable ]

end TrafficSpecWitness.LVMC_11_46_030_o2
