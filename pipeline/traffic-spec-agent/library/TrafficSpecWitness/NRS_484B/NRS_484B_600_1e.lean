/-
  Witnesses for NRS_484B_600_1e.

  The scene is 2 km of open highway running east: one region of kind `highway`, 16 m wide
  (y from −8 m to +8 m, x from 0 to 2000 m), and one eastbound lane inside it (y from −4 m to 0 m).
  One road user, track 1, is the subject `v`; it travels east along the middle of that lane
  (y = −2 m) from x = 100 m, a body 4.8 m long and 1.8 m wide. Each trace is three observations
  one second apart, the body advancing by its own speed each second; no other road user is present.

  The figures: 41 m/s (about 92 mph) breaks the stated 80 miles per hour (35.7632 m/s) by a clear
  margin, 31 m/s (about 69 mph) keeps it by one, 9 m/s is the bicycle's pace, and 0 m/s is the
  halted vehicle whose velocity is the zero vector. Every figure here is the witness's own and
  appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: v ↦ 1

/-- The highway itself: the way the road user travels on. -/
def highway : Structure := Build.rect 10 .highway (m 0) (m (-8)) (m 2000) (m 8)

/-- The eastbound lane of that highway. -/
def eastLane : Structure :=
  Build.lane 11 [(m 0, m (-4)), (m 2000, m (-4)), (m 2000, m 0), (m 0, m 0)] Build.east
    (ordinal := some 1) (count := some 1)

/-- Track 1 at the `k`-th observation: east along the lane at a constant speed, from x = 100 m. -/
def mover (classes : List RoadUserClass) (speed : Q) (k : Nat) : RoadUser :=
  let travelled := Q.mul (Q.ofInt (Int.ofNat k)) speed
  Build.user 1 classes (Q.add (m 100) travelled, m (-2)) Build.east speed (cm 240, cm 90, cm 75)
    (some travelled)

def sceneOf (t : Timestamp) (u : RoadUser) : Scene :=
  Build.scene t (some 1) [u] [highway, eastLane] []

/-- A three-second run of one road user of these classes at this speed. -/
def runOf (classes : List RoadUserClass) (speed : Q) : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t => sceneOf t (mover classes speed k)

/-- `forbid` (violated): A vehicle travels along an open highway at about 41 m/s, some 92 miles per hour, above the 80 miles per hour the paragraph states. No other road user is in the scene and the verdict is decided: violated. -/
def forbidTrace : Trace := runOf [.motorVehicle] (Units.metresPerSecond 41)

/-- `permit` (compliant): The same vehicle on the same highway travels at about 31 m/s, some 70 miles per hour, below the stated bound, with no other road user in the scene: compliant. -/
def permitTrace : Trace := runOf [.motorVehicle] (Units.metresPerSecond 31)

/-- `idle` (not_applicable): The road user travelling at about 9 m/s on the highway is a bicycle,
    which DEF-NRS-484A-320 leaves out of the vehicle aggregate, so it is no member of
    DEF-NRS-484A-320::vehicle and the paragraph does not engage. (The node's narrative names an
    electric scooter; the run's reading leaves that class unresolved under this aggregate, which
    is unknown rather than false — see task_result.md.) -/
def idleTrace : Trace := runOf [.bicycle] (Units.metresPerSecond 9)

/-- `blind` (unknown): A vehicle is driven along the highway on a source whose capability manifest declares kin.speed absent, so its rate of speed is unobserved at every observation and the comparison with 80 miles per hour cannot be decided. -/
def blindTrace : Trace := runOf [.motorVehicle] (Units.metresPerSecond 31)

/-- `branch_1` (not_applicable): the vehicle stands still on the same lane — its velocity is the
    zero vector, so it is driven or operated at no rate of speed and the paragraph does not
    engage, whatever its speed would be measured against. -/
def haltedTrace : Trace := runOf [.motorVehicle] Q.zero

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" haltedTrace .notApplicable ]

end TrafficSpecWitness.NRS_484B_600_1e
