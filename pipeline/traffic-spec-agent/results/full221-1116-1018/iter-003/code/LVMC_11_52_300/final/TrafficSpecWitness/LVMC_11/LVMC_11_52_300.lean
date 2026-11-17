/-
  Witnesses for LVMC_11_52_300.

  Geometry: one street, a highway region 10 km long (x from -5000 m to 5000 m) and 20 m wide
  (y from -10 m to 10 m); in `branch_2` a private lot north of it (y from 20 m to 60 m) and no
  street under the vehicle. The subject (track 1) stands at (0, 5) (lot: (0, 40)) at 0 m/s while
  at rest; it arrives and leaves at 1 m/s along +x, 60 m per sample. Samples are 60 s apart
  (well inside half of the 180 s parking window and of the 30 min window); scene k carries the
  civil minute of the day `start + k` on Monday 2026-11-16. Each witness names, as `window`, the
  instants whose 30 min look-back (and the 180 s look-back of its first instant) lie inside the
  trace. Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_52_300
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_52_300

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def street : Structure := Build.rect 100 .highway (m (-5000)) (m (-10)) (m 5000) (m 10)

def clock (minute : Nat) : CivilTime :=
  { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := minute }

def halfBody : Q × Q × Q := (m 3, cm 125, m 2)

/-- Scene k: the subject at rest for `kStop ≤ k ≤ kLeave`, moving at 1 m/s otherwise; civil
    minute `start + k` when `hasClock`; standing at `y` (5 m: on the street; 40 m: on the lot). -/
def sceneAt (cls : List RoadUserClass) (start kStop kLeave : Nat) (hasClock : Bool) (y : Int)
    (k : Nat) (t : Timestamp) : Scene :=
  let moving := k < kStop || k > kLeave
  let x : Int := if k < kStop then 60 * ((k : Int) - kStop)
    else if k > kLeave then 60 * ((k : Int) - kLeave) else 0
  let speed := if moving then Units.metresPerSecond 1 else Q.zero
  Build.scene t (some 1)
    [ Build.user 1 cls (m x, m y) Build.east speed halfBody ]
    [ street ]
    []
    (env := { civilTime := if hasClock then some (clock (start + k)) else none })

def minAt (k : Nat) : Timestamp := k * 60000

/-- `forbid` (violated): A trailer (vehicle aggregate, not self-propelled, so not a motor vehicle) stands at rest on a street from 01:10 to 01:50 civil time. -/
def forbidTrace : Trace :=
  Build.trace 41 0 (Units.seconds 60) fun k t =>
    sceneAt [.trailerOrCombination] 70 0 40 true 5 k t

/-- `permit` (compliant): A trailer stands at rest on a street from 02:00 to 02:20 civil time and is then towed away. -/
def permitTrace : Trace :=
  Build.trace 56 0 (Units.seconds 60) fun k t =>
    sceneAt [.trailerOrCombination] 105 15 35 true 5 k t

/-- `idle` (not_applicable): A passenger car (motor vehicle aggregate) stands at rest on a street from 01:00 to 05:00 civil time. -/
def idleTrace : Trace :=
  Build.trace 241 0 (Units.seconds 60) fun k t =>
    sceneAt [.motorVehicle] 60 0 240 true 5 k t

/-- `blind` (unknown): A trailer stands at rest on a street for forty minutes; the recording carries no civil time, so whether the period lies between one and six a.m. is unknown. -/
def blindTrace : Trace :=
  Build.trace 41 0 (Units.seconds 60) fun k t =>
    sceneAt [.trailerOrCombination] 70 0 40 false 5 k t

/-- `branch_1` (compliant): A trailer stands at rest on a street from 00:30 to 01:20 civil time and is then towed away: only twenty minutes of the period lie within the hours. -/
def branch_1Trace : Trace :=
  Build.trace 76 0 (Units.seconds 60) fun k t =>
    sceneAt [.trailerOrCombination] 25 5 55 true 5 k t

/-- `branch_2` (not_applicable): A trailer stands at rest on a private lot off the street from
    01:10 to 01:50 civil time: the words reach only parking on a street. -/
def branch_2Trace : Trace :=
  Build.trace 41 0 (Units.seconds 60) fun k t =>
    sceneAt [.trailerOrCombination] 70 0 40 true 40 k t

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := none) : Scenario :=
  { name := name
    rule := "LVMC_11_52_300"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated (window := some (minAt 35, minAt 40))
  , witness "permit" permitTrace .compliant (window := some (minAt 35, minAt 55))
  , witness "idle" idleTrace .notApplicable (window := some (minAt 35, minAt 240))
  , witness "blind" blindTrace (.unknown []) ["env.civil_time"] (window := some (minAt 35, minAt 40))
  , witness "branch_1" branch_1Trace .compliant (window := some (minAt 35, minAt 75))
  , witness "branch_2" branch_2Trace .notApplicable (window := some (minAt 35, minAt 40)) ]

end TrafficSpecWitness.LVMC_11_52_300
