/-
  Witnesses for LVMC_11_52_300.

  Geometry: one street (region 10, kind highway), a rectangle 20 m wide running east from
  x = -100 m to x = 8000 m. Track 1 is the subject, half-extent 3 m × 1.25 m × 1.5 m, heading
  east, its reference point on the street's centre line (y = 0). Observations every 60 s
  (adequate for the 180 s parking window and the 30 min period). While moving it travels east
  at 0.5 m/s (30 m per observation, far above the 0.1 m/s halt tolerance); at rest its speed is 0.
  Civil time (when recorded) is 2026-03-10, a Tuesday, its minute of day advancing one per
  observation from the trace's start minute. Each witness's `window` starts 35 min into its trace,
  so the 30 min period plus the 3 min parking look-back is always covered.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_300
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_300

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def street : Structure := Build.rect 10 .highway (m (-100)) (m (-10)) (m 8000) (m 10)

def civil (minute : Nat) : Env :=
  { civilTime := some { year := 2026, month := 3, day := 10, weekday := 1, minuteOfDay := minute } }

/-- Observation k of a trace that starts at civil minute `start` (none: no civil time recorded):
    the subject moves before `restFrom` and after `restTo`, and is at rest in between. -/
def stayTrace (classes : List RoadUserClass) (start : Option Nat) (n restFrom restTo : Nat) : Trace :=
  Build.trace n 0 (Units.seconds 60) fun k t =>
    let moving := k < restFrom || k > restTo
    let moved : Nat := min k restFrom + (k - restTo)
    let speed : Q := if moving then Units.ratio 1 2 else Q.zero
    Build.scene t (some 1)
      [ Build.user 1 classes (m (30 * Int.ofNat moved), m 0) Build.east speed (m 3, cm 125, cm 150) ]
      [ street ]
      [ ]
      (env := match start with
        | some s => civil (s + k)
        | none => {})

def minute (k : Nat) : Timestamp := Int.ofNat k * 60000

/-- `forbid` (violated): A trailer (vehicle aggregate, not a motor vehicle) stands at rest on a street from 01:10 to 01:50 civil time.
    Trace 00:40–02:00; at rest k = 30 … 70 (01:10–01:50). -/
def forbidTrace : Trace := stayTrace [.trailerOrCombination] (some 40) 81 30 70

/-- `permit` (compliant): A trailer stands at rest on a street from 02:00 to 02:20 civil time and is then towed away.
    Trace 01:20–02:40; at rest k = 40 … 60 (02:00–02:20), moving before and after. -/
def permitTrace : Trace := stayTrace [.trailerOrCombination] (some 80) 81 40 60

/-- `idle` (not_applicable): A passenger car (motor vehicle aggregate) stands at rest on a street from 01:00 to 05:00 civil time.
    Trace 01:00–05:00, at rest throughout. -/
def idleTrace : Trace := stayTrace [.motorVehicle] (some 60) 241 0 240

/-- `blind` (unknown): A trailer stands at rest on a street for forty minutes; the recording carries no civil time, so whether the period lies between one and six a.m. is unknown.
    50 min trace, at rest k = 5 … 45, no civil time. -/
def blindTrace : Trace := stayTrace [.trailerOrCombination] none 51 5 45

/-- `branch_1` (compliant): A trailer stands at rest on a street from 00:30 to 01:20 civil time and is then towed away: only twenty minutes of the period lie within the hours.
    Trace 00:00–01:40; at rest k = 30 … 80 (00:30–01:20). -/
def branch_1Trace : Trace := stayTrace [.trailerOrCombination] (some 0) 101 30 80

def witness (name : String) (τ : Trace) (expected : Verdict) (w : Timestamp × Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_52_300"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some w
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (minute 35, minute 80)
  , witness "permit" permitTrace .compliant (minute 35, minute 80)
  , witness "idle" idleTrace .notApplicable (minute 35, minute 240)
  , witness "blind" blindTrace (.unknown []) (minute 35, minute 50) ["env.civil_time"]
  , witness "branch_1" branch_1Trace .compliant (minute 35, minute 100) ]

end TrafficSpecWitness.LVMC_11_52_300
