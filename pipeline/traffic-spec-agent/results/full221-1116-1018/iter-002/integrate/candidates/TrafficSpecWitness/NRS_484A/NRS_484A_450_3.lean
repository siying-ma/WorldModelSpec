/-
  Witnesses for NRS_484A_450_3.

  Geometry (every figure here is the witness's own and appears nowhere in the rule):
  - intersection r (10): the square x ∈ [-6, 6], y ∈ [-6, 6];
  - approach lane c (11): x ∈ [0, 6], y ∈ [-80, -6], designated direction north, entering r;
    a yield sign (50) governs c;
  - crosswalk (12) marking c: x ∈ [-6, 6], y ∈ [-10, -6] (entrances observed);
  - stop line (13) marking c: x ∈ [0, 6], y ∈ [-8, -7.5] (entrances observed);
  - far-side crosswalk (14) and stop line (15) north of r, observed to mark no carrier;
  - highways: north–south (20) x ∈ [-6, 6], y ∈ [-80, 6]; east–west (21) x ∈ [-80, 80], y ∈ [-6, 6].
  - The subject (track 1) is a car (half-length 2 m, half-width 1 m) at x = 3 heading north; its
    front is 2 m ahead of its reference point. The crossing car (track 2) travels east at 10 m/s on
    y = -1, on the east–west highway.
  - Observations 1 s apart. The conflict (closest approach of the centres within 3 s, below 3 m)
    is placed at the approach start — the last observation with the subject's front more than 2 m
    short of the governing mark — where the subject still moves at 10 m/s toward the crossing car.
-/
import TrafficSpec.Rules.NRS_484A.NRS_484A_450_3
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484A_450_3

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n
def mps (n : Int) : Q := Units.metresPerSecond n

-- Binders ↦ tracks: subject ↦ 1

-- Structures
def intersectionR : Structure := Build.rect 10 .intersection (m (-6)) (m (-6)) (m 6) (m 6)
def laneC : Structure :=
  Build.lane 11 [(m 0, m (-80)), (m 6, m (-80)), (m 6, m (-6)), (m 0, m (-6))] Build.north
    (enters := some 10)
def crosswalkC : Structure :=
  { Build.rect 12 .crosswalk (m (-6)) (m (-10)) (m 6) (m (-6)) with
      marked := some true, entranceOf := [11], entranceObserved := true }
def stopLineC : Structure :=
  { Build.rect 13 .stopLine (m 0) (m (-8)) (m 6) (cm (-750)) with
      entranceOf := [11], entranceObserved := true }
def farCrosswalk : Structure :=
  { Build.rect 14 .crosswalk (m (-6)) (m 6) (m 6) (m 10) with
      marked := some true, entranceOf := [], entranceObserved := true }
def farStopLine : Structure :=
  { Build.rect 15 .stopLine (m (-6)) (cm 1050) (m 0) (m 11) with
      entranceOf := [], entranceObserved := true }
def highwayNS : Structure := Build.rect 20 .highway (m (-6)) (m (-80)) (m 6) (m 6)
def highwayEW : Structure := Build.rect 21 .highway (m (-80)) (m (-6)) (m 80) (m 6)

/-- A crosswalk marks c. -/
def crosswalkLayout : List Structure := [intersectionR, laneC, crosswalkC, highwayNS, highwayEW]
/-- No crosswalk marks c (the far one is observed to mark none); a stop line marks c. -/
def stopLineLayout : List Structure := [intersectionR, laneC, stopLineC, farCrosswalk, highwayNS, highwayEW]
/-- Neither a crosswalk nor a stop line marks c (both lists observed). -/
def bareLayout : List Structure := [intersectionR, laneC, farCrosswalk, farStopLine, highwayNS, highwayEW]

def yieldSign : Device := Build.sign 50 .yieldSign [11]
/-- The source does not observe which regions the yield sign governs. -/
def yieldSignBlind : Device := { Build.sign 50 .yieldSign [] with governsObserved := false }

-- Road users
def subjectAt (y v : Q) : RoadUser :=
  Build.user 1 [.motorVehicle] (m 3, y) Build.north v (m 2, m 1, m 1)
def crossingAt (x : Q) : RoadUser :=
  Build.user 2 [.motorVehicle] (x, m (-1)) Build.east (mps 10) (m 2, m 1, m 1)

/-- A trace at 1 s spacing: the subject's y and speed per observation, the crossing car's x per
    observation (none: the subject is alone). -/
def run (ys vs : List Q) (xs : Option (List Q)) (structures : List Structure) (devices : List Device) : Trace :=
  Build.trace ys.length 0 (Units.seconds 1) fun k t =>
    let others := match xs with
      | some l => [crossingAt (l.getD k Q.zero)]
      | none => []
    Build.scene t (some 1) (subjectAt (ys.getD k Q.zero) (vs.getD k Q.zero) :: others) structures devices

def tens (n : Nat) : List Q := List.replicate n (mps 10)

/-- `forbid` (violated): A car on lane c, governed by a yield sign, with a crosswalk marking c, approaches at 10 m/s while a car on the crossing highway is on a closest approach with it 2 s ahead at 1 m; the car never comes to rest and enters the intersection.
    Approach start at k = 3 (front 10 m short of the crosswalk; conflict: closest approach in 2 s
    at about 1.4 m); entry at k = 5. -/
def forbidTrace : Trace :=
  run [m (-52), m (-42), m (-32), m (-22), m (-12), m (-2)] (tens 6)
    (some [m (-46), m (-36), m (-26), m (-16), m (-6), m 4]) crosswalkLayout [yieldSign]

/-- `permit` (compliant): Same conflict; the car comes to rest 1 m short of the crosswalk, off it, lets the crossing car pass, and enters.
    Approach start and conflict at k = 2; at rest with its front 1 m short of the crosswalk at
    k = 3, 4; on the crosswalk at k = 5; in r at k = 6. -/
def permitTrace : Trace :=
  run [m (-40), m (-30), m (-20), m (-13), m (-13), m (-8), m (-2)]
    [mps 10, mps 10, mps 10, mps 0, mps 0, mps 5, mps 6]
    (some [m (-36), m (-26), m (-16), m (-6), m 4, m 14, m 24]) crosswalkLayout [yieldSign]

/-- `idle` (not_applicable): The car approaches the yield sign alone in the scene, no road user is ever on a closest approach with it, and it enters without halting: no stop was required for safety. -/
def idleTrace : Trace :=
  run [m (-52), m (-42), m (-32), m (-22), m (-12), m (-2)] (tens 6) none crosswalkLayout [yieldSign]

/-- `blind` (unknown): As in forbid, but the source does not observe which travel regions the yield sign governs. -/
def blindTrace : Trace :=
  run [m (-52), m (-42), m (-32), m (-22), m (-12), m (-2)] (tens 6)
    (some [m (-46), m (-36), m (-26), m (-16), m (-6), m 4]) crosswalkLayout [yieldSignBlind]

/-- `branch_1` (compliant): No crosswalk marks c (lists observed); a stop line marks c; with the conflict present, the car comes to rest 1 m short of the line and then enters. -/
def branch_1Trace : Trace :=
  run [m (-41), m (-31), m (-21), m (-11), m (-11), m (-7), m (-2)]
    [mps 10, mps 10, mps 10, mps 0, mps 0, mps 4, mps 5]
    (some [m (-36), m (-26), m (-16), m (-6), m 4, m 14, m 24]) stopLineLayout [yieldSign]

/-- `branch_2` (compliant): Neither a crosswalk nor a stop line marks c (lists observed); with the conflict present, the car comes to rest 1 m short of the intersection's edge, off it, and then enters. -/
def branch_2Trace : Trace :=
  run [m (-39), m (-29), m (-19), m (-9), m (-9), m (-3)]
    [mps 10, mps 10, mps 10, mps 0, mps 0, mps 6]
    (some [m (-36), m (-26), m (-16), m (-6), m 4, m 14]) bareLayout [yieldSign]

/-- `branch_3` (violated): A crosswalk marks c; the conflict is present on the approach; the car rests 20 m short of the crosswalk, moves on and enters without halting again. -/
def branch_3Trace : Trace :=
  run [m (-42), m (-32), m (-32), m (-22), m (-12), m (-2)]
    [mps 10, mps 0, mps 0, mps 10, mps 10, mps 10]
    (some [m (-46), m (-36), m (-26), m (-16), m (-6), m 4]) crosswalkLayout [yieldSign]

/-- `branch_4` (violated): A stop line marks c and no crosswalk does; the conflict is present at the approach start; the car never comes to rest and enters. -/
def branch_4Trace : Trace :=
  run [m (-51), m (-41), m (-31), m (-21), m (-11), m (-1)] (tens 6)
    (some [m (-46), m (-36), m (-26), m (-16), m (-6), m 4]) stopLineLayout [yieldSign]

/-- `branch_5` (violated): Neither a crosswalk nor a stop line marks c; the conflict is present at the approach start; the car never comes to rest and enters. -/
def branch_5Trace : Trace :=
  run [m (-49), m (-39), m (-29), m (-19), m (-9), m 1] (tens 6)
    (some [m (-46), m (-36), m (-26), m (-16), m (-6), m 4]) bareLayout [yieldSign]

/-- `branch_6` (not_applicable): A stop line marks c and no crosswalk does; the car is alone, no road user is on a closest approach with it, and it enters without halting: the search for a conflict ends at the approach start (k = 3, front 11 m short of the line). -/
def branch_6Trace : Trace :=
  run [m (-51), m (-41), m (-31), m (-21), m (-11), m (-1)] (tens 6) none stopLineLayout [yieldSign]

/-- `branch_7` (not_applicable): Neither a crosswalk nor a stop line marks c; the car is alone and enters without halting: the search for a conflict ends at the approach start (k = 3, front 11 m short of r). -/
def branch_7Trace : Trace :=
  run [m (-49), m (-39), m (-29), m (-19), m (-9), m 1] (tens 6) none bareLayout [yieldSign]

/-- `history_boundary` (unknown): The recording begins with the car already 1 m short of the crosswalk marking c, moving at 3 m/s, while a crossing car is on a closest approach with it 2 s ahead at 1 m; it enters without a recorded halt and no recorded observation shows it outside the stopping zone upstream.
    Sampled at 4 m/s (front 1 m short at k = 0, on the crosswalk at k = 1, in r at k = 2); the
    crossing car's closest approach is about 2.7 s ahead at about 1.5 m. -/
def history_boundaryTrace : Trace :=
  Build.trace 3 0 (Units.seconds 1) fun k t =>
    let ys : List Q := [m (-13), m (-9), m (-5)]
    let xs : List Q := [m (-23), m (-13), m (-3)]
    Build.scene t (some 1)
      [ Build.user 1 [.motorVehicle] (m 3, ys.getD k Q.zero) Build.north (mps 4) (m 2, m 1, m 1)
      , crossingAt (xs.getD k Q.zero) ]
      crosswalkLayout [yieldSign]

def witness (name : String) (τ : Trace) (expected : Verdict) (last : Timestamp)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484A_450_3"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, last)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace .violated 5000
  , witness "permit" permitTrace .compliant 6000
  , witness "idle" idleTrace .notApplicable 5000
  , witness "blind" blindTrace (.unknown []) 5000 ["dev.governs"]
  , witness "branch_1" branch_1Trace .compliant 6000
  , witness "branch_2" branch_2Trace .compliant 5000
  , witness "branch_3" branch_3Trace .violated 5000
  , witness "branch_4" branch_4Trace .violated 5000
  , witness "branch_5" branch_5Trace .violated 5000
  , witness "branch_6" branch_6Trace .notApplicable 5000
  , witness "branch_7" branch_7Trace .notApplicable 5000
  , witness "history_boundary" history_boundaryTrace (.unknown []) 2000 (boundary := "the approach start: the observation at which the car was outside the crosswalk's stopping zone upstream lies before the recording, so whether it halted within the zone before the recording began is not observed") ]

end TrafficSpecWitness.NRS_484A_450_3
