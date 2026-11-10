/-
  Witnesses for NRS_484B_560_7a.

  Geometry (every figure is the witness's own and appears nowhere in the rule): one eastbound lane
  (region 1, x ∈ [-100, 100], y ∈ [-2, 2]); a level railway crossing (region 2) across it,
  x ∈ [0, 6]. x (track 1) is a car, 4 m long and 2 m wide, heading east. The s6 distance is 15 ft
  (4.572 m): a car with its trailing end 2 m past the crossing is still crossing; one 9 m or more
  past it, or 9 m or more short of it before entering, is not.
  - forbid: x approaches at 5 m/s (10 m short of the crossing), then halts centred at 3 m, on the
    tracks; truck y (track 2, 10 m long) stands at 12 m, a 2 m gap ahead of x's front.
  - permit: x alone at 7 m/s through positions -11, -4, 3, 10, 17: on the crossing at 3, 2 m past it
    at 10 (still crossing), 9 m past at 17.
  - idle: the lane alone, no crossing; x halts with y 2 m ahead.
  - blind: as forbid with `rel.surface_gap` absent and the undercarriage assumption declared not
    to hold (an undeclared one would be a second unknown beside the masked atom); the
    source does not observe y's extent either, so Core cannot compute the gap from the footprints
    (masking drops only a supplied gap), nor y's occupancy. y's position still places it ahead of x.
  - branch_1: x at 7 m/s through -11, -4, 3, 10, then halted at 17 (9 m past) behind y at 25 (1 m gap).
  - branch_2: x halts on the crossing alone; `asm.undercarriage_grounded` declared true there.
  - branch_3: as forbid, with a police officer (device 10) directing stop and governing the lane.
  - branch_4: as forbid, with a pedestrian z (track 3) walking south at 2 m/s towards x's centre,
    6 m then 4 m away while x stands: closest approach within 3 s at centre distance 0.
  - branch_5: x at 7 m/s through -11, -4, 3, then halted at 10 (trailing end 2 m past the crossing,
    short of 15 ft) behind y at 19 (2 m gap).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_560_7a
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_560_7a

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: x ↦ 1

def laneId : RegionId := 1
def crossingId : RegionId := 2

def lane : Structure := Build.rect laneId .lane (m (-100)) (m (-2)) (m 100) (m 2)
def crossing : Structure := Build.rect crossingId .railwayCrossing (m 0) (m (-2)) (m 6) (m 2)

/-- x, a car heading east, centred at `px` on the lane's axis. -/
def car (px : Int) (speed : Int) : RoadUser :=
  Build.user 1 [.motorVehicle] (m px, m 0) Build.east (Units.metresPerSecond speed) (m 2, m 1, m 1)

/-- y, a truck standing still, centred at `px`. -/
def truck (px : Int) : RoadUser :=
  Build.user 2 [.truck] (m px, m 0) Build.east (Units.metresPerSecond 0) (m 5, m 1, m 2)

/-- x approaching then halted on the crossing: 10 m short of it at the first instant. -/
def haltingCar (k : Nat) : RoadUser := if k = 0 then car (-12) 5 else car 3 0

/-- `forbid` (violated): x, a car, enters a level crossing; a truck y stands queued just beyond it. x halts behind y with its body still on the tracks, the gap to y within the standstill gap; no officer directs traffic and no road user moves toward x. -/
def forbidTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ haltingCar k, truck 12 ]
      [ lane, crossing ]
      [ ]

/-- `permit` (compliant): x, alone in the scene, drives over a level crossing at a steady speed and continues well past it without halting. -/
def permitTrace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ car (-11 + 7 * (k : Int)) 7 ]
      [ lane, crossing ]
      [ ]

/-- `idle` (not_applicable): x drives on a road with no railway crossing and halts behind a queued vehicle. -/
def idleTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ haltingCar k, truck 12 ]
      [ lane ]
      [ ]

/-- `blind` (unknown): x halts on the crossing with a vehicle y ahead of it; the source declares rel.surface_gap absent and the trace declares no undercarriage assumption, so whether x halts at the back of a queue is unknown. -/
def blindTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let s := Build.scene t (some 1)
      [ haltingCar k, Build.withKin (truck 12) fun kin => { kin with extent := none } ]
      [ lane, crossing ]
      [ ]
      (assumptions := [("asm.undercarriage_grounded", false)])
    -- without y's body the source observes only x's occupancy
    { s with occupancyObserved := [1], occupies := s.occupies.filter (·.1 == 1) }

/-- `branch_1` (compliant): x crosses without halting and halts behind queued y only once its body is farther than the stated distance past the crossing. -/
def branch_1Trace : Trace :=
  Build.trace 6 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (if k < 4 then car (-11 + 7 * (k : Int)) 7 else car 17 0), truck 25 ]
      [ lane, crossing ]
      [ ]

/-- `branch_2` (violated): x halts on the crossing with no road user ahead of it; the trace declares asm.undercarriage_grounded for x at that observation. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ haltingCar k ]
      [ lane, crossing ]
      [ ]
      (assumptions := [("asm.undercarriage_grounded", k != 0)])

/-- The police officer directing x to stop, governing the lane x occupies. -/
def officer : Device :=
  { Build.device 10 .humanDirection [laneId] (some (m 3, m 4)) with
    humanRole := some .policeOfficer
    humanIndication := some .stop }

/-- `branch_3` (compliant): As in forbid, but a police officer at the crossing directs x to stop (dev.human_direction, role police_officer, indication stop, governing the lane x occupies) when it halts. -/
def branch_3Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ haltingCar k, truck 12 ]
      [ lane, crossing ]
      [ officer ]

/-- z, a pedestrian walking south towards x's centre line, `py` north of it. -/
def pedestrian (py : Int) : RoadUser :=
  Build.user 3 [.pedestrian] (m 3, m py) Build.south (Units.metresPerSecond 2) (cm 30, cm 30, cm 90)

/-- `branch_4` (compliant): as in forbid, but x halts for a pedestrian z whose predicted closest approach to x lies within the conflict horizon and clearance. -/
def branch_4Trace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ haltingCar k, truck 12, pedestrian (8 - 2 * (k : Int)) ]
      [ lane, crossing ]
      [ ]

/-- `branch_5` (violated): x drives onto the crossing and halts behind queued y with its trailing end only 2 m past it, short of the stated distance: it has not completely crossed. -/
def branch_5Trace : Trace :=
  Build.trace 5 0 (Units.seconds 1) fun k t =>
    Build.scene t (some 1)
      [ (if k < 3 then car (-11 + 7 * (k : Int)) 7 else car 10 0), truck 19 ]
      [ lane, crossing ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_560_7a"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("x", 1)]
    expected := expected
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated
  , witness "permit" permitTrace .compliant
  , witness "idle" idleTrace .notApplicable
  , witness "blind" blindTrace (.unknown []) ["rel.surface_gap"]
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated
  , witness "branch_3" branch_3Trace .compliant
  , witness "branch_4" branch_4Trace .compliant
  , witness "branch_5" branch_5Trace .violated ]

end TrafficSpecWitness.NRS_484B_560_7a
