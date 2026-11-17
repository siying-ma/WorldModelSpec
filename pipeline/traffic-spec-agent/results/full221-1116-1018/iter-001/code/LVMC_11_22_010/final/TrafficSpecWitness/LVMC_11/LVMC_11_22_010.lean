/-
  Witnesses for LVMC_11_22_010.

  Geometry (every figure is the witness's own and appears nowhere in the rule):
  - lane 10: eastbound, x from -50 m to 200 m, y from -2 m to 2 m; lane 11: eastbound, y from 2 m to
    6 m, its left neighbour (used by `branch_2` only).
  - every car is a motor vehicle of half-extent 2.4 m × 1.0 m × 0.75 m, heading east.
  - three instants 0.1 s apart; a car moving at 10 m/s advances 1 m per instant.
  Against the reading (time-to-collision horizon 1.5 s, centre clearance 3 m, halt tolerance 0.1 m/s):
  - forbid: the subject (track 1) at x = 0, 1, 2 m, 10 m/s, closes on a halted car (track 2) at
    x = 12 m in the same lane: the centres meet (distance 0 m) after 1.2 s, then 1.1 s, then 1.0 s —
    inside 1.5 s, and 0 m is well below 3 m. The bodies stay 5 m or more apart, so no contact.
  - permit: the subject follows a car (track 2) 30 m ahead at the same 10 m/s: the centres never
    approach, and the bodies are 25 m apart.
  - idle: the subject stands (0 m/s) in lane 10 before a red signal: not in motion.
  - blind: the forbid scene with the subject's speed unobserved (and masked in the manifest).
  - branch_1: the subject drives alone at 10 m/s.
  - branch_2: the subject (y = 1.2 m, in lane 10) and a car (track 3, y = 3 m, in lane 11) drive side by
    side at 10 m/s; their bodies overlap by 0.2 m across: contact, with nothing ahead in the lane.
-/
import TrafficSpec.Rules.LVMC_11.LVMC_11_22_010
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.LVMC_11_22_010

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def carExtent : Q × Q × Q := (cm 240, cm 100, cm 75)
def cruise : Q := Units.metresPerSecond 10
def halted : Q := Units.metresPerSecond 0
def sampleStep : Q := Units.milliseconds 100

def laneA : Structure :=
  Build.lane 10 [(m (-50), m (-2)), (m 200, m (-2)), (m 200, m 2), (m (-50), m 2)] Build.east
    (some 11) none
def laneB : Structure :=
  Build.lane 11 [(m (-50), m 2), (m 200, m 2), (m 200, m 6), (m (-50), m 6)] Build.east
    none (some 10)

def car (track : TrackId) (pos : Vec) (speed : Q) : RoadUser :=
  Build.user track [.motorVehicle] pos Build.east speed carExtent

/-- `forbid` (violated): The subject closes on a halted vehicle ahead in its lane at constant speed; the closest approach falls below the clearance within p.attention_ttc_min. -/
def forbidTrace : Trace :=
  Build.trace 3 0 sampleStep fun k t =>
    Build.scene t (some 1)
      [ car 1 (m k, m 0) cruise
      , car 2 (m 12, m 0) halted ]
      [ laneA ]
      [ ]

/-- `permit` (compliant): The subject follows a vehicle ahead at a steady gap, never closing within the threshold, and touches nothing. -/
def permitTrace : Trace :=
  Build.trace 3 0 sampleStep fun k t =>
    Build.scene t (some 1)
      [ car 1 (m k, m 0) cruise
      , car 2 (m (30 + k), m 0) cruise ]
      [ laneA ]
      [ ]

/-- `idle` (not_applicable): The subject is halted at a signal. -/
def idleTrace : Trace :=
  Build.trace 3 0 sampleStep fun _k t =>
    Build.scene t (some 1)
      [ car 1 (m 0, m 0) halted ]
      [ laneA ]
      [ Build.signal 100 [10] [.circularRed] ]

/-- `blind` (unknown): The subject's speed is not observed. -/
def blindTrace : Trace :=
  Build.trace 3 0 sampleStep fun k t =>
    Build.scene t (some 1)
      [ Build.withKin (car 1 (m k, m 0) cruise) fun kn => { kn with speed := none }
      , car 2 (m 12, m 0) halted ]
      [ laneA ]
      [ ]

/-- `branch_1` (compliant): The subject drives alone on an empty road, touching nothing. -/
def branch_1Trace : Trace :=
  Build.trace 3 0 sampleStep fun k t =>
    Build.scene t (some 1)
      [ car 1 (m k, m 0) cruise ]
      [ laneA ]
      [ ]

/-- `branch_2` (violated): The subject side-swipes a car in the next lane while nothing is ahead of it
    in its own lane: the contact conjunct alone decides. -/
def branch_2Trace : Trace :=
  Build.trace 3 0 sampleStep fun k t =>
    Build.scene t (some 1)
      [ car 1 (m k, cm 120) cruise
      , car 3 (m k, m 3) cruise ]
      [ laneA, laneB ]
      [ ]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "LVMC_11_22_010"
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
  , witness "branch_1" branch_1Trace .compliant
  , witness "branch_2" branch_2Trace .violated ]

end TrafficSpecWitness.LVMC_11_22_010
