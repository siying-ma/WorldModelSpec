/-
  Witnesses for NRS_484B_410_o2.

  Geometry (the witness's own figures; none appears in the rule):
  - The highway (region 10) is the strip x ∈ [-100, 100] m, y ∈ [0, 20] m. South of it (y < 0)
    is a private parking lot, which is no highway.
  - Every trace has four observations, t = 0, 1, 2, 3 s. The subject (track 1, a motor vehicle,
    half-extent 2.25 × 0.9 × 0.75 m) drives north out of the lot: y = -5, -3, -1, +1 m at 2 m/s, so
    its reference point first lies in the highway at t = 3 s (the entry).
  - The conflicting car (track 2) drives west along the highway at y = 3 m at 13 m/s and is 10 m
    east of the subject at the entry: relative position (10, 2) m, relative velocity (-13, -2) m/s,
    closest approach after about 0.77 s (within the 3 s horizon) at a centre distance of about
    0.46 m, far below the 3 m clearance.
  - The exception branches put the subject at rest (speed 0, below the 0.1 m/s tolerance) at
    (0, -1) m for t = 0..2 s, inside a lot region at y ∈ [-4, -0.5] m, then on the highway at
    (0, 1) m at t = 3 s, with the conflicting car present: without the exception they would be
    violated.
  - `entering` and the exception branches judge only t = 1..3 s (`window`): the entry is a `rises`,
    which reads the observation before.
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_410_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_410_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def car (track : TrackId) (pos : Vec) (heading : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos heading speed (cm 225, cm 90, cm 75)

def highway : Structure := Build.rect 10 .highway (m (-100)) (m 0) (m 100) (m 20)

/-- A weekday morning; the signs below are unconditional anyway. -/
def civil : Env :=
  { civilTime := some { year := 2026, month := 11, day := 16, weekday := 0, minuteOfDay := 600 } }

/-- The subject leaving the lot at 2 m/s: y = -5, -3, -1, +1 m. -/
def entering (k : Nat) : RoadUser :=
  car 1 (Q.zero, m (-5 + 2 * Int.ofNat k)) Build.north (Units.metresPerSecond 2)

/-- The subject at rest at (0, -1) m until t = 2 s, then on the highway at (0, 1) m. -/
def haltThenEnter (k : Nat) : RoadUser :=
  if k < 3 then car 1 (Q.zero, m (-1)) Build.north Q.zero
  else car 1 (Q.zero, m 1) Build.north (Units.metresPerSecond 2)

/-- The car on the highway closing at 13 m/s, 10 m east of the subject at t = 3 s. -/
def closing (k : Nat) : RoadUser :=
  car 2 (m (10 + 13 * (3 - Int.ofNat k)), m 3) Build.west (Units.metresPerSecond 13)

/-- A curb zone in the lot, around the subject's halt position. -/
def curbZone (kind : CurbZoneKind) (colour : CurbColour) : Structure :=
  { Build.rect 20 .curbZone (m (-5)) (m (-4)) (m 5) (cm (-50)) with
      curbKind := some kind, curbColour := some colour }

/-- A drive aisle of the lot (a lane, hence a travel region), around the subject's halt position. -/
def aisle : Structure := Build.rect 30 .lane (m (-5)) (m (-4)) (m 5) (cm (-50))

/-- An unconditional no-stopping sign governing the aisle. -/
def noStoppingSign : Device :=
  { Build.sign 40 .regulatorySign [30] with code := some .noStopping, conditions := some {} }

def run (users : Nat → List RoadUser) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1) (users k) structures devices (env := civil)

/-- `forbid` (violated): The subject car leaves a private parking lot and its footprint first overlaps the highway region while a car on the highway 10 m away closes on it at 13 m/s, so their centres are predicted to meet within the horizon. -/
def forbidTrace : Trace := run (fun k => [entering k, closing k]) [highway] []

/-- `permit` (compliant): The subject car leaves a private parking lot onto the highway; no other road user is in the scene. -/
def permitTrace : Trace := run (fun k => [entering k]) [highway] []

/-- `idle` (not_applicable): The subject car is on the highway at every observation of the trace and never enters it. -/
def idleTrace : Trace :=
  run (fun k => [car 1 (m (10 * Int.ofNat k), m 5) Build.east (Units.metresPerSecond 10)]) [highway] []

/-- `blind` (unknown): The subject car moves from a parking lot toward the highway, but rel.occupies is not observed on this source, so the entry cannot be decided. -/
def blindTrace : Trace := run (fun k => [entering k]) [highway] []

/-- `branch_1` (not_applicable): the subject was at rest in a fire-lane curb zone just before it entered the highway (exception, curb kind). -/
def branch1Trace : Trace :=
  run (fun k => [haltThenEnter k, closing k]) [highway, curbZone .fireLane CurbColour.none] []

/-- `branch_2` (not_applicable): the subject was at rest at a red-painted passenger-loading curb just before it entered the highway (exception, curb colour). -/
def branch2Trace : Trace :=
  run (fun k => [haltThenEnter k, closing k]) [highway, curbZone .passengerLoading .red] []

/-- `branch_3` (not_applicable): the subject was at rest in a lot aisle governed by an unconditional no-stopping sign just before it entered the highway (exception, posted sign). -/
def branch3Trace : Trace :=
  run (fun k => [haltThenEnter k, closing k]) [highway, aisle] [noStoppingSign]

/-- `branch_4` (violated): the subject was at rest at an unrestricted white passenger-loading curb, so the exception does not hold, and it entered the highway into the closing car. -/
def branch4Trace : Trace :=
  run (fun k => [haltThenEnter k, closing k]) [highway, curbZone .passengerLoading .white] []

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "")
    (window : Option (Timestamp × Timestamp) := some (1000, 3000)) : Scenario :=
  { name := name
    rule := "NRS_484B_410_o2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := window
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.occupies"]
  , witness "branch_1" branch1Trace .notApplicable
  , witness "branch_2" branch2Trace .notApplicable
  , witness "branch_3" branch3Trace .notApplicable
  , witness "branch_4" branch4Trace .violated ]

end TrafficSpecWitness.NRS_484B_410_o2
