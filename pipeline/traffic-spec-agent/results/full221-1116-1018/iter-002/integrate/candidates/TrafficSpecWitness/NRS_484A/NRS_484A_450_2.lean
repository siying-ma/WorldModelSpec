/-
  Witnesses for NRS_484A_450_2.

  Geometry (world frame, +x east): one approach lane c (region 10) from x = -80 to x = 0, y 0..4,
  direction east, recorded as entering intersection r (region 20, x 0..16, y -8..12). Where the
  scene has them: a crosswalk (30, x -4.5..-1.5) and a stop line (40, x -2.5..-2.0), each recorded
  (entrances observed) as marking c only; a stop sign (50) governing c, or a traffic signal (60)
  governing c (idle). branch_5 adds the opposing lane 11 (x 16..60, y -4..0, west, entering r) and
  a stop line 41 on it, recorded as marking lane 11 only. The car (track 1, a motor vehicle) drives east along y = 2, half-length 2 m,
  half-width 1 m, observed every second; its occupancy is stated from its footprint (the interval
  x - 2 .. x + 2 against each region's x-interval), so a body across two regions occupies both.

  With p.stop_point_tolerance = 2 m: a crosswalk's zone is a reference point in [-8.5, -6.5) (front
  within 2 m, off it); a halt 1 m short of it is at x = -7.5. A stop line's halt 1 m short is at
  x = -5.5; the intersection edge's at x = -3. Speeds at rest are 0 (≤ 0.1 m/s), moving ≥ 2 m/s.
  Every figure here is the witness's own and appears nowhere in the rule.
-/
import TrafficSpec.Rules.NRS_484A.NRS_484A_450_2
import TrafficSpec.Core.Evidence.Builders

namespace TrafficSpecWitness.NRS_484A_450_2

open TrafficSpec

def m (n : Int) : Q := Units.metres n
def cm (n : Int) : Q := Units.centimetres n

-- Binders ↦ tracks: subject ↦ 1

def halfLen : Q := m 2
def body : Q × Q × Q := (m 2, m 1, cm 75)

/-- Lane c: the approach, entering r. -/
def laneC : Structure :=
  Build.lane 10 [(m (-80), m 0), (m 0, m 0), (m 0, m 4), (m (-80), m 4)] Build.east (enters := some 20)

/-- The intersection r. -/
def isect : Structure := Build.rect 20 .intersection (m 0) (m (-8)) (m 16) (m 12)

/-- The near-side crosswalk, recorded as marking c. -/
def crosswalkC : Structure :=
  { Build.rect 30 .crosswalk (cm (-450)) (m 0) (cm (-150)) (m 4) with
    entranceOf := [10], entranceObserved := true, marked := some true }

/-- The stop line, recorded as marking c. -/
def stopLineC : Structure :=
  { Build.rect 40 .stopLine (cm (-250)) (m 0) (m (-2)) (m 4) with
    entranceOf := [10], entranceObserved := true }

/-- The opposing approach: lane 11 east of r (x 16..60, y -4..0), direction west, entering r. -/
def laneOther : Structure :=
  Build.lane 11 [(m 16, m (-4)), (m 60, m (-4)), (m 60, m 0), (m 16, m 0)] Build.west (enters := some 20)

/-- A stop line on the far side of r, recorded as marking the opposing approach (lane 11) only. -/
def stopLineOther : Structure :=
  { Build.rect 41 .stopLine (m 18) (m (-4)) (cm 1850) (m 0) with
    entranceOf := [11], entranceObserved := true }

def stopSign : Device := Build.sign 50 .stopSign [10]
def stopSignBlind : Device := { Build.sign 50 .stopSign [] with governsObserved := false }
def greenSignal : Device := Build.signal 60 [10] [.circularGreen]

/-- Each region's x-interval, for the footprint occupancy. -/
def spanOf (s : Structure) : Option (RegionId × Q × Q) :=
  if s.id == 10 then some (10, m (-80), m 0)
  else if s.id == 20 then some (20, m 0, m 16)
  else if s.id == 30 then some (30, cm (-450), cm (-150))
  else if s.id == 40 then some (40, cm (-250), m (-2))
  else none   -- regions 11 and 41 lie off the car's path (y -4..0, beyond r)

/-- The regions the car's footprint (x - 2 .. x + 2) overlaps. -/
def overlapping (x : Q) (structs : List Structure) : List (TrackId × RegionId) :=
  (structs.filterMap spanOf).filterMap fun (rid, lo, hi) =>
    if Q.lt lo (Q.add x halfLen) then
      if Q.lt (Q.sub x halfLen) hi then some (1, rid) else none
    else none

/-- A trace of the car at the listed (x in cm, speed in m/s), one second apart. -/
def drive (pts : List (Int × Int)) (structs : List Structure) (devs : List Device) : Trace :=
  Build.trace pts.length 0 (Units.seconds 1) fun k t =>
    let p := pts.getD k (0, 0)
    let x := cm p.1
    let u := Build.user 1 [.motorVehicle] (x, m 2) Build.east (Units.metresPerSecond p.2) body
    Build.scene t (some 1) [u] structs devs (occupies := some (overlapping x structs))

def lastT (pts : List (Int × Int)) : Timestamp := (Int.ofNat (pts.length - 1)) * 1000

/-- `forbid`: rolls over the crosswalk at 4 m/s and enters r (at x = 1.5) never at rest. -/
def forbidPts : List (Int × Int) :=
  [(-4400, 10), (-3400, 10), (-2400, 10), (-1500, 8), (-900, 4), (-500, 4), (-250, 4), (150, 4)]

/-- `forbid` (violated): A car on lane c, governed by a stop sign, with a crosswalk recorded as marking c, approaches from 40 m at 10 m/s, rolls over the crosswalk at 4 m/s and enters the intersection without ever being at rest. -/
def forbidTrace : Trace := drive forbidPts [laneC, isect, crosswalkC] [stopSign]

/-- `permit`: at rest at x = -7.5 (front 1 m short of the crosswalk, off it) for two samples. -/
def permitPts : List (Int × Int) :=
  [(-4400, 10), (-3400, 10), (-2400, 10), (-1500, 6), (-1000, 3), (-750, 0), (-750, 0), (-600, 2),
   (-300, 3), (300, 4)]

/-- `permit` (compliant): The same car comes to rest 1 m short of the crosswalk, off it, then proceeds and enters the intersection. -/
def permitTrace : Trace := drive permitPts [laneC, isect, crosswalkC] [stopSign]

/-- `idle`: the lane is governed by a traffic signal only. -/
def idlePts : List (Int × Int) :=
  [(-4400, 10), (-3400, 10), (-2400, 10), (-1400, 10), (-400, 10), (600, 10)]

/-- `idle` (not_applicable): A car enters the intersection through a lane governed by a traffic signal and by no stop sign. -/
def idleTrace : Trace := drive idlePts [laneC, isect] [greenSignal]

/-- `blind` (unknown): As in forbid, but the source does not observe which travel regions the stop sign governs. -/
def blindTrace : Trace := drive forbidPts [laneC, isect, crosswalkC] [stopSignBlind]

/-- `branch_1`: at rest at x = -5.5 (front 1 m short of the stop line). -/
def branch_1Pts : List (Int × Int) :=
  [(-4400, 10), (-3400, 10), (-2400, 10), (-1500, 6), (-900, 3), (-550, 0), (-550, 0), (-300, 2),
   (-100, 3), (250, 4)]

/-- `branch_1` (compliant): No crosswalk marks c (lists observed); a stop line marks c; the car comes to rest 1 m short of the line and then enters. -/
def branch_1Trace : Trace := drive branch_1Pts [laneC, isect, stopLineC] [stopSign]

/-- `branch_2`: at rest at x = -3 (front 1 m short of r's edge, off r). -/
def branch_2Pts : List (Int × Int) :=
  [(-4400, 10), (-3400, 10), (-2400, 10), (-1400, 6), (-800, 3), (-300, 0), (-300, 0), (-100, 2),
   (300, 4)]

/-- `branch_2` (compliant): Neither a crosswalk nor a stop line marks c (lists observed); the car comes to rest 1 m short of the intersection's edge, off it, and then enters. -/
def branch_2Trace : Trace := drive branch_2Pts [laneC, isect] [stopSign]

/-- `branch_3`: at rest at x = -26.5 (front 20 m short of the crosswalk), then on without a halt. -/
def branch_3Pts : List (Int × Int) :=
  [(-4400, 10), (-3400, 8), (-2650, 0), (-2650, 0), (-2000, 6), (-1200, 8), (-600, 5), (-250, 4),
   (200, 4)]

/-- `branch_3` (violated): A crosswalk marks c; the car comes to rest 20 m short of it, moves on and enters the intersection without halting again: the halt lies before the approach start. -/
def branch_3Trace : Trace := drive branch_3Pts [laneC, isect, crosswalkC] [stopSign]

/-- `branch_4`: at rest at x = -24.5 (front 20 m short of the stop line), then on without a halt. -/
def branch_4Pts : List (Int × Int) :=
  [(-4400, 10), (-3400, 8), (-2450, 0), (-2450, 0), (-1800, 6), (-1000, 8), (-500, 5), (-300, 4),
   (-100, 4)]

/-- `branch_4` (violated): No crosswalk marks c; a stop line marks c; the car comes to rest 20 m short of the line, moves on and enters without halting again: the halt lies before the approach start. -/
def branch_4Trace : Trace := drive branch_4Pts [laneC, isect, stopLineC] [stopSign]

/-- `branch_5`: at rest at x = -23 (front 21 m short of r), then on without a halt. -/
def branch_5Pts : List (Int × Int) :=
  [(-4400, 10), (-3400, 8), (-2300, 0), (-2300, 0), (-1600, 6), (-900, 7), (-400, 5), (100, 4)]

/-- `branch_5` (violated): Neither a crosswalk nor a stop line marks c (a stop line beyond r is recorded as marking another approach only); the car comes to rest 21 m short of the intersection's edge, moves on and enters without halting again: the halt lies before the approach start. -/
def branch_5Trace : Trace := drive branch_5Pts [laneC, isect, laneOther, stopLineOther] [stopSign]

/-- `history_boundary`: first sample at x = -7.5 (front 1 m short of the crosswalk) at 3 m/s. -/
def history_boundaryPts : List (Int × Int) :=
  [(-750, 3), (-450, 3), (-150, 3), (150, 3)]

/-- `history_boundary` (unknown): The recording begins with the car already 1 m short of the crosswalk marking c, moving at 3 m/s; it enters the intersection without a recorded halt, and no recorded observation shows it outside the stopping zone upstream. -/
def history_boundaryTrace : Trace := drive history_boundaryPts [laneC, isect, crosswalkC] [stopSign]

def witness (name : String) (τ : Trace) (last : Timestamp) (expected : Verdict)
    (absent : List String := []) (boundary : String := "") : Scenario :=
  { name := name
    rule := "NRS_484A_450_2"
    trace := τ
    reading := {}          -- ignored by the gate: the run's reading is substituted
    manifest := Build.manifest absent
    grounding := [("subject", 1)]
    expected := expected
    window := some (0, last)
    boundary := boundary }

def scenarios : List Scenario :=
  [ witness "forbid" forbidTrace (lastT forbidPts) .violated
  , witness "permit" permitTrace (lastT permitPts) .compliant
  , witness "idle" idleTrace (lastT idlePts) .notApplicable
  , witness "blind" blindTrace (lastT forbidPts) (.unknown []) ["dev.governs"]
  , witness "branch_1" branch_1Trace (lastT branch_1Pts) .compliant
  , witness "branch_2" branch_2Trace (lastT branch_2Pts) .compliant
  , witness "branch_3" branch_3Trace (lastT branch_3Pts) .violated
  , witness "branch_4" branch_4Trace (lastT branch_4Pts) .violated
  , witness "branch_5" branch_5Trace (lastT branch_5Pts) .violated
  , witness "history_boundary" history_boundaryTrace (lastT history_boundaryPts) (.unknown []) (boundary := "the approach start: the observation at which the car was outside the crosswalk's stopping zone upstream lies before the recording, so whether it halted within the zone before the recording began is not observed") ]

end TrafficSpecWitness.NRS_484A_450_2
