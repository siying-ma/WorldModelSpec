/-
  Witnesses for NRS_484B_257_2_o2.

  Geometry (the witness's own figures; none appears in the rule):
    - intersection X (region 10): the square [-10, 10] × [-10, 10];
    - carrier c (region 11): a lane x ∈ [0, 4], y ∈ [-40, -10], northbound, entering X — the
      subject's approach;
    - carrier c2 (region 12): a lane x ∈ [-40, -10], y ∈ [-4, 0], eastbound, entering X — v's
      approach.
    - subject (track 1) and v (track 2): passenger cars, half-extents 2 m × 1 m × 0.75 m, one
      observation per second.
    - conflict scene: at t = 0 s the subject is on c at (2, -13) and v on c2 at (-11, -2); at
      t = 1 s the subject is in X at (2, -8) northbound at 5 m/s and v in X at (-4, -2) eastbound
      at 5 m/s: their centres meet at (2, -2) 1.2 s ahead (closest-approach distance 0 m, against
      a 3 s horizon and a 3 m clearance); the bodies do not touch at t = 1 s.
    - hazard scene: at t = 1 s the subject is in X at (2, -9) at 5 m/s, v still on c2 at (-12, -2)
      at 10 m/s: centres meet 1.4 s ahead.
    - permit scene: the subject waits at rest on c at (2, -13) while v crosses X; at t = 2 s the
      subject enters X at (2, -8) at 5 m/s with v at (6, -2), already past and moving away
      (no approach ahead); at t = 3 s v has left X at (14, -2).
  Devices: a yield sign (20) or stop signs (20, 21), a police officer (23), a traffic signal (24).
-/
import TrafficSpec.Rules.NRS_484B.NRS_484B_257_2_o2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484B_257_2_o2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def isect : Structure := Build.rect 10 .intersection (m (-10)) (m (-10)) (m 10) (m 10)
def laneC : Structure :=
  Build.lane 11 [(m 0, m (-40)), (m 4, m (-40)), (m 4, m (-10)), (m 0, m (-10))] Build.north
    (enters := some 10)
def laneC2 : Structure :=
  Build.lane 12 [(m (-40), m (-4)), (m (-10), m (-4)), (m (-10), m 0), (m (-40), m 0)] Build.east
    (enters := some 10)

def car (id : TrackId) (x y : Int) (h : Vec) (speed : Int) : RoadUser :=
  Build.user id [.motorVehicle] (m x, m y) h (Units.metresPerSecond speed) (m 2, m 1, cm 75)

def yieldOn (rs : List RegionId) : Device := Build.sign 20 .yieldSign rs
def stopOn (id : DeviceId) (rs : List RegionId) : Device := Build.sign id .stopSign rs
def police (rs : List RegionId) : Device :=
  { Build.device 23 .humanDirection rs with humanRole := some .policeOfficer, humanIndication := some .proceed }
def flagger (rs : List RegionId) : Device :=
  { Build.device 23 .humanDirection rs with humanRole := some .flagger, humanIndication := some .proceed }
def operatingSignal (rs : List RegionId) : Device :=
  { Build.signal 24 rs [.circularGreen] with inoperative := some false, uncovered := some true }
def darkSignal (rs : List RegionId) : Device :=
  { Build.signal 24 rs [.dark] with inoperative := some true, uncovered := some true }

def mkScene (t : Timestamp) (users : List RoadUser) (devices : List Device) : Scene :=
  Build.scene t (some 1) users [isect, laneC, laneC2] devices

/-- The subject enters X from c and moves across it; v, having entered X from c2, is on a
    collision course with it. -/
def conflictUsers (k : Nat) : List RoadUser :=
  match k with
  | 0 => [car 1 2 (-13) Build.north 5, car 2 (-11) (-2) Build.east 5]
  | _ => [car 1 2 (-8) Build.north 5, car 2 (-4) (-2) Build.east 5]

def conflictTrace (devices : List Device) : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t => mkScene t (conflictUsers k) devices

/-- The subject enters X from c; v is still on c2, approaching so closely as to be a hazard. -/
def hazardUsers (k : Nat) : List RoadUser :=
  match k with
  | 0 => [car 1 2 (-14) Build.north 5, car 2 (-22) (-2) Build.east 10]
  | _ => [car 1 2 (-9) Build.north 5, car 2 (-12) (-2) Build.east 10]

/-- The subject waits at rest on c while v crosses, then enters X behind it. -/
def permitUsers (k : Nat) : List RoadUser :=
  match k with
  | 0 => [car 1 2 (-13) Build.north 0, car 2 (-14) (-2) Build.east 8]
  | 1 => [car 1 2 (-13) Build.north 0, car 2 (-6) (-2) Build.east 8]
  | 2 => [car 1 2 (-8) Build.north 5, car 2 6 (-2) Build.east 8]
  | _ => [car 1 2 (-3) Build.north 5, car 2 14 (-2) Build.east 8]

/-- `forbid` (violated): A dev.yield_sign governs c; the subject entered X and moves across it with kin.speed above p.halt_speed_tolerance; v occupies X having entered from c2, which no stop or yield sign governs; their closest approach lies within p.conflict_horizon at a centre distance below p.conflict_centre_clearance. -/
def forbidTrace : Trace := conflictTrace [yieldOn [11]]

/-- `permit` (compliant): Same scene; the subject waits at rest until v has cleared, then moves across X with no closest approach to v within the bound. -/
def permitTrace : Trace :=
  Build.trace 4 0 (Units.seconds 1) fun k t => mkScene t (permitUsers k) [yieldOn [11]]

/-- `idle` (not_applicable): No stop or yield sign governs c or X when the subject enters X. -/
def idleTrace : Trace := conflictTrace []

/-- `blind` (unknown): Subject moving across X in conflict with v; dev.governs is absent, so whether a sign governs c, and whether v is so obligated, are unknown. -/
def blindTrace : Trace := conflictTrace [yieldOn [11]]

/-- `branch_1` (compliant): The subject moves across X with no other road user in the scene. -/
def branch_1Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t =>
    mkScene t ((conflictUsers k).filter (·.track == 1)) [yieldOn [11]]

/-- `branch_2` (compliant): At an all-way stop, v entered X from c2, which a stop sign governs; the subject moves in conflict with v: v is itself obligated to stop, and this duty does not protect it. -/
def branch_2Trace : Trace := conflictTrace [stopOn 20 [11], stopOn 21 [12]]

/-- `branch_3` (not_applicable): a yield sign governs c, but a police officer directs the traffic
    on c: the exception of span a. -/
def branch_3Trace : Trace := conflictTrace [yieldOn [11], police [11]]

/-- `branch_4` (not_applicable): a yield sign governs c, but an operating traffic signal controls
    X: the exception of span b. -/
def branch_4Trace : Trace := conflictTrace [yieldOn [11], operatingSignal [10]]

/-- `branch_5` (violated): the signal governing c is inoperative, so the yield sign governs; the
    subject moves in conflict with protected v. -/
def branch_5Trace : Trace := conflictTrace [yieldOn [11], darkSignal [11]]

/-- `branch_6` (violated): v, on unsigned c2 and not yet in X, approaches so closely as to be an
    immediate hazard while the subject moves across X. -/
def branch_6Trace : Trace :=
  Build.trace 2 0 (Units.seconds 1) fun k t => mkScene t (hazardUsers k) [yieldOn [11]]

/-- `branch_7` (compliant): a yield sign governs X itself, so v entering from c2 is obligated too;
    the subject moves in conflict with it. -/
def branch_7Trace : Trace := conflictTrace [yieldOn [10]]

/-- `branch_8` (compliant): a stop sign governs X itself, so v entering from c2 is obligated too;
    the subject moves in conflict with it. -/
def branch_8Trace : Trace := conflictTrace [stopOn 20 [10]]

/-- `branch_9` (violated): a flagger, not a police officer, directs on c, where a yield sign
    governs; the exception of span a does not apply, and the subject moves in conflict with v. -/
def branch_9Trace : Trace := conflictTrace [yieldOn [11], flagger [11]]

def witness (name : String) (τ : Trace) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484B_257_2_o2"
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
  , witness "branch_2" branch_2Trace .compliant
  , witness "branch_3" branch_3Trace .notApplicable
  , witness "branch_4" branch_4Trace .notApplicable
  , witness "branch_5" branch_5Trace .violated
  , witness "branch_6" branch_6Trace .violated
  , witness "branch_7" branch_7Trace .compliant
  , witness "branch_8" branch_8Trace .compliant
  , witness "branch_9" branch_9Trace .violated ]

end TrafficSpecWitness.NRS_484B_257_2_o2
