/-
  Witnesses for NRS_484B_600_1e.

  The carriageway is one and the same in the first four scenes: a highway region 3000 m long
  (x from 0 to 3000 m, y from -3 to 12 m), one eastbound lane lying on it (region 2, against the
  kerb, y from 0 to 3.6 m), and a parking bay at the edge of the way (region 3, x from 200 to
  220 m, y from -3 to 0 m). `branch_1` has no structure at all: open ground that is no public way.

  The subject is track 1, a motor vehicle 4 m long and 1.8 m wide, heading east; its position
  advances by its speed over the trace, so a moving subject stays within the lane polygon. No
  other road user and no device is in any scene.

  Every trace is 5 scenes 1 s apart, 0 s to 4 s. Nothing in the rule looks back in time, so no
  scenario names a window.

  Every figure here is the witness's own and appears nowhere in the rule: 45 m/s stands well above
  the eighty miles per hour the paragraph states (35.76 m/s) and 25 m/s clearly below it, while
  25 m/s stands well above p.speed_resolution and the parked subject's zero clearly below it.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_600_1e
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_600_1e

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: v ↦ 1

def hwId : RegionId := 1
def laneA : RegionId := 2
def bayId : RegionId := 3

/-- The public way: one carriageway, 3000 m long. -/
def highway : Structure := Build.rect hwId .highway (m 0) (m (-3)) (m 3000) (m 12)

/-- The eastbound lane of that highway, 3.6 m wide, lying on it. -/
def laneEast : Structure :=
  let s :=
    Build.lane laneA
      [(m 0, m 0), (m 3000, m 0), (m 3000, cm 360), (m 0, cm 360)] Build.east
  { s with ways := some [hwId] }

/-- A parking bay at the edge of the way. -/
def bay : Structure := Build.rect bayId .parkingSpace (m 200) (m (-3)) (m 220) (m 0)

/-- The open highway of the first four scenes. -/
def openHighway : List Structure := [highway, laneEast, bay]

/-- Half-length, half-width, half-height of an ordinary car. -/
def halfExtent : Q × Q × Q := (m 2, cm 90, cm 75)

/-- Where a body that started at `x0` and runs at `speed` stands at the `k`-th instant. -/
def along (x0 speed : Q) (k : Nat) : Q := Q.add x0 (Q.mul speed (Q.ofInt (Int.ofNat k)))

def dt : Q := Units.seconds 1
def nScenes : Nat := 5

/-- The subject alone, from `x0` at `speed` along the line `y`, among the structures given. -/
def runTrace (x0 speed y : Q) (structures : List Structure) : Trace :=
  Build.trace nScenes 0 dt fun k t =>
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (along x0 speed k, y) Build.east speed halfExtent ]
      structures []

/-- `forbid` (violated): the subject runs east along the lane of the open highway at 45 m/s and
    holds it there for the whole trace — well above the eighty miles per hour the paragraph
    states. Nothing is posted and no other road user is in the scene. -/
def forbidTrace : Trace := runTrace (m 100) (mps 45) (cm 180) openHighway

/-- `permit` (compliant): the same highway and the same lane, the subject travelling briskly at
    25 m/s — clear of p.speed_resolution, so it is being driven, and clearly below the stated
    rate at every instant. -/
def permitTrace : Trace := runTrace (m 100) (mps 25) (cm 180) openHighway

/-- `idle` (not_applicable): the subject stands still in the parking bay at the edge of the same
    highway, its speed observed and zero at every instant, so it is below p.speed_resolution and
    is not being driven or operated: the rule is not engaged. -/
def idleTrace : Trace := runTrace (m 210) Q.zero (cm (-150)) openHighway

/-- `blind` (unknown): the permit scene exactly, on a source whose manifest declares kin.speed
    absent. Neither whether the vehicle is in motion nor whether its rate exceeds the stated one
    can be decided, so the rule reports unknown rather than compliance. -/
def blindTrace : Trace := permitTrace

/-- `branch_1` (violated): the subject runs at 45 m/s across open ground that is no public way —
    the scene holds no highway, no lane and no region at all, and no other road user. The rate is
    forbidden in any event, so the duty is engaged and broken here as it is upon a highway. -/
def branch_1Trace : Trace := runTrace (m 100) (mps 45) (cm 180) []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) : Scenario :=
  { name := name
    rule := "NRS_484B_600_1e"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("v", 1)]
    expected := expected }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["kin.speed"]
  , witness "branch_1" branch_1Trace .violated ]

end TrafficSpecWitness.NRS_484B_600_1e
